import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/ble_peripheral_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if running on mobile (iOS/Android)
  final isMobile = !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  if (isMobile) {
    // Mobile app - BLE Peripheral (Remote control side)
    runApp(const MobileRemoteTouchApp());
  } else {
    // macOS/Desktop app - show error
    runApp(const DesktopErrorApp());
  }
}

/// Mobile app (iOS/Android) - Acts as BLE Peripheral (Remote control)
class MobileRemoteTouchApp extends StatelessWidget {
  const MobileRemoteTouchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BLEPeripheralManager>(
      create: (_) => BLEPeripheralManager(),
      child: MaterialApp(
        title: 'RemoteTouch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const MobileHomePage(),
      ),
    );
  }
}

/// Mobile home page with connection status and touchpad
class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  @override
  void initState() {
    super.initState();

    // Auto-start advertising when app launches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleManager = context.read<BLEPeripheralManager>();
      bleManager.startAdvertising();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BLEPeripheralManager>(
      builder: (context, bleManager, child) {
        // Show touchpad when connected
        if (bleManager.isConnected) {
          return const TouchpadScreen();
        }

        // Show connection screen when not connected
        return const ConnectionScreen();
      },
    );
  }
}

/// Connection screen - shown when not connected
class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RemoteTouch'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<BLEPeripheralManager>(
        builder: (context, bleManager, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Connection status icon
                Icon(
                  bleManager.isAdvertising
                      ? Icons.bluetooth_searching
                      : Icons.bluetooth_disabled,
                  size: 80,
                  color: bleManager.isAdvertising ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 20),

                // Status text
                Text(
                  bleManager.isAdvertising
                      ? 'Waiting for Mac connection...'
                      : 'Not advertising',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                Text(
                  'Status: ${bleManager.isAdvertising ? "Advertising" : "Idle"}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 40),

                // Control buttons
                if (!bleManager.isAdvertising)
                  ElevatedButton.icon(
                    onPressed: () => bleManager.startAdvertising(),
                    icon: const Icon(Icons.bluetooth),
                    label: const Text('Start Advertising'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => bleManager.stopAdvertising(),
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Stop Advertising'),
                  ),

                const SizedBox(height: 40),

                // Instructions
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Instructions:\n'
                    '1. Make sure Bluetooth is ON\n'
                    '2. Start RemoteTouch app on your Mac\n'
                    '3. Tap "Start Advertising" above\n'
                    '4. Wait for Mac to connect automatically',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Touchpad screen - shown when connected
class TouchpadScreen extends StatefulWidget {
  const TouchpadScreen({super.key});

  @override
  State<TouchpadScreen> createState() => _TouchpadScreenState();
}

class _TouchpadScreenState extends State<TouchpadScreen> {
  Offset? _lastPosition;
  DateTime? _lastTapTime;
  static const Duration _doubleTapThreshold = Duration(milliseconds: 300);

  void _sendCommand(String type, Map<String, dynamic> data) {
    final bleManager = context.read<BLEPeripheralManager>();
    final command = {
      'type': type,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...data,
    };
    bleManager.sendCommand(command);
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
          Consumer<BLEPeripheralManager>(
            builder: (context, bleManager, child) {
              return Row(
                children: [
                  Icon(
                    bleManager.isConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color:
                        bleManager.isConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bleManager.isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color:
                          bleManager.isConnected ? Colors.green : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.link_off),
                    onPressed: () => bleManager.disconnect(),
                    tooltip: 'Disconnect',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Touchpad area
            Expanded(
              child: _buildTouchpad(),
            ),

            // Control buttons
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTouchpad() {
    return GestureDetector(
      onPanStart: (details) {
        _lastPosition = details.localPosition;
      },
      onPanUpdate: (details) {
        if (_lastPosition != null) {
          final dx = details.localPosition.dx - _lastPosition!.dx;
          final dy = details.localPosition.dy - _lastPosition!.dy;

          _sendCommand('mouseMove', {
            'dx': dx,
            'dy': dy,
          });

          _lastPosition = details.localPosition;
        }
      },
      onPanEnd: (details) {
        _lastPosition = null;
      },
      onTapUp: (details) {
        final now = DateTime.now();

        // Check for double tap
        if (_lastTapTime != null &&
            now.difference(_lastTapTime!) < _doubleTapThreshold) {
          // Double tap
          _sendCommand('doubleClick', {});
          _lastTapTime = null;
        } else {
          // Single tap - wait to confirm
          _lastTapTime = now;
          Future.delayed(_doubleTapThreshold, () {
            if (_lastTapTime == now) {
              _sendCommand('click', {});
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
            color: Colors.blue.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
                Icons.touch_app,
                size: 64,
                color: Colors.blue.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              const Text(
                'Touchpad',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Swipe to move cursor\nTap to click\nDouble-tap to double-click',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
              onPressed: () => _sendCommand('back', {}),
            ),
          ),
          const SizedBox(width: 16),

          // Forward button
          Expanded(
            child: _buildButton(
              icon: Icons.arrow_forward,
              label: 'Forward',
              onPressed: () => _sendCommand('forward', {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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
}

/// Desktop error app - should only run on macOS via native code
class DesktopErrorApp extends StatelessWidget {
  const DesktopErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'RemoteTouch Flutter UI is for mobile only',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'On macOS, the app runs as a menu bar application.\n'
                'Please look for the RemoteTouch icon in your menu bar.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
