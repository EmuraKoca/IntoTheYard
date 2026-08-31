# IntoTheYard — Proje Notları

Bu dosya, farklı bilgisayarlardaki (ev / işyeri) Claude Code oturumları arasında bağlam
köprüsü olarak kullanılır. Her oturum başında oku, her oturum sonunda güncelle.

## Momentum Mekaniği — Baştan Tasarım (2026-08-22, TEST BEKLİYOR)

Vector Utility review'i sırasında Momentum sisteminin dağınık/tutarsız olduğu fark edildi
(6 farklı bağımsız üretici, görsel geri bildirim yok, hiç tükenmiyor). Kullanıcı ile
tasarım baştan konuşuldu, şu hale getirildi — **henüz evde test edilmedi, doğrulanması
gerekiyor**:

### Yeni mimari
- **Momentum Engine (35)** artık sistemin TEK kapısı. Bu kart alınmadan:
  - Momentum hiç birikmiyor (üretim mantığı `player.gd::_physics_process`'e taşındı,
    `has_momentum_engine` şartına bağlı).
  - HUD'daki Momentum bar'ı hiç görünmüyor (`game_scene.gd::_process`'te
    `p.has_momentum_engine` kontrolü eklendi).
  - Üretim: yürürken her 4s'de +1 stack (`MOMENTUM_GEN_INTERVAL`), +%3 Core Hızı/stack,
    maks 20 stack (Lv2:%5/Lv3:%7, maks 30 Lv3'te — mevcut level scaling korundu).
- **Momentum Field Core (179)** artık bağımsız üretici DEĞİL — Momentum Engine'in
  üretimine **+1 ekleyen bir çarpan**. Kendi `_inner_core_tick()` mantığı boşaltıldı
  (`pass`), `has_momentum_field_core` flag'i pickup handler'da set ediliyor, üretim
  formülünde (`player.gd`) okunuyor.
- **Armor Rush (164)** yeniden tasarlandı: eski "Armor kazanınca +1 Momentum" kaldırıldı,
  yerine "Momentum ≥ eşik → Armor kazanımına anlık +1" geldi. **Kalıcı değil** — her
  `gain_armor()` çağrısında canlı kontrol ediliyor, momentum eşiğin altına düşerse bonus
  da otomatik kayboluyor (state saklanmıyor). Eşik: Lv1:13, Lv2:11, Lv3:9.
- **Momentum Transfer (169)** Utility'den **Individuality**'ye taşındı, tek seviyeli oldu:
  "Armor ilk kez sıfırlanınca → o anki TÜM Momentum stack'i ×2 Armor'a döner" — run başına
  **sadece 1 kez** tetikleniyor (`_momentum_transfer_used` flag'i, bir daha asla
  çalışmıyor). Roguelike "ilk ölümden dirilme" mantığının Armor/Momentum versiyonu.
- **Requires:** Pressure Valve (104), Momentum Cascade (108), Overcharge Core (183),
  Kinetic Surge (171), Momentum Field Core (179), Armor Rush (164), Momentum Transfer
  (169) — hepsi artık tek `requires: [35]` (eski requires_any listeleri kaldırıldı,
  Momentum Engine tek kapı).
- **Dokunulmadı (kullanıcı isteğiyle, Individuality review'inde ele alınacak):**
  Steel Rhythm (109), Risk Engine (60), Adrenal Surge (32) — bunlar da momentum kartları
  ama henüz eski mantıklarıyla duruyor, sıra gelince yeniden gözden geçirilecek.

### Ayrıca eklenen: Momentum tükenmesi (Yasuo tarzı)
`player.gd::_physics_process`'e eklendi: oyuncu 3s hareketsiz kalırsa, o andan itibaren
her 3s'de 1 stack kaybediliyor (`_momentum_still_time`, `_momentum_decay_acc`). Hareket
edince ikisi de anında sıfırlanıyor. Kaynağı ne olursa olsun tüm stack'leri etkiliyor.

### Merkezi `gain_momentum()` — hâlâ geçerli
Önceki session'da kurulan merkezi fonksiyon (`player.gd`) korunuyor, yeni üretim yolu da
(Momentum Engine'in 4s tick'i) buradan geçiyor — Pressure Valve doğru saymaya devam ediyor.

### BUG FIX (2026-08-25): Momentum yürümeden de birikiyordu
Kullanıcı test sırasında fark etti — `ball.gd`'de Momentum Engine'in **eski vuruş-bazlı
üretim kodu** ("isabet başına +1 stack, Fortified Core: %20 ihtimalle atla") silinmemiş
kalmıştı, hareket şartına hiç bakmadan her core isabetinde tetikleniyordu. Tamamen
kaldırıldı — artık gerçekten **tek üretim kaynağı hareket**.
- Yan etki: **Fortified Core System (Individuality, index 50)** — "Armor Cap +15 /
  Momentum gain -%20" — cezası (`momentum_gain_mult`) artık hiçbir yerde okunmuyor,
  sadece bedava +15 Armor Cap kalmış kart haline geldi. **Henüz düzeltilmedi**, Vector
  Individuality review'inde (bu kart zaten o kategoride) ele alınacak.
- **Momentum Zone (`momentum_zone.gd`) komple silindi** — kontrol edilince hiçbir sahneye
  bağlı olmadığı, hiçbir yerden spawn edilmediği anlaşıldı (tamamen ölü/kullanılmayan
  eski bir fikir, kullanıcı onayıyla dosya silindi). "Tek üretim kaynağı hareket" kuralını
  bozan üçüncü bir gizli yol da böylece ortadan kalkmış oldu.

### YAPILACAK (bir sonraki session)
- [ ] **Evde test et**: Momentum Engine almadan bar'ın gizli kaldığını, alınca SADECE
      hareketle (vuruşla değil) stack biriktiğini, durunca 3s sonra tükendiğini, Armor
      Rush'ın eşik altına düşünce bonusu kaybettiğini, Momentum Transfer'in Armor ilk
      sıfırlanışta bir kez tetiklenip bir daha çalışmadığını doğrula.
- [ ] Sorun çıkarsa bildir, birlikte düzeltilecek.
- [ ] Fortified Core System (50) düzeltmesi Individuality review'i sırasında yapılacak.
- [ ] Steel Rhythm / Risk Engine / Adrenal Surge'ü de bu yeni mimariye göre gözden geçir
      (Individuality review'i sırasında zaten planlı, henüz dokunulmadı).

## Yeni HUD: Sol Üst Health + Momentum Bar (2026-08-25, TEST BEKLİYOR)

Kullanıcı, sağ paneldeki eski `IntegrityBar`'ı sol üste taşımak ve altına yeni bir
Momentum bar eklemek istedi. Pixellab.ai ile iki özel asset üretildi (Vector'ın renk
paletine uygun, cyberpunk stil, içi şeffaf/boş — dolgu Godot'ta ayrı katman olarak
ekleniyor):
- `assets/hudBars/vector/health_bar_frame.png` (161×28, iç dolgu alanı x:5-155 y:11-22)
- `assets/hudBars/vector/momentum_bar_frame.png` (161×18, iç dolgu alanı x:36-143 y:6-11)
- İleride Cyclone (yeşilimsi) ve Leila (pembemsi) için de aynı isimlerle ayrı klasörler
  gelecek (`assets/hudBars/cyclone/`, `assets/hudBars/leila/`), momentum bar'ı ise
  sadece Vector'a özgü.

### Godot tarafı (`game_scene.tscn`)
- Yeni node'lar `UI` altında: `HealthBar2` (Control, sol üst 20,20 — 322×56, 2× ölçek) ve
  `MomentumBar` (Control, 20,84 — 322×36). Her ikisinde de `Fill` (ProgressBar, şeffaf
  background stylebox + renkli fill stylebox, interior rect'e göre pozisyonlanmış) +
  `Frame` (TextureRect, `expand_mode=1 stretch_mode=0 texture_filter=1` — pixel-perfect
  stretch) + `Label` yapısı var.
- Eski `IntegrityBar` **silinmedi**, sadece karaktere göre `visible` toggle ediliyor
  (`game_scene.gd::_ready()`): Vector'da gizli+HealthBar2 görünür, diğer karakterlerde
  eskisi gibi görünür+HealthBar2/MomentumBar gizli.

### BUG FIX: Armor gri overlay'i eski yerde kalıyordu
`_setup_armor_bar()`/`_update_armor_ui()` fonksiyonları Armor'un gri katmanını hep
`$UI/IntegrityBar`'ın konumuna göre çiziyordu — IntegrityBar gizlenince overlay boşlukta
kalmış gibi görünüyordu. Yeni `_get_hp_bar_rect()` helper'ı eklendi (karaktere göre doğru
bar'ın — HealthBar2/Fill ya da eski IntegrityBar — mutlak rect'ini döndürüyor), her iki
fonksiyon da buna yönlendirildi.

### YAPILACAK (bir sonraki session)
- [ ] **Evde test et**: PNG'lerin doğru yerleştiğini, Health/Momentum bar'ların doğru
      konumda/boyutta göründüğünü, Armor gri katmanının artık doğru yerde çizildiğini
      doğrula.
- [ ] Sağ paneli tamamen "alınan güçlendirmeler" listesine ayırma işi hâlâ yapılmadı
      (kullanıcı bunu ayrı bir tur olarak bıraktı — Level/Toplar/Süre/Yakalama/Fusion
      Energy/Calamity elemanlarının yeniden konumlandırılması gerekiyor).

### BUG FIX (build hatası, 2026-08-25): ball.gd satır başı boşluk karakteri
`ball.gd:1882`'de (Bulwark Echo bloğu) satır başında tab'lardan önce fazladan bir boşluk
karakteri sızmıştı (muhtemelen concurrent bir edit'ten) — Godot "mixed tabs/spaces" hatası
verip crash oluyordu. Python ile byte-level tespit edilip düzeltildi. Not: bu tür
görünmez whitespace sorunları normal `Read`/`grep` ile bazen yakalanamayabilir, şüphe
varsa `python3` ile raw byte taraması yap.

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

### İlerleme — Vector Utility (15 kart, kod sırasına göre) — TAMAMLANDI (2026-08-22)
- [x] Momentum Engine (35) — çalışıyor. Level scaling: `momentum_speed_bonus` Lv1:%3
      Lv2:%5 Lv3:%7, `momentum_max` Lv1-2:20 Lv3:30. İsabet sadece düşmana çarpınca sayılıyor
      (duvar sekmesi saymıyor, `_hit_subject()` içinde). Dynamic desc eklendi.
- [x] Chain Density (37) — çalışıyor: uçuşta yeni düşmana ilk çarpışta sayaç +1, bonus
      `sayaç × chain_density_bonus_per_hit` (Lv1:1 Lv2:2 Lv3:3), dönüşe geçince sıfırlanıyor
      (`_start_returning()`). Dynamic desc eklendi.
- [x] Impact Feedback (36) — **BUG FIX (mimari)**: sayaç (`impact_hit_count`) player-level
      paylaşımlıydı, hiç sıfırlanmıyordu (run boyu kümülatif) → Kinetic Rogue deseniyle
      per-ball'a çevrildi (`_impact_hit_acc`, launch/launch_with_speed/add_to_orbit'te
      sıfırlanıyor). Açıklama da netleştirildi ("Armor Core kazanımı kalıcı +1 artar" —
      "direkt zırh puanı" karışıklığı önlendi). `impact_feedback_threshold` Lv1:10 Lv2:7
      Lv3:5. `armor_gain_per_hit`'e kalıcı etki, hangi core vurursa vursun sayaç artıyor
      (ödül sadece Armor Core'a yansıyor).
- [x] Last Stand (38) — **BUG FIX**: Core Speed bonusu (`last_stand_bonus`) tamamen
      `has_momentum_engine and momentum_stacks > 0` şartının içindeydi → Momentum Engine
      yoksa kart tamamen pasif kalıyordu, bağımsız hale getirildi (`elif` dalı eklendi).
      `last_stand_hp_mult`/`last_stand_armor_mult` Lv1:0.5%/0 Lv2:0.8%/0.003 Lv3:1.2%/0.005
      (Armor Gain verimliliği sadece Lv2-3'te aktif). Dynamic desc Lv1'de tek satır,
      Lv2-3'te ikinci satırı koşullu ekliyor.
- [x] Pressure Valve (104) — **BUG FIX (mimari + kapsam)**: `_pressure_valve_acc` artışı
      sadece Momentum Engine'in kendi RNG şansına (`randf() < momentum_gain_mult`) bağlıydı,
      Momentum Field Core/Steel Rhythm/Armor Rush/Momentum Transfer/Risk Engine'den gelen
      stack'leri hiç saymıyordu. **Merkezi `player.gain_momentum(amount)` fonksiyonu
      kuruldu** — artık tüm momentum kaynakları (ball.gd, base_enemy.gd, game_scene.gd,
      momentum_zone.gd) buradan geçiyor, Pressure Valve hepsini doğru sayıyor.
      `requires_any: [35, 60, 109, 164, 169, 179]` eklendi. `pressure_valve_threshold`
      Lv1:5 Lv2:4 Lv3:3.
- [x] Momentum Cascade (108) — `requires_any` (aynı 6 kart) eklendi. Level scaling —
      **kullanıcı kararıyla tasarım değişti**: ilk önerim (eşik sabit, çarpan büyüsün)
      yerine tam tersi seçildi (çarpan sabit ×1.5, eşik düşsün): `momentum_cascade_threshold`
      Lv1:12 Lv2:10 Lv3:8.
- [x] Bulwark Surge (110) — Armor≥eşik → Core Speed ×mult. Level scaling: eşik Lv1-2:%75
      Lv3:%60, çarpan Lv1:1.15 Lv2:1.20 Lv3:1.30. Kullanılmayan `bulwark_surge_active`
      flag'i temizlendi (gerçek hesap zaten player.gd'de bağımsız yapılıyordu).
- [x] Armor Rush (164) — Armor kazanınca +N Momentum (miktar önemli değil, "kazanıldı mı"
      şartı yeterli — Armor Core 3 versin yine +1 sayılır). Level scaling: `armor_rush_
      stack_amount` Lv1:1 Lv2:2 Lv3:3. Armor Rush + Pressure Valve zincirleme riski
      kontrol edildi — minimum eşik 3 olduğu için sonsuz döngü oluşmuyor, güvenli.
- [x] Combat Rhythm (165) — **BUG FIX (mimari)**: `_combat_rhythm_count` player-level
      paylaşımlıydı (Kinetic Rogue'un eski hatasıyla aynı) → per-ball'a çevrildi
      (`_combat_rhythm_acc`, 3 launch/return noktasında sıfırlanıyor). Level scaling —
      kullanıcı kararı: eşik yükseltildi (düşürülmedi), `combat_rhythm_threshold` Lv1:6
      Lv2:5 Lv3:4.
- [x] Shield Bash (166) — dönüş hızı Armor×mult kadar artıyor. Level scaling:
      `shield_bash_mult` Lv1:1.25 Lv2:1.5 Lv3:2.0.
- [x] Siege Protocol (167) — Siege Core duvar sekmesinde bonus biriktiriyor, isabette
      harcanıp sıfırlanıyor (top hiç düşmana çarpmadan dönerse bonus bir sonraki uçuşa
      taşınıyor — bug değil, açıklamayla tutarlı). Level scaling: `siege_protocol_bonus`
      Lv1:1 Lv2:2 Lv3:3. requires:[45] zaten mevcuttu.
- [x] Bulwark Echo (168) — **MANTIK DÜZELTMESİ**: eski açıklama "Armor kazanımının yarısı
      tekrar" diyordu ama Bulwark Core'un kazanımı hep sabit (+2, hiç değişmiyor) olduğu
      için "yarısı" ifadesi anlamsızdı → doğrudan sabit miktar olarak yeniden yazıldı.
      Level scaling — kullanıcı kararı: Lv1/Lv2 aynı miktar (1), sadece gecikme kısalıyor;
      Lv3'te hem gecikme hem miktar artıyor: `bulwark_echo_delay` Lv1:4s Lv2:3s Lv3:2s,
      `bulwark_echo_amount` Lv1:1 Lv2:1 Lv3:2.
- [x] Momentum Transfer (169) — Armor sıfırlanırsa +N Momentum (`gain_momentum()`'a
      bağlandı). Level scaling: `momentum_transfer_amount` Lv1:3 Lv2:4 Lv3:5.
- [x] Kinetic Surge (171) — **KRİTİK BUG FIX (ölü kart)**: `spd = max(spd, 600.0)` no-op'tu
      çünkü oyundaki HER top zaten varsayılan 600 hızla fırlatılıyor (`ball_launcher.gd`
      `ball.launch(direction)` spd vermeden çağırıyor, default=600.0) — kart hiçbir zaman
      gerçek bir etki yaratmıyordu. Taban hız gerçek bonusa çevrildi: `kinetic_surge_speed`
      Lv1:700 Lv2:750 Lv3:750, `kinetic_surge_threshold` Lv1-2:15 Lv3:12 (kullanıcı kararı).
      Not: `launch_with_speed()` fonksiyonu hâlâ hiçbir yerde çağrılmıyor (dead code,
      dokunulmadı).
- [x] Armor Conduit (172) — **TASARIM DEĞİŞİKLİĞİ (kullanıcı kararı)**: eski flat +2 bonus
      hasar (ayrı `take_damage(2)` çağrısı) yerine tüm core hasarına çarpan uygulanacak
      şekilde yeniden yazıldı, hesaplama noktası da Phase Shift/System Overload'la aynı
      yere (crit + damage_mult SONRASI, final `total_damage` üzerinde) taşındı.
      `armor_conduit_mult` Lv1:1.25 Lv2:1.5 Lv3:2.0.

**Mimari not — merkezi `gain_momentum()` fonksiyonu (player.gd):** Pressure Valve'i
düzeltirken kuruldu, artık `momentum_stacks`'i artıran HER yer (Momentum Engine, Momentum
Field Core, Steel Rhythm, Armor Rush, Momentum Transfer, Risk Engine, momentum_zone.gd,
base_enemy.gd reaksiyon bonusu) bu fonksiyondan geçiyor. Yeni bir momentum-üretici kart
eklenirse, `momentum_stacks = min(...)` yazmak yerine MUTLAKA `gain_momentum(N)` çağrılmalı
— yoksa Pressure Valve o kaynağı sayamaz.

**Build hatası (2026-08-22):** `var _echo_amt := player_node.bulwark_echo_amount` tip
çıkarım hatası verdi (`player_node` generic Node/Variant döndüğü için `:=` tip
çıkaramıyor) — `var _echo_amt: int = ...` şeklinde açık tip belirtilerek düzeltildi.
Yeni kod yazarken loosely-typed node'lardan (`_get_player()`, `get_node_or_null` vb.)
property okurken `:=` yerine açık tip kullanmaya dikkat et.

**VECTOR UTILITY TAMAMLANDI (15/15 kart) — 2026-08-22**

### İlerleme — Vector Individuality (21 kart, index sırasına göre) — TAMAMLANDI (2026-08-26)
- [x] Blood for Steel (30) — çalışıyor: -10 Max HP, +10 Max Armor/Cap. Dil temiz, bug yok.
- [x] Pain Converter (31) — çalışıyor: HP<%50 → Armor Gain ×1.5 (genel `mult` üzerinden,
      tüm armor kaynaklarını etkiliyor). Dil temiz, bug yok.
- [x] Adrenal Surge (32) — HP<%30 → Momentum stack'lerin Core Speed'e dönüşüm oranı ×2.
      Tamamen `has_momentum_engine` bloğunun içinde, `requires: [35]` eklendi.
- [x] Scar Tissue (33) — **BUG FIX**: kod -10 HP uyguluyordu ama TR açıklama "-5 HP"
      diyordu (EN ile bile uyuşmuyordu) — TR "-10" olarak düzeltildi, Armor Cap/Regen
      miktarları (+5 / +1 sn) da iki dile de eklendi (önceden hiç belirtilmiyordu).
- [x] Emergency Protocol (34) — **KRİTİK BUG FIX**: -15 HP bedeli `player_damaged()`
      (genel düşman hasar fonksiyonu) üzerinden veriliyordu — Armor önce absorbe ettiği
      için gerçek HP kaybı garanti değildi, üstelik Armor tam sıfırlanırsa Momentum
      Transfer'in run başına 1 kez çalışan acil "revive" hakkını boşa harcayabiliyordu.
      Doğrudan `player_hp = max(1, player_hp - 15)` yapılacak şekilde düzeltildi. Ayrıca
      TR açıklamadaki yanlış sayı (%100 → doğrusu %75) düzeltildi, EN alanındaki Türkçe
      metin İngilizceye çevrildi.
- [x] Reinforced Frame (48) — çalışıyor: +20 Armor Cap / Core Speed -%10. Tutarlılık için
      `player_max_armor` senkron satırı eklendi (diğer benzer kartlarla aynı desen).
- [x] Iron Constitution (49) — çalışıyor: `armor_gain_mult` ×1.25 (kümülatif havuz).
      Dil temiz, bug yok.
- [x] Fortified Core System (50) — **BUG FIX (bugünkü Momentum redesign'in yan etkisi)**:
      cezası (`momentum_gain_mult *= 0.8`) artık hiçbir yerde okunmuyordu (eski vuruş
      bazlı üretimin RNG şansıydı, silindi). Yeni hareket-bazlı sisteme uyarlandı:
      `momentum_gen_interval *= 1.25` (matematiksel olarak yine tam -%20 üretim hızı).
      `requires: [35]` eklendi.
- [x] Blood Circuit (51) — çalışıyor: HP≤%70 iken Core Speed'e doğrusal +%0→%50 bonus.
      Dil temiz, bug yok.
- [x] Fractured Frame (52) — çalışıyor: Core Damage ×1.4 / Max HP -15. **BUG FIX**: HP
      düşürme satırında güvenlik payı (floor clamp) yoktu, `max(1, ...)` eklendi (diğer
      -HP kartlarıyla tutarlı hale getirildi).
- [x] Glass Engine (53) — çalışıyor: HP<%50 → Armor Gain ×1.5, HP>%70 → Armor Gain ×0.7.
      Açıklamaya kesin eşik sayıları (%50/%70) ve "Armor Gain" (sadece "Armor" değil)
      netliği eklendi — kullanıcı isteğiyle.
- [x] Overclocked Reflex (54) — çalışıyor: Core Speed ×1.2 / Armor Gain ×0.85. Dil temiz.
- [x] Hyper Recovery Loop (56) — **ÇİFT BUG FIX**: TR açıklaması tamamen eski/yanlıştı
      ("Core sıfır hasar verir" — kartın çok önceki bir versiyonundan kalma, patch
      notlarına göre bu mekanik `hyper_loop_max_bounce`'a çevrilmiş ama TR hiç
      güncellenmemiş). Üstelik `hyper_loop_max_bounce` değişkeninin kendisi de
      `ball.gd`'de hiçbir yerde okunmuyordu — tamamen ölü kod. Kullanıcı kararıyla kart
      sadeleştirildi: sadece "Core dönüş hızı ×1.5" kaldı, ölü değişken/atama silindi.
- [x] Battlefield Anchor (58) — çalışıyor: `slow_duration_mult` ×2 (sadece Anchor Core'u
      etkiliyor) / Player Speed -%10. `requires: [41]` eklendi (Anchor Core olmadan
      upside tamamen ölüydü). Açıklama "Yavaşlatma süresi" yerine netlik için "Düşman
      yavaşlama süresi" olarak güncellendi (kullanıcı isteğiyle, yanlış anlaşılabilirdi).
- [x] Risk Engine (60) — **BUG FIX**: "Armor Gain -%30" cezası hiç implemente edilmemişti
      (sadece "hasar→momentum" upside'ı vardı, kod tabanında ceza için hiçbir satır
      yoktu) — Iron Constitution/Overclocked Reflex'le aynı desende `armor_gain_mult
      *= 0.7` eklendi. `requires: [35]` eklendi.
- [x] Iron Blood (105) — çalışıyor: alım anındaki Max HP'nin her 10'u için +1 Armor Cap
      (tek seferlik). Ölü `var p` satırı temizlendi, açıklamaya "(tek seferlik/once)"
      netliği eklendi, TR dil eksikliği giderildi.
- [x] Steel Rhythm (109) — çalışıyor: Armor=Cap iken hit → +1 Momentum. **YENİ KOŞUL
      (kullanıcı isteği)**: artık momentum'u sadece **maks %50'ye kadar** doldurabiliyor
      (`momentum_stacks < momentum_max * 0.5` şartı eklendi) — geri kalan %50-100 aralığı
      sadece hareketle (Momentum Engine) doldurulabiliyor, "asıl kaynak hareket" felsefesi
      korunuyor. `requires: [35]` + TR dil eksikliği giderildi.
- [x] Severance Protocol (111) — çalışıyor: HP ilk kez %40 altına düşünce +10 Armor Cap
      (tek seferlik, bayrakla korunuyor). TR dil eksikliği giderildi.
- [x] Inertia Plating (112) — çalışıyor: alım anındaki Momentum stack'inin 5'e bölünüp
      yuvarlanmış hali kadar Armor Cap (tek seferlik). `requires: [35]` eklendi (Momentum
      Engine'siz momentum_stacks hep 0, kart tamamen ölü kalıyordu), TR dil eksikliği
      giderildi.
- [x] Overclock Threshold (113) — çalışıyor: 20 Momentum stack'ine ulaşınca kalıcı Core
      Damage ×1.3 (tek seferlik, bayrakla korunuyor). `requires: [35]` eklendi, TR dil
      eksikliği giderildi.
- [x] Momentum Transfer (169) — bugünkü Momentum redesign sırasında Utility'den bu
      kategoriye taşınmış ve tamamen elden geçirilmişti (bkz. yukarıdaki Momentum bölümü),
      Individuality review'inde ayrıca ele alınmadı.

**VECTOR INDIVIDUALITY TAMAMLANDI (21/21 kart) — 2026-08-26**

### İlerleme — Vector Calamity (8 kart, index sırasına göre)
Bu tur ayrıca **VFX ayarlamaları** için de önemli (kullanıcı özellikle belirtti) — her
kartın implementasyon/requires/dil incelemesinin yanında görsel efekti de gözden
geçirilecek.
- [x] Gravitational Force (9) — çalışıyor: tıklanan noktaya 5s boyunca 150px yarıçaptaki
      düşmanları çekiyor (`_activate_gravity()`), VFX zaten mevcut (mor spiral parçacık +
      vorteks halkası, `_vfx_gravity()`). **BUG FIX**: `_CALAMITY_DISPLAY_NAMES`
      sözlüğünde "🌀" ikonu yanlışlıkla "Calamity Cyclone" diye etiketlenmişti (Calamity
      slot tooltip'inde yanlış isim gösteriyordu) → "Gravitational Force" olarak
      düzeltildi. **Ölü kod temizliği**: "🔮" ikonu (`_activate_arise()` — topu oyuncuya
      fırlatan alakasız bir mekanik, muhtemelen çok eski bir kalıntı) hem kart havuzunda
      hiç yoktu (index 10 tanımsızdı) hem de mağazadan alınan "başlangıç Calamity"
      rastgele havuzunda hâlâ duruyordu (hayalet calamity riski) — tüm referansları
      (display name, tetikleme bloğu, Calamity Circle rengi, fonksiyonun kendisi, ölü
      pickup handler, mağaza havuzu) komple silindi.
      VFX prompt'u kullanıcıya verildi (Pixellab için, mor/violet spiral vorteks temalı,
      mevcut parçacık rengiyle `Color(0.65, 0.1, 1.0)` eşleşecek şekilde).
      **VFX tamamlandı (2026-08-26, evde test edildi)**: kullanıcı `assets/VFX/calamitys/
      gravitationalForce/` klasörüne 8 frame'lik gerçek sprite animasyonu ekledi, elle
      çizilmiş vorteks halkası (`draw_arc`) bununla değiştirildi (`AnimatedSprite2D`,
      10 fps, spin loop). **BUG FIX**: VFX z_index'i (4-5) düşmanların z_index'inin (temel
      düşmanlar 2, boss'lar 3) üstündeydi, düşmanlar sprite'ın arkasında kalıyordu — hem
      parçacıklar hem vorteks z_index=1'e çekildi (tüm düşman tiplerinin altında). Ayrıca
      kullanıcı isteğiyle: %65 saydamlık (`modulate` alpha) + süre başında ortadan büyüyüp
      (1s, scale 0→2.0, TRANS_BACK) süre bitmeden 1s önce tekrar sıfıra küçülen scale
      animasyonu eklendi.
- [x] **Iron Fortress (173) — KALDIRILDI (kullanıcı kararı, 2026-08-26)**: açıklama "Tüm
      Momentum → Armor (stack başına +1, 8s)" diyordu ama kod tamamen anlık çalışıyordu
      (`momentum_stacks` sıfırlanıp aynı miktar Armor'a ekleniyordu), "8s" hiçbir yerde
      karşılığı olmayan anlamsız bir ifadeydi. Kullanıcı düzeltmek yerine kartı komple
      kaldırmayı tercih etti — tüm referansları (kart havuzu, display name, tetikleme
      bloğu, `_activate_iron_fortress()` fonksiyonu, upgrade handler, debug test yorumu)
      silindi.
- [x] Shockwave (174) — çalışıyor: mevcut Armor/2 kadar (en az 1) AoE hasar, **Yard'daki
      tüm düşmanlara** (x≥385 sınırı zaten doğruydu). Açıklama netleştirildi ("tüm
      düşmanlar" → "Avlu'daki tüm düşmanlara", TR/EN'de "Yard" kelimesiyle). Dil bug'ı
      düzeltildi (EN alanı Türkçe yazılmıştı). **VFX eklendi**: `_vfx_shockwave()` —
      oyuncu üzerinde merkezlenen tek seferlik patlama sprite'ı (9 frame,
      `assets/VFX/calamitys/shockwave/`), ölçek 0.6→7.0 büyüyor (kullanıcı 10'dan 7'ye
      düşürdü), **Yard dışına taşmasın diye `Polygon2D` + `clip_children` ile kırpma
      alanı eklendi** (x:385-1920, y:255-1080 — cadde/tribün sınırı `SegmentShape2D`
      referans alındı). `_react_flash_screen()` de aynı Yard sınırına çekildi (paylaşımlı
      fonksiyon, diğer tüm Calamity flaşlarını da düzeltti).
- [x] Full Breach (175) — **KRİTİK BUG FIX**: "Armor sıfırlanır, 8s: Core Damage ×2.5"
      diyordu ama sadece Armor sıfırlanıyordu, `×2.5` hiç uygulanmıyordu (`full_breach_
      active`/`full_breach_timer` meta'ları set edilip hiç okunmuyordu — Iron Fortress'le
      aynı hata deseni). Gerçek mekanik kuruldu: `player.gd`'ye `full_breach_mult`/
      `_full_breach_timer` eklendi, `ball.gd`'nin hasar pipeline'ına bağlandı. **Ekstra
      "güç hissi" eklendi**: aktivasyonda `screen_shake_heavy()`, 8s boyunca Yard'a sınırlı
      kırmızı vignette (`_vfx_full_breach_vignette()`), aktifken her isabette büyük kırmızı
      impact patlaması. `requires` gerekmiyor (Armor zaten Vector'ın temel sistemi). Dil
      bug'ı düzeltildi.
- [x] Momentum Burst (176) — **AYNI KRİTİK BUG FIX deseni**: "Tüm Momentum harca: +2 Core
      Speed/stack (10s)" vaadi tamamen ölüydü (`momentum_burst_bonus`/`momentum_burst_
      timer` meta'ları hiç okunmuyordu). Gerçek mekanik kuruldu: stack başına **+%5** Core
      Speed (kullanıcı kararı — +2 sabit/  %2 az bulundu, %5 kabul edildi), `player.gd`'ye
      `momentum_burst_bonus`/`_momentum_burst_timer` eklendi, orbit speed formülüne
      `has_momentum_engine` şartından bağımsız bağlandı (stack sıfırlansa da çalışır).
      `requires: [35]` eklendi, dil bug'ı düzeltildi.
      **Görsel hız geri bildirimi kuruldu (kullanıcı isteği, momentum sisteminin geneli
      için de geçerli)**: `ball.gd`'de zaten var olan ama kullanılmayan/bozuk iki trail
      sistemi bulundu ve düzeltildi:
      1. `_update_momentum_trail()` (CPUParticles2D, momentum stack sayısına göre
         yoğunluk/renk/hız ölçekleniyordu) — **BUG FIX**: `top_level=true` eksikti,
         parçacıklar topla birlikte hareket ediyordu (iz bırakmıyordu); ayrıca Momentum
         Burst sırasında stack sıfırlandığı için tamamen kayboluyordu — Burst aktifken
         `t=1.0` zorlanacak şekilde düzeltildi.
      2. `_setup_trail()` (Line2D, genişlik eğrisi + HDR glow renk gradyanı, core tipine
         göre renkleniyor) — **tamamen kapalıydı** (`return # devre dışı — test için`
         satırı), açıldı. **Kullanıcı isteğiyle**: uzunluk artık topun o anki `speed`
         değerine göre dinamik — `(speed - 600.0) / 5.0` formülü, 0-40 arası clamp
         (varsayılan 600 hızda hiç görünmüyor, hızlandıkça uzuyor).
      **DEBUG test kolaylığı eklendi**: `_ready()`'de run başlar başlamaz
      `has_momentum_engine=true` + `momentum_stacks=10` set ediliyor (test bitince
      kaldırılmalı).
- [x] Rampart Collapse (177) — implementasyon doğru (en yakın hedefe Armor Cap kadar hasar,
      Armor sıfırlanır), requires gerekmiyor (Armor Cap her zaman mevcut). **Dil bug'ı**
      (aynı tekrarlayan desen): EN `desc` alanı Türkçe yazılmıştı → düzeltildi, `lang.gd`'de
      hiç TR girdisi yoktu → eklendi.
      **VFX komple yeniden inşa edildi (kullanıcı isteğiyle, 2 aşamalı gerçek sprite akışı)**:
      önceki tek seferlik ekran flaşı + jenerik parçacık yerine, kullanıcının tarif ettiği
      "tekli hedefe nişan" hissi kuruldu:
      1. **Aşama 1 — Şarj**: `_vfx_rampart_charge()`, player üzerinde oynayan bir
         `AnimatedSprite2D` (`assets/VFX/calamitys/rampartCollapse/charge/frame_000..007.png`,
         henüz kullanıcı tarafından eklenmedi) — hexagon Armor parçaları bir noktada
         yoğunlaşıyor.
      2. **Core fırlatma**: şarj animasyonunun **son frame'i** projectile sprite'ı olarak
         yeniden kullanılıyor (`_spawn_rampart_projectile()`), hedefe 0.22s'lik bir tween ile
         fırlıyor (`_fire_rampart_core()`).
      3. **Aşama 2 — Patlama**: hedefe ulaşınca tek seferlik hasar uygulanıyor, ardından
         `_vfx_rampart_impact()` oynuyor (`assets/VFX/calamitys/rampartCollapse/impact/
         frame_000..007.png`, henüz eklenmedi) + screen shake + parçacık patlaması +
         Yard-sınırlı ekran flaşı.
      Sprite dosyaları henüz yoksa kod crash etmiyor (`ResourceLoader.exists` guard'ı),
      sadece kısa bir gecikme + parçacık efektiyle çalışıyor.
      **Renk düzeltmesi**: ilk taslakta turuncu/kahverengi (rust-orange) renk paleti
      kullanılmıştı, kullanıcı Vector'ın gerçek Armor görselinin (`assets/VFX/hexShieldWest/
      hexShieldEast`) parlak **camgöbeği/cyan** tonunda olduğunu hatırlattı — tüm renkler
      (parçacık patlaması, ekran flaşı, projectile placeholder, kart menü rengi) `Color(0.2,
      0.85, 1.0)` cyan tonuna çekildi, iki VFX prompt'u da cyan temaya göre yeniden yazıldı.
      **YAPILACAK**: kullanıcı Pixellab'de 2 ayrı 8-frame animasyon üretip
      `assets/VFX/calamitys/rampartCollapse/charge/` ve `.../impact/` klasörlerine
      ekleyecek (henüz eklenmedi).

      **Ev session'ından gelenler (`8584e4e`)**: `charge/` klasörüne 13 frame'lik gerçek
      sprite eklendi (kod zaten dinamik `while ResourceLoader.exists(...)` ile yüklüyordu,
      8 sabit sayı varsayımı yoktu — ekstra frame sorunsuz çalıştı). `impact/` klasörü
      hâlâ boş.

      **Sonraki turda 3 ek değişiklik (kullanıcı isteğiyle, aynı gün)**:
      1. Mavi ekran flaşı (`_react_flash_screen`) kaldırıldı — sadece screen shake +
         parçacık patlaması + sprite impact VFX kaldı.
      2. Hasar **AoE'ye çevrildi**: artık sadece en yakın hedefe değil, çarpma noktasının
         130px yarıçapındaki (Yard sınırı korunarak) tüm düşmanlara Armor Cap kadar hasar.
      3. **Hedefleme tamamen manuel oldu**: `_activate_rampart_collapse()` artık en yakın
         düşmanı otomatik bulmuyor, `target_pos: Vector2` (mouse pozisyonu) parametresi
         alıyor — core artık oyuncunun tıkladığı/nişan aldığı noktaya uçup orada patlıyor.
         Kart `_CALAMITY_TARGETED` listesine eklendi, nişan-önizleme çemberine (cyan,
         130px) dahil edildi. Açıklamalar "otomatik hedefleme" → "nişan al ve ateşle"
         olarak güncellendi.

## Calamity Kullanım Sistemi — Tıklamalı Seçime Geçiş (2026-08-31)

Kullanıcı eski C-tuşu-ile-cycle + E-tuşu-ile-ateşle akışından rahatsız oldu ("cycle etme
zorunluluğu rahatsız ediyor, direkt tıklamalı seçim olsun" — Slay the Spire potion
kullanımı referans alındı). Meğerse zaten **hazır bir altyapı** vardı: `_calamity_cells`
(sağ panelde, `LabelCalamity`'nin üzerine bindirilmiş, sadece hover-tooltip için var olan
3 adet görünmez `Panel`) — bunlar gerçek tıklanabilir/görünür hücrelere çevrildi.

### Yapılan değişiklikler
- **`_setup_calamity_cells()`**: 3 → **5 hücre** (shop'tan max +2 slot alınabiliyordu,
  eskiden fazla slotlar için hücre yoktu — gizli bug da düzeltildi). Artık görünür
  `StyleBoxFlat` (kenarlık/arkaplan) + içinde emoji gösteren bir `Label` var, `mouse_filter
  = STOP` + `gui_input` bağlı.
- **`update_ui()`**: `LabelCalamity` artık sadece başlık ("— FELAKET —") gösteriyor, slot
  metni tamamen `_update_calamity_cells()`'e taşındı (her hücrenin emoji/boş/dim/highlight
  durumunu senkronluyor).
- **`_CALAMITY_TARGETED`** const listesi eklendi (Lightning, Flame, Gravitational Force,
  Volcanic Rift, Siege Rain, Glitch Bomb, Decay Field, Rampart Collapse — mouse pozisyonu
  gerektirenler). `_calamity_needs_target()` bu listeye bakıyor.
- **Tıklama akışı (`_on_calamity_cell_clicked`)**: hedef gerektirmeyen Calamity'ye tıklayınca
  **anında ateşleniyor**. Hedef gerektirene tıklayınca **nişan modu** açılıyor (hücre sarı
  highlight alıyor, mevcut yarıçap-önizleme çemberi — değişmedi — mouse'u takip ediyor).
- **Ateşleme onayı iki yoldan da çalışıyor**: (1) hücreye basılı tutup sahaya sürükleyip
  **bırakınca** (drag-to-target, `_input()`'ta global `MOUSE_BUTTON_LEFT` release dinleniyor),
  (2) nişan halindeyken **E tuşuna** basınca. **Önemli guard**: nişanı açan tıklamanın kendi
  bırakışı (hâlâ hücrenin üzerindeyken) yanlışlıkla ateşlemesin diye, release pozisyonu
  armed hücrenin `Rect2`'si içindeyse sayılmıyor — sadece hücre dışında (sahada) bırakılan
  mouse gerçek ateşleme sayılıyor. Bu iki aşamalı test sırasında bulunan bug'dı ("basılı
  tutuyorum, bırakınca ateşleme olmuyor" — E dışında hiçbir onay yolu yoktu, eklendi).
- **Escape** artık önce nişanı iptal ediyor (varsa), yoksa pause menüsünü açıyor (eskisi gibi).
- **C tuşu (cycle) tamamen kaldırıldı.**
- Büyük calamity dispatch elif-zinciri `_dispatch_calamity_effect()` fonksiyonuna
  çıkarıldı, hem tıklama hem E/drag-release onayı `_consume_calamity()` ortak fonksiyonunu
  paylaşıyor (Void Resonance skip / slot tüketme / Mana Overflow bonusu — hepsi tek yerde).
- `max_calamity_slots` hesaplama satırı `_ready()`'de daha yukarı taşındı (hücre sayısı
  ilk `update_ui()` çağrısında doğru görünsün diye).

**Test edildi, kullanıcı onayladı** (drag-to-target akışı evde test edilip düzeltildi).

- [x] WormHole (198) — implementasyon doğru: player'ın 120px önünde (sabit yön, mouse'a
      bağlı değil) 5s'lik delik açılıyor, 70px yarıçapındaki Boss-hariç düşmanlar
      `subject_died()` + `queue_free()` ile ışınlanıp yarım skor veriyor. Requires
      gerekmiyor (bağımsız kart). Dil zaten ev session'ında (`8584e4e`) düzeltilmişti.
      **Ölü kod temizliği**: nişan-önizleme çemberinde (`_process`) WormHole için hâlâ
      duran `elif calamity == "🌀🕳️":` dalı silindi — WormHole hedeflemeli olmadığı
      (`_CALAMITY_TARGETED` listesinde yok) için bu dal artık hiç tetiklenmiyordu.
      **VFX gerçek sprite'a çevrildi** (Gravitational Force ile aynı desen):
      `_vfx_wormhole_open()` — eski elle çizilen mor `ColorRect` yerine
      `assets/VFX/calamitys/wormhole/frame_000..008.png`'den (9 frame, kullanıcı ekledi)
      10fps spin-loop `AnimatedSprite2D`, süre başında büyüyüp (0→1.6 scale) bitmeden
      küçülüyor. Sprite yoksa eski `ColorRect` fallback'ine düşüyor (crash yok).
      **Kullanıcı testi sonrası 3 ek düzeltme (aynı gün)**:
      1. **z_index bug fix**: vortex/fallback z_index 5 → 1, düşmanların (z_index 2-3)
         üzerinde görünüyordu, artık altlarında kalıyor.
      2. **Emme animasyonu eklendi**: yakalanan düşmanlar artık anında `queue_free()`
         olmuyor, ~0.4s boyunca dönerek (`rotation += 14·dt`) + küçülerek (`scale→0`)
         merkeze doğru çekiliyor (vorteksin kendi dönüş hareketiyle tutarlı). Süre
         bitiminde hâlâ çekilmekte olan biri kalırsa donuk kalmasın diye sonda bir
         temizleme eklendi.
      3. **Tıklama davranışı düzeltildi + hedef bug'ı çözüldü**: WormHole artık
         `_CALAMITY_TARGETED` listesinde — tıklar tıklamaz ateşlenmiyor, tıkla+
         sürükle+bırak veya tıkla+E gerekiyor (kullanıcı: "mouse tıklar tıklamaz
         çalışıyor, iyi değil"). **Asıl bug**: açılma konumu sabit `Vector2(120,0)`
         (her zaman sağa) idi, kullanıcı "karakterin tam önünde, sağında/solunda
         değil" istedi — `player.aim_direction` (karakterin gerçek anlık bakış/nişan
         yönü) kullanılacak şekilde düzeltildi. Nişan-önizleme çemberi de gerçek
         açılış konumunu gösteriyor (mouse pozisyonunu değil).

**WORMHOLE TAMAMLANDI (198) — 2026-08-31**

- [x] Siege Rain (199) — **GERÇEK BUG (görsel)**: 7s boyunca her 0.5s'de düşen Siege Core'un
      isabet öncesi "gölge uyarısı" (`shadow_node`) script'siz bir `Node2D` idi ve
      `queue_redraw()` çağırıyordu — ama hiçbir `_draw()` override'ı olmadığı için **hiçbir
      şey çizilmiyordu**, oyuncu 14 darbeden hiçbirinin nereye düşeceğini göremiyordu.
      Gerçek bir `Polygon2D` halkasına çevrildi: küçük başlayıp 0.6s'de tam isabet
      yarıçapına büyüyor (`scale` tween), aynı anda alpha artıyor — artık isabet alanı
      net görünüyor. Requires gerekmiyor (Siege Core sprite'ı sadece kozmetik ödünç
      alınmış, mekanik bağımlılık yok). Dil bug'ı (aynı tekrarlayan desen): EN `desc`
      Türkçe yazılmıştı → düzeltildi, `lang.gd`'de TR girdisi hiç yoktu → eklendi.

**VECTOR CALAMITY TAMAMLANDI (7/7 kart, Iron Fortress kaldırıldı) — 2026-08-31**

## Vector Calamity — Review Sonrası Cila Turu (2026-08-31, aynı gün devamı)

Kartlar tamamlandıktan sonra kullanıcı açıklamaları tekrar gözden geçirdi ve birkaç
karta ek VFX/dengeleme turu yaptı.

### Açıklama güncellemeleri (kullanıcı diktesiyle)
- **Gravitational Force**: "Düşmanları 5 sn boyunca merkeze doğru çeker." (TR),
  "Pulls enemies toward the center for 5s" (EN) — eski metin belirsizdi.
- **Rampart Collapse**: "nişan al ve ateşle" ifadesi kaldırıldı (tüm Calamity'ler zaten
  tıklamalı sistemde), sade: "Hedeflenen noktaya Armor Cap kadar alan hasarı verir,
  Armor sıfırlanır" (TR) / "Deals AoE damage equal to Armor Cap at the targeted point.
  Armor resets" (EN).
- **WormHole**: "Vector'un çevresinde solucan deliği açılır\nYaklaşan düşmanlar
  sonsuzluğa karışır. (Boss hariç)" (TR) / "Opens a wormhole around Vector\nApproaching
  enemies vanish into the void (Boss immune)" (EN) — süre ifadesi (5s) kaldırıldı, dil
  sadeleştirildi. **Not**: "çevresinde" ifadesi kullanıcının tercihi, gerçek
  implementasyon hâlâ tam önünde (aim_direction) sabit bir noktada açılıyor, çevresini
  sarmıyor — anlamca sorun yaratmıyor ama tam teknik doğruluk için bilgi amaçlı not.

### WormHole ikon bug fix
`"🌀🕳️"` (cyclone + hole, iki ayrı emoji birleşimi) Calamity slotunda **iki ayrı ikon**
gibi görünüyordu (bir hücrede iki glyph). Kullanıcı sağdakini (`🕳️`, hole) seçti, tüm
referanslar (`_CALAMITY_DISPLAY_NAMES`, `_CALAMITY_TARGETED`, dispatch, debug default,
mağaza pool) tek emoji'ye çevrildi.

### Siege Rain — VFX + tasarım komple yeniden yapıldı
Kullanıcı kendi ürettiği 6 frame'lik `assets/VFX/calamitys/siegeRain/` sprite'ının
aslında **tam bir "düşüş + çarpma" animasyonu** olduğunu fark etti (küçük başlayıp
büyüyerek inen meteor + patlama) — eskiden ayrı bir "düşen Siege Core topu" sprite'ı
(oyundaki gerçek Siege Core kartından ödünç alınmış, alakasız) + tween ile taklit
ediliyordu, bu tamamen kaldırıldı, tek animasyon yeterli.
- **Uyarı halkası tamamen kaldırıldı** (önceki turda eklenen Polygon2D telegraph),
  turuncu zemin çatlağı (ColorRect) da kaldırıldı — hepsi yeni sprite'ın kendisiyle
  gereksiz hale geldi.
- **Darbe aralığı**: 0.5s → **1s** (toplam süre 7s → 14s, 14 darbe aynı kaldı).
- **Düşüş yüksekliği/süresi** birkaç iterasyonda ayarlandı: 300px/0.35s → 550px/0.7s
  (ilk deneme, sonra sprite'ın kendisi düşüşü içerdiği için bu ayrı tween'in kendisi
  komple silindi).
- **KRİTİK BUG FIX (pause)**: `get_tree().create_timer()`'ın varsayılanı
  `process_always=true` — yani `upgrading` sırasında (`get_tree().paused=true`) bu
  sayaçlar durmadan işlemeye devam ediyordu, menüden çıkınca birikmiş birkaç darbe aynı
  anda tetikleniyordu ("3 core aynı anda düştü" — kullanıcı bulgusu). Tüm ilgili
  `create_timer()` çağrılarına `process_always=false` eklendi.
- **Hedefleme pasiflik sorunu düzeltildi**: kullanıcı "aşırı pasif bir karta dönüşüyor"
  dedi çünkü darbeler tamamen rastgele (±40px, sonra ±120px) boş noktalara düşüyordu,
  düşmana isabet garantisi yoktu. Artık her darbe önce seçilen alandaki (170px yarıçap,
  önizleme çemberiyle aynı) gerçek, **canlı** (`is_dead` filtresi eklendi — ölü
  düşmanlar/cesetler hedef sayılmıyor) düşmanlar arasından rastgele birini seçip onun
  konumuna (±20px küçük sapmayla) düşüyor; alanda düşman yoksa eski rastgele nokta
  davranışına düşüyor.
- **Nişan önizleme çemberi büyütüldü**: 80px → 170px (yeni ±120px sapma alanının
  köşegen mesafesine göre gerçekçi boyut).
- **Kalıcı iz efekti eklendi**: animasyon bitince (son karede durunca) 3sn (5sn'den
  düşürüldü) öylece kalıp 1sn'de fade-out ile kayboluyor.
- **z_index — iki aşamalı, dinamik**: **düşerken** (`z_index=4`) düşmanların (2-3)
  ÖNÜNDE görünüyor (gökten düşme hissi), animasyon bitip son karede (kraterin izi)
  durunca `animation_finished` içinde `z_index=-1`'e geçiyor — hem canlı hem ölü/ceset
  (`z_index=0`) düşmanların ARKASINDA kalıyor (kullanıcı iki ayrı bug'ı da buldu, ikisi
  de düzeltildi).

### Full Breach — gerçek sprite VFX eklendi
Kullanıcı `assets/VFX/calamitys/fullBreach/` klasörüne 9 frame'lik bir animasyon ekledi
(cyan hexagon Armor parçalarının kırılıp merkeze doğru parlak bir enerji patlamasına
dönüşmesi — "Armor sıfırlanır → hasar bonusuna dönüşür" temasıyla birebir örtüşüyor).
`_vfx_full_breach_burst(pos)` eklendi, `_activate_full_breach()`'ten player pozisyonunda
çağrılıyor (12fps, tek seferlik), mevcut kırmızı vinyet + screen shake + parçacık
patlamalarının ÜZERİNE ekleniyor (onlar kaldırılmadı).

**Kalan VFX eksiği**: Rampart Collapse'ın "impact" (patlama) klasörü hâlâ boş (sadece
"charge" var), Momentum Burst'ün hiç özel VFX'i yok (sadece genel trail hissi).

### Full Breach — kırmızı vinyet kaldırıldı, yerine core aurası eklendi (aynı gün)
Kullanıcı 8s süren tam ekran kırmızı vinyeti rahatsız edici buldu ("şu kırmızılığı
kaldırsak, core'lara görsel efekt eklesek, çevrelerini kızartmak gibi"). Yapılan:
- `_vfx_full_breach_vignette()` fonksiyonu ve çağrısı tamamen silindi (aktivasyon anındaki
  kısa `_react_flash_screen` + `screen_shake_heavy` kaldı, diğer Calamity'lerle tutarlı).
- `ball.gd`'ye `_full_breach_aura` (CPUParticles2D, halka şeklinde emission, kırmızı-turuncu
  ember parçacıkları) eklendi — momentum trail ile aynı lazy-init deseni, `full_breach_mult
  > 1.0` iken her topun (fırlatılan/dönen) etrafında sürekli parçacık saçıyor, buff bitince
  otomatik sönüyor.
- **BUG FIX (crash)**: ilk denemede `emission_ring_axis` (CPUParticles**3D**'ye özgü bir
  property) yanlışlıkla `CPUParticles2D`'ye set edilmeye çalışıldı, oyun anında crash
  ediyordu — satır silindi, 2D ring emission zaten eksen istemiyor.

### Yeni genel özellik: Düşük Can Uyarı Vinyeti (tüm karakterler)
Full Breach sohbeti sırasında kullanıcı, "her oyunda olan, can azalınca ekran kenarında
kırmızılık" tarzı klasik bir düşük-HP uyarısı istedi — Vector'a özgü değil, genel bir HUD
özelliği. `_setup_low_hp_vignette()` (`_ready()`'de bir kez kurulur) + `_update_low_hp_
vignette()` (`_process()`'te her frame) eklendi:
- `GradientTexture2D` (radial, merkez şeffaf → kenar opak kırmızı, shader'sız) tam ekran
  `TextureRect`, `$UI` altında.
- Eşik: HP ≤ %30 iken görünür oluyor. Şiddet (`_severity`) 0 (eşikte) → 1 (0 HP'de) arası
  ölçekleniyor: hem taban alpha (0.12→0.55) hem nabız hızı (2→5 Hz) hem nabız genliği
  (0.05→0.18) buna göre artıyor — can azaldıkça daha yoğun ve daha hızlı "kalp atışı" hissi.
  Sinüs dalgasıyla (`Time.get_ticks_msec()`) pulse ediliyor.
- `upgrading` (menü açıkken) otomatik gizleniyor.

Sıradaki adım: aynı 4 aşamalı review süreci **Leila** için baştan başlayacak (Cyclone
Identity/Utility/Individuality zaten önceki session'da tam review edilmişti, tekrar
gerekmiyor — Leila'nın tamamı + Cyclone Calamity hâlâ eksik, bkz. dosyanın en altındaki
"Sonrası" notu).

## Core Speed Mimarisi — KRİTİK BUG FIX + Fırlatılan Topa Bağlama (2026-08-29)

Kullanıcı Momentum Burst'ün trail ile hissedilmediğini fark etti, araştırma sırasında
**dev bir sistemik bug** ortaya çıktı: `player.gd::_physics_process`'teki `_effective_orbit_speed`
değişkeni — Momentum Engine, Last Stand, Momentum Burst, Blood Circuit, Adrenal Armor
System, Bulwark Surge, Mana Overflow, Bounce Barrage, Elemental Harmony'nin TÜMÜNÜN
"Core Speed" bonusunu topladığı yer — **hiçbir yerde okunmuyordu**. Orbit toplar zaten
dönmüyor (sadece silah pozisyonunda duruyor, "orbiting" state'i sadece Connected Core
dart-strike mantığı için var), yani bu 9 kartın "Core Speed" vaadi **tamamen ölüydü**,
run boyu hiçbir gerçek etkileri yoktu.

**Fix**: `_effective_orbit_speed` kaldırıldı, yerine gerçekten okunan `core_speed_mult`
(player.gd) kondu — aynı hesap zinciri (tüm 9 kart) artık bu tek çarpanda toplanıyor.
`ball.gd`'ye `_get_core_speed_mult()` helper'ı eklendi, **fırlatılan (flying) ve dönen
(returning) topun gerçek `speed`'ine** çarpan olarak uygulanıyor (`move_and_collide`
çağrılarında) — Momentum stack'i/Burst/Bulwark Surge vb. arttıkça top artık gerçekten
daha hızlı gidiyor.

**Trail entegrasyonu**: `_update_trail()`'deki dinamik uzunluk formülü de `speed *
_get_core_speed_mult()` (efektif hız) üzerinden hesaplanıyor — böylece Momentum/Core
Speed kaynaklı hızlanma artık trail ile görsel olarak hissediliyor. Kullanıcı geri
bildirimiyle uzunluk 2 kademede kısaltıldı (aşırı hızda göz yormasın diye): son formül
`clamp(int((effective_speed - 680.0) / 5.0 * 0.5), 0, 20)` (orijinal `(speed-680)/5`,
0-40'a göre toplam yarıya indirildi).

Önceki oturumda (ev, `64f7a44`) ayrıca `ball.gd`'de dönüş rampasının doğal hızlanmasının
(600→680) trail'i yanlışlıkla tetiklediği bug'ı düzeltilmişti (referans 600→680'e
çekilmişti) — bu session'daki değişiklikler o düzeltmenin üzerine inşa edildi.

**Not**: Bu mimari değişiklik Vector Calamity review sürecinin bir parçası değil, ayrı
bir kritik sistemik bug fix'i — ama Momentum Burst'ün (176) VFX/hissiyat kontrolü
sırasında ortaya çıktığı için o kartın altında değil, ayrı bölümde tutuluyor.

**DEBUG NOTU:** `game_scene.gd::_ready()`'de `_debug_test_calamity` değişkeni run başında
otomatik bir Calamity veriyor (şu an "🔓" Full Breach — test turuna göre sık sık
değişiyor, en son değeri kod içinde kontrol et) — test bittiğinde bu satır ve momentum
debug override'ı (`has_momentum_engine`/`momentum_stacks=10`) kaldırılmalı veya
boşaltılmalı, kalıcı build'e sızmamalı.

Not: Vector'a ait görünüp aslında Leila'ya ait olan iki Calamity kartı var (Lightning
index 7, Flame Zone index 8) — bunlar Vector Calamity listesine dahil değil, karıştırma.

### UI eklentisi: Connected Core tooltip (2026-08-22)
- Connected Core rozetinin ("◈ Bağlantılı Core") üzerine gelince artık native Godot
  tooltip'i açılıyor: "Bu core fırlatılamaz — sürekli oyuncunun etrafında döner." (EN
  karşılığı da eklendi, `lang.gd` → `ui_connected_core_tooltip`).
- ÖNEMLİ implementasyon notu: tooltip badge Label'ına değil, kartın tamamını kaplayan ve
  badge'in üstünde duran `click_area` (Button) node'una eklendi — çünkü `click_area` daha
  sonra oluşturulup üstte kaldığı için mouse hover'ı önce o yakalıyor, badge'e asla
  ulaşmıyordu. Yeni bir hover/tooltip eklenecekse bu sıralamaya dikkat edilmeli.

Sonrası: Vector Individuality → Vector Calamity → aynı süreç Leila için de tekrarlanacak
(Cyclone Identity/Utility/Individuality zaten önceki session'da tam review edilmişti,
tekrar gerekmiyor — sadece Vector Individuality/Calamity ve tüm Leila eksik).

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
