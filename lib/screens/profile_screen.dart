import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_provider.dart';
import '../services/storage_service.dart';
import '../app/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    final isPremium = ref.watch(isPremiumProvider).valueOrNull ?? false;
    final name = StorageService.settingsBox.get('user_name', defaultValue: 'Kullanıcı');
    final email = user?.email ?? 'Misafir Hesabı';
    
    // Check sign in method
    String signInMethod = 'Misafir';
    IconData methodIcon = Icons.person_outline;
    if (user != null) {
      if (user.providerData.any((p) => p.providerId == 'google.com')) {
        signInMethod = 'Google ile giriş yapıldı';
        methodIcon = Icons.g_mobiledata;
      } else if (user.providerData.any((p) => p.providerId == 'apple.com')) {
        signInMethod = 'Apple ile giriş yapıldı';
        methodIcon = Icons.apple;
      } else if (user.isAnonymous) {
        signInMethod = 'Misafir Hesabı';
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User Info Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                   CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPremium ? Colors.amber.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPremium ? Icons.star : Icons.star_outline,
                          size: 16,
                          color: isPremium ? Colors.amber : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPremium ? 'PREMIUM ÜYESİ' : 'STANDART ÜYELİK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPremium ? Colors.amber[800] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Account Section
            _buildSectionTitle('Hesap Yönetimi'),
            _buildOptionCard(
              context,
              title: 'Giriş Yöntemi',
              subtitle: signInMethod,
              icon: methodIcon,
              onTap: () {},
            ),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Uygulama Ayarları'),
             _buildOptionCard(
              context,
              title: 'Para Birimi',
              subtitle: 'Varsayılan Birim: TRY',
              icon: Icons.currency_lira,
              onTap: () {},
            ),
             _buildOptionCard(
              context,
              title: 'Veri Yedekleme',
              subtitle: 'Google Drive / iCloud',
              icon: Icons.cloud_done_outlined,
              onTap: () {},
            ),
             _buildOptionCard(
              context,
              title: 'Yardım & Destek',
              icon: Icons.help_outline_rounded,
              onTap: () {},
            ),
            
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context, ref),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Çıkış Yap', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Versiyon 1.2.0 (Build 42)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: isDark ? Colors.grey[900] : Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış yapılsın mı?'),
        content: const Text('Hesabınızdan çıkış yapılacaktır. Verileriniz senkronize kalsa da tekrar giriş yapmanız gerekecektir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Kalsın')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      ref.read(skipLoginProvider.notifier).state = false; // Force back to login if they logged out
      await StorageService.setSkipLogin(false);
      
      if (context.mounted) {
        // We'll let the App router handle the redirect based on auth status
        Navigator.of(context).pop();
      }
    }
  }
}
