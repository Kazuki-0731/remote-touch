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
    return MultiProvider(
      providers: [
        // Provide services
        Provider<DeviceStorage>.value(value: deviceStorage),
        Provider<GestureProcessor>(
          create: (_) => GestureProcessor(
            sensitivity: appSettings.sensitivity,
          ),
        ),

        // Provide BLE Manager as ChangeNotifier
        ChangeNotifierProvider<BLECentralManager>(
          create: (_) => BLECentralManager(),
        ),

        // Provide ViewModels
        ChangeNotifierProxyProvider<BLECentralManager, ConnectionViewModel>(
          create: (context) => ConnectionViewModel(
            bleManager: context.read<BLECentralManager>(),
            deviceStorage: deviceStorage,
          ),
          update: (context, bleManager, previous) =>
              previous ?? ConnectionViewModel(
                bleManager: bleManager,
                deviceStorage: deviceStorage,
              ),
        ),
        ChangeNotifierProxyProvider2<BLECentralManager, GestureProcessor, TouchpadViewModel>(
          create: (context) => TouchpadViewModel(
            bleManager: context.read<BLECentralManager>(),
            gestureProcessor: context.read<GestureProcessor>(),
          ),
          update: (context, bleManager, gestureProcessor, previous) =>
              previous ?? TouchpadViewModel(
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
