import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_settings.dart';
import 'services/ble_central_manager.dart';
import 'services/device_storage.dart';
import 'services/gesture_processor.dart';
import 'viewmodels/connection_viewmodel.dart';
import 'viewmodels/touchpad_viewmodel.dart';
import 'views/touchpad_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DeviceStorage asynchronously
  final deviceStorage = await DeviceStorage.create();
  
  // Load saved settings
  final appSettings = await deviceStorage.loadSettings();
  
  runApp(RemoteTouchApp(
    deviceStorage: deviceStorage,
    appSettings: appSettings,
  ));
}

class RemoteTouchApp extends StatelessWidget {
  final DeviceStorage deviceStorage;
  final AppSettings appSettings;
  
  const RemoteTouchApp({
    super.key,
    required this.deviceStorage,
    required this.appSettings,
  });

  @override
  Widget build(BuildContext context) {
    // Create service instances
    final bleManager = BLECentralManager();
    final gestureProcessor = GestureProcessor(
      sensitivity: appSettings.sensitivity,
    );

    return MultiProvider(
      providers: [
        // Provide services
        Provider<BLECentralManager>.value(value: bleManager),
        Provider<DeviceStorage>.value(value: deviceStorage),
        Provider<GestureProcessor>.value(value: gestureProcessor),
        
        // Provide ViewModels
        ChangeNotifierProvider<ConnectionViewModel>(
          create: (_) => ConnectionViewModel(
            bleManager: bleManager,
            deviceStorage: deviceStorage,
          ),
        ),
        ChangeNotifierProvider<TouchpadViewModel>(
          create: (_) => TouchpadViewModel(
            bleManager: bleManager,
            gestureProcessor: gestureProcessor,
          ),
        ),
      ],
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
        home: const TouchpadView(),
      ),
    );
  }
}
