//
//  PairingIntegrationExample.swift
//  RemoteTouch macOS
//
//  Example integration of pairing functionality
//  This file demonstrates how to use the pairing system
//

import Foundation
import CoreBluetooth

/// Example class showing how to integrate pairing functionality
class PairingIntegrationExample: BLEPeripheralManagerDelegate {
    
    private let bleManager: BLEPeripheralManager
    private let pairingWindow: PairingWindowController
    
    init() {
        bleManager = BLEPeripheralManager()
        pairingWindow = PairingWindowController()
        
        bleManager.delegate = self
    }
    
    func start() {
        // Start BLE advertising
        bleManager.startAdvertising()
        print("Started BLE advertising. Ready for pairing.")
    }
    
    // MARK: - BLEPeripheralManagerDelegate
    
    func peripheralManager(_ manager: BLEPeripheralManager, didReceiveCommand command: Any) {
        // Handle commands from iOS device
        print("Received command: \(command)")
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, didUpdateConnectionState isConnected: Bool) {
        if isConnected {
            print("Device connected")
        } else {
            print("Device disconnected")
            pairingWindow.closeWindow()
        }
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, didGeneratePairingCode code: String) {
        print("Generated pairing code: \(code)")
        
        // Show pairing window with code
        pairingWindow.showPairingCode(code)
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, didCompletePairingWith device: Device) {
        print("Pairing completed with device: \(device.name)")
        
        // Show success message
        pairingWindow.showPairingSuccess(deviceName: device.name)
        
        // List all paired devices
        let pairedDevices = bleManager.getPairedDevices()
        print("Total paired devices: \(pairedDevices.count)")
        for device in pairedDevices {
            print("  - \(device.name) (last connected: \(device.lastConnected))")
        }
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, didFailPairingWithError error: PairingError) {
        print("Pairing failed: \(error.localizedDescription)")
        
        // Show error message
        pairingWindow.showPairingFailure(error: error.localizedDescription)
        
        // Check if locked out
        if manager.isPairingLockedOut() {
            if let remainingTime = manager.getRemainingLockoutTime() {
                let seconds = Int(remainingTime)
                pairingWindow.showLockout(remainingSeconds: seconds)
                print("Pairing locked out for \(seconds) seconds")
            }
        }
    }
    
    // MARK: - Device Management Examples
    
    func listPairedDevices() {
        let devices = bleManager.getPairedDevices()
        print("Paired devices:")
        for device in devices {
            print("  - \(device.name) (\(device.id))")
            print("    Last connected: \(device.lastConnected)")
        }
    }
    
    func removePairedDevice(deviceId: String) {
        do {
            try bleManager.removePairedDevice(deviceId)
            print("Removed device: \(deviceId)")
        } catch {
            print("Failed to remove device: \(error)")
        }
    }
    
    func checkDevicePaired(centralIdentifier: UUID) -> Bool {
        return bleManager.isDevicePaired(centralIdentifier)
    }
}

// MARK: - Usage Example

/*
 
 // In your AppDelegate or main app controller:
 
 let pairingExample = PairingIntegrationExample()
 pairingExample.start()
 
 // To list paired devices:
 pairingExample.listPairedDevices()
 
 // To remove a device:
 pairingExample.removePairedDevice(deviceId: "some-uuid")
 
 // To check if device is paired:
 let isPaired = pairingExample.checkDevicePaired(centralIdentifier: someUUID)
 
 */
