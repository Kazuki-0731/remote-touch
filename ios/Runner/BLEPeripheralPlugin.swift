import Flutter
import UIKit
import CoreBluetooth

/// iOS BLE Peripheral Plugin
/// Implements BLE Peripheral functionality for advertising and accepting connections from macOS
class BLEPeripheralPlugin: NSObject, FlutterPlugin, CBPeripheralManagerDelegate {

    // MARK: - Properties

    private var peripheralManager: CBPeripheralManager?
    private var methodChannel: FlutterMethodChannel?

    // BLE Service and Characteristic UUIDs (must match macOS app)
    private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    private let commandCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABD")
    private let statusCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABE")

    private var service: CBMutableService?
    private var commandCharacteristic: CBMutableCharacteristic?
    private var statusCharacteristic: CBMutableCharacteristic?

    private var connectedCentral: CBCentral?
    private var isAdvertising = false

    // MARK: - Plugin Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "remote_touch/ble_peripheral", binaryMessenger: registrar.messenger())
        let instance = BLEPeripheralPlugin()
        instance.methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - Flutter Method Call Handler

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startAdvertising":
            startAdvertising(result: result)
        case "stopAdvertising":
            stopAdvertising(result: result)
        case "sendCommand":
            if let args = call.arguments as? [String: Any] {
                sendCommand(args, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            }
        case "disconnect":
            disconnect(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - BLE Peripheral Methods

    private func startAdvertising(result: @escaping FlutterResult) {
        if peripheralManager == nil {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        }

        // Wait for peripheral manager to be ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            if self.peripheralManager?.state == .poweredOn {
                self.setupService()
                self.startAdvertisingService()
                result(true)
            } else {
                result(FlutterError(code: "BLE_NOT_READY", message: "Bluetooth not ready", details: nil))
            }
        }
    }

    private func setupService() {
        // Create command characteristic (Write, Notify)
        commandCharacteristic = CBMutableCharacteristic(
            type: commandCharacteristicUUID,
            properties: [.write, .notify],
            value: nil,
            permissions: [.writeable]
        )

        // Create status characteristic (Read, Notify)
        statusCharacteristic = CBMutableCharacteristic(
            type: statusCharacteristicUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )

        // Create service
        service = CBMutableService(type: serviceUUID, primary: true)
        service?.characteristics = [commandCharacteristic!, statusCharacteristic!]

        // Add service to peripheral manager
        peripheralManager?.add(service!)
    }

    private func startAdvertisingService() {
        let advertisingData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "RemoteTouch"
        ]

        peripheralManager?.startAdvertising(advertisingData)
        isAdvertising = true
        print("BLEPeripheralPlugin: Started advertising")
    }

    private func stopAdvertising(result: @escaping FlutterResult) {
        peripheralManager?.stopAdvertising()
        isAdvertising = false
        connectedCentral = nil
        result(nil)
        print("BLEPeripheralPlugin: Stopped advertising")
    }

    private func sendCommand(_ command: [String: Any], result: @escaping FlutterResult) {
        guard let commandChar = commandCharacteristic,
              let central = connectedCentral else {
            result(false)
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: command)
            let success = peripheralManager?.updateValue(jsonData, for: commandChar, onSubscribedCentrals: [central]) ?? false
            result(success)
        } catch {
            print("Error serializing command: \(error)")
            result(false)
        }
    }

    private func disconnect(result: @escaping FlutterResult) {
        // CBPeripheralManager doesn't have direct disconnect method
        // Stopping advertising will prevent new connections
        stopAdvertising(result: result)
    }

    // MARK: - CBPeripheralManagerDelegate

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("BLEPeripheralPlugin: State changed to \(peripheral.state.rawValue)")

        switch peripheral.state {
        case .poweredOn:
            print("BLEPeripheralPlugin: Bluetooth powered on")
        case .poweredOff:
            print("BLEPeripheralPlugin: Bluetooth powered off")
            methodChannel?.invokeMethod("onError", arguments: ["error": "Bluetooth powered off"])
        case .unsupported:
            print("BLEPeripheralPlugin: Bluetooth unsupported")
            methodChannel?.invokeMethod("onError", arguments: ["error": "Bluetooth unsupported"])
        case .unauthorized:
            print("BLEPeripheralPlugin: Bluetooth unauthorized")
            methodChannel?.invokeMethod("onError", arguments: ["error": "Bluetooth unauthorized"])
        default:
            break
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("Error adding service: \(error.localizedDescription)")
            return
        }
        print("BLEPeripheralPlugin: Service added successfully")
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Error starting advertising: \(error.localizedDescription)")
            methodChannel?.invokeMethod("onError", arguments: ["error": error.localizedDescription])
            return
        }
        print("BLEPeripheralPlugin: Advertising started successfully")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("BLEPeripheralPlugin: Central subscribed to characteristic: \(characteristic.uuid)")
        connectedCentral = central

        let args: [String: Any] = [
            "connected": true,
            "deviceName": central.identifier.uuidString
        ]
        methodChannel?.invokeMethod("onConnectionStateChanged", arguments: args)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("BLEPeripheralPlugin: Central unsubscribed from characteristic: \(characteristic.uuid)")
        connectedCentral = nil

        let args: [String: Any] = [
            "connected": false,
            "deviceName": NSNull()
        ]
        methodChannel?.invokeMethod("onConnectionStateChanged", arguments: args)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == commandCharacteristicUUID {
                // Command received from macOS Central
                if let value = request.value,
                   let json = try? JSONSerialization.jsonObject(with: value) as? [String: Any] {
                    print("BLEPeripheralPlugin: Received command: \(json)")
                    // Note: In reversed architecture, we don't process commands here
                    // Commands are sent FROM iOS/Android TO macOS
                }
                peripheral.respond(to: request, withResult: .success)
            }
        }
    }
}
