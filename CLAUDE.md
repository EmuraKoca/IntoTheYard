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

## Ev Session Sonrası: Fragman Hazırlığı + VFX Takip Bug Fix'leri (2026-08-31/09-01)

Ev session'ında (`c49e8bf`) fragman/tanıtım kaydı hazırlığı yapıldı: Elemental Shield
Core'da asset yolu crash'i düzeltildi (kod düz dosya yapısı bekliyordu, asset'ler alt
klasörlere bölünmüştü), `neon_sign.gd`'deki "For Human ITY" alt yazısı kaldırıldı, XP
eşiği üretim değerine (150) sabitlendi, ve **tüm test/debug override'ları temizlendi**
(boss gauntlet, hızlı build, `_debug_test_calamity` dahil).

### KRİTİK BUG FIX: Full Breach + Rampart Collapse VFX'i Vector'ı takip etmiyordu
Kullanıcı fark etti: Vector hareketliyken bu iki Calamity kullanılınca animasyon
**kullanıldığı yerde sabit kalıyor**, oyuncuyu takip etmiyordu. Kök sebep: her iki VFX de
(`_vfx_full_breach_burst`, `_vfx_rampart_charge`) `add_child()` ile `game_scene`'e (dünya
sabit) ekleniyordu, pozisyon sadece aktivasyon anında **bir kere** (`global_position = pos`
snapshot) set ediliyordu — bir daha hiç güncellenmiyordu.
- **Fix**: her iki fonksiyon da artık `player: Node2D` parametresi alıyor, VFX doğrudan
  **Player'a child olarak bağlanıyor** (`player.add_child(...)`, `position = Vector2.ZERO`),
  Player'ın transform'unu otomatik miras alıp hareketini takip ediyor. Player root'unun
  scale/rotation hiç manipüle edilmediği doğrulandı (facing flip child sprite'ta yapılıyor),
  bu yüzden VFX'in bozulma riski yok.
- **Ek bug (Rampart Collapse)**: `_fire_rampart_core()` şarj animasyonu bitince Core'u eski
  (şarj başlangıcındaki) `start_pos` snapshot'ından fırlatıyordu — Vector şarj sırasında
  (0.6-0.7s) hareket ederse core yanlış yerden çıkıyordu. Artık şarj bitince oyuncunun
  **o anki güncel** `global_position`'ından fırlıyor.

**DEBUG NOTU (yeniden eklendi):** Ev session'ı tüm debug override'ları temizlemişti, bu
turun testi için `_ready()`'ye geçici bir blok eklendi — run başında `calamity_slots`'a
hem "🏚️" (Rampart Collapse) hem "🔓" (Full Breach) otomatik ekleniyor. **Test bitince bu
blok kaldırılmalı**, kalıcı build'e sızmamalı.

Sıradaki adım: aynı 4 aşamalı review süreci **Leila** için baştan başladı (Cyclone
Identity/Utility/Individuality zaten önceki session'da tam review edilmişti, tekrar
gerekmiyor — Leila'nın tamamı + Cyclone Calamity hâlâ eksik, bkz. dosyanın en altındaki
"Sonrası" notu).

## AKTİF SÜREÇ: Leila Kart-kart Full Review (2026-09-01 başladı)

Vector'da kurulan aynı 4 aşamalı süreç (implementasyon → requires → TR → EN) Leila için
de başladı, index sırasına göre.

### Yeni sistem: Kart üzerinde hover ile "keyword sözlüğü" popup'ı (Gwent tarzı)
Kullanıcı, dynamic açıklamalarda geçen durum efekti keyword'lerinin (Electrified, Wet,
Burning, Slowed, Frozen) üzerine gelince Gwent'teki gibi bir açıklama paneli açılmasını
istedi. Kuruldu:
- `lang.gd`: `STATUS_KEYWORDS` listesi + `status_glossary(keyword)` fonksiyonu
  (`_STATUS_GLOSSARY_EN`/`_STATUS_GLOSSARY_TR` sözlükleri). **Keyword başlığı** (örn.
  "Electrified") kasıtlı olarak her zaman İngilizce kalıyor — oyunun "kart isimleri/
  türleri hep İngilizce" kuralıyla tutarlı olsun diye, sadece açıklama gövdesi dile göre
  değişiyor.
- `game_scene.gd`: `_setup_card_glossary()` / `_show_card_glossary()` / `_hide_card_glossary()`
  eklendi. Kart açıklama metni (`_desc_str`) taranıp `STATUS_KEYWORDS`'ten biri geçiyorsa,
  kartın sağında (sığmazsa solunda) bir panel açılıyor, her keyword için kalın başlık +
  açıklama gösteriyor.
  **Mimari not**: panel `$UI`'a DEĞİL, kart seçim ekranının kendi `CanvasLayer`'ına
  (`show_upgrade_menu()`'deki `canvas` değişkeni) ekleniyor — `$UI`'a eklenseydi
  CanvasLayer sıralaması yüzünden kartların arkasında kalırdı (her ikisi de default
  layer=1, `canvas` sonradan eklendiği için üstte kalıyor).
  Tetikleme: `click_area.mouse_entered`/`mouse_exited` (kart büyütme animasyonuyla aynı
  yerde) — kartın TAMAMINA hover, sadece kelimenin üzerine değil (click_area tüm kartı
  kapladığı için RichTextLabel'ın kendi `[hint]` mekanizması hiç tetiklenmiyordu, Connected
  Core rozetinde daha önce bulunan aynı sorun — bu yüzden bu basit yaklaşım seçildi).
  Panel boyutu sabit tahmini yükseklik kullanıyor (`20 + keyword_sayısı × 78`) — async
  `fit_content` hesaplaması yerine, 1 frame gecikme riskini önlemek için.

### İlerleme — Leila Identity (19 kart, index sırasına göre)
- [x] Electric Core (1) — implementasyon doğru (9 hasar + Electrified uygular, kendi
      başına hasar vermiyor, reaksiyon/combo tetikleyicisi). Requires gerekmiyor
      (başlangıç kartı). Dynamic desc eklendi (Core Mastery ile hasar canlı güncelleniyor,
      "Electrified" kelimesi bold): `[b]9[/b] damage.\nApplies [b]Electrified[/b] to enemy`
      / TR: `[b]9[/b] hasar.\nDüşmana [b]Electrified[/b] uygular`.
- [x] Cryo Core (15) — implementasyon doğru ama açıklamada eksik bir sinerji vardı: hedef
      zaten **Wet** ise Slow yerine tam **Frozen** uyguluyor (`ball.gd:2168-2172`), hiç
      yazılmamıştı. Requires gerekmiyor. Dynamic desc: `[b]4[/b] damage.\nSlows enemy by
      25%. Freezes instead if\nenemy is already [b]Wet[/b]` / TR eşleniği.
- [x] Hydro Core (17) — **BUG FIX**: açıklama "single hit" diyordu (bir kez vurup top yok
      olmalı) ama bunu sağlayan `queue_free()`/`return` satırları yorum satırına alınmıştı
      (`ball.gd:2160-2161`) — top hiç yok olmuyordu, diğer core'lar gibi kalıcı kalıp
      tekrar tekrar Wet uyguluyordu. Kullanıcı kararı: **mevcut (kalıcı) davranış doğru
      kabul edildi**, ölü/yorumlanmış kod satırları silindi, açıklama ona göre güncellendi
      ("single hit" ifadesi kaldırıldı, hem dynamic desc hem statik EN fallback'te).
      Dynamic desc: `[b]3[/b] damage.\nApplies [b]Wet[/b] to enemy` / TR eşleniği.
- [x] Pyro Core (18) — implementasyon doğru (6 hasar + `apply_burn()`, 3 tick × 2 hasar/sn
      DOT). Requires gerekmiyor. Dynamic desc eklendi: `[b]6[/b] damage.\nApplies
      [b]Burning[/b] to enemy` / TR eşleniği.
- [x] Plasma Core (61) — **BUG FIX (launcher/hit-chain uyumsuzluğu, tekrarlayan desen)**:
      launcher'da `max_damage=7` yazıyordu ama `can_electric=true` da set ettiği için
      `_hit_subject()`'in ana elif zincirinde `can_electric` dalına düşüp gerçek hasar
      **9** çıkıyordu (launcher'daki 7 hiç kullanılmıyordu). Kullanıcı kararıyla `can_plasma`
      elif zincirine en öncelikli eklendi, gerçek hasar artık 7. Mekanik: isabet ettiği
      düşmana Electrified uygular + 180px (Conduction ile genişleyebilir) içindeki zaten-
      Electrified düşmanlara hasarın yarısını sıçratır. Requires gerekmiyor.
      Dynamic desc: `[b]7[/b] damage. Applies [b]Electrified[/b].\nDeals half damage to
      nearby [b]Electrified[/b] enemies` / TR eşleniği.
- [x] Steam Core (62) — **AYNI BUG deseni**: `can_water=true` yüzünden gerçek hasar 3
      çıkıyordu, launcher'ın niyeti 5'ti — kullanıcı onayıyla `can_steam` elif zincirine
      eklendi, gerçek hasar artık 5. Mekanik: isabette Wet uygular + çarptığı noktada
      buhar bulutu bırakıp 0.8s sonra 45px'teki diğer düşmanlara da Wet uygular. Requires
      gerekmiyor. Dil bug'ı (EN alanı Türkçe yazılmıştı) düzeltildi.
      Dynamic desc: `[b]5[/b] damage. Applies [b]Wet[/b].\nLeaves a steam cloud → nearby
      enemies get [b]Wet[/b]` / TR eşleniği.
- [x] Arc Core (63) — **AYNI BUG deseni + ikinci sayı hatası**: `can_electric=true`
      yüzünden gerçek hasar 9 çıkıyordu, launcher'ın niyeti 6'ydı — düzeltildi. Ayrıca
      açıklama "2 yakın düşmana yayılır" diyordu ama `arc_chain_targets` varsayılan
      **1**'den başlıyor (`player.gd:234`), gerçek limit `2+1=3` (Arc Amplifier (68) her
      alışta +1 daha ekliyor, zaten `requires:[63]` ile doğru bağlı). Dynamic yapıldı,
      artık doğru sayıyı gösteriyor. Requires gerekmiyor. Dil bug'ı düzeltildi.
      Dynamic desc: `[b]6[/b] damage. Applies [b]Electrified[/b].\nSpreads it to [b]3[/b]
      nearby enemies` / TR eşleniği.
- [x] Echo Core (64) — **KRİTİK BUG FIX**: açıklama "dönüşte uygular" diyordu (kopyalanan
      elementin sadece o dönüş yolculuğuna özel, geçici olması bekleniyordu) ama kopyalanan
      element flag'i (`can_electric`/`can_fire`/`can_water`/`can_cryo`) hiçbir yerde
      sıfırlanmıyordu — top bir element kopyaladıktan sonra **kalıcı olarak** o tipe
      dönüşüyordu, üstelik farklı bir element daha kopyalarsa flag'ler hiç temizlenmediği
      için **birikip** aynı anda birden fazla debuff uygulamaya başlıyordu (zamanla
      giderek güçlenen, tasarım dışı bir top). Kullanıcı kararı: **gerçekten geçici
      olmalı**. `_reset_echo_element()` eklendi, `launch()`/`launch_with_speed()`'de
      (her yeni fırlatmada) `_echo_element` ve tüm element flag'leri sıfırlanıyor —
      kopyalanmadıysa top bir sonraki atışta tamamen "çıplak" başlıyor. Requires
      gerekmiyor. Damage tipli core değil (elif zincirinde yok), `max_damage` (5+ball_
      mastery) zaten doğru — dynamic desc'e hasar sayısı da eklendi.
      Dynamic desc: `[b]5[/b] damage. Copies element from\ndebuffed enemy — applies it
      on return` / TR eşleniği.
- [x] Prism Core (65) — Connected Core, orbit'te kalır. Her 2s: 55px içindeki rastgele
      1 düşmana element uygular (Burning/Wet/Electrified/Slowed). Zaten
      `_CONNECTED_CORE_INDICES`'te doğru kayıtlıydı. Requires gerekmiyor. Dil bug'ı
      düzeltildi (EN alanı Türkçe yazılmıştı, TR hiç yoktu), dynamic desc + 4 keyword bold.
      **Bu incelemede Connected Core'ların ortak "dart-strike" mekaniği fark edildi**
      (aşağıya bak).
- [x] Scatter Core (77) — isabette 3 küçük parça oluşturup kendi `queue_free()` oluyor
      (tek vuruşluk, açıklamayla tutarlı). **Bilinen ama düzeltilmeyen bug**: parçalar
      `max_damage=3` ile spawn ediliyor ama rastgele element flag'i taşıdıkları için ana
      hasar zincirinde gerçek hasarları 3-9 arası değişiyor (Electric→9, Fire→6, Cryo→4,
      Water→3). **Kullanıcı kararı: olduğu gibi kalsın** ("çok da OP bir core değil zaten").
      Requires gerekmiyor. TR dil eksikliği giderildi.
- [x] Catalyst Core (78) — Burning/Electrified/Wet/Slowed'ı isabette sıfırlayıp yeniden
      uygulayarak süre tazeliyor. Frozen kapsam dışı — **kullanıcı kararıyla bilinçli
      olarak eklenmedi** (Frozen zaten en güçlü durum efekti). Hasar tipli core değil,
      override bug'ı yok. Requires gerekmiyor. TR eklendi, dynamic desc + bold keyword'ler.
- [x] Voltaic Core (87) — **AYNI can_electric override bug'ı**: launcher'da 8 yazıyordu,
      gerçek hasar 9 çıkıyordu (zincirin her sıçraması da yanlış değeri taşıyordu) —
      düzeltildi, gerçek hasar artık 8. Mekanik: Electrified hedefe çarpınca en yakın
      diğer Electrified düşmana TAM hasarla (Plasma'nın aksine yarım değil) zincirleniyor,
      3 sıçramaya kadar. Requires gerekmiyor. Dil bug'ı düzeltildi.
- [x] Mist Core (185) — Connected Core, her 4s 70px'teki rastgele 1 düşmana Wet. Requires
      gerekmiyor. Dil bug'ı düzeltildi.
- [x] Frost Aura Core (186) — Connected Core, 50px içine giren (henüz Slowed olmayan)
      düşmanlar sürekli kontrol edilip Slow uygulanıyor — sürekli yavaşlatma alanı gibi
      çalışıyor. Requires gerekmiyor. Dil bug'ı düzeltildi.
- [x] Static Aura Core (187) — Connected Core, 60px içine giren düşmanlara Electrified,
      düşman başına 3s cooldown (önceki bir ev session'ında zaten düzeltilmiş bug'dı,
      dictionary düzgün temizleniyor). Requires gerekmiyor. Dil bug'ı düzeltildi.
- [x] **Catalyst Pulse Core (188) — KALDIRILDI (kullanıcı kararı, 2026-09-09)**: açıklama
      "Her 3s: 120px'teki debufflı düşmanların süreleri +1s uzar" diyordu ama kod
      tamamen ölüydü — `burn_ticks`/`wet_duration`/`electrified_duration`/`slow_duration`
      diye 4 property kontrol ediyordu, bunlardan HİÇBİRİ gerçekte var olmuyordu
      (`burn_ticks` sadece `apply_burn()`'ün içinde yerel bir değişken, diğer üçü hiç
      tanımlı değil). `subject.get(X)` var olmayan property için `null` döndüğünden
      `if null and ...` hep false oluyor, 4 blok da sessizce hiçbir şey yapmıyordu.
      **Kök sebep**: gerçek debuff süreleri `await get_tree().create_timer(dur).timeout`
      ile askıya alınmış coroutine'lerin içinde yerel değişken olarak tutuluyor — dışarıdan
      "süreyi uzatma" mimari olarak mümkün değil (Catalyst Core (78) bu sorunu "uzatma"
      yerine "sıfırlayıp yeniden uygulama" ile çözmüştü, aynı çözüm burada da önerildi
      ama kullanıcı kartı komple kaldırmayı tercih etti — Iron Fortress'teki gibi). Tüm
      referansları (kart havuzu, pickup handler, display name, art dosya adı eşlemesi,
      `_CONNECTED_CORE_INDICES`, `ball.gd`'deki ölü mekanik bloğu, `ball_launcher.gd`'deki
      spawn kodu, index→type dispatch tablosu) silindi.
- [x] **Echo Resonance Core (189) — KRİTİK BUG FIX (çakışan çifte implementasyon,
      2026-09-11)**: `ball_launcher.gd`'de "echo_resonance_core" tipi İKİ AYRI `match`
      bloğunda işleniyordu: (1) `can_echo_resonance=true` set eden eski/farklı bir
      mekanik (`_echo_resonance_spread()` — en yakın debufflı düşmanın debuff'ını
      çevresine yayar), (2) `is_inner_core=true`/`inner_core_type="echo_resonance_core"`
      set eden asıl Connected Core mekaniği (`_inner_core_tick()`'teki gerçek kod —
      oyuncunun `last_applied_element`'ini 80px'e yayar, kartın açıklamasıyla birebir
      eşleşen). Her iki `match` de aynı `ball_type` string'ine tepki verdiği için İKİSİ
      DE aynı anda set ediliyordu — kart aynı anda iki farklı, birbiriyle alakasız
      mekaniği paralel çalıştırıyordu (Catalyst Pulse Core'daki gibi bir "dead/gölge
      kod" bug'ı, ama burada ikisi de kısmen çalışıyordu, sadece davranış açıklamadan
      sapıyordu). Kullanıcı kararıyla eski/fazladan mekanik (`can_echo_resonance` flag'i,
      `_echo_res_timer`, `ECHO_RES_INTERVAL`/`ECHO_RES_RADIUS` const'ları,
      `_echo_resonance_spread()` fonksiyonu, ball.gd/game_scene.gd'deki tüm
      `can_echo_resonance` okuma noktaları, ball_launcher.gd'deki ilk match dalı) komple
      silindi — sadece Connected Core (`inner_core_type`) yolu kaldı, diğer Mist/Frost
      Aura/Static Aura Core'larla aynı desende (launcher'da `max_damage` set etmiyor,
      sadece dart-strike'ın genel 3 hasarını kullanıyor). `last_applied_element`
      property'si (player.gd:257) gerçekten var ve her element uygulayan core tarafından
      güncelleniyor (Catalyst Pulse Core'un aksine bu kart ölü değildi, sadece çakışmalıydı)
      — `requires` gerekmiyor, herhangi bir elementli core alınca zaten çalışır. Dil bug'ı
      (aynı tekrarlayan desen): EN `desc` Türkçe yazılmıştı → düzeltildi. TR/EN dynamic
      desc eklendi (`lang.gd`, index 189) — 4 debuff keyword'ü bold gösteriliyor.
      **Kullanıcı kararı (standart kural)**: Connected Core açıklamalarında artık px
      değeri yazılmıyor, "80px içindeki düşmanlara" yerine "yakındaki düşmanlara" /
      "to nearby enemies" gibi genel ifade kullanılıyor — px sayısı oyuncu için anlamsız
      bir teknik detay. Bundan sonra incelenecek tüm Connected Core'larda (Volatile Aura
      Core, Elemental Shield Core, ve Vector'da daha önce yazılmış Iron Aura/Fortress/
      Overcharge Core gibi px içerenler fırsat oldukça) bu kurala göre güncellenmeli.
- [x] **Volatile Aura Core (190) — BUG FIX (2026-09-11)**: implementasyon doğru —
      tick-tabanlı değil, `base_enemy.gd::_notify_reaction()`'a eklenen bir hook üzerinden
      çalışıyor (herhangi bir reaksiyon tetiklenince, kartı taşıyan her ball'un 80px'indeki
      tüm düşmanlara 2 hasar). **Bug**: `_notify_reaction()` 7 reaksiyon türünden 6'sında
      çağrılıyordu (Electrocute/Steam/Cryostatic/Shatter/Melt Frozen/Overcharge) ama
      **Melt reaksiyonunda (`_react_melt()`, Burning+Slowed kombosu) hiç çağrılmıyordu** —
      hem Volatile Aura Core'un pulse'ı hem Perfect Catalyst'in element-tekrar-uygulaması
      hem reaction_heal_amount/momentum bonusu bu reaksiyonda sessizce atlanıyordu.
      Kullanıcı onayıyla düzeltildi: `_react_melt(mult: float)` → `_react_melt(mult, game,
      player)` imzasına çekildi (diğer 6 reaksiyon fonksiyonuyla aynı), `_check_reaction()`
      içindeki 2 çağrı noktası güncellendi, `_notify_reaction(game, player)` diğerleriyle
      aynı sırada (die() kontrolünden ÖNCE, ölüm olsa bile tetiklenecek şekilde) eklendi.
      Requires gerekmiyor (herhangi 2 element kombosu reaksiyon sayılıyor, tek bir core'a
      bağlı değil). Dil bug'ı (aynı tekrarlayan desen) + px kuralı (bkz. yukarı) uygulanarak
      düzeltildi, dynamic desc eklendi.
- [x] **Elemental Shield Core (191) — HAVUZDAN KALDIRILDI (kullanıcı kararı, 2026-09-11,
      Iron Fortress/Catalyst Pulse Core'dan FARKLI — komple silinmedi)**: gerçek mekanik
      (`game_scene.gd::player_damaged()` satır 2350-2357) açıklamayla tutarsızdı —
      açıklama "son uyguladığın element TÜRÜNE özel direnç" vaat ediyordu ama (1) oyunda
      düşman saldırıları element tipine göre ayrışmıyor (hasar hep düz sayı), (2)
      `last_applied_element` hiç sıfırlanmadığı için mekanik aslında "ilk element
      vuruşundan itibaren TÜM hasara kalıcı %20 direnç" gibi çalışıyordu — Hydro Core'daki
      gibi bir "açıklama gerçekte olmayan bir sistemi tarif ediyor" durumu. Kullanıcı bu
      kartı **gereksiz/tutarsız** buldu, ileride boss'lara element uygulanabilen bir
      sistem kurulunca yeniden ele alınmak üzere kart havuzundan (`upgrades` dizisinden)
      çıkarıldı — ama Iron Fortress/Catalyst Pulse Core'un aksine **kod bilerek
      silinmedi**: `ball.gd`'deki sprite-animasyon mantığı, `game_scene.gd`'deki hasar
      azaltma bloğu + index dispatch + art mapping + pickup handler + `_CONNECTED_CORE_
      INDICES` kaydı, `ball_launcher.gd`'deki spawn kodu, `lang.gd`'de (henüz) yazılmamış
      açıklama — hepsi dokunulmadan duruyor, kart sadece havuzdan çekilemez hale getirildi
      (`upgrades` dizisindeki satır yorum satırına çevrildi). **Sonraki adımda ele
      alınacak**: boss element sistemi netleşince bu kart ya orijinal haliyle geri
      eklenecek ya da o sisteme göre yeniden tasarlanacak.

**LEILA IDENTITY TAMAMLANDI (19/19 kart incelendi, Elemental Shield Core havuzdan
kaldırıldı) — 2026-09-11**

### KRİTİK BUG FIX: Electric/Cryo/Hydro/Pyro Amp + kendi Core'ları — aynı override deseni
      (2026-09-11, Electric Amp (13) incelenirken bulundu)
`ball.gd::_hit_subject()`'in hasar zincirinde `elif can_electric: base_damage = 9`,
`elif can_cryo: base_damage = 4`, `elif can_water: base_damage = 3`, `elif can_fire:
base_damage = 6` — Plasma/Steam/Arc/Voltaic'te bulunanla AYNI bug deseni: sabit sayılar
`max_damage`'i (ki `electric_bonus`/`cryo_bonus`/`hydro_bonus`/`pyro_bonus` — Amp
kartlarının kaynağı — + `ball_mastery` zaten içinde, `ball_launcher.gd:254-269`) komple
eziyordu, sonra sadece `ball_mastery` tekrar ekleniyordu (Amp bonusları hiç). **Sonuç:
Electric Amp (13) / Cryo Amp (99) / Hydro Amp (100) / Pyro Amp (101) kartlarının 4'ü de
tamamen ölüydü** — Leila'nın en temel 4 Identity core'unun (Electric/Cryo/Hydro/Pyro Core)
kendi Amp'ları hiç çalışmıyordu.
**Fix**: 4 core için de `base_damage = max_damage` + `_typed_core = false` (max_damage
zaten ball_mastery içerdiği için çift eklenmesin diye) yapıldı. `lang.gd`'deki 4 core'un
(1/15/17/18) dynamic desc formülüne ilgili `_bonus` stat'ı eklendi (artık gerçek hasarı
gösteriyor). 4 Amp kartına `requires` eklendi (kendi core'u alınmadan havuza girmesin —
Electric Amp→[1], Cryo Amp→[15], Hydro Amp→[17], Pyro Amp→[18]), TR dil eksikliği
(99/100/101'de hiç TR girdisi yoktu) giderildi.
**NOT — aynı bug muhtemelen Vector'da da var**: `can_pierce` de sabit `base_damage = 5`
kullanıyor ama `pierce_bonus` (Ball Mastery'nin farklı bir kartı, index 12) `ball_launcher.
gd:257`'de `max_damage`'e ekleniyor — yani **Pierce Core (2)**'nin kendi damage-bonus
kartı da muhtemelen ölü. Bu, Vector Identity review'i ZATEN TAMAMLANMIŞ olduğu için o
turda kaçırılmış bir bug — ayrı olarak ele alınmalı (henüz düzeltilmedi, kullanıcı onayı
bekliyor).

- [x] Conduction (66) — **KAPSAM GENİŞLETME (kullanıcı kararı, 2026-09-12)**:
      `electric_reaction_range_mult` (×1.3) eskiden SADECE Plasma Core'un (61) 180px
      Electrified-sıçrama menzilinde kullanılıyordu — Arc Core'un (63) 160px yayma
      menzili ve Voltaic Core'un (87) 220px zincir menzili bu çarpanı hiç okumuyordu,
      isim/açıklama ("Electric reaction range") ise genel bir izlenim veriyordu. Kullanıcı
      "bütün elektrik yayan toplar" istedi — `_arc_range`/`_voltaic_chain()`'in
      `_nearest_dist` başlangıç değeri de aynı çarpanla ölçeklendirildi, artık 3 core'u
      birden etkiliyor. `requires_any: [61, 63, 87]` eklendi (üçünden biri yoksa kart
      faydasız kalıyordu). Not: gerçek reaksiyon sistemi (Electrocute/Steam/vb.,
      `_check_reaction()`) hâlâ etkilenmiyor — bunlar menzile değil, aynı düşman
      üzerindeki debuff çakışmasına dayanıyor, kavramsal olarak "range" içermiyorlar.
      TR dil eksikliği (hiç girdi yoktu) giderildi.

- [x] Hydro Pressure (67) — implementasyon doğru: Fırlatılan Hydro/Steam Core'lar (`ball_
      type in ["water","steam"]`) %25 daha hızlı fırlıyor (`ball_launcher.gd:431`),
      Connected Mist Core / Prism Core (`can_orbit`) varsa iç yörünge dönüş hızı %25
      artıyor (`player.gd:740`) — `requires_any: [17,62,65,185]` zaten doğru 4 core'u
      kapsıyor. Dil bug'ı (aynı tekrarlayan desen): EN `desc` Türkçe yazılmıştı →
      düzeltildi, TR hiç yoktu → eklendi.

- [x] Arc Amplifier (68) — implementasyon doğru: `arc_chain_targets += 1` (Arc Core'un
      dynamic desc formülüyle — "2 + arc_chain_targets" — birebir eşleşiyor), `requires:
      [63]` zaten doğruydu. Dil bug'ı (aynı tekrarlayan desen): EN `desc` Türkçe
      yazılmıştı → düzeltildi, TR hiç yoktu → eklendi.

- [x] Static Charge (69) — implementasyon doğru: Electrified düşman hasar alınca (`from_
      ally` değilse) 150px içindeki diğer Electrified düşmanlara hasarın %40'ı doğrudan
      `health -=` ile aktarılıyor (`take_damage()` üzerinden değil — sonsuz zincir riski
      yok). **Eksik**: `requires` hiç yoktu, Electrified uygulayan hiçbir core (Electric/
      Plasma/Arc/Voltaic) olmadan tamamen faydasız kalabiliyordu — `requires_any: [1, 61,
      63, 87]` eklendi (Conduction'daki gibi). EN zaten temizdi, TR hiç yoktu → eklendi.

- [x] Supercooling (71) — implementasyon doğru: `base_enemy.gd::apply_slow()`'da
      (satır 490-492) `cryo_slow_mult` ile yavaşlatma miktarı çarpılıyor (0.9 tavanı var,
      %90'ı geçemiyor), herhangi bir cryo-kaynaklı slow'u (Cryo Core + Frost Aura Core)
      etkiliyor — genel/doğru bir kapsam. **Eksik**: `requires` yoktu, `requires_any:
      [15, 186]` eklendi (Cryo Core / Frost Aura Core). Dil bug'ı: EN `desc`'te "+%15"
      Türkçe format sızıntısıydı → "+15%" düzeltildi, TR hiç yoktu → eklendi.

- [x] Thermal Vision (73) — implementasyon doğru: `base_enemy.gd::apply_burn()`'de
      (satır 305-306) `burn_damage_mult` ile tick hasarı çarpılıyor, herhangi bir
      Burning-uygulayan core'u (Pyro Core + Prism Core) etkiliyor. **Eksik**: `requires`
      yoktu, `requires_any: [18, 65]` eklendi. Dil bug'ı: EN `desc`'te "+%20" Türkçe
      format sızıntısıydı → "+20%" düzeltildi, TR hiç yoktu → eklendi.

- [x] **Arcane Mind (80) — KRİTİK BUG FIX (sıralama hatası, 2026-09-12)**:
      `apply_wet()`/`apply_electrified()`/`apply_slow()`'un hepsinde `is_wet`/
      `is_electrified`/`is_slowed` flag'i ÖNCE `true` yapılıyor, `first_debuff_duration_
      mult` kontrolü (`not _had_any_element()`) SONRA çalışıyordu — `_had_any_element()`
      (`is_burning or is_wet or is_electrified or is_slowed or is_frozen`) kendi az önce
      set edilen flag'i gördüğü için HER ZAMAN true dönüyordu, yani "ilk element mi"
      kontrolü asla `true` olamıyordu. **Sonuç: Arcane Mind (80) ve Arcane Focus (75,
      Individuality) ikisi de %100 ölüydü** — hiçbir zaman hiçbir debuff süresini
      uzatmadılar. Ayrıca kontrol `apply_burn()`'de hiç yoktu (Burning tamamen kapsam
      dışıydı), açıklama ise "First applied element" (element = herhangi biri) diyordu.
      **Fix**: her 4 fonksiyonda da (`apply_wet`/`apply_electrified`/`apply_slow`/
      `apply_burn`) flag set edilmeden HEMEN ÖNCE `var _was_first := not
      _had_any_element()` ile anlık durum donduruldu, mult kontrolü bu değişkeni
      kullanacak şekilde değiştirildi. `apply_burn()`'e de aynı kontrol eklendi (`dur`
      yerine `burn_ticks` ölçekleniyor, `int(round(burn_ticks * mult))`). `apply_frozen()`
      dokunulmadı — o zaten sadece bir reaksiyon sonucu (cryo+wet), "ilk debuff" hiç
      olamıyor, mantıklı bir istisna.
      **NOT**: Arcane Focus (75, Individuality kategorisinde) de bu fonksiyonları
      kullanıyor, dolayısıyla bu fix onu da otomatik düzeltti — Individuality turunda
      ayrıca dokunmaya gerek yok, sadece dil/requires kontrolü yeterli olacak.

- [x] **Resonance Engine (81) — KRİTİK BUG FIX + TASARIM DEĞİŞİKLİĞİ (2026-09-14)**:
      **Bug**: `base_enemy.gd::_notify_reaction()`'da `if player.get("momentum_stacks")
      and player.get("momentum_max"):` — bu satır aslında "bu property var mı" kontrolü
      olması gerekirken, GDScript'te `momentum_stacks` varsayılan `0` (int) olduğu için
      boolean bağlamda **falsy** sayılıyordu — `momentum_stacks == 0` iken (oyunun başı,
      ya da hiç başka kaynak yoksa) koşul hep `false` dönüyor, `gain_momentum(1)` hiç
      çağrılmıyordu. **Leila'ya özel kritik yan etki**: Momentum Engine (35) `"chars":
      ["vector"]` — Leila'nın kart havuzunda YOK, Leila'nın başka hiçbir momentum
      kaynağı da yok. Yani Resonance Engine Leila için **tek** momentum kaynağıydı, ama
      "stack zaten >0 ise +1 daha ver" mantığı ile birleşince **tam bir kilitlenme**
      oluşuyordu — stack'i sıfırdan yükseltecek hiçbir yol yoktu, sonsuza dek 0'da kalırdı.
      **Kullanıcı kararıyla mekanik tamamen yeniden tasarlandı**: artık Vector'ın paylaşımlı
      `momentum_stacks`/`gain_momentum()` sistemine hiç dokunmuyor, kendine özel **geçici,
      stack-bazlı bir sistem** kullanıyor:
      - `player.gd`: `has_resonance_engine` (bool) + `resonance_stacks: Array[float]`
        (her eleman bir stack'in kalan süresi) + `RESONANCE_MAX_STACKS=5` +
        `RESONANCE_STACK_DURATION=3.0` + `RESONANCE_SPEED_PER_STACK=0.02`.
      - `add_resonance_stack()`: 5'in altındaysa yeni stack ekler (3s), doluysa en eskisini
        3s'ye resetler.
      - `_physics_process`'teki `core_speed_mult` zincirine eklendi: her frame tüm
        stack'lerin süresi azaltılıyor, süresi bitenler diziden siliniyor, kalan stack
        sayısı × %2 geçici Core Speed olarak çarpanlanıyor — **kalıcı/birikimli DEĞİL**,
        kullanıcı özellikle "kalıcı yapmayalım" dedi (eski `orbit_speed_mult +=` kalıcı
        birikim mantığı tamamen kaldırıldı).
      - `_notify_reaction()`'daki eski blok `if player.get("has_resonance_engine") and
        player.has_resonance_engine: player.add_resonance_stack()` ile değiştirildi.
      - Momentum bar'ı (HUD) **bilerek eklenmedi** — kullanıcı: "harcanabilir bir kaynak
        değil Leila için", sadece arka planda sessizce Core Speed'i besleyen bir sistem.
      - `requires` gerekmiyor (Volatile Aura Core'daki gibi, herhangi 2 element kombosu
        yeterli, tek bir core'a bağlı değil).
      **Yeni genel özellik — "Momentum" glossary keyword'ü**: kullanıcı Vector'da da
      "Momentum" kelimesinin hiçbir yerde açıklanmadığını fark etti ("Core Speed'i temsil
      ediyor" bilgisi hiçbir kartta yazmıyordu). `Lang.STATUS_KEYWORDS`'e "Momentum"
      eklendi (Electrified/Wet/Burning/Slowed/Frozen ile aynı text-scan mekanizması —
      Connected Core'un aksine, kelime açıklama metninde gerçekten geçiyor), glossary
      girdisi: "Represents Core Speed — each stack makes your cores move faster." / TR
      karşılığı. **Bu, hem Resonance Engine'in hem TÜM Vector Momentum kartlarının
      (Momentum Engine, Momentum Cascade, Pressure Valve, vb. — "Momentum" kelimesi geçen
      her kart) hover popup'ında otomatik olarak açıklama göstermesini sağlıyor** —
      tek bir merkezi düzeltmeyle geriye dönük tüm kartlara yayıldı.

- [x] Frozen Time (82) — implementasyon doğru: `base_enemy.gd::apply_frozen()`'da
      `freeze_duration_mult` (varsayılan 1.0, Resonance Engine'deki 0-falsy riski yok)
      ile 3sn'lik dondurma süresi çarpanlanıyor. Requires eklenmedi (Frozen bir reaksiyon
      sonucu — Volatile Aura Core/Resonance Engine'deki gibi tek bir core'a bağlı değil).
      Dil: EN zaten temizdi, TR hiç yoktu → eklendi. Açıklama "Freeze" → "[b]Frozen[/b]"
      olarak güncellendi (glossary keyword'üyle eşleşsin diye — artık hover'da Frozen'ın
      ne olduğunu gösteren panel açılıyor).
      **Yan bulgu (kart değil, ayrı not)**: **Cryostasis (index 70)** — Pierce Amp (12)/
      Split Amp (14) ile aynı orphan/ölü kod deseni: `freeze_duration_mult *= 1.1`
      pickup handler'ı + display-name kaydı var ama `upgrades` dizisinde hiç kart tanımı
      yok, oyuncu asla alamıyor. Kullanıcıya soruldu, henüz karar verilmedi — "Fikirler /
      Değerlendirilecek" bölümüne not düşüldü (aşağı bak).

- [x] Overheat (83) — implementasyon doğru: `_overheat_counter` (player-level) her burn
      tick'inde +1, 33'e ulaşınca `_react_overheat()` tetiklenip 150px'e 15 hasar
      (sıfırlanıp tekrar birikmeye başlıyor). Pyroblast (102) sinerjisi doğrulandı
      (`has_pyroblast` ile radius `150+saved_count×8`'e büyüyor). `requires_any: [18,65]`
      eklendi (Pyro Core / Prism Core — Burning uygulayan tek kaynaklar). Dil bug'ı
      (aynı tekrarlayan desen) düzeltildi, "Burning" keyword'ü bold yapıldı (glossary'e
      bağlandı). **Tasarım sorusu netleşti (kullanıcı onayı, 2026-09-14)**: sayacın
      player-level (düşman-özel değil) olması kasıtlı — çok düşman aynı anda yanınca
      patlamanın daha hızlı tetiklenmesi bilinçli bir sinerji, bug değil.

- [x] Elemental Harmony (84) — implementasyon doğru: `game_scene.gd::_process()`'te
      (satır 4295-4304) her frame sahadaki TÜM düşmanlar taranıyor, aktif debuff
      tiplerinin (Wet/Burning/Slowed/Electrified/Frozen) benzersiz sayısı hesaplanıp
      `elemental_harmony_bonus = benzersiz_sayı × 0.05` yapılıyor (`core_speed_mult`
      zincirinde okunuyor) — kaynağı kim uyguladıysa uygulasın sayılıyor, sürekli canlı
      güncelleniyor. Requires gerekmiyor (genel saha taraması, tek bir core'a bağlı
      değil). Dil: EN zaten temizdi, TR hiç yoktu → eklendi.

- [x] Thermal Expansion (89) — implementasyon doğru: `base_enemy.gd::_react_steam()`'de
      (satır 669-676) Steam reaksiyon menzili 120→200px genişliyor, ayrıca menzildeki
      düşmanlara Wet de uygulanıyor. **Eksik açıklama**: eski desc ("Steam explosion area
      grows") ikinci etkiyi (Wet yayılımı) hiç belirtmiyordu → eklendi, sayı da netleşti
      (+67%, px yerine yüzde — Conduction'daki gibi). Requires eklenmedi (Steam reaksiyonu
      Wet+Burning kombosu gerektiriyor, tek bir core'a bağlı değil — Volatile Aura Core/
      Frozen Time'daki gibi). TR hiç yoktu → eklendi.

- [x] Mana Overflow (90) — implementasyon doğru: `_consume_calamity()`'de (game_scene.gd:
      2007-2008) her Calamity kullanımında `mana_overflow_timer += 5.0` (üst üste
      kullanımda süre uzuyor), `player.gd`'nin `core_speed_mult` zincirinde
      (`mana_overflow_timer > 0.0` iken ×1.5) okunuyor. Requires gerekmiyor (Calamity
      sistemi zaten evrensel). Açıklama netleştirildi (sayı/süre hiç yazmıyordu →
      "+50% Core Speed for 5s" eklendi). TR hiç yoktu → eklendi.

- [x] Perfect Catalyst (91) — implementasyon doğru: `_notify_reaction()`'da (base_enemy.
      gd:766-773) herhangi bir reaksiyon tetiklenince `last_applied_element`'e göre
      (fire/wet/electric/cryo) ilgili `apply_X()` tekrar çağrılıyor (zaten o debuff aktif
      değilse). `apply_slow(0.25)` çağrısı da Supercooling'in `cryo_slow_mult`'unu
      dahili olarak zaten okuyor — çift işlem riski yok. Requires gerekmiyor (reaksiyon
      genel bir sistem). Dil: EN temizdi, TR hiç yoktu → eklendi.

- [x] Pyroblast (102) — implementasyon doğru: `_react_overheat()`'te (base_enemy.gd:344-345)
      `has_pyroblast` iken patlama yarıçapı `150 + saved_count×8`'e büyüyor (Overheat'in
      33'e ulaşan tick sayacına bağlı). **Eksik**: `requires` yoktu — Overheat (83)
      olmadan kart tamamen anlamsız (patlama hiç tetiklenmez) → `requires: [83]` eklendi.
      Açıklama netleştirildi ("Burn Stacks" yanıltıcıydı — bu mekanik burn debuff süresiyle
      değil, Overheat'in tick sayacıyla ilgili → "Overheat'in patlama yarıçapı, biriken
      tick sayısına göre büyür" olarak düzeltildi). TR hiç yoktu → eklendi.

- [x] **Cryo Burst (210) — AÇIKLAMA/YORUM DÜZELTMESİ (kullanıcı kararı, 2026-09-14)**:
      `take_damage()`'da (base_enemy.gd:192-194) Slowed düşmana yapılan HER vuruşta +8
      bonus hasar veriliyor, tekrarı engelleyen bir mekanizma yok. Ama açıklama ("sonraki
      vuruş") ve kod yorumu ("1 kez/düşman") bunun tek seferlik olması gerektiğini
      ima ediyordu. Kullanıcı kararı: **kod doğru, açıklama yanlıştı** — davranış
      değiştirilmedi (basit ve güçlü bir sinerji kartı olarak kalıyor), hem `desc` hem
      `lang.gd` hem `player.gd`/`base_enemy.gd`'deki yanıltıcı yorumlar "her vuruşta"
      diye düzeltildi. `requires_any: [15, 186]` eklendi (Cryo Core / Frost Aura Core —
      Slowed uygulayan tek kaynaklar), dil bug'ı (EN alanı Türkçe yazılmıştı) düzeltildi.

- [x] Arc Overload (211) — implementasyon doğru: `_react_electrocute()`'te (base_enemy.gd)
      `has_arc_overload` iken 180px'teki 1 ek düşmana 5 hasar zinciri ekleniyor (ölürse
      `die("electric")`). Requires eklenmedi (Electrocute reaksiyonu Electric+Wet kombosu
      gerektiriyor, tek bir core'a bağlı değil — Frozen Time/Volatile Aura Core'daki gibi).
      Dil bug'ı (aynı tekrarlayan desen): EN `desc` Türkçe yazılmıştı → düzeltildi, TR
      hiç yoktu → eklendi.

**LEILA UTILITY TAMAMLANDI (21/21 kart) — 2026-09-14**

- [x] **Mystic Flow (76) — 3 KATMANLI KRİTİK BUG FIX (2026-09-14)**:
      1. **Çifte/çakışan sayaç sistemi**: `mystic_flow_stacks` iki ayrı, birbirinden
         habersiz yerden besleniyordu — `ball.gd::_defense_hit()` (SADECE Connected
         Core dart-strike'ında, `can_fire`/`can_water`/`can_electric`/`can_cryo` flag'i
         olan bir top vurunca) doğru uniqueness kontrolü yapıp `SPEED += 5` (sabit)
         ekliyordu; `base_enemy.gd::_notify_mystic_flow()` (HER `apply_burn/wet/
         electrified/slow` çağrısında — reaksiyonlar, Perfect Catalyst, Prism/Mist/
         Frost Aura Core'un periyodik uygulamaları dahil) hiçbir uniqueness kontrolü
         yapmadan sayaç artırıp `move_speed_bonus_pct` (yüzdesel, ayrı bir çarpan) set
         ediyordu — oyuncu aynı anda hem sabit hem yüzdesel bonus alıyordu, "her
         BENZERSİZ element" açıklaması da unique olmayan tekrarlarla bozuluyordu.
      2. **`ball.gd`'deki "doğru" yol aslında hiç çalışmıyordu**: hiçbir mevcut Connected
         Core `can_fire`/`can_water`/`can_electric`/`can_cryo` flag'i kullanmıyor
         (`inner_core_type` dispatch sistemi kullanıyorlar), yani bu blok pratikte
         erişilemez ölü kodtu.
      3. **`has_mystic_flow` flag'i hiç yoktu**: mekanik kart alınıp alınmadığına
         bakılmaksızın (varsa) her oyuncuda otomatik çalışıyordu — kartın (76) pickup
         handler'ı sadece `mystic_flow_stacks`/`move_speed_bonus_pct`'i SIFIRLIYORDU,
         yani kartı almak o ana kadarki bonusu siliyordu (zararlı bir seçim).
      **Fix (kullanıcı onayıyla, ball.gd yolu tek otorite yapılacaktı ama ölü olduğu
      anlaşılınca base_enemy.gd yoluna karar değişti)**: `player.gd`'ye `has_mystic_flow`
      eklendi, pickup handler artık bunu `true` yapıyor (reset yerine). `_notify_mystic_
      flow()`'a hem `has_mystic_flow` kontrolü hem gerçek uniqueness kontrolü (`_element
      in mystic_flow_elements`) eklendi — artık TEK, doğru çalışan sistem. `ball.gd`'deki
      ölü blok (Mystic Flow + kullanılmayan `has_elemental_harmony_ind` — hiçbir kart bu
      flag'i hiç set etmiyordu, o da orphan'dı) silindi, `last_applied_element` güncellemesi
      (Echo Resonance Core/Perfect Catalyst için kritik) korundu. `has_elemental_harmony_
      ind` ve kullanılmayan `has_resonant_soul_ind` (aynı şekilde tamamen orphan, "Resonant
      Soul" kartının gerçek mekaniği zaten `reaction_heal_amount` üzerinden farklı çalışıyor)
      `player.gd`'den de silindi.
      **Sayı düzeltmesi**: yalnızca 4 element tipi var (fire/wet/electric/cryo), yani
      gerçek maksimum +%4 (eski açıklama "max %20" diyordu — 20 stack limiti anlamsızdı,
      kaldırıldı) → açıklama "max 4%" olarak düzeltildi. Requires eklenmedi (herhangi bir
      element core'u yeterli, tek birine bağlı değil). TR hiç yoktu → eklendi.

### AÇIK İŞ — Leila Utility Lv1/Lv2/Lv3 scaling eksik (2026-09-14, kullanıcı hatırlattı)
Vector'ın Utility kartlarında her kart `_apply_utility_level(index, level)`'da Lv1/Lv2/Lv3
için ayrı değerlere sahipken, incelediğimiz **21 Leila Utility kartının HİÇBİRİ için bu
fonksiyonda bir `case` yok**. Havuz mantığı (`_utility_levels[isim] < 3`, satır 2840-2844)
kategoriye göre otomatik çalıştığı için TÜM Utility kartları (Leila'nınkiler dahil) 3 kez
alınabiliyor — ama level'a göre ayrım yapmayan kartlarda 2./3. alış ya `+=`/`*=` sayesinde
doğal olarak ölçekleniyor (Amp'lar, Conduction, Arc Amplifier, Supercooling, Thermal
Vision, Arcane Mind, Frozen Time) ya da **`has_X = true` boolean olduğu için tamamen
ziyan oluyor** (Hydro Pressure 67, Static Charge 69, Resonance Engine 81, Overheat 83,
Elemental Harmony 84, Thermal Expansion 89, Mana Overflow 90, Perfect Catalyst 91,
Pyroblast 102, Cryo Burst 210, Arc Overload 211 — bu 11 kart 2./3. alışta sıfır etki
yaratıyor, oyuncu boş yere upgrade slotu harcıyor).
**Kullanıcı kararı**: Leila Individuality review'i bitince buraya dönülecek, bu 21 (özellikle
boolean olan 11) karta tek tek Vector'daki gibi Lv1/Lv2/Lv3 değerleri tasarlanacak.

### TAMAMLANDI — Leila Utility Lv1/Lv2/Lv3 scaling (2026-09-14)
Individuality bitince bu işe dönüldü, tüm kararlar uygulandı:

**1. Electric/Cryo/Hydro/Pyro Amp (13/99/100/101) — HAVUZDAN KALDIRILDI (kullanıcı
kararı)**: "Bunu sanki konuşmuştuk" — evet, Fikirler bölümündeki not buydu, şimdi
uygulandı. Elemental Shield Core'daki gibi kod silinmedi (`upgrades` dizisindeki 4 satır
yorum satırına çevrildi), sadece havuzdan çekilemez hale getirildi — ileride level-up/
coin sistemine dönüşebilir.

**2. Perfect Catalyst (91) — Utility'den Individuality'ye TAŞINDI (kullanıcı kararı)**:
"tier gerektirecek bişi yok" — binary bir mekanik (reaksiyon → son element tekrar
uygula), sayısal scaling'e uygun değildi. `_UPGRADE_META[91]` ve `upgrades` dizisindeki
`category` alanı "Individuality" yapıldı, pickup handler'a `_seen_individualities.
append("Perfect Catalyst")` eklendi (artık tek seferlik alınabiliyor, diğer Individuality
kartlarıyla aynı desen).

**3. Kalan 16 karta Lv1/Lv2/Lv3 scaling eklendi** (`_apply_utility_level()`'a yeni
`match index:` case'leri, `player.gd`'ye yeni scaling değişkenleri, ilgili tüm consumer
kod noktaları hardcoded sayı yerine bu değişkenleri okuyacak şekilde güncellendi):

| Kart | Lv1 | Lv2 | Lv3 |
|---|---|---|---|
| Conduction (66) | +20% menzil | +30% | +45% |
| Hydro Pressure (67) | +20% hız | +25% | +35% |
| Arc Amplifier (68) | +1 hedef | +2 | +3 |
| Static Charge (69) | %25 aktarım | %35 | %45 |
| Supercooling (71) | +15% slow | +25% | +40% |
| Thermal Vision (73) | +20% burn dmg | +30% | +45% |
| Arcane Mind (80) | ×1.5 | ×2.0 | ×3.0 |
| Resonance Engine (81) | maks 3 stack | maks 4 | maks 5 (%2/stack, 3sn sabit) |
| Frozen Time (82) | +25% freeze süresi | +35% | +50% |
| Overheat (83) | 45 tick eşiği | 35 | 25 |
| Elemental Harmony (84) | %3/unique | %4.5 | %6 |
| Thermal Expansion (89) | 100px | 150px | 200px |
| Mana Overflow (90) | +30%/4sn | +40%/5sn | +60%/6sn |
| Pyroblast (102) | ×4 px/tick | ×6 | ×9 |
| Cryo Burst (210) | +4 bonus dmg | +6 | +9 |
| Arc Overload (211) | 1 hedef/4dmg | 1 hedef/5dmg | 2 hedef/5dmg |

**Teknik detaylar**:
- Eskiden `*=`/`+=` ile biriken kartlar (Conduction, Arc Amplifier, Supercooling, Thermal
  Vision, Arcane Mind, Frozen Time) artık `_apply_utility_level`'da MUTLAK değer set
  ediyor (biriktirmiyor) — elif dispatch'teki eski `*=`/`+=` satırları `pass`'e çevrildi.
- Eskiden sabit sayı olan mekanikler için yeni `player.gd` değişkenleri eklendi:
  `static_charge_mult`, `hydro_pressure_mult`, `overheat_threshold`,
  `elemental_harmony_util_bonus`, `thermal_expansion_radius`, `mana_overflow_duration`,
  `mana_overflow_mult`, `pyroblast_mult`, `cryo_burst_bonus`, `arc_overload_targets`,
  `arc_overload_dmg`, `resonance_max_stacks` (const'tan var'a çevrildi) — hepsi ilgili
  `base_enemy.gd`/`ball_launcher.gd`/`player.gd`/`game_scene.gd` konumlarında hardcoded
  sayının yerine geçti.
- `lang.gd::_dynamic_desc()`'e 16 kart için canlı-değer gösteren case'ler eklendi (Vector
  Pressure Valve/Momentum Cascade'deki desen — `[b]%d[/b]` ile güncel seviye değeri).
  İlgili eski statik `_DESC_TR` girdileri (artık dynamic'in gölgelediği) silindi.
- EN fallback `desc` alanları dokunulmadı (zaten temizdi, dynamic zaten önceliği alıyor).

- [x] Resonant Soul (85) — implementasyon doğru: `_notify_reaction()`'da (base_enemy.gd:
      765-767) `reaction_heal_amount` (=2) her reaksiyonda `heal_player()`'a geçiyor,
      `player_hp` max'ı aşmıyor. Individuality kategorisinde (tek seferlik, `_seen_
      individualities` ile tekrar alınamıyor) — Utility'lerdeki gibi bir level/scaling
      sorunu yok. Requires gerekmiyor. Dil: EN temizdi, TR hiç yoktu → eklendi.

- [x] Elemental Memory (86) — implementasyon doğru (eski bilinen sorun listesindeki
      "kalıcı 2× uzama" bug'ı yanlış alarmmış, bkz. yukarıdaki düzeltme): reaksiyon
      tetiklenince (`_notify_reaction()`) `_had_reaction=true` set ediliyor, düşmanın
      bir sonraki debuff'ı (`apply_burn/wet/electrified/slow`) bunu görüp süreyi ×2
      yapıp flag'i hemen sıfırlıyor — tek seferlik, açıklamayla birebir eşleşiyor.
      Requires gerekmiyor. Dil bug'ı (EN alanı Türkçe yazılmıştı) düzeltildi, TR hiç
      yoktu → eklendi.

- [x] Wet Armor (200) — implementasyon doğru: `player_damaged()`'da (game_scene.gd:
      2342-2349) sahada Wet bir düşman varsa gelen hasar ×0.9 (en az 1). **Eksik**:
      `requires` yoktu, `requires_any: [17, 62, 65, 185]` eklendi (Hydro/Steam/Prism/
      Mist Core — Wet uygulayan kaynaklar). Dil bug'ı (aynı tekrarlayan desen): EN
      `desc` Türkçe yazılmıştı → düzeltildi, TR hiç yoktu → eklendi.

- [x] Burn Frenzy (201) — implementasyon doğru: `apply_burn()`'de (base_enemy.gd:307-312)
      sahadaki yanan düşman sayısı (kendisi dahil) sayılıp `tick_dmg += min(count, 7)`
      yapılıyor. `requires_any: [18, 65]` eklendi (Pyro Core / Prism Core). Dil bug'ı
      (aynı tekrarlayan desen): EN `desc` Türkçe yazılmıştı → düzeltildi, TR hiç yoktu
      → eklendi.

- [x] Steam Surge (202) — implementasyon doğru: Steam reaksiyonunda (base_enemy.gd:
      682-683) `_steam_surge_timer=3.0` set ediliyor, `player.gd:610`'da hareket
      hızına ×1.15 uygulanıyor (Mystic Flow'un `move_speed_bonus_pct`'iyle çakışmadan,
      ayrı çarpan olarak). Requires eklenmedi (Steam reaksiyonu genel, tek bir core'a
      bağlı değil). Dil bug'ı (aynı tekrarlayan desen) düzeltildi, TR hiç yoktu → eklendi.

- [x] Shock Reflex (203) — implementasyon doğru: Electrocute reaksiyonunda (base_enemy.gd)
      `_shock_reflex_timer=3.0`, `player_damaged()`'da timer aktifken %8 ihtimalle hasar
      tamamen iptal ediliyor (`randf() < 0.08: return`). Requires eklenmedi (Electrocute
      reaksiyonu genel). Açıklama netleştirildi ("%8 hasar kaçınma" → "%8 İHTİMALLE
      kaçınma", şans-bazlı olduğu netleşti). Dil bug'ı düzeltildi, TR hiç yoktu → eklendi.

- [x] **Frost Barrier (204) — İSİM DÜZELTMESİ (kullanıcı kararı, 2026-09-14)**: kod
      `_react_shatter()`'ın içinde tetikleniyor (Electric+Frozen kombosu — zaten Frozen
      olan düşmana Shatter uygulanınca), ama açıklama "Freeze reaksiyonu" diyordu — bu,
      düşmanın Frozen HALE GELMesiyle (Cryo+Wet, `apply_frozen()`) karıştırılabilirdi,
      iki farklı reaksiyon. Kullanıcı kararıyla açıklama "Shatter reaksiyonu" olarak
      düzeltildi (mekanik değişmedi, sadece isimlendirme netleşti). Mekanik doğru:
      +5 HP kalkan (birikir, maks 20), timer her tetiklemede 4s'ye resetleniyor, süre
      bitince kalkan komple sıfırlanıyor (kademeli değil, ani). Requires eklenmedi
      (Shatter, Frozen+Electric çoklu kombo gerektiriyor, tek bir core'a bağlı değil).
      Dil bug'ı düzeltildi, TR hiç yoktu → eklendi.

- [x] Primal Instinct (205) — implementasyon doğru: `_notify_reaction()`'da (base_enemy.
      gd:843-848) `_wave_reaction_types` (Void Resonance ile paylaşımlı dizi) benzersiz
      reaksiyon tiplerini biriktiriyor, 3'e ulaşınca `_primal_instinct_timer=5.0` set
      ediliyor, `take_damage()`'da (enemy'nin kendi fonksiyonu) timer aktifken oyuncunun
      verdiği hasar ×1.1 oluyor. Dizi `show_upgrade_menu()` açıldığında (her level-up'ta)
      sıfırlanıyor — "dalga" burada gerçek düşman dalgası değil, level-up aralığı anlamına
      geliyor (Void Resonance'ta da aynı kullanım). Açıklama netlik için "Bir dalgada" →
      "Bir sonraki level up'a kadar" olarak güncellendi (yanlış anlaşılmasın diye — gerçek
      düşman dalgası kavramıyla karışabilirdi). Requires gerekmiyor (genel reaksiyon
      sistemi). Dil bug'ı (EN alanı Türkçe yazılmıştı) düzeltildi, TR hiç yoktu → eklendi.

- [x] **Melt Spiral (206) — 2 BUG FIX (2026-09-14)**: Melt reaksiyonunda (`_notify_
      reaction()`, base_enemy.gd:790-829) düşman konumunda 2s'lik alev VFX'i bırakıyor.
      **Bug 1**: hasar 0.5s aralıklarla 4 kez (2 hasar/s) veriliyordu, açıklama "(1/s)"
      diyordu — 4 tick'ten 2 tick'e (1.0s ve 2.0s) düşürüldü, artık gerçekten 1 hasar/s.
      **Bug 2 (Siege Rain'deki AYNI pause bug'ı)**: `create_timer()` çağrıları
      `process_always` varsayılanıyla (true) kullanılıyordu — `upgrading` (level-up menüsü,
      `get_tree().paused=true`) sırasında bu sayaçlar durmuyordu, menüden çıkınca birikmiş
      tick'ler aynı anda patlayabiliyordu. Tüm `create_timer()` çağrılarına `, false`
      (process_always=false) eklendi. Requires eklenmedi (Melt reaksiyonu Fire+Slowed
      kombosu, genel). Dil bug'ı düzeltildi, TR hiç yoktu → eklendi.

- [x] Void Resonance (207) — implementasyon doğru: `_wave_reaction_types` (Primal
      Instinct ile paylaşımlı) 4 benzersiz reaksiyona ulaşınca `_void_resonance_ready
      =true`, sonraki Calamity kullanımında (`_consume_calamity()`) slot tüketilmiyor
      ve dizi hemen sıfırlanıyor (yeniden 4'e doğru birikmeye başlıyor). Primal
      Instinct'teki aynı "dalga" terminolojisi netliği uygulandı ("level-up aralığı"
      anlamında). Requires gerekmiyor. Dil bug'ı düzeltildi, TR hiç yoktu → eklendi.

**LEILA INDIVIDUALITY TAMAMLANDI (11/11 kart) — 2026-09-14**

**LEILA UTILITY LV SCALING TAMAMLANDI (16/16 kart, +4 Amp havuzdan kaldırıldı, Perfect
Catalyst Individuality'ye taşındı) — 2026-09-14**

## KRİTİK PROJE ÇAPINDA BUG FIX: `.get("fonksiyon_adı")` her zaman false dönüyordu
      (2026-09-16, Cyclone Calamity review'i sırasında Glitch Bomb'da bulundu)

GDScript'te `Object.get(prop)` sadece **property/değişken** okur — bir metod (fonksiyon)
adı verilirse metod var olsa bile her zaman `null` (yani boolean bağlamda `false`) döner.
Doğru kullanım `has_method(prop)`. Proje genelinde bu yanlış kalıp **10 yerde** kullanılmıştı,
hepsi sessizce hiçbir zaman çalışmıyordu (crash yok, sadece etkisiz):

| Dosya:Satır (eski) | Etkilenen mekanik | Durum |
|---|---|---|
| `game_scene.gd` (Glitch Bomb, 215) | 120px alana Glitch uygulama | **hiç çalışmıyordu** |
| `game_scene.gd` (Virus Rain, 217) | düşmanlara Antivirus stack | **hiç çalışmıyordu** |
| `game_scene.gd` (Decay Field, 218) | alandaki düşmanlara Decay | **hiç çalışmıyordu** |
| `base_enemy.gd:244` (Leech Nova Core, 214, Cyclone Identity) | öldürünce çevreye Glitch yayma | **hiç çalışmıyordu** |
| `base_enemy.gd:646` (`_react_electrocute`) | 100px'teki düşmanlara Electrified yayma | **hiç çalışmıyordu** |
| `base_enemy.gd:677` (Thermal Expansion, 89) | Steam reaksiyonunda genişleyen alana Wet yayma | **hiç çalışmıyordu** — daha önce (2026-09-14) "implementasyon doğru" diye onaylanmıştı, o inceleme hatalıydı |
| `base_enemy.gd:696` (`_react_cryostatic`/Shatter) | 120px'teki düşmanlara Slow yayma | **hiç çalışmıyordu** |
| `ball.gd:1196` (Steam Core, 62, Leila Identity) | buhar bulutu → 45px'teki düşmanlara Wet | **hiç çalışmıyordu** — daha önce (2026-09-01) "implementasyon doğru" diye onaylanmıştı, o inceleme hatalıydı |
| `ball.gd:2148` (Arc Core, 63, Leila Identity) | Electrified'ı 2-3 yakın düşmana yayma | **hiç çalışmıyordu** — daha önce (2026-09-01) "implementasyon doğru" diye onaylanmıştı, o inceleme hatalıydı |
| `ball.gd:2689` (Tracer Core, 212, Cyclone Identity) | iz üzerindeki düşmanı 0.5s yavaşlatma | **hiç çalışmıyordu** |

**Fix**: kullanıcı onayıyla tüm 10 yer `obj.get("apply_X")` → `obj.has_method("apply_X")`
olarak düzeltildi (proje içinde zaten doğru kullanılan, örn. `_activate_backdoor()`'daki
`has_method("apply_glitch")` deseniyle birebir aynı). Tracer Core'daki `create_timer(0.1*
(i+1))` çağrısına da aynı turda eksik olan `process_always=false` eklendi (klasik pause
bug'ı).

**ÖNEMLİ NOT**: Bu bug'ın etkilediği 3 kart (Thermal Expansion 89, Steam Core 62, Arc
Core 63) daha önceki review turlarında **yanlışlıkla "implementasyon doğru" diye
onaylanmıştı** — kod satırının kendisi (`apply_wet()`/`apply_electrified()` çağrısı) o
sırada doğru görünüyordu ama onu koruyan `if` koşulu her zaman false olduğu için pratikte
hiç tetiklenmiyordu, bu detay o incelemelerde kaçırılmıştı. **Kullanıcı bu 3 kartın (ve
diğer 7'sinin) review sürecine tekrar dönüleceğini belirtti** — bu düzeltmeler sadece
"her zaman false olan koşulu düzelt" seviyesinde, kartların denge/açıklama/requires
tarafı henüz yeniden gözden geçirilmedi.

## AKTİF SÜREÇ: Cyclone Calamity Kart-kart Full Review (2026-09-16 başladı)

Aynı 4 aşamalı süreç (implementasyon → requires → TR → EN) + sprite kontrolü, Cyclone'un
9 Calamity kartı için başladı (Cyclone Identity/Utility/Individuality zaten önceki
session'da tam review edilmişti).

- [x] **Data Storm (129)**: implementasyon doğru (Avlu'daki tüm Glitched düşmanlara 10
      hasar). `requires_any: [16, 192, 197, 214]` eklendi (Glitch Core / Glitch Pulse
      Core / Circuit Overload Core / Leech Nova Core — Glitch uygulayan kaynaklar). Dil:
      EN netleştirildi + "Glitched" bold, TR hiç yoktu → eklendi. **Yeni glossary
      keyword'leri**: "Glitched"/"Antivirus"/"Decay" `Lang.STATUS_KEYWORDS`'e eklendi
      (Cyclone'un 3 temel status efekti daha önce hiç açıklanmıyordu).
      **VFX eklendi (kullanıcı isteği, 2026-09-16)**: kullanıcı `assets/VFX/calamitys/
      dataStorm/` klasörüne 16 frame'lik (32×32, element-göstergesi boyutunda) bir
      "bozulma patlaması" sprite'ı ekledi. `_vfx_data_storm_burst(subject)` eklendi —
      her Glitched düşmanda AYRI AYRI (tek merkezi VFX değil) çalışıyor: (1) düşmanın
      üzerindeki statik glitch element-göstergesi (`_hide_debuff("glitch")`) kaldırılıp
      yerine bu animasyon (element-göstergesiyle aynı offset'te, `_elem_indicator_y_
      offset()`) tek seferlik oynatılıyor, (2) animasyon bitince hasar uygulanıyor
      (görsel olarak "hasar o an oluyor" hissi + `_react_flash`), (3) düşmanın
      `is_glitched` durumu tüketilip temizleniyor (kullanıcı: "sonra zaten glitch efekti
      silinmiş olsun"). Sprite yoksa animasyon beklemeden direkt hasar + glitch temizleme
      yapılıyor (crash yok). Açıklama buna göre güncellendi (EN/TR): "...clearing Glitch"
      / "...Glitch'leri temizlenir".
      **Ek düzeltme (kullanıcı test etti, aynı gün)**: düşman burst animasyonu oynarken
      başka bir kaynaktan ölürse VFX cesedin üzerinde oynamaya devam ediyordu — artık her
      frame `is_dead` kontrol ediliyor, ölürse animasyon anında kesiliyor (hasar da
      uygulanmıyor, zaten ölü).

- [x] **Backdoor (130)**: implementasyon doğru (Avlu'daki tüm düşmanlara 3sn Glitch).
      Requires gerekmiyor (Glitch'in kendi kaynağı, kendi kendine yeten). Dil: EN
      netleştirildi ("becomes Glitched" + bold), TR hiç yoktu → eklendi. **Sprite
      kontrolü**: kart art'ı mevcut (`backdoor_art.png`), oyun içi VFX sadece genel ekran
      flaşı — özel sprite yok (aşağıdaki VFX turunda gerçek sprite'a bağlandı).
      **VFX eklendi — "The Yard Engine" (kullanıcı isteği, 2026-09-16)**: kullanıcı
      `assets/VFX/theYardEngine/starting/` (16 frame, 128×128 — cihaz yerden yükselip
      beliriyor) ve `.../ending/` (16 frame — cihaz tekrar yere gömülüp kayboluyor, aynı
      frame'lerin tersten sırası) klasörlerini ekledi. `_vfx_backdoor_engine()` eklendi:
      1. Sahanın merkezinde (`Vector2(1152, 667)`, Yard merkezi — Freezing Cold'un
         yörüngesinde de kullanılan aynı nokta) "start" animasyonu (12fps, non-loop)
         oynatılıyor.
      2. **Son 2 frame'de** (`frame_changed` sinyaliyle, `frame >= start_frame_count-2`
         kontrolü, sadece bir kez tetikleniyor) sahadaki (x≥385) tüm düşmanlara cihazdan
         zigzag elektrik çizgileri (`_vfx_backdoor_bolt()`, mor `Line2D`, hızlı fade)
         gönderiliyor — **kartın gerçek vaadi (Glitch uygulama) TAM BU ANDA** tetikleniyor,
         çizgi görselle senkron.
      3. "start" bitince "end" animasyonu oynatılıp (aynı SpriteFrames kaynağı, ikinci
         animasyon olarak eklendi) bitince `queue_free()`.
      Eski davranış (anında Glitch + ekran flaşı) sprite yoksa fallback olarak korundu
      (crash yok). Bu, Data Storm'dan farklı bir desen: "merkezi cihaz + çizgilerle
      dağıtılan debuff" — ileride benzer "alan geneli" Calamity'lerde (Systemic Failure,
      Virus Rain gibi) referans alınabilir.
      **BUG FIX (kullanıcı fark etti, aynı gün)**: hedef filtresi sadece `x >= 385.0`
      kontrol ediyordu, Avlu'nun **y ekseni** sınırını (255-1080) hiç bakmıyordu — üst/alt
      bölgedeki (spawn/tribün alanı) düşmanlar da yanlışlıkla etkileniyordu. Artık tam
      dikdörtgen kontrolü var: `x:385-1920, y:255-1080` dışındaki hiçbir düşman bolt/
      Glitch almıyor.

- [x] **Bounce Barrage (138)**: implementasyon doğru — `player.gd`'nin `core_speed_mult`
      zincirine bağlı (2026-08-29'daki Core Speed mimarisi düzeltmesi üzerinden gerçekten
      top hızını ×3 yapıyor), 5sn. Requires gerekmiyor (Core Speed her build'de anlamlı).
      Dil: EN zaten temizdi, TR hiç yoktu → eklendi. Sprite kontrolü: kart art'ı mevcut
      (`bounce_barrage_art.png`), özel VFX yoktu.
      **VFX eklendi (kullanıcı isteği, aynı gün)**: ekran flaşı kaldırıldı, yerine
      `ball_launcher.gd`'ye `electrify_weapon(duration)` eklendi — Cyclone'un silah
      sprite'ına (`_cyclone_weapon_anim`) süre boyunca sürekli mavi-cyan kıvılcım
      parçacıkları (`CPUParticles2D`, silaha child olarak bağlı — silahın pozisyon
      takibiyle otomatik hareket ediyor) + pulse eden modulate (beyaz↔cyan, loop tween)
      uygulanıyor, süre bitince `_stop_electrify_weapon()` ile temizleniyor.
      **Ek VFX (kullanıcı isteği, aynı gün)**: aktivasyon anında bir kez çalışan enerji
      patlaması eklendi — `assets/VFX/calamitys/bounceBarrage/` (8 frame, 168×168),
      `ball_launcher.gd::play_weapon_burst()` silahın üzerinde tek seferlik oynatıp
      (14fps, non-loop) bitince kendini siliyor. Süre boyunca sürekli çalışan elektrik
      efektinden (kıvılcım parçacıkları + speed_scale×3) ayrı, sadece aktivasyon anına
      özel bir "patlama" hissi.

- [x] **Mirror Image (144) — AÇIKLAMA DÜZELTMESİ (kullanıcı kararı, 2026-09-17)**: kod
      incelemesinde bir tasarım/açıklama uyuşmazlığı bulundu — `add_to_orbit(ball)`,
      `is_normal_core=true` olan topları GERÇEK yörüngeye (`inner_orbit_balls`) değil,
      oyuncunun normal top rezervine (`orbit_balls`, magazine) ekliyor. Yani kart aslında
      "sürekli oyuncunun etrafında dönen 2 kalıcı hayalet top" değil, **+2 bonus mermi**
      veriyor (auto-mode'da hemen ateşleniyor, manuel modda sıradaki atışlarda kullanılıyor,
      25sn içinde kullanılmazsa zorla kaldırılıyor). Kullanıcı kararı: **mekanik doğru
      kabul edildi, sadece açıklama gerçeğe göre düzeltildi** — "Spawn 2 phantom cores
      for 25s" → "Grants 2 bonus cores. Unused ones vanish after 25s" / TR: "2 bonus core
      kazandırır. Kullanılmayanlar 25sn sonra kaybolur". Requires gerekmiyor (kendi
      kendine yeten). Sprite kontrolü: kart art'ı mevcut (`mirror_image_art.png`), özel
      VFX yok.
      **Spawn görseli düzeltmesi (kullanıcı isteği, 2026-09-18)**: kullanıcı bonus
      core'ların sağ üst köşedeki `$BallLauncher`'dan (`Vector2(1539, 317)`) çıkmasını
      istedi. İlk denemede sadece spawn pozisyonu launcher'a çekildi ama hiçbir görsel
      fark olmadı — sebebi `player.gd::_physics_process`'in HER FRAME `orbit_balls`
      (reserve/magazine kuyruğu) içindeki tüm topları oyuncunun silah pozisyonuna
      sabitlemesi (`orbit_balls[i].global_position = global_position + _weapon_offset`),
      yani launcher'a verilen spawn konumu bir sonraki fizik frame'inde anında eziliyordu.
      **Fix**: gerçek core'lar (reserve mekaniği, önceki gibi oyuncu pozisyonunda
      görünmez şekilde kuyruğa giriyor) hiç değiştirilmedi — bunun yerine
      `_vfx_mirror_image_travel()` adında SADECE görsel/kozmetik bir efekt eklendi: küçük
      camgöbeği bir "core" launcher'dan oyuncuya doğru uçup (0.4sn, `tween_method` ile
      canlı takip — oyuncu hareket etse bile hedefi güncelliyor) sonda hızla soluyor. 2
      core için hafif gecikmeli (0.12sn arayla) iki kez tetikleniyor.

### İlerleme — Leila Calamity (8 kart, index sırasına göre) — sprite kontrolü de dahil
- [x] Lightning (7) — implementasyon doğru: tıklanan noktaya 100px yarıçapta 3 hasar +
      Electrified uyguluyor (`_activate_lightning()`), VFX elle çizilmiş zigzag `Line2D`
      (gerçek sprite değil, ama kart art'ı mevcut: `lightning_art.png`). Requires
      gerekmiyor. Açıklama netleştirildi (eskiden hasar/etki hiç belirtilmiyordu), TR
      zaten vardı ama aynı şekilde netleştirildi. **Sprite kontrolü**: kart art dosyası
      mevcut (`assets/upgradeCardsArt/Leila/calamityCards/lightning_art.png`), AMA
      oyun içi VFX'in kendisi eski usul elle çizimdi (zigzag `Line2D` + `draw_arc`
      halka), gerçek sprite yoktu. Kullanıcı Pixellab prompt'u istedi, üretildi
      (`assets/VFX/calamitys/lightning/frame_000-004.png`, 5 frame), `_vfx_lightning()`
      artık `AnimatedSprite2D` ile bu sprite'ı oynatıyor (16fps, tek seferlik, `animation_
      finished`'da otomatik siliniyor) — eski elle-çizim kod `_vfx_lightning_fallback()`'e
      taşındı, sprite eksikse ona düşüyor (crash yok, WormHole'daki desenle aynı).

      **DEBUG override güncellendi**: eski Vector test bloğu ("🏚️ Rampart Collapse + 🔓
      Full Breach") kaldırıldı, yerine `calamity_slots.clear()` + 3 slotun hepsine
      "⚡" (Lightning) eklendi — Leila Calamity review'i süresince, her kartın sprite'ı
      hazırlandıkça bu debug bloğu o kartın emoji'siyle güncellenecek. **Test bitince
      bu blok kaldırılmalı**, kalıcı build'e sızmamalı.

      **Evde test sonrası 2 ek düzeltme (kullanıcı kararı, aynı gün)**: (1) düşman
      üzerinde hiç görsel geri bildirim yoktu ("hasar gerçekten işliyor mu belli değil")
      → `_react_flash(Color(1.0, 1.0, 0.6, 1.0))` (sarı-beyaz) eklendi, isabet alan her
      düşman artık kısaca renk değiştiriyor. (2) hasar kullanıcıya çok düşük geldi →
      önce 3'ten 8'e, sonra düşman HP değerleri karşılaştırılıp (subject 15, heavy_
      subject/boss 45) **13**'e çıkarıldı — standart subject'i 2, heavy/boss'u 4
      vuruşta öldürüyor artık. Açıklamalar (EN/TR) güncellendi.

### YENİ ÖZELLİK: Karaktere özel Calamity nişan sprite'ı (2026-09-15)
Kullanıcı `assets/charsRedesign/<char>/<char>CalamityAim.png` altında zaten Vector/
Cyclone için hazır ama **hiç koda bağlanmamış** sprite'lar olduğunu fark etti, Leila'nınkini
de ekledi (`leilaCalamityAim.png`). Nişan alırken (`calamity_aiming=true`) gösterilen eski
görsel `$UI/CalamityCircle` (`calamity_circle.gd`) idi — mouse pozisyonunda, Calamity'ye
göre renk/yarıçap değişen yarı saydam bir `draw_circle`/`draw_arc` daireydi.

**Yapılan**: `calamity_circle.gd`'ye `aim_texture: Texture2D` eklendi — `_draw()` artık
`aim_texture` set edilmişse (merkeze göre) sprite'ı çiziyor, yoksa eski daireye düşüyor
(fallback, crash yok). `game_scene.gd::_ready()`'de karaktere göre `res://assets/
charsRedesign/%s/%sCalamityAim.png` yolu `ResourceLoader.exists()` ile kontrol edilip
`$UI/CalamityCircle.aim_texture`'a yükleniyor. Dispatch bloğundaki (`_process`, ~4404-4444)
her Calamity'ye özel `.color`/`.radius` atamaları **komple kaldırıldı** (kullanıcı: "daire
kalkacak, sadece bu kullanılacak") — sadece `.visible`/`.position` (hedefsiz Calamity'ler
için gizleme, WormHole için player-önü sabit konum) korundu. Konum zaten mouse imlecinde
(`mouse_pos`), kullanıcının istediği gibi.

**YAPILACAK**: Vector/Cyclone'un aim sprite'ları da artık otomatik aktif olacak (aynı
mekanizma, dosyalar zaten mevcuttu) — ikisi de evde/oyunda görsel olarak doğrulanmalı.

**Ölçekleme eklendi (aynı gün, kullanıcı "aşırı küçük" dedi — 2 iterasyon)**:
1. İlk deneme: sabit "100px taban = ×1.0" oranı kullanıldı — yetersiz kaldı, çünkü
   `leilaCalamityAim.png`'nin ham piksel boyutu sadece **16×16** — sabit oran bu küçük
   taban boyutu hesaba katmıyordu (Python/PIL ile doğrulandı).
2. **Düzeltme**: ölçek artık `_aim_tex.get_size().x` (gerçek texture piksel genişliği)
   okunarak dinamik hesaplanıyor: `scale = (yarıçap × 2) / texture_genişliği` — yani
   hedef çap ne olursa olsun sprite tam o çapı kaplayacak şekilde büyütülüyor, texture
   küçük/büyük farketmiyor. Gerçek yarıçaplar kod içinden doğrulandı: Lightning 100px,
   Flame Zone 120px, Gravitational Force 150px, Volcanic Rift 180px, Glitch Bomb 120px,
   Decay Field 100px, Rampart Collapse 130px, WormHole 70px; Siege Rain 170px (tek nokta
   değil, ±120px'lik sapma/scatter alanını temsil ediyor).
3. **2 küçük düzeltme daha (kullanıcı: "biraz küçültelim, pikseller dağılmış/blur")**:
   (a) ölçeğe `× 0.75` çarpanı eklendi (biraz daha küçük), (b) `texture_filter =
   CanvasItem.TEXTURE_FILTER_NEAREST` set edildi — 16×16'lık pixel-art sprite ~12× büyütülünce
   varsayılan linear filtreleme bulanıklaştırıyordu, nearest ile artık keskin pikseller
   korunuyor (WormHole/Lightning VFX'lerinde zaten kullanılan aynı desen).

### YENİ ÖZELLİK: Düşman HP etiketi (2026-09-15, test kolaylığı için)
Kullanıcı hasarın gerçekten işleyip işlemediğini göremiyordu (düşmanlarda hiç HP
göstergesi yoktu). `base_enemy.gd`'ye her düşmanın üzerinde (`-20, -82` — debuff
ikonlarının biraz üstünde) sürekli güncellenen bir `Label` eklendi (`_hp_label`,
"health/max_health" formatında), `_physics_process`'te her frame `_update_hp_label()`
ile tazeleniyor (ölü veya ally grubundaysa gizleniyor). Kalıcı bir HUD özelliği olarak
bırakıldı, sadece debug değil — geliştirme sürecinde faydalı, kaldırılması gerekmiyor.

- [x] **Flame Zone (8) — 2 BUG FIX (kullanıcı kararı, 2026-09-15)**: `_activate_flame()`
      120px'lik alana 3sn boyunca 6 tick (0.5sn arayla) hasar veriyor, ilk tick'te
      Burning da uyguluyor (zaten yanmıyorsa).
      **Bug 1 (Siege Rain/Melt Spiral'daki AYNI pause bug'ı)**: `create_timer(0.5)`
      çağrıları `process_always=false` içermiyordu — düzeltildi (`, false` eklendi).
      **Bug 2 (hasar çok düşüktü)**: tick başına 1 hasar (toplam 6 direkt + ~6 burn DOT
      = ~12) — düşman HP değerleriyle (subject 15, heavy/boss 45) karşılaştırılıp tick
      başına **4**'e çıkarıldı (toplam 24 direkt + ~6 burn DOT = ~30, 3 saniyeye yayılı).
      Ayrıca her tick'te hit-flash eklendi (`_react_flash`, turuncu). Requires gerekmiyor.
      Açıklama netleştirildi (eskiden hiçbir sayı yazmıyordu), TR zaten vardı ama aynı
      şekilde netleştirildi. **Sprite kontrolü**: kart art'ı mevcut (`flame_zone_art.png`),
      oyun içi VFX (`_vfx_flame()`) tamamen procedural (draw_arc zemin halkası +
      CPUParticles2D alev parçacığı), gerçek sprite yok — henüz Pixellab prompt'u
      istenmedi, sıradaki adımda sorulabilir.
      **VFX sprite'a bağlandı (aynı gün)**: kullanıcı `assets/VFX/calamitys/flameZone/`
      klasörüne 9 frame'lik loop animasyon ekledi. `_vfx_flame()` artık `AnimatedSprite2D`
      ile bu sprite'ı oynatıyor (10fps, loop, 168×168px — 120px yarıçapa yakın, ek
      ölçekleme gerekmedi). Kullanıcı isteğiyle: 3sn'lik aktif süre bitince animasyon
      son frame'de duruyor (`fire.stop()` + son frame'e sabitleme), 2sn öylece kalıp
      sonra 1sn'de fade-out ile kayboluyor (Siege Rain'in "kalıcı iz" desenine benzer).
      Eski elle-çizim kod (`draw_arc` halka + `CPUParticles2D`) `_vfx_flame_fallback()`'e
      taşındı, sprite eksikse ona düşüyor (o fallback'in kendi `create_timer()` çağrılarına
      da fırsat bu fırsattı diye `process_always=false` eklendi).
      **z_index bug fix (kullanıcı fark etti, aynı gün)**: `fire.z_index=3` idi — temel
      düşmanlarla (2) eşit değil ÜSTÜNDE, boss'larla (3, cyber_404/s_miler_79/nyx_09)
      eşit — bu yüzden düşmanlar alevin altında/arkasında kalıyordu. Hem sprite hem
      fallback'teki (`ground`/`particles`) tüm z_index'ler **1**'e çekildi (WormHole
      vortex'teki aynı desen — "düşmanların z_index 2-3'ünün altında kalsın").
      **Loop'tan tek-seferlik animasyona geçildi (aynı gün, kullanıcı isteği)**: kullanıcı
      "loop'suz, temiz görünüm" istedi — 3sn × 12fps = 36 frame önerildi, kullanıcı
      `flameZone/` klasörünü 36 (gerçekte frame_000-036, 37 dosya) frame ile güncelledi.
      Kod `sf.set_animation_speed("burn", 12.0)` + `set_animation_loop("burn", false)`
      olarak değiştirildi, `fire.animation_finished` sinyali beklenip (artık elle son
      frame'e sabitleme gerekmiyor — Godot non-loop animasyonu zaten son frame'de
      otomatik duruyor) sonra 2sn bekleyip 1sn'de fade-out ile kayboluyor.
      **Etki alanı/görsel boyut uyuşmazlığı (aynı gün, kullanıcı fark etti)**: hasar
      yarıçapı (120px) sprite'ın gerçek görsel boyutundan (168px sprite → 84px yarıçap)
      büyüktü — oyuncu görmediği bir alanda hasar alabiliyordu. Kullanıcı kararıyla
      **hasar alanı görsele göre küçültüldü** (120→84px, büyütme yerine) —
      `_activate_flame()`'deki mesafe kontrolü + `_vfx_flame()`'in `radius` değişkeni +
      nişan sprite ölçeklemesindeki (🔥) `_aim_radius` hepsi 84'e çekildi, üçü senkron.
      **z_index ikinci düzeltme (aynı gün, kullanıcı fark etti)**: FlameZone içinde ölen
      düşmanların cesetleri (`is_dead=true` olunca `z_index=0`, base_enemy.gd:246) hâlâ
      alevin (z_index=1) altında kalıyordu. Siege Rain'in kraterindeki aynı çözüm
      uygulandı: hem sprite hem fallback'teki tüm katmanlar **z_index=-1**'e çekildi —
      artık hem canlı düşmanların (2-3) HEM cesetlerin (0) altında kalıyor.

- [x] Blizzard (94) — implementasyon doğru: `_activate_blizzard()` Yard'daki (x≥385) zaten
      Wet olan tüm düşmanları anında Frozen yapıyor, açıklamayla birebir eşleşiyor.
      **Eksik**: `requires` yoktu — Wet uygulayan hiçbir core olmadan tamamen faydasız
      (hiçbir düşman Wet olamaz) → `requires_any: [17, 62, 65, 185]` eklendi (Hydro/
      Steam/Prism/Mist Core). Dil bug'ı (EN alanı Türkçe yazılmıştı) düzeltildi, TR hiç
      yoktu → eklendi, "Wet"/"Frozen" keyword'leri bold yapıldı (glossary'e bağlandı).
      **Sprite kontrolü**: kart art'ı mevcut (`blizzard_art.png`), oyun içi VFX sadece
      genel ekran flaşı (`_react_flash_screen`) — özel bir sprite/animasyon yok. Ayrıca
      eski "bilinen sorun" listesindeki freeze VFX çakışma endişesi yanlış alarmmış
      (bkz. yukarıdaki düzeltme), kontrol edildi.
      **YENİDEN TASARIM (kullanıcı kararı, 2026-09-15): "Blizzard" → "Freezing Cold"**:
      - İsim değişti (`upgrades` dizisi, `_CALAMITY_DISPLAY_NAMES`, pickup handler yorumu,
        fonksiyon adı `_activate_blizzard()` → `_activate_freezing_cold()`, çağrı noktası
        güncellendi). Emoji ("❄️") değişmedi.
      - **Yeni mekanik eklendi**: eskiden sadece Wet düşmanları donduruyordu, artık
        **Wet OLMAYAN düşmanlara da Slowed uygulanıyor** (`apply_slow(0.4, 3.0)`,
        zaten Slowed değilse). Açıklama: "Wet enemies become Frozen instantly. Other
        enemies are Slowed" / TR eşleniği.
      - **Kart art dosyası yeniden adlandırıldı**: `blizzard_art.png` → `freezing_cold_
        art.png` (+ `.import` dosyasının içindeki `source_file` referansı da düzeltildi)
        — art yolu kart adından otomatik türetiliyor (`name.to_lower().replace(" ","_")
        + "_art.png"`, satır 2813), isim değişince dosya adı da değişmek zorundaydı.
      - **Yeni VFX**: kullanıcı `assets/VFX/calamitys/freezingCold/` klasörüne 9 frame
        (256×256) ekledi, "ekranın üstünden hızla girip her yeri gezip ekrandan çıkacak"
        tarif etti — önceki nokta-merkezli Calamity VFX'lerinden farklı olarak
        `_vfx_freezing_cold()` TAM EKRAN diyagonal bir geçiş: `top_level=true` bir
        `AnimatedSprite2D` (×3.5 ölçek, 12fps loop), ekran dışı sol-üstten
        (-500,-500) başlayıp 1.3sn'de ekran dışı sağ-alta (2420,1580) tween ile
        süzülüp `queue_free()` oluyor. Sprite yoksa fonksiyon sessizce hiçbir şey
        yapmıyor (crash yok, `ResourceLoader.exists()` guard'ı).
      **`.import` dosyası doğrulandı**: Godot editörü açılınca otomatik yeniden import
      etti (`source_file`/`path` artık `freezing_cold_art.png`'e işaret ediyor, kullanıcı
      tarafında doğrulandı).

      **VFX 2. iterasyon — komple yeniden tasarlandı (aynı gün, kullanıcı isteği)**:
      İlk versiyon (ekran dışından diyagonal geçiş, 1.3sn) "çok hızlı" ve "çok kocaman"
      bulundu. Yeni tasarım:
      1. **Spawn noktası**: `$BallLauncher` (sahnede player'a değil ROOT'a bağlı, sabit
         bir node — `game_scene.tscn:3671`, konumu `(1539, 317)`, ekranın sağ üst
         köşesine denk geliyor) — kullanıcının "sahanın BallLauncher'ı" dediği şey bu.
      2. **Büyüme**: o noktada scale 0 → 1.6 (TRANS_BACK/EASE_OUT, 0.5sn) — "küçükten
         büyüğe doğru büyüsün".
      3. **Yörünge**: Yard merkezi `(1152, 667)` etrafında 480px yarıçapla **4 tam tur**
         dönüyor (`tween_method` ile açı parametrize edilip `TAU × 4` boyunca
         hesaplanıyor) — "sahayı dört dönsün".
      4. **Rüzgar efekti**: storm ile birlikte hareket eden ayrı bir `CPUParticles2D`
         (`wind`) eklendi — yörünge boyunca teğetsel yönde (hareket yönüne dik açı)
         parçacık üflüyor, fırtına hissi veriyor.
      5. **Kayboluş**: 4 tur bitince scale 1.6 → 0 + alpha fade (TRANS_BACK/EASE_IN,
         0.4sn), hem storm hem wind `queue_free()`.

      **3. iterasyon — komple yeniden tasarlandı (aynı gün, kullanıcı Paint ile rota
      çizdi)**: dairesel yörünge hem "çok hızlı" hem istenen görünümle uyuşmuyordu.
      Kullanıcı zigzag bir rota çizip tarif etti + **mekanik de değişti**:
      - **Yeni rota**: `waypoints` dizisi — spawn (BallLauncher, sağ üst) → (450,550) →
        (750,950) → (1150,300) → (1000,1080) → (950,1400, ekran dışı çıkış). Her segment
        `travel_speed=300px/s`'e göre süre alıyor (mesafe/hız), `tween_method` ile
        `from.lerp(to, t)` interpolasyonu — "aşırı hızlı olmasın" isteğiyle önceki 4-tur/
        4sn'lik daireden belirgin şekilde yavaşlatıldı.
      - **Mekanik artık "yoldaki düşmanlara" özel**: eskiden `_activate_freezing_cold()`
        aktivasyon anında TÜM Yard'daki düşmanlara aynı anda etki uyguluyordu. Artık
        `_freezing_cold_tick(pos)` adında ayrı bir fonksiyon var — hortumun VFX'i her
        segment boyunca hareket ederken (`tween_method` callback'i içinde) o anki
        konumuna 140px'ten yakın düşmanlara etki uyguluyor (Wet→Frozen, değilse→Slowed).
        `_activate_freezing_cold()` artık sadece ekran flaşı + VFX çağrısından ibaret,
        gerçek etki VFX'in hareketine bağlı hale geldi.
      - Rüzgar parçacıklarının yönü artık hareket segmentinin TERS yönünü gösteriyor
        (`wind.direction = -seg_dir`) — gerçek bir "arkadan üfleyen fırtına" hissi.
      - Açıklama buna göre güncellendi: "A blizzard sweeps across the Yard. Wet enemies
        in its path become Frozen, others are Slowed" / TR eşleniği.

      **4. ince ayar (aynı gün, kullanıcı isteği)**: `travel_speed` 300→380→**450px/s**
        (iki kez hızlandırıldı). **Kural**: rota değişebilir ama çıkış noktası HER ZAMAN
        **North** (yukarı, ekran dışı negatif y) olmalı — son waypoint `y=-300` yapıldı
        (önceden South/aşağı çıkıyordu).

      **5. Rastgele rota (aynı gün, kullanıcı isteği)**: sabit zigzag noktaları yerine
        artık her aktivasyonda 3 rastgele ara nokta üretiliyor (`randf_range(450-1850,
        300-1050)`, Yard sınırları içinde) — çıkış noktası kuralı korunuyor, son waypoint
        her zaman `y=-300` (North) ama `x` de rastgele (`450-1850`) seçiliyor. Spawn
        noktası hâlâ sabit (BallLauncher).

      **6. Bölge garantisi (aynı gün, kullanıcı test etti — "sadece sağ tarafta
        gezindi, can sıkıcı")**: tamamen bağımsız rastgele noktalar bazen şans
        eseri hep aynı bölgede kümelenebiliyordu. Yard'ın genişliği 3 dilime bölündü
        (`450-900`, `900-1400`, `1400-1850`), sıra karıştırılıp (`shuffle()`) HER
        dilimden tam olarak 1 ara nokta alınıyor — artık sahanın gerçekten her
        yerinde (sol/orta/sağ) gezinmesi garanti, sadece ziyaret sırası rastgele.

- [x] **Monsoon (95) — 2 BUG FIX (2026-09-16)**: `_activate_monsoon()` Yard'daki (x≥385)
      tüm düşmanlara Wet uyguluyor, açıklamayla birebir eşleşiyor. Requires gerekmiyor
      (Wet uygulamanın kendisi bu kart — kendi kaynağı). **Sprite kontrolü**: Monsoon'un
      ZATEN gerçek sprite VFX'i var (`assets/VFX/monsoonVFX/rain_drops-01..04.png`, 4
      frame, tüm sahayı kaplıyor) — sprite eksikliği yok.
      **Bug 1**: `_CALAMITY_DISPLAY_NAMES["🌊"]` = "Calamity Flood" yazıyordu ama "🌊"
      gerçekte Monsoon'un kendi emoji'si (dispatch + pickup handler ikisi de "🌊"
      kullanıyor) — "Flood" diye bir Calamity hiç yok, tooltip yanlış isim gösteriyordu.
      "Calamity Monsoon" olarak düzeltildi.
      **Bug 2 (hayalet Calamity, Gravitational Force'un "🔮"siyle aynı desen)**: run
      başında mağazadan verilen rastgele Calamity havuzunda (`_cal_pool`, satır 1145)
      **"💧"** vardı — bu emoji hiçbir elif dispatch dalında yok, hiçbir pickup handler'ı
      yok, tamamen erişilemez/işlevsiz bir emoji. Şans eseri bir oyuncuya run başında
      verilirse o slot tamamen ölü kalıyordu. "💧" → "🌊" (gerçek Monsoon) ile değiştirildi.
      Dil: EN zaten temizdi, TR hiç yoktu → eklendi, "Wet" keyword'ü bold yapıldı.

- [x] **EMP Pulse (96) — BUG FIX (2026-09-16)**: `_activate_emp()` Yard'daki (x≥385) tüm
      Electrified düşmanlara 15 hasar veriyor, açıklamayla birebir eşleşiyor. **Bug**:
      `_CALAMITY_DISPLAY_NAMES["🔋"]` = "Calamity **Battery**" yazıyordu — "EMP Pulse"
      olması gerekirken (Monsoon'daki "Flood" bug'ıyla aynı desen) → düzeltildi.
      **Eksik**: `requires` yoktu, Electrified uygulayan hiçbir core olmadan tamamen
      faydasız → `requires_any: [1, 61, 63, 87]` eklendi (Electric/Plasma/Arc/Voltaic
      Core). Ayrıca isabet alan düşmanlara hiç görsel geri bildirim yoktu, hit-flash
      eklendi (`_react_flash`, mavi). **Sprite kontrolü**: kart art'ı mevcut
      (`emp_pulse_art.png`), oyun içi VFX sadece genel ekran flaşı — özel sprite yok.
      Dil: EN zaten temizdi, TR hiç yoktu → eklendi, "Electrified" keyword'ü bold yapıldı.
      **VFX paylaşımı (kullanıcı isteği, aynı gün)**: `_vfx_lightning()` refactor edildi
      — şimşek sprite'ının kendisi (ekran flaşı hariç) `_vfx_lightning_bolt(pos)` adında
      ayrı bir fonksiyona çıkarıldı (Lightning kartı hâlâ flaş+bolt ikisini birden
      çağırıyor, davranışı değişmedi). `_activate_emp()` artık isabet alan HER Electrified
      düşmanın üzerinde aynı anda bu şimşek sprite'ını (`assets/VFX/calamitys/lightning/`)
      oynatıyor — birden fazla düşman aynı anda vurulursa hepsinde ayrı ayrı görünüyor.
      **Ekran sallanma efekti eklendi (kullanıcı isteği, aynı gün)**: zaten var olan
      hazır `_screen_shake_small()` fonksiyonu çağrıldı (3× ufak rastgele offset, 0.04sn
      aralıklarla) — `screen_shake_heavy()`'nin (Full Breach/Rampart Collapse'de
      kullanılan) hafif versiyonu, tekrar yazmaya gerek kalmadı.

- [x] **Volcanic Rift (97) — BUG FIX (kullanıcı kararı, 2026-09-16)**: `_activate_
      volcanic_rift()` 180px'lik alana 4sn boyunca 0.5sn arayla (8 tick) 2 hasar + ilk
      tick'te Burning uyguluyor (`is_burning` guard'ı sonraki tick'lerde tekrar
      tetiklemiyor — eski "Bilinen sorunlar" listesindeki soru işareti çözüldü, bug
      değil, bilinçli tasarım). **Bug (Siege Rain/Flame Zone/Melt Spiral'daki AYNI pause
      bug'ı)**: `create_timer(0.5)` `process_always=false` içermiyordu → düzeltildi.
      Ayrıca her tick'te hit-flash eklendi (`_react_flash`, turuncu). Requires gerekmiyor
      (kendi kendine yeten, element core'a bağlı değil). Açıklama netleştirildi (eskiden
      "leaves lava trail" diyordu, hasar/süre/etki hiç yazmıyordu). Dil: EN düzeltildi,
      TR hiç yoktu → eklendi, "Burning" keyword'ü bold yapıldı.
      **VFX sprite'a bağlandı (aynı gün)**: kullanıcı `assets/VFX/calamitys/volcanicRift/`
      klasörüne 44 frame'lik tek seferlik erüpsiyon animasyonu ekledi. `_vfx_volcanic_
      rift()` eklendi — `AnimatedSprite2D`, 11fps (44÷11=4sn, hasar süresiyle birebir
      eşleşiyor), non-loop, z_index=-1 (canlı düşmanların 2-3 VE cesetlerin 0 altında).
      Sprite yoksa fonksiyon sessizce hiçbir şey yapmıyor (crash yok, `ResourceLoader.
      exists()` guard'ı, sadece ekran flaşı kalır).
      **Etki alanı/görsel boyut uyuşmazlığı (Flame Zone'daki AYNI sorun)**: sprite'ın
      gerçek boyutu 168×168px (~84px görsel yarıçap) ama hasar yarıçapı 180px'ti —
      kullanıcı kararıyla **hasar alanı görsele göre küçültüldü** (180→84px) —
      `_activate_volcanic_rift()`'teki mesafe kontrolü + nişan sprite ölçeklemesindeki
      (🌋) `_aim_radius` ikisi de 84'e çekildi, senkron.
      **Kenar düzeltme (aynı gün, kullanıcı isteği)**: sprite'ın sol-üst ve sağ-alt
      köşeleri çok düz/kesintisiz duruyordu ("kesik kesik olsun" istendi). Python/PIL +
      scipy ile 44 frame'in TAMAMINA, sadece bu iki köşeye (bounding box köşelerine
      gaussian falloff'lu yakınlık ağırlığı, ~55px yarıçap) odaklanan bir alpha-erozyon
      efekti uygulandı — `distance_transform_edt` ile kenara uzaklık hesaplanıp, düşük
      frekanslı smooth noise'a göre rastgele "ısırık" alınarak kesikli/çentikli bir kenar
      oluşturuldu (diğer kenarlara dokunulmadı, sadece mevcut alandan aşındırma yapıldı —
      yeni renk/alan sentezlemedi, güvenli). Orijinal frame'ler `assets/VFX/calamitys/
      volcanicRift/_original_backup/` altında saklı (2 iterasyon oldu — ilk deneme tüm
      kenarları etkiledi, kullanıcı "sadece iki uç" deyince backup'tan restore edilip
      köşe-ağırlıklı versiyon yeniden uygulandı).
      **Görsel giriş/çıkış iterasyonları (aynı gün, kullanıcı isteği)**: önce `scale=0`'dan
      büyüyüp (TRANS_BACK/EASE_OUT) süre bitince küçülen bir versiyon denendi, TRANS_BACK'in
      "sekme/overshoot" hissi kullanıcıya "zıplama gibi" geldi → TRANS_SINE'a çekildi
      (düz büyüme/küçülme). Sonra küçülmenin animasyon TAMAMEN bittikten sonra aniden
      başlaması ("son framede aniden küçülme") istenmedi → son 3, sonra son 10 frame'lik
      süreye yayılıp animasyon oynarken paralel başlayacak şekilde değiştirildi. **Son
      karar**: kullanıcı scale animasyonunu (büyüme + küçülme) komple kaldırdı — sprite
      artık sabit boyutta oynuyor, animasyon bitince `animation_finished` sinyaliyle
      direkt `queue_free()` (kalıntı yok, scale tween'i de yok).
      **Ekran flaşı kaldırıldı**: `_activate_volcanic_rift()`'teki `_react_flash_screen()`
      çağrısı silindi (sprite VFX'i zaten yeterli görsel geri bildirim veriyor) — düşman
      isabet flaşı (`_react_flash`, turuncu) korundu, o ayrı bir şey.
      **Kenar düzeltmesi geri alındı**: kullanıcı kendi yeni bir sprite ayarladığı için
      Python/PIL köşe-erozyon işlemi artık geçersiz, `_original_backup/` klasörü de
      kullanıcının yeni sprite'ı koyarken silinmiş — geriye dönük bir iz kalmadı.

**VOLCANIC RIFT (97) TAMAMLANDI — 2026-09-16**

- [x] **Thunderstorm (98) — 2 BUG FIX (2026-09-16)**: `_activate_thunderstorm()` 5sn
      boyunca her saniye rastgele 3 düşmana 5 hasar + Electrified uyguluyor, her isabette
      Lightning'in gerçek sprite VFX'ini (`_vfx_lightning()`) tekrar kullanıyor — sprite
      eksikliği yok (paylaşımlı). **Bug 1 (Siege Rain/Flame Zone/Melt Spiral/Volcanic
      Rift'teki AYNI pause bug'ı)**: `create_timer(1.0)` `process_always=false`
      içermiyordu → düzeltildi. **Bug 2 (display name drift, Monsoon/EMP Pulse'daki AYNI
      desen)**: `_CALAMITY_DISPLAY_NAMES["⛈️"]` = "Calamity **Storm**" yazıyordu —
      "Thunderstorm" olması gerekirken → düzeltildi. Ayrıca isabet alan düşmanlara hiç
      hit-flash yoktu (diğer tüm Calamity'lerde var), eklendi (`_react_flash`, sarı-beyaz).
      Requires gerekmiyor (Electrified uygulamanın kendisi bu kart). Açıklama netleştirildi
      (eskiden "Random lightning strikes for 5s" diyordu, hasar/hedef sayısı hiç
      yazmıyordu), TR hiç yoktu → eklendi, "Electrified" keyword'ü bold yapıldı.
      `_CALAMITY_TARGETED` listesinde değil — doğru (mouse pozisyonuna bakmıyor, tamamen
      rastgele hedefli).
      **Dengeleme (kullanıcı kararı, aynı gün)**: saniyede vurulan hedef sayısı 3 → **2**'ye
      düşürüldü (`mini(3, ...)` → `mini(2, ...)`) — 5sn'de toplam en fazla 10 vuruş × 5
      hasar = 50 hasar potansiyeli (eskiden 15×5=75'ti). Açıklamalar (EN/TR) buna göre
      güncellendi.
      **BUG FIX (Avlu sınırı eksikti, kullanıcı fark etti)**: diğer tüm Calamity'ler hedef
      seçerken `x >= 385.0` (Avlu sınırı) kontrolü yaparken Thunderstorm bunu hiç
      yapmıyordu — sahadaki TÜM "subjects" grubundan rastgele seçiyordu, Avlu dışındaki
      (henüz spawn/sınır dışı) düşmanları da vurabiliyordu. Hedef listesi artık
      `s.global_position.x >= 385.0` ile filtrelendikten sonra karıştırılıyor.

### Connected Core ortak mekaniği: "dart-strike" (2026-09-09, kullanıcı hatırlattı)
Prism Core incelenirken kullanıcı "yakındaki düşmana vurma olayı da vardı" diye hatırlattı
— haklı çıktı. TÜM Connected Core'lar (`is_inner_core=true`) `_process_orbiting()` →
`_start_strike()` → `_defense_hit()` zinciri üzerinden, 78px'e giren herhangi bir düşmana
otomatik "dart" hareketiyle saldırıyor. Bu, Vector'ın daha önce incelenen Connected
Core'larında (Iron Aura, Momentum Field, Regen Pulse, Fortress, Bloodwall, Overcharge,
Anchor Pulse) da var ama **o turda hiç fark edilmemiş, açıklamalara hiç eklenmemişti**.

**Yapılan**:
- Hasar `_get_defense_base_damage()`'te elementsiz core'lar için (çoğu Connected Core)
  2 → **3**'e çıkarıldı (`else: fd=6`, sonuç `int(6*0.5)=3`). Bu fonksiyon SADECE Connected
  Core'lar tarafından kullanılıyor (dış yörünge toplarını hiç etkilemiyor — `_process_
  orbiting()` inner olmayanlar için erken `return` ediyor), güvenli bir değişiklik.
- Her kartın açıklamasına tek tek yazmak yerine, **"Connected Core" yeni bir sözlük
  keyword'ü oldu** (`Lang.STATUS_KEYWORDS`'e benzer ama ayrı, badge tabanlı): kart
  `_CONNECTED_CORE_INDICES` listesindeyse, hover popup'ına otomatik olarak "Connected
  Core: Fırlatılamaz — sürekli oyuncunun etrafında döner. Menziline giren düşmanlara 3
  hasarlık dart saldırısı yapar." bilgisi ekleniyor (`_show_card_glossary()`'ye
  `is_connected_core` parametresi eklendi).
- **UI temizliği**: eski ayrı "◈ Connected Core" badge Label'ı kaldırıldı, yerine kart
  açıklamasının ilk satırına `[b]Connected Core[/b]` başlığı eklendi (isim altında).
  Eski native tooltip (`click_area.tooltip_text = ui_connected_core_tooltip`) de
  kaldırıldı — artık popup zaten bunu kapsıyor, tekrar gereksizdi.
- **Popup boyutu düzeltildi**: sabit "78px/keyword" tahmini yerine, her keyword'ün gerçek
  metin uzunluğuna göre satır sayısı hesaplanıp panel/label yüksekliği dinamik büyütülüyor
  (kullanıcı: "yazı sığmamış" — uzun "Connected Core" metni panelin dışına taşıyordu).

**DEBUG NOTU (test kolaylığı, aynı gün eklendi):** `game_scene.gd::subject_died()`'da
`_spawn_data_particles(...)` çağrısına `× 8.0` çarpanı eklendi — düşman öldürünce upgrade
kartı gelme hızı 8 kat arttı (test için hızlı level almak amacıyla). **Karıştırılmamalı**:
bu `_data_current`'ı (run-içi upgrade tetikleyicisi) etkiliyor, `GameData.add_xp` (meta/
karakter seviyesi, run'lar arası) etkilenmiyor — ilk denemede yanlışlıkla ikincisine
uygulanmıştı, kullanıcı fark edip düzelttirdi. **Test bitince ×8.0 kaldırılmalı.**

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
- ~~**Elemental Memory yanlış davranıyor**~~ — **YANLIŞ ALARMDI (2026-09-14 doğrulandı)**: bu not 2026-07-05'ten kalmaydı, kart-kart review sırasında (Elemental Memory, 86) kontrol edildi — `apply_burn()`/`apply_wet()`/`apply_electrified()`/`apply_slow()`'un hepsinde `_had_reaction` flag'i kullanıldıktan hemen sonra `_had_reaction = false` ile düzgün resetleniyor, kalıcı 2× uzama riski yok. Muhtemelen bu not yazıldıktan sonraki bir session'da zaten düzeltilmiş, not güncellenmemiş.
- **Volatile Mixture çift tetik riski ONAYLANDI**: `_check_reaction()` içinde Volatile Mixture kolu erken `return` ediyor, ama bazı yollarda (örn. `is_wet && is_slowed → apply_frozen()` dalı) `apply_frozen()` çağrılıyor; bu yeniden `_check_reaction("wet")` içine girmez, güvenli. Ancak `is_burning && is_wet → _react_steam()` + arkasından gelen `apply_burn()` (Perfect Catalyst üzerinden) çift steam riski var. Test gerekli.
- **Perfect Catalyst + Volatile Mixture sonsuz döngü**: Reaksiyon → `_notify_reaction()` → `apply_burn()` → `apply_burn()` erken `return` (is_burning guard var) → güvenli. Ama `apply_wet()` → `_check_reaction("wet")` → Volatile Mixture aktifse bir sonraki elementi tetikleyebilir. Döngü kırıcı yok.
- **Living Storm + Static Charge kombinasyonu**: Living Storm electrified düşman yaklaşınca `health -= 3` → `take_damage(0, false)` çağırmıyor, doğrudan health düşürüyor, Static Charge tetiklenmiyor. Fakat Living Storm hasarı `die()` çağırıyor; bu `_collapse → _become_ally / _escape` döngüsünü tetikler. Sonsuz döngü yok ama beklenmedik die() zincirleri olabilir.
- **Overheat eşiği global counter**: `_overheat_counter` Player'a bağlı, düşmana değil — tüm düşmanların burn tick'leri tek sayaca yazılıyor (hedeflenen davranış mı?). 13 eşiği: 4-5 aynı anda yanan düşmanla ~2-3 saniyede dolabilir, oldukça hızlı.
- **Cryostasis (index 70) Lv3 scaling yok**: `_apply_utility_level` içinde index 70 için case yok. Her alışta `freeze_duration_mult *= 1.1` uygulanıyor (elif'te), utility cap 3 seviye ama scaling tanımsız. Frozen Time (82) da aynı sorun.
- ~~**Mana Overflow (index 90) implementasyonu eksik**~~ — **TAMAMLANDI**: `player.gd:639-641`'de Calamity sonrası 5 sn +%50 Core Speed uygulanıyor.
- ~~**Pyroblast (index 102) implementasyonu eksik**~~ — **TAMAMLANDI**: `base_enemy.gd:336-337`'de `_react_overheat` içinde radius counter×8 px büyüyor.
- ~~**Thermal Expansion (index 89) implementasyonu eksik**~~ — **TAMAMLANDI**: `base_enemy.gd:669-676`'da `_react_steam` radius 120→200 genişliyor, ıslak efekt de yayılıyor.
- ~~**Elemental Harmony Utility (index 84) implementasyonu eksik**~~ — **TAMAMLANDI**: `game_scene.gd:3556-3564` + `player.gd:643-644`'te aktif unique element başına +%5 Core Speed uygulanıyor.
- ~~**Calamity Blizzard**~~ — **YANLIŞ ALARMDI (2026-09-15 doğrulandı, Blizzard kart review'i sırasında)**: `_freeze_sf` (static) sadece PAYLAŞIMLI `SpriteFrames` KAYNAĞI (frame verisi) — her düşman kendi `AnimatedSprite2D` INSTANCE'ını (`_freeze_sprite`) oluşturup bu kaynağı atıyor. `play()`/`frame` gibi oynatma durumu instance-level olduğu için 20+ düşman aynı anda freeze olsa bile çakışma riski yok, bu zaten Godot'un önerdiği standart kaynak paylaşım optimizasyonu.
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

## Fikirler / Değerlendirilecek (henüz uygulanmadı)

- **Pierce Amp (index 12) / Split Amp (index 14) / Cryostasis (index 70) — orphan/ölü
  kod (2026-09-11/14, Pierce Core + Frozen Time review'leri sırasında bulundu)**: Vector'ın Core Mastery (11, "+1 damage to all
  cores") kartıyla aynı desende, `pierce_bonus`/`split_bonus` player değişkenleri +
  `ball_launcher.gd`'de `max_damage` hesabına ekleniyorlar + pickup handler'ları
  (`elif index == 12/14:`) çalışır durumda — AMA `upgrades` dizisinde bu index'ler için
  hiçbir kart tanımı yok, yani havuzda hiç görünmüyorlar, tamamen ulaşılamaz kod.
  `can_pierce`/`can_split` de Plasma/Steam/Arc/Voltaic/Electric/Cryo/Hydro/Pyro'daki
  gibi `_hit_subject()`'te sabit sayıyla eziliyor (`pierce_bonus`/`split_bonus` gerçekte
  hiç okunmuyor) ama kart alınamadığı için pratikte etkisiz — aktif bir bug değil.
  **Şimdilik dokunulmadı** (kullanıcı kararı). **Kullanıcının notu**: Core'a özel ekstra
  hasar sağlayan bu tarz kartlar (Amp kartları) tamamen kaldırılabilir — bunun yerine
  oyuncu ekstra hasarı **level up ile** ya da **coin (Chip mağazası?) ile satın alabilir**
  bir sisteme geçilebilir. Henüz tasarım detayı yok, review süreci bitince değerlendirilecek.

- **Calamity kartlarına SFX eklenmesi (2026-09-16, kullanıcı sordu)**: Şu an mevcut SFX
  sadece top çarpma sesleri (`assets/sfx/hitBalls/`: hitClassic/hitElemental/hitHeavy) +
  karakter silah ateşleme sesleri + müzikler — **hiçbir Calamity kartının kendine özel
  bir sesi yok** (`game_scene.gd`'de `AudioStreamPlayer` sadece müzik için kullanılıyor).
  Kullanıcı kararı: kart-kart review süreci bitince ele alınacak, şimdi değil.

- **Core "çarpma ömrü" mekaniği (2026-09-07, kullanıcı fikri)**: Her core'un bir isabet
  ömrü olsun (X vuruştan sonra core yok olsun/tükensin) — diğer arkanoid oyunlarına göre
  farklı bir mekanik olur, ayrıca oto-mod (auto_mode) kullanan oyuncu bile tamamen AFK
  kalamaz, arada müdahale etmek zorunda kalır. Henüz tasarım detayları netleşmedi (hangi
  core'lar etkilenecek, ömür nasıl yenilenecek, Connected Core'lar dahil mi vb.) — sadece
  fikir olarak not düşüldü, review süreci bitince değerlendirilecek.

## Notlar

- Detaylı sürüm notları için `güncelleme notları.txt` dosyasına bakılmalı.
- Commit mesajları Türkçe yazılıyor, format: kısa özet + (gerekirse) madde listesi.
- Düşman tipleri: subject, armed_subject, frantic_subject, heavy_subject,
  cyber_shotgun, cyber_shooter, cyber_rifle — her birinin sprite node ismi farklı
  (örn. `$ArmedSprite`, `$HeavySprite`, `$ShotgunSprite` vb.), kopyala-yapıştır
  yaparken bu isimleri değiştirmeyi unutma.
