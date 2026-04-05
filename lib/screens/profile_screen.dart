import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../app/theme.dart';
import 'legal_text_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = StorageService.settingsBox.get('user_name', defaultValue: 'Kullanıcı');
    final email = user?.email ?? 'Misafir Hesabı';

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
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Account Section
            
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
              title: 'Yardım & Destek',
              icon: Icons.help_outline_rounded,
              onTap: () {},
            ),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Yasal Bilgiler'),
            _buildOptionCard(
              context,
              title: 'Gizlilik Politikası',
              icon: Icons.privacy_tip_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LegalTextScreen(
                      title: 'Gizlilik Politikası',
                      content: '''Gizlilik Politikası

Son Güncelleme Tarihi: 4 Nisan 2026

1. Giriş ve Kapsam
ParamNerede ("Uygulama"), kullanıcıların ("Siz") kişisel verilerinin korunmasına, veri mahremiyetine ve gizliliğine azami hassasiyet göstermektedir. Bu gizlilik politikası, Uygulama'yı kullanımınız esnasında toplanan, işlenen ve saklanan verilerin hukuki dayanaklarını, saklanma koşullarını ve haklarınızı detaylandırmaktadır. Uygulamayı indirmeniz veya kullanmanız, işbu politikada izah edilen şartları kabul ettiğiniz anlamına gelir.

2. Toplanan Veriler ve Veri İşleme Amacı
Uygulamanın temel amacı kişisel bütçe yönetimi, gelir, gider ve tasarruf planlamanızı analiz etmektir. Bu bağlamda, girmiş olduğunuz tüm finansal kayıtlar (gelirler, harcamalar, bütçe limitleri, vb.) yalnızca kullanım deneyiminizi optimize etmek ve size içgörüler sunmak amacıyla işlenmektedir. 
Uygulamamız, veri minimalizasyonu prensiplerine sadık kalarak, doğrudan uygulamanın işleyişi ile ilgili olmayan hiçbir gereksiz veriyi talep etmez veya işlemez.

3. Verilerin Depolanması ve Güvenlik Seviyesi
Verileriniz, yerel (offline) mimari üzerine kuruludur. Girdiğiniz tüm kayıtlar cihazınızın güvenli depolama alanında tutulmaktadır. Kullanıcının açık rızası ve aktif tercihi ile harici bir bulut senkronizasyon servisi (örn. iCloud, Google Drive) kullanıldığı durumlar haricinde veriler cihaz dışarısına çıkartılmaz veya kendi sunucularımızda barındırılmaz. Verileriniz, genel kabul görmüş standart şifreleme ve güvenlik önlemleri ile korunmaktadır.

4. Veri Paylaşımı ve Üçüncü Taraflara Aktarım
ParamNerede, cihazınızda işlenen kişisel ve finansal verilerinizi hiçbir ad altında üçüncü şahıslarla, reklam ajanslarıyla veya bağımsız analiz şirketleriyle paylaşmaz ve gelir elde etmek amacıyla üçüncü kişi ve kurumlara devretmez / satmaz. 

5. Kullanıcı Hakları ve Verilerin İmhası
Uygulamada yer alan tüm finansal kayıtlarınız sizin mülkiyetinizdedir. İstediğiniz an ayarlar kısmından verilerinizin tamamını silebilir veya uygulamayı cihazınızdan kaldırarak verilerin kalıcı olarak imha edilmesini sağlayabilirsiniz.

6. İletişim
İşbu Gizlilik Politikası ile ilgili her tür soru, geri bildirim veya teknik destek talebi için resmi destek e-posta adresimiz üzerinden bizimle iletişime geçebilirsiniz.

İletişim Adresi: legal@paramnerede.com
''',
                    ),
                  ),
                );
              },
            ),
            _buildOptionCard(
              context,
              title: 'Kullanım Koşulları',
              icon: Icons.description_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LegalTextScreen(
                      title: 'Kullanım Koşulları',
                      content: '''Kullanım Koşulları

Son Güncelleme Tarihi: 4 Nisan 2026

1. Taraflar ve Sözleşmenin Kabulü
İşbu Kullanım Koşulları ("Sözleşme"), ParamNerede uygulamasının ("Uygulama") yüklenmesi, çalıştırılması ve kullanılmasıyla ilgili uygulama geliştiricisi ile son kullanıcı ("Siz" veya "Kullanıcı") arasındaki yasal ve bağlayıcı hak ve yükümlülükleri düzenler. Uygulamayı kullanmaya başlayarak bu belgedeki tüm kuralları okuduğunuzu, anladığınızı ve geri dönülemez bir şekilde kabul ettiğinizi beyan edersiniz.

2. Hizmetin Kapsamı ve Verilen Lisans
Uygulama, temel olarak bireysel finans ve bütçe yönetimi alanında hesaplama ve görselleştirme desteği sunan bir finansal takip araçları bütünüdür. Geliştirici, Kullanıcı'ya yalnızca kişisel, ticari olmayan ve devredilemez nitelikte geçici bir kullanım lisansı tesis etmektedir. Uygulamanın kaynak kodunun değiştirilmesi, tersine mühendisliği, çoğaltılması ve ticari veya kötü niyetli amaçlarla farklı bir sürümünün yayınlanması kesinlikle yasaktır ve doğrudan hak ihlali oluşturur.

3. Sorumluluk Reddi (Disclaimer) ve Mali Tavsiye Sınırları
Uygulama aracılığıyla analiz edilen veriler, bütçe yönlendirmeleri, harcama grafikleri ve genel finansal yorumlar tamamen bilgilendirme amaçlıdır. Uygulamada yer alan hiçbir görsel veya metin bildirim, profesyonel, yasal, vergisel veya serbest piyasa koşullarını yönlendirecek nitelikte bir "Yatırım Tavsiyesi" veya danışmanlık hizmeti yerine geçmez. Kullanıcının bu bilgilere dayanarak alacağı her çeşit finansal veya yatırımsal aksiyondan doğacak doğrudan ya da dolaylı zararlardan Uygulama Geliştiricisi sorumlu tutulamaz.

4. Veri Sorumluluğu, Kullanım Riskleri ve Yedekleme
Kullanıcı, Uygulama içine girilen tüm hesap ve gelir/gider verilerinin doğruluğundan tek başına sorumludur. Uygulama, çevrimdışı işleyişi dolayısıyla girilen verilerin donanım arızası, işletim sistemi hatası veya cihaz kaybı gibi kullanıcının denetimindeki aksaklıklardan doğacak veri kaybı durumlarında sorumluluk kabul etmez. Kullanıcıların verilerini ilgili bulut hizmetlerine (iCloud / Google Drive) düzenli olarak yedeklemesi önemle tavsiye olunur.

5. Sözleşme İhlali ve Hizmetin Sona Ermesi
İşbu sözleşmede veya meri mevzuatta belirtilen yükümlülüklere aykırı kullanımın tespiti halinde veya Uygulama geliştiricisinin bağımsız ve haklı inisiyatifiyle, önceden hiçbir fesih veya iptal ihbarnamesine gerek kalmaksızın, kullanıcının uygulamaya veya bazı özelliklere olan erişimi engellenebilir veya feshedilebilir.

6. Değişiklik ve Güncellemeler
Geliştirici, gelişen teknoloji veya değişen hukuk kuralları gereği işbu Kullanım Koşulları üzerinde tek taraflı olarak güncelleme veya değişiklik yapma hakkını saklı tutar. Değişiklikler, uygulama arayüzünde yayınlandıkları andan itibaren Kullanıcı tarafından kabul edilmiş sayılarak yürürlüğe girer.
''',
                    ),
                  ),
                );
              },
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
