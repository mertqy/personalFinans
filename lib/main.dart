import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive Initialize
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint('Storage initialization failed: $e');
  }

  // Locale Initialize
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';

  runApp(const ProviderScope(child: ParamNeredeApp()));
}

class ParamNeredeApp extends StatelessWidget {
  const ParamNeredeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Param Nerede',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skipLogin = ref.watch(skipLoginProvider);

    // Skip login logic: Go to onboarding if first time, else MainScreen
    final showOnboarding = !StorageService.isOnboardingCompleted();
    if (showOnboarding) {
      return const OnboardingScreen();
    }

    if (!skipLogin) {
      return const LoginScreen();
    }

    return const MainScreen();
  }
}
