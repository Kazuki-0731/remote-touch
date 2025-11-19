import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/ble_peripheral_manager.dart';

/// Control mode for the remote
enum ControlMode {
  presentation,
  mediaControl,
  basicMouse,
}

/// Settings keys for SharedPreferences
class SettingsKeys {
  static const String sensitivity = 'touchpad_sensitivity';
  static const String controlMode = 'control_mode';
}

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
  bool _isTouching = false;
  double _sensitivity = 1.0; // デフォルト感度
  ControlMode _currentMode = ControlMode.basicMouse; // デフォルトモード
  static const Duration _doubleTapThreshold = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sensitivity = prefs.getDouble(SettingsKeys.sensitivity) ?? 1.0;
      final modeIndex = prefs.getInt(SettingsKeys.controlMode) ?? 2; // デフォルトはbasicMouse
      _currentMode = ControlMode.values[modeIndex];
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(SettingsKeys.sensitivity, _sensitivity);
    await prefs.setInt(SettingsKeys.controlMode, _currentMode.index);
  }

  void _sendCommand(String type, Map<String, dynamic> data) {
    final bleManager = context.read<BLEPeripheralManager>();
    final command = {
      'type': type,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...data,
    };
    bleManager.sendCommand(command);
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          currentSensitivity: _sensitivity,
          currentMode: _currentMode,
          onSensitivityChanged: (newSensitivity) {
            setState(() {
              _sensitivity = newSensitivity;
            });
          },
          onModeChanged: (newMode) {
            setState(() {
              _currentMode = newMode;
            });
          },
        ),
      ),
    );
    // 設定画面から戻った後に設定を保存
    await _saveSettings();
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
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _openSettings,
                    tooltip: 'Settings',
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
      // Pan gestures for cursor movement
      onPanStart: (details) {
        setState(() {
          _isTouching = true;
          _lastPosition = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        if (_lastPosition != null) {
          final dx = (details.localPosition.dx - _lastPosition!.dx) * _sensitivity;
          final dy = (details.localPosition.dy - _lastPosition!.dy) * _sensitivity;

          _sendCommand('mouseMove', {
            'dx': dx,
            'dy': dy,
          });

          _lastPosition = details.localPosition;
        }
      },
      onPanEnd: (details) {
        setState(() {
          _isTouching = false;
          _lastPosition = null;
        });
      },

      // Tap gestures for clicks (no cursor movement)
      onTapDown: (details) {
        setState(() => _isTouching = true);
      },
      onTapUp: (details) {
        setState(() => _isTouching = false);

        final now = DateTime.now();

        // Check for double tap
        if (_lastTapTime != null &&
            now.difference(_lastTapTime!) < _doubleTapThreshold) {
          // Double tap - send immediately
          _sendCommand('doubleClick', {});
          _lastTapTime = null;
        } else {
          // Potential single tap - wait to confirm it's not a double tap
          _lastTapTime = now;
          Future.delayed(_doubleTapThreshold, () {
            if (_lastTapTime == now) {
              _sendCommand('click', {});
              _lastTapTime = null;
            }
          });
        }
      },
      onTapCancel: () {
        setState(() => _isTouching = false);
        _lastTapTime = null; // Cancel pending tap
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isTouching
                ? Colors.blue.withOpacity(0.9)
                : Colors.blue.withOpacity(0.5),
            width: _isTouching ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isTouching
                  ? Colors.blue.withOpacity(0.4)
                  : Colors.black.withOpacity(0.5),
              blurRadius: _isTouching ? 20 : 10,
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
      child: _buildButtonsForMode(),
    );
  }

  Widget _buildButtonsForMode() {
    switch (_currentMode) {
      case ControlMode.presentation:
        return Row(
          children: [
            Expanded(
              child: _buildButton(
                icon: Icons.arrow_back,
                label: 'Previous',
                onPressed: () => _sendCommand('back', {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildButton(
                icon: Icons.arrow_forward,
                label: 'Next',
                onPressed: () => _sendCommand('forward', {}),
              ),
            ),
          ],
        );
      case ControlMode.mediaControl:
        return Row(
          children: [
            Expanded(
              child: _buildButton(
                icon: Icons.play_arrow,
                label: 'Play/Pause',
                onPressed: () => _sendCommand('playPause', {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildButton(
                icon: Icons.volume_up,
                label: 'Volume',
                onPressed: () => _sendCommand('volumeUp', {}),
              ),
            ),
          ],
        );
      case ControlMode.basicMouse:
        return Row(
          children: [
            Expanded(
              child: _buildButton(
                icon: Icons.arrow_back,
                label: 'Back',
                onPressed: () => _sendCommand('back', {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildButton(
                icon: Icons.arrow_forward,
                label: 'Forward',
                onPressed: () => _sendCommand('forward', {}),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.5),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.4),
        highlightColor: Colors.white.withOpacity(0.2),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade700,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings screen for touchpad sensitivity adjustment and mode selection
class SettingsScreen extends StatefulWidget {
  final double currentSensitivity;
  final ControlMode currentMode;
  final Function(double) onSensitivityChanged;
  final Function(ControlMode) onModeChanged;

  const SettingsScreen({
    super.key,
    required this.currentSensitivity,
    required this.currentMode,
    required this.onSensitivityChanged,
    required this.onModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _sensitivity;
  late ControlMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _sensitivity = widget.currentSensitivity;
    _selectedMode = widget.currentMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.onSensitivityChanged(_sensitivity);
            widget.onModeChanged(_selectedMode);
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Control Mode Section
            _buildSectionHeader('Control Mode'),
            _buildModeSelector(),

            const SizedBox(height: 32),

            // Sensitivity Section
            _buildSectionHeader('Touchpad Sensitivity'),
            _buildSensitivitySlider(),

            const SizedBox(height: 32),

            // About Section
            _buildSectionHeader('About'),
            _buildAboutSection(),
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

  Widget _buildModeSelector() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final mode = await Navigator.push<ControlMode>(
            context,
            MaterialPageRoute(
              builder: (context) => ModeSelectionScreen(
                currentMode: _selectedMode,
              ),
            ),
          );
          if (mode != null) {
            setState(() {
              _selectedMode = mode;
            });
          }
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
                _getModeIcon(_selectedMode),
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getModeDisplayName(_selectedMode),
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
  }

  Widget _buildSensitivitySlider() {
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
                '${(_sensitivity * 100).toInt()}%',
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
              value: _sensitivity,
              min: 0.5,
              max: 3.0,
              divisions: 25,
              onChanged: (value) {
                setState(() {
                  _sensitivity = value;
                });
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
  }

  Widget _buildAboutSection() {
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
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'RemoteTouch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transform your phone into a wireless touchpad for your Mac',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
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

/// Mode selection screen
class ModeSelectionScreen extends StatelessWidget {
  final ControlMode currentMode;

  const ModeSelectionScreen({
    super.key,
    required this.currentMode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text('Select Control Mode'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildModeCard(
              context,
              mode: ControlMode.basicMouse,
              icon: Icons.mouse,
              title: 'Basic Mouse Mode',
              description: 'Standard mouse control with back/forward buttons',
              features: [
                'Cursor movement',
                'Click and double-click',
                'Back/Forward navigation',
              ],
            ),
            const SizedBox(height: 16),
            _buildModeCard(
              context,
              mode: ControlMode.presentation,
              icon: Icons.present_to_all,
              title: 'Presentation Mode',
              description: 'Optimized for slide presentations',
              features: [
                'Cursor movement',
                'Click and double-click',
                'Previous/Next slide buttons',
              ],
            ),
            const SizedBox(height: 16),
            _buildModeCard(
              context,
              mode: ControlMode.mediaControl,
              icon: Icons.music_note,
              title: 'Media Control Mode',
              description: 'Control media playback and volume',
              features: [
                'Cursor movement',
                'Play/Pause button',
                'Volume control',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required ControlMode mode,
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
  }) {
    final isSelected = mode == currentMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context, mode);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[700]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.grey[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.blue : Colors.grey[400],
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? Colors.blue : Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 28,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: Colors.grey[500],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        feature,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
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
