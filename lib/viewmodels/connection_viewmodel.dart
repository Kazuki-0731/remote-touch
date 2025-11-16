import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device.dart';
import '../models/status_data.dart';
import '../services/ble_central_manager.dart';
import '../services/device_storage.dart';

/// ViewModel for connection management
/// Handles device discovery, connection, pairing, and status monitoring
/// 
/// Requirements:
/// - 4.1: Scan for and discover BLE devices
/// - 4.3: Handle pairing with devices
/// - 5.1, 5.2: Display connection state
/// - 5.3, 5.4: Display battery level and status
/// - 6.2: Select and connect to registered devices
/// - 12.1, 12.2, 12.3, 12.4: Handle automatic reconnection
class ConnectionViewModel extends ChangeNotifier {
  final BLECentralManager _bleManager;
  final DeviceStorage _deviceStorage;

  // Discovered devices during scanning
  List<BluetoothDevice> _discoveredDevices = [];
  
  // Registered devices (saved)
  List<Device> _registeredDevices = [];
  
  // Currently selected/connected device
  Device? _selectedDevice;
  
  // Pairing state
  bool _isPairing = false;
  String? _pairingError;

  // Subscription to BLE manager updates
  StreamSubscription? _bleManagerSubscription;

  // Callback for reconnection failure notification
  // Requirements: 12.4 - Notify user when reconnection fails
  Function()? onReconnectionFailed;

  ConnectionViewModel({
    required BLECentralManager bleManager,
    required DeviceStorage deviceStorage,
  })  : _bleManager = bleManager,
        _deviceStorage = deviceStorage {
    _loadRegisteredDevices();
    _listenToBLEManager();
    _setupReconnectionCallback();
  }
  
  /// Setup callback for reconnection failure
  void _setupReconnectionCallback() {
    _bleManager.onReconnectionFailed = () {
      // Forward the callback to the UI layer
      onReconnectionFailed?.call();
    };
  }

  // Getters
  BLEConnectionState get connectionState => _bleManager.connectionState;
  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<Device> get registeredDevices => List.unmodifiable(_registeredDevices);
  Device? get selectedDevice => _selectedDevice;
  BluetoothDevice? get connectedBLEDevice => _bleManager.connectedDevice;
  StatusData? get lastStatus => _bleManager.lastStatus;
  int get batteryLevel => _bleManager.lastStatus?.batteryLevel ?? 100;
  bool get isPairing => _isPairing;
  String? get pairingError => _pairingError;
  bool get isConnected => connectionState == BLEConnectionState.connected;
  bool get isReconnecting => connectionState == BLEConnectionState.reconnecting;
  bool get isDisconnected => connectionState == BLEConnectionState.disconnected;
  int get reconnectionAttempts => _bleManager.reconnectionAttempts;
  int get maxReconnectionAttempts => _bleManager.maxReconnectionAttemptsCount;

  /// Get connection state as a user-friendly string
  /// 
  /// Requirements:
  /// - 5.1: Display "Connected" when connected
  /// - 5.2: Display "Disconnected" when disconnected
  /// - 12.1: Display "Reconnecting" during reconnection
  String get connectionStateText {
    switch (connectionState) {
      case BLEConnectionState.connected:
        return 'Connected';
      case BLEConnectionState.connecting:
        return 'Connecting...';
      case BLEConnectionState.reconnecting:
        return 'Reconnecting...';
      case BLEConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  /// Start scanning for BLE devices
  /// 
  /// Requirements:
  /// - 4.1: Scan for macOS devices in range
  Future<void> startScanning() async {
    try {
      await _bleManager.startScanning();
      
      // Update discovered devices list periodically
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (_bleManager.discoveredDevices.isNotEmpty) {
          _discoveredDevices = _bleManager.discoveredDevices;
          notifyListeners();
        }
        
        // Stop timer after 15 seconds (scan timeout)
        if (timer.tick >= 30) {
          timer.cancel();
        }
      });
    } catch (e) {
      debugPrint('Error starting scan: $e');
    }
  }

  /// Stop scanning for BLE devices
  Future<void> stopScanning() async {
    await _bleManager.stopScanning();
    notifyListeners();
  }

  /// Connect to a discovered BLE device
  /// 
  /// Requirements:
  /// - 4.1: Connect to selected device
  /// - 4.3: Initiate pairing process
  /// - Device storage error fallback handling
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _isPairing = true;
      _pairingError = null;
      notifyListeners();

      final success = await _bleManager.connect(device);
      
      if (success) {
        // Create or update device record
        final deviceRecord = Device(
          id: device.remoteId.str,
          name: device.platformName.isNotEmpty ? device.platformName : 'Unknown Device',
          peripheralUUID: device.remoteId.str,
          lastConnected: DateTime.now(),
          isPaired: true,
        );

        // Save device with fallback handling
        // Requirement: Device storage error fallback
        try {
          await _deviceStorage.saveDevice(deviceRecord);
          debugPrint('Device saved to storage successfully');
        } catch (storageError) {
          debugPrint('Warning: Failed to save device to storage: $storageError');
          debugPrint('Device will be available in memory only for this session');
          // Continue anyway - device is still connected in memory
        }
        
        _selectedDevice = deviceRecord;
        
        // Reload registered devices (with error handling)
        await _loadRegisteredDevices();
      } else {
        _pairingError = 'Failed to connect to device';
      }

      _isPairing = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      _pairingError = 'Connection error: $e';
      _isPairing = false;
      notifyListeners();
      return false;
    }
  }

  /// Connect to a registered device by ID
  /// 
  /// Requirements:
  /// - 6.2: Connect to previously registered device
  Future<bool> connectToRegisteredDevice(String deviceId) async {
    try {
      final device = _registeredDevices.firstWhere(
        (d) => d.id == deviceId,
        orElse: () => throw Exception('Device not found'),
      );

      // Find the BLE device
      // First check if it's already discovered
      BluetoothDevice? bleDevice;
      
      for (var discovered in _discoveredDevices) {
        if (discovered.remoteId.str == device.peripheralUUID) {
          bleDevice = discovered;
          break;
        }
      }

      // If not found, start scanning
      if (bleDevice == null) {
        await startScanning();
        
        // Wait a bit for scan results
        await Future.delayed(const Duration(seconds: 3));
        
        for (var discovered in _discoveredDevices) {
          if (discovered.remoteId.str == device.peripheralUUID) {
            bleDevice = discovered;
            break;
          }
        }
      }

      if (bleDevice == null) {
        _pairingError = 'Device not found in range';
        notifyListeners();
        return false;
      }

      await stopScanning();
      return await connectToDevice(bleDevice);
    } catch (e) {
      debugPrint('Error connecting to registered device: $e');
      _pairingError = 'Failed to connect: $e';
      notifyListeners();
      return false;
    }
  }

  /// Send pairing code to device
  /// 
  /// Requirements:
  /// - 4.3: Send pairing code for verification
  /// - 4.5: Handle pairing errors
  Future<bool> sendPairingCode(String code) async {
    try {
      if (code.length != 6 || int.tryParse(code) == null) {
        _pairingError = 'Invalid pairing code format';
        notifyListeners();
        return false;
      }

      final success = await _bleManager.sendPairingCode(code);
      
      if (!success) {
        _pairingError = 'Failed to send pairing code';
        notifyListeners();
        return false;
      }

      _pairingError = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending pairing code: $e');
      _pairingError = 'Pairing error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    await _bleManager.disconnect();
    _selectedDevice = null;
    notifyListeners();
  }

  /// Remove a registered device
  /// 
  /// Requirements:
  /// - 6.3: Allow removal of registered devices
  Future<void> removeDevice(String deviceId) async {
    try {
      final device = _registeredDevices.firstWhere((d) => d.id == deviceId);
      await _deviceStorage.removeDevice(device);
      await _loadRegisteredDevices();
      
      // If this was the selected device, clear selection
      if (_selectedDevice?.id == deviceId) {
        _selectedDevice = null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing device: $e');
    }
  }

  /// Manually retry connection
  /// 
  /// Requirements:
  /// - 12.4: Allow manual reconnection after failures
  Future<void> retryConnection() async {
    if (_selectedDevice != null) {
      await connectToRegisteredDevice(_selectedDevice!.id);
    } else if (connectedBLEDevice != null) {
      await connectToDevice(connectedBLEDevice!);
    }
  }

  /// Load registered devices from storage
  /// 
  /// Requirement: Device storage error fallback handling
  Future<void> _loadRegisteredDevices() async {
    try {
      _registeredDevices = await _deviceStorage.loadDevices();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading registered devices: $e');
      debugPrint('Continuing with empty device list');
      // Fallback: Use empty list if storage fails
      _registeredDevices = [];
      notifyListeners();
    }
  }

  /// Listen to BLE manager state changes
  void _listenToBLEManager() {
    // The BLE manager is a ChangeNotifier, so we can listen to it
    _bleManager.addListener(() {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _bleManagerSubscription?.cancel();
    super.dispose();
  }
}
