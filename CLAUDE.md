# IntoTheYard — Proje Notları

Bu dosya, farklı bilgisayarlardaki (ev / işyeri) Claude Code oturumları arasında bağlam
köprüsü olarak kullanılır. Her oturum başında oku, her oturum sonunda güncelle.

## Şu an üzerinde çalışılanlar / devam eden işler

- v0.0.9.9e tamamlandı, test aşamasında
- Freeze VFX boyut/pozisyon (scale=0.5, pos=0,0) oyunda test edilmeli — karaktere göre ayar gerekebilir

## Bilinen sorunlar / takip edilmesi gerekenler

- Freeze VFX scale ve pozisyon karaktere göre ayarlanmamış, test sonrası düzeltilecek
- Calamity Lightning/Flame durum efektleri test edilmedi
- Leila kart sinerjileri (reaksiyon zinciri, Volatile Mixture, Catalyst Mind vb.) tam test bekliyor

## Notlar

- Detaylı sürüm notları için `güncelleme notları.txt` dosyasına bakılmalı.
- Commit mesajları Türkçe yazılıyor, format: kısa özet + (gerekirse) madde listesi.
- Düşman tipleri: subject, armed_subject, frantic_subject, heavy_subject,
  cyber_shotgun, cyber_shooter, cyber_rifle — her birinin sprite node ismi farklı
  (örn. `$ArmedSprite`, `$HeavySprite`, `$ShotgunSprite` vb.), kopyala-yapıştır
  yaparken bu isimleri değiştirmeyi unutma.
