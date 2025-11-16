import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remote_touch/models/models.dart';
import 'package:remote_touch/services/device_storage.dart';

void main() {
  group('DeviceStorage', () {
    late DeviceStorage storage;

    setUp(() async {
      // Set up mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = DeviceStorage(prefs);
    });

    test('should save and load a device', () async {
      final device = Device(
        id: 'test-id',
        name: 'Test Mac',
        peripheralUUID: 'uuid-123',
        lastConnected: DateTime.now(),
        isPaired: true,
      );

      await storage.saveDevice(device);
      final devices = await storage.loadDevices();

      expect(devices.length, 1);
      expect(devices.first.id, device.id);
      expect(devices.first.name, device.name);
    });

    test('should enforce maximum 5 devices limit', () async {
      // Add 6 devices
      for (int i = 0; i < 6; i++) {
        final device = Device(
          id: 'device-$i',
          name: 'Mac $i',
          peripheralUUID: 'uuid-$i',
          lastConnected: DateTime.now().add(Duration(minutes: i)),
          isPaired: true,
        );
        await storage.saveDevice(device);
      }

      final devices = await storage.loadDevices();

      // Should only have 5 devices
      expect(devices.length, 5);
      // The oldest device (device-0) should be removed
      expect(devices.any((d) => d.id == 'device-0'), false);
      // The newest device (device-5) should be present
      expect(devices.any((d) => d.id == 'device-5'), true);
    });

    test('should update existing device', () async {
      final device = Device(
        id: 'test-id',
        name: 'Test Mac',
        peripheralUUID: 'uuid-123',
        lastConnected: DateTime.now(),
        isPaired: false,
      );

      await storage.saveDevice(device);

      final updatedDevice = device.copyWith(isPaired: true);
      await storage.updateDevice(updatedDevice);

      final devices = await storage.loadDevices();

      expect(devices.length, 1);
      expect(devices.first.isPaired, true);
    });

    test('should remove a device', () async {
      final device = Device(
        id: 'test-id',
        name: 'Test Mac',
        peripheralUUID: 'uuid-123',
        lastConnected: DateTime.now(),
        isPaired: true,
      );

      await storage.saveDevice(device);
      await storage.removeDevice(device);

      final devices = await storage.loadDevices();
      expect(devices.length, 0);
    });

    test('should save and load app settings', () async {
      final settings = AppSettings(
        sensitivity: 2.5,
        idleTimeout: Duration(seconds: 120),
        autoReconnect: false,
        maxReconnectAttempts: 5,
      );

      await storage.saveSettings(settings);
      final loadedSettings = await storage.loadSettings();

      expect(loadedSettings.sensitivity, 2.5);
      expect(loadedSettings.idleTimeout.inSeconds, 120);
      expect(loadedSettings.autoReconnect, false);
      expect(loadedSettings.maxReconnectAttempts, 5);
    });

    test('should return default settings when none are saved', () async {
      final settings = await storage.loadSettings();

      expect(settings.sensitivity, 1.0);
      expect(settings.idleTimeout.inSeconds, 60);
      expect(settings.autoReconnect, true);
      expect(settings.maxReconnectAttempts, 10);
    });

    test('should clear all devices', () async {
      final device = Device(
        id: 'test-id',
        name: 'Test Mac',
        peripheralUUID: 'uuid-123',
        lastConnected: DateTime.now(),
        isPaired: true,
      );

      await storage.saveDevice(device);
      await storage.clearDevices();

      final devices = await storage.loadDevices();
      expect(devices.length, 0);
    });
  });
}
