# IntoTheYard — Proje Notları

Bu dosya, farklı bilgisayarlardaki (ev / işyeri) Claude Code oturumları arasında bağlam
köprüsü olarak kullanılır. Her oturum başında oku, her oturum sonunda güncelle.

## Şu an üzerinde çalışılanlar / devam eden işler

**Sprint 1 (2026-07-02 → 2026-07-09) — Stabilizasyon & Kritik Bugfix:**

- [ ] Elemental Memory logic implement et (duration logic yok, sadece flag var)
- [ ] Volatile Mixture çift tetik riski test et + guard ekle
- [ ] Living Storm + Static Charge sonsuz döngü riskini kır
- [ ] Calamity Lightning/Flame tam test (hasar + durum efekti doğrula)
- [ ] Leila reaksiyon zinciri tam test (Perfect Catalyst, Volatile Mixture, Catalyst Mind)
- [ ] Freeze VFX scale/pozisyon oyunda test et, karaktere göre ayarla
- [ ] Steam VFX scale/pozisyon tüm 7 düşman için test et
- [ ] v0.0.9.9f güncelleme notu yaz

## Kart Dengesi — Hedefler (2026-07-11)

Her karakter hedef: **65 kart**

| Kategori     | Vector | Leila | Cyclone |
|--------------|--------|-------|---------|
| Identity     | 9      | 14    | 3       |
| Utility      | 7      | 21    | 21      |
| Individuality| 19     | 5     | 18      |
| Calamity     | 0      | 5     | 5       |
| **Toplam**   | **35** | **45**| **47**  |
| **Eksik**    | **+30**| **+20**| **+18**|

- Vector: öncelik Calamity (0 → en az 4-5) + Identity
- Leila: Utility'yi kırp veya doldur, Identity/Individuality dengele
- Cyclone: Identity'yi artır (3 → en az 8-10), Ricochet/Static/Decay/Mirror eklenecek

## Bilinen sorunlar / takip edilmesi gerekenler

### Kritik Bug Riskleri (Playtester Raporu 2026-07-05)
- **Elemental Memory yanlış davranıyor**: `apply_burn()` burn_ticks'i 3→6 yapıyor DOĞRU, ama `apply_wet()` / `apply_electrified()` / `apply_slow()` `_had_reaction` flag'ini OKUYUP `dur *= 2.0` yapıyor. Flag reset edilmiyor — bir kez reaksiyon geçiren düşman sonraki tüm debuff'larda kalıcı 2× uzama alır. Bu kasıtlı mı kontrol edilmeli.
- **Volatile Mixture çift tetik riski ONAYLANDI**: `_check_reaction()` içinde Volatile Mixture kolu erken `return` ediyor, ama bazı yollarda (örn. `is_wet && is_slowed → apply_frozen()` dalı) `apply_frozen()` çağrılıyor; bu yeniden `_check_reaction("wet")` içine girmez, güvenli. Ancak `is_burning && is_wet → _react_steam()` + arkasından gelen `apply_burn()` (Perfect Catalyst üzerinden) çift steam riski var. Test gerekli.
- **Perfect Catalyst + Volatile Mixture sonsuz döngü**: Reaksiyon → `_notify_reaction()` → `apply_burn()` → `apply_burn()` erken `return` (is_burning guard var) → güvenli. Ama `apply_wet()` → `_check_reaction("wet")` → Volatile Mixture aktifse bir sonraki elementi tetikleyebilir. Döngü kırıcı yok.
- **Living Storm + Static Charge kombinasyonu**: Living Storm electrified düşman yaklaşınca `health -= 3` → `take_damage(0, false)` çağırmıyor, doğrudan health düşürüyor, Static Charge tetiklenmiyor. Fakat Living Storm hasarı `die()` çağırıyor; bu `_collapse → _become_ally / _escape` döngüsünü tetikler. Sonsuz döngü yok ama beklenmedik die() zincirleri olabilir.
- **Overheat eşiği global counter**: `_overheat_counter` Player'a bağlı, düşmana değil — tüm düşmanların burn tick'leri tek sayaca yazılıyor (hedeflenen davranış mı?). 13 eşiği: 4-5 aynı anda yanan düşmanla ~2-3 saniyede dolabilir, oldukça hızlı.
- **Cryostasis (index 70) Lv3 scaling yok**: `_apply_utility_level` içinde index 70 için case yok. Her alışta `freeze_duration_mult *= 1.1` uygulanıyor (elif'te), utility cap 3 seviye ama scaling tanımsız. Frozen Time (82) da aynı sorun.
- **Mana Overflow (index 90) implementasyonu eksik**: `has_mana_overflow = true` set ediliyor ama bu flag'i okuyan kod yok (game_scene.gd ve subject.gd'de yok). Kart alınıyor, hiçbir şey olmuyor.
- **Pyroblast (index 102) implementasyonu eksik**: Flag set edilmiyor, handler yok. Kart tamamen dead code.
- **Thermal Expansion (index 89) implementasyonu eksik**: Flag set edilmiyor, handler yok. Dead code.
- **Elemental Harmony Utility (index 84) implementasyonu eksik**: `has_elemental_harmony_util = true` set ediliyor ama bu flag'i okuyan kod yok.
- **Calamity Blizzard**: Tüm düşmanlara `apply_frozen()` çağırıyor, `apply_frozen()` `is_frozen` guard'ı var — güvenli. Ama freeze VFX (`static var _freeze_sf`) paylaşımlı; aynı frame'de 20+ düşman freeze olursa tek SpriteFrames instance çakışma yaratır mı? Test gerekli.
- **Volcanic Rift subject.take_damage() + apply_burn() çakışması**: `_activate_volcanic_rift` her 0.5 saniyede `apply_burn()` çağırıyor. `apply_burn()` içinde `is_burning` guard var, tekrar tetiklenmez. Ama `take_damage(2)` ayrı çalışıyor — her 0.5 saniyede 2 direkt hasar + burn tick'i = 4 sn toplam hasar potansiyeli yüksek, intentional mı?
- **Calamity slot dolduğunda ses/görsel feedback yok**: Slot dolu (size >= 3) olduğunda Calamity kartı seçilirse sessizce yok sayılıyor.
- **Prismatic Core min_level=4 ama rarity=rare**: Epic olmayan tek Lv4 core — inconsistency.
- **Chain Catalyst (index 106) min_level=1 ama rarity=uncommon, weight=6**: Lv1'den erişilebilir ama kombo potansiyeli çok yüksek; erken almak oyunu kırar.

### Daha önce bilinen sorunlar
- Calamity Lightning/Flame durum efektleri test edilmedi
- Leila kart sinerjileri tam test bekliyor
- Pain Converter + Glass Engine + Adrenal Armor System 2.73× combo — cap kararı verilmedi
- Electrocute / Melt / Overheat VFX yok (promptlar hazır, sprite yok)
- Cyclone kart sayısı bilinmiyor — kontrol edilmeli
- Fusion Zone kaldırıldı, güncelleme notlarına yazılmamış
- Cards Unlocked ekranı unlock_bg.png bağlantısı eksik
- Roadmap: C:\Project ITY\IntoTheYard\docs\roadmap.md

## Notlar

- Detaylı sürüm notları için `güncelleme notları.txt` dosyasına bakılmalı.
- Commit mesajları Türkçe yazılıyor, format: kısa özet + (gerekirse) madde listesi.
- Düşman tipleri: subject, armed_subject, frantic_subject, heavy_subject,
  cyber_shotgun, cyber_shooter, cyber_rifle — her birinin sprite node ismi farklı
  (örn. `$ArmedSprite`, `$HeavySprite`, `$ShotgunSprite` vb.), kopyala-yapıştır
  yaparken bu isimleri değiştirmeyi unutma.
