// Basic widget test for RemoteTouch app

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_touch/services/device_storage.dart';
import 'package:remote_touch/main.dart';

void main() {
  testWidgets('RemoteTouch app smoke test', (WidgetTester tester) async {
    // Create device storage for testing
    final deviceStorage = await DeviceStorage.create();
    final appSettings = await deviceStorage.loadSettings();
    
    // Build our app and trigger a frame
    await tester.pumpWidget(RemoteTouchApp(
      deviceStorage: deviceStorage,
      appSettings: appSettings,
    ));

    // Verify that the touchpad view is displayed
    expect(find.text('Basic Mouse Mode'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Forward'), findsOneWidget);
  });
}
