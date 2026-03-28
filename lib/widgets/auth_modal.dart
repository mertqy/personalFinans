import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import 'auth/google_auth_button.dart';
import 'auth/apple_auth_button.dart';

class AuthModal extends ConsumerStatefulWidget {
  const AuthModal({super.key});

  @override
  ConsumerState<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends ConsumerState<AuthModal> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleSignIn(Future<dynamic> Function() signInMethod) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // Save old UID for data migration
      final oldUid = authService.currentUser?.uid ?? 'temp_user';

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
        if (!mounted) return;
        Navigator.pop(context); // Close modal on success
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
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141724),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (kIsWeb || !Platform.isIOS)
                    ? 'Google hesabıyla\nüyelik aç veya giriş yap'
                    : 'Google ya da Apple hesabıyla\nüyelik aç veya giriş yap',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 24),

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

          GoogleAuthButton(
            onPressed: () => _handleSignIn(
              () => ref.read(authServiceProvider).signInWithGoogle(),
            ),
            isLoading: _isLoading,
          ),
          if (!kIsWeb && Platform.isIOS) ...[
            const SizedBox(height: 12),
            AppleAuthButton(
              onPressed: () => _handleSignIn(
                () => ref.read(authServiceProvider).signInWithApple(),
              ),
              isLoading: _isLoading,
            ),
          ],

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}
