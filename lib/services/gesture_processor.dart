import 'dart:ui';
import '../models/command.dart';

/// Processes touch gestures and converts them to commands
class GestureProcessor {
  double _sensitivity;
  DateTime? _lastTapTime;
  static const Duration _doubleTapThreshold = Duration(milliseconds: 300);

  GestureProcessor({double sensitivity = 1.0}) : _sensitivity = sensitivity;

  /// Updates the sensitivity setting
  void updateSensitivity(double sensitivity) {
    _sensitivity = sensitivity;
  }

  /// Gets the current sensitivity
  double get sensitivity => _sensitivity;

  /// Processes a swipe gesture and returns a cursor movement command
  /// 
  /// Requirements:
  /// - 1.1: Convert swipe to cursor movement
  /// - 1.4: Apply sensitivity (0.5x to 3.0x)
  /// - 8.4: Use stored sensitivity setting
  CursorMoveCommand processSwipe({
    required Offset translation,
    required Offset velocity,
  }) {
    // Calculate base cursor delta from translation
    final baseDelta = _calculateCursorDelta(
      translation: translation,
      velocity: velocity,
    );

    // Apply sensitivity multiplier
    final adjustedDelta = Offset(
      baseDelta.dx * _sensitivity,
      baseDelta.dy * _sensitivity,
    );

    return CursorMoveCommand(delta: adjustedDelta);
  }

  /// Processes a tap gesture and returns a tap command
  /// 
  /// Requirements:
  /// - 2.1: Detect single tap
  /// - 2.3: Detect double tap within 300ms
  TapCommand? processTap() {
    final now = DateTime.now();
    
    // Check if this is a double tap
    if (_lastTapTime != null) {
      final timeSinceLastTap = now.difference(_lastTapTime!);
      
      if (timeSinceLastTap <= _doubleTapThreshold) {
        // This is a double tap
        _lastTapTime = null; // Reset for next tap sequence
        return TapCommand(type: ClickType.double_);
      }
    }
    
    // Record this tap time for potential double tap detection
    _lastTapTime = now;
    
    // Return single tap command
    return TapCommand(type: ClickType.single);
  }

  /// Resets the tap detection state (useful when gesture is cancelled)
  void resetTapState() {
    _lastTapTime = null;
  }

  /// Calculates cursor movement delta from translation and velocity
  /// 
  /// This method combines translation (distance moved) with velocity
  /// to create smooth and responsive cursor movement.
  Offset _calculateCursorDelta({
    required Offset translation,
    required Offset velocity,
  }) {
    // Base calculation uses translation directly
    // Velocity can be used to add momentum in future enhancements
    
    // For now, use translation as the primary input
    // The translation represents the finger movement on screen
    return translation;
  }
}

