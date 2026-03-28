import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app/theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Initialize
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // AdMob Initialize (Does not support web)
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMob initialization failed: $e');
    }
  }

  // Hive Initialize
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint('Storage initialization failed: $e');
  }

  // Locale Initialize
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';

  runApp(const ProviderScope(child: PersonalFinansApp()));
}

class PersonalFinansApp extends StatelessWidget {
  const PersonalFinansApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Param Nerede',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skipLogin = ref.watch(skipLoginProvider);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not authenticated
        if (!snapshot.hasData && !skipLogin) {
          return const LoginScreen();
        }

        // Authenticated or Skipped — check onboarding
        final showOnboarding = !StorageService.isOnboardingCompleted();
        if (showOnboarding) {
          return const OnboardingScreen();
        }

        return const MainScreen();
      },
    );
  }
}
