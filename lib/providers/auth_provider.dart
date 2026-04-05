import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final skipLoginProvider = StateProvider<bool>((ref) {
  // Suspend login: Always true for now
  return true;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (uid) {
      if (uid == null) return null;
      return AppUser.local(); // Return a local user if any UID is present
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
