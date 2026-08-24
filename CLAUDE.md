# IntoTheYard — Proje Notları

Bu dosya, farklı bilgisayarlardaki (ev / işyeri) Claude Code oturumları arasında bağlam
köprüsü olarak kullanılır. Her oturum başında oku, her oturum sonunda güncelle.

## AKTİF SÜREÇ: Kart-kart Full Review (2026-08-21 başladı)

Her karakterin her kartı sırayla (Identity → Utility → Individuality → Calamity, kod
sırasına göre index artan) şu 4 başlıkta incelenip onaylanıyor:

1. **Implementasyon** — `game_scene.gd`'deki `elif index == N:` handler'ı + `ball.gd`/
   `player.gd`/`base_enemy.gd`'deki gerçek efekt kodu okunur, açıklamayla birebir eşleşiyor
   mu doğrulanır. Bug varsa düzeltilir (kullanıcı onayı ile).
2. **Requires/Requires_any** — kartın önkoşul zinciri mantıklı mı (örn. bir core'a bağımlı
   bir Utility, o core alınmadan havuza girmemeli) kontrol edilir, eksikse eklenir.
3. **Türkçe açıklama** — `lang.gd` içindeki `_DESC_TR` (statik) veya `_dynamic_desc()`
   (değişken sayılı kartlar için) güncellenir.
4. **İngilizce açıklama** — `game_scene.gd`'deki `upgrades` dizisindeki `desc` alanı
   (bu alan İngilizce fallback olarak kullanılıyor, `Lang.desc()` locale=="en" olduğunda
   bunu döndürür).

### Dinamik açıklama sistemi (bu session'da kuruldu)
- `game_scene.gd`'de kart açıklama Label'ı `RichTextLabel` + `bbcode_enabled=true`.
- `Lang.desc(index, fallback, player)` çağrısı önce `lang.gd`'deki `_dynamic_desc(index, player)`'a
  bakar — eğer o kartın sayısı **başka bir kart/upgrade ile değişebiliyorsa**, oraya bir
  `match index:` dalı eklenip `[b]%d[/b]` gibi BBCode ile canlı değer gösterilir.
  Sayısı hiç değişmeyen kartlarda dokunmaya gerek yok, eski statik `_DESC_TR` yeterli.
- Örnek: Armor Core (40) → `armor_gain_per_hit` (Impact Feedback ile artabiliyor),
  Anchor Core (41) → slow süresi (`slow_duration_mult`, Battlefield Anchor ile ×2 olabiliyor).
- Yeni bir kart incelerken **her zaman sor**: "bu sayıyı etkileyen başka bir kart var mı?"
  Varsa dynamic yap, yoksa statik bırak.

### İlerleme — Vector Identity (index sırasına göre)
- [x] Pierce Core (2) — heavy_subject'e %50 zırh eklendi (gri ton), Cyber-404'ün mevcut
      armor'ı da pierce'i bloklayacak şekilde `_has_active_armor()` helper'ı yazıldı.
      Desc: "Zırhı olmayan düşmanı deşip geçer" / "Pierces through unarmored enemies."
- [x] Armor Core (40) — **BUG FIX**: eski kod hem `can_armor` (sabit +1) hem az önce
      eklenen `has_armor_core` (armor_gain_per_hit) ile çift sayıyordu, `can_armor` bloğu
      silinip tek sisteme (armor_gain_per_hit, Impact Feedback ile scale eder) birleştirildi.
      Desc dynamic: "Düşmana vuruş → [b]N[/b] Armor kazandırır" / "Hit enemy → gain [b]N[/b] Armor"
- [x] Anchor Core (41) — implementasyon doğru (%60 yavaşlatma, 3sn, sadece düşmana çarpınca,
      7 basic + 3 boss'un tamamında geçerli, slow debuff ikonu mevcut). Süre
      `slow_duration_mult` (Battlefield Anchor ×2) ile değişebildiği için dynamic yapıldı;
      yavaşlatma yüzdesi (%60) hiç değişmiyor (Supercooling Leila-only, Vector run'ında
      hiç görünmez) o yüzden statik bırakıldı.
      Desc dynamic: "İsabet → düşman [b]N[/b] Saniye boyunca %60 yavaşlar" /
      "Hit enemy → slows 60% for [b]N[/b]s"
- [x] Crusher Core (42) — **BUG FIX**: "breaks Armor" sadece flavor text'ti, gerçek bir
      mekaniği yoktu. `ball.gd`'de zırhlı düşmana (heavy_subject) çarpınca `enemy_armor`
      anında sıfırlanacak + sprite modulate reset edilecek şekilde gerçek mekanik eklendi.
      Base hasar 12 → **9**'a düşürüldü (dengeleme, aşağıya bak).
      Desc dynamic: "İsabet → düşmanın Zırhını anında kırar" / "Hit → instantly breaks enemy Armor"
- [x] Siege Core (45) — implementasyon doğru, özel mekaniği yok, sadece "en yüksek hasar"
      kimliği (Siege Protocol + Siege Rain ile sinerjik). Base hasar 15 (değişmedi).
      Desc dynamic: "En yüksek hasarlı core" / "Highest damage core"
- [x] Kinetic Core (43) — implementasyon doğru: her duvar sekmesi sayaca ekleniyor,
      düşmana çarpınca base hasarın üstüne sayaç kadar bonus hasar ayrı `take_damage()`
      ile ekleniyor (crit/damage_mult'tan etkilenmiyor). Base hasar 7 (değişmedi).
      Desc dynamic: "Her duvar sekmesi → +hasar" / "Each wall bounce → +dmg"
- [x] Bulwark Core (44) — implementasyon doğru (+2 Armor sabit, Bulwark Echo ile 2s sonra
      yarısı tekrar). **DENGELEME**: Armor Core'u her yönden domine ediyordu (6 dmg+2 armor
      > 5 dmg+1 armor). Bulwark hasarı 6 → **3**'e düşürüldü. Ayrıca Impact Feedback (36)
      sadece Armor Core'un `armor_gain_per_hit`'ini büyütüyordu, Bulwark'ın sabit +2'si
      bundan hiç etkilenmiyordu — `requires: [40]` eklenerek Impact Feedback artık sadece
      Armor Core alınmışsa havuza giriyor (Bulwark'tan ayrıştırıldı, karıştırılmasın diye).
      Desc dynamic: "İsabet → +2 Armor" / "Hit → +2 Armor"
- [x] Tempered Core (47) — çalışıyor: base hasar 9 (+ball_mastery), Armor aktifken ayrı
      +3 sabit hasar (herhangi bir Armor kaynağından, tek bir core'a bağlı değil). Requires
      gerekmiyor (oyuncu zaten başlangıçta Armor'lu). Dynamic desc'e (2/40/41/42/43/44/45
      listesine) eklendi: "[b]N[/b] hasar.\nZırh aktifken → +3 hasar" / "...Armor active → +3 dmg".
- [x] Bloodbound Core (46) — çalışıyor: base hasar 8 (+ball_mastery), eksik HP'nin her 5'i
      için ayrı +1 bonus hasar (`take_damage()`, crit'ten etkilenmiyor). Eksik-HP kısmı
      kullanıcı isteğiyle dinamik yapılmadı (oyuncu kendi hesaplasın), sadece ball_mastery
      kısmı dynamic: "[b]N[/b] hasar.\nHer 5 eksik can için +1 bonus hasar" / "...Every 5
      missing HP → +1 bonus dmg".
- [x] Iron Aura Core (178) — **BUG FIX**: `_CONNECTED_CORE_INDICES`'te eksikti (178/179
      unutulmuştu, sadece 180-184 vardı) → yanlış limit havuzuna (`special_core_count`
      yerine `connected_core_count`) sayılıyordu + Connected Core rozetini almıyordu, ikisi
      de düzeltildi. Hasar Core Mastery'den etkilenmiyor (ayrı `_inner_core_tick()` yolu,
      `_hit_subject()`'e hiç girmiyor) — dynamic'e gerek yok. Dil bug'ı: `desc` alanı
      (İngilizce olması gereken yer) Türkçe yazılmıştı, `_DESC_TR`'de hiç girdi yoktu →
      ikisi de ayrıştırıldı ve düzeltildi. **Bu dil bug'ı 178-184 arası tüm yeni Connected
      Core'larda muhtemelen var, sırayla kontrol edilip düzeltilecek.**
- [x] Momentum Field Core (179) — aynı `_CONNECTED_CORE_INDICES` bug'ı + aynı dil bug'ı
      düzeltildi. Stack üretimi (hareket ederken 1s'de +1) önkoşulsuz çalışıyor ama
      stack'lerin Core Speed'e dönüşmesi sadece `has_momentum_engine` (Momentum Engine
      kartı) varsa oluyor — Overcharge Core (183) / Kinetic Surge (171) ise stack'i
      doğrudan (Momentum Engine'siz) kullanıyor. Bu yüzden `requires_any: [35, 171, 183]`
      eklendi (üçünden biri alınmadan havuza girmiyor, faydasız pick riski önlendi).
- [x] Regen Pulse Core (180) — çalışıyor, her 15s +1 Armor. `gain_armor()` fonksiyonu
      birden fazla çarpan içeriyor (Pain Converter/Glass Engine/Adrenal Armor/Momentum
      Cascade = HP/Momentum durumuna bağlı, Iron Constitution/Overclocked Reflex/Risk
      Engine = `armor_gain_mult`, kart kaynaklı kümülatif). Kullanıcı kararı: sadece
      **kart-kaynaklı** çarpan (`armor_gain_mult`) dynamic'e yansıtıldı, HP/Momentum bazlı
      olanlar hariç tutuldu. Aynı dil bug'ı düzeltildi.
- [x] Fortress Core (181) — çalışıyor, Armor %75+ doluyken 90px'e sürekli %25 yavaşlatma
      (her frame yenilenen kısa süreli slow). **BUG FIX**: `apply_slow()` çağrısı `source`
      parametresini geçmiyordu → varsayılan "cryo" ile Leila'nın buz VFX'i yanlışlıkla
      düşmanda oynuyordu; Anchor Core'daki gibi `"anchor"` source'u eklenip VFX engellendi.
      Sayılar (%75, 90px, %25) hiçbir kartla değişmiyor, statik kaldı. Aynı dil bug'ı
      düzeltildi.
- [x] Bloodwall Core (182) — çalışıyor, HP %50 altındayken her 9s +1 HP. **BUG FIX**:
      `gfx.player_hp` direkt değiştiriliyordu ama `gfx.update_ui()` çağrılmıyordu — HP
      bar'ı iyileşmeyi anında göstermiyordu, eklendi. Aynı dil bug'ı düzeltildi.
- [x] Overcharge Core (183) — çalışıyor, Momentum 15+ iken her 4s 60px'e 2 hasar pulse.
      `requires_any: [35, 109, 179]` eklendi (Momentum Engine / Steel Rhythm / Momentum
      Field Core — momentum_stacks'i üreten tek yollar bunlar, hiçbiri yoksa kart tamamen
      pasif kalıyordu). Aynı dil bug'ı düzeltildi.
- [x] Anchor Pulse Core (184) — çalışıyor, 5s hareketsizlik sonrası her 1s +1 Armor
      (sayaç sıfırlanmıyor, bilinçli olarak sürekli tekrarlıyor — bug değil, açıklamayla
      birebir örtüşüyor). `armor_gain_mult` (kart-kaynaklı) dynamic'e eklendi, aynı dil
      bug'ı düzeltildi.

**VECTOR IDENTITY TAMAMLANDI (16/16 kart) — 2026-08-22**

### SIRADAKİ AŞAMA: Vector Utility
Henüz başlanmadı. Vector Utility kartları `game_scene.gd`'de `"category": "Utility"` ve
`"chars": ["vector"]` filtresiyle bulunabilir (index'ler dağınık, örn. 35-38, 171-172 gibi
Identity kartlarının arasına serpiştirilmiş — sıralı bir blok değil, dikkatli taranmalı).
Aynı 4 aşamalı süreç (İmplementasyon → Requires → TR açıklama → EN açıklama) uygulanacak.

### UI eklentisi: Connected Core tooltip (2026-08-22)
- Connected Core rozetinin ("◈ Bağlantılı Core") üzerine gelince artık native Godot
  tooltip'i açılıyor: "Bu core fırlatılamaz — sürekli oyuncunun etrafında döner." (EN
  karşılığı da eklendi, `lang.gd` → `ui_connected_core_tooltip`).
- ÖNEMLİ implementasyon notu: tooltip badge Label'ına değil, kartın tamamını kaplayan ve
  badge'in üstünde duran `click_area` (Button) node'una eklendi — çünkü `click_area` daha
  sonra oluşturulup üstte kaldığı için mouse hover'ı önce o yakalıyor, badge'e asla
  ulaşmıyordu. Yeni bir hover/tooltip eklenecekse bu sıralamaya dikkat edilmeli.

Sonrası: Vector Utility → Vector Individuality → Vector Calamity → aynı süreç Leila ve
Cyclone için de tekrarlanacak (Cyclone Identity/Utility/Individuality zaten önceki session'da
tam review edilmişti, tekrar gerekmiyor — sadece Vector ve Leila eksik).

### KRİTİK BUG FIX: Core Mastery hiç çalışmıyordu (2026-08-22)
- Ortak havuzdaki **Core Mastery** kartı ("+1 damage to all cores") aslında hiçbir tipli
  core'u etkilemiyordu. `ball.gd`'deki `_hit_subject()` içinde `base_damage = max_damage`
  (ball_mastery dahil) ile başlıyor ama hemen ardından **her tipli core için sabit sayıyla
  eziliyordu** (`elif can_pierce: base_damage = 10` gibi) — `max_damage` ve içindeki
  `ball_mastery` bonusu tamamen atılıyordu. Sadece tipsiz/normal top (Identity core
  alınmadan önce) bundan faydalanıyordu.
- **Fix**: `_typed_core` flag'i eklendi, tipli core ise elif zincirinden sonra
  `base_damage += ball_mastery` ekleniyor; tipsiz top zaten `max_damage`'dan geldiği için
  çift sayılmıyor.
- Artık **tüm Identity core açıklamaları dinamik** — hasar sayısı Core Mastery alındıkça
  `[b]N[/b]` ile canlı güncelleniyor. Aynı düzeltme deseni yeni kart eklenince (Siege,
  Kinetic, Bulwark, Bloodbound, Tempered) her birine tek tek uygulanmalı.

### Base hasar dengeleme (2026-08-22)
Review sırasında bulunan tutarsızlıklar düzeltildi:
| Core | Eski | Yeni | Sebep |
|------|------|------|-------|
| Pierce (2) | 10 | **5** | Piercing (çoklu düşman) zaten güçlü bir avantaj, üstüne yüksek hasar abartıydı |
| Armor (40) | 5 | **4** | Bulwark ile dengelemek için düşürüldü |
| Crusher (42) | 12 | **9** | Zırh kırma bedava bonus, Siege'in (15) altında kalmalı |
| Bulwark (44) | 6 | **3** | Armor Core'u her yönden domine ediyordu (daha çok hasar + 2× armor) |

`ball.gd` (hasar hesabı) + `ball_launcher.gd` (spawn/fusion max_damage) + `lang.gd`
(dinamik açıklama) + `game_scene.gd` (EN fallback açıklama) — 4 dosyada senkron tutulmalı,
biri unutulursa sayılar tutarsız görünür.

## Ev Session Notları (2026-08-21)

- **Cyclone kart art sistemi baştan başlatıldı** — Identity (17/17), Utility (23/23),
  Individuality (18/18) tamamlandı. Calamity kısmen tamam (art eksikleri var, kontrol
  edilmeli). Toplamda Cyclone'un görsel eksiği kalmadı denecek durumda.
- **AntiVirus Core → Virus Core** olarak yeniden adlandırıldı (`game_scene.gd`), internal
  key (`antivirus_core`) değişmedi, sadece display name.
- **Static Aura Core** bug fix: per-enemy 3s cooldown eksikti (sadece `is_electrified`
  guard'ı vardı, düşman debuff bitince hemen tekrar tetikleniyordu). `_static_aura_cd`
  Dictionary (instance_id → time_left) eklendi, `ball.gd`.
- **Catalyst Pulse Core** tetik süresi 5s → 3s düşürüldü (kullanıcı "çok uzun" dedi).
- **Supercooling / Thermal Vision** açıklamaları netleştirildi: Supercooling "Cryo Slow
  +%15", Thermal Vision "Burn tick hasarı +%20" (önceden belirsiz "daha fazla" ifadeleri
  vardı).
- **Vector + Leila kart art'ları doğrulandı**: Vector %100 tam. Leila'da sadece Tempest
  Core + Prismatic Core eksik görünüyor ama bu ikisi zaten oyundan silinmiş kartlar
  (xlsx'te kalıntı kayıt), yani Leila da fiilen tam.
- Kart art dosya adı otomasyonu doğrulandı: `kart_adı.to_lower().replace(" ","_") + "_art.png"`
  — doğru klasöre (`Identity/Utility/Individuality/Calamity`) atılan her PNG otomatik yükleniyor.

## Şu an üzerinde çalışılanlar / devam eden işler

**Sprint 1 (2026-07-02 → 2026-07-09) — Stabilizasyon & Kritik Bugfix:**

- [ ] Elemental Memory logic implement et (duration logic yok, sadece flag var)
- [ ] Volatile Mixture çift tetik riski test et + guard ekle
- [ ] Living Storm + Static Charge sonsuz döngü riskini kır
- [ ] Calamity Lightning/Flame tam test (hasar + durum efekti doğrula)
- [ ] Leila reaksiyon zinciri tam test (Perfect Catalyst, Volatile Mixture, Catalyst Mind)
- [x] Freeze VFX scale/pozisyon oyunda test et, karaktere göre ayarla
- [x] Steam VFX scale/pozisyon tüm 7 düşman için test et
- [ ] v0.0.9.9f güncelleme notu yaz

**Devam eden (2026-07-13):**
- [ ] Vector +30 kart (öncelik: Calamity 0→4-5, Identity)
- [ ] Leila +20 kart
- [ ] Cyclone +18 kart (Ricochet/Static/Decay/Mirror implementasyonu)

**Meta Progression (2026-07-29) — TAMAMLANDI:**
- [x] Chip para birimi eklendi (kalıcı, run'lar arası)
- [x] Düşman kill milestone'ları (7 tür + boss, 3-5 eşik)
- [x] Core fire milestone'ları (tüm tipler, 3 eşik)
- [x] Run sonu ekranına Chip göstergesi eklendi
- [x] Chip Mağazası eklendi — 6 kalıcı upgrade (karakter seçim ekranı)
- [x] Cesetler kalıcı yapıldı (fade out kaldırıldı)
- [x] Başlangıç core sayısı 5 → 3'e indirildi

**Sıradaki adımlar (2026-07-29):**
- [ ] Milestone ilerleme göstergesi (mağaza veya ayrı ekran — "47/100 subject")
- [ ] Chip Mağazasına yeni upgrade'ler ekle (ilerleyen sürümde)
- [ ] Kart dengesi: Vector Calamity (0 → en az 4-5 kart)
- [ ] Bug listesi: Elemental Memory, Volatile Mixture çift tetik, Living Storm döngüsü

**v0.1.3.0 (2026-07-30) — TAMAMLANDI:**
- [x] Chip collect mekanizması — milestone tamamlanınca otomatik değil, COLLECT butonu ile alınır
- [x] Görevler + Black Market sol panele taşındı (sade metin butonlar)
- [x] Başarım ekranı kategorilere ayrıldı, scrollable
- [x] Yeni başarım kategorileri: Reaksiyonlar, Hayatta Kalma, Karaktere Özel Kill, Upgrade, 3 Element/run
- [x] Yeni kalıcı sayaçlar: reaction_counts, char_kills, total_upgrades_taken, calamity_filled_count, survival milestones, run_3element_count

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

> **Not (2026-07-17 Playtester):** Kod sayımına göre mevcut kartlar: Vector ~63, Leila ~64, Cyclone ~62.
> Tablodaki sayılar eski — yeni eklenen kartlar (index 164-223 arası blok) tabloya yansıtılmamış.

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
- ~~**Mana Overflow (index 90) implementasyonu eksik**~~ — **TAMAMLANDI**: `player.gd:639-641`'de Calamity sonrası 5 sn +%50 Core Speed uygulanıyor.
- ~~**Pyroblast (index 102) implementasyonu eksik**~~ — **TAMAMLANDI**: `base_enemy.gd:336-337`'de `_react_overheat` içinde radius counter×8 px büyüyor.
- ~~**Thermal Expansion (index 89) implementasyonu eksik**~~ — **TAMAMLANDI**: `base_enemy.gd:669-676`'da `_react_steam` radius 120→200 genişliyor, ıslak efekt de yayılıyor.
- ~~**Elemental Harmony Utility (index 84) implementasyonu eksik**~~ — **TAMAMLANDI**: `game_scene.gd:3556-3564` + `player.gd:643-644`'te aktif unique element başına +%5 Core Speed uygulanıyor.
- **Calamity Blizzard**: Tüm düşmanlara `apply_frozen()` çağırıyor, `apply_frozen()` `is_frozen` guard'ı var — güvenli. Ama freeze VFX (`static var _freeze_sf`) paylaşımlı; aynı frame'de 20+ düşman freeze olursa tek SpriteFrames instance çakışma yaratır mı? Test gerekli.
- **Volcanic Rift subject.take_damage() + apply_burn() çakışması**: `_activate_volcanic_rift` her 0.5 saniyede `apply_burn()` çağırıyor. `apply_burn()` içinde `is_burning` guard var, tekrar tetiklenmez. Ama `take_damage(2)` ayrı çalışıyor — her 0.5 saniyede 2 direkt hasar + burn tick'i = 4 sn toplam hasar potansiyeli yüksek, intentional mı?
- **Calamity slot dolduğunda ses/görsel feedback yok**: Slot dolu (size >= 3) olduğunda Calamity kartı seçilirse sessizce yok sayılıyor.
- **Prismatic Core min_level=4 ama rarity=rare**: Epic olmayan tek Lv4 core — inconsistency.
- **Chain Catalyst (index 106) min_level=1 ama rarity=uncommon, weight=6**: Lv1'den erişilebilir ama kombo potansiyeli çok yüksek; erken almak oyunu kırar.

### Playtester Raporu Bulguları (2026-07-17)

**Denge sorunları:**
- **Echo Core (Cyclone, index 19) min_level=0, rarity=epic, weight=1**: Lv0'dan erişilebilen tek epic core — diğer epic'ler Lv3-5. Weight:1 nadir tutuyor ama karşılaşılabilir. min_level en az 2-3'e çekilmeli.
- **Momentum Engine (index 35) common weight=8, min_level=0**: 20 stack × %3 hız = +60% max hız buff. Oyunun en güçlü scaling kartlarından biri common rarity'de. En azından weight düşürülmeli veya rarity uncommon yapılmalı.
- **Calamity Lightning/Flame Zone (index 7/8) weight=8, rarity=common, min_level=0**: Diğer tüm Calamity kartları epic/legendary (weight 2-3). Bu ikisi hem common hem weight:8 — çok sık Calamity sunuluyor, slotlar hızla dolabilir. Rarity/weight inconsistency.
- **Glitch Bomb (index 215) + Antivirus Rain (index 217) weight=5, rarity=rare**: Cyclone'un diğer Calamity'leri legendary (weight:2). Bunlar rare/weight:5, oranlama tutarsız.
- **Deep Freeze (index 208) weight=4, rarity=rare**: Leila'nın legendary Calamity'leri weight:2. Deep Freeze rare ama weight 2 değil 4 — inconsistency.

**Dead Code kartları (2026-07-17 teyit → 2026-07-17 TAMAMLANDI):**
- 4 kart da implement edilmiş durumda (base_enemy.gd + player.gd + game_scene.gd). CLAUDE.md notları eskiydi.

**Kart sayısı tablosu güncel değil:**
- Tablodaki Vector:35/Leila:45/Cyclone:47 sayıları yeni eklenen index 104-223 bloğunu yansıtmıyor.
- Gerçek mevcut sayılar (yaklaşık): Vector ~63, Leila ~64, Cyclone ~62.
- Kart dengesi tablosunu güncelle + gerçek sayımı doğrula.

### Daha önce bilinen sorunlar
- Calamity Lightning/Flame durum efektleri test edilmedi
- Leila kart sinerjileri tam test bekliyor
- Pain Converter + Glass Engine + Adrenal Armor System 2.73× combo — cap kararı verilmedi
- Electrocute / Melt / Overheat VFX yok (promptlar hazır, sprite yok)
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
