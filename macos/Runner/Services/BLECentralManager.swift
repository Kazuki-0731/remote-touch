import Foundation
import CoreBluetooth

// Import Command model from Models directory
// Assuming the Models directory is added to the target
struct Command: Codable {
    let type: String
    let x: Double?
    let y: Double?
    let deltaX: Double?
    let deltaY: Double?
    let button: String?
    let key: String?
}

/// Protocol for BLE Central Manager delegate
protocol BLECentralManagerDelegate: AnyObject {
    func centralManager(_ manager: BLECentralManager, didReceiveCommand command: Any)
    func centralManager(_ manager: BLECentralManager, didUpdateConnectionState isConnected: Bool)
    func centralManager(_ manager: BLECentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String: Any])
}

/// BLE Central Manager for macOS
/// Scans for and connects to iOS/Android Peripherals
class BLECentralManager: NSObject {

    // MARK: - Properties

    weak var delegate: BLECentralManagerDelegate?

    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?
    private var statusCharacteristic: CBCharacteristic?

    // BLE Service and Characteristic UUIDs (must match iOS/Android app)
    static let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    static let commandCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABD")
    static let statusCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABE")

    private(set) var isScanning = false
    private(set) var isConnected = false

    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]

    // MARK: - Initialization

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Public Methods

    /// Start scanning for peripherals
    func startScanning() {
        guard let centralManager = centralManager,
              centralManager.state == .poweredOn else {
            NSLog("BLECentralManager: Cannot start scanning - Bluetooth not powered on")
            return
        }

        discoveredPeripherals.removeAll()
        centralManager.scanForPeripherals(
            withServices: [BLECentralManager.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        isScanning = true
        NSLog("BLECentralManager: Started scanning")
    }

    /// Stop scanning for peripherals
    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
        NSLog("BLECentralManager: Stopped scanning")
    }

    /// Connect to a peripheral
    func connect(to peripheral: CBPeripheral) {
        guard let centralManager = centralManager else { return }

        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        NSLog("BLECentralManager: Connecting to \(peripheral.name ?? "Unknown")")
    }

    /// Disconnect from current peripheral
    func disconnect() {
        guard let peripheral = connectedPeripheral,
              let centralManager = centralManager else { return }

        centralManager.cancelPeripheralConnection(peripheral)
        NSLog("BLECentralManager: Disconnecting")
    }

    /// Send command to connected peripheral
    func sendCommand(_ command: Command) {
        guard let peripheral = connectedPeripheral,
              let characteristic = commandCharacteristic else {
            NSLog("BLECentralManager: Cannot send command - not connected")
            return
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            NSLog("BLECentralManager: Sent command: \(command.type)")
        } catch {
            NSLog("BLECentralManager: Error encoding command: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func discoverServices(for peripheral: CBPeripheral) {
        peripheral.discoverServices([BLECentralManager.serviceUUID])
    }

    private func discoverCharacteristics(for service: CBService) {
        connectedPeripheral?.discoverCharacteristics(
            [BLECentralManager.commandCharacteristicUUID, BLECentralManager.statusCharacteristicUUID],
            for: service
        )
    }

    private func setupCharacteristics() {
        guard let characteristics = connectedPeripheral?.services?.first?.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.uuid == BLECentralManager.commandCharacteristicUUID {
                commandCharacteristic = characteristic
                // Subscribe to notifications
                connectedPeripheral?.setNotifyValue(true, for: characteristic)
                NSLog("BLECentralManager: Found command characteristic")
            } else if characteristic.uuid == BLECentralManager.statusCharacteristicUUID {
                statusCharacteristic = characteristic
                // Subscribe to notifications
                connectedPeripheral?.setNotifyValue(true, for: characteristic)
                NSLog("BLECentralManager: Found status characteristic")
            }
        }

        // Connection is fully established
        isConnected = true
        delegate?.centralManager(self, didUpdateConnectionState: true)
        NSLog("BLECentralManager: Connection established")
    }
}

// MARK: - CBCentralManagerDelegate

extension BLECentralManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("BLECentralManager: State changed to \(central.state.rawValue)")

        switch central.state {
        case .poweredOn:
            NSLog("BLECentralManager: Bluetooth powered on - ready to scan")
            // Auto-start scanning when Bluetooth becomes available
            if !isScanning {
                startScanning()
            }
        case .poweredOff:
            NSLog("BLECentralManager: Bluetooth powered off")
        case .unsupported:
            NSLog("BLECentralManager: Bluetooth unsupported")
        case .unauthorized:
            NSLog("BLECentralManager: Bluetooth unauthorized")
        case .resetting:
            NSLog("BLECentralManager: Bluetooth resetting")
        case .unknown:
            NSLog("BLECentralManager: Bluetooth state unknown")
        @unknown default:
            NSLog("BLECentralManager: Unknown Bluetooth state")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        NSLog("BLECentralManager: Discovered peripheral: \(peripheral.name ?? "Unknown") (RSSI: \(RSSI))")

        discoveredPeripherals[peripheral.identifier] = peripheral
        delegate?.centralManager(self, didDiscoverPeripheral: peripheral, advertisementData: advertisementData)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("BLECentralManager: Connected to \(peripheral.name ?? "Unknown")")
        discoverServices(for: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("BLECentralManager: Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        isConnected = false
        delegate?.centralManager(self, didUpdateConnectionState: false)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("BLECentralManager: Disconnected from \(peripheral.name ?? "Unknown")")
        isConnected = false
        commandCharacteristic = nil
        statusCharacteristic = nil
        connectedPeripheral = nil
        delegate?.centralManager(self, didUpdateConnectionState: false)

        if let error = error {
            NSLog("BLECentralManager: Disconnect error: \(error.localizedDescription)")
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLECentralManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            NSLog("BLECentralManager: Error discovering services: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }

        for service in services {
            if service.uuid == BLECentralManager.serviceUUID {
                NSLog("BLECentralManager: Found RemoteTouch service")
                discoverCharacteristics(for: service)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            NSLog("BLECentralManager: Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        setupCharacteristics()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            NSLog("BLECentralManager: Error reading characteristic: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else { return }

        if characteristic.uuid == BLECentralManager.commandCharacteristicUUID {
            // Received command from iOS/Android peripheral
            do {
                let decoder = JSONDecoder()
                let command = try decoder.decode(Command.self, from: data)
                NSLog("BLECentralManager: Received command: \(command.type)")
                delegate?.centralManager(self, didReceiveCommand: command)
            } catch {
                NSLog("BLECentralManager: Error decoding command: \(error)")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            NSLog("BLECentralManager: Error writing characteristic: \(error.localizedDescription)")
            return
        }

        NSLog("BLECentralManager: Successfully wrote to characteristic")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            NSLog("BLECentralManager: Error updating notification state: \(error.localizedDescription)")
            return
        }

        NSLog("BLECentralManager: Notification state updated for \(characteristic.uuid)")
    }
}
