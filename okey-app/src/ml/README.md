# Core ML Modeli (İleride)

Bu klasör, kendi eğitilmiş Okey taşı tanıma modelini içerecek.

## Plan
1. Kullanıcı fotoğrafları backend'de biriktirilecek
2. Google Colab'da MobileNet ile transfer learning
3. Core ML formatına export (.mlmodel)
4. Bu klasöre eklenerek uygulamaya entegre edilecek

## Hedef
- 54 sınıf: 4 renk × 13 numara + 2 joker
- Her sınıf için 100-200 eğitim fotoğrafı
- Cihaz içi çalışma: internet gerekmez, sıfır API maliyeti
