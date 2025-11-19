import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/touchpad_viewmodel.dart';
import '../viewmodels/connection_viewmodel.dart';
import '../models/models.dart';
import '../services/device_storage.dart';
import 'mode_selection_view.dart';

/// Settings view for app configuration
/// 
/// Requirements:
/// - 8.1: Sensitivity adjustment slider (0.5x to 3.0x)
/// - 8.2: Save and load sensitivity settings
/// - Device management UI for saved devices
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late DeviceStorage _deviceStorage;
  List<Device> _savedDevices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    _deviceStorage = await DeviceStorage.create();
    await _loadDevices();
  }

  Future<void> _loadDevices() async {
    final devices = await _deviceStorage.loadDevices();
    setState(() {
      _savedDevices = devices;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Control Mode Section
            _buildSectionHeader('Control Mode'),
            _buildModeSelector(context),
            
            const SizedBox(height: 32),

            // Sensitivity Section
            _buildSectionHeader('Touchpad Sensitivity'),
            _buildSensitivitySlider(context),
            
            const SizedBox(height: 32),

            // Saved Devices Section
            _buildSectionHeader('Saved Devices'),
            _buildDevicesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return Consumer<TouchpadViewModel>(
      builder: (context, viewModel, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ModeSelectionView(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getModeIcon(viewModel.currentMode),
                    color: Colors.blue,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getModeDisplayName(viewModel.currentMode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to change mode',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensitivitySlider(BuildContext context) {
    return Consumer<TouchpadViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current sensitivity value
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sensitivity',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${viewModel.sensitivity.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Slider
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: Colors.blue,
                  inactiveTrackColor: Colors.grey[700],
                  thumbColor: Colors.blue,
                  overlayColor: Colors.blue.withOpacity(0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: viewModel.sensitivity,
                  min: 0.5,
                  max: 3.0,
                  divisions: 25, // 0.1 increments
                  onChanged: (value) {
                    viewModel.updateSensitivity(value);
                    _saveSensitivity(value);
                  },
                ),
              ),

              // Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0.5x (Slow)',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '3.0x (Fast)',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Adjust how fast the cursor moves in response to your swipes',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDevicesList(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_savedDevices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.devices_other,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No saved devices',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to a Mac to save it',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Device count info
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${_savedDevices.length} of 5 devices saved',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),

        // Device list
        ..._savedDevices.map((device) => _buildDeviceCard(context, device)),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, Device device) {
    return Consumer<ConnectionViewModel>(
      builder: (context, connectionVM, child) {
        final isConnected = connectionVM.selectedDevice?.id == device.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isConnected ? Colors.blue : Colors.grey[700]!,
              width: isConnected ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.computer,
                color: isConnected ? Colors.blue : Colors.grey[400],
                size: 24,
              ),
            ),
            title: Text(
              device.name,
              style: TextStyle(
                color: isConnected ? Colors.blue : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              isConnected
                  ? 'Connected'
                  : 'Last connected: ${_formatDate(device.lastConnected)}',
              style: TextStyle(
                color: isConnected ? Colors.blue[300] : Colors.grey[400],
                fontSize: 14,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red[300],
              ),
              onPressed: () => _confirmDeleteDevice(context, device),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteDevice(BuildContext context, Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Remove Device',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove "${device.name}"?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: Colors.red[300]),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deviceStorage.removeDevice(device);
      await _loadDevices();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${device.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveSensitivity(double sensitivity) async {
    final settings = await _deviceStorage.loadSettings();
    final updatedSettings = settings.copyWith(sensitivity: sensitivity);
    await _deviceStorage.saveSettings(updatedSettings);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  IconData _getModeIcon(ControlMode mode) {
    switch (mode) {
      case ControlMode.presentation:
        return Icons.present_to_all;
      case ControlMode.mediaControl:
        return Icons.music_note;
      case ControlMode.basicMouse:
        return Icons.mouse;
    }
  }

  String _getModeDisplayName(ControlMode mode) {
    switch (mode) {
      case ControlMode.presentation:
        return 'Presentation Mode';
      case ControlMode.mediaControl:
        return 'Media Control Mode';
      case ControlMode.basicMouse:
        return 'Basic Mouse Mode';
    }
  }
}
