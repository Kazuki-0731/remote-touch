import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../viewmodels/connection_viewmodel.dart';
import '../models/device.dart';
import '../services/ble_central_manager.dart';

/// Device list and pairing view
/// 
/// Requirements:
/// - 4.1: Scan for and discover BLE devices
/// - 4.3: Handle pairing with pairing code input
/// - 6.2: Display and select registered devices
/// - 6.3: Manage registered devices (remove)
class DeviceListView extends StatefulWidget {
  const DeviceListView({super.key});

  @override
  State<DeviceListView> createState() => _DeviceListViewState();
}

class _DeviceListViewState extends State<DeviceListView> {
  bool _isScanning = false;
  final TextEditingController _pairingCodeController = TextEditingController();

  @override
  void dispose() {
    _pairingCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Devices'),
        backgroundColor: Colors.grey[850],
        elevation: 0,
      ),
      body: Consumer<ConnectionViewModel>(
        builder: (context, connectionVM, child) {
          return Column(
            children: [
              // Registered devices section
              _buildRegisteredDevicesSection(connectionVM),
              
              // Divider
              Container(
                height: 8,
                color: Colors.grey[850],
              ),
              
              // Available devices section
              Expanded(
                child: _buildAvailableDevicesSection(connectionVM),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build the registered devices section
  Widget _buildRegisteredDevicesSection(ConnectionViewModel connectionVM) {
    return Container(
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registered Devices',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${connectionVM.registeredDevices.length}/5',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          if (connectionVM.registeredDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Center(
                child: Text(
                  'No registered devices.\nScan and connect to add devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: connectionVM.registeredDevices.length,
              itemBuilder: (context, index) {
                final device = connectionVM.registeredDevices[index];
                return _buildRegisteredDeviceItem(device, connectionVM);
              },
            ),
        ],
      ),
    );
  }

  /// Build a registered device list item
  Widget _buildRegisteredDeviceItem(Device device, ConnectionViewModel connectionVM) {
    final isConnected = connectionVM.selectedDevice?.id == device.id &&
        connectionVM.isConnected;
    final isConnecting = connectionVM.selectedDevice?.id == device.id &&
        connectionVM.connectionState == BLEConnectionState.connecting;
    final isReconnecting = connectionVM.selectedDevice?.id == device.id &&
        connectionVM.connectionState == BLEConnectionState.reconnecting;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isConnected ? Colors.blue.withValues(alpha: 0.2) : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          isConnected ? Icons.bluetooth_connected : Icons.devices,
          color: isConnected ? Colors.blue : Colors.grey[400],
          size: 28,
        ),
        title: Text(
          device.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isConnected
                  ? 'Connected'
                  : isReconnecting
                      ? 'Reconnecting...'
                      : isConnecting
                          ? 'Connecting...'
                          : 'Last connected: ${_formatDate(device.lastConnected)}',
              style: TextStyle(
                color: isConnected
                    ? Colors.blue[300]
                    : isReconnecting
                        ? Colors.orange[300]
                        : isConnecting
                            ? Colors.orange[300]
                            : Colors.grey[500],
                fontSize: 12,
              ),
            ),
            // Show reconnection attempt count
            // Requirements: 12.1, 12.2 - Display reconnection progress
            if (isReconnecting)
              Text(
                'Attempt ${connectionVM.reconnectionAttempts}/${connectionVM.maxReconnectionAttempts}',
                style: TextStyle(
                  color: Colors.orange[200],
                  fontSize: 10,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isConnecting || isReconnecting)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            else if (!isConnected)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                onPressed: () => _confirmRemoveDevice(device, connectionVM),
              ),
          ],
        ),
        onTap: isConnected || isConnecting || isReconnecting
            ? null
            : () => _connectToRegisteredDevice(device, connectionVM),
      ),
    );
  }

  /// Build the available devices section (scan results)
  Widget _buildAvailableDevicesSection(ConnectionViewModel connectionVM) {
    return Container(
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Devices',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : () => _startScanning(connectionVM),
                  icon: Icon(
                    _isScanning ? Icons.stop : Icons.search,
                    size: 18,
                  ),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScanning ? Colors.orange : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isScanning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          
          Expanded(
            child: connectionVM.discoveredDevices.isEmpty && !_isScanning
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No devices found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Scan" to search for devices',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: connectionVM.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = connectionVM.discoveredDevices[index];
                      return _buildDiscoveredDeviceItem(device, connectionVM);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Build a discovered device list item
  Widget _buildDiscoveredDeviceItem(
    BluetoothDevice device,
    ConnectionViewModel connectionVM,
  ) {
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';
    
    // Check if this device is already registered
    final isRegistered = connectionVM.registeredDevices.any(
      (d) => d.peripheralUUID == device.remoteId.str,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          Icons.bluetooth,
          color: Colors.blue[300],
          size: 28,
        ),
        title: Text(
          deviceName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          isRegistered ? 'Already registered' : device.remoteId.str,
          style: TextStyle(
            color: isRegistered ? Colors.orange[300] : Colors.grey[500],
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[600],
          size: 16,
        ),
        onTap: () => _connectToDiscoveredDevice(device, connectionVM),
      ),
    );
  }

  /// Start scanning for devices
  Future<void> _startScanning(ConnectionViewModel connectionVM) async {
    setState(() {
      _isScanning = true;
    });

    await connectionVM.startScanning();

    // Stop scanning after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        _stopScanning(connectionVM);
      }
    });
  }

  /// Stop scanning for devices
  Future<void> _stopScanning(ConnectionViewModel connectionVM) async {
    await connectionVM.stopScanning();
    
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  /// Connect to a registered device
  Future<void> _connectToRegisteredDevice(
    Device device,
    ConnectionViewModel connectionVM,
  ) async {
    // Show loading dialog
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            Text(
              'Connecting to ${device.name}...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    final success = await connectionVM.connectToRegisteredDevice(device.id);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      // Connection successful, go back to touchpad view
      Navigator.of(context).pop();
    } else {
      // Show error
      _showErrorDialog(
        'Connection Failed',
        connectionVM.pairingError ?? 'Could not connect to device',
      );
    }
  }

  /// Connect to a discovered device
  Future<void> _connectToDiscoveredDevice(
    BluetoothDevice device,
    ConnectionViewModel connectionVM,
  ) async {
    // Stop scanning first
    if (_isScanning) {
      await _stopScanning(connectionVM);
    }

    // Show pairing dialog
    _showPairingDialog(device, connectionVM);
  }

  /// Show pairing code input dialog
  void _showPairingDialog(
    BluetoothDevice device,
    ConnectionViewModel connectionVM,
  ) {
    _pairingCodeController.clear();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          'Pair Device',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 6-digit pairing code displayed on your Mac:',
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pairingCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            if (connectionVM.pairingError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        connectionVM.pairingError!,
                        style: TextStyle(color: Colors.red[300], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: connectionVM.isPairing
                ? null
                : () => _submitPairingCode(device, connectionVM),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: connectionVM.isPairing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Pair'),
          ),
        ],
      ),
    );
  }

  /// Submit pairing code and connect
  Future<void> _submitPairingCode(
    BluetoothDevice device,
    ConnectionViewModel connectionVM,
  ) async {
    final code = _pairingCodeController.text.trim();
    
    if (code.length != 6) {
      _showErrorDialog('Invalid Code', 'Please enter a 6-digit pairing code');
      return;
    }

    // First connect to the device
    final connected = await connectionVM.connectToDevice(device);
    
    if (!connected) {
      if (!mounted) return;
      _showErrorDialog(
        'Connection Failed',
        connectionVM.pairingError ?? 'Could not connect to device',
      );
      return;
    }

    // Then send the pairing code
    final paired = await connectionVM.sendPairingCode(code);
    
    if (!mounted) return;
    
    if (paired) {
      // Success! Close pairing dialog and return to touchpad
      Navigator.of(context).pop(); // Close pairing dialog
      Navigator.of(context).pop(); // Return to touchpad view
      
      _showSuccessSnackBar('Successfully paired with ${device.platformName}');
    } else {
      // Show error in the dialog (it will update via connectionVM.pairingError)
      // Don't close the dialog, let user try again
    }
  }

  /// Confirm device removal
  void _confirmRemoveDevice(Device device, ConnectionViewModel connectionVM) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(
          'Remove Device',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove "${device.name}"?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              connectionVM.removeDevice(device.id);
              Navigator.of(context).pop();
              _showSuccessSnackBar('Device removed');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[300]),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[300]),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.grey[850],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
