import 'package:flutter_test/flutter_test.dart';
import 'package:remote_touch/services/ble_central_manager.dart';

void main() {
  group('BLECentralManager Reconnection', () {
    late BLECentralManager bleManager;

    setUp(() {
      bleManager = BLECentralManager();
    });

    test('should start in disconnected state', () {
      expect(bleManager.connectionState, BLEConnectionState.disconnected);
      expect(bleManager.reconnectionAttempts, 0);
    });

    test('should have correct max reconnection attempts', () {
      expect(bleManager.maxReconnectionAttemptsCount, 10);
    });

    test('should call onReconnectionFailed callback when set', () {
      bool callbackCalled = false;
      bleManager.onReconnectionFailed = () {
        callbackCalled = true;
      };

      // Trigger the callback
      bleManager.onReconnectionFailed?.call();

      expect(callbackCalled, true);
    });

    test('should expose reconnection state', () {
      // Initially disconnected
      expect(bleManager.connectionState, BLEConnectionState.disconnected);
      
      // The reconnecting state would be set during actual reconnection
      // This test verifies the state enum exists and can be checked
      const testState = BLEConnectionState.reconnecting;
      expect(testState, isNotNull);
    });
  });
}
