# 🎯 Icon Kurulum Talimatları

## 📥 Adım 1: Icon'ları İndir

1. **[favicon.io/emoji-favicons/money-bag](https://favicon.io/emoji-favicons/money-bag/)** linkine git
2. **"Download"** butonuna tıkla
3. ZIP dosyasını aç

## 📁 Adım 2: Dosyaları Kopyala

ZIP'ten bu dosyaları `public/` klasörüne kopyala:
- `android-chrome-192x192.png` → `icon-192x192.png` olarak yeniden adlandır
- `android-chrome-512x512.png` → `icon-512x512.png` olarak yeniden adlandır

## 🔄 Adım 3: GitHub'a Yükle

```bash
git add .
git commit -m "feat: Add professional money bag PWA icons"
git push origin main
```

## ✅ Sonuç

- 💰 Para torbası emoji icon'u
- 📱 Ana ekranda profesyonel görünüm
- 🎨 Vercel otomatik deploy edecek
- 🔄 PWA cache temizlenmesi için uygulamayı sil ve yeniden yükle

**Not**: Download edilen ZIP'te diğer boyutlar da var ama PWA için sadece 192x192 ve 512x512 gerekli. 