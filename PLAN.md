# 101 Okey App — Proje Planı

## Karar Özeti (Sohbetten)

### Hedef
Türk Okey oyuncuları için fotoğrafla taş tanıma ve el hesaplama yapan iOS uygulaması.
App Store'a çıkarılacak, para kazanılacak.

### Teknoloji Kararları
- **Mobil:** Swift + SwiftUI (native iOS, Xcode)
- **Backend:** Node.js + Express.js (tek servis, mikro servis yok)
- **Veritabanı:** SQLite (sunucusuz, ücretsiz)
- **AI (Geçici):** Claude Vision API (Haiku - ucuz) veya Gemini Flash (ücretsiz kota)
- **AI (Hedef):** Kendi eğitilmiş Core ML modeli (cihaz içi, sıfır maliyet)
- **Deploy:** Railway veya Render (ücretsiz tier)
- **Satın Alma:** Apple StoreKit 2 (abonelik + paket)

### Neden Sıfırdan?
Eski `idk/` projesi referans olarak tutuldu ama kullanılmıyor.
Eski proje aşırı karmaşık: 3 mikro servis, Docker, Nginx, Grafana — gereksiz.
Sadece oyun mantığı algoritması referans alınabilir.

---

## Fiyatlandırma

| Paket | Fiyat | Detay |
|-------|-------|-------|
| Ücretsiz | 0₺ | Günlük 1 hesaplama |
| Küçük Paket | 50₺ | 15 fotoğraf hakkı |
| Büyük Paket | 100₺ | 50 fotoğraf hakkı |
| Aylık Abonelik | 500₺ | Günlük 25 limit |

> Apple %30 komisyon alır (küçük geliştirici programında %15).

---

## Mimari

```
📱 OkeyApp (SwiftUI)
├── Camera/Galeri → fotoğraf seç
├── API isteği → Backend
├── Sonuç göster (taşlar + puan)
└── StoreKit → paket / abonelik satın al

☁️ Backend (Express.js - Railway)
├── POST /api/recognize   → AI ile taş tanı
├── POST /api/evaluate    → Okey el hesapla
├── POST /api/auth        → Apple Sign In
├── GET  /api/usage       → Günlük limit kontrol
└── POST /api/verify-purchase → Apple receipt doğrula

🗄️ SQLite
└── users, usage_logs, purchases
```

---

## AI Yol Haritası

### Aşama 1 — Şimdi (Claude/Gemini Vision)
- Fotoğraf backend'e gönderilir
- Claude Haiku veya Gemini Flash API çağrısı
- Taşlar JSON olarak döner
- Tahmini doğruluk: %75-85

### Aşama 2 — 1-2 ay sonra (Veri Toplama)
- Kullanıcı fotoğrafları (izinli) sunucuda biriktirilir
- Her taş için 100-200 fotoğraf hedefi
- 54 sınıf: 4 renk × 13 numara + 2 joker

### Aşama 3 — Final (Core ML)
- Google Colab'da MobileNet transfer learning
- Core ML'e export
- Uygulama içinde çalışır, internet gerekmez, sıfır maliyet

---

## Geliştirme Aşamaları

### Aşama 1 — Temel Altyapı
- [ ] Backend Express.js kurulumu
- [ ] SQLite veritabanı şeması
- [ ] Claude/Gemini Vision entegrasyonu
- [ ] Okey oyun mantığı (eski projeden adapte)
- [ ] Xcode SwiftUI proje kurulumu

### Aşama 2 — Core Özellikler
- [ ] Camera + galeri entegrasyonu (SwiftUI)
- [ ] Fotoğraf → Backend → Taş listesi akışı
- [ ] Taşların ekranda gösterimi
- [ ] El puanı hesaplama ve gösterim
- [ ] Apple Sign In

### Aşama 3 — Monetizasyon
- [ ] StoreKit 2 entegrasyonu
- [ ] Günlük limit mantığı
- [ ] Paket satın alma ekranı
- [ ] Apple receipt doğrulama (backend)

### Aşama 4 — AI İyileştirme
- [ ] Veri toplama altyapısı (fotoğraf kaydetme)
- [ ] Etiketleme arayüzü
- [ ] Core ML model eğitimi (Google Colab)
- [ ] Core ML entegrasyonu (tamamen cihaz içi)

### Aşama 5 — App Store
- [ ] App Store Connect kurulumu
- [ ] TestFlight beta testi
- [ ] App Store açıklaması ve görseller
- [ ] Yayın

---

## Klasör Yapısı

```
/101
├── PLAN.md                  ← bu dosya
├── OkeyApp/                 ← SwiftUI iOS projesi
│   ├── OkeyApp/
│   │   ├── App/
│   │   │   └── OkeyAppApp.swift
│   │   ├── Views/
│   │   │   ├── HomeView.swift
│   │   │   ├── CameraView.swift
│   │   │   ├── ResultView.swift
│   │   │   └── PackagesView.swift
│   │   ├── Models/
│   │   │   ├── Tile.swift
│   │   │   ├── GameResult.swift
│   │   │   └── User.swift
│   │   ├── Services/
│   │   │   ├── APIService.swift
│   │   │   ├── StoreKitService.swift
│   │   │   └── CameraService.swift
│   │   └── ML/
│   │       └── (ileride Core ML modeli buraya)
│   └── OkeyApp.xcodeproj
│
└── backend/                 ← Node.js API
    ├── src/
    │   ├── routes/
    │   │   ├── recognize.js
    │   │   ├── evaluate.js
    │   │   └── auth.js
    │   ├── services/
    │   │   ├── visionService.js
    │   │   └── okeyLogic.js
    │   ├── middleware/
    │   │   ├── auth.js
    │   │   └── rateLimit.js
    │   └── index.js
    ├── database/
    │   └── schema.sql
    ├── package.json
    └── .env.example
```

---

## Önemli Notlar

1. Apple Developer hesabı gerekli ($99/yıl) — App Store'a çıkmak için
2. Railway/Render ücretsiz tier yeterli başlangıç için
3. Gemini Flash API ücretsiz kota: günlük 1500 istek — başlangıç için yeterli
4. Eski `idk/` projesi referans: `idk/services/game-logic/src/index.js` oyun mantığı
5. Kullanıcı limitlerini backend'de tut — client-side limit atlatılabilir
