import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/status_data.dart';

/// BLE Peripheral Manager for iOS/Android app
/// Advertises as a BLE Peripheral and accepts connections from macOS Central
class BLEPeripheralManager extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('remote_touch/ble_peripheral');

  // Connection state
  bool _isAdvertising = false;
  bool _isConnected = false;
  String? _connectedDeviceName;

  // Status tracking
  StatusData? _lastStatus;

  // Getters
  bool get isAdvertising => _isAdvertising;
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDeviceName;
  StatusData? get lastStatus => _lastStatus;

  BLEPeripheralManager() {
    _setupMethodCallHandler();
  }

  /// Setup method call handler for native callbacks
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'onAdvertisingStateChanged':
          final bool advertising = call.arguments['isAdvertising'] as bool;
          _handleAdvertisingStateChanged(advertising);
          break;
        case 'onConnectionStateChanged':
          final bool connected = call.arguments['isConnected'] ?? call.arguments['connected'] as bool;
          final String? deviceName = call.arguments['deviceName'] as String?;
          _handleConnectionStateChanged(connected, deviceName);
          break;
        case 'onCommandReceived':
          final String commandJson = call.arguments['command'] as String;
          debugPrint('Received command from Central: $commandJson');
          break;
        case 'onStatusUpdate':
          final Map<String, dynamic> statusMap = Map<String, dynamic>.from(call.arguments);
          _handleStatusUpdate(statusMap);
          break;
        case 'onError':
          final String error = call.arguments['error'] as String;
          _handleError(error);
          break;
      }
    });
  }

  /// Start advertising as BLE Peripheral
  Future<bool> startAdvertising() async {
    try {
      final bool success = await _channel.invokeMethod('startAdvertising');
      if (success) {
        _isAdvertising = true;
        notifyListeners();
        debugPrint('BLEPeripheralManager: Started advertising');
      }
      return success;
    } catch (e) {
      debugPrint('Error starting advertising: $e');
      return false;
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    try {
      await _channel.invokeMethod('stopAdvertising');
      _isAdvertising = false;
      _isConnected = false;
      _connectedDeviceName = null;
      notifyListeners();
      debugPrint('BLEPeripheralManager: Stopped advertising');
    } catch (e) {
      debugPrint('Error stopping advertising: $e');
    }
  }

  /// Send command data to connected Central (macOS)
  Future<bool> sendCommand(Map<String, dynamic> command) async {
    if (!_isConnected) {
      debugPrint('Cannot send command: Not connected');
      return false;
    }

    try {
      final bool success = await _channel.invokeMethod('sendCommand', command);
      return success;
    } catch (e) {
      debugPrint('Error sending command: $e');
      return false;
    }
  }

  /// Disconnect from connected Central
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
      _connectedDeviceName = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  // Private handlers

  void _handleAdvertisingStateChanged(bool advertising) {
    _isAdvertising = advertising;
    notifyListeners();
    debugPrint('BLEPeripheralManager: Advertising state changed to $advertising');
  }

  void _handleConnectionStateChanged(bool connected, String? deviceName) {
    _isConnected = connected;
    _connectedDeviceName = deviceName;
    notifyListeners();

    if (connected) {
      debugPrint('BLEPeripheralManager: Connected to $deviceName');
    } else {
      debugPrint('BLEPeripheralManager: Disconnected');
    }
  }

  void _handleStatusUpdate(Map<String, dynamic> statusMap) {
    try {
      _lastStatus = StatusData.fromJson(statusMap);
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing status update: $e');
    }
  }

  void _handleError(String error) {
    debugPrint('BLEPeripheralManager error: $error');
  }

  @override
  void dispose() {
    stopAdvertising();
    super.dispose();
  }
}
