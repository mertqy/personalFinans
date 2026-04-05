// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finans/main.dart';
import 'package:personal_finans/screens/main_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:personal_finans/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;

    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return null;
        });

    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
          return '.';
        });

    const connectivityChannel = MethodChannel(
      'dev.fluttercommunity.plus/connectivity',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (
          MethodCall methodCall,
        ) async {
          return 'wifi';
        });

    // Initialize Hive for tests
    await Hive.initFlutter('test_boxes');
    await StorageService.init();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Suppress font loading errors in tests and fix missing await
    await tester.binding.setSurfaceSize(const Size(1080, 1920));

    // Build our app and trigger a frame.
    await tester.pumpWidget(ProviderScope(child: const ParamNeredeApp()));

    // Initial pump to load the first frame
    await tester.pump();

    // We might need to wait for animations or async logic
    // But for a smoke test, finding the MainScreen is enough
    expect(find.byType(MainScreen), findsOneWidget);
  });
}
