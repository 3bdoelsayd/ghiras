import 'package:flutter_test/flutter_test.dart';
import 'package:ghiras/main.dart';
import 'package:ghiras/core/constants/app_strings.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GhirasApp());

    // Verify that the splash screen or home screen shows the app name.
    // Since there's a timer in splash, we might need to pump and wait if we wanted to see home.
    expect(find.text(AppStrings.appName), findsOneWidget);
  });
}
