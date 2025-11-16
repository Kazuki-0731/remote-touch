//
//  BLEPeripheralManager.swift
//  RemoteTouch macOS
//
//  BLE Peripheral Manager for macOS - handles BLE server functionality
//

import Foundation
import CoreBluetooth
import IOKit.ps

/// Delegate protocol for BLE Peripheral Manager events
protocol BLEPeripheralManagerDelegate: AnyObject {
    func peripheralManager(_ manager: BLEPeripheralManager, didReceiveCommand command: Any)
    func peripheralManager(_ manager: BLEPeripheralManager, didUpdateConnectionState isConnected: Bool)
    func peripheralManager(_ manager: BLEPeripheralManager, didGeneratePairingCode code: String)
    func peripheralManager(_ manager: BLEPeripheralManager, didCompletePairingWith device: Device)
    func peripheralManager(_ manager: BLEPeripheralManager, didFailPairingWithError error: PairingError)
}

/// BLE Peripheral Manager - manages BLE server functionality on macOS
class BLEPeripheralManager: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: BLEPeripheralManagerDelegate?
    
    private var peripheralManager: CBPeripheralManager!
    private var commandCharacteristic: CBMutableCharacteristic!
    private var statusCharacteristic: CBMutableCharacteristic!
    private var pairingCharacteristic: CBMutableCharacteristic!
    
    private var statusUpdateTimer: Timer?
    private var connectedCentral: CBCentral?
    
    // Pairing manager
    private let pairingManager = PairingManager()
    
    // MARK: - BLE UUIDs (matching design document)
    
    static let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    static let commandCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABD")
    static let statusCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABE")
    static let pairingCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABF")
    
    // MARK: - State
    
    private(set) var isAdvertising = false
    private(set) var isConnected = false
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        pairingManager.delegate = self
    }
    
    // MARK: - Pairing Methods
    
    /// Get current pairing code for display
    func getCurrentPairingCode() -> String? {
        return pairingManager.getCurrentPairingCode()
    }
    
    /// Check if device is already paired
    func isDevicePaired(_ centralIdentifier: UUID) -> Bool {
        return pairingManager.isDevicePaired(centralIdentifier)
    }
    
    /// Get all paired devices
    func getPairedDevices() -> [Device] {
        return pairingManager.loadPairedDevices()
    }
    
    /// Remove a paired device
    func removePairedDevice(_ deviceId: String) throws {
        try pairingManager.removePairedDevice(deviceId)
    }
    
    /// Check if pairing is locked out
    func isPairingLockedOut() -> Bool {
        return pairingManager.isLockedOut()
    }
    
    /// Get remaining lockout time
    func getRemainingLockoutTime() -> TimeInterval? {
        return pairingManager.getRemainingLockoutTime()
    }
    
    // MARK: - Public Methods
    
    /// Start advertising the BLE service
    /// 
    /// Requirement: BLE advertising error handling with retry logic
    func startAdvertising() {
        guard peripheralManager.state == .poweredOn else {
            print("BLEPeripheralManager: Cannot start advertising - Bluetooth not powered on")
            print("BLEPeripheralManager: Current state: \(peripheralManager.state.rawValue)")
            
            // Schedule retry if Bluetooth is not ready
            if peripheralManager.state == .unknown || peripheralManager.state == .resetting {
                print("BLEPeripheralManager: Will retry advertising in 2 seconds")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.startAdvertising()
                }
            }
            return
        }
        
        guard !isAdvertising else {
            print("BLEPeripheralManager: Already advertising")
            return
        }
        
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [BLEPeripheralManager.serviceUUID],
            CBAdvertisementDataLocalNameKey: "RemoteTouch-\(getDeviceName())"
        ]
        
        peripheralManager.startAdvertising(advertisementData)
        isAdvertising = true
        print("BLEPeripheralManager: Started advertising as RemoteTouch-\(getDeviceName())")
    }
    
    /// Stop advertising the BLE service
    func stopAdvertising() {
        guard isAdvertising else {
            return
        }
        
        peripheralManager.stopAdvertising()
        isAdvertising = false
        print("BLEPeripheralManager: Stopped advertising")
    }
    
    /// Send status data to connected iOS device
    func sendStatus(_ status: StatusData) {
        guard isConnected, let central = connectedCentral else {
            print("BLEPeripheralManager: Cannot send status - no connected device")
            return
        }
        
        do {
            let data = try status.toJSON()
            let success = peripheralManager.updateValue(
                data,
                for: statusCharacteristic,
                onSubscribedCentrals: [central]
            )
            
            if success {
                print("BLEPeripheralManager: Status sent successfully")
            } else {
                print("BLEPeripheralManager: Status send queued (transmission queue full)")
            }
        } catch {
            print("BLEPeripheralManager: Failed to encode status - \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupService() {
        // Create characteristics
        commandCharacteristic = CBMutableCharacteristic(
            type: BLEPeripheralManager.commandCharacteristicUUID,
            properties: [.write],
            value: nil,
            permissions: [.writeable]
        )
        
        statusCharacteristic = CBMutableCharacteristic(
            type: BLEPeripheralManager.statusCharacteristicUUID,
            properties: [.notify],
            value: nil,
            permissions: [.readable]
        )
        
        pairingCharacteristic = CBMutableCharacteristic(
            type: BLEPeripheralManager.pairingCharacteristicUUID,
            properties: [.read, .write],
            value: nil,
            permissions: [.readable, .writeable]
        )
        
        // Create service
        let service = CBMutableService(
            type: BLEPeripheralManager.serviceUUID,
            primary: true
        )
        service.characteristics = [
            commandCharacteristic,
            statusCharacteristic,
            pairingCharacteristic
        ]
        
        // Add service to peripheral manager
        peripheralManager.add(service)
        print("BLEPeripheralManager: Service added")
    }
    
    private func startStatusUpdates() {
        stopStatusUpdates()
        
        // Send status every 2 seconds as per requirements
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.sendPeriodicStatus()
        }
        
        print("BLEPeripheralManager: Started status updates")
    }
    
    private func stopStatusUpdates() {
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
    }
    
    private func sendPeriodicStatus() {
        let batteryLevel = getBatteryLevel()
        let connectionQuality = 100 // Simplified - could be enhanced with RSSI
        
        let status = StatusData(
            batteryLevel: batteryLevel,
            timestamp: Date(),
            connectionQuality: connectionQuality
        )
        
        sendStatus(status)
    }
    
    private func getBatteryLevel() -> Int {
        // Get battery level using IOKit
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for source in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as! [String: Any]
            
            if let currentCapacity = info[kIOPSCurrentCapacityKey] as? Int,
               let maxCapacity = info[kIOPSMaxCapacityKey] as? Int,
               maxCapacity > 0 {
                return (currentCapacity * 100) / maxCapacity
            }
        }
        
        return 100 // Default to 100% if battery info unavailable (desktop Mac)
    }
    
    private func getDeviceName() -> String {
        return Host.current().localizedName ?? "Mac"
    }
    
    private func handleConnectionStateChange(isConnected: Bool) {
        self.isConnected = isConnected
        
        if isConnected {
            startStatusUpdates()
            
            // Update last connected time for paired device
            if let central = connectedCentral {
                let deviceId = central.identifier.uuidString
                try? pairingManager.updateDeviceLastConnected(deviceId)
            }
        } else {
            stopStatusUpdates()
            connectedCentral = nil
        }
        
        delegate?.peripheralManager(self, didUpdateConnectionState: isConnected)
    }
}

// MARK: - CBPeripheralManagerDelegate

extension BLEPeripheralManager: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("BLEPeripheralManager: Bluetooth powered on")
            setupService()
        case .poweredOff:
            print("BLEPeripheralManager: Bluetooth powered off")
            stopAdvertising()
        case .resetting:
            print("BLEPeripheralManager: Bluetooth resetting")
        case .unauthorized:
            print("BLEPeripheralManager: Bluetooth unauthorized")
        case .unsupported:
            print("BLEPeripheralManager: Bluetooth unsupported")
        case .unknown:
            print("BLEPeripheralManager: Bluetooth state unknown")
        @unknown default:
            print("BLEPeripheralManager: Unknown Bluetooth state")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("BLEPeripheralManager: Failed to add service - \(error)")
            return
        }
        
        print("BLEPeripheralManager: Service added successfully")
        startAdvertising()
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("BLEPeripheralManager: Failed to start advertising - \(error)")
            print("BLEPeripheralManager: Error details: \(error.localizedDescription)")
            isAdvertising = false
            
            // Requirement: Retry advertising on failure after delay
            print("BLEPeripheralManager: Will retry advertising in 10 seconds")
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                self?.startAdvertising()
            }
            return
        }
        
        print("BLEPeripheralManager: Advertising started successfully")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == BLEPeripheralManager.commandCharacteristicUUID {
                handleCommandWrite(request)
            } else if request.characteristic.uuid == BLEPeripheralManager.pairingCharacteristicUUID {
                handlePairingWrite(request)
            }
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == BLEPeripheralManager.pairingCharacteristicUUID {
            handlePairingRead(request)
        } else {
            peripheral.respond(to: request, withResult: .requestNotSupported)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("BLEPeripheralManager: Central subscribed to characteristic: \(characteristic.uuid)")
        
        if characteristic.uuid == BLEPeripheralManager.statusCharacteristicUUID {
            connectedCentral = central
            handleConnectionStateChange(isConnected: true)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("BLEPeripheralManager: Central unsubscribed from characteristic: \(characteristic.uuid)")
        
        if characteristic.uuid == BLEPeripheralManager.statusCharacteristicUUID {
            handleConnectionStateChange(isConnected: false)
        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print("BLEPeripheralManager: Ready to update subscribers")
        // Can retry sending queued status updates here if needed
    }
}

// MARK: - PairingManagerDelegate

extension BLEPeripheralManager: PairingManagerDelegate {
    
    func pairingManager(_ manager: PairingManager, didGenerateCode code: String) {
        print("BLEPeripheralManager: Pairing code generated: \(code)")
        delegate?.peripheralManager(self, didGeneratePairingCode: code)
    }
    
    func pairingManager(_ manager: PairingManager, didCompletePairingWith device: Device) {
        print("BLEPeripheralManager: Pairing completed with device: \(device.name)")
        delegate?.peripheralManager(self, didCompletePairingWith: device)
    }
    
    func pairingManager(_ manager: PairingManager, didFailPairingWithError error: PairingError) {
        print("BLEPeripheralManager: Pairing failed with error: \(error.localizedDescription)")
        delegate?.peripheralManager(self, didFailPairingWithError: error)
    }
    
    func pairingManager(_ manager: PairingManager, didLockoutUntil date: Date) {
        print("BLEPeripheralManager: Pairing locked out until: \(date)")
    }
    
    // MARK: - Request Handlers
    
    private func handleCommandWrite(_ request: CBATTRequest) {
        guard let data = request.value else {
            print("BLEPeripheralManager: Received command with no data")
            peripheralManager.respond(to: request, withResult: .invalidAttributeValueLength)
            return
        }
        
        // Requirement 4.5: Validate command data size
        if data.count == 0 {
            print("BLEPeripheralManager: Received empty command data")
            peripheralManager.respond(to: request, withResult: .invalidAttributeValueLength)
            return
        }
        
        if data.count > 512 {
            print("BLEPeripheralManager: Command data too large: \(data.count) bytes")
            peripheralManager.respond(to: request, withResult: .invalidAttributeValueLength)
            return
        }
        
        do {
            // Requirement 4.5: Parse and validate command
            let command = try CommandParser.parse(data)
            peripheralManager.respond(to: request, withResult: .success)
            
            // Notify delegate of received command
            delegate?.peripheralManager(self, didReceiveCommand: command)
            
            print("BLEPeripheralManager: Command received and parsed successfully")
        } catch {
            // Requirement 4.5: Handle invalid command errors gracefully
            print("BLEPeripheralManager: Failed to parse command - \(error)")
            print("BLEPeripheralManager: Command data (hex): \(data.map { String(format: "%02x", $0) }.joined())")
            
            // Log error details for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("BLEPeripheralManager: Invalid command JSON: \(jsonString)")
            }
            
            peripheralManager.respond(to: request, withResult: .unlikelyError)
        }
    }
    
    private func handlePairingWrite(_ request: CBATTRequest) {
        guard let data = request.value else {
            peripheralManager.respond(to: request, withResult: .invalidAttributeValueLength)
            return
        }
        
        guard let pairingData = String(data: data, encoding: .utf8) else {
            peripheralManager.respond(to: request, withResult: .unlikelyError)
            return
        }
        
        // Parse pairing request JSON
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["code"] as? String,
                  let deviceName = json["deviceName"] as? String else {
                peripheralManager.respond(to: request, withResult: .unlikelyError)
                return
            }
            
            // Verify pairing code
            let success = pairingManager.verifyPairingCode(code, from: request.central, deviceName: deviceName)
            
            if success {
                peripheralManager.respond(to: request, withResult: .success)
                print("BLEPeripheralManager: Pairing successful")
            } else {
                peripheralManager.respond(to: request, withResult: .unlikelyError)
                print("BLEPeripheralManager: Pairing failed")
            }
        } catch {
            print("BLEPeripheralManager: Failed to parse pairing request - \(error)")
            peripheralManager.respond(to: request, withResult: .unlikelyError)
        }
    }
    
    private func handlePairingRead(_ request: CBATTRequest) {
        // Check if device is already paired
        if pairingManager.isDevicePaired(request.central.identifier) {
            // Device already paired, return success status
            let response = ["status": "paired"]
            if let data = try? JSONSerialization.data(withJSONObject: response) {
                request.value = data
                peripheralManager.respond(to: request, withResult: .success)
            } else {
                peripheralManager.respond(to: request, withResult: .unlikelyError)
            }
            return
        }
        
        // Check if locked out
        if pairingManager.isLockedOut() {
            let response = [
                "status": "locked",
                "remainingTime": pairingManager.getRemainingLockoutTime() ?? 0
            ] as [String : Any]
            
            if let data = try? JSONSerialization.data(withJSONObject: response) {
                request.value = data
                peripheralManager.respond(to: request, withResult: .success)
            } else {
                peripheralManager.respond(to: request, withResult: .unlikelyError)
            }
            return
        }
        
        // Generate new pairing code
        let code = pairingManager.generatePairingCode(for: request.central)
        
        if code.isEmpty {
            // Failed to generate code (locked out)
            peripheralManager.respond(to: request, withResult: .unlikelyError)
            return
        }
        
        // Return pairing code
        let response = [
            "status": "pending",
            "code": code
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: response)
            request.value = data
            peripheralManager.respond(to: request, withResult: .success)
            print("BLEPeripheralManager: Pairing code sent to iOS device")
        } catch {
            print("BLEPeripheralManager: Failed to encode pairing response - \(error)")
            peripheralManager.respond(to: request, withResult: .unlikelyError)
        }
    }
}
