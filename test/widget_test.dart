// Basic widget test for RemoteTouch app

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_touch/main.dart';

void main() {
  testWidgets('RemoteTouch app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MobileRemoteTouchApp());

    // Verify that the app starts
    expect(find.byType(MobileRemoteTouchApp), findsOneWidget);
  });
}
