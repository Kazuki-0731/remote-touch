import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/touchpad_viewmodel.dart';
import '../viewmodels/connection_viewmodel.dart';
import '../models/command.dart';
import '../services/ble_central_manager.dart';
import 'device_list_view.dart';
import 'settings_view.dart';

/// Main touchpad view for controlling the Mac
/// 
/// Requirements:
/// - 1.1: Swipe gestures for cursor movement
/// - 2.1: Single tap for click
/// - 2.3: Double tap for double-click
/// - 3.1, 3.2: Physical buttons for back/forward
/// - 5.1, 5.2: Display connection state
/// - 5.4: Display battery level
class TouchpadView extends StatefulWidget {
  const TouchpadView({super.key});

  @override
  State<TouchpadView> createState() => _TouchpadViewState();
}

class _TouchpadViewState extends State<TouchpadView> {
  // Tap detection state
  DateTime? _lastTapTime;
  static const Duration _doubleTapThreshold = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _setupReconnectionCallback();
  }

  /// Setup callback for reconnection failure notification
  /// Requirements: 12.4 - Show notification when reconnection fails
  void _setupReconnectionCallback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectionVM = Provider.of<ConnectionViewModel>(context, listen: false);
      connectionVM.onReconnectionFailed = () {
        if (mounted) {
          _showReconnectionFailedDialog();
        }
      };
    });
  }

  /// Show dialog when reconnection fails
  /// Requirements: 12.4 - Notify user and prompt for manual reconnection
  void _showReconnectionFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange[300]),
            const SizedBox(width: 8),
            Text(
              'Connection Lost',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Failed to reconnect after multiple attempts. Please check that your Mac is nearby and Bluetooth is enabled.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final connectionVM = Provider.of<ConnectionViewModel>(context, listen: false);
              await connectionVM.retryConnection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text('RemoteTouch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.devices),
            tooltip: 'Devices',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DeviceListView(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsView(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            _buildStatusBar(context),
            
            // Touchpad area
            Expanded(
              child: _buildTouchpadArea(context),
            ),
            
            // Control buttons
            _buildControlButtons(context),
          ],
        ),
      ),
    );
  }

  /// Build the status bar showing connection and battery
  Widget _buildStatusBar(BuildContext context) {
    return Consumer<ConnectionViewModel>(
      builder: (context, connectionVM, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Connection status
              Row(
                children: [
                  Icon(
                    _getConnectionIcon(connectionVM.connectionState),
                    color: _getConnectionColor(connectionVM.connectionState),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        connectionVM.connectionStateText,
                        style: TextStyle(
                          color: _getConnectionColor(connectionVM.connectionState),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Show reconnection attempt count
                      // Requirements: 12.1, 12.2 - Display reconnection progress
                      if (connectionVM.isReconnecting)
                        Text(
                          'Attempt ${connectionVM.reconnectionAttempts}/${connectionVM.maxReconnectionAttempts}',
                          style: TextStyle(
                            color: Colors.orange[200],
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              // Battery level
              if (connectionVM.isConnected)
                Row(
                  children: [
                    Icon(
                      _getBatteryIcon(connectionVM.batteryLevel),
                      color: _getBatteryColor(connectionVM.batteryLevel),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${connectionVM.batteryLevel}%',
                      style: TextStyle(
                        color: _getBatteryColor(connectionVM.batteryLevel),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build the main touchpad area
  Widget _buildTouchpadArea(BuildContext context) {
    return Consumer2<TouchpadViewModel, ConnectionViewModel>(
      builder: (context, touchpadVM, connectionVM, child) {
        final isMediaMode = touchpadVM.currentMode == ControlMode.mediaControl;
        
        return GestureDetector(
          onPanUpdate: (details) {
            // Handle swipe for cursor movement or media control
            // Requirements: 1.1, 1.3, 9.2, 9.3
            if (connectionVM.isConnected) {
              touchpadVM.handleSwipe(
                translation: details.delta,
                velocity: Offset(
                  details.delta.dx / 0.016, // Convert to velocity (assuming 60fps)
                  details.delta.dy / 0.016,
                ),
              );
            }
          },
          onPanEnd: (details) {
            // Reset tap state when pan ends
            touchpadVM.resetTapState();
          },
          onTapUp: (details) {
            // Handle tap gestures
            // Requirements: 2.1, 2.3, 9.1
            if (!connectionVM.isConnected) return;

            final now = DateTime.now();
            
            // In media mode, always treat tap as single tap (play/pause)
            if (isMediaMode) {
              touchpadVM.handleTap();
              _lastTapTime = null;
              return;
            }
            
            // Check if this is a double tap (non-media modes)
            if (_lastTapTime != null &&
                now.difference(_lastTapTime!) < _doubleTapThreshold) {
              // Double tap detected
              _lastTapTime = null;
              touchpadVM.handleTap(); // This will be processed as double tap
            } else {
              // Single tap - wait to see if double tap follows
              _lastTapTime = now;
              Future.delayed(_doubleTapThreshold, () {
                if (_lastTapTime == now) {
                  // No double tap followed, process as single tap
                  touchpadVM.handleTap();
                  _lastTapTime = null;
                }
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: connectionVM.isConnected
                    ? _getModeBorderColor(touchpadVM.currentMode)
                    : Colors.grey.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getModeIcon(touchpadVM.currentMode),
                    size: 64,
                    color: connectionVM.isConnected
                        ? _getModeIconColor(touchpadVM.currentMode)
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getModeText(touchpadVM.currentMode),
                    style: TextStyle(
                      color: connectionVM.isConnected
                          ? Colors.white70
                          : Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Show mode-specific instructions
                  if (connectionVM.isConnected && isMediaMode) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tap: Play/Pause',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Swipe Up/Down: Volume',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (!connectionVM.isConnected) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Not Connected',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (touchpadVM.isIdle) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Idle Mode',
                      style: TextStyle(
                        color: Colors.orange[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build the control buttons (back/forward)
  Widget _buildControlButtons(BuildContext context) {
    return Consumer2<TouchpadViewModel, ConnectionViewModel>(
      builder: (context, touchpadVM, connectionVM, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back button
              Expanded(
                child: _buildButton(
                  icon: Icons.arrow_back,
                  label: 'Back',
                  onPressed: connectionVM.isConnected
                      ? () => touchpadVM.handleBackButton()
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              
              // Forward button
              Expanded(
                child: _buildButton(
                  icon: Icons.arrow_forward,
                  label: 'Forward',
                  onPressed: connectionVM.isConnected
                      ? () => touchpadVM.handleForwardButton()
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build a control button
  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.blue : Colors.grey[700],
            borderRadius: BorderRadius.circular(12),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isEnabled ? Colors.white : Colors.grey[500],
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for icons and colors

  IconData _getConnectionIcon(BLEConnectionState state) {
    switch (state) {
      case BLEConnectionState.connected:
        return Icons.bluetooth_connected;
      case BLEConnectionState.connecting:
      case BLEConnectionState.reconnecting:
        return Icons.bluetooth_searching;
      case BLEConnectionState.disconnected:
        return Icons.bluetooth_disabled;
    }
  }

  Color _getConnectionColor(BLEConnectionState state) {
    switch (state) {
      case BLEConnectionState.connected:
        return Colors.green;
      case BLEConnectionState.connecting:
      case BLEConnectionState.reconnecting:
        return Colors.orange;
      case BLEConnectionState.disconnected:
        return Colors.red;
    }
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 60) return Icons.battery_6_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor(int level) {
    if (level > 20) return Colors.white;
    return Colors.red;
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

  String _getModeText(ControlMode mode) {
    switch (mode) {
      case ControlMode.presentation:
        return 'Presentation Mode';
      case ControlMode.mediaControl:
        return 'Media Control Mode';
      case ControlMode.basicMouse:
        return 'Basic Mouse Mode';
    }
  }

  Color _getModeBorderColor(ControlMode mode) {
    switch (mode) {
      case ControlMode.presentation:
        return Colors.blue.withValues(alpha: 0.5);
      case ControlMode.mediaControl:
        return Colors.purple.withValues(alpha: 0.5);
      case ControlMode.basicMouse:
        return Colors.blue.withValues(alpha: 0.5);
    }
  }

  Color _getModeIconColor(ControlMode mode) {
    switch (mode) {
      case ControlMode.presentation:
        return Colors.blue.withValues(alpha: 0.7);
      case ControlMode.mediaControl:
        return Colors.purple.withValues(alpha: 0.7);
      case ControlMode.basicMouse:
        return Colors.blue.withValues(alpha: 0.7);
    }
  }
}
