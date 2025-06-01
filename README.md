# Finans - Mobil Gelir Gider Takibi

Modern ve kullanıcı dostu mobil finans uygulaması. Gelir ve giderlerinizi kolayca takip edin.

## 🚀 Özellikler

- ✅ **Hızlı İşlem Ekleme**: Tek tıkla gelir/gider ekleme
- ✅ **Detaylı İstatistikler**: Aylık, günlük ortalamalar ve kategori analizleri
- ✅ **Tekrarlayan İşlemler**: Günlük, haftalık, aylık, yıllık tekrarlar
- ✅ **Mobil Optimizasyon**: Dokunmatik ekranlar için optimize edilmiş
- ✅ **PWA Desteği**: Telefona uygulama olarak yüklenebilir
- ✅ **Offline Çalışma**: İnternet olmadan da kullanılabilir
- ✅ **Dark Mode**: Göz dostu karanlık tema
- ✅ **Türkçe Dil Desteği**: Tamamen Türkçe arayüz

## 📱 Mobil Uygulama Olarak Yükleme

### Android (PWA)
1. Chrome tarayıcısında uygulamayı açın
2. Menüden "Ana ekrana ekle" seçeneğini seçin
3. Uygulama ana ekranınıza eklenir

### iOS (PWA)
1. Safari'de uygulamayı açın
2. Paylaş butonuna tıklayın
3. "Ana Ekrana Ekle" seçeneğini seçin

## 🛠️ Teknolojiler

- **Next.js 15** - React framework
- **TypeScript** - Tip güvenliği
- **Tailwind CSS** - Modern CSS framework
- **Capacitor** - Mobil uygulama wrapper
- **PWA** - Progressive Web App
- **LocalStorage** - Veri saklama

## 🏗️ Kurulum ve Geliştirme

### Gereksinimler
- Node.js 18+
- npm veya yarn

### Kurulum
```bash
# Projeyi klonlayın
git clone [repo-url]
cd personal-finance-app

# Bağımlılıkları yükleyin
npm install

# Geliştirme sunucusunu başlatın
npm run dev
```

### Build ve Deploy
```bash
# Production build
npm run build

# PWA olarak build
npm run export

# Mobil uygulama build
npm run build:mobile
```

## 📂 Proje Yapısı

```
src/
├── app/                 # Next.js App Router
│   ├── globals.css     # Global stiller
│   ├── layout.tsx      # Ana layout
│   └── page.tsx        # Ana sayfa
├── components/         # React bileşenleri
│   ├── forms/         # Form bileşenleri
│   └── Statistics.tsx # İstatistik bileşeni
├── contexts/          # React Context'ler
├── lib/               # Yardımcı fonksiyonlar
└── types/             # TypeScript tipleri
```

## 🎯 Kullanım

### Temel İşlemler
1. **Gelir Ekleme**: Yeşil "Gelir Ekle" butonuna tıklayın
2. **Gider Ekleme**: Kırmızı "Gider Ekle" butonuna tıklayın
3. **İstatistikler**: Sağ üst menüden "İstatistikler" seçin

### Tekrarlayan İşlemler
- Maaş, kira gibi düzenli ödemeler için kullanın
- Günlük, haftalık, aylık, yıllık seçenekleri mevcut

### Kategoriler
- **Gelir**: Maaş, Serbest Çalışma, Yatırım, Diğer
- **Gider**: Yiyecek, Ulaşım, Barınma, Sağlık, Eğlence, Alışveriş, Faturalar, Eğitim, Diğer

## 📊 İstatistikler

- **Genel Özet**: Toplam gelir, gider, net bakiye
- **Aylık Veriler**: Bu ay gelir/gider/bakiye
- **Günlük Ortalamalar**: Günlük gelir/gider ortalamaları
- **Top Kategoriler**: En çok kullanılan kategoriler
- **Genel Bilgiler**: İşlem sayıları ve aktif gün sayısı

## 🔧 Özelleştirme

### Tema
Uygulama tamamen dark mode olarak tasarlanmıştır. Renk şeması:
- Ana renk: `#111827` (Koyu gri)
- İkincil renk: `#1f2937` (Gri)
- Gelir rengi: `#10B981` (Yeşil)
- Gider rengi: `#EF4444` (Kırmızı)

### Kategoriler
`src/lib/constants.ts` dosyasından kategorileri özelleştirebilirsiniz.

## 📱 Mobil Optimizasyon

- Touch-friendly butonlar (minimum 44px)
- Swipe gesture desteği
- Safe area desteği (iPhone notch)
- Responsive tasarım
- Hızlı yükleme
- Offline çalışma

## 🚀 Deployment

### Vercel (Önerilen)
```bash
npm run build
# Vercel'e deploy edin
```

### Netlify
```bash
npm run build
# out/ klasörünü Netlify'a yükleyin
```

### GitHub Pages
```bash
npm run build
# out/ klasörünü gh-pages branch'ine push edin
```

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 İletişim

Sorularınız için issue açabilir veya pull request gönderebilirsiniz.

---

**Not**: Bu uygulama tamamen offline çalışır ve verileriniz sadece cihazınızda saklanır. Hiçbir veri sunucuya gönderilmez.
