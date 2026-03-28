import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../widgets/auth/google_auth_button.dart';
import '../widgets/auth/apple_auth_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleSignIn(Future<dynamic> Function() signInMethod) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final oldUid = authService.currentUser?.uid ?? 'temp_user';

      // If we are already logged in (maybe anonymously), sign out first to ensure fresh login
      // But for social login, we might want to link. 
      // For now, let's follow AuthModal logic: sign out then sign in.
      await authService.signOut();

      final result = await signInMethod();
      if (mounted) {
        final newUid = result?.user?.uid;
        if (newUid != null && newUid != oldUid) {
          await StorageService.migrateUserData(oldUid, newUid);
        }

        if (result?.user?.displayName != null) {
          await StorageService.settingsBox.put(
            'user_name',
            result!.user!.displayName,
          );
        }
        await StorageService.setSkipLogin(false);
        ref.read(skipLoginProvider.notifier).state = false;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Giriş yapılamadı. Tekrar deneyin.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App Logo & Title
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Text(
                'Param Nerede',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 8),

              Text(
                'Finanslarınızı kolayca yönetin',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

              const Spacer(flex: 2),

              // Error Message
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Social Sign In
              GoogleAuthButton(
                onPressed: () => _handleSignIn(
                  () => ref.read(authServiceProvider).signInWithGoogle(),
                ),
                isLoading: _isLoading,
                label: 'Google ile Giriş Yap',
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

              if (!kIsWeb && Platform.isIOS) ...[
                const SizedBox(height: 12),
                AppleAuthButton(
                  onPressed: () => _handleSignIn(
                    () => ref.read(authServiceProvider).signInWithApple(),
                  ),
                  isLoading: _isLoading,
                  label: 'Apple ile Giriş Yap',
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              ],

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'VEYA',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                ],
              ).animate().fadeIn(delay: 700.ms, duration: 500.ms),

              const SizedBox(height: 24),

              // Anonymous / Skip Login
              TextButton(
                onPressed: _isLoading ? null : () async {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  try {
                    final authService = ref.read(authServiceProvider);
                    await authService.signInAnonymously();
                    if (mounted) {
                      await StorageService.setSkipLogin(true);
                      ref.read(skipLoginProvider.notifier).state = true;
                    }
                  } catch (e) {
                    debugPrint('Anonymous sign in failed: $e');
                    if (mounted) {
                      await StorageService.setSkipLogin(true);
                      ref.read(skipLoginProvider.notifier).state = true;
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: Text(
                  'Misafir Olarak Devam Et',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 500.ms),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),

              const Spacer(),

              // Terms & Privacy
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Devam ederek Kullanım Koşulları ve\nGizlilik Politikası\'nı kabul etmiş olursunuz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

