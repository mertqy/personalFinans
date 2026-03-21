import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'services/storage_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart'; // Added this import for NumberFormat

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hive Initialize
  await StorageService.init();
  
  // Locale Initialize
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';
  
  final showOnboarding = !StorageService.isOnboardingCompleted();

  runApp(
    ProviderScope(
      child: PersonalFinansApp(showOnboarding: showOnboarding),
    ),
  );
}

class PersonalFinansApp extends StatelessWidget {
  final bool showOnboarding;
  final ThemeData? theme;
  const PersonalFinansApp({super.key, required this.showOnboarding, this.theme});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Param Nerede',
      debugShowCheckedModeBanner: false,
      theme: theme ?? AppTheme.darkTheme,
      home: showOnboarding ? const OnboardingScreen() : const MainScreen(),
    );
  }
}
