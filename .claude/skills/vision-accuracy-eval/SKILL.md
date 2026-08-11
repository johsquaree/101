---
name: vision-accuracy-eval
description: Okey taş tanıma (vision) doğruluğunu kullanıcı düzeltme verisiyle test eder. "taş tanıma doğruluğunu kontrol et", "vision prompt'unu test et", "eval çalıştır" gibi isteklerde kullan.
---

# Vision Doğruluk Eval'i

## Ne yapar
`backend/scripts/evalAccuracy.js`, `photo_archive` tablosundaki (`corrected_tiles` dolu olan) geçmiş fotoğrafları kullanıcının yaptığı düzeltmeyi "doğru cevap" (ground truth) kabul edip mevcut `visionService.recognizeTiles()` fonksiyonunu bu fotoğraflar üzerinde yeniden çalıştırır. AI'ın tahmini ile kullanıcı düzeltmesini karşılaştırıp taş bazında doğruluk yüzdesi ve hata türü dağılımı (renk karışıklığı / sayı karışıklığı / kayıp taş / fazla taş) verir.

## Ne zaman kullan
- Kullanıcı "vision prompt'unu değiştirdim, doğruluk arttı mı" diye sorduğunda
- `visionService.js` içindeki prompt, model veya tool şeması değiştirildiğinde, commit atmadan önce regresyon kontrolü olarak
- Kullanıcı taş tanıma hatalarından şikayet ettiğinde kök nedeni (hangi renk/sayı çiftleri karışıyor) anlamak için

## Nasıl çalıştırılır
```
cd backend
npm run eval
```

İsteğe bağlı `--limit N` ile son N düzeltilmiş kayıtla sınırlanabilir (varsayılan: tümü).

Ön koşul: `ANTHROPIC_API_KEY` ve `DB_PATH` ortam değişkenleri gerçek veriyi gösteren değerlere ayarlı olmalı (prod DB'nin bir kopyası üzerinde çalıştırmak daha güvenli — script salt-okunur açıyor ama yine de canlı DB dosyası üzerinde çalışmamaya dikkat et).

## Sonucu yorumlarken
- **Genel doğruluk düşükse (%80 altı):** prompt veya model seçimi zayıf demektir, `visionService.js` PROMPT sabitini gözden geçir
- **"renk-karisikligi" çoğunluktaysa:** ışık/gölge kaynaklı olabilir, kullanıcıya fotoğraf çekim tavsiyesi (düz ışık, taşları yayarak çekme) veya prompt'a renk ayırt etme talimatı eklenmeli
- **"sayi-karisikligi" çoğunluktaysa:** çift haneli sayı okuma sorunudur (10 ile 1, 12 ile 2 karışması gibi), prompt'a bu spesifik uyarı eklenmeli
- **Belirli bir kayıt sürekli hatalıysa:** o fotoğrafı (`image_path`) manuel incele, açı/netlik sorunu olabilir

## Yeni veri biriktikçe
`corrected_tiles` verisi arttıkça bu eval seti büyür ve daha güvenilir hale gelir. Prompt/model değişikliği yapmadan önce ve sonra eval'i çalıştırıp sayıları karşılaştırmak, değişikliğin gerçekten iyileştirme mi yoksa regresyon mu olduğunu gösterir.
