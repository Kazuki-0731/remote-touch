import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remote_touch/views/device_list_view.dart';
import 'package:remote_touch/viewmodels/connection_viewmodel.dart';
import 'package:remote_touch/services/ble_central_manager.dart';
import 'package:remote_touch/services/device_storage.dart';

void main() {
  late BLECentralManager bleManager;
  late DeviceStorage deviceStorage;
  late ConnectionViewModel connectionViewModel;

  setUp(() async {
    // Mock SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    
    bleManager = BLECentralManager();
    deviceStorage = await DeviceStorage.create();
    connectionViewModel = ConnectionViewModel(
      bleManager: bleManager,
      deviceStorage: deviceStorage,
    );
  });

  tearDown(() {
    connectionViewModel.dispose();
    bleManager.dispose();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<ConnectionViewModel>.value(
        value: connectionViewModel,
        child: const DeviceListView(),
      ),
    );
  }

  testWidgets('DeviceListView displays registered devices section',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Verify the registered devices section is displayed
    expect(find.text('Registered Devices'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('DeviceListView displays available devices section',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Verify the available devices section is displayed
    expect(find.text('Available Devices'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
  });

  testWidgets('DeviceListView shows empty state when no devices registered',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Verify empty state message
    expect(
      find.text('No registered devices.\nScan and connect to add devices.'),
      findsOneWidget,
    );
  });

  testWidgets('DeviceListView shows empty state when no devices discovered',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Verify empty state for discovered devices
    expect(find.text('No devices found'), findsOneWidget);
    expect(find.text('Tap "Scan" to search for devices'), findsOneWidget);
  });

  testWidgets('Scan button is present and tappable',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Find and verify scan button
    final scanButton = find.text('Scan');
    expect(scanButton, findsOneWidget);

    // Note: We don't actually tap it in the test because it would try to
    // start real BLE scanning which requires platform support
  });
}
