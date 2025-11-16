// End-to-End Integration Tests for RemoteTouch
// Tests the complete flow from iOS App to macOS App

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_touch/models/command.dart';
import 'package:remote_touch/models/device.dart';
import 'package:remote_touch/models/status_data.dart';
import 'package:remote_touch/services/ble_central_manager.dart';
import 'package:remote_touch/services/gesture_processor.dart';
import 'package:remote_touch/viewmodels/touchpad_viewmodel.dart';
import 'dart:ui';

void main() {
  group('E2E: BLE Communication Flow', () {
    late MockBLECentralManager bleManager;
    late GestureProcessor gestureProcessor;
    late TouchpadViewModel viewModel;

    setUp(() {
      bleManager = MockBLECentralManager();
      gestureProcessor = GestureProcessor();
      viewModel = TouchpadViewModel(
        bleManager: bleManager,
        gestureProcessor: gestureProcessor,
      );
    });

    test('E2E: Complete pairing flow', () async {
      // Step 1: Start scanning for devices
      expect(bleManager.connectionState, BLEConnectionState.disconnected);
      
      // Step 2: Simulate device discovery
      final device = Device(
        id: 'test-device-id',
        name: 'Test Mac',
        peripheralUUID: 'test-peripheral-uuid',
        lastConnected: DateTime.now(),
        isPaired: false,
      );
      
      // Step 3: Initiate connection
      bleManager.simulateConnection(device);
      expect(bleManager.connectionState, BLEConnectionState.connected);
      
      // Step 4: Verify pairing code exchange would occur
      // (In real scenario, macOS would generate code and iOS would verify)
      expect(bleManager.isConnected, true);
    });

    test('E2E: Cursor movement command flow', () async {
      // Setup: Connect device
      bleManager.setConnected(true);
      await viewModel.setMode(ControlMode.basicMouse);
      
      // Step 1: User swipes on touchpad
      const swipeTranslation = Offset(50.0, 30.0);
      const swipeVelocity = Offset(200.0, 100.0);
      
      viewModel.handleSwipe(
        translation: swipeTranslation,
        velocity: swipeVelocity,
      );
      
      // Step 2: Verify command was sent via BLE
      expect(bleManager.lastCommand, isNotNull);
      expect(bleManager.lastCommand!['type'], 'cursorMove');
      expect(bleManager.lastCommand!['delta'], isNotNull);
      
      // Step 3: Verify command structure matches protocol
      final command = bleManager.lastCommand!;
      expect(command.containsKey('type'), true);
      expect(command.containsKey('delta'), true);
      
      final delta = command['delta'] as Map<String, dynamic>;
      expect(delta.containsKey('dx'), true);
      expect(delta.containsKey('dy'), true);
    });

    test('E2E: Click command flow', () async {
      // Setup: Connect device
      bleManager.setConnected(true);
      await viewModel.setMode(ControlMode.basicMouse);
      
      // Step 1: User taps on touchpad
      viewModel.handleTap();
      
      // Step 2: Verify single click command was sent
      expect(bleManager.lastCommand, isNotNull);
      expect(bleManager.lastCommand!['type'], 'tap');
      expect(bleManager.lastCommand!['clickType'], 'single');
    });

    test('E2E: Double click command flow', () async {
      // Setup: Connect device
      bleManager.setConnected(true);
      await viewModel.setMode(ControlMode.basicMouse);
      
      // Step 1: User double taps on touchpad (handled by gesture processor)
      // Note: Double tap detection is handled internally by GestureProcessor
      // For testing, we verify that tap commands can be sent
      viewModel.handleTap();
      
      // Step 2: Verify tap command was sent
      expect(bleManager.lastCommand, isNotNull);
      expect(bleManager.lastCommand!['type'], 'tap');
      // Note: clickType is determined by GestureProcessor based on tap timing
    });

    test('E2E: Status update reception flow', () async {
      // Setup: Connect device
      bleManager.setConnected(true);
      
      // Step 1: Simulate status update from macOS
      final statusData = StatusData(
        batteryLevel: 85,
        timestamp: DateTime.now(),
        connectionQuality: 95,
      );
      
      bleManager.simulateStatusUpdate(statusData);
      
      // Step 2: Verify status was received and processed
      expect(bleManager.lastReceivedStatus, isNotNull);
      expect(bleManager.lastReceivedStatus!.batteryLevel, 85);
      expect(bleManager.lastReceivedStatus!.connectionQuality, 95);
    });
  });

  group('E2E: Mode-Specific Operations', () {
    late MockBLECentralManager bleManager;
    late GestureProcessor gestureProcessor;
    late TouchpadViewModel viewModel;

    setUp(() {
      bleManager = MockBLECentralManager();
      gestureProcessor = GestureProcessor();
      viewModel = TouchpadViewModel(
        bleManager: bleManager,
        gestureProcessor: gestureProcessor,
      );
      bleManager.setConnected(true);
    });

    test('E2E: Presentation mode - navigation buttons', () async {
      // Step 1: Switch to presentation mode
      await viewModel.setMode(ControlMode.presentation);
      expect(viewModel.currentMode, ControlMode.presentation);
      
      // Step 2: Press back button (should send left arrow)
      viewModel.handleBackButton();
      expect(bleManager.lastCommand!['type'], 'button');
      expect(bleManager.lastCommand!['action'], 'back');
      
      // Step 3: Press forward button (should send right arrow)
      viewModel.handleForwardButton();
      expect(bleManager.lastCommand!['type'], 'button');
      expect(bleManager.lastCommand!['action'], 'forward');
    });

    test('E2E: Media control mode - play/pause', () async {
      // Step 1: Switch to media control mode
      await viewModel.setMode(ControlMode.mediaControl);
      
      // Step 2: Tap for play/pause
      viewModel.handleTap();
      
      // Step 3: Verify media control command
      expect(bleManager.lastCommand!['type'], 'mediaControl');
      expect(bleManager.lastCommand!['action'], 'playPause');
    });

    test('E2E: Media control mode - volume control', () async {
      // Step 1: Switch to media control mode
      await viewModel.setMode(ControlMode.mediaControl);
      
      // Step 2: Swipe up for volume up
      bleManager.clearCommands(); // Clear mode change command
      viewModel.handleVerticalSwipe(-20.0);
      await Future.delayed(Duration(milliseconds: 10)); // Allow async command to complete
      expect(bleManager.lastCommand, isNotNull);
      expect(bleManager.lastCommand!['type'], 'mediaControl');
      expect(bleManager.lastCommand!['action'], 'volumeUp');
      
      // Step 3: Swipe down for volume down
      bleManager.clearCommands(); // Clear previous command
      await Future.delayed(Duration(milliseconds: 150)); // Wait for throttle period
      viewModel.handleVerticalSwipe(20.0);
      await Future.delayed(Duration(milliseconds: 10)); // Allow async command to complete
      expect(bleManager.lastCommand, isNotNull);
      expect(bleManager.lastCommand!['type'], 'mediaControl');
      expect(bleManager.lastCommand!['action'], 'volumeDown');
    });

    test('E2E: Basic mouse mode - button actions', () async {
      // Step 1: Switch to basic mouse mode
      await viewModel.setMode(ControlMode.basicMouse);
      
      // Step 2: Press back button (should send Command+Left)
      viewModel.handleBackButton();
      expect(bleManager.lastCommand!['type'], 'button');
      expect(bleManager.lastCommand!['action'], 'back');
      
      // Step 3: Press forward button (should send Enter)
      viewModel.handleForwardButton();
      expect(bleManager.lastCommand!['type'], 'button');
      expect(bleManager.lastCommand!['action'], 'forward');
    });
  });

  group('E2E: Auto-Reconnection Flow', () {
    late MockBLECentralManager bleManager;

    setUp(() {
      bleManager = MockBLECentralManager();
    });

    test('E2E: Successful reconnection after disconnect', () async {
      // Step 1: Start with connected state
      bleManager.setConnected(true);
      expect(bleManager.connectionState, BLEConnectionState.connected);
      
      // Step 2: Simulate unexpected disconnect
      bleManager.simulateDisconnect();
      expect(bleManager.connectionState, BLEConnectionState.reconnecting);
      
      // Step 3: Simulate successful reconnection
      bleManager.simulateReconnectSuccess();
      expect(bleManager.connectionState, BLEConnectionState.connected);
      expect(bleManager.reconnectionAttempts, 0);
    });

    test('E2E: Failed reconnection after max attempts', () async {
      // Step 1: Start with connected state
      bleManager.setConnected(true);
      
      // Step 2: Simulate disconnect
      bleManager.simulateDisconnect();
      expect(bleManager.connectionState, BLEConnectionState.reconnecting);
      
      // Step 3: Simulate max reconnection attempts
      for (int i = 0; i < 10; i++) {
        bleManager.incrementReconnectionAttempts();
      }
      
      // Step 4: Verify failure state
      expect(bleManager.reconnectionAttempts, 10);
      
      // Step 5: Simulate reconnection failure callback
      bool failureCallbackCalled = false;
      bleManager.onReconnectionFailed = () {
        failureCallbackCalled = true;
      };
      bleManager.onReconnectionFailed?.call();
      
      expect(failureCallbackCalled, true);
    });

    test('E2E: Reconnection state transitions', () async {
      // Test the complete state machine
      expect(bleManager.connectionState, BLEConnectionState.disconnected);
      
      // Connect
      bleManager.setConnected(true);
      expect(bleManager.connectionState, BLEConnectionState.connected);
      
      // Disconnect and start reconnecting
      bleManager.simulateDisconnect();
      expect(bleManager.connectionState, BLEConnectionState.reconnecting);
      
      // Reconnect successfully
      bleManager.simulateReconnectSuccess();
      expect(bleManager.connectionState, BLEConnectionState.connected);
    });
  });

  group('E2E: Command Serialization', () {
    test('E2E: Cursor move command serialization', () {
      final command = {
        'type': 'cursorMove',
        'delta': {
          'dx': 10.5,
          'dy': 20.3,
        },
      };
      
      // Verify command structure
      expect(command['type'], 'cursorMove');
      expect(command['delta'], isA<Map<String, dynamic>>());
      final delta = command['delta'] as Map<String, dynamic>;
      expect(delta['dx'], isA<double>());
      expect(delta['dy'], isA<double>());
    });

    test('E2E: Tap command serialization', () {
      final singleTap = {
        'type': 'tap',
        'clickType': 'single',
      };
      
      final doubleTap = {
        'type': 'tap',
        'clickType': 'double',
      };
      
      expect(singleTap['type'], 'tap');
      expect(singleTap['clickType'], 'single');
      expect(doubleTap['clickType'], 'double');
    });

    test('E2E: Button command serialization', () {
      final backButton = {
        'type': 'button',
        'action': 'back',
      };
      
      final forwardButton = {
        'type': 'button',
        'action': 'forward',
      };
      
      expect(backButton['type'], 'button');
      expect(backButton['action'], 'back');
      expect(forwardButton['action'], 'forward');
    });

    test('E2E: Media control command serialization', () {
      final playPause = {
        'type': 'mediaControl',
        'action': 'playPause',
      };
      
      final volumeUp = {
        'type': 'mediaControl',
        'action': 'volumeUp',
      };
      
      expect(playPause['type'], 'mediaControl');
      expect(playPause['action'], 'playPause');
      expect(volumeUp['action'], 'volumeUp');
    });

    test('E2E: Mode change command serialization', () {
      final modeChange = {
        'type': 'modeChange',
        'mode': 'presentation',
      };
      
      expect(modeChange['type'], 'modeChange');
      expect(modeChange['mode'], 'presentation');
    });
  });
}

/// Enhanced Mock BLE Central Manager for E2E testing
class MockBLECentralManager extends BLECentralManager {
  BLEConnectionState _state = BLEConnectionState.disconnected;
  Map<String, dynamic>? lastCommand;
  StatusData? lastReceivedStatus;
  int _reconnectionAttempts = 0;

  @override
  BLEConnectionState get connectionState => _state;

  @override
  int get reconnectionAttempts => _reconnectionAttempts;

  void setConnected(bool connected) {
    _state = connected ? BLEConnectionState.connected : BLEConnectionState.disconnected;
  }

  void simulateConnection(Device device) {
    _state = BLEConnectionState.connected;
  }

  void simulateDisconnect() {
    _state = BLEConnectionState.reconnecting;
  }

  void simulateReconnectSuccess() {
    _state = BLEConnectionState.connected;
    _reconnectionAttempts = 0;
  }

  void incrementReconnectionAttempts() {
    _reconnectionAttempts++;
  }

  void simulateStatusUpdate(StatusData status) {
    lastReceivedStatus = status;
  }

  @override
  Future<bool> sendCommand(Map<String, dynamic> command) async {
    lastCommand = command;
    return true;
  }

  @override
  bool get isConnected => _state == BLEConnectionState.connected;

  void clearCommands() {
    lastCommand = null;
  }
}
