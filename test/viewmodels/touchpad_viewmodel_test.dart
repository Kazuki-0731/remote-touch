import 'package:flutter_test/flutter_test.dart';
import 'package:remote_touch/models/command.dart';
import 'package:remote_touch/services/ble_central_manager.dart';
import 'package:remote_touch/services/gesture_processor.dart';
import 'package:remote_touch/viewmodels/touchpad_viewmodel.dart';
import 'dart:ui';

void main() {
  group('TouchpadViewModel Media Control Mode', () {
    late TouchpadViewModel viewModel;
    late MockBLECentralManager mockBLEManager;
    late GestureProcessor gestureProcessor;

    setUp(() {
      mockBLEManager = MockBLECentralManager();
      gestureProcessor = GestureProcessor();
      viewModel = TouchpadViewModel(
        bleManager: mockBLEManager,
        gestureProcessor: gestureProcessor,
      );
    });

    test('should set media control mode', () async {
      await viewModel.setMode(ControlMode.mediaControl);
      expect(viewModel.currentMode, ControlMode.mediaControl);
    });

    test('should handle tap as play/pause in media mode', () async {
      await viewModel.setMode(ControlMode.mediaControl);
      mockBLEManager.setConnected(true);
      
      viewModel.handleTap();
      
      expect(mockBLEManager.lastCommand, isNotNull);
      expect(mockBLEManager.lastCommand!['type'], 'mediaControl');
      expect(mockBLEManager.lastCommand!['action'], 'playPause');
    });

    test('should handle vertical swipe up as volume up in media mode', () async {
      await viewModel.setMode(ControlMode.mediaControl);
      mockBLEManager.setConnected(true);
      
      viewModel.handleVerticalSwipe(-10.0); // Negative = up
      
      expect(mockBLEManager.lastCommand, isNotNull);
      expect(mockBLEManager.lastCommand!['type'], 'mediaControl');
      expect(mockBLEManager.lastCommand!['action'], 'volumeUp');
    });

    test('should handle vertical swipe down as volume down in media mode', () async {
      await viewModel.setMode(ControlMode.mediaControl);
      mockBLEManager.setConnected(true);
      
      viewModel.handleVerticalSwipe(10.0); // Positive = down
      
      expect(mockBLEManager.lastCommand, isNotNull);
      expect(mockBLEManager.lastCommand!['type'], 'mediaControl');
      expect(mockBLEManager.lastCommand!['action'], 'volumeDown');
    });

    test('should ignore horizontal swipes in media mode', () async {
      await viewModel.setMode(ControlMode.mediaControl);
      mockBLEManager.setConnected(true);
      mockBLEManager.clearCommands();
      
      // Horizontal swipe (dx > dy)
      viewModel.handleSwipe(
        translation: const Offset(20.0, 2.0),
        velocity: const Offset(100.0, 10.0),
      );
      
      // Should not send cursor move command in media mode
      expect(mockBLEManager.commandCount, 0);
    });

    test('should handle vertical swipes for volume in media mode', () async {
      await viewModel.setMode(ControlMode.mediaControl);
      mockBLEManager.setConnected(true);
      mockBLEManager.clearCommands();
      
      // Vertical swipe up (dy < 0, |dy| > |dx|)
      viewModel.handleSwipe(
        translation: const Offset(2.0, -20.0),
        velocity: const Offset(10.0, -100.0),
      );
      
      expect(mockBLEManager.lastCommand, isNotNull);
      expect(mockBLEManager.lastCommand!['type'], 'mediaControl');
      expect(mockBLEManager.lastCommand!['action'], 'volumeUp');
    });
  });
}

/// Mock BLE Central Manager for testing
class MockBLECentralManager extends BLECentralManager {
  BLEConnectionState _state = BLEConnectionState.disconnected;
  Map<String, dynamic>? lastCommand;
  int commandCount = 0;

  @override
  BLEConnectionState get connectionState => _state;

  void setConnected(bool connected) {
    _state = connected ? BLEConnectionState.connected : BLEConnectionState.disconnected;
  }

  @override
  Future<bool> sendCommand(Map<String, dynamic> command) async {
    lastCommand = command;
    commandCount++;
    return true;
  }

  void clearCommands() {
    lastCommand = null;
    commandCount = 0;
  }
}
