import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/status_data.dart';

/// Connection state for BLE
enum BLEConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// BLE Central Manager for iOS app
/// Handles device scanning, connection, and communication with macOS peripheral
class BLECentralManager extends ChangeNotifier {
  // GATT Service and Characteristic UUIDs (must match macOS app)
  static final Guid serviceUUID = Guid('12345678-1234-1234-1234-123456789ABC');
  static final Guid commandCharacteristicUUID = Guid('12345678-1234-1234-1234-123456789ABD');
  static final Guid statusCharacteristicUUID = Guid('12345678-1234-1234-1234-123456789ABE');
  static final Guid pairingCharacteristicUUID = Guid('12345678-1234-1234-1234-123456789ABF');

  // BLE state
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _statusCharacteristic;
  BluetoothCharacteristic? _pairingCharacteristic;

  BLEConnectionState _connectionState = BLEConnectionState.disconnected;
  final List<BluetoothDevice> _discoveredDevices = [];
  
  // Status data
  StatusData? _lastStatus;
  
  // Reconnection logic
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int maxReconnectionAttempts = 10;
  static const Duration reconnectionInterval = Duration(seconds: 5);
  
  // Callback for reconnection failure notification
  // Requirements: 12.4 - Notify user when reconnection fails
  Function()? onReconnectionFailed;

  // Subscriptions
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _statusSubscription;

  // Getters
  BLEConnectionState get connectionState => _connectionState;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  StatusData? get lastStatus => _lastStatus;

  /// Start scanning for BLE devices
  Future<void> startScanning() async {
    try {
      _discoveredDevices.clear();
      notifyListeners();

      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint('BLE is not supported on this device');
        return;
      }

      // Check if Bluetooth is on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        debugPrint('Bluetooth is not turned on');
        return;
      }

      // Start scanning
      await FlutterBluePlus.startScan(
        withServices: [serviceUUID],
        timeout: const Duration(seconds: 15),
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (!_discoveredDevices.contains(result.device)) {
            _discoveredDevices.add(result.device);
            notifyListeners();
          }
        }
      });
    } catch (e) {
      debugPrint('Error starting scan: $e');
    }
  }

  /// Stop scanning for BLE devices
  Future<void> stopScanning() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  /// Connect to a BLE device
  /// 
  /// Requirements:
  /// - 4.5: Handle pairing errors appropriately
  /// - 12.1, 12.2: Implement retry logic for connection failures
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _connectionState = BLEConnectionState.connecting;
      notifyListeners();

      // Stop scanning if active
      await stopScanning();

      // Connect to device with timeout
      // Requirement 4.5: Handle connection errors
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _connectedDevice = device;

      // Listen to connection state changes
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((state) {
        _handleConnectionStateChange(state);
      });

      // Discover services
      // Requirement 4.5: Handle service discovery errors
      final services = await device.discoverServices();
      
      // Find our service
      BluetoothService? remoteService;
      for (var service in services) {
        if (service.uuid == serviceUUID) {
          remoteService = service;
          break;
        }
      }

      if (remoteService == null) {
        debugPrint('BLE Error: RemoteTouch service not found on device');
        debugPrint('This may not be a RemoteTouch macOS device');
        await disconnect();
        return false;
      }

      // Find characteristics
      for (var characteristic in remoteService.characteristics) {
        if (characteristic.uuid == commandCharacteristicUUID) {
          _commandCharacteristic = characteristic;
        } else if (characteristic.uuid == statusCharacteristicUUID) {
          _statusCharacteristic = characteristic;
        } else if (characteristic.uuid == pairingCharacteristicUUID) {
          _pairingCharacteristic = characteristic;
        }
      }

      if (_commandCharacteristic == null || _statusCharacteristic == null) {
        debugPrint('BLE Error: Required characteristics not found');
        debugPrint('Device may be running incompatible RemoteTouch version');
        await disconnect();
        return false;
      }

      // Subscribe to status notifications
      // Requirement 4.5: Handle subscription errors
      await _subscribeToStatus();

      _connectionState = BLEConnectionState.connected;
      _reconnectionAttempts = 0;
      notifyListeners();

      debugPrint('BLE: Successfully connected to device');
      return true;
    } catch (e) {
      // Requirement 4.5: Detailed error logging for connection failures
      debugPrint('BLE Connection Error: $e');
      
      // Provide specific error messages based on error type
      if (e.toString().contains('timeout')) {
        debugPrint('Connection timed out - device may be out of range');
      } else if (e.toString().contains('already connected')) {
        debugPrint('Device is already connected');
      } else if (e.toString().contains('connection failed')) {
        debugPrint('Connection failed - device may be busy or unavailable');
      }
      
      _connectionState = BLEConnectionState.disconnected;
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    try {
      _reconnectionTimer?.cancel();
      _reconnectionTimer = null;
      
      _statusSubscription?.cancel();
      _statusSubscription = null;
      
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      _connectedDevice = null;
      _commandCharacteristic = null;
      _statusCharacteristic = null;
      _pairingCharacteristic = null;
      _connectionState = BLEConnectionState.disconnected;
      _reconnectionAttempts = 0;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  /// Send a command to the macOS device
  /// 
  /// Requirements:
  /// - 12.1: Handle command send failures gracefully
  /// - Implements single retry on failure as per design
  Future<bool> sendCommand(Map<String, dynamic> commandJson) async {
    if (_commandCharacteristic == null || _connectionState != BLEConnectionState.connected) {
      debugPrint('Cannot send command: not connected');
      return false;
    }

    try {
      final jsonString = jsonEncode(commandJson);
      final bytes = utf8.encode(jsonString);
      
      // Validate command size (BLE has MTU limits, typically 512 bytes)
      if (bytes.length > 512) {
        debugPrint('Command too large: ${bytes.length} bytes (max 512)');
        return false;
      }
      
      await _commandCharacteristic!.write(
        bytes,
        withoutResponse: false,
      );
      
      return true;
    } catch (e) {
      debugPrint('Error sending command: $e');
      
      // Retry once as per design document
      // Requirement: Command send failure retry logic
      try {
        debugPrint('Retrying command send...');
        final jsonString = jsonEncode(commandJson);
        final bytes = utf8.encode(jsonString);
        await _commandCharacteristic!.write(bytes, withoutResponse: false);
        debugPrint('Command retry successful');
        return true;
      } catch (retryError) {
        debugPrint('Command retry failed: $retryError');
        
        // If retry fails, connection may be unstable
        if (retryError.toString().contains('disconnected') || 
            retryError.toString().contains('not connected')) {
          debugPrint('Connection appears to be lost - may trigger reconnection');
        }
        
        return false;
      }
    }
  }

  /// Send pairing code to macOS device
  Future<bool> sendPairingCode(String code) async {
    if (_pairingCharacteristic == null) {
      debugPrint('Cannot send pairing code: characteristic not found');
      return false;
    }

    try {
      final bytes = utf8.encode(code);
      await _pairingCharacteristic!.write(bytes, withoutResponse: false);
      return true;
    } catch (e) {
      debugPrint('Error sending pairing code: $e');
      return false;
    }
  }

  /// Subscribe to status notifications from macOS
  Future<void> _subscribeToStatus() async {
    if (_statusCharacteristic == null) return;

    try {
      // Enable notifications
      await _statusCharacteristic!.setNotifyValue(true);

      // Listen to notifications
      _statusSubscription?.cancel();
      _statusSubscription = _statusCharacteristic!.lastValueStream.listen((value) {
        _handleStatusUpdate(value);
      });
    } catch (e) {
      debugPrint('Error subscribing to status: $e');
    }
  }

  /// Handle status updates from macOS
  void _handleStatusUpdate(List<int> value) {
    try {
      final jsonString = utf8.decode(value);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _lastStatus = StatusData.fromJson(json);
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing status data: $e');
    }
  }

  /// Handle connection state changes
  void _handleConnectionStateChange(BluetoothConnectionState state) {
    if (state == BluetoothConnectionState.disconnected) {
      if (_connectionState == BLEConnectionState.connected) {
        // Unexpected disconnection - start reconnection
        _startReconnection();
      }
    }
  }

  /// Start automatic reconnection
  /// 
  /// Requirements:
  /// - 12.1: Display "Reconnecting" state
  /// - 12.2: Retry connection every 5 seconds, max 10 attempts
  /// - 12.3: Display "Connected" on success
  /// - 12.4: Display "Disconnected" and notify user on failure
  void _startReconnection() {
    if (_connectedDevice == null) return;
    if (_reconnectionAttempts >= maxReconnectionAttempts) {
      debugPrint('Max reconnection attempts reached');
      _connectionState = BLEConnectionState.disconnected;
      notifyListeners();
      
      // Notify user that reconnection failed
      // Requirement 12.4: User notification on reconnection failure
      onReconnectionFailed?.call();
      return;
    }

    _connectionState = BLEConnectionState.reconnecting;
    _reconnectionAttempts++;
    notifyListeners();

    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(reconnectionInterval, () async {
      debugPrint('Reconnection attempt $_reconnectionAttempts/$maxReconnectionAttempts');
      
      final device = _connectedDevice;
      if (device != null) {
        final success = await connect(device);
        if (!success && _reconnectionAttempts < maxReconnectionAttempts) {
          _startReconnection();
        } else if (!success) {
          _connectionState = BLEConnectionState.disconnected;
          notifyListeners();
          
          // Notify user that all reconnection attempts failed
          // Requirement 12.4: User notification on reconnection failure
          onReconnectionFailed?.call();
        }
      }
    });
  }
  
  /// Get reconnection attempt count
  /// Used for displaying reconnection progress to user
  int get reconnectionAttempts => _reconnectionAttempts;
  
  /// Get max reconnection attempts
  int get maxReconnectionAttemptsCount => maxReconnectionAttempts;

  @override
  void dispose() {
    _reconnectionTimer?.cancel();
    _statusSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    disconnect();
    super.dispose();
  }
}
