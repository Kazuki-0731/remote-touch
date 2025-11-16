import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../models/command.dart';
import '../services/ble_central_manager.dart';
import '../services/gesture_processor.dart';

/// ViewModel for the touchpad screen
/// Handles gesture processing, BLE communication, and mode management
/// 
/// Requirements:
/// - 1.1: Process swipe gestures and send cursor movement commands
/// - 2.1: Process tap gestures and send click commands
/// - 7.1, 7.2, 7.3: Manage control modes (presentation, media, basicMouse)
/// - 11.1, 11.2: Implement idle detection and power management
class TouchpadViewModel extends ChangeNotifier {
  final BLECentralManager _bleManager;
  final GestureProcessor _gestureProcessor;

  // Control mode state
  ControlMode _currentMode = ControlMode.basicMouse;

  // Idle detection
  DateTime _lastInteractionTime = DateTime.now();
  Timer? _idleCheckTimer;
  bool _isIdle = false;
  static const Duration _idleTimeout = Duration(seconds: 60);
  static const Duration _idleCheckInterval = Duration(seconds: 5);

  // Command throttling for performance
  DateTime? _lastCommandSentTime;
  static const Duration _minCommandInterval = Duration(milliseconds: 16);

  TouchpadViewModel({
    required BLECentralManager bleManager,
    required GestureProcessor gestureProcessor,
  })  : _bleManager = bleManager,
        _gestureProcessor = gestureProcessor {
    _startIdleDetection();
  }

  // Getters
  ControlMode get currentMode => _currentMode;
  double get sensitivity => _gestureProcessor.sensitivity;
  bool get isIdle => _isIdle;
  bool get isConnected => _bleManager.connectionState == BLEConnectionState.connected;

  /// Handle swipe gesture on touchpad
  /// 
  /// Requirements:
  /// - 1.1: Convert swipe to cursor movement and send via BLE
  /// - 1.3: Send data within 16ms intervals
  /// - 9.2, 9.3: In media mode, vertical swipes control volume
  void handleSwipe({
    required Offset translation,
    required Offset velocity,
  }) {
    _updateLastInteraction();

    // In media control mode, handle vertical swipes for volume control
    if (_currentMode == ControlMode.mediaControl) {
      // Check if this is primarily a vertical swipe
      if (translation.dy.abs() > translation.dx.abs() && translation.dy.abs() > 5) {
        handleVerticalSwipe(translation.dy);
        return;
      }
      // Ignore horizontal swipes in media mode
      return;
    }

    // Throttle commands to maintain 16ms interval (60fps)
    final now = DateTime.now();
    if (_lastCommandSentTime != null) {
      final timeSinceLastCommand = now.difference(_lastCommandSentTime!);
      if (timeSinceLastCommand < _minCommandInterval) {
        return; // Skip this command to maintain throttling
      }
    }

    // Process the swipe gesture
    final command = _gestureProcessor.processSwipe(
      translation: translation,
      velocity: velocity,
    );

    // Send command via BLE
    _sendCommand(command.toJson());
    _lastCommandSentTime = now;
  }

  /// Handle tap gesture on touchpad
  /// 
  /// Requirements:
  /// - 2.1: Send single tap as click command
  /// - 2.3: Send double tap as double-click command
  /// - 9.1: In media mode, tap sends play/pause
  void handleTap() {
    _updateLastInteraction();

    // In media control mode, tap means play/pause
    if (_currentMode == ControlMode.mediaControl) {
      final command = MediaControlCommand(action: MediaAction.playPause);
      _sendCommand(command.toJson());
      return;
    }

    // In other modes, process as regular tap
    final tapCommand = _gestureProcessor.processTap();
    if (tapCommand != null) {
      _sendCommand(tapCommand.toJson());
    }
  }

  /// Handle vertical swipe in media control mode
  /// 
  /// Requirements:
  /// - 9.2: Up swipe increases volume
  /// - 9.3: Down swipe decreases volume
  void handleVerticalSwipe(double deltaY) {
    if (_currentMode != ControlMode.mediaControl) {
      return;
    }

    _updateLastInteraction();

    // Throttle volume commands to avoid flooding
    final now = DateTime.now();
    if (_lastCommandSentTime != null) {
      final timeSinceLastCommand = now.difference(_lastCommandSentTime!);
      if (timeSinceLastCommand < const Duration(milliseconds: 100)) {
        return; // Throttle volume commands more aggressively
      }
    }

    // Determine if swipe is up or down (negative deltaY = up, positive = down)
    final action = deltaY < 0 ? MediaAction.volumeUp : MediaAction.volumeDown;
    final command = MediaControlCommand(action: action);
    _sendCommand(command.toJson());
    _lastCommandSentTime = now;
  }

  /// Handle back button press
  /// 
  /// Requirements:
  /// - 3.1: Send mode-appropriate back command
  void handleBackButton() {
    _updateLastInteraction();
    final command = ButtonCommand(action: ButtonAction.back);
    _sendCommand(command.toJson());
  }

  /// Handle forward button press
  /// 
  /// Requirements:
  /// - 3.2: Send mode-appropriate forward command
  void handleForwardButton() {
    _updateLastInteraction();
    final command = ButtonCommand(action: ButtonAction.forward);
    _sendCommand(command.toJson());
  }

  /// Change the control mode
  /// 
  /// Requirements:
  /// - 7.1: Set presentation mode
  /// - 7.2: Set media control mode
  /// - 7.3: Set basic mouse mode
  /// - 7.4: Send mode change to macOS
  Future<void> setMode(ControlMode mode) async {
    if (_currentMode == mode) return;

    _currentMode = mode;
    _updateLastInteraction();

    // Send mode change command to macOS
    final command = ModeChangeCommand(mode: mode);
    await _sendCommand(command.toJson());

    notifyListeners();
  }

  /// Update sensitivity setting
  /// 
  /// Requirements:
  /// - 8.1: Allow sensitivity adjustment 0.5x to 3.0x
  /// - 8.4: Apply sensitivity to cursor movement
  void updateSensitivity(double sensitivity) {
    // Clamp sensitivity to valid range
    final clampedSensitivity = sensitivity.clamp(0.5, 3.0);
    _gestureProcessor.updateSensitivity(clampedSensitivity);
    notifyListeners();
  }

  /// Send a command via BLE
  Future<void> _sendCommand(Map<String, dynamic> commandJson) async {
    if (!isConnected) {
      debugPrint('Cannot send command: not connected');
      return;
    }

    try {
      await _bleManager.sendCommand(commandJson);
    } catch (e) {
      debugPrint('Error sending command: $e');
    }
  }

  /// Update last interaction time and exit idle state if needed
  void _updateLastInteraction() {
    _lastInteractionTime = DateTime.now();
    
    if (_isIdle) {
      _exitIdleState();
    }
  }

  /// Start idle detection timer
  /// 
  /// Requirements:
  /// - 11.1: Detect 60 seconds of inactivity
  void _startIdleDetection() {
    _idleCheckTimer?.cancel();
    _idleCheckTimer = Timer.periodic(_idleCheckInterval, (_) {
      _checkIdleState();
    });
  }

  /// Check if app should enter idle state
  void _checkIdleState() {
    final now = DateTime.now();
    final timeSinceLastInteraction = now.difference(_lastInteractionTime);

    if (!_isIdle && timeSinceLastInteraction >= _idleTimeout) {
      _enterIdleState();
    }
  }

  /// Enter idle state
  /// 
  /// Requirements:
  /// - 11.2: Reduce BLE data transmission frequency in idle state
  void _enterIdleState() {
    _isIdle = true;
    debugPrint('Entering idle state');
    notifyListeners();
    
    // Note: Actual BLE transmission frequency reduction would be handled
    // by the BLE manager or at a lower level. This flag can be used
    // to modify behavior in the UI or reduce command sending.
  }

  /// Exit idle state
  /// 
  /// Requirements:
  /// - 11.3, 11.4: Resume normal operation when user interacts
  void _exitIdleState() {
    _isIdle = false;
    debugPrint('Exiting idle state');
    notifyListeners();
  }

  /// Reset tap detection state (useful when gesture is cancelled)
  void resetTapState() {
    _gestureProcessor.resetTapState();
  }

  @override
  void dispose() {
    _idleCheckTimer?.cancel();
    super.dispose();
  }
}
