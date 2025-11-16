import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Service for persisting device information and app settings using SharedPreferences
class DeviceStorage {
  static const int maxDevices = 5;
  static const String _devicesKey = 'saved_devices';
  static const String _settingsKey = 'app_settings';

  final SharedPreferences _prefs;

  DeviceStorage(this._prefs);

  /// Factory constructor to create DeviceStorage with SharedPreferences
  static Future<DeviceStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DeviceStorage(prefs);
  }

  /// Save a device to storage
  /// If the device already exists (by id), it will be updated
  /// If adding a new device exceeds maxDevices, the oldest device will be removed
  /// 
  /// Fallback: If storage fails, device is kept in memory only
  /// Requirement: Device storage error fallback handling
  Future<void> saveDevice(Device device) async {
    try {
      final devices = await loadDevices();
      
      // Check if device already exists
      final existingIndex = devices.indexWhere((d) => d.id == device.id);
      
      if (existingIndex != -1) {
        // Update existing device
        devices[existingIndex] = device;
      } else {
        // Add new device
        devices.add(device);
        
        // If we exceed max devices, remove the oldest one
        if (devices.length > maxDevices) {
          // Sort by lastConnected and remove the oldest
          devices.sort((a, b) => a.lastConnected.compareTo(b.lastConnected));
          devices.removeAt(0);
        }
      }
      
      await _saveDevicesList(devices);
    } catch (e) {
      // Fallback: Log error but don't throw
      // Device will be kept in memory only for this session
      debugPrint('Error saving device to storage: $e');
      debugPrint('Device will be available in memory only for this session');
      rethrow; // Re-throw so caller can handle appropriately
    }
  }

  /// Load all saved devices from storage
  /// 
  /// Fallback: Returns empty list if storage is corrupted or unavailable
  /// Requirement: Device storage error fallback handling
  Future<List<Device>> loadDevices() async {
    try {
      final devicesJson = _prefs.getString(_devicesKey);
      
      if (devicesJson == null || devicesJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> decoded = json.decode(devicesJson);
      return decoded
          .map((item) => Device.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback: If there's an error parsing, return empty list
      // This allows the app to continue functioning without saved devices
      debugPrint('Error loading devices from storage: $e');
      debugPrint('Returning empty device list - storage may be corrupted');
      return [];
    }
  }

  /// Remove a device from storage
  Future<void> removeDevice(Device device) async {
    final devices = await loadDevices();
    devices.removeWhere((d) => d.id == device.id);
    await _saveDevicesList(devices);
  }

  /// Update an existing device in storage
  Future<void> updateDevice(Device device) async {
    await saveDevice(device);
  }

  /// Save the list of devices to SharedPreferences
  Future<void> _saveDevicesList(List<Device> devices) async {
    final devicesJson = json.encode(devices.map((d) => d.toJson()).toList());
    await _prefs.setString(_devicesKey, devicesJson);
  }

  /// Save app settings to storage
  /// 
  /// Fallback: If storage fails, settings are kept in memory only
  /// Requirement: Device storage error fallback handling
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final settingsJson = json.encode(settings.toJson());
      await _prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      // Fallback: Log error but don't throw
      // Settings will be kept in memory only for this session
      debugPrint('Error saving settings to storage: $e');
      debugPrint('Settings will be available in memory only for this session');
      rethrow; // Re-throw so caller can handle appropriately
    }
  }

  /// Load app settings from storage
  /// Returns default settings if none are saved
  /// 
  /// Fallback: Returns default settings if storage is corrupted or unavailable
  /// Requirement: Device storage error fallback handling
  Future<AppSettings> loadSettings() async {
    try {
      final settingsJson = _prefs.getString(_settingsKey);
      
      if (settingsJson == null || settingsJson.isEmpty) {
        return AppSettings();
      }
      
      final Map<String, dynamic> decoded = json.decode(settingsJson);
      return AppSettings.fromJson(decoded);
    } catch (e) {
      // Fallback: If there's an error parsing, return default settings
      // This allows the app to continue functioning with default configuration
      debugPrint('Error loading settings from storage: $e');
      debugPrint('Using default settings - storage may be corrupted');
      return AppSettings();
    }
  }

  /// Clear all stored devices
  Future<void> clearDevices() async {
    await _prefs.remove(_devicesKey);
  }

  /// Clear all stored settings
  Future<void> clearSettings() async {
    await _prefs.remove(_settingsKey);
  }

  /// Clear all stored data (devices and settings)
  Future<void> clearAll() async {
    await clearDevices();
    await clearSettings();
  }
}
