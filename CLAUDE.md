# IntoTheYard — Proje Notları

Bu dosya, farklı bilgisayarlardaki (ev / işyeri) Claude Code oturumları arasında bağlam
köprüsü olarak kullanılır. Her oturum başında oku, her oturum sonunda güncelle.

## Cyber-404 füzesi düzeltildi — takip eden, dash ile atlatılan (2026-10-02, oyunda denenmedi)
Kullanıcı 15sn'lik füzeyi oyunda hiç göremedi. Kök sebepler: `missile.gd` `max_range=400`
iken boss oyuncudan 450-550px uzakta durduğu için (`keep_distance=500`) füze hep boşlukta
patlıyordu + görsel 12×12'lik turuncu `ColorRect`'ti, patlama efekti yoktu. Ayrıca füze
fırlatıldığı yöne DÜZ gidiyordu — oysa tasarım takip eden füzeydi, sadece dash ile kaçılmalı.
`missile.gd` baştan yazıldı: **takip eder** (`turn_rate=2.2 rad/sn`, hız 300) ama oyuncuya
`ARM_RADIUS=110px` yaklaşınca **kurulur**: takibi bırakıp düz gider, `ARM_DELAY=0.35sn` sonra
patlar (`blast_radius=70`, hasar 3, temasta hemen patlar) — bu aralıkta dash (120px/0.12sn,
i-frame yok, sadece konum) atan oyuncu yarıçapın dışına çıkar, hasar yemez ve füze patlamış
olur. Süre (`lifetime=7sn`) dolunca da patlar. İlk denemede Smiler'ın `skillMissile/VFX/`
sprite'ı kullanılmıştı ama kullanıcı "uyumsuz oldu" dedi; yer tutucuya dönüldü, sonra kullanıcı
kendi sprite'ını ekledi: **`assets/VFX/homingMissile/`** (24 kare, 32×32, burnu AŞAĞI/south
bakıyor; 0-18 uçuş, 19-23 patlama). `missile.gd` kareleri dinamik yüklüyor
(`EXPLODE_FROM=19`), tek yönlü olduğu için `rotation = direction.angle() - PI/2` ile hareket
yönüne döndürüyor (ölçek 1.25 — önce 2.5 idi, kullanıcı isteğiyle %50 küçültüldü); kurulunca beyaz yanıp söner; patlamada 5 kare
`blast_radius*2/32` ölçeğinde oynuyor. `missile.tscn`'den `ColorRect` silindi,
çarpışma yarıçapı 8→14.
**Füze sesleri (aynı gün)**: `assets/sfx/bosses/cyber404/homingMissileLaunch.ogg` (3.44sn) füze
doğduğu an füzenin child'ı olan `AudioStreamPlayer`'da çalıyor (GameplaySFX), patlayınca
0.15sn'de kısılıp duruyor; `homingMissileExplosion.ogg` (1.56sn) füze silinince kesilmesin
diye `Sfx.play_path` (autoload havuzu) ile çalıyor — parent ömrü dersi (bkz. kırılma sesi).
Sesler 0 dB; yüksek/kısık gelirse `volume_db` ayarlanacak.
**Fırlatma animasyonu (aynı gün)**: `assets/enemys/cyber404/animations/launchMissile/` (4 kare,
252×252: hazır, şarj, parlama, toparlanma) — `cyber_404.gd::_setup_sprite()` "launchMissile"
animasyonunu dinamik yüklüyor (8fps ≈ 0.5sn); `_launch_missile()` animasyonu oynatıp
`MISSILE_FIRE_FRAME=2` (parlama karesi, 0.25sn) gelince füzeyi spawn ediyor, animasyon bitince
"walk"a dönüyor (ölmüşse/oyuncu yoksa füze çıkmaz).
**Shockwave (2026-10-02, oyunda denenmedi)**: `game_scene.gd::boss_shockwave(pos, radius)` yazıldı —
Vector'un Shockwave sprite'ını (`assets/VFX/calamitys/shockwave/`, `_vfx_shockwave(at, final_scale, dur)`
artık parametreli) boss'tan dışa 0.7sn'de genişletiyor (Avlu'ya kırpılı, ölçek = radius/105), aynı ses
(-4dB) + `screen_shake_heavy`. Dalga cephesi oyuncuya ulaşınca (oyuncu max yarıçap içindeyse) BİR KEZ 2 hasar.
`cyber_404.gd::_shockwave()` 3 dalga (1.5sn arayla, boss ~4.5sn sersem) yarıçaplar 300/450/600 (eskiden 150/300/450).

## Cyber-404 "Shotgun burst" → "Ring attack" (2026-10-02, oyunda denenmedi)
Kullanıcı "shotgun burst" ismini mantıksız buldu (her yana mermi atıyor) ve
`assets/enemys/cyber404/animations/ringAttack/frame_000-024.png` (25 kare, 252×252, kare 0-2
hazırlık, 3-24 ateş efekti) ekledi. `cyber_404.gd`: `_shotgun_burst`→`_ring_attack`,
`shotgun_timer`→`ring_timer` (9sn aralık, mermi sayıları aynı; mermi `bullet_type` hâlâ
"shotgun"). `_setup_sprite()` "ringAttack" animasyonunu dinamik yüklüyor (14fps ≈ 1.8sn,
non-loop); saldırı başlayınca animasyon oynuyor, 3 kare (≈0.21sn) hazırlıktan SONRA 5 dalga
başlıyor (0.3sn arayla, artık pause-safe `create_timer(…, false)`), animasyon bitince
"walk"a dönülüyor (ölmüşse dönmez). Ölürse dalgalar duruyor (`is_dead` kontrolü).

## Cyber-404 boss teması bağlandı (2026-10-02, oyunda denenmedi)
Kullanıcı `assets/sfx/bosses/cyber404/cyber404inthefield.ogg` ekledi (Vorbis, 156.6sn, sorunsuz
import). `cyber_404.gd::_start_theme()` (`_ready()`'den çağrılıyor — boss kutudan çıkıp
`add_child` edildiği an) boss'un child'ı olan bir `AudioStreamPlayer`'la ("GameplaySFX" bus,
yani level-up/pause'da mute + oyun duraklayınca ses de duruyor) **döngüde** (`stream.loop=true`)
çalıyor; `die()` içinde `_stop_theme()` 1.5sn fade-out ile susturuyor. Ses seviyesi kullanıcı
isteğiyle iki kez kısıldı: önce %35 (0.65), sonra mevcut sesin %30'u daha (0.65×0.7) →
`volume_db = linear_to_db(0.455)` (≈ -6.8 dB). Not: müzik değil SFX
bus'ında; ayrı bir boss-müziği mantığı kurulursa (normal gameplay müziğini kısma vb.) buraya
bakılmalı — şu an gameplay müziği boss temasıyla BİRLİKTE çalmaya devam ediyor.
Boss saldırı zamanlamaları (kullanıcıyla sırayla gözden geçirilecek): shotgun burst 9sn,
füze 15sn, shockwave 30sn (zırh>0), rastgele silah 4-8sn.

## Eski (küçük) oyun alanı sınırları düzeltildi (2026-10-02, oyunda denenmedi)
Kullanıcı: sol tarafa giden mermiler bir yerden sonra yok oluyor. Gerçek arena duvarları
x:360-1630, y:240-1080 (`game_scene.tscn` WallLeft/WallRight/WallBottom) ama eski, daha dar
arenadan (x≈840-1640) kalma sabitler vardı — tarama sonucu bulunan hepsi düzeltildi:
- `bullet.gd`: sol sınır `x <= 840` → **330** (düşman mermileri 840'ta siliniyordu).
- `nyx_09.gd`: ışınlanma X clamp'i 950-1540 → **420-1570**; lazer kırpma sınırları
  910/1580 → **360/1630** (`_laser_clip_length`; y sınırları 260/1040 zaten uyumluydu).
- `cyber_404.gd`: zincir çapası `(1240,500)`/uzunluk 300 (boss yalnızca x≈940-1540'ta
  gezebiliyordu) → **`(995,560)`/450** (arena merkezi, aynı oran).
Diğer düşmanlarda/Smiler'da (`s_miler_79`, subject/ranged/cyber_* scriptleri) eski sabit
bulunamadı; `base_enemy.SURGERY_EXIT` hiçbir yerde kullanılmıyor.

## Vuruş sesi Sfx havuzuna taşındı (2026-10-02, oyunda denenmedi)
Kullanıcı düşmana/duvara vurunca ses gelmediğini bildirdi. Kodda net bir hata bulunamadı
(dosyalar sağlam/import'lu, çağrı `_hit_subject()` ve duvar sekmesinde duruyordu, v0.1.0.3'ten
beri değişmemişti) — şüpheli konuma bağlı `AudioStreamPlayer2D` + "SFX" bus'ıydı.
`ball.gd::_play_hit_sfx()` artık `Sfx.play_path("res://assets/sfx/hitBalls/hitClassic.ogg", -4.0)`
çağırıyor (calamity seslerinin kullandığı, çalıştığı doğrulanmış yol); `_hit_sfx` node'u ve
statik stream değişkenleri silindi. Yan etki: level-up/pause'da gameplay mute'una dahil oldu.
Not: `hitElemental.ogg`/`hitHeavy.ogg` eskiden de hiç çalınmıyordu (sadece Classic), hâlâ
kullanılmıyor. Düzelmediyse asıl sebep ayarlardaki SFX/Master sürgüsü ya da bus olabilir.

## Boss HP barı yeniden tasarlandı — tek frame + iki katman dolgu (2026-10-01, oyunda denenmedi)
Kullanıcı eski boss can/zırh barını (iki ayrı `ColorRect` çifti, çirkin duruyordu — bkz.
ekran görüntüsü) Vector'un `HealthBar2` mimarisiyle aynı mantığa çevirmemizi istedi: tek
bir frame grafiği + üstünde gri zırh dolgusu, azalınca/bitince altındaki kırmızı can
dolgusu görünür. Önce kullanıcıya Pixellab için jenerik (tüm boss'larda kullanılabilecek)
bir prompt yazıldı, kullanıcı ürettirip `assets/ui/bossesHealthBar.png`'ye ekledi
(256×25px, koyu metal çerçeve + üstte kırmızı/turuncu hazard-stripe aksanı, iç kısmı
TAMAMEN şeffaf — Python ile tarandı: iç dolgu alanı x:9-246 y:6-19, yani 237×13px).

`game_scene.gd::show_boss_bar()`/`update_boss_bar()` komple yeniden yazıldı:
- `BOSS_BAR_SCALE=1.8` ile frame ~460×45px'e büyütülüyor (eski 400×20'lik ColorRect'e
  yakın görünür genişlik).
- Katman sırası (arkadan öne): koyu interior arkaplan (`InteriorBG`) → kırmızı can dolgusu
  (`HealthBar`, her zaman güncel can oranına göre boyutlanıyor) → gri zırh dolgusu
  (`ArmorBar`, zırh oranına göre boyutlanıyor, `armor <= 0` olunca `visible=false` ile
  altındaki can barını açığa çıkarıyor) → en üstte frame PNG'si (`Frame`, `TEXTURE_FILTER_
  NEAREST`, pixel-art keskinliği için).
- `update_boss_bar(armor, health, max_armor, max_health)` imzası DEĞİŞMEDİ — `cyber_404.gd`
  tarafında hiçbir güncelleme gerekmedi, çağrı noktaları aynen çalışıyor.
- Şu an sadece Cyber-404 kullanıyor ama fonksiyonlar karaktere özel bir şey içermiyor —
  Smiler/Nyx de `show_boss_bar(self, "İSİM")` çağırırsa aynı barı otomatik kullanır.
- Kırmızı dolgu rengi kullanıcı isteğiyle yumuşatıldı: `Color(0.8,0.1,0.1)` (canlı/neon
  kırmızı) → `Color(0.58,0.21,0.16)` (frame'in kendi pas/hazard-stripe renginden,
  `rgb(146,74,55)`, Python ile örneklenerek seçildi — oyunun paletine daha uyumlu).

## Cyber-404 boyutu büyütüldü + giriş animasyonundaki "zıplama" kaldırıldı (2026-10-01, oyunda denenmedi)
Kullanıcı "Cyber404'ün boyunu büyütelim" dedi — ilk denemede `cyber_404.gd::_ready()`'deki
`scale = Vector2(0.1,0.1)`'i `0.13`'e çıkarmak **hiçbir görsel etki yaratmadı**: kök sebep
`game_scene.gd::_spawn_boss_at()`'teki giriş tween'i, boss'un scale'ini (ne olursa olsun)
SABİT bir hedefe (`Vector2(1.8,1.8)`) tweenliyormuş — `cyber_404.gd`'deki değer tamamen
eziliyordu. `cyber_404.gd`'deki değişiklik geri alındı (etkisizdi), asıl büyütme
`_spawn_boss_at()`'teki hedef değerde yapıldı: `1.8` → `2.3` (%28) → kullanıcı isteğiyle
**`2.43`** (%35) oldu.

**İkinci düzeltme**: kullanıcı "kutudan çıkarken zıplıyor gibi yapıyor, olduğu yerde kalsın,
hiçbir hareket yapmasın" dedi — kök sebep: aynı tween'de `position`'ı spawn_pos'tan SABİT
bir hedefe (`Vector2(995,400)`, spawn_pos'tan ~170px yukarı) kaydıran paralel bir ikinci
tween vardı, bu "zıplama" hissini veriyordu. **Pozisyon tween'i komple kaldırıldı** — boss
artık spawn edildiği yerde (`spawn_pos`, crate'in kaldığı nokta) sabit kalıyor.

**Üçüncü düzeltme (aynı gün devamı)**: kullanıcı "küçükten büyüğe doğru efekti kaldıralım"
dedi — büyüme (scale) tween'i de TAMAMEN kaldırıldı, `b.scale = Vector2(2.43, 2.43)`
doğrudan `add_child()`'dan ÖNCE set ediliyor. Artık `_spawn_boss_at()`'te hiçbir animasyon
yok — boss kutunun kaldığı yerde, doğrudan nihai boyutunda (2.43, kutudan ÖNCE 1.8'di,
%35 büyütüldü) beliriyor. `_screen_shake()` + collision shape enable + `_landing_wave()`
artık `await tw.finished` beklemeden hemen aynı frame'de çalışıyor (tween kalmadığı için).
**Kutu da aynı %35 oranda büyütüldü**: `crate_intro.gd::CRATE_SPRITE_SCALE` 1.3 → **1.76**
(1.3 × 1.35).

**BUG FIX (kullanıcı fark etti, aynı gün devamı)**: "boss minicik kalmış" — `b.scale =
Vector2(2.43,2.43)` `add_child(b)`'DEN ÖNCE set edilmişti, ama `cyber_404.gd::_ready()`
kendi `scale = Vector2(0.1,0.1)` satırını tam `add_child()` çağrıldığı anda (node tree'ye
girince `_ready` tetiklenir) çalıştırıyor — SONRADAN çalıştığı için 2.43'ün üzerine yazıp
boss'u 0.1'e (minicik) düşürüyordu. Eskiden tween yaklaşımında bu sorun yoktu çünkü tween
`add_child()`'dan SONRA başlatılıyordu, `_ready()`'nin 0.1'i çoktan uygulanmış oluyordu,
tween onun üzerine doğru şekilde büyütüyordu. **Fix**: `b.scale = Vector2(2.43,2.43)`
satırı `add_child(b)`'DEN SONRAYA taşındı.

## Cyber-404 collision shape görsel gövdeye göre küçültüldü (2026-10-01, oyunda denenmedi)
Kullanıcı "core'lar direkt boss'a vurmuyor gibi, belli bir karenin içine girmiyorlar"
dedi — Python ile `cyber404_walk_S.png`'nin ilk karesi (252×252) içindeki gerçek karakter
siluetinin alpha bbox'ı ölçüldü: (70,65)-(182,172), yani 112×107px. Bunu sprite'ın kendi
scale'i (0.7) ve root node scale'iyle (2.43, bu session'da büyütülmüştü) çarpınca gerçek
görünen gövde ~190×182 dünya pikseli çıkıyor. Eski collision shape (`RectangleShape2D`,
100×80 — root scale'den ETKİLENİYOR ama sprite'ın 0.7'lik ek scale'inden etkilenmiyor,
yani dünya boyutu 100×2.43=243 × 80×2.43=194) **görünen gövdeden daha büyüktü** — core'lar
gerçek vücuda değmeden, görünmez/boş bir sınıra çarpıp sekiyordu, "vücuda vurmuyor gibi"
hissi buradan geliyordu. **Fix**: `cyber_404.tscn`'deki `RectangleShape2D` boyutu 100×80 →
**78×75** (190/2.43≈78.4, 182/2.43≈74.9 — gerçek görünen gövdeye denk gelecek şekilde
geriye hesaplandı), ayrıca siluetin dikey merkezinin frame merkezinden hafif yukarıda
olması (~-5px dünya) nedeniyle `CollisionShape2D.position = Vector2(0, -5)` eklendi.
**Not**: Cyber-404'ün scale'i ileride tekrar değişirse (`game_scene.gd::_spawn_boss_at()`'teki
`2.43`), bu collision shape boyutu da orantılı olarak yeniden hesaplanmalı — formül:
`local_size = (local_bbox_px × sprite.scale) / root_scale`.

## Leila/Cyclone de yeni HealthBar2'ye taşındı (2026-10-01, oyunda denenmedi)
Kullanıcı `assets/hudBars/leila/` ve `assets/hudBars/cyclone/` altına Vector'unkiyle
BİREBİR aynı boyutta (161×28, aynı iç dolgu koordinatları: x:5-155 y:11-22) kendi
`health_bar_frame.png`'lerini ekledi (Leila magenta/mor tonlu, Cyclone yeşil tonlu).

Eskiden sadece Vector `$UI/HealthBar2`'yi kullanıyordu, diğer karakterler sağ-alt köşedeki
eski `$UI/IntegrityBar`'da kalıyordu (`char_type == "vector"` dallanması). Artık **her
üç karakter de HealthBar2'yi kullanıyor**, `IntegrityBar` tamamen gizlendi (değerleri hâlâ
arka planda senkron tutuluyor ama hiç görünmüyor — kod sadeliği için silinmedi, zararsız).
- `game_scene.gd` (karakter seçimi bloğu): `$UI/HealthBar2.visible=true` artık KOŞULSUZ,
  `$UI/MomentumBar.visible` sadece Vector'da true kalıyor (Momentum hâlâ Vector'a özel).
  Karaktere göre `$UI/HealthBar2/Frame.texture` dinamik `load()` ediliyor
  (`assets/hudBars/<char>/health_bar_frame.png`), `Fill`'in rengi de yeni bir
  `StyleBoxFlat` ile karaktere göre değiştiriliyor: Vector cyan (değişmedi), **Leila
  `Color(0.87,0.2,0.89)`** (frame'in kendi en parlak piksel rengi `rgb(222,50,226)`'dan
  örneklendi), **Cyclone `Color(0.48,0.72,0.2)`** (frame'den `rgb(122,183,51)`).
- `_get_hp_bar_rect()`: artık "vector" kontrolü olmadan HER ZAMAN `HealthBar2/Fill`'i
  döndürüyor (Armor overlay sistemi — şu an sadece Vector kullanıyor ama genel kaldı).
- `_setup_frost_barrier_ui()`/`_update_frost_barrier_ui()` (Leila'ya özel "Frost Barrier"
  kartı, 204): eskiden doğrudan `$UI/IntegrityBar`'a (artık gizli) bağlıydı — Armor
  overlay'in kullandığı `_get_hp_bar_rect()` helper'ına taşındı, artık HealthBar2'nin
  üzerinde doğru konumda görünüyor.
**Test edilmesi gereken**: Leila/Cyclone ile oyun açılıp sol üstteki yeni bar'ın doğru
renk/texture ile göründüğü, Leila'nın Frost Barrier overlay'inin (varsa) doğru pozisyonda
çıktığı doğrulanmalı.

**Renkler kullanıcının verdiği kesin hex'lere güncellendi (aynı gün devamı)**: ilk turda
tahmini renkler (Vector cyan, Leila magenta, Cyclone yeşil — frame'den örneklenmişti)
kullanılmıştı, kullanıcı kesin hex değerler verdi: **Vector can=`#182236`** (koyu lacivert,
`HealthBar2/Fill`), **Vector zırh=`#575859`** (gri, `ArmorOverlay`, `_setup_armor_bar()`),
**Cyclone=`#084518`** (koyu yeşil), **Leila=`#3d233c`** (koyu mor/bordo). Hepsi `0xRR/255.0`
şeklinde doğrudan hex'ten çevrildi (yuvarlama hatası riski olmasın diye elle ondalık
hesaplanmadı). Boss barının (Cyber-404) renkleri bu değişiklikten etkilenmedi, ayrı kaldı.

## KRİTİK BUG FIX: Boss/Vector HP barlarının dikişinden düşmanlar görünüyordu (2026-10-01)
Kullanıcı ekran görüntüsüyle gösterdi: hem boss barında hem Vector'un kendi can barında,
dolgunun (can/zırh) alt/sağ kenarında **düşmanlar (küçük figürler) barın içinden/üstünden
görünüyordu** — ilk bakışta CanvasLayer sıralama sorunu gibi göründü ama piksel piksel
inceleyince (Python ile ekran görüntüsünün kendisinden renk örnekleme) gerçek sebep çok
daha basit çıktı: **dolgu `ProgressBar`/`ColorRect`'leri, PNG'nin gerçek şeffaf iç alanından
TAM 1 texture-pikseli KISA bırakılmıştı** (texture ölçümünde `(son_opak_satır - ilk_şeffaf_
satır)` yerine yanlışlıkla 1 eksik hesaplanmış — "inclusive range" hatası, hem `health_bar_
frame.png` hem `momentum_bar_frame.png` hem yeni `bossesHealthBar.png`'de aynı kalıpta).
Bu 1 pikseli (2x/1.8x ölçekte ~2px dünya pikseli) **hiçbir şey kapatmıyordu** — ne dolgu
(kısa kaldığı için), ne de çerçeve (gerçek interior'ın İÇİNDE kaldığı için, border değil) —
yani UI'da gerçekten BOŞ/şeffaf bir dikiş vardı, arkadaki oyun dünyası (ve o an o pikselde
duran düşmanlar) oradan görünüyordu. CanvasLayer'ların kendisiyle hiç ilgisi yoktu.

**Fix — 3 bar da gerçek ölçülen interior + 1px güvenlik payıyla (opak çerçevenin içine
hafifçe taşacak şekilde, zararsız) büyütüldü**:
- `game_scene.tscn::UI/HealthBar2/Fill`: offset (10,22)-(310,44) → **(9,21)-(313,47)**
- `game_scene.tscn::UI/MomentumBar/Fill`: offset (72,12)-(286,22) → **(73,11)-(289,25)**
- `game_scene.gd::BOSS_BAR_INTERIOR_OFS/SIZE`: (9,6)/(237,13) → **(8,5)/(240,16)**
**Genel kural**: bundan sonra yeni bir bar frame'i eklenirken, Python ile ölçülen interior
sınırlarına MUTLAKA +1px güvenlik payı eklensin (border opak olduğu için taşma görünmez,
ama eksik kalırsa arkadaki dünya dikişten sızar) — "tahmin" yerine ölçüm + pay standart hale
getirilmeli.

### SONUÇ: Boss Crate kırılma sesi — KÖK SEBEP BULUNDU, çözüldü (2026-10-01)
Aşağıdaki tüm "kırılma sesi takılıyor" bölümleri (2026-09-30) bu notla kapandı. **Ses
dosyasında/formatta/decoder'da/pool'da HİÇBİR sorun yoktu** — gerçek sebep basitti:
`_smash_player`, kutunun (`self`) child'ı olarak ekleniyordu, kutu da kendi animasyonu
bitince (`_pre_delay` + animasyon süresi ≈ 5sn) kendini `queue_free()` ediyordu — child
olan ses node'u da TAM O ANDA/ondan kısa süre önce siliniyor, bu da "takılmış/üst üste
binmiş/tekrar başlatılıyormuş gibi" duyulan sese sebep oluyordu. **Doğrulama**: sabit
5sn'lik bir zamanlayıcı testinde ses `_smash_player` kutudan bağımsız bir parent'a
(`get_parent()`, gölgedeki desenin aynısı) bağlanınca TERTEMİZ çaldı — hem format (Ogg/WAV)
hem tetikleme yöntemi (frame-based/plain timer/pooled/dedicated) testleri YANLIŞ YÖNE
odaklanmıştı, hiçbiri gerçek sebebi (node lifecycle/parenting) test etmiyordu.

**Kalıcı Fix**: `_smash_player` artık `self` (kutu) yerine `get_parent()`'a (`game_scene`,
gölge node'uyla aynı parent) ekleniyor — kutu ne zaman silinirse silinsin ses node'u
etkilenmiyor, `finished` sinyaliyle kendi kendini `queue_free()` ediyor. Tetikleme tekrar
`frame_changed`'e bağlandı: `IMPACT_FRAME` (10. kare, çarpma anıyla AYNI kare — artık ekran
sarsıntısı ile kırılma sesi birlikte tetikleniyor) olunca bir kez çalıyor (`_smash_fired`
guard'ı, `_landed_fired`/`_visible_fired` ile aynı desen).
**Genel öğrenilen ders**: bir ses "takılmış/bozuk" çalıyorsa ve dosya/format/pool/decoder
testleri hiçbir şey bulamıyorsa, **ses node'unun parent'ının ömrü/lifecycle'ı** da şüpheli
listesine eklenmeli — özellikle parent kendi kendini kısa süre içinde `queue_free()` eden
geçici bir node'sa (bu projede "intro"/"VFX" gibi tek seferlik sahne nesneleri).

### 2. BUG — frame_changed BEKLENENDEN FAZLA ateşleniyordu, bool bayrak yetersiz kaldı (aynı gün devamı)
Yukarıdaki parenting fix'i sonrası ses artık ÇALIYORDU ama kullanıcı "sesin başlangıcı
7-8 kere taramalı tüfek gibi tekrarlıyor, her defasında bir öncekini durdurup üst üste
biniyor, en son çalınan temiz oynuyor" dedi — bu **birden fazla `.play()` çağrısının AYNI
AudioStreamPlayer'da art arda yapıldığının** klasik belirtisi (Godot'ta `play()` zaten
çalan bir player'da çağrılırsa önceki çalmayı kesip baştan başlatıyor). `_landed_fired`/
`_visible_fired` ile aynı desendeki bool bayrak (`_smash_fired`) teorik olarak bunu
önlemesi gerekirken, `frame_changed`'in (muhtemelen o anki sahne yoğunluğu/hitch'ten
dolayı frame'in ileri-geri salınması veya aynı frame için sinyalin beklenenden fazla
ateşlenmesi yüzünden) umulandan fazla tetiklenmesi bir şekilde ikinci bir `.play()`
çağrısına izin veriyordu.
**Fix (ilk deneme — crash verdi)**: kırılma sesi `_landed_fired`/`_visible_fired`'ın
paylaştığı ortak closure'dan AYRILDI, kendi self-disconnecting özel bir `frame_changed`
dinleyicisine taşındı — `var _smash_cb: Callable; _smash_cb = func(): ...
disconnect(_smash_cb)` şeklinde, lambda'nın KENDİ KENDİNE referans verdiği bir yapı
denendi. **Çalışmadı**: `E ... Cannot disconnect from 'frame_changed': the provided
callable is null` hatası verdi. **Gerçek sebep**: GDScript'teki closure'lar dış
değişkenleri (`_landed_fired` gibi bool bayraklar için sorunsuz çalışan) normalde
referans gibi paylaşıyor AMA bir lambda kendi atandığı değişkene KENDİ GÖVDESİ İÇİNDE
referans verirse, o değişkeni "capture" ettiği an (lambda'nın `func(): ...` ifadesi
değerlendirildiği sırada, ATAMA TAMAMLANMADAN ÖNCE) hâlâ `null` (Callable'ın varsayılan
değeri) olan ESKİ değeri yakalıyor — atama tamamlandıktan sonra bile lambda içindeki
referans o eski null'a sabit kalıyor. Yani **self-reference içeren lambda'lar GDScript'te
güvenilir değil**, sadece dışarıdan/önceden tanımlanmış DEĞİŞKENLERİ okuyup yazan
lambda'lar (bool bayrak deseni gibi) güvenli.
**Gerçek Fix**: self-reference'ı tamamen ortadan kaldıran, **adlı (named) bir fonksiyon**
(`_on_smash_frame_check()`) + 2 instance değişkeni (`_smash_check_sprite`,
`_smash_check_player`) kullanan bir yapıya geçildi — `spr.frame_changed.connect(
_on_smash_frame_check)` ile bağlanıyor, fonksiyonun kendisi `is_connected()` kontrolüyle
güvenli şekilde `disconnect(_on_smash_frame_check)` çağırabiliyor (self-reference yok,
Callable her zaman geçerli çünkü adlı fonksiyonlar `Callable(self, "ad")` olarak her an
yeniden oluşturulabilir, lambda'nın "capture anındaki anlık değer" sorunu burada yok).
**Not**: `_landed_fired`/`_visible_fired` için aynı potansiyel risk hâlâ teorik olarak
var ama onların efektleri (ekran sarsıntısı, boss spawn) başka bayraklarla da korunuyor
(`_boss_spawned` vb.) ve tekrarlı tetiklenseler bile kullanıcı tarafında fark edilecek
kadar belirgin bir semptom vermiyorlardı — bu yüzden şimdilik dokunulmadı, sadece ses
(tekrarlanması EN BELİRGİN şekilde duyulan efekt) için bu daha sağlam deseni kullanıyoruz.
Benzer bir sorun fark edilirse aynı self-disconnecting desen oraya da uygulanabilir.

**Denenen ve SIRASIYLA ELENEN tüm ihtimaller** (hepsi aynı "takılmış/üst üste binmiş"
semptomunu verdi):
1. Paylaşımlı `Sfx` havuzu yerine özel/dedicated `AudioStreamPlayer` (Freezing Cold'daki
   `storm_audio` deseni) — **elendi**.
2. `Sfx.preload_sound()` ile önceden cache'leme (senkron `load()` hitch'i ihtimali) —
   **elendi**.
3. Dosyayı Python `soundfile` ile PCM'e tam decode edip sıfırdan temiz Vorbis olarak
   yeniden kodlama (nonstandard Ogg container şüphesi) — **elendi**.
4. Kullanıcının **tamamen farklı, güvenilir bir siteden** yeniden indirdiği ikinci bir
   `woodSmash.ogg` dosyası — **aynı sonuç, elendi** (dosyanın kendisi şüpheden kurtuldu).
5. **Kesin tanı testi**: kutunun `frame_changed`/animasyon mantığından TAMAMEN bağımsız,
   sıfırdan yeni bir `AudioStreamPlayer` ile sabit bir `create_timer(12.0)` üzerinden
   çalma — **aynı sonuç** → frame-tetikleme zincirinin (`_crack_fired` guard'ı vb.) suçlu
   olmadığı kesinleşti.
6. **Format testi**: aynı dosyanın Ogg Vorbis hali ile Python `soundfile` ile üretilen
   PCM16 WAV hali (decode gerektirmeyen ham format) aynı anda, ayrı `AudioStreamPlayer`'larla
   çalındı — **ikisi de aynı şekilde takıldı** → Godot'un Ogg Vorbis decoder'ı da elendi.

**Sonuç**: format, dosya kaynağı, tetikleme yöntemi (frame-based / plain timer / pooled /
dedicated player) — denenen HİÇBİR değişken sonucu değiştirmedi. Kullanıcının "şimdiye
kadar yaptığımız hiçbir seste sorun yokken bunda olması garip" gözlemiyle birlikte en
olası açıklama: sorun ses dosyasında/Godot'un ses sisteminde değil, **o anki sahne
yoğunluğunda** (kutu aynı anda düşüyor, tween'ler/gölge/shake çalışıyor, yeni node'lar
`add_child` ediliyor) oluşan genel bir frame hıçkırığı/hitch'in o an çalan HERHANGİ bir
sesi etkilemesi — ama bu da doğrulanmadı, sadece eleme sonrası kalan en makul ihtimal.

**Ara adım (geri alındı)**: önce kırılma sesi komple kaldırılmıştı (`_smash_player` +
`_crack_fired` bloğu silinmiş, `woodSmash.ogg`/`.import` + geçici `woodSmash.wav`
dosyaları silinmişti) — kullanıcı "yanlış anlattım, sesi kaldır değil SABİT 5. saniyeye
koy demek istedim" diye düzeltti. **Dosya hiç commit edilmemişti (git'te untracked'tı),
silinince geri getirilemedi — kullanıcının `assets/sfx/cyber404BossCrate/woodSmash.ogg`'u
tekrar eklemesi gerekiyor.**

**Güncel Fix**: `crate_intro.gd::_play_intro_sprite()`'da kırılma sesi artık `frame_changed`'e
hiç bağlı değil — fonksiyon başlar başlamaz sıfırdan bir `AudioStreamPlayer` (`_smash_player`,
dedicated, pooled değil) oluşturuluyor, `get_tree().create_timer(SMASH_FIXED_TIME=5.0, false)`
ile **sabit 5sn'de** bir kez çalıyor (frame/animasyon ilerlemesinden tamamen bağımsız, saf
zaman bazlı — tıpkı tanı testindeki 12sn'lik deneme gibi). `CRACK_FRAME` sabiti hâlâ SADECE
düşüş sesinin bitiş zamanlamasını (`_pre_delay`) hesaplamak için kullanılıyor, kırılma
sesiyle artık hiç ilgisi yok. `game_scene.gd::_start_boss_intro()`'daki eski tanı/debug test
blokları kaldırıldı (gerek kalmadı, mekanik zaten kalıcı hale geldi).
**UYARI**: tanı testlerinde bu dosya (hangi formatta/kaynaktan olursa olsun) HER tetikleme
yönteminde (frame-based, pooled, dedicated, plain timer) aynı "takılma" sorununu vermişti —
5sn'lik sabit zamanlayıcı da aynı mekanizmayı kullanıyor, yani **sorunun tekrar etme
ihtimali yüksek**, kullanıcı test edip onaylamalı. Tekrar ederse kaynağı WAV olarak baştan
tasarlamak (`AudioStreamWAV`, Vorbis import'suz) veya sesi kutunun diğer işlemlerinden
(tween/gölge/node oluşturma) tamamen izole bir ortamda test etmek gündeme gelebilir.

### Boss Crate sesleri bağlandı (2026-09-30, aynı gün, oyunda denenmedi)
Kullanıcı `assets/sfx/cyber404BossCrate/` altına 2 dosya ekledi (ikisi de Vorbis,
sorunsuz): `fallingdown.ogg` (3.5sn) ve `woodsmash.ogg` (1.44sn). İstek: düşüş sesi
kutu daha görünmeden çalmaya başlasın, kırılma sesi ise gerçek kırılma anına
(CRACK_FRAME=14) denk gelsin.
- `_play_intro_sprite()`'ın en başına (pozisyon/z_index set edilmeden ÖNCE)
  `Sfx.play_path(".../fallingdown.ogg")` eklendi — kutu henüz `add_child` bile
  edilmemişken, animasyon/tween başlamadan hemen çalıyor.
- `frame_changed` callback'ine yeni `_crack_fired` guard'ı eklendi: `spr.frame >=
  CRACK_FRAME` (14) olunca bir kez `woodsmash.ogg` çalıyor — daha önce sadece bilgi
  amaçlı duran `CRACK_FRAME` sabiti artık gerçek bir tetikleyici.

### Düzeltme: kırılma sesi HÂLÂ tekrar tekrar takılıyor — dosya temiz Vorbis'e yeniden kodlandı (aynı gün devamı)
Kullanıcı özel AudioStreamPlayer'dan sonra bile ısrarla "tekrar tekrar başlatılıyor
gibi, 3 kare boyunca sıkışıyor" dedi. **Kod tarafı tekrar didik didik kontrol edildi**:
`_crack_fired` guard'ı `_landed_fired`/`_visible_fired` ile BİREBİR aynı, kanıtlanmış
desen (proje genelinde `_vfx_yard_engine`'in `_bolts_fired`'ı dahil onlarca yerde
kullanılıyor, hiçbirinde tekrar tetikleme sorunu yok) — GDScript lambda'ları local
değişkenleri referans gibi tutuyor, `_play_intro_sprite()` da tek bir kez çağrılıyor
(`_start_boss_intro()`'un iki çağrı noktası — normal 10dk akışı ve debug 10sn akışı —
birbirini `_boss_spawned`/`_crate_node` bayraklarıyla karşılıklı dışlıyor, aynı anda
ikisi asla tetiklenemez). Yani **kod tarafında gerçek bir "3 kerede tekrar başlatma"
bug'ı YOK** — sinyal sadece bir kez ateşleniyor, `.play()` de sadece bir kez çağrılıyor.

Geriye kalan tek açıklama: `woodsmash.ogg`'un **Ogg konteyner/header'ının** kendisi
— genel dalga formu (amplitude) temiz çıksa da, dosyanın orijinal kaynağından
(muhtemelen bir online converter) standart dışı bir Ogg sayfa yapısıyla gelmiş olması,
`soundfile`/libsndfile'ın tolere edip sorunsuz okuduğu ama **Godot'un kendi Ogg Vorbis
decoder'ının** stutter/pop ile tepki verdiği bir senaryo (projenin önceki FLAC-in-Ogg
sorunuyla aynı aileden, farklı bir belirti). **Fix**: dosya PCM'e (ham ses verisine)
tam decode edilip `soundfile` ile SIFIRDAN temiz bir Vorbis dosyası olarak yeniden
kodlandı (`format='OGG', subtype='VORBIS'`) — içerik/dalga formu birebir aynı, sadece
konteyner standart bir encoder'dan geçmiş oluyor. Henüz test edilmedi, kullanıcıdan
tekrar doğrulama bekleniyor; hâlâ sorun olursa kaynağı farklı bir siteden indirip
tekrar denemek gerekebilir (dosyanın kendisinde bir sorun olduğu ihtimali güçlendi).

### Düzeltme: kırılma sesi hâlâ "sıkışmış" çalıyordu — Sfx havuzu yerine özel AudioStreamPlayer (aynı gün devamı)
`Sfx.preload_sound()` ile hitch riskini ortadan kaldırmak yetmedi, kullanıcı hâlâ
"sıkışmış/bugged" olduğunu bildirdi. `woodsmash.ogg`'un dalga formu Python'da tekrar
ayrıntılı incelendi (clipping yok, mid-dosya sessizlik/kopukluk yok, zarf eğrisi
tamamen normal bir çarpma-sönümü) — dosyanın kendisinde bir bozukluk YOK. Kalan tek
şüpheli: `Sfx.play_path()`'in paylaşımlı 8'lik havuzu (`_players`, `_next` ile dönen) —
kırılma anında havuzdaki aynı slotun başka bir sesle (örn. UI hover/click, Yard Engine
sesi vb.) çakışması/yeniden yönlendirilmesi ihtimali. **Fix**: kırılma sesi artık
paylaşımlı havuzu hiç kullanmıyor — Freezing Cold'un `storm_audio`'suyla birebir aynı
desende KENDİNE AİT, özel bir `AudioStreamPlayer` (`_smash_player`, kutunun child'ı,
`GameplaySFX` bus'ında, `process_mode=ALWAYS`) oluşturuldu. Stream düşüş sesiyle aynı
anda yükleniyor (hitch riski hâlâ ortadan kalkmış durumda), tam kırılma karesinde
sadece `.play()` çağrılıyor — başka hiçbir sesle slot paylaşmıyor, kesintiye/yeniden
tetiklenmeye açık değil. `Sfx.preload_sound()` genel bir yardımcı fonksiyon olarak
`sfx.gd`'de kaldı (ileride benzer kare-kilitli sesler için kullanılabilir).

### 2 BUG FIX — kırılma sesi geç kalıyordu + "takılmış/bugged" çalıyordu (2026-10-01)
Kullanıcı test etti: "(1) tam kırılma anında smash çalışmıyor, biraz geç başlıyor,
(2) smash SFX'i garip çalıyor, sıkışmış/bugged gibi".

**Bug 1 — gecikme hesabı**: Python `soundfile` ile analiz edilince `fallingdown.ogg`'un
dosya süresi 3.5sn olmasına rağmen gerçek sesin **~3.17sn'de bittiği, kalan ~0.33sn'nin
sessizlik** olduğu görüldü — `_fall_stream.get_length()` tam 3.5sn döndürdüğü için
hesaplanan `_pre_delay` de bu sessizliği hesaba katıyordu, sonuçta smash her zaman
sesin gerçek (duyulabilir) bitişinden ~0.3sn SONRA tetikleniyordu ("geç başlıyor"
hissi tam buradan geliyordu). **Fix**: `fallingdown.ogg` Python'da analiz edilip
(RMS eşiği ile son anlamlı örnek bulunup) **3.20sn'ye trimlendi** (gerçek Vorbis,
format='OGG' subtype='VORBIS' ile yeniden yazıldı) — artık dosyanın `get_length()`'i
gerçek duyulabilir süreyle (küçük bir güvenlik payıyla) eşleşiyor, `_pre_delay` hesabı
otomatik doğru çıkıyor, ek bir kod değişikliği gerekmedi (sadece asset düzeltmesi).

**Bug 2 — "takılmış/bugged" çalma**: `woodsmash.ogg`'un dalga formu Python'da analiz
edildi (clipping yok, ani sessizlik/kopukluk yok, dosyanın kendisi temiz) — asıl sebep
muhtemelen `Sfx.play_path()`'in İLK çağrıldığı anda yaptığı **senkron `load()`**
işlemiydi: kırılma sesi tam bir animasyon karesine kilitlenmesi gereken bir tetikleme
olduğu için, o anda ilk kez diskten yüklenmesi (küçük de olsa) bir hitch/gecikme
yaratıp sesin "takılmış" gibi başlamasına sebep olabiliyordu. **Fix**: `sfx.gd`'ye
yeni `preload_sound(path)` fonksiyonu eklendi (sadece `_cache`'e önceden yüklüyor,
çalmıyor) — `crate_intro.gd` artık `woodsmash.ogg`'u düşüş sesiyle AYNI anda (kırılmadan
~2.5sn önce) önbelleğe alıyor, gerçek tetiklenme anında `_cache`'ten doğrudan okunuyor,
hiç senkron disk I/O'su olmuyor.

### Düzeltme: Düşüş sesi çok daha erken başlıyor, sonu tam kırılmaya denk geliyor (aynı gün)
Kullanıcı: "İç içe oturmuş, falling'in sonunu tam smash'e denk getir" — `fallingdown.ogg`
(3.5sn) çok uzun ama `CRACK_FRAME` (14. kare, ~1.0sn) çok erken geliyordu, yani ses
kırılma anında daha yeni başlamış oluyordu, "iç içe" hissi buradan geliyordu.
**Fix**: `_pre_delay = fall_dur - crack_time` (`AudioStream.get_length()` ile dosyanın
gerçek süresi okunup dinamik hesaplanıyor, sabit sayı değil — dosya değişirse otomatik
uyarlanır) kadar bir bekleme eklendi. Ses ÖNCE çalıyor, sonra bu gecikme kadar (şu an
~2.5sn) kutu hiç görünmeden bekleniyor (henüz hiçbir sprite/tween kurulmamış), gecikme
bitince kutunun görsel sekansı (düşüş+animasyon) başlıyor — kırılma sesi (CRACK_FRAME)
tam düşüş sesinin bittiği ana denk geliyor. Toplam "boss geliyor" hissi artık ses
başladığı andan itibaren ~1sn daha uzun sürüyor (önceki 10sn'lik debug tetiklemesi
bundan etkilenmiyor, sadece görsel gecikmeye giriyor).

### BUG FIX: Kalan kareler (26-36) hiç oynamıyordu (kullanıcı fark etti, aynı gün)
Kullanıcı: "frame'lerin hepsi oynamıyor". Kök sebep: `game_scene.gd::_on_boss_emerged()`
`boss_emerged` sinyali gelir gelmez (25. kare) kutuyu **0.3sn'de** soldurup
`queue_free()` ediyordu — 14fps'te 0.3sn ≈ 4 kare, yani 25-29 arası birkaç kare
solarak görünüp kutu siliniyordu, kalan ~7 kare (30-36) hiç oynamadan kayboluyordu.
**Fix**: `crate_intro.gd`'ye `_owns_cleanup: bool` bayrağı eklendi — sprite yolunda
`boss_emerged` (25. karede) tetiklenirken bu bayrak `true` yapılıyor, fonksiyon
`emit_signal`'den SONRA `await spr.animation_finished` ile animasyonun GERÇEKTEN
bitmesini bekliyor, ancak o zaman kendi soldurma+silme işlemini kendisi yapıyor.
`game_scene.gd::_on_boss_emerged()` artık `crate._owns_cleanup == true` ise kutuyu
erken silmiyor (temizliği kutunun kendisine bırakıyor) — sadece eski procedural
fallback yolunda (animasyon zaten tam bitmiş oluyor) eskisi gibi hemen soldurup
siliyor. Böylece boss 25. karede spawn oluyor AMA kutu 36. kareye kadar tam
oynayıp öyle kayboluyor, hiçbir kare atlanmıyor.

### Düzeltme: gerçek düşüş hareketi + boyut küçültme + gölgenin sabit yere bağlanması (aynı gün)
Kullanıcı test etti: "düşme yok, bir anda beliriyor kutu" — sprite'ın kendi kareleri
(0-9. kareler) görsel olarak yeterli bir düşüş hissi VERMİYORDU, land_pos'ta sabit
duruyordu, sadece animasyon oynuyordu. Gerçek bir Y-tween eklendi: kutu artık
`land_pos.y - 700px`'ten (ekran dışı yukarı) başlayıp, `IMPACT_FRAME/FPS` (~0.71sn)
süresinde `land_pos.y`'ye düşüyor (`TRANS_QUAD`/`EASE_IN`) — animasyonun kendi kareleriyle
SENKRON, çarpma anında (10. kare) hem animasyon hem gerçek pozisyon aynı ana denk geliyor.
**Boyut küçültüldü**: `CRATE_SPRITE_SCALE` 1.8 → **1.3** (kullanıcı: "biraz küçültebilir
miyiz"). **Gölge mimarisi düzeltildi**: gölge artık kutunun child'ı DEĞİL — kutu havada
hareket ederken gölgenin YERDE (`land_pos`) sabit kalması gerektiği için kutuyla aynı
parent'a (`game_scene`) ekleniyor, `global_position` ile land_pos'a sabitleniyor. Kutu
`queue_free()` olunca (`tree_exiting` sinyali) gölge de birlikte temizleniyor, sızıntı yok.

## Boss intro sandığı — kesin frame zamanlaması, büyütme, gölge + gerçek 10sn tetikleme (2026-09-30, aynı gün devamı)

Kullanıcı sprite'ı kare kare izleyip kesin zamanlamayı verdi: **0-9 düşüş, 10 çarpma,
14 ilk kırılma, 25 boss artık deliklerden görünür hale geliyor** (37 kare toplam).
`crate_intro.gd`'deki tahmini `%35` oranı bu kesin sayılarla değiştirildi:
`IMPACT_FRAME=10` ("landed" sinyali → kamera sarsıntısı), `VISIBLE_FRAME=25`
("boss_emerged" sinyali → gerçek boss spawn'ı artık animasyon TAM bitmeden, 25. karede
tetikleniyor — `game_scene.gd::_on_boss_emerged()` bu sinyali alınca kutuyu 0.3sn'de
soldurup siliyor, kalan ~11 kare bu solma sırasında görsel olarak örtüşüyor, "boss
deliklerden görünüyor" hissini pekiştiriyor). `CRACK_FRAME=14` şimdilik sadece bilgi
amaçlı sabit, ayrı bir tetikleme yok.

**Boyut büyütüldü**: kullanıcı "çok küçük" dedi — `CRATE_SPRITE_SCALE=1.8` sabiti eklendi,
`AnimatedSprite2D.scale` buna set ediliyor.

**Düşüş gölgesi eklendi**: `_setup_fall_shadow()`/`_update_fall_shadow(frame)` — kutunun
altına sabit bir elips (`Polygon2D`, z_index=-1, kutunun altında kalıyor), 0. karede
`scale=0.15`'ten başlayıp 10. kareye (çarpma anı) kadar `1.0`'a büyüyor, sonrasında sabit
kalıyor — "düşerken küçükten büyüyen gölge" isteğine birebir. Gölgenin dikey konumu
(`position.y = 62 * CRATE_SPRITE_SCALE`) tahmini bir değer, sprite'ın gerçek taban
noktasına göre oyunda ince ayar gerekebilir.

### Boss zamanlaması gerçek 10 saniyeye sabitlendi, level-up ekranından bağımsızlaştı
Kullanıcı: "level up ekranını kapatır kapatmaz boss geliyor, anlaşılmıyor — normalde
10. dakikada sorun olmuyordu, bunu direkt 10. saniyeye sabitleyelim." Eski debug
yaklaşımı (`_on_upgrade_selected()`'da "ilk kart seçilince hemen") kaldırıldı — bunun
yerine oyunun **gerçek** (`elapsed_time`, `_process()`'te her frame `delta` ile artan,
`get_tree().paused` iken donan) süre sayacına bağlı yeni bir kontrol eklendi:
`if not _debug_boss_triggered and elapsed_time >= 10.0: ... _start_boss_intro()`.
Bu, normal `BOSS_SPAWN_TIME=600.0` (10 dakika) mekanizmasının BİREBİR aynısı, sadece
süre 10 saniyeye çekilmiş hâli — level-up ekranının ne zaman kapatıldığından tamamen
bağımsız, ne zaman geleceği net (oyun süresinin 10. saniyesi). `_debug_boss_triggered`
bayrağı eklendi (eski `_debug_first_upgrade_done`'ın yerine geçti). **Test bitince bu
blok (+ `_debug_boss_triggered` değişkeni) kaldırılmalı**, `BOSS_SPAWN_TIME` zaten
600.0'da bırakıldı (dokunulmadı) — sadece debug'daki paralel 10sn kontrolü kaldırılacak.

## Boss intro sandığı gerçek sprite'a bağlandı (2026-09-30, oyunda denenmedi)

`crate_intro.gd` eskiden tamamen `_draw()` ile procedural çiziliyordu (ahşap tahtalar,
metal köşe bantları, kapak açılıp uçması, boss'un kırmızı gözlerinin yükselmesi — hepsi
kod içinde geometrik şekillerle). Kullanıcı Pixellab'de düşüş+çarpma+parçalanma temalı
tek sürekli bir animasyon ürettirdi, `assets/VFX/bossCrate/frame_000..036.png` (37 kare,
168×168) olarak eklendi.

**Yapılan**: `play_intro(land_pos)` artık önce sprite'ı arıyor
(`ResourceLoader.exists("res://assets/VFX/bossCrate/frame_000.png")`) — varsa
`_play_intro_sprite()`, yoksa eski procedural sekans `_play_intro_fallback()`'e
(fonksiyon adı değişti, davranışı BİREBİR aynı, silinmedi) düşüyor. Sprite yolu:
`AnimatedSprite2D` (14fps, non-loop, 37÷14≈2.6sn), `land_pos`'ta sabit duruyor (Y ekseni
tween'i yok — düşüş hareketi artık animasyonun kendi kareleri içinde, prompt'ta
"frame 1-3 düşüyor" diye tarif edilmişti). Kamera sarsıntısını tetikleyen `"landed"`
sinyali animasyonun **~%35'lik frame'inde** (`int(total * 0.35)`, çarpma anına denk
gelmesi beklenen tahmini nokta) ateşleniyor, `"boss_emerged"` (asıl boss spawn'ı) ise
animasyon TAMAMEN bitince.

**Test edilmesi gereken/kesin olmayan nokta**: `%35` çarpma tahmini gerçek sprite'ı
görmeden yapıldı (prompt'taki "10 kavramsal karenin 4.'sü impact" oranından
hesaplandı) — oyunda test edilip kamera sarsıntısının gerçek çarpma anıyla eşleşip
eşleşmediği kontrol edilmeli, tutmazsa `_impact_frame` oranı (`0.35`) ayarlanabilir.

## DEBUG: Cyber-404 boss'u artık ilk level'dan sonra hemen geliyor (2026-09-30, test için)

Kullanıcı sadece Cyber-404'ü (bölüm sırasındaki 3 boss'tan ikincisi — Smiler → Cyber404
→ Nyx, `_spawn_section_boss()`'taki `_boss_check_index` sırası) test etmek istedi, normal
akışta boss'lar her bölümde **10. dakikada** (`BOSS_SPAWN_TIME=600.0`) geliyor — test için
o kadar beklemek gerekmesin diye kısayol eklendi.

`_on_upgrade_selected()`'a (`level += 1`'in hemen altına) eklendi: ilk kart seçilince
doğrudan `_start_boss_intro()` çağrılıyor (Smiler/Nyx dispatch zincirini atlayıp —
`_spawn_boss_at()` zaten koşulsuz `cyber_404_scene` instantiate ediyor, ayrı bir branch
gerekmedi), `_cyber404_spawned` + `_boss_spawned` true'ya çekiliyor (normal 10dk'lık
zamanlayıcı bir daha tetiklenmesin, aynı testte ikinci bir boss gelmesin diye).

**BUG FIX**: ilk denemede `level == 1` kontrolü kullanılmıştı ama `level` değişkeni
(`game_scene.gd:7`) zaten **1'den başlıyor** — ilk kart seçiminde `level += 1` ile
**2** oluyor, `level == 1` hiçbir zaman tutmuyordu, boss hiç gelmiyordu (kullanıcı test
edip fark etti). Yeni `_debug_first_upgrade_done: bool` bayrağı eklendi, sayıya bağımlı
olmadan "bu run'da ilk kart mı seçildi" kontrolü buradan yapılıyor.

**Test bitince bu blok (+ `_debug_first_upgrade_done` değişkeni) kaldırılmalı**, kalıcı
build'e sızmamalı.

## BUG FIX: Ayarlar ekranındaki bazı puntolar Silver'ın 19px ızgarasına hiç oturmamıştı (2026-09-30, oyunda denenmedi)

Kullanıcı: "Kontroller kısmındaki yazı aşırı küçük, okunmuyor." Kontrol edilince: Silver
font'a geçiş sırasında (2026-09-25, `19 * max(1, round(eski*1.46/19))` formülü) `main_menu.gd`
içindeki **ayarlar ekranını kodla üreten** `_build_controls_tab`/`_build_audio_tab`/
`_build_display_tab`/`_build_language_tab` fonksiyonlarındaki `_add_label(...)` çağrıları
gözden kaçmış — bunlar `.tscn`'deki `theme_override_font_sizes` taramasına dahil değildi
(dinamik olarak runtime'da Control ağacı kuruluyor), formül hiç uygulanmamıştı. Silver'ın
gerçek piksel ızgarası 19px olduğu için 12-18 arası boyutlar bulanık/eksik glyph
render ediyordu.

**Fix — hepsi 19'a çekildi**:
- Kontroller sekmesi: sütun başlıkları (13→19) + tuş satırları (15→19).
- Ses sekmesi: bus etiketleri (16→19).
- Display sekmesi: "Çözünürlük" başlığı (16→19), "Tam Ekran" başlığı (16→19), alt not (12→19).
- Dil sekmesi: başlık (18→19), alt not (12→19).

`add_theme_font_size_override("font_size", ...)` ile doğrudan set edilen yerler (buton
metinleri, slider değer etiketleri vb.) zaten 19/38/95 gibi doğru katlardaydı — sadece
`_add_label()` helper'ına geçilen ham sayı parametreleri (tscn taramasının kapsamı
dışında kaldığı için) kaçmıştı. Aynı kaçak başka bir ekranda varsa (kod ile üretilen,
`.tscn`'de görünmeyen Control ağaçları) aynı yöntemle kontrol edilmeli.

## Cyclone Calamity sesleri bağlandı (2026-09-30, oyunda denenmedi)

Kullanıcı `assets/sfx/calamitys/cyclone/` altına Cyclone'un 8 Calamity'sinin hepsi için
ses ekledi (Data Storm, Backdoor, Bounce Barrage, Mirror Image, Systemic Failure,
Glitch Field, System Crash — dosya adı `systemChrash.ogg` yazım farkıyla, sorun değil —
Decay Field). Python `soundfile` ile hepsinin gerçek Ogg Vorbis olduğu doğrulandı (Convertio
dışındaki sitelerden yapılanlar dahil, hiçbiri FLAC çıkmadı — çevirmeye gerek kalmadı).
Süreler mekaniklerle uyumlu (Decay Field 5.08sn ≈ 5sn'lik alan süresi, diğerleri anlık
tetiklenen kartlar oldukları için tek seferlik çalıyor, süre tam eşleşmesi gerekmiyor).

Vector/Leila Calamity'leriyle aynı desen — her `_activate_X()` fonksiyonunun başında
`Sfx.play_path("res://assets/sfx/calamitys/cyclone/<dosya>.ogg")`:
- `_activate_data_storm()` → `dataStorm.ogg`
- `_activate_backdoor()` → `backdoor.ogg`
- `_activate_systemic_failure()` → `systemicFailure.ogg`
- `_activate_bounce_barrage()` → `bounceBarrage.ogg` (10sn — kartın 5sn'lik buff'ından
  uzun, ama tek seferlik çaldığı için sorun değil, sonradan kısaltılabilir)
- `_activate_mirror_image()` → `mirrorImage.ogg`
- `_activate_glitch_bomb(pos)` → `glitchField.ogg`
- `_activate_system_crash()` → `systemChrash.ogg`
- `_activate_decay_field(pos)` → `decayField.ogg`

Data Storm/Backdoor/Systemic Failure/System Crash "The Yard Engine" ortak makinesini
kullanıyor ama sesleri ayrı ayrı (fonksiyon başında) çalınıyor — makinenin kendi ateşleme
sesi (`yardEngineImpact.ogg`) zaten `_vfx_yard_engine()`'in içinde ayrıca çalıyordu,
bu ikisi üst üste biniyor (Vector'daki desenle aynı, sorun değil).

**DEBUG**: test için Cyclone'un ilk 3 Calamity'si (💾 Data Storm / 👾 Backdoor / 🎱 Bounce
Barrage) `_ready()`'de otomatik slota ekleniyor (eski Leila Thunderstorm/Wildfire debug
bloğunun yerine geçti). **Test bitince bu blok kaldırılmalı.**

### Bounce Barrage (138, Cyclone) süresi 5sn → 10sn (kullanıcı kararı, 2026-09-30)
`bounceBarrage.ogg` aslında Vector'dan alınmış bir ses (kullanıcının kendi ifadesiyle) —
Vector'da bu ses Momentum Burst'ün 10sn'lik `electrify_weapon(10.0)` süresine göre
seçilmişti, ses dosyasının kendisi de 10.02sn. Cyclone'un Bounce Barrage'ı ise 5sn'de
kalmıştı — ses dosyasının yarısında kesiliyordu. Kullanıcı: "5 saniye az olmuş, Vector
gibi 10 saniye yapalım" — `_activate_bounce_barrage()`'daki `p.bounce_barrage_timer` ve
`$BallLauncher.electrify_weapon()` ikisi de 5.0 → 10.0 yapıldı, kart açıklaması (EN
`upgrades` dizisi + TR `lang.gd` index 138) "5s" → "10s" olarak güncellendi. Mekanik
(top hızı ×3) değişmedi, sadece süre uzadı.

## Küçük dil/UX bug fix turu (2026-09-29, aynı gün devamı) — oyunda denenmedi

Kullanıcı 3 sorun bildirdi:
- **Ayarlar → Display'de "Çözünürlük" iki dilde de aynıydı**: `main_menu.gd`'de
  `Lang.t(...)` yerine düz string ("Çözünürlük") yazılmıştı — tek yerdeki tek istisnaydı,
  aynı ekrandaki diğer tüm etiketler (`set_display_fs` vb.) zaten doğru kullanıyordu.
  `lang.gd`'ye `set_display_resolution` (TR: "ÇÖZÜNÜRLÜK", EN: "RESOLUTION") eklendi,
  `main_menu.gd:526` buna bağlandı. **Yan bulgu**: `set_display_note`'un metni de
  ("* Çözünürlük ayarı ileriki güncellemede eklenecek." / "Resolution settings coming in
  a future update.") eskiydi — çözünürlük seçimi zaten uzun süredir çalışıyor (bkz.
  `güncelleme notları.txt`), not güncellenmedi kalmıştı. "* Tam ekran açıkken çözünürlük
  değiştirilemez." / "* Resolution cannot be changed while fullscreen is on." olarak
  düzeltildi (gerçek kısıtlamayı — `_apply_resolution` fullscreen'de çalışmıyor — anlatan
  daha doğru bir not).
- **Karakter seçim ekranı "SELECT YOUR CHARACTER" iki dilde de aynıydı**: başlık
  `character_select.tscn`'de (`Label` node, satır 218) doğrudan sabit metin olarak
  yazılmıştı, hiç `Lang.t()`'e bağlı değildi. `lang.gd`'ye `cs_title` eklendi (TR:
  "KARAKTERİNİ SEÇ", EN: "SELECT YOUR CHARACTER"), `character_select.gd::_ready()`'ye
  `$Label.text = Lang.t("cs_title")` eklendi.
  **Kontrol edilip bug OLMADIĞI doğrulanan**: kullanıcının işaret ettiği "sıradaki ödül"
  metni (`cs_next_unlock` + `GameData.get_unlock_for_level()`'den gelen "Piercing Ball"/
  "Crusher Fusion" gibi isimler) — bunlar kart/core isimleri, proje kuralı gereği
  ("kart isimleri her zaman İngilizce kalır") bilerek her iki dilde de İngilizce kalıyor,
  düzeltme gerekmiyor.
- **Başarımlar ekranında Collect'e basınca scroll en üste sıçrıyordu**:
  `character_select.gd::_open_achievements()` her Collect tıklamasında TÜM ekranı
  (`canvas.queue_free()` + yeniden `_open_achievements()` çağrısı) sıfırdan inşa ediyordu
  — yeni `ScrollContainer` her zaman `scroll_vertical=0`'dan başlıyordu. Fix:
  `_open_achievements(restore_scroll: int = 0)` parametresi eklendi, Collect butonunun
  callback'i tıklama anındaki `scroll.scroll_vertical` değerini yakalayıp yeniden
  açılışta bu değeri geri veriyor (`call_deferred` ile — `ScrollContainer` layout'u bir
  frame sonra kesinleştiği için anlık set tek başına yetmeyebilir, ikisi birden
  uygulandı).

## Herkese Açık (Ortak) Kartlar — Review TAMAMLANDI (2026-09-23)

Kullanıcı xlsx üretimi sonrası "bu genel kartlara baktık mı?" diye sordu — `"chars": []`
ile işaretli, hiçbir karaktere özel olmayıp tüm karakterlerin havuzunda görünen 5 kart:
**Speed Upgrade (4)**, **Max Health Up (21)**, **Medkit (20)**, **Core Mastery (11)**,
**Chain Extension (224)**. Hepsi kontrol edildi:
- **Core Mastery (11)**: zaten bu session'da kapsamlı incelenmişti (bkz. "KRİTİK PROJE
  ÇAPINDA BUG FIX" ve "Core Mastery hiç çalışmıyordu" bölümleri) — tekrar dokunulmadı.
- **Max Health Up (21)**, **Medkit (20)**: implementasyon doğru (+5 Max HP/+5 heal,
  +10 heal), EN/TR ikisi de zaten doğruydu.
- **Speed Upgrade (4) — BUG FIX**: `player.SPEED += 50` (implementasyon doğru) ama EN
  `desc` alanı Türkçe yazılmıştı ("Kalıcı: Hareket hızı +50"), TR girdisi de belirsiz/
  sayısız bir ifadeydi ("Hareket hızı artar" — +50 sayısı hiç geçmiyordu). İkisi de
  düzeltildi: EN "Permanent: Movement Speed +50", TR "Kalıcı: Hareket hızı +50".
- **Chain Extension (224)**: bir önceki turda (xlsx üretimi sırasında) zaten bulunup
  düzeltilmişti (bkz. yukarıdaki commit notu).

Hiçbiri karaktere özel bir core'a bağlı olmadığı için `requires` gerekmiyor (zaten yoktu,
doğru). xlsx dosyaları Speed Upgrade düzeltmesini yansıtacak şekilde yeniden üretildi.

## Momentum Burst (176, Vector) — Yard Engine + silah elektriklenmesi (2026-09-24)

Kullanıcı, VFX'i olmayan Calamity'ler sorulunca **Momentum Burst**'ü işaret etti — Vector
"The Yard Engine" ortak makinesini (Backdoor/Systemic Failure/System Crash'in kullandığı)
hiç kullanmıyordu. İstenen: makineden Vector'un silahına elektrik akımı gitsin, süre
boyunca silahta da elektriklenme (hız arttığı belli olsun) görünsün.

**`ball_launcher.gd` genelleştirildi** — eskiden `electrify_weapon()`/`play_weapon_burst()`
sadece `_cyclone_weapon_anim`'e (Cyclone'un AnimatedSprite2D silahı) çalışıyordu, Bounce
Barrage için yazılmışlardı. Yeni `_get_active_weapon_node()` helper'ı o an ekranda hangi
karakterin silahı varsa onu döndürüyor (Cyclone/Leila: AnimatedSprite2D, Vector:
Sprite2D — `speed_scale` sadece AnimatedSprite2D'de var, kontrol ediliyor). Yeni
`get_weapon_position()` — VFX'lerin hedef alması için silahın o anki dünya pozisyonu.
`electrify_weapon()` artık hangi node olursa olsun (parçacık + pulse eden modulate)
uygulanabiliyor, `play_weapon_burst()` (tek seferlik patlama) sadece AnimatedSprite2D
silahlarda çalışıyor (Vector'un statik Sprite2D'si animasyon oynatamadığı için bilerek
dışarıda bırakıldı — Momentum Burst zaten bunu çağırmıyor, sadece `electrify_weapon`).

**`_activate_momentum_burst()` yeniden yazıldı** — `_vfx_yard_engine()`'in aynı deseni
(makine belirir, son 2 frame'de tetikleme) ama tek hedefli özel bir versiyon: sahadaki
düşmanlara değil, **doğrudan Vector'un silahına** (`launcher.get_weapon_position()`) tek
bir cyan/elektrik `_vfx_engine_bolt()` çizgisi gidiyor. Çizginin ulaştığı an (mekanik
DEĞİŞMEDİ): stack'ler tüketiliyor, `momentum_burst_bonus` hesaplanıyor, ardından
`electrify_weapon(10.0)` çağrılıp silah 10sn boyunca (bonus süresiyle birebir) kıvılcım
saçıyor + pulse ediyor — hız artışının görsel karşılığı. Sprite yoksa eski davranışa
(ekran flaşı) düşüyor, crash yok.

**DEBUG override (test için, `_ready()`'de)**: 3 slot da "💨" (Momentum Burst) ile
dolduruluyor, `has_momentum_engine=true` + `momentum_stacks=20` set ediliyor (Momentum
Engine hiç almadan da kart hemen test edilebilsin diye). **Test bitince bu blok
kaldırılmalı**, kalıcı build'e sızmamalı — eskiden bu blokta Leila'nın Wildfire testi
duruyordu, o kaldırılıp yerine bu geldi.

**Test sırasında bulunan gerçek bug — düzeltildi (2026-09-24)**: Vector'un silahındaki
kıvılcım parçacıkları hiç görünmüyordu, çünkü sabit `z_index=8` veriliyordu ama Vector'un
silah sprite'ı (`_weapon_sprite`) `z_index=15` ile çiziliyor — parçacıklar silahın
ARKASINDA kalıp görünmez oluyordu. (Cyclone'un silahı z=7 olduğu için Bounce Barrage'da
bu sorun hiç fark edilmemişti, tesadüfen doğru sıradaydı.) Fix: parçacık z_index'i artık
`target.z_index + 1` olarak dinamik hesaplanıyor, hangi karakterin silahı olursa olsun
her zaman önde kalıyor. Parçacık sayısı/hızı da (14→22, hız 20-60→30-90) biraz
güçlendirildi, daha net görünsün diye.

**2./3. basışta hiç VFX oynamaması — BUG DEĞİL, mekaniğin kendisi**: Momentum Burst
TÜM stack'i harcayıp sıfırlıyor (`p.momentum_stacks = 0`). Debug momentum_stacks'i
sadece `_ready()`'de BİR KEZ 20'ye set ediyor — ilk kullanımdan sonra 0'da kalıyor,
tekrar dolması için normal oyun mekaniği gereği **yürümek** gerekiyor (Momentum
Engine: yürürken her 4sn +1 stack). `if stacks <= 0: return` satırı EN BAŞTA kontrol
edildiği için stack yokken fonksiyon hiçbir VFX'e (motor/bolt/silah) ulaşmadan hemen
çıkıyor — "birikmiş bir durum" değil, tam tersi, harcanmış durumda. Test sırasında
iki kullanım arasında biraz yürümek gerekiyor.

## Full Breach (175) — ekran flaşı kaldırıldı (2026-09-24, kullanıcı test sonrası karar)

`_react_flash_screen(Color(1.0, 0.2, 0.1, 0.5))` çağrısı silindi — sprite VFX
(`_vfx_full_breach_burst`, aura parçacıkları) + `screen_shake_heavy()` zaten yeterli
geri bildirim veriyordu, kırmızı flaş fazlaydı. (Rampart Collapse'ta daha önce aynı
kararla mavi flaş kaldırılmıştı — aynı desen.)

## Yard Engine — alan/nokta hedefli Calamity'lere genelleştirildi (2026-09-24)

Kullanıcı isteği: alan etkili (oyuncunun tıkladığı bir noktayı hedefleyen) Calamity'ler
de Yard Engine'e bağlansın — makine belirsin, tıklanan noktaya Calamity'nin kendi renk
paletine uyan bir elektrik çizgisi göndersin, çizgi ulaşınca kartın asıl VFX'i (örn.
Gravitational Force'un vorteksi) orada başlasın.

**Yeni paylaşımlı fonksiyon: `_vfx_yard_engine_to_point(get_target_pos, bolt_color,
on_arrival, fallback_fn)`** (`game_scene.gd`) — `_vfx_yard_engine()`'den (düşman listesine
çoklu bolt gönderen versiyon) farklı olarak SERBEST bir tek noktaya tek çizgi gönderiyor.
`get_target_pos` bir `Callable` (`Vector2` döndürür) — hedef pozisyon makine animasyonu
oynarken (yaklaşık 1sn) hâlâ değişebilir diye (örn. oyuncu hareket ediyorsa silah
pozisyonu), çizgi ateşlenirken YENİDEN okunuyor, spawn anında sabitlenmiyor. Sprite
yoksa `fallback_fn` çağrılır (kendi ekran flaşı + asıl etkiyi tetiklemesi gerekiyor).

**Momentum Burst (176) refactor edildi** — eskiden kendi içinde tekrarlayan ~50 satırlık
makine/bolt kodu vardı, şimdi bu paylaşımlı fonksiyonu çağırıyor (davranış aynı, sadece
kod tekilleşti).

**Gravitational Force (9) — Yard Engine'e bağlandı**: `_activate_gravity(pos)` artık
önce makineyi çağırıyor (mor/violet `Color(0.65, 0.1, 1.0)` — kartın kendi parçacık
rengiyle aynı), çizgi tıklanan noktaya ulaşınca `_vfx_gravity(pos)` + 5sn'lik çekim
mekaniği başlıyor. Önceden VFX/etki tıklar tıklamaz anında başlıyordu, artık makine
animasyonu kadar (~1-1.3sn) bir "hazırlanma" gecikmesi var — kullanıcı test edip
zamanlamayı onaylamalı.

**Henüz bağlanmayan diğer alan/nokta hedefli Vector Calamity'leri**: Siege Rain (199,
kendi "düşen meteor" görsel dilini zaten kullanıyor) ve Rampart Collapse (177, kendi
şarj+fırlatma+patlama sistemi zaten var) — ikisi de kendi VFX kimliğine sahip, Yard
Engine'e bağlamak mantık değiştirir. Kullanıcıya bunlar için de istenip istenmediği
sorulacak, henüz dokunulmadı.

**WormHole (198) — Yard Engine'e bağlandı (2026-09-24)**: `_activate_wormhole()` da
aynı desene geçirildi. Bolt rengi mor (`Color(0.4, 0.0, 0.8)` — WormHole'ün kendi
rengi). Fonksiyonun sonundaki eski `_react_flash_screen(Color(0.4, 0.0, 0.8, 0.3))`
kapanış flaşı kaldırıldı — artık makinenin kendi giriş/çıkış animasyonu yeterli
görsel kapanış hissi veriyor, ayrı bir flaşa gerek kalmadı. 45 frame'lik gerçek
sprite VFX kullanıcı tarafından eklendi (`_vfx_wormhole_open()` zaten dinamik
`while ResourceLoader.exists(...)` ile yüklüyordu, kod tarafında değişiklik
gerekmedi).

### WormHole artık tıklamalı (kullanıcı kararı, 2026-09-24) + tüm hedefli Calamity'ler Avlu'ya kilitlendi
Kullanıcı: "WormHole karakterin çevresinde değil, istediğimiz yerde (Yard içinde)
açılsın" + "diğer tüm alan etkili skillerde mouse Yard dışına çıkmasın" dedi. İki
değişiklik:
- **WormHole hedefleme deseni değişti**: `_activate_wormhole()` artık `target_pos:
  Vector2` parametresi alıyor (Gravitational Force/Rampart Collapse ile aynı desen),
  eskiden `player.aim_direction × 120px` ile oyuncunun ÖNÜNE sabit açılıyordu, artık
  tıklanan noktaya açılıyor. Nişan önizleme çemberindeki WormHole'e özel "oyuncunun
  önüne sabitle" override'ı (`elif calamity == "🕳️": ... player.global_position +
  aim_direction × 120`) silindi — artık diğer hedefli Calamity'ler gibi doğrudan
  mouse pozisyonunu takip ediyor. Kart açıklaması "around Vector" → "at the targeted
  point" olarak güncellendi (EN+TR).
- **Yeni merkezi `_clamp_to_yard(pos: Vector2) -> Vector2` helper'ı** (`game_scene.gd`,
  `_yard_subjects()`'in hemen üstünde) — Avlu dikdörtgenine (x:385-1920, y:255-1080,
  projede zaten tekrar eden sabit değerler) kilitliyor. İki yere bağlandı: (1)
  `_consume_calamity()` — gerçek aktivasyon pozisyonu artık HER ZAMAN kilitli, mouse
  Avlu dışındaysa (cadde/tribün) en yakın Avlu kenarına clamp'leniyor; (2) `_process`
  içindeki nişan önizleme çemberi — çember de aynı şekilde kilitleniyor, oyuncu neyi
  göreceğini önceden biliyor (önizleme ile gerçek sonuç arasında sürpriz yok). Bu,
  Vector'un Gravitational Force/Rampart Collapse/WormHole'ü ve diğer karakterlerin
  tüm hedefli Calamity'lerini (Lightning, Flame Zone, Volcanic Rift, Siege Rain,
  Glitch Field, Decay Field) kapsıyor — hepsi aynı merkezi noktadan geçiyor.

## Sağ Panel — Fusion Energy kaldırıldı, Calamity yukarı taşındı + süreli Calamity
geri sayımı eklendi (2026-09-24)

Kullanıcı ekran görüntüsü paylaştı: sağ panelde "⚡ FUSION ENERGY" başlığı boş bir
alanı işgal ediyordu. Kontrol edilince gerçek sebep bulundu: **Fusion Zone mekaniği
ITY 2'ye ertelenmiş** (`_ready()`'deki eski yorum: "Fusion Zone şimdilik tüm
karakterler için kapalı"), `$UI/FusionEnergyBar` zaten `visible=false` yapılıyordu
ama `$UI/LabelFusionEnergy` (başlık) unutulmuş, hâlâ görünürdü — ekrandaki boşluğun
gerçek sebebi buydu.

- **`$UI/LabelFusionEnergy.visible = false`** eklendi (`_ready()`).
- **`LabelCalamity`** (Calamity başlığı) `game_scene.tscn`'de y:612→**506**'ya taşındı
  (Fusion Energy başlığının eski yerine, kutu boyu da 612-842'den 506-530'a
  küçültüldü — eskiden kartın açıklamasını da içeren eski bir tasarımdan kalma
  gereksiz büyüklükteydi, artık sadece başlık tutuyor).
- **`_setup_calamity_cells()`**'teki `CAL_PY` sabiti 636→**530** (hücreler başlığın
  hemen altında).
- **Yeni: süreli Calamity geri sayımı**. `_calamity_timer_label` (yeni Label,
  hücrelerin 8px altında, y≈578) her frame (`_process` → `_update_calamity_timer_label()`)
  güncelleniyor. `_CALAMITY_TIMER_DEFS` sabiti (player.gd'deki hangi `_xxx_timer`
  değişkeninin hangi karta ait olduğunu eşliyor): Full Breach (`_full_breach_timer`),
  Momentum Burst (`_momentum_burst_timer`), Bounce Barrage (`bounce_barrage_timer`) —
  şu an projede sadece bu 3 Calamity'nin "bitiş süresi olan kalıcı buff" tarzı bir
  `player.gd` değişkeni var (diğerleri ya anlık ya da kendi coroutine'i içinde yerel
  `duration`/`elapsed` kullanıyor, dışarıdan okunamıyor). Aynı anda birden fazlası
  aktifse (örn. Full Breach + Momentum Burst üst üste kullanılırsa) hepsi alt alta
  satır satır gösteriliyor: "Full Breach = 5s\nMomentum Burst = 12s" gibi. İsimler
  kart-adı kuralı gereği hep İngilizce (locale'den bağımsız).
- DataBar (XP/upgrade ilerleme çubuğu, y=698) ve altındaki "DATA HARVESTED"/"0 units"
  etiketlerine dokunulmadı — yeterli boşluk vardı, çakışma riski yok.

**AÇIK KONU ÇÖZÜLDÜ (2026-09-30 doğrulandı)**: yukarıdaki "sağ panel dil tutarsızlığı"
notu artık geçersiz — aynı 2026-09-25 turunun bir parçası olarak "Fırlatılabilir Core'lar"/
"Launchable Cores", "Bağlı Core'lar"/"Connected Cores", "— FELAKET —"/"— CALAMITY —",
"— GELİŞTİRMELER —"/"— UPGRADES —", "TOPLANAN VERİ"/"DATA HARVESTED", " birim"/" units",
"CORE'LAR"/"CORES" hepsi zaten `Lang.t()` üzerinden ayrışmıştı. `ui_upgrades_chain`
("▸ Zincir Artışı") anahtarı da Geliştirmeler listesi dinamikleştirilirken zaten
silinmişti (bkz. yukarıdaki "Sağ panel: Geliştirmeler listesi + core sayacı düzeltildi"
bölümü). Not sadece o zaman güncellenmemiş kalmıştı, kullanıcı sorunca kontrol edilip
kapatıldı — ek bir iş gerekmiyor.

## Vector Calamity — Yard Engine + VFX/UI turu TAMAMLANDI (2026-09-24)

Kullanıcı Vector'un 7 Calamity'sini (Gravitational Force, Shockwave, Full Breach,
Momentum Burst, Rampart Collapse, WormHole, Siege Rain) tek tek test etti, hepsi
onaylandı. Bu turda yapılanların özeti:
- Momentum Burst + Gravitational Force + WormHole artık "The Yard Engine" makinesini
  kullanıyor (bkz. yukarıdaki ilgili bölümler) — Momentum Burst silaha, diğer ikisi
  tıklanan/hesaplanan noktaya elektrik gönderiyor.
- Full Breach ve WormHole'ün gereksiz kapanış ekran flaşları kaldırıldı.
- WormHole tıklamalı hale geldi (eskiden oyuncunun önüne sabitti), tüm hedefli
  Calamity'ler Avlu sınırına kilitlendi (`_clamp_to_yard()`).
- Sağ paneldeki ölü "Fusion Energy" alanı Calamity başlığı/hücrelerine devredildi,
  süreli buff'lar (Full Breach/Momentum Burst/Bounce Barrage) için canlı geri sayım
  eklendi.
- **Siege Rain (199) — açıklama bug'ı bulundu ve düzeltildi**: kart açıklaması hâlâ
  redesign-öncesi değerleri gösteriyordu ("7sn, her 0.5sn'de bir") — gerçek kod uzun
  süredir "14sn, her 1sn'de bir" olarak çalışıyordu, açıklama hiç güncellenmemişti.
  EN+TR düzeltildi.
- Vector Calamity test turunda kullanılan tüm DEBUG override'ları (`_ready()`'deki
  calamity_slots/momentum_stacks bloğu) **temizlendi**, kalıcı build'e sızmıyor.

**AÇIK/BEKLEYEN İŞLER**:
- Siege Rain ve Rampart Collapse henüz Yard Engine'e bağlanmadı (ikisinin de kendi
  VFX kimliği var, kullanıcı isterse ayrıca konuşulacak).
- Sağ panelin dil tutarlılığı (TR/EN karışık kullanım + "Zincir Artışı" gibi kart-adı
  çeviri hatası) henüz ele alınmadı, kullanıcıdan yön kararı bekleniyor.
- `_CALAMITY_TIMER_DEFS`'e şu an sadece 3 Calamity var (Full Breach/Momentum Burst/
  Bounce Barrage) — diğer süreli etkiler (Gravitational Force'un 5sn çekimi, Siege
  Rain'in 14sn'si vb.) kendi coroutine'lerinde yerel değişken kullandığı için bu
  sisteme henüz bağlı değil, istenirse ayrı bir refactor gerekir.

## Momentum Burst — Yard Engine GERİ ALINDI, Bounce Barrage deseni (2026-09-24)

Kullanıcı kararıyla Momentum Burst'ün Yard Engine bağlantısı iptal edildi —
`_activate_momentum_burst()` artık Cyclone'un Bounce Barrage'ıyla BİREBİR aynı
desende: makine/bolt beklemeden anında `electrify_weapon(10.0)` + `play_weapon_burst()`
çağırıyor. `play_weapon_burst()` sadece AnimatedSprite2D silahlarda (Cyclone/Leila)
çalıştığı için Vector'da (Sprite2D) sessizce no-op oluyor — Vector'da sadece sürekli
kıvılcım+pulse (`electrify_weapon`) kalıyor, tek seferlik patlama sprite'ı yok (zaten
Bounce Barrage'ın kendi patlaması da sadece AnimatedSprite2D silahlarda çalışıyordu,
aynı kısıtlama). `_vfx_yard_engine_to_point()` helper'ı hâlâ duruyor — Gravitational
Force ve WormHole tarafından kullanılmaya devam ediyor, sadece Momentum Burst
kaldırıldı.

## Data Storm (129, Cyclone) — BUG FIX: genel geri bildirim yoktu, Yard Engine'e bağlandı (2026-09-24)

Kullanıcı test edip doğru tespit etti: Data Storm'da hiçbir genel (ekran seviyesinde)
geri bildirim yoktu. Kontrol edilince: `_activate_data_storm()` sahadaki Glitched
düşmanları tek tek gezip her birinde küçük, lokal bir patlama sprite'ı
(`_vfx_data_storm_burst`, gerçek ve çalışıyor) oynatıyordu ama **hiçbir shake/flash
çağrısı yoktu** — sahada Glitched düşman yoksa kart tamamen SESSİZCE hiçbir şey
yapmadan tüketiliyordu (görsel/işitsel sıfır onay).

**Fix**: `_activate_data_storm()` artık "The Yard Engine" ortak makinesini kullanıyor
(`_vfx_yard_engine(_vfx_data_storm_burst, Color(0.7, 0.0, 0.8, 1.0), Color(0.7, 0.0,
0.8, 0.4), _is_glitched)` — Data Storm'un kendi rengiyle, `_is_glitched` filtresiyle).
Kullanıcı kararı: **shake olsun, flash olmasın** — `_vfx_yard_engine`'in sprite
mevcutken zaten flash çağırmayan, sadece `_fire_bolts` içinde `_screen_shake_strong()`
çağıran davranışı buna zaten birebir uyuyordu, ek bir değişikliğe gerek kalmadı
(flash sadece sprite dosyası EKSİKSE fallback yolunda çalışıyor, o normal koşulda
tetiklenmiyor). Yan fayda: makine artık sahada hiç Glitched düşman olmasa bile
belirip kayboluyor (bolt gönderilmese de) — "kart tetiklendi" hissi artık hiçbir
zaman sıfır olmuyor, eski sessiz-no-op bug'ı da bu sayede kendiliğinden çözüldü.

## KRİTİK BUG FIX: 14 Cyclone kartının pickup handler'ı hiç çalışmıyordu (2026-09-24)

Kullanıcı Virus Core (160) kartını seçti, hiçbir şey olmadı ("top sayısı 5 değildi,
ilk upgrade'di" — yani core limiti bug'ı değildi, gerçek bir şey kırıktı). Kaynağı
bulundu: `game_scene.gd`'de bu tip kartların (Cyclone "Rogue" bloğu) pickup
efektlerini uygulayan `match index:` ifadesi şu satırla sarılıydı:

```gdscript
elif index >= 114 and index <= 146:
    var p := get_node("Player")
    match index:
        114: ...
        ...
        163: $BallLauncher.queue_upgrade_ball("ricochet_core")
```

**Üst sınır (146) yanlıştı** — match bloğunun içinde 148'den 163'e kadar birçok
`case` vardı ama dış `elif` şartı `index <= 146` olduğu için index 146'nın ÜSTÜNDEKİ
HİÇBİR kart bu bloğa hiç girmiyordu, `match` içindeki ilgili case'ler tamamen ölü
kodtu. Muhtemelen bu kartlar zamanla eklenirken (159-163 Identity Core dalgası,
148-156 Individuality/Utility ekleri) üst sınır güncellenmeyi unutulmuş.

**Etkilenen 14 kart (hiçbiri seçildiğinde efekti uygulanmıyordu)**:
Stack Overflow (148), Viral Load (149), Memory Leak (150), Corruption Protocol (151),
Cascade Delete (152), Zero Day (154), Kernel Panic (155), Systemic Failure'ın
Calamity slotuna eklenmesi (156), Backstab Protocol (158), **Phantom Circuit Core
(159), Virus Core (160), Decay Core (161), Static Core (162), Ricochet Core (163)**.

**ÖNEMLİ NOT**: Bu kartların hepsinin kod tarafındaki gerçek MEKANİĞİ (`ball.gd`,
`base_enemy.gd` içindeki `can_X`/`has_X` bayraklarına bağlı davranış) daha önceki
review turlarında ayrıntılıca incelenip doğru bulunmuştu — ama o incelemeler sadece
"bayrak set edilirse ne olur" kısmını doğruluyordu, **bayrağın gerçekten set
edildiği pickup tetikleme yolunu** kontrol etmemiştik. Yani "implementasyon doğru"
diye onaylanan bu 14 kart aslında **hiçbir zaman gerçekten alınamıyordu** — ekran
görüntüsünde havuzda görünüp seçilebiliyorlardı ama seçilince efekt hiç
uygulanmıyordu (tıpkı kullanıcının bulduğu gibi).

**Fix**: `elif index >= 114 and index <= 146:` → `elif index >= 114 and index <= 163:`
(match bloğundaki en yüksek case değeriyle eşleşecek şekilde). Tek satırlık değişiklik,
tüm 14 kartı aynı anda düzeltti. **Kullanıcıya not**: geçmiş review turlarında bu 14
kart için "implementasyon doğru" denmişti — o değerlendirme mekanik AÇISINDAN hâlâ
geçerli, sadece "kart hiç tetiklenmiyordu" katmanı o turlarda kaçırılmıştı.

## PERFORMANS BUG FIX: Backdoor/Systemic Failure kalabalık odada kısa kasmaya sebep oluyordu (2026-09-24)

Kullanıcı: Backdoor kullandıktan hemen sonra (kalabalık düşman varken) kısa süreli bir
kasma yaşadı, ~3sn sonra Data Storm'a basınca glitchli düşman kalmamıştı.

**Kök sebep**: `_vfx_yard_engine()`'in bolt-ateşleme döngüsü (`_fire_bolts`), filtresi
olmayan (Backdoor, Systemic Failure — TÜM sahadaki düşmanları hedefleyen) Calamity'lerde
sahadaki HER düşman için **aynı frame içinde** bir `Line2D` (zigzag çizgi) + `Tween`
oluşturuyor, ayrıca `apply_fn.call()` (örn. `apply_glitch()`) de kendi içinde bir debuff
ikonu ekliyor. Kalabalık bir odada (30-40+ düşman) bu, tek frame'de onlarca node/tween/
sprite oluşturulması demek — gözle görülür bir CPU spike'ı/kasma.

**Fix**: `_fire_bolts` artık hedef listesini önce topluyor, sonra her 6 hedefte bir
`await get_tree().process_frame` ile bir sonraki frame'e geçiyor — iş birkaç frame'e
yayılıyor (60 FPS'te 30 düşman ≈ 5 frame ≈ 80ms), görsel olarak hâlâ neredeyse anlık
ama tek frame'lik spike ortadan kalkıyor. `_vfx_yard_engine()` kullanan TÜM Calamity'leri
etkiliyor (Backdoor, Systemic Failure, Data Storm, System Crash, Wildfire) — sadece
filtresiz olanlarda (Backdoor/Systemic Failure) pratikte fark yaratır, filtreli olanlar
zaten az sayıda hedefle çalışıyordu.

**İkincil gözlem (bug değil, muhtemelen zamanlama)**: Backdoor → Data Storm arasında
~3sn beklenmiş ama Data Storm'a basıldığında glitchli düşman kalmamıştı. Backdoor'un
kendi Glitch süresi **3sn'lik açık bir süre** (`apply_glitch(3.0)`, taban 2sn'lik
varsayılanın üstünde, kasıtlı) ama HEM Backdoor'un HEM Data Storm'un kendi Yard Engine
giriş animasyonu ~1.3sn sürüyor (bolt'lar animasyonun SON 2 frame'inde ateşleniyor) —
yani Backdoor'un glitch'i gerçekte ~1.3sn'de başlayıp ~4.3sn'de bitiyor, kullanıcı
Data Storm'a "~3sn sonra" bastıysa, Data Storm'un KENDİ ~1.3sn'lik giriş animasyonu
da eklenince bolt'ları gerçekte ~4.3sn işaretinde ateşleniyor — tam da glitch'in
bitiş anına denk geliyor, üstüne kasma da birkaç yüz ms yiyorsa süre kolayca kaçmış
olabilir. Kod tarafında bir hata değil, saf zamanlama — kullanıcı isterse Backdoor'un
glitch süresi (3sn → 4-5sn) artırılabilir, henüz değiştirilmedi.

## PERFORMANS BUG FIX #2: BallLauncher top fırlatacağı sırada kasma (2026-09-24, aynı gün devamı)

Kullanıcı kasmaların Calamity'lerin yanında **BallLauncher'ın sağ üstte top fırlatacağı
sırada** da olduğunu belirtti. İki ayrı kök sebep bulundu, ikisi de aynı desen
(SpriteFrames'i her seferinde sıfırdan inşa edip diskten yeniden `load()` etmek):

1. **`ball.gd::_setup_ball_sprite()`** — her top spawn'ında (her `_ready()`'de, yani
   run başında birden fazla top aynı anda kurulurken ya da run içinde yeni bir core
   alınıp `queue_upgrade_ball` ile sıraya girince) TÜM tipler için (normal top dahil!)
   `SpriteFrames.new()` + `frame_count` kadar `load()` çağrısıyla sıfırdan inşa
   ediliyordu. **Fix**: `static var _ball_sprite_frames_cache: Dictionary` eklendi
   (steam cloud VFX'teki `_steam_cloud_sf` ile aynı, zaten kanıtlanmış paylaşım deseni)
   — folder+frame_count anahtarına göre tip başına BİR KEZ inşa edilip önbelleğe
   alınıyor, sonraki her spawn'da doğrudan oradan okunuyor. Sadece ortak/basit yol
   (normal top + çoğu Identity/Connected Core) kapsandı; Ricochet Core'un 7-segmentli
   özel `rc_frames` bloğuna (top başına sadece 1 kez, ricochet core görece nadir
   olduğu için) dokunulmadı — düşük öncelik, istenirse ayrıca eklenir.
2. **`ball_launcher.gd::_update_preview_sprite()` — muhtemel asıl suçlu**: bu fonksiyon
   `_process()`'te HER FRAME çağrılıyor, sıradaki top tipi (`next_type`) değiştiğinde
   (kuyruk ilerledikçe sıkça değişebilir) aynı şekilde `SpriteFrames.new()` +
   `load()` döngüsüyle sıfırdan inşa ediyordu — **tam olarak "top fırlatılacağı sırada"
   görünen önizleme sprite'ı**. Aynı önbellekleme deseni burada da uygulandı
   (`static var _preview_sprite_frames_cache`, `ball_launcher.gd`'ye ayrı, ball.gd'nin
   içine karışmadan).

İkisi de davranışı DEĞİŞTİRMİYOR (aynı SpriteFrames içerikleri, sadece tekrar inşa
etmek yerine önbellekten okunuyor) — sadece spawn/önizleme-değişimi anındaki CPU
işini ortadan kaldırıyor.

## Yard Engine animasyonu hızlandırıldı (2026-09-24, kullanıcı: kombo yapmakta zorlanıyordu)

`_vfx_yard_engine()` ve `_vfx_yard_engine_to_point()`'teki "start"/"end" animasyon
hızı 12fps → **22fps**'e çıkarıldı (4 satır, iki fonksiyonda da aynı). 16 frame'lik
her aşama artık ~1.33sn yerine ~0.73sn sürüyor — tam bir giriş+çıkış döngüsü ~2.67sn'den
~1.45sn'ye indi. Tetikleme mantığı (son 2 frame'de bolt ateşleme) zaten frame indeksine
göre çalıştığı için otomatik olarak daha erken/hızlı tetikleniyor, ayrı bir değişikliğe
gerek kalmadı.

## Oyuncu hasar alınca beyaz flaş eklendi (2026-09-25)

Kullanıcı fark etti: düşmanlar fiziksel hasar alınca beyaz yanıp sönüyordu (2026-09-19
tarihli "Fiziksel Vuruş Geri Bildirimi" özelliği) ama **oyuncunun kendisi hasar alınca
hiçbir görsel geri bildirim yoktu**. `player.gd::take_damage()`'a aynı desende
(`base_enemy.gd::_react_flash()`'in birebir kopyası — `_flash_id` korumalı, çakışan
art arda hasarlarda sadece son flaşın rengi sıfırlamasına izin veriyor) yeni bir
`_react_flash_physical()` fonksiyonu eklendi, `take_damage()`'ın başında çağrılıyor.

**Uygulama detayı**: Player 3 ayrı karakter sprite'ı barındırıyor (`$VectorSprite`/
`$CycloneSprite`/`$LeilaSprite`, sadece biri o an görünür) — ama `modulate` Player
ROOT node'una (CharacterBody2D) uygulanıyor, tek tek sprite seçmeye gerek yok
(Godot'ta modulate çocuklara miras geçiyor, gizli olanlar zaten görünmüyor,
zararsız). Player root'unda `modulate` başka hiçbir yerde kullanılmıyordu (sadece
dash-trail hayalet klonlarında, ayrı bir node), çakışma riski yok.

## Font: Silver indirildi ve projeye eklendi (2026-09-25) — HENÜZ UI'ya BAĞLANMADI

Font önerileri (Pixel Operator / Grand9K Pixel) araştırılırken **Silver** (Poppy Works,
itch.io) daha iyi çıktı: lisans **CC BY 4.0** (ticari kullanım serbest, sadece atıf;
Grand9K'nın CC-BY-SA'sındaki ShareAlike şartı yok), $100.000 bütçe/kazanç eşiğini
aşarsa hello@poppy.works ile doğrudan lisans gerekiyor. Dil kapsamı çok geniş
(Latin+Kiril+CJK+Tayca+Devanagari…, 13.783 glyph), Türkçe karakterlerin (ğ ş ı İ ö ü ç)
hepsi fonttools ile doğrulandı — eksik yok. Gamepad/klavye/mouse ikonları fontun
içinde. SIGNALIS, Crypt of the NecroDancer, World of Horror gibi oyunlarda kullanılıyor.
Bilinen küçük sorunlar (topluluk yorumları): dikey hizalama kayması ve büyük "I"
kerning'i — Godot'ta Y-offset ayarı gerekebilir.

- Dosya: `assets/silverfont/Silver.ttf` (3.7 MB) + `assets/silverfont/LICENSE.txt`
  (atıf notu). Kullanıcı ücretsiz yolu seçildi ("No thanks, just take me to the
  downloads"), ödeme yapılmadı.
- **YAPILACAK**: (1) oyunun credits ekranına "Silver font by Poppy Works" atfı
  eklenmeli (CC BY 4.0 zorunluluğu), (2) UI'daki mevcut Orbitron font referansları
  (`game_scene.gd` başındaki `_font_bold`/`_font_regular` preload'ları + `.tscn`'deki
  `font_regular`/`font_bold` ExtResource'ları) Silver'a çevrilecek — kullanıcı onayı
  bekleniyor, Orbitron şu an oyunun UI kimliği.

### KARAR (2026-09-25): Probly12 iptal, SILVER kullanılıyor — TEST BEKLİYOR
Probly12 denendi ("çok küçük", 12px tasarım, sembol eksik) → **komple kaldırıldı**
(`assets/probly12font/` silindi, kodda referans yok). Fontlar (`game_scene`/`main_menu`/
`character_select` `.gd`+`.tscn`, `neon_sign.gd`) `res://assets/silverfont/Silver.ttf`'e
çevrildi (Bold/Regular aynı dosya, Silver tek ağırlık). `Silver.ttf.import`:
antialiasing=0, hinting=0, subpixel=0, oversampling=1.0 (pixel keskin).
**Silver'ın gerçek piksel ızgarası 19px** (1 piksel = 100/1900 em; büyük harf 9px, x-height
6px, glyph advance 6px). Bu yüzden TÜM font boyutları `19 * max(1, round(eski*1.46/19))`
formülüyle 19'un katlarına oturtuldu (≤18→19, 20-28→38, 36-42→57, 48-52→76, 64→95,
88→133) — 117 yer (tscn `theme_override_font_sizes`, gd `add_theme_font_size_override`,
`.font_size =`, `_dfs/_nfs/desc_font_size`). Kart açıklama kademeleri (13/11/10) artık
hepsi 19. **Riskler**: 19→38 sıçraması büyük; sabit kutular taşabilir (sağ panel 272px,
menü butonları, hover pop-up). `▸ ⏸ ⚡ ◻` glyph'leri Silver'da yok (fallback); `→ ≥ ≤ — •`
var. **Yapılacak**: (1) credits ekranına "Silver font by Poppy Works" atfı (CC BY 4.0),
(2) `assets/orbitronfont/` artık referanssız — silinebilir. Geri alma: `git diff` (boyutlar
dağınık, eski boyutlar HEAD'de).
**Ana menü buton ortalama (2026-09-25)**: Silver'ın ascent/descent'i asimetrik (1200/-900,
büyük harf 900) → metin buton içinde ~6px yukarıda kalıyordu. `main_menu.tscn`'deki 6
buton StyleBoxFlat'ında (`StyleBoxFlat_1,2,3,5,6,7`) `content_margin_top` 10 → **22**
(alt 10 aynı) yapıldı = metin 6px aşağı. `⚙` Silver'da yok (fallback font satır yüksekliğini
bozuyordu) → `≡` ile değiştirildi (`main_menu.tscn` + `lang.gd` mm_settings/set_title).
`▶` ve `■` Silver'da mevcut, dokunulmadı. Alt yazı (19px) küçük — 38'e çıkarma önerisi
kullanıcı onayı bekliyor.
**Ana menü ikonları PNG'ye çevrildi (2026-09-25)**: kullanıcı klasik ikon (disket=Kaydı Yükle,
güç düğmesi=Çıkış) istedi — font glyph'iyle mümkün değil (Silver'da yok). PIL ile 10x10
pixel-art çizilip 2x (20x20) + altta 12px saydam boşluk (32px yükseklik; metin 6px aşağı
kaydırıldığı için ikon dikey hizalı kalsın) `assets/menuIcons/{play,load,settings,quit}.png`
üretildi (beyaz, butonun font rengiyle `icon_*_color` tint). Butonlar `Button.icon` +
`texture_filter=1` + `h_separation=16` kullanıyor; `lang.gd` `mm_*` metinlerinden `▶ ■ ≡`
glyph'leri kaldırıldı. Godot ilk açılışta PNG'leri import eder. Oyun içi ayar ekranı başlığı
(`set_title`) hâlâ `≡` glyph'i kullanıyor.
**Karakter seçim ekranı (2026-09-25)**: CONFIRM/BACK butonlarının 6 StyleBoxFlat'ında
`content_margin_top` 10→22 (menüdeki aynı Silver dikey-ortalama düzeltmesi; `▶ ◀` glyph'leri
Silver'da var, metinde kaldı). Karakter kartlarında isim + class (Kinetik…) 19→**38**: orta kart
isim `y-130` / class `y-82` (yükseklik 44), yan kartlar isim `y-62` (yükseklik 44) —
görselde taşma/çakışma kontrolü kullanıcıda.
**Karakter seçim sol bilgi paneli sadeleştirildi (2026-09-25)**: eski tasarımdan kalma
`Pasif: ...` satırı (`LabelPassive` gizlendi, `CHARS`'tan `"passive"` alanı silindi) ve
`Toplar: ...` (başlangıç core'ları, `"balls"` alanı silindi) kaldırıldı; `cs_passive`/`cs_balls`
dil anahtarları silindi. LV/XP satırı 19→38 ve Lang'a alındı (`cs_level_line`/`cs_level_max`):
max seviyede eski "11921 / 1 XP" saçmalığı yerine "SEVİYE 5 — MAKS". "Görevler"/"Black Market"
sabit metinleri `cs_quests`/`cs_market` anahtarlarına taşındı (TR: Görevler, EN: Quests).
Karakter class isimleri (Kinetik/Elemental/Manipülasyon) hâlâ `CHARS`'ta sabit TR — dil
anahtarına taşınmadı. **Vector'un "Normal Ball +3 hasar" pasifi kodda da silindi** (`ball_launcher.gd` `vector_bonus`,
kullanıcı onayı): Vector'un normal topu artık 8 değil **5 + ball_mastery** hasar verir.
**Sağ panel: Geliştirmeler listesi + core sayacı düzeltildi (2026-09-25)**:
- **"Geliştirmeler" hiç gerçek veri göstermiyordu**: `update_ui()` sadece 3 eski sabit kontrol
  yapıyordu (`SPEED>300`, `chain_length>220` — bu başlangıçtan beri true olduğu için
  "Zincir Artışı" hep sabit görünüyordu —, `has_next_one`). Artık `_owned_indices`'ten
  gerçekten alınan **Utility/Individuality/ortak** kartlar listeleniyor (en yeni üstte, max 6
  satır + "+N", Utility ise `Lv2/Lv3` eki; Identity core'lar ve Calamity'ler zaten kendi
  slotlarında olduğu için, Medkit anlık olduğu için hariç). `_refresh_upgrade_list()`
  (`_on_upgrade_selected`'te çağrılıyor) metni önbelleğe alıyor, `update_ui()` sadece atıyor.
  Eski `ui_upgrades_speed/chain/next` dil anahtarları silindi.
- **Core sayacı yanlıştı**: `orbit_balls.size() / MAX_ORBIT(10)` sadece rezervdeki (fırlatılmayı
  bekleyen) topları sayıyordu; havadaki 3 başlangıç topu sayılmıyordu ve 10 azami yanlıştı.
  Artık `player_balls` grubundaki TÜM core'lar (normal + launchable + connected, havadakiler
  dahil; Scatter parçaları ve Mirror Image bonus topları hariç) / **azami = 3 + shop core bonusu
  + 5 launchable + 3 connected (=11)**. Etiket TOPLAR→**CORE'LAR** (EN: CORES).
**Pause menüsü yenilendi (2026-09-25)**: eskiden düz gri varsayılan `Button`'lar (200×55, küçük yazı,
başlık x=880 sabit → ortalı değildi). Yeni yardımcı `_make_neon_button(text, icon, pink, pos)`
(`game_scene.gd`) ana menüdeki neon stili (cyan / Çıkış için pembe, hover glow, Silver 38, 22px üst
marj, `menuIcons` PNG ikonları) kodla üretiyor; yeni `assets/menuIcons/home.png` (Ana Menü).
Başlık 1920 genişlikli Label ile ortalandı. Butonlar 410×70, x=755, y=420/518/616/714 (Devam,
Ayarlar, Ana Menü, Çıkış). Ayarlar alt ekranı (`_show_pause_settings`) da aynı tarza çevrildi: ortalı başlık, sürgü etiket/değerleri 38px, ses etiketleri `set_audio_master/music/sfx` Lang anahtarlarından (eskiden sabit TR "Ana Ses/Müzik/Efektler"), cyan dolgulu slider + kare tutamaç (kodla üretilen `ImageTexture`), neon GERİ butonu (yeni `menuIcons/back.png`).
**Lisans notu**: Silver CC BY 4.0 ama bütçe/kazanç >$100.000 ise yazardan doğrudan lisans
gerekiyor; uçuk teklif gelirse plan: pazarlık ya da başka fonta geçiş (font 7 dosyada
tek satırla değişiyor; OFL alternatifleri: Galmuri, DotGothic16, Fusion Pixel, Unifont).

## (ESKİ NOT) Font seçimi (2026-09-23)

Kullanıcı pixel-art'a yakışan, hem Türkçe (ğ/ş/ı/İ/ö/ü/ç) hem gelecekte başka diller
için de kullanılabilecek bir font istedi. İki öneri sunuldu, kullanıcı evde ikisini de
deneyip karar verecek:
- **Pixel Operator** — ücretsiz/ticari kullanıma açık, gerçek pixel-art hissi, Latin
  Extended-A (Türkçe karakterler dahil) düzgün destekleniyor, Bold varyantı var, küçük
  boyutlarda net. Şu anki TR/EN ihtiyacı için önerilen.
  Kaynak: https://www.dafont.com/pixel-operator.font
- **Grand9K Pixel** — Latin + Kiril + Yunan + CJK (Çince/Japonca/Korece) kapsıyor,
  ileride TR/EN dışında dil eklenirse daha geleceğe dönük ama Latin harflerde biraz
  daha kalın/az net duruyor.
  Kaynak: https://www.dafont.com/grand9k-pixel.font

Karar verilince: font dosyasını (.ttf/.otf) projeye ekleyip Godot'ta `FontFile` olarak
UI'daki mevcut font referanslarına (kart açıklamaları, HUD, menüler vb.) bağlamak
gerekecek — henüz hiçbir entegrasyon yapılmadı, sadece öneri aşamasındayız.

## Cyclone Identity — Kart-kart Full Review TAMAMLANDI (2026-09-23)

Kullanıcı isteğiyle Cyclone'un 17 Identity core'u (Glitch/Echo Core önceki session'da,
kalan 15'i bu turda) implementasyon + requires + TR + EN 4 aşamalı review'den geçirildi.
Requires zaten Identity core'larda beklenmiyor (kartın kendisi kaynak) — sadece Spike
Core'da gerçek bir bağımlılık bulunup eklendi (aşağı bak).

**Bulunan ve düzeltilen buglar:**
- **Virus Core (160) — açıklama/kod uyuşmazlığı**: açıklama "1 dmg/s, 3s" diyordu, gerçek
  `apply_antivirus()`/`_process_antivirus()` (base_enemy.gd) 0.5sn tick aralığıyla stack
  başına 1 hasar veriyor (= 2 dmg/s) ve taban süre 5sn (Memory Leak ile uzayabilir) —
  açıklama koda göre "2 dmg/s, 5s" olarak düzeltildi (davranış değişmedi).
- **Rogue's Eye Core (196) — pause bug (tekrarlayan desen)**: işaretlemeyi geri alan
  `get_tree().create_timer(3.0)` çağrısı `process_always=false` içermiyordu — level-up
  menüsünde (`paused=true`) süre donmuyordu. `, false` eklendi.
  **Not**: işaretleme sayacı için ayrı bir `_inner_tick_timer_b` (7sn cooldown) zaten
  doğru pause-safe çalışıyordu (`_inner_core_tick`'in genel `delta` akışı) — sadece bu
  tekil `create_timer` unutulmuştu.
- **Leech Nova Core (214) — açıklama/kod uyuşmazlığı**: açıklama "1s Glitch" diyordu,
  kod `apply_glitch()`'i süre parametresi vermeden çağırıyor (varsayılan 3.0sn) —
  açıklama "3s Glitch" olarak düzeltildi (diğer Glitch kaynaklarıyla tutarlı, davranış
  değişmedi).
- **Spike Core (213) — eksik requires**: Decay stack'ine bağımlı (`decay_stacks >= 3`
  kontrolü) ama tek kaynağı Decay Core (161) olduğu halde `requires` yoktu, Decay Core
  almadan tamamen faydasız kalabiliyordu → `requires: [161]` eklendi.

**Dil düzeltmeleri (tekrarlayan proje-geneli desen — EN `desc` alanı Türkçe yazılmış,
`lang.gd`'de TR girdisi hiç yoktu)**: Phantom Circuit Core (159), Ricochet Core (163),
Glitch Pulse Core (192), Shadow Core (193), Data Drain Core (194), Virus Beacon Core (195),
Rogue's Eye Core (196), Circuit Overload Core (197), Tracer Core (212), Spike Core (213),
Leech Nova Core (214) — hepsinin EN `desc` alanı İngilizceye çevrildi, `lang.gd`'ye TR
girdisi eklendi. "Glitched"/"Virus"/"Decay" keyword'leri bold yapılıp glossary'e bağlandı
(zaten `Lang.STATUS_KEYWORDS`'te vardı, sadece kart metinlerinde kullanılmıyordu).

**px kuralı uygulandı (Connected Core kararı)**: 192-197 hepsi `_CONNECTED_CORE_INDICES`'te
zaten kayıtlı Connected Core'lar (is_inner_core=true) — Echo Resonance Core (189)
incelemesindeki kural gereği açıklamalarından "80px"/"60px"/"90px"/"100px"/"50px" gibi
piksel değerleri kaldırılıp "yakındaki düşmana(lar)" ifadesine çevrildi.

**Doğrulanan, bug bulunmayan kartlar**: Data Leech Core (22, +2 Can/isabet, Data Siphon
(121) sinerjisi doğru), Decay Core (161, açıklama zaten doğruydu), Static Core (162,
açıklama zaten doğruydu), Glitch Pulse Core (192, 4sn/Glitch mantığı doğru), Shadow Core
(193, dash sonrası 1 hasar/sn 3 tick — outer 1sn'lik tick gate'i sayesinde doğru çalışıyor,
ilk bakışta "her frame 1 hasar" bug'ı gibi göründü ama değildi), Data Drain Core (194,
aynı 1sn tick gate'i doğru), Virus Beacon Core (195, `die()` hook'u önceki turda zaten
pause-safe yapılmıştı), Circuit Overload Core (197, Circuit Breaker senkronu doğru),
Tracer Core (212, 1sn iz + 0.5sn yavaşlatma doğru, zaten pause-safe).

**Core Mastery override bug'ı KONTROL EDİLDİ, YOK**: bu 15 core'un HİÇBİRİ `_hit_subject()`
içindeki hasar-override `elif` zincirinde (Plasma/Steam/Arc/Voltaic/Electric/Cryo/Water/
Fire/Pierce/Armor/Anchor/Crusher/Kinetic/Bulwark/Siege/Bloodbound/Tempered) yer almıyor —
hepsi `base_damage = max_damage` (zaten ball_mastery içeriyor) varsayılanını koruyor,
Core Mastery bonusu hepsinde doğru çalışıyor. Data Leech Core (22) istisna: `can_leech`
elif'te `base_damage = 2` sabit ama `_typed_core` true kaldığı için ball_mastery yine de
ekleniyor (launcher'daki `max_damage=2, no ball_mastery` ile birlikte doğru toplam veriyor).

**CYCLONE IDENTITY TAMAMLANDI (17/17 core) — 2026-09-23**

### Cyclone Identity — Kullanıcı Cila Turu (2026-09-23, aynı gün devamı)
İlk review sonrası kullanıcı açıklamaları tekrar okuyup birkaç ek düzeltme istedi:
- **Phantom Circuit Core (159)**: TR "Bu fırlatışta" → "Her fırlatışta" (her atışta
  tekrarlandığını netleştirmek için), EN "First hit this flight" → "Every flight, first
  hit" ile eşleştirildi.
- **Virus Core (160) / Decay Core (161)**: açıklamalar sadeleştirildi — sadece "İsabet →
  1 Virus/Decay stack" kaldı, sayısal detaylar (hasar/sn, süre, maks stack) kaldırıldı.
  Kullanıcı haklı: bu detaylar zaten hover glossary panelinde (`Lang.STATUS_GLOSSARY`)
  var, kart üzerinde tekrar etmeye gerek yok.
- **Static Core (162)**: "%40 yavaşlatır" ifadesi "[b]Slowed[/b] uygular (%40, 0.5sn)"
  olarak değiştirildi — "Slowed" artık bold ve glossary'e bağlı (daha önce keyword
  kullanılmıyordu, sadece düz metindi).
- **Virus Beacon Core (195)**: açıklama "Yakındaki bir Virus'lü düşman ölürse, 3sn
  boyunca yakındaki düşmanlara 1'er stack yayar" olarak sadeleştirildi. **Eksik requires
  bulundu ve eklendi**: `requires: [160]` (Virus Core — tek Virus stack kaynağı,
  olmadan kart tamamen faydasız kalıyordu).
- **Rogue's Eye Core (196) — mekanik yeniden tasarlandı**: kullanıcı "7sn beklemek
  %10 bonus için mantıksız" dedi. Yeni tasarım: 7sn bekleme/3sn süre kaldırıldı, core
  artık **sürekli** en yakın düşmanı işaretli tutuyor (`_inner_core_tick`'in 1sn'lik
  genel tick'i içinde her seferinde en yakını yeniden hesaplayıp değişince eski hedefin
  işaretini kaldırıyor, `_re_marked_target` yeni bir per-ball state var'ı — `ball.gd`).
  Yeni `_exit_tree()` eklendi (top yok olunca işaretli düşmanın flag'i temizleniyor,
  sızıntı önlendi). Bonus **%10 → %50**'ye çıkarıldı (`base_enemy.gd::take_damage()`,
  `is_marked` çarpanı `1.1` → `1.5`). Yeni ortak keyword: **"Mark"** — `Lang.
  STATUS_KEYWORDS`'e eklendi, EN/TR glossary girdisi yazıldı ("Marked enemies take 50%
  more damage." / "İşaretli düşmanlar %50 daha fazla hasar alır."). Kart metni artık
  "[b]Marks[/b] the nearest enemy" / "Yakındaki bir düşmanı [b]Mark[/b] eder" — bold
  kelime glossary'nin substring taramasıyla eşleşiyor (kart tam "Marked" yazmasa da
  "Marks"/"Mark" içinde "Mark" geçtiği için tetikleniyor).
- **Circuit Overload Core (197)**: `requires: [143]` eklendi (Circuit Breaker,
  Individuality — "Her 25. isabet: Avlu'daki tüm düşmanlar 3sn Glitched" kartı; Circuit
  Overload Core'un `circuit_overload_active` bayrağı SADECE bu kart alınmışsa set
  ediliyor, olmadan tamamen pasif kalıyordu).
- **Leech Nova Core (214) — DENGELEME (kullanıcı kararı)**: "Öldürünce +2 HP + yakındaki
  düşmanlara 3sn Glitched" kombosu fazla güçlü bulundu — Glitch yayma kısmı **komple
  kaldırıldı** (`base_enemy.gd::die()`'daki ilgili for döngüsü silindi), kart artık
  sadece "Öldürünce: +2 HP kazanır".

## Cyclone Utility — Kart-kart Full Review TAMAMLANDI (2026-09-23)

14 kart (`_apply_utility_level()`'da hepsi basit `p.X_level = level` deseni kullanıyor —
Vector/Leila'daki gibi `match level: 1/2/3` blokları değil, formüller consumer kod
tarafında `level` değişkenini doğrudan okuyor). Hepsinin implementasyonu doğrulandı,
sayılar (Lv1/Lv2/Lv3, taban değerler) kod ile birebir eşleşiyordu — **hiçbir kartta
sayısal/mantık bug'ı bulunmadı**. Tek sorun proje-geneli tekrarlayan desendi: **14
kartın 14'ünde de** EN `desc` alanı aslında Türkçe yazılmıştı, `lang.gd`'de TR girdisi
hiç yoktu — hepsi ayrıştırıldı (EN çevrildi, TR eklendi), "Glitched"/"Virus"/"Decay"
geçen yerlerde bold+glossary bağlantısı kuruldu.

**Eksik requires bulunup eklendi**:
- **Data Exploit (115) / Extended Glitch (119) / Signal Jam (120)**: üçü de Glitch
  uygulanmış bir düşmana bağımlı ama hiçbirinde `requires` yoktu → Data Storm/System
  Crash'te kullanılan aynı liste (`requires_any: [16, 192, 197, 214]` — Glitch
  Core/Glitch Pulse Core/Circuit Overload Core/Leech Nova Core) eklendi.
- **Decay Amp (222)**: Decay patlaması hasarını büyütüyor ama tek Decay stack kaynağı
  Decay Core (161) olduğu halde requires yoktu → `requires: [161]` eklendi.

**Zaten doğru olan requires**: Bounce Mastery (133→114), Stack Overflow/Memory Leak/
Cascade Delete/Corruption Protocol (148/150/152/151→160), Pinball Protocol (134→163),
Stealth Pass/Ghost Protocol (139/140→159) — hepsi doğru kaynağa bağlıydı.

**Requires gerekmeyen, doğrulanan kartlar**: Angular Precision (131, her top için
genel — herhangi bir core'a bağlı değil), Backstab Protocol (158, kuzey duvar sekmesi
her top için evrensel, core-agnostic).

**Bounce Mastery (133) notu**: açıklama "+1 (taban 4 → 6)" biraz kafa karıştırıcı
görünebilir — Ricochet Strike'ın kendi tabanı 4, Bounce Mastery Lv1 alınca 6'ya
sıçrıyor (formül `5 + level`), sonraki seviyelerde gerçekten +1/level artıyor (6→7→8).
İlk sıçramanın +2 olması bug değil, kartın kendi tasarımı — dokunulmadı.

**CYCLONE UTILITY TAMAMLANDI (14/14 kart) — 2026-09-23**

### Cyclone — Glitch/Virus taban süreleri düşürüldü (kullanıcı kararı, 2026-09-23)
Kullanıcı Extended Glitch/Memory Leak review'i sırasında iki taban süreyi düşürmeye
karar verdi:
- **Glitch taban süresi 3sn → 2sn**: `base_enemy.gd::apply_glitch(duration: float =
  2.0)` (varsayılan parametre) + Extended Glitch'in kendi formülü (`2.0 +
  extended_glitch_bonus`). Bu, `apply_glitch()`'i parametresiz çağıran HER kaynağı
  etkiliyor (Glitch Core, Glitch Pulse Core, Circuit Overload Core, Circuit Breaker,
  Exploit Network, vb. — proje genelinde tek bir yer). **Explicit süre veren tek
  istisna dokunulmadı**: Backdoor (130) kendi `apply_glitch(3.0)` çağrısını koruyor
  (kasıtlı Calamity-özel tasarım). Extended Glitch artık 3sn/4sn/5sn üretiyor (eskiden
  4/5/6). Glitch Core (16) ve Circuit Breaker (143) açıklamaları "3s" → "2s" güncellendi.
- **Virus taban süresi 5sn → 3sn**: `base_enemy.gd::apply_antivirus()`'teki `_dur`
  hesaplaması. Memory Leak artık 4sn/5sn/6sn üretiyor (eskiden 6/7/8).

## Cyclone Individuality — Kart-kart Full Review TAMAMLANDI (2026-09-23)

15 kart (114, 145, 121, 149, 116, 126, 136, 141, 146, 143, 154, 155, 219, 220, 221)
incelendi. Aynı proje-geneli dil bug'ı burada da vardı: **15 kartın 15'inde de** EN
`desc` Türkçe yazılmıştı, TR girdisi hiç yoktu — hepsi ayrıştırıldı, "Glitched"/
"Virus"/"Decay" geçen yerlerde bold+glossary bağlantısı kuruldu.

**KRİTİK BUG FIX — Shadow Dance (146) tamamen ölü karttı**: "7 duvar sekmesi → kalıcı
+%3 Core Speed" vaadi hiçbir zaman gerçekleşmiyordu. `ball.gd` doğru şekilde
`_shadow_dance_acc` (player.gd) değişkenini her 7 sekmede +0.03 artırıyordu ama
`player.gd::_physics_process`'teki `core_speed_mult` hesap zincirinde bu değişken
**hiçbir yerde okunmuyordu** — Vector'ın eski "Core Speed Mimarisi" bug'ıyla
(2026-08-29, `_effective_orbit_speed`) aynı kalıp, sadece Cyclone tarafında gözden
kaçmış. `core_speed_mult *= 1.0 + _shadow_dance_acc` satırı eklendi (Resonance
Engine'in hemen altına, doğru indent seviyesinde — ilk denemede yanlışlıkla
Resonance Engine'in `if` bloğunun içine girmişti, PowerShell ile tab seviyesi
düzeltilip doğrulandı).

**Pause bug fix — Ghost Step (220)**: dash sonrası bağışıklık penceresini kapatan
`get_tree().create_timer(1.5)` çağrısı `process_always=false` içermiyordu (aynı
tekrarlayan desen) → `, false` eklendi.

**Eksik requires bulunup eklendi**: System Overload (126) — "5+ Glitched düşman"
şartı bir Glitch kaynağına bağımlı ama requires yoktu → `requires_any: [16, 192,
197, 214]` eklendi (Data Storm/System Crash/Data Exploit ile aynı liste).

**Ricochet Strike (114) — açıklama koda göre düzeltildi (kullanıcı kararı, 2026-09-23)**:
bonus hasar (`_wall_bounce_count * _rc_bonus`) her isabette uygulanıyor,
`_wall_bounce_count` sadece fırlatma anında (launch/launch_with_speed) sıfırlanıyor —
top sekip birden fazla düşmana art arda çarparsa HER isabet aynı bonusu alıyor
(tüketilmiyor/azalmıyor). Eski açıklama "next hit" (tekil) diyordu, kullanıcı
**davranışı korumayı seçti** (nerf yok) — açıklama "Wall bounces in flight add +4 dmg
to every hit until it returns" / "Fırlatıştaki duvar sekmeleri, top dönene kadar her
vuruşa +4 hasar ekler" olarak koda göre güncellendi.

**Diğer doğrulanan kartlar (bug yok)**: Data Siphon (121), Viral Load (149), Shadow
Strike (116, "sağ/sol" = x-ekseni sekmesi doğru kontrol ediliyor), Phase Shift (141),
Circuit Breaker (143), Zero Day (154), Kernel Panic (155), Decay Harvest (219),
Overclock Protocol (221) — hepsi kodla birebir eşleşiyordu, requires zaten doğruydu.
Rogue's Instinct (145) "Enemy purified" flavor ifadesi netlik için "On kill" olarak
sadeleştirildi (mekanik zaten her düşman ölümünde tetikleniyordu, sadece "arındırılmış"
belirli bir düşman tipi değil).

**CYCLONE INDIVIDUALITY TAMAMLANDI (15/15 kart) — 2026-09-23**

### Angular Precision (131) — terminoloji düzeltmesi
TR açıklamadaki "uçuş" kelimesi "fırlatış" ile değiştirildi (kullanıcı: daha doğal/
anlaşılır) — "Her fırlatışın ilk vuruşu: +%5 hasar". EN tarafı "flight" olarak
bırakıldı, çünkü bu terim projede aynı kavram için tutarlı şekilde kullanılıyor
(Phantom Circuit Core "Every flight" vb. ile eşleşiyor).

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

- [x] **Systemic Failure (156) — MEKANİK/AÇIKLAMA DÜZELTMESİ (kullanıcı kararı, 2026-09-19)**:
      açıklama "2× Antivirus stack" diyordu ama kod stack'i olmayan düşmana direkt cap
      (3 + `stack_overflow_level`) veriyor, stack'liye mevcut miktarı ekleyip cap'e kırpıyordu —
      "2×" sadece kısmen doğruydu. Kullanıcı kararı: **herkese maksimum stack** — kod
      `apply_antivirus(_cap)` olarak sadeleşti, açıklama "All enemies in the Yard get max
      Antivirus stacks" / TR "...maksimum Antivirus stack'i alır" (Antivirus bold, glossary'e
      bağlı). Ek bug'lar: `is_dead` filtresi yoktu (cesetlere de Antivirus ikonu takılıyordu)
      ve Y sınırı eksikti (Backdoor'daki aynı eksik) → ikisi de eklendi (tam Avlu dikdörtgeni
      x:385-1920, y:255-1080, canlı düşmanlar). Requires gerekmiyor (Antivirus'un kendi
      kaynağı). Sprite: kart art'ı mevcut (`systemic_failure_art.png`), oyun içi VFX sadece
      genel ekran flaşı — özel sprite yok.

      **İsimlendirme düzeltmesi (kullanıcı, aynı gün)**: "Antivirus" ismi eski sistemden
      (düşmanları kurtarma mekaniği — artık yok) kalmaydı. Kart açıklamalarındaki ve
      glossary'deki tüm "Antivirus" ifadeleri **"Virus"** yapıldı (`game_scene.gd` 8 desc:
      Virus Core, Stack Overflow, Memory Leak, Viral Load, Kernel Panic, Systemic Failure,
      Virus Beacon Core TR, Virus Rain; `lang.gd`: `STATUS_KEYWORDS` + EN/TR glossary +
      Systemic Failure TR). Kod tarafı (`apply_antivirus`, `antivirus_stacks`,
      `is_antivirused` vb.) dokunulmadı — sadece oyuncuya görünen metinler. Debuff ikonu
      zaten "virus"tu. **Yeni metin yazarken bu statüye "Virus" de.**

- [x] **Glitch Bomb (215) — KRİTİK BUG FIX (2026-09-19)**: `_activate_glitch_bomb()`
      düşmanları `get_nodes_in_group("enemies")` ile arıyordu ama **oyunda hiçbir düşman
      "enemies" grubunda değil** (hepsi `"subjects"` — `.tscn`/`add_to_group` taraması ile
      doğrulandı). Yani `has_method` düzeltmesinden SONRA bile kart hiçbir zaman çalışmıyordu
      (boş liste). Aynı yanlış grup adı **5 Calamity'de** vardı: **Glitch Bomb, System Crash,
      Virus Rain, Decay Field ve Wildfire (Leila)** — hepsi tamamen ölüydü. Yeni
      `_yard_subjects()` helper'ı eklendi (`subjects` grubu, canlı, tam Avlu dikdörtgeni
      x:385-1920 y:255-1080) ve 5 fonksiyon bunu kullanıyor. **Wildfire'da ek bug**:
      yayılma döngüsünde `if other == e or spread_count >= 2: break` — ilk eleman kendisiyse
      döngü hemen kırılıp hiç yayılma olmuyordu → `other == e: continue`, `spread_count >= 2:
      break` olarak ayrıldı. Açıklama: EN alanı Türkçe + "120px" yazıyordu → "Enemies in the
      targeted area become Glitched for 4s" / TR "Hedeflenen alandaki düşmanlar 4sn boyunca
      Glitched olur" (px kaldırıldı). Requires gerekmiyor (Glitch'in kaynağı). Sprite: kart
      art'ı mevcut (`glitch_bomb_art.png`), VFX sadece ekran flaşı. **NOT**: System Crash /
      Virus Rain / Decay Field / Wildfire'ın implementasyonu artık çalışıyor ama kart
      review'leri (açıklama/requires/VFX) sırası geldiğinde yapılacak — Wildfire Leila'nın
      Calamity listesinde hiç incelenmemişti, sıra bittikten sonra ele alınmalı.

      **VFX: "The Yard Engine" ortaklaştırıldı (kullanıcı isteği, 2026-09-19)**: Backdoor'un
      makine VFX'i Systemic Failure'a da bağlandı. `_vfx_backdoor_engine()` /
      `_vfx_backdoor_bolt()` genelleştirilip `_vfx_yard_engine(apply_fn, bolt_color,
      fallback_flash)` / `_vfx_engine_bolt(from, to, color)` oldu — cihaz beliriyor, son 2
      frame'de canlı+Avlu içi düşmanlara çizgi gidip `apply_fn` (kartın gerçek etkisi) o an
      uygulanıyor, sonra "ending" oynuyor. Backdoor: mor çizgiler + Glitch 3sn; Systemic
      Failure: **yeşil** çizgiler + max Virus stack. Sprite yoksa etkiyi anında uygulayıp
      ekran flaşına düşüyor. İleride benzer "alan geneli" kartlar (Virus Rain vb.) aynı
      helper'ı kullanabilir. Debug slotu: "🧪".
      **Shake (kullanıcı isteği, aynı gün)**: çizgilerin çıktığı anda (`_fire_bolts`)
      `_screen_shake_small()` çağrılıyor — ortak helper'da olduğu için hem Backdoor hem
      Systemic Failure'da çalışıyor. Yoğun bulunursa `screen_shake_heavy()`/daha hafif ayar
      denenebilir.
      **Güçlendirme + hasar geri bildirimi (kullanıcı isteği, aynı gün)**: `_screen_shake_
      small` (±1px) ve `screen_shake_heavy` (±3px) yetersiz kaldı → yeni `_screen_shake_
      strong()` eklendi (±8px, 8 adım azalan genlik, ~0.4sn) ve çizgi anında o kullanılıyor.
      Ayrıca `base_enemy.gd::_process_antivirus` her Virus tick'inde (0.5sn'de bir hasar)
      `_react_flash(Color(0.2, 1.0, 0.45))` (yeşil) çağırıyor — yanma gibi düşman hasar
      aldığını gösteren görsel geri bildirim. Bu, TÜM Virus kaynaklarında (Virus Core,
      Virus Rain vb.) geçerli, sadece Systemic Failure'da değil.

      **MEKANİK DEĞİŞİKLİĞİ — Glitch Bomb artık kalıcı yer alanı (kullanıcı kararı, 2026-09-19)**:
      Flame Zone deseni: `_activate_glitch_bomb(pos)` ~3sn (6 tick x 0.5s, `create_timer(0.5,false)`)
      boyunca 84px içindeki canlı Avlu düşmanlarına `apply_glitch(1.5)` uyguluyor (üstünden geçen
      glitch'lenir). VFX: `_vfx_glitch_bomb(pos)` — `assets/VFX/calamitys/glitchBomb/` (37 frame,
      168x168, 12fps, non-loop, z_index=-1, bitince queue_free; sprite yoksa eski ekran flaşı).
      `_aim_radius` 120->84, EN/TR açıklamalar güncellendi.

### İsim değişikliği: Glitch Bomb → Glitch Field (kullanıcı kararı, 2026-09-23)
Kart artık patlamıyor (Flame Zone deseni, yerde kalan alan), "Bomb" ismi eski patlayan
tasarımdan kalmıştı, anlam kaymıştı. Tüm referanslar güncellendi (`_CALAMITY_DISPLAY_NAMES`,
dispatch yorumları, kart tanımı, `_aim_radius` yorumu, index 215 pickup handler yorumu).
Art dosyası da yeniden adlandırıldı: `glitch_bomb_art.png` → `glitch_field_art.png`
(+ `.import`, `source_file`/`path` düzeltildi — art yolu kart adından otomatik türediği için
zorunlu, Freezing Cold'daki aynı adım). Emoji (💣) ve iç fonksiyon adı (`_vfx_glitch_bomb`,
kullanıcıya görünmüyor) değişmedi. Aşağıdaki eski notlardaki "Glitch Bomb" adı artık
"Glitch Field" — tarih/mekanik bilgisi geçerliliğini koruyor, sadece isim eskimiş.

### BUG FIX: Virus'tan ölen düşmanlar yürüme animasyonunda takılı kalıyordu (2026-09-19)
`base_enemy.gd::_physics_process` sırası `_process_antivirus(delta)` → `_enemy_process(delta)`
idi. Virus DOT'u düşmanı öldürünce (`die()` → ölüm animasyonu) AYNI frame'de hemen
ardından `_enemy_process()` çalışıp `_update_walk_anim()` ile yürüme animasyonunu tekrar
oynatıyor, ölüm animasyonunu eziyordu (düşman düşüp ölmüyor, yürür pozda kalıyordu).
Fix: `_process_antivirus(delta)` sonrası `if is_dead: return`.

### BUG FIX: Glitch'li düşmanlar cesetlere saldırıyordu (kullanıcı fark etti, 2026-09-19)
Glitch'li düşmanlar (`is_glitched`) oyuncu yerine `subjects` grubundaki EN YAKIN düşmana
saldırıyor — ama hedef döngüsünde `is_dead` kontrolü yoktu, cesetler (15sn yerde kalıp
soluyor, o süre boyunca grupta kalıyor) da aday olduğu için ölü düşmanlara gidip vuruyorlardı. 7 dosyada (`subject`,
`armored_subject`, `heavy_subject`, `frantic_subject`, `cyber_shooter`, `cyber_rifle`,
`cyber_shotgun`) aynı döngü `if z == self or not is_instance_valid(z) or z.get("is_dead"):
continue` olarak düzeltildi. Boss'lar (`nyx_09`, `s_miler_79`) bu döngüyü kullanmıyor.

### Fiziksel Vuruş Geri Bildirimi + Glitchli Silahlı Düşman Davranışı (2026-09-19)
- **Fiziksel vuruş flaşı**: `take_damage(amount, from_ally, kill_cause, physical: bool = false)` —
  4. parametre eklendi (`base_enemy.gd`, `melee_enemy.gd`, `cyber_404.gd`, `nyx_09.gd`,
  `s_miler_79.gd`; **player.gd'nin `take_damage`'i hâlâ tek argüman alır — oyuncuya
  `physical` gönderme, crash eder**). `physical=true` iken düşman 0.08sn beyaz
  (`Color(2,2,2)`) parlar. Top isabeti (`ball.gd` ana vuruş + Connected Core dart-strike) ve
  glitchli düşmanın düşmana vuruşu `physical=true` gönderir; element/Calamity hasarları
  göndermez (kendi renkleri kalır, Virus yeşili aynen). Boss'lar `_react_flash`'a sahip
  olmadığı için kendi `_physical_flash()` yardımcılarını kullanır.
- `_react_flash(color, dur=0.15)` artık `_flash_id` sayacıyla çakışan flaşlarda sadece SON
  flaşın rengi sıfırlamasına izin verir; timer `process_always=false`.
- **Glitchli silahlı düşmanlar (cyber_shooter/rifle/shotgun)**: mermi atmaz. Nedeni: mermi
  (`bullet.gd`) sadece `player`/`allies` grubuna vuruyor, `subjects`'e hasar vermiyordu ve
  Glitch süresi (Glitch Bomb tick'i 1.5sn) atış aralığından (3sn) kısaydı. Yeni davranış
  `ranged_enemy.gd::_glitch_melee(delta)`: en yakın canlı düşmana yürür, 40px'te saniyede bir
  3 fiziksel hasar (sprite'ı hedefe 8px atılıp geri döner — saldırı animasyonu yok). Üç
  `_enemy_process` başında `if is_glitched: _glitch_melee(delta); return`.
- **AÇIK İŞ (kullanıcı, 2026-09-19)**: silahlı düşmanlarla ilgili Glitch'ten bağımsız bazı
  sorunlar var, kullanıcı henüz detay vermedi — sonraki turda sorulacak/bakılacak.
- Test havuzu override'ı (`pool = [cyber...]`) kaldırıldı; gerekirse `game_scene.gd`'de
  düşman havuzunun (`match pool[randi() % pool.size()]` öncesi) yeniden eklenebilir.

- [x] **System Crash (216) — 2026-09-19**: mekanik doğru (Avlu'daki Glitchli her düşman mevcut
      HP'sinin %30'unu kaybeder, en az 1). Boss'lar zaten etkilenmez: `nyx_09`/`s_miler_79`'da
      `apply_glitch` yok, `cyber_404.apply_glitch()` bilerek `return` ediyor, yani `is_glitched`
      hiç true olmaz. Dil: EN alanı Türkçe + `%%30` idi → "All Glitched enemies in the Yard
      lose 30% of their current HP" ("in the Yard" korundu, "into" hareket anlamı taşıdığı için
      kullanılmıyor), `lang.gd`'ye TR (216) eklendi. `requires_any: [16, 192, 197, 214]` eklendi
      (Data Storm ile aynı Glitch kaynakları). **VFX**: "The Yard Engine" yeniden kullanıldı,
      `_vfx_yard_engine()`'e `filter_fn` (sadece Glitchli düşmanlar) ve `to_engine` (çizgiler
      düşmandan makineye akar) parametreleri eklendi; hasar çizgilerle aynı anda uygulanır,
      isabet alan düşman macenta flaş alır. **İKON**: `💻💥` iki glyph (WormHole'daki sorun),
      kullanıcı ileride özel ikon çizdirecek, şimdilik dokunulmadı. Debug slotları:
      `["💣", "💻💥", "💻💥"]`.

- [x] **Virus Rain (217) — KALDIRILDI (kullanıcı kararı, 2026-09-19)**: "3s boyunca her 0.5s
      tüm düşmanlara 1 Virus stack" — stack üst sınırı (varsayılan 3) 1.5s'de doluyor, kalan
      3 tick boşa gidiyordu ve etkisi Systemic Failure'ın (herkese anında max stack) yavaş
      versiyonundan ibaretti; kullanıcı "gereksiz olmuş" dedi. Tüm referanslar silindi (kart
      satırı, `_CALAMITY_DISPLAY_NAMES`, dispatch, nişan-önizleme dalı, pickup handler,
      `_activate_antivirus_rain()`). `virus_rain_art.png` (+ `.import`) dosyası
      `assets/upgradeCardsArt/Cyclone/calamityCards/` altında ORPHAN olarak duruyor, istenirse
      silinebilir. Playtester notundaki "Antivirus Rain (217)" ve yukarıdaki eski satırlar
      artık geçersiz. **Cyclone Calamity'de kalan kart: Decay Field (218).**

- [x] **Decay Field (218) — TAMAMLANDI (2026-09-19/20)**: mekanik doğru (5sn, alandaki
      canlı düşmanlara `apply_decay()`). Düzeltmeler: ilk tick artık alan açılır açılmaz
      (eskiden 1sn sonra), z_index 1 → -1 (cesetlerin altında), EN/TR açıklama yenilendi
      (`lang.gd` 218 eklendi, "Decay" bold → sözlük paneli). Requires gerekmiyor (Decay'in
      kendi kaynağı).
      **VFX bağlandı**: `assets/VFX/calamitys/decayField/frame_000..035` (36 frame, 168×168)
      → `_activate_decay_field()` artık `AnimatedSprite2D` (tek seferlik, hız = frame sayısı
      ÷ 5sn ≈ 7.2 fps, alan süresiyle birebir), yarıçap **100 → 84px** (sprite'ın görsel
      yarıçapı, Flame Zone/Volcanic Rift ile aynı uyum), `_aim_radius` ☠️ 84'e senkronlandı.
      Sprite yoksa eski `Polygon2D` daire fallback'i çalışıyor.

      **DECAY MEKANİĞİ YENİDEN TASARLANDI — artık SÜRELİ (kullanıcı kararı, 2026-09-20)**:
      eskiden stack'ler ve %5/stack yavaşlatma **kalıcıydı** (ölene kadar). "Decay'li
      düşmanı öldürmek için acele etsin — zaten başlı başına güçlü bir mekanik" gerekçesiyle:
      - **Her stack bağımsız 3sn ömürlü** (`_decay_timers`, `DECAY_STACK_DURATION`); süre
        bitince stack düşer, yavaşlatma orantılı geri alınır. Maks 3 stack, stack başına %5
        yavaşlatma (değişmedi). Stack doluyken tekrar Decay gelirse **en eski stack'in süresi
        tazelenir** (alan içindeyken 3 stack korunur; eskiden `return` ile yok sayılıyordu).
      - Zamanlayıcı `_physics_process`'te (`_process_decay(delta)`) — `create_timer` DEĞİL,
        yani pause'da durur, donma/sersemlemede de akmaya devam eder.
      - **Ölüm patlaması aynı** (stack × 2/3/5/7 hasar, 80px) — ama artık düşman 3sn içinde
        öldürülmezse stack'ler düşüp patlama zayıflar/kaybolur → "zaman bombası" hissi.
      - **Slow ikonu**: Decay stack ≥ 1 iken düşmanda hem "decay" hem "slow" ikonu görünür
        (Decay yavaşlatmayı `apply_slow()` yerine doğrudan `speed` üzerinden yapıyor, bu
        yüzden ikon hiç çıkmıyordu). Normal Slowed bitince/reaksiyon slow'u silince ikon
        Decay aktifse KALIYOR (frozen'da gizlenir, doğru).
      - **HIZ YÖNETİMİ DÜZELTMESİ (yan bulgu)**: yavaşlatmayı geri yükleyen 6 yer
        (`speed = original_speed`) Decay'in hız düşüşünü sessizce siliyordu, `apply_slow()`
        de `original_speed`'i Decay'li hızdan alıyordu. Artık `original_speed` = Decay'siz
        taban hız, geri yükleme `_restore_base_speed()` (= taban × mevcut Decay çarpanı).
        Decay çarpanı oran olarak uygulanıyor (`_sync_decay_stacks()`), tamamen geri alınabilir.
      - Sözlük (glossary) girdisi güncellendi: "kalıcı yavaşlatır" → "her stack 3sn sürer,
        stack'liyken ölürse patlar" (EN/TR).
      - **Ölüm patlamasına görsel eklendi** (kullanıcı isteği — eskiden hasar işleniyor ama
        hiçbir görsel yoktu, "çalışmıyor" gibi hissettiriyordu): `_vfx_decay_burst(stacks)` —
        hasar alanıyla birebir (`DECAY_BLAST_RADIUS=80`, hem hasar hem VFX bu sabiti kullanır)
        genişleyen kehribar halka + dolgu (`Line2D`+`Polygon2D`, 0.2→1.0 ölçek, 0.4sn fade) +
        stack sayısıyla artan `CPUParticles2D` kıvılcım (8 + stack×5) + patlamadan hasar alan
        her düşmanda kehribar `_react_flash`. Spike Core'un manuel tetiklediği patlamada da
        aynı görsel çıkar. **Bilinen istisna**: WormHole `die()` çağırmadan `queue_free()`
        yaptığı için WormHole ile yutulan Decay'li düşman patlamaz.
      - **Halka düzensiz/zikzaklı yapıldı (kullanıcı isteği)**: mükemmel daire yerine her
        patlamada rastgele 22-28 köşeli, tepe/çukur değişen (dışa %88-100, içe %50-78 yarıçap)
        çokgen (`LINE_JOINT_SHARP`, hafif rastgele dönüş). En dış uç hasar yarıçapını (80px)
        aşmaz → görsel alanı olduğundan büyük göstermez.
      - **Decay'li ölüm → `brutalDeath` animasyonu (kullanıcı isteği)**: `die()`'da
        `_on_decay_death()` stack'leri silmeden ÖNCE `_died_decayed = decay_stacks > 0`
        yakalanıyor; `anim_type` seçiminde `cause == "brutal" or _died_decayed` en üst
        öncelik (burn/frozen/electric'in önünde). 7 temel düşman tipinin HEPSİNDE dört ölüm
        animasyonu da mevcut (`assets/effectiveDeathAnimations/`, doğrulandı — eski "cyberShotgun'ın
        brutal'ı yok" notu geçersiz); kodda animasyon bulunamazsa normal `died_`'e düşen
        güvenlik yedeği zararsızca duruyor. **Not**: Spike Core
        patlamayı ölümden ÖNCE tetikleyip stack'leri sildiği için, o düşman sonradan ölürse
        brutal almaz (o an stack'i kalmamıştır). **Kullanıcı kararı (2026-09-20): bu istisna
        bilinçli olarak KALSIN** — Spike Core sadece pasif tetikleyici, öldürücü olmayan
        vuruşta düşmanı öldürmemeli/brutal yapmamalı. Öldürücü vuruşta ise zaten çalışıyor:
        `_hit_subject()`'te hasar (`take_damage`) Decay/Spike satırlarından ÖNCE işlendiği için
        düşman o vuruşta ölürse `die()` stack'leri görüp brutal + ölüm patlaması verir, ardından
        Spike kontrolü boşa düşer (stack'ler temizlenmiş, çift patlama yok). Patlama
        `_on_decay_death()` içinde kendine hasar vermez.
      - **BUG FIX (kullanıcı fark etti: "öldüğü halde ayakta öylece durdu", 2026-09-20)**:
        `base_enemy.gd::die()` içindeki **Virus Beacon Core** bloğu, `is_dead=true` ve ölüm
        animasyonundan ÖNCE `await create_timer(...)` ile toplam ~3sn (0s+1s+2s) bekliyordu —
        Virus'lu düşman Virus Beacon Core'un 80px'inde ölürse canı bitmesine rağmen ~3sn ayakta
        kalıyor, skor/animasyon o kadar geç işleniyordu (ve `create_timer` pause'da da akıyordu).
        Yayılma artık ayrı bir coroutine'e (`_virus_beacon_spread(ball)`, `await`'siz çağrı,
        `process_always=false`) çıkarıldı, `die()` beklemeden devam eder. **Belirsiz kalan**:
        aynı belirti upgrade ekranı (`get_tree().paused=true`) ölüm animasyonunun ortasına
        denk gelirse de görülebilir (AnimatedSprite2D pause'da donar, menü kapanınca devam
        eder) — debug `× 8.0` XP çarpanı level-up'ı çok sıklaştırdığı için bu tesadüf kolay.
        Kullanıcı hangisi olduğunu netleştirirse (kalıcı mı kaldı, kart seçince düştü mü)
        buradan devam edilir. Taranan ve TEMİZ çıkan: `health -=` ile direkt hasar veren
        tüm yollarda (`base_enemy.gd`) `die()` kontrolü mevcut.
      **Cyclone Calamity review'i TAMAMLANDI** (Data Storm, Backdoor, Bounce Barrage, Mirror
      Image, Systemic Failure, Glitch Bomb, System Crash, Decay Field; Virus Rain kaldırıldı).
      Sonraki: Leila'nın Wildfire'ı (🔥💥, hiç review edilmedi — `_yard_subjects()` ve yayılma
      döngüsü bug'ları zaten düzeltildi, açıklama/requires/VFX kaldı).

- [x] **Wildfire (209, 🔥💥) — 2026-09-21**: Leila'nın epic Calamity'si (min_level 4). Avlu'daki
      Burning düşmanlar patlar (10 hasar) + yakındaki (120px) yanmayan en fazla 2 düşmana Burning
      yayar. Bu kart Leila Calamity review'inde atlanmış kalmıştı (8. kart). **BUG**: döngü canlı
      listeyi gezerken `apply_burn()` ile yeni tutuşanlar da aynı kullanımda patlıyordu
      (zincirleme, sıraya bağlı) + yayılma hedefi zaten yanansa sayaç boşa gidiyordu → yanan
      düşmanların listesi ilk filtre çağrısında DONDURULUYOR (`_ids`), yayılma sadece
      yanmayanlara, zincir yok. Requires: `requires_any: [18, 65]` (Pyro/Prism Core). Dil: EN
      Türkçe idi → düzeltildi, `lang.gd`'ye TR (209) eklendi, "Burning" bold. **VFX**: "The Yard
      Engine" (`_vfx_yard_engine`, turuncu çizgiler, sadece yanan düşmanlara filtreli), patlayan
      düşmanda turuncu `_react_flash`. İKON `🔥💥` iki glyph — kullanıcı sonra çizdirecek.
      Debug slotları: `["🔥", "🔥💥", "🔥💥"]` + `queue_upgrade_ball("fire")` (test bitince kaldır).

### Debuff Süreleri Yeniden Ayarlandı + Thermal Vision/Overheat (2026-09-21, kullanıcı kararı)
Amaç: Calamity/element reaksiyonlarında top dönmeden debuff bitmesin. `base_enemy.gd` başında
tek yerden ayar sabitleri: `BURN_DURATION=6`, `BURN_TICK_INTERVAL=2`, `WET_DURATION=6`,
`ELECTRIFIED_DURATION=6`, `SLOW_DEFAULT_DURATION=6`, `FROZEN_DURATION=3` (Frozen bilerek kısa —
tam donma). Slowed'ın SADECE varsayılan süresi (süre vermeyen çağrılar: Cryo Core vb.) 6sn oldu;
açık süre veren çağrılar (Anchor 0.5s, Tracer 0.5s, bazı 2s/3s) dokunulmadı.
- **Burn**: 3 tick x 2sn aralık, 2 hasar/tick (toplam 6, eskiden 3 tick x 1sn). Tick sayısı artık
  süre bazlı: `round(burn_dur / tick_interval)`; Elemental Memory (86) süreyi x2, Arcane Mind (80)
  ilk-element çarpanı süreyi çarpar (eskiden tick sayısını çarpıyordu). Timer `process_always=false`
  (pause'da durur). **Diğer debuff timer'ları (`apply_frozen/wet/electrified/slow`,
  `_react_electrocute`, `_register_corpse`) hâlâ pause korumasız — açık iş.**
- **Thermal Vision (73)** yüzde bazlı `burn_damage_mult` KALDIRILDI (`int(2.0*1.2)=2` yüzünden
  üç seviyesi de hiçbir şey yapmıyordu, kart fiilen ölüydü). Yeni: `player.burn_bonus_dmg`
  Lv1:+1 Lv2:+2 Lv3:+2 tick hasarı, Lv3'te ayrıca `burn_fast_ticks` (1.5sn aralık → 4 tick).
  Toplam Burn hasarı 9 / 12 / 16. Dynamic desc (`lang.gd` 73) + EN kart açıklaması güncellendi.
- **Overheat (83)** eşikleri 45/35/25 → **30/25/15** (tick aralığı yarıya indiği için sayaç yavaş
  dolar, bu telafi). Kart EN açıklaması 33→30, `lang.gd` fallback 30.
- **Arcane Mind (80)** çarpanları 1.5/2/3 → **7/6, 8/6, 9/6** (6sn'lik debuff 7/8/9sn olur; 18sn'ye
  çıkması aşırıydı). Açıklama artık "6 yerine N sn" gösterir (`lang.gd` 80 + EN kart açıklaması).
- **Pause koruması tamamlandı**: `apply_frozen/wet/electrified/slow`, `_react_electrocute` (0.8sn),
  `_register_corpse` (15sn) timer'ları `create_timer(..., false)` — level-up menüsünde debuff
  süreleri artık akmaz. (`base_enemy.gd`'de korumasız `.timeout` kalmadı.)
- Burn Frenzy (201) tick başına bonus verir (tick azaldığı için toplamı düşer, dokunulmadı).

### BUG FIX: Cesetlerde elem-indicator görünmeye devam ediyordu (2026-09-21)
`die()` sadece ÖNCEDEN açık göstergeleri gizliyordu (`visible=false`), sonradan çağrılan
`_show_debuff()` ölü düşmanda yeni gösterge yaratabiliyordu. Kaynak: `apply_antivirus()`'te
`is_dead` kontrolü yoktu (Virus Beacon Core'un yayılma döngüsü cesetleri de tarıyor) →
ceset üzerinde "virus" ikonu açılıyordu. Fix: `_show_debuff()` başına `if is_dead: return`
(hepsine genel koruma) + `apply_antivirus()` başına `if is_dead: return`.
**Asıl sebep (Burn/Wet için, kullanıcı gözlemi)**: `apply_burn/wet/electrified/slow` önce
`_check_reaction()` çağırıyor; reaksiyon hasarı (Melt/Steam/Cryostatic vb.) düşmanı ÖLDÜRÜRSE
fonksiyon `is_instance_valid(self)` kontrolünden geçip (ceset silinmediği için hâlâ geçerli)
devam ediyor, cesede `is_burning`/`is_wet` set edip gösterge açıyor ve tick timer'ı
çalıştırıyordu. 4 yerde kontrol `if not is_instance_valid(self) or is_dead: return` yapıldı.

### Prism Core (65) → diğer Connected Core'larla aynı mimariye taşındı (2026-09-23)
Echo Core (19) düzeltmesi sırasında kullanıcı, Prism Core'un TEK istisna olduğu izlenimini
düzeltti ("epey bi connected core var, hep şaşırıyorsun") — Prism Core zaten çoktan beri
Connected Core'du, sadece tarihsel olarak diğerlerinden (`is_inner_core`+`inner_core_type`
string dispatch) FARKLI, kendi ayrı `can_orbit` boolean bayrağıyla çalışıyordu (Prism Core
Connected Core sisteminin ilk örneğiydi, sonra gelen ~18 Connected Core'un hepsi
`inner_core_type` desenine geçti ama Prism hiç taşınmadı). Kullanıcı "kafa karıştırmasın,
diğerleriyle aynı yap" dedi, bozulma riski taşımadığı doğrulanınca uygulandı:
- `ball_launcher.gd`'nin "orbit" spawn case'i (bu string ball_type komutu, isim değişmedi)
  artık `can_orbit=true` yerine `inner_core_type="prism_core"` set ediyor (`is_inner_core`
  zaten vardı).
- `ball.gd`: `can_orbit` bayrağı komple silindi. Eski `_prism_apply_random_element()`
  tetikleme mantığı (`_physics_process`'teki ayrı `if can_orbit and state=="orbiting"`
  bloğu) kaldırıldı, aynı davranış (her 2s: 55px içindeki TÜM düşmanlara — mist_core'un
  aksine tek hedef değil — bağımsız rastgele element) artık `_inner_core_tick()`'in
  `"prism_core":` case'i içinde, diğer Connected Core'larla aynı `_inner_tick_timer_b`
  deseniyle çalışıyor. Sprite seçimi de genel `inner_folders` dict'ine taşındı
  (`"prism_core": ["orbitCore", 17]`), eski ayrı `elif can_orbit:` dalı silindi.
  `_auto_fire()`'daki `can_orbit or is_inner_core` kontrolü sadece `is_inner_core`'a
  sadeleşti (zaten hep birlikte true oluyorlardı).
- `game_scene.gd`: `_get_ball_core_type()`'daki `ball.get("can_orbit")` satırı silindi —
  artık fonksiyonun genel `is_inner_core` fallback'i (`return inner_core_type`) devreye
  girip "prism_core" döndürüyor. UI ikon/isim sözlüklerine (`_CORE_DISPLAY_NAMES`,
  `_CORE_FOLDER_MAP`) `"prism_core"` anahtarı eklendi (eski `"orbit"` anahtarları da
  kaldı, başka bir yerde kullanılmıyor ama zararsız).
- `player.gd`: Hydro Pressure'ın (67) iç yörünge hız bonusu kontrolü — eskiden
  `inner_core_type == "mist_core" or can_orbit == true` — artık
  `inner_core_type in ["mist_core", "prism_core"]` (tek liste, aynı iki core'u kapsıyor).
- Kart havuzu index→ball_type string eşlemesi (`65: "orbit"`) ve pickup handler'daki
  `queue_upgrade_ball("orbit")` çağrısı **değişmedi** — "orbit" burada sadece bir spawn
  komutu adı, `can_orbit` bayrağıyla aynı isim olması tesadüf, karıştırılmamalı.
- `player.gd`'deki `ball.get("can_orbit")` içeren 4 satır (`add_to_orbit`/`_fire_ball`,
  `orbit_balls`/magazine kuyruğu için) bilerek dokunulmadı — Prism Core zaten
  `is_inner_core=true` olduğu için `add_to_orbit()`'te erken `return` ile
  `inner_orbit_balls`'a gidiyor, bu 4 satıra hiç ulaşmıyordu (zaten ölü kod o satırlar
  için), `.get()` kullandıkları için var olmayan property'de de crash etmiyorlar.

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
- [x] ~~Cesetler kalıcı yapıldı (fade out kaldırıldı)~~ — **GEÇERSİZ (2026-09-20 düzeltildi)**:
      sonradan süreli sisteme dönülmüş (`1f33c94`); güncel davranış: ceset **15sn** yerde
      kalır, 1.5sn'de solup `queue_free()` olur (`base_enemy.gd::_register_corpse()`). Eski
      "10+ ceset olunca kan efektiyle yok ol" sisteminin kalıntıları (`_corpse_queue`,
      `_MAX_CORPSES`) kullanılmadığı için silindi.
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

## Playtester Tam Tarama — Ölü Kod + Asset Temizliği (2026-09-23)

Kullanıcı isteğiyle `/playtester` genişletilmiş kapsamda çalıştırıldı: kart review'i
zaten tamamlanmıştı (bkz. yukarıdaki tüm "TAMAMLANDI" bölümleri), bu turda odak ölü
kod ve kullanılmayan asset'lere kaydı.

**Ölü kod bulundu ve SİLİNDİ (kullanıcı onayı, 2026-09-23)**: `ball.gd`'de
`_reload_to_launcher()` → `_get_ball_type_str()` → `ball_launcher.gd::
queue_reload_ball()` zinciri — hiçbir yerden çağrılmıyordu, üçü de silindi.
`launch_with_speed()` (ball.gd:467) de kullanıcı onayıyla silindi — tek çağıranı
hiç olmamıştı.
`fusion_zone.gd` ile ilgili eski "kaldırıldı" notu **yanlış alarmmış** — hâlâ aktif
kullanılıyor (`game_scene.gd`'de "fusion_zone" grubu üzerinden), not geçersiz sayıldı.

**Asset temizliği yapıldı (669 dosya silindi, commit `7fa09a6`)**: arka plan agent'ı
`assets/` altındaki tüm görselleri kod referanslarıyla (literal path + dinamik
`"res://.../%s/frame_%03d.png"` desenleri + `ResourceLoader.exists` guard'ları)
karşılaştırdı. Kullanıcı onayıyla silinenler:
- `assets/projectiles/` (mermiler `bullet.gd`'de `_draw()` ile procedural çiziliyor)
- `assets/selectCharacters/` (hiç referans yok)
- Kaldırılmış kartların yetim art dosyaları: `virus_rain_art.png`,
  `catalyst_pulse_core_art.png`, `elemental_shield_core_art.png`, `iron_fortress_art.png`
- Silinmiş kartların top sprite'ları: `assets/balls/prismaticCore/`,
  `assets/balls/tempestCore/`, `assets/balls/catalystPulseCore/`
- `assets/VFX/disappearanceOfBlood/`
- 3 tekil eski render: `Cyclone729x1281.png`, `LeilaNew.png`, `Vector721x1351.png`
- Frantic Subject'in kullanılmayan ham sprite klasörleri (`rotations/`,
  `animations/High_Kick-.../`, `animations/Running-.../` — gerçek yürüme/ölüm
  animasyonları ayrı `sheets/` klasöründen ve `animations/died/`den geliyor)

**DOKUNULMADI (belirsiz, kullanıcı kararıyla)**: `assets/placeHolder/` altındaki ~40
dosya (çoğu "Gaming/" alt klasöründe) — büyük "sheet" görselleri, `AtlasTexture` ile
alt bölge olarak `.tscn`'de kullanılıyor olabilirler, agent tam emin olamadı. Silinmedi.

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

## Credits ekranı eklendi (2026-09-25)
Ana menüye CREDITS butonu (`BtnCredits`, Quit bir kademe aşağı, y=837) + basit overlay (`_on_credits`, `main_menu.gd`): "Silver font by Poppy Works — CC BY 4.0" (CC BY atıf şartı karşılandı). İleride başka atıflar `body.text`'e eklenir. `mm_credits` Lang anahtarı (TR: KREDİLER). Oyunda denenmedi.

## Credits ikonu + ekran yenileme + pembe Geri butonları (2026-09-25)
`menuIcons/credits.png` (yıldız benzeri 10x10 ikon) Credits butonuna bağlandı. Credits ekranı pause menüsü stiline çevrildi (95px sarı başlık, cyan başlık + açık renk satır; yeni atıflar `_on_credits` içindeki `lines` listesine eklenir). Credits ve pause-Ayarlar "Geri" butonları Quit'teki pembe renge (`back.png` ikonlu) çevrildi. Oyunda denenmedi.

## SFX sistemi kuruldu — UI sesleri bağlandı (2026-09-26, oyunda denenmedi)
Yeni autoload `Sfx` (`sfx.gd`, `project.godot`): 8'lik ses havuzu, pause'da da çalar. `Sfx.play("ad")` → `assets/sfx/ui/ad.ogg`. **Her Button'a otomatik** hover (`hover`, -8dB) + click (`menuClick`) bağlanır (`node_added`). Pembe (Quit/Geri) ve kırmızı (Kapat) font rengi → `backQuitCancel`. Butona özel: `set_meta("sfx_click", "ad")` / `""` (sessiz). Özel bağlar: karakter seç `characterSelect`, ok butonları `characterSwipe` (`_slide`), COLLECT `chipCollect`, satın alma `purchase`, yetersiz bakiye `errorBuzz` (buton artık disabled değil), Yeni Oyun EVET `confirmClick`, pause `pause`/`unpause`, level-up ekranı açılışı `selectCardScreen` (belirsizdi, `show_upgrade_menu` başına bağlandı). Ses listesi: `SFX_LISTESI.md`. SFX bus'ı yok (Master'dan çalar).
**SFX format notu (2026-09-26):** indirilen `.ogg` dosyaları aslında **Ogg FLAC** çıktı — Godot yalnızca **Ogg Vorbis** import eder (`valid=false`, "Failed loading resource"). 12 UI sesi Python `soundfile` ile Vorbis'e çevrildi (FLAC'ı Ogg'den çıkarıp STREAMINFO uzunluğu yamalanarak). Yeni ses indirilirse aynı sorun çıkabilir: `head` ile `vorbis` geçiyor mu bak; `fLaC` geçiyorsa çevir. `SFX` bus'ı `Sfx.play()` içinde çalarken seçilir.

## Ölüm iris-out efekti (2026-09-26, oyunda denenmedi)
`show_game_over()` artık önce `_play_death_iris()` çağırıyor: oyuncunun ekran konumunda (`get_global_transform_with_canvas().origin`) merkezlenen sert kenarlı siyah daire shader'ı (CanvasLayer 100, `step()` ile), yarıçap 1400→0 1.2sn (QUAD ease-in), ardından 0.5sn siyah bekleme, sonra Game Over ekranı. Sahne donuk (paused). Ölüm sesi henüz yok (SFX_LISTESI #122).
- Ölü kod temizlendi (2026-09-26): `player.gd` `play_death()` + `_vector_dead` silindi (tscn'de 'death' animasyonu yoktu, hiç çağrılmıyordu).

## Vector ölüm animasyonu bağlandı (2026-09-28, oyunda denenmedi)
Kullanıcı `assets/charsRedesign/vector/death/` altına 33 frame'lik gerçek ölüm animasyonu
ekledi. `player.gd`'ye geri eklendi: `_vector_dead` bayrağı + `play_death() -> bool` (SpriteFrames'e
"death" animasyonu — 14fps, non-loop, 33 frame — eklendi `_setup_vector_sprite_new()`'de) +
`death_anim_duration()`. `_process`/`_update_vector_animation` artık `_vector_dead` iken sprite'ı
ezmiyor. **Pause sırasında oynaması için**: `play_death()` çağrıldığında SADECE `$VectorSprite`
node'unun `process_mode`'u `ALWAYS` yapılıyor (Player'ın tamamı değil — Player paused kalınca
input/hareket/fizik donuyor, sadece AnimatedSprite2D'nin kendi iç oynatma mekanizması pause'u
görmezden geliyor).

`game_scene.gd::player_damaged()`: HP 0'a inince artık `get_tree().paused=true`'dan ÖNCE
`play_death()` çağrılıyor (Vector değilse veya "death" animasyonu yoksa `false` dönüp no-op —
Leila/Cyclone şimdilik hâlâ donuk kalıyor, animasyonları gelince aynı desenle eklenecek).
`show_game_over(death_dur)` artık iris-out'tan ÖNCE `death_dur` (33/14 ≈ 2.36sn) kadar bekliyor —
animasyon bitene kadar sahne "donmuş" görünüyor ama aslında Vector'un ölüm animasyonu oynuyor,
ardından iris kapanıp Game Over ekranı geliyor.

### Düzeltme: iris ile ölüm animasyonu paralel oynuyor (2026-09-28, aynı gün)
Kullanıcı: "ölürken aynı sırada iris de oynasa". Eskiden iris, `death_dur` (≈2.36sn) kadar
bekleyip ONDAN SONRA başlıyordu. Artık `play_death()` çağrıldığı anda hem ölüm animasyonu
HEM iris aynı anda başlıyor — `_play_death_iris(hold_time)` 1.2sn'de kapanıyor, kapandıktan
sonra `hold_time = max(0.5, death_dur - 1.2)` kadar siyah bekliyor (yani toplam siyah-kalma
süresi ≥ ölüm animasyonu süresi) — animasyon iris'in arkasında saklı bitiyor, iris açılıp
geri sahneyi göstermeden direkt Game Over ekranına geçiyor.

### Düzeltme 2: iris kapanma süresi ölüm animasyonuna eşitlendi (2026-09-28, aynı gün)
Kullanıcı: "frame'lerin hepsi oynamadan iris kapanıyor". Sabit 1.2sn yerine daire artık
`death_dur`'a (33 frame ≈ 2.36sn) göre kapanıyor — `_play_death_iris(close_duration,
hold_time=0.4)`, animasyon TAM bitince daire de tam kapanıyor, ardından 0.4sn sabit siyah
bekleme + Game Over ekranı.

### 14 kareye indirilen animasyon — slow motion (2026-09-28, aynı gün)
Kullanıcı ölüm animasyonunu 33'ten 14 kareye indirdi ama "iris kapanma süresi aynı kalsın,
animasyon yavaşlasın (slow motion)" istedi. `DEATH_ANIM_FRAME_COUNT`/`DEATH_ANIM_DURATION`
sabitleri ayrıştırıldı — toplam süre (2.357sn, eski 33/14fps ile birebir) sabit tutulup
oynatma hızı `frame_count / duration` ile yeniden hesaplanıyor (14/2.357 ≈ 5.94fps — normal
yürüme 10fps'in çok altında, göze belirgin bir yavaşlık/slow-motion hissi veriyor).
`death_anim_duration()` hâlâ aynı süreyi döndürdüğü için iris kapanma süresi (game_scene.gd,
`close_duration = death_dur`) otomatik senkron kaldı, ayrı bir değişikliğe gerek kalmadı.

## Leila ölüm animasyonu bağlandı (2026-09-28, aynı gün, oyunda denenmedi)
Vector ile aynı desende: `assets/charsRedesign/leila/animations/death/` (14 kare, Vector'unkinden
farklı olarak `animations/` altında, doğrudan `charsRedesign/leila/` altında değil). `play_death()`
genelleştirildi — artık `character_type`'a göre Vector ya da Leila'nın sprite'ını oynatıyor.
Leila'da ayrı bir `_leila_dead` bayrağına gerek kalmadı: `_update_leila_animation()` zaten
`_leila_oneshot` iken erken çıkıyor ve Vector'daki gibi "animasyon durunca idle'a geri dön"
şeklinde bir 2. bekçi (`_process`'teki vector-özel blok) Leila'da hiç yok — tek gereken
`_on_leila_anim_finished()`'a `animation == "death"` guard'ı eklemekti (oneshot flag'i
sıfırlanmasın, son karede donuk kalsın). Süre/hız mantığı Vector'la birebir aynı:
`LEILA_DEATH_ANIM_FRAME_COUNT` (14) / paylaşımlı `DEATH_ANIM_DURATION` (2.357sn) = fps,
`death_anim_duration()` her iki karakter için de aynı sabit süreyi döndürüyor, iris zaten
buna göre senkronlanıyor (game_scene.gd tarafında değişiklik gerekmedi). Cyclone'un ölüm
animasyonu hâlâ yok, gelince aynı desenle eklenecek.

## Cyclone ölüm animasyonu bağlandı (2026-09-28, aynı gün, oyunda denenmedi)
Vector/Leila ile aynı desende: `assets/charsRedesign/cyclone/animations/death/` (14 kare).
Cyclone'un Leila'dan farkı: hiçbir "tek seferlik animasyon" (oneshot) mekanizması yoktu —
`_update_cyclone_animation()` her frame doğrudan `velocity`'e göre walk/idle atıyordu, ölümü
ezmemesi için yeni `_cyclone_dead` bayrağı eklendi (Vector'daki `_vector_dead`'in eşdeğeri).
`play_death()`'e üçüncü dal eklendi. Süre/hız Vector/Leila ile birebir aynı: `CYCLONE_DEATH_
ANIM_FRAME_COUNT` (14) / paylaşımlı `DEATH_ANIM_DURATION` (2.357sn). **3 karakterin de ölüm
animasyonu artık bağlı** — `game_scene.gd` tarafında hiçbir değişiklik gerekmedi, `play_death()`
zaten `character_type`'a bakıp doğru sprite'ı seçiyor.

## Ölüm sesi + müzik durdurma (2026-09-28, oyunda denenmedi)
Kullanıcı `assets/sfx/characters/death.ogg` ekledi (3 karakter için ortak, zaten Vorbis).
`Sfx`'e genel `play_path(path, volume_db)` eklendi (UI klasörü dışındaki tam yoldan tek
seferlik ses — `play()`'in altyapısı `_play_stream()`'e çıkarıldı, ikisi de paylaşıyor).
`game_scene.gd::player_damaged()`'da HP sıfırlanınca (`play_death()` çağrısından hemen sonra,
pause'dan ÖNCE) gameplay müziği (`music.name = "GameplayMusic"`, yeni verildi) durduruluyor,
ardından `Sfx.play_path("res://assets/sfx/characters/death.ogg")` bir kez çalıyor (loop yok,
SFX bus'ı pause'da da akıyor — `Sfx` havuzu zaten `PROCESS_MODE_ALWAYS`).

## Vector Calamity + Yard Engine + Black Market sesleri bağlandı (2026-09-28, oyunda denenmedi)
Kullanıcı `assets/sfx/calamitys/vector/` (6 dosya), `assets/sfx/engines/yardEngineImpact.ogg`,
`assets/sfx/ui/blackMarketEntrance.ogg` ekledi (hepsi Vorbis, sorunsuz). Tümü tek seferlik
(`Sfx.play_path`), loop yok:
- **Yard Engine ateşleme sesi** (`yardEngineImpact.ogg`): hem `_vfx_yard_engine()`'in
  `_fire_bolts` hem `_vfx_yard_engine_to_point()`'in `_fire_bolt` closure'unda,
  `_screen_shake_strong()` ile aynı anda — makineyi kullanan TÜM Calamity'lerde ortak
  (Data Storm, Backdoor, Systemic Failure, System Crash, Wildfire, Gravitational Force,
  WormHole).
- **Gravitational Force + WormHole** (`gravatioanlForceWormHole.ogg`, isim kullanıcının
  kendi yazımı — dosya adı bu şekilde bırakıldı): ikisi de `_vfx_yard_engine_to_point`
  kullanıyor, `on_arrival` closure'ının (`_run_pull` / `_run_wormhole`) en başında, asıl
  görsel efekt (vorteks/solucan deliği) başlamadan hemen önce çalıyor.
- **Shockwave** (`shockwave.ogg`): `_activate_shockwave()` başında.
- **Full Breach** (`fullBreach.ogg`): `_activate_full_breach()` başında.
- **Momentum Burst** (`momentumBurst.ogg`): `_activate_momentum_burst()`'te stack kontrolü
  geçince (stack yoksa ses de çalmıyor).
- **Rampart Collapse** (`rampartCollapse.ogg`): `_activate_rampart_collapse()` başında.
- **Siege Rain** (`siegeRain.ogg`): `_activate_siege_rain()` başında (14sn'lik darbe
  dizisinin başlangıcında bir kez).
- **Black Market** (`blackMarketEntrance.ogg`): `character_select.gd::_open_shop()` başında
  — buton zaten genel `menuClick` sesini çalıyor (Sfx'in otomatik Button hover/click'i),
  bu ikisinin üzerine ekleniyor.

## Gravitational Force / WormHole sesi uzatıldı (2026-09-28, oyunda denenmedi)
Kullanıcı sesin kısa kaldığını söyledi (dosya 4.7sn, ama kısa hissettiriyordu). `Sfx.play_path()`'e
`pitch_scale` parametresi eklendi (dosyaya dokunmadan oynatma hızını yavaşlatıp fiziksel olarak
uzatıyor). `gravatioanlForceWormHole.ogg` artık `0.8` pitch_scale ile çalıyor (~4.7sn → ~5.9sn,
5sn'lik çekim/solucan deliği süresine daha yakın), yan etki olarak biraz daha derin/ağır bir ton
— vorteks hissine uyuyor. İhtiyaç olursa başka seslerde de aynı parametre kullanılabilir.

## Düzeltme: Siege Rain sesi her darbede çalsın (2026-09-28, aynı gün)
Kullanıcı: Siege Rain'in mekaniği diğerlerinden farklı (14sn boyunca 14 ayrı darbe) — ses
aktivasyon anında bir kez değil, **her düşen Siege Core'un isabet anında** çalmalı. Ses çağrısı
`_activate_siege_rain()`'in başından `_spawn_siege_rain_impact()`'in içine, `_screen_shake()`
ile aynı satıra (isabet + hasar uygulanan an) taşındı — artık 14 darbenin her birinde ayrı
ayrı çalıyor.

### Düzeltme 2: Siege Rain sesi düşüşün başında çalıyor (2026-09-28, aynı gün)
Kullanıcı: ses dosyasının kendisi zaten düşme+çarpma sırasını içeriyor (başta düşüş sesi,
sonda impact) — bu yüzden isabet anında DEĞİL, Core'un düşmeye BAŞLADIĞI anda çalmalı ki
sesin kendi impact kısmı gerçek çarpma anıyla çakışsın. Çağrı `_spawn_siege_rain_impact()`'in
başına, `burst.play("fall")`'dan hemen önce taşındı.

## Monsoon (95) VFX düzeltildi — Avlu'nun tamamını kaplıyor (2026-09-28, oyunda denenmedi)
Kullanıcı fark etti: görsel "kötü duruyordu". Kök sebep: `_play_monsoon_vfx()` 256×240'lık
yağmur damlası sprite'ını hiç büyütmeden Avlu'nun (~1535×825px) tam ortasına koyuyordu, 0.5sn
(4 kare × 8fps) sonra kayboluyordu — mekanik (tüm Avlu'daki düşmanlara Wet) ile görsel kapsamı
tamamen uyuşmuyordu, ortada ufak bir yama gibi kalıyordu. Fix: `AnimatedSprite2D` yerine
`TextureRect` + `STRETCH_TILE` — doku orijinal boyutunda bozulmadan Avlu'nun TAMAMINI
kaplayacak şekilde tekrarlanıyor (`_react_flash_screen` ile aynı sınır: x 385-1920, y
255-1080), 4 kare elle 8fps'te 3 tur (~1.5sn) döndürülüp 0.3sn'de soluyor. Mekanik
(`apply_wet`, aktivasyon anında anlık) değişmedi, sadece görsel.

## Monsoon (95) komple yeniden tasarlandı — Yard Engine + genişleyen dalga (2026-09-28, oyunda denenmedi)
Kullanıcı eski 4 karelik `rain_drops-*.png`'yi sildi, yerine `assets/VFX/monsoonVFX/frame_000-036.png`
(37 kare, 256×256, parlak mavi halka + su damlası patlaması, son karelerde damlalar dışa
savrulup soluyor) koydu. İstek: "The Yard Engine" Avlu'nun tam ortasına mavi ışın fırlatsın,
ışın ulaştığı an bu efekt oradan çıkıp Avlu sınırlarına doğru büyüyerek yayılsın, bir kez
çalışsın (loop yok) — Shockwave'in "0.6→büyük ölçek, Yard'a kırpılmış" deseniyle aynı mantık.
`_activate_monsoon()` artık `_vfx_yard_engine_to_point()` kullanıyor (hedef = Yard merkezi,
`Vector2(1152,667)` — engine zaten orada duruyor, bu yüzden çizgi kısa/anlık ama zararsız),
`on_arrival`'da hem `_yard_subjects()`'e Wet uygulanıyor hem `_play_monsoon_vfx()` çağrılıyor.
`_play_monsoon_vfx()` komple yeniden yazıldı: Shockwave'deki `Polygon2D` kırpma alanı
(x:385-1920, y:255-1080) + `AnimatedSprite2D` (20fps, 37 kare ≈1.85sn, non-loop) Avlu
merkezinde `scale` 0.6→6.0 büyüyor (`TRANS_QUAD`/`EASE_OUT`), animasyon bitince kırpma
node'u siliniyor. `fallback_fn` de aynı `_run_ripple` closure'ı (sprite eksikse zaten
`_play_monsoon_vfx()`'in kendi `total==0` guard'ı ekran flaşına düşüyor, crash yok).
Eskiden Monsoon her koşulda etki uyguluyordu (`x>=385` manuel kontrol) — artık `_yard_subjects()`
üzerinden ölü/ceset düşmanlar da hariç tutuluyor (küçük bir iyileşme, davranışı bozmuyor).

### Düzeltme: Monsoon'un merkezi görünür alana taşındı (2026-09-28, aynı gün, ekran görüntüsü)
Kullanıcı ekran görüntüsü paylaştı: dalga efekti sağa kaymış görünüyordu. Kök sebep: Yard
Engine'in tüm kartlarda paylaştığı `Vector2(1152, 667)` — bu, oyun dünyasının MATEMATİKSEL
merkezi (Avlu sınırı kod içinde x:385-1920) ama sağ UI paneli (x:1630-1920, `game_scene.tscn`
`ColorRect` ile doğrulandı) o alanın bir kısmını kapatıyor — oyuncunun GERÇEKTEN GÖRDÜĞÜ alan
x:385-1630. Küçük/ince VFX'lerde bu fark fark edilmiyordu, Monsoon'un büyük halkası belirgin
kıldı. Fix: `_vfx_yard_engine_to_point()`'e opsiyonel `engine_pos` parametresi eklendi
(varsayılan hâlâ `Vector2(1152,667)` — diğer TÜM Yard Engine kartları etkilenmedi), Monsoon
bu parametreyi ve ripple'ın kendi konumunu (`_play_monsoon_vfx(pos)`, artık parametre alıyor)
`Vector2(1007.5, 667.0)` (görünür alanın gerçek merkezi) olarak veriyor — SADECE Monsoon
etkilendi.

## Leila Calamity sesleri bağlandı (2026-09-29, oyunda denenmedi)
Kullanıcı `assets/sfx/calamitys/leila/` altına 8 dosya ekledi (Lightning/Flame Zone/
Freezing Cold/Monsoon/EMP Pulse/Volcanic Rift/Thunderstorm/Wildfire — Leila'nın 8
Calamity'sinin hepsi, hepsi Vorbis). Süreler mekaniklerle örtüşüyor (Volcanic Rift 4.01sn
= tam 4sn hasar süresi, Thunderstorm 5.04sn = tam 5sn, Freezing Cold 13.39sn ≈ fırtınanın
Avlu'yu gezme süresi). 7'si aktivasyon anında bir kez çalıyor (`Sfx.play_path`, Vector
Calamity'lerle aynı desen): Lightning, Flame Zone, EMP Pulse, Wildfire, Volcanic Rift,
Monsoon (`_run_ripple` closure'ının başında, ışın ulaşınca), Thunderstorm (aktivasyon anı).
**Thunderstorm'a özel ek**: kullanıcı isteğiyle `thunderStorm.ogg` aktivasyonda bir kez
çalmanın YANINDA, 5sn boyunca her çarpmada (`_vfx_lightning()` çağrısıyla aynı satırda,
saniyede 2 hedef) AYRICA `lightning.ogg` de çalıyor — iki ses üst üste biniyor.
**Freezing Cold bağlandı, sonra fırtınanın ömrüne senkronlandı (2026-09-29, aynı gün)**:
ilk denemede `freezingCold.ogg` (13.39sn) `_activate_freezing_cold()` başında sabit
çalıyordu — ama fırtınanın rotası (waypoint'ler) her seferinde RASTGELE, gerçek gezinme
süresi genelde 13.39sn'den kısa, bu yüzden fırtına ekrandan çıkıp küçüldükten sonra da
ses bir süre daha ötmeye devam ediyordu (kullanıcı: "sahadan çıktığında azalarak
kaybolmuyor"). Fix: `Sfx.play_path` yerine `_vfx_freezing_cold()` içinde özel bir
`AudioStreamPlayer` (`storm_audio`) oluşturulup fırtınanın kendisiyle aynı anda
başlatılıyor, fırtına küçülüp kaybolmaya başladığı TAM anda (`shrink_tw` ile paralel)
sesin `volume_db`'si de 0.8sn'de -40'a inip duruyor/siliniyor — artık ses fırtınanın
GERÇEK (rastgele) süresine otomatik uyum sağlıyor, sabit 13.39sn dinlemek zorunda
kalınmıyor.

**DEBUG**: test için ilk 3 Leila Calamity'si (⚡ Lightning / 🔥 Flame Zone / ❄️ Freezing
Cold) `_ready()`'de otomatik slota ekleniyor. **Test bitince kaldırılmalı.**

## EMP Pulse ekran flaşı kaldırıldı + level-up ekranında SFX artık susuyor (2026-09-29)
- **EMP Pulse (96)**: `_react_flash_screen(Color(0.3, 0.6, 1.0, 0.5))` çağrısı silindi —
  isabet alan düşmanlarda zaten `_vfx_lightning_bolt` + hit-flash var, ekran flaşı fazlaydı
  (Full Breach/Rampart Collapse'daki aynı kararın devamı). `_screen_shake_small()` kaldı.
- **SFX pause/level-up kontrolü**: kullanıcı fark etti, oyun-içi tek seferlik sesler
  (calamity, ölüm) level-up/iskarta ekranı açıkken durmuyordu — Godot'ta ses çalma
  SceneTree pause'undan bağımsız çalışıyor, `paused=true` olsa bile devam ediyor. Fix:
  `sfx.gd`'ye ikinci bir bus eklendi — **"GameplaySFX"** ("SFX" bus'ına send ediliyor,
  yani ayarlardaki SFX sürgüsünü hâlâ takip ediyor). `play()` (UI hover/click) hâlâ
  doğrudan "SFX" bus'ında, hiçbir zaman susturulmuyor. `play_path()` (tüm calamity/ölüm
  sesleri) artık "GameplaySFX"te. Yeni `Sfx.set_gameplay_muted(bool)` — `upgrading = true/
  false` olan HER 6 noktaya (`show_upgrade_menu`, `_on_skip`, `_on_upgrade_selected`,
  core-iskarta ekranının aç/kapat/iptal 3 noktası) eşleştirilip çağrıldı. Freezing Cold'un
  özel `storm_audio`'su da "SFX" yerine "GameplaySFX" bus'ına taşındı, o da artık
  kapsanıyor. Menüdeki buton tıklama/hover sesleri etkilenmiyor, sadece o anda çalan/
  başlayacak calamity/ölüm sesleri susuyor (mute, pause değil — menü kapanınca kaldığı
  yerden DEVAM ETMEZ, yeni tetiklenen sesler duyulur).

### Düzeltme: Pause menüsünde de SFX susmuyordu (2026-09-29, aynı gün)
Önceki düzeltme sadece `upgrading` (level-up/iskarta) noktalarını kapsıyordu — asıl
duraklatma menüsü (`_show_pause_menu`) AYRI bir kod yolu, `upgrading` hiç set etmiyor,
o yüzden hâlâ susmuyordu. `_show_pause_menu()`'ye `Sfx.set_gameplay_muted(true)`,
`_on_resume()`'a `set_gameplay_muted(false)` eklendi. `_on_main_menu()`'ye de eklendi —
`Sfx` autoload olduğu için sahneler arası hayatta kalıyor, ana menüye dönerken
susturulmuş kalmaması için oraya da unmute eklendi.

## Flame Zone + Volcanic Rift Yard Engine'e bağlandı (2026-09-29, oyunda denenmedi)
Kullanıcı isteğiyle Gravitational Force/WormHole/Monsoon'daki aynı desen: makine sahanın
merkezinde belirip tıklanan noktaya kartın kendi renginde bir ışın gönderiyor, ışın
ulaşınca kartın MEVCUT VFX'i (Flame Zone'un alev sprite'ı / Volcanic Rift'in erüpsiyon
sprite'ı) ve hasar döngüsü olduğu gibi başlıyor — `_vfx_yard_engine_to_point(get_target_pos,
bolt_color, on_arrival, fallback_fn)` ile sarmalandı, `on_arrival`/`fallback_fn` ikisi de
aynı closure (`_run_flame`/`_run_rift`) — sprite eksikse bile kartın kendi etkisi/sesleri
hiç aksamadan aynı şekilde çalışıyor. Bolt rengi: Flame Zone turuncu `Color(1.0,0.5,0.1)`,
Volcanic Rift kırmızı-turuncu `Color(1.0,0.4,0.1)` — ikisi de kartın kendi VFX rengine
yakın. Mekanik/hasar/ses hiç değişmedi, sadece önüne ~0.7-1.3sn'lik makine giriş animasyonu
eklendi (diğer Yard Engine kartlarıyla aynı gecikme).

## BUG FIX: Thunderstorm'un fon sesi ilk Lightning çarpmasında kesiliyordu (2026-09-29)
Kök sebep: `Sfx.play_path()` HER çağrıda `AudioServer.set_bus_send("GameplaySFX", "SFX")`
çağırıyordu (redundant — zaten doğru hedefe bağlıydı) — Godot bunu bus'ı yeniden bağlama
gibi işleyip o bus'ta o an çalmakta olan başka bir sesi kesiyordu. Thunderstorm aktivasyonda
`thunderStorm.ogg`'u başlatıyor, hemen ardından (aynı saniyede) ilk çarpma `lightning.ogg`
için tekrar `play_path()` çağırınca bus yeniden bağlanıp Thunderstorm'un fon sesini
susturuyordu. Fix: `sfx.gd`'ye `_gameplay_bus_linked` bayrağı eklendi, `_route_gameplay_bus()`
artık sadece "SFX" bus'ı bulunup GERÇEKTEN bağlanana kadar (genelde oyunda bir kez, ana
menüden geçerken) çağrılıyor, sonrasında dokunulmuyor.

## Thunderstorm (98) yeniden ayarlandı — 0.saniye çarpması kaldırıldı (2026-09-29)
Kullanıcı: "hâlâ tamamı çalmıyor, Lightning önden başlıyor" — kök sebep bus yönlendirmesi
değil ZAMANLAMAYDI: eski kod `thunderStorm.ogg`'u başlatır başlatmaz (t=0) AYNI FRAME'DE
ilk dalganın `lightning.ogg`'unu da çalıyordu (while döngüsü `await`'den önce bir tur
çalışıyordu) — iki ses sıfır gecikmeyle üst üste binip biri kesiliyordu.
**Fix**: döngü artık `for _wave in range(4): await create_timer(1.0,false).timeout; ...vur...`
— ilk vuruş artık t≈1sn'de (fon sesiyle çakışmıyor), toplam **4 dalga × 2 hedef = 8 vuruş**
(eskiden 5×2=10). Kart süresi 5sn → **4sn**, EN+TR açıklamalar buna göre güncellendi.

### Düzeltme: süre 5sn'de kaldı, sadece ilk saniye sakin (2026-09-29, aynı gün)
Kullanıcı: toplam süre 5sn'de kalsın, sadece ilk saniye fon sesiyle sakin geçsin, yıldırımlar
2. saniyeden itibaren düşsün. Döngü `for _wave in range(5)` oldu — `_wave==0` turunda hiç
çarpma yok (`continue`, sadece bekliyor), 2./3./4./5. turlarda (t=2,3,4,5) vuruyor. Toplam
süre 5sn, vuruş sayısı yine 4 dalga × 2 = 8 (değişmedi). Açıklamalar "1s of calm, then...
4s" / "İlk 1sn sakin, ardından 4sn..." olarak güncellendi.

### GERÇEK BUG FIX: Thunderstorm her turda 2 kez bekliyordu (2026-09-29, aynı gün)
Kullanıcı ısrarla haklı çıktı ("koda dikkatli bak, tactical mode açık değildi") — sorun
Tactical Mode değil, BENİM önceki düzenlemedeki hataydı. Döngüyü `while elapsed<5.0` →
`for _wave in range(5)` yaparken, eski döngünün SONUNDAKİ `await create_timer(1.0,
false).timeout` satırını silmeyi unutmuştum — yeni döngünün BAŞINDAKİ await ile birlikte
her tur (0. tur hariç, çünkü `continue` bottom-await'i atlıyordu) **çift bekliyordu**:
wave=1: +1s (top) → vur → +1s (bottom) = tur başına 2sn. Sonuç: gerçek vuruşlar 2, 4, 6,
8. saniyelerde, toplam 9sn — kullanıcının kronometreyle ölçtüğü BİREBİR eşleşiyor.
**Fix**: döngü sonundaki fazladan `await` satırı silindi. Artık tek await/tur, vuruşlar
gerçekten 1, 2, 3, 4. saniyelerde (0. tur sakin), toplam 5sn.

## Shockwave halkası inceltildi — sabit kalınlık (2026-10-02, oyunda denenmedi)
Sprite ×7 büyütülünce halkanın kalınlığı da büyüyordu (Vector'da da, boss'ta da). Artık `_vfx_shockwave()`:
merkezde sabit boyutlu (0.8) sprite parlaması + yeni `shockwave_ring.gd` ile `draw_arc` halka (kalınlık
`thickness=5` px, yarıçaptan bağımsız; geniş soluk glow + ince çekirdek, yarıçap 0→final_scale×105, alfa söner).
Kalınlık için `shockwave_ring.gd::thickness`, hız için `dur` ayarlanır. Vector Shockwave ve Cyber-404 ikisi de kullanır.
Halka dalgalı yapıldı: kenar açıya göre iki sinüsle dalgalanıyor, dalgalar zamanla kayıyor (`wave_amp=12`px, `wave_count=9` — `shockwave_ring.gd`'den ayarlanır; 0 yapılırsa düz halka).

## Cyber-404 yürüme animasyonu kaynağı değişti (2026-10-03, oyunda denenmedi)
Kullanıcı `assets/enemys/cyber404/animations/animation-3e031936/south/` karelerini Aseprite'te düzenledi ama oyun hâlâ eski görseli gösteriyordu: `_setup_sprite()` "walk"u `sheets/cyber404_walk_S.png` sheet'inden (Haziran'dan beri değişmemiş) kesiyordu. Artık "walk" bu klasörden dinamik yükleniyor (`frame_000..`, 6 kare 252×252, 8fps). `sheets/cyber404_walk_S.png` artık kullanılmıyor (silinebilir). Kare düzenlerken Godot'un yeniden import etmesi için editör açık olmalı.

## BUG FIX: Cyber-404 shockwave pause/level-up'ta akmaya devam ediyordu (2026-10-03, oyunda denenmedi)
`cyber_404.gd::_shockwave()` dalgalar arası `create_timer(1.5)` kullanıyordu (varsayılan `process_always=true`) — pause/level-up ekranında sayaç akıyor, dalga duraklamış sahnede tetikleniyor, menü kapanınca iki dalga üst üste biniyordu. `, false` eklendi (pause-safe) + her dalga öncesi `is_dead` kontrolü. Dalga görselleri/hasar tween'i zaten oyunla birlikte duruyor.

## Cyber-404 rastgele silah animasyonu bağlandı (2026-10-03, oyunda denenmedi)
`assets/enemys/cyber404/animations/randomShot/` (7 kare, 252×252: namlu kıvılcımı, büyük parlama, toparlanma ×2 tur). `_setup_sprite()` "randomShot" animasyonunu dinamik yüklüyor (`RANDOM_SHOT_FPS=12` ≈ 0.58sn, non-loop); `_random_weapon()` animasyonu oynatıp `RANDOM_SHOT_FIRE_FRAME=1` (büyük parlama, ~0.08sn) gelince seçilen atışı yapıyor (3 tür aynı: tek smg / 7'li saçma / 5'li smg seri — hedef yönü ateş anında hesaplanıyor), bitince "walk"a dönüyor. 5'li seri `create_timer(0.15, false)` ile pause-safe yapıldı (öncekinde pause'da akıyordu), ölünce seri duruyor. Bu ile Cyber-404 VFX/animasyon seti tamam (walk, ring, launchMissile, randomShot, death).

## Cyber-404 ateş sesleri bağlandı (2026-10-03, oyunda denenmedi)
`assets/sfx/bosses/cyber404/` altına `machineGun.ogg` (1.52sn), `shotgun.ogg` (1.01sn), `singleShot.ogg` (0.89sn) eklendi (hepsi Vorbis). `cyber_404.gd` (`SFX_*` sabitleri, `Sfx.play_path` — GameplaySFX, pause/level-up'ta mute): **machineGun** = ring attack (animasyon hazırlığı bitince, 5 dalga başlarken bir kez; süre 5×0.3sn'ye denk) + rastgele silahın 5'li smg serisi; **shotgun** = rastgele silahın 7'li saçması; **singleShot** = rastgele silahın tek smg'si. Sesler 0 dB, ayar gerekirse `play_path(path, volume_db)`. 5'li seri 0.6sn sürüyor, machineGun 1.52sn — ses seriyi geçiyor (gerekirse pitch_scale ile hızlandırılır).
Düzeltme (aynı gün): machineGun ring attack'te görselden ~0.1sn önce bitiyordu (ses ~1.5sn, animasyonun ateş kısmı 22 kare/14fps ≈ 1.57sn). `Sfx.play_path(SFX_MACHINEGUN, 0.0, RING_SFX_PITCH=0.95)` ile hafif yavaşlatılıp süre eşitlendi. Hâlâ erken/geç bitiyorsa `RING_SFX_PITCH` ayarlanır (küçük = daha uzun).
**Asıl sebep (aynı gün, 2. düzeltme)**: machineGun ring attack'te hâlâ erken kesiliyordu çünkü `Sfx.play_path()` paylaşımlı 8'lik **round-robin havuz** kullanıyor — ring attack sırasında sık çalan başka sesler (top vuruşları `hitClassic`, calamity vb.) 8 çağrıda havuzu döndürüp uzun sesin player'ını yeniden kullanıyor, ses ortada kesiliyor (kısa sesler fark ettirmiyordu). Yeni `Sfx.play_path_dedicated(path, vol, pitch)`: sese özel geçici `AudioStreamPlayer` (GameplaySFX bus, pause'da mute'lanır, bitince kendini siler). machineGun artık bunu kullanıyor; pitch 0.95 kaldı. **Genel kural**: ~1sn'den uzun, kesilmemesi gereken sesler için `play_path_dedicated` kullan (Freezing Cold'un `storm_audio`'su ve boss teması zaten kendi player'ını kullanıyor).

## Cyber-404 randomShot 3 kareye indi + seri animasyonu (2026-10-03, oyunda denenmedi)
Kullanıcı `randomShot`'u 7→3 kareye indirdi (0 kıvılcım, 1 büyük parlama = ateş anı, 2 toparlanma; 12fps ≈ 0.25sn) — önceki uzun görsel tek atış/saçmada sesten uzun sürüyordu. `_random_weapon()` artık önce atış türünü seçiyor: tek smg / 7'li saçma → animasyon bir kez, parlama karesinde mermi (singleShot/shotgun sesleri doğal kuyruklarıyla ~1sn, görsel 0.25sn). **5'li sıralı smg** ayrı `_random_series()`: animasyon HER mermide baştan oynar (`speed_scale` ile bir tur = `SERIES_SHOT_INTERVAL=0.15sn`, mermi parlama karesinde), toplam 0.75sn; `machineGun` (1.5sn) seri bitince 0.12sn fade ile susar. `Sfx.play_path_dedicated()` artık player'ı döndürüyor (fade için). Seri bitince `speed_scale=1` + "walk".

## BUG FIX: pause/level-up'ta uzun SFX'ler kayboluyordu (2026-10-03, oyunda denenmedi)
`Sfx.set_gameplay_muted(true)` sadece GameplaySFX bus'ını mute ediyordu; player'lar (`PROCESS_MODE_ALWAYS`) çalmaya devam ediyor, pause süresince ses "sessizce" akıp bitiyordu — menü kapanınca uzun ses (örn. taramalı machineGun) yoktu. Artık `set_gameplay_muted()` ayrıca `Sfx`'in çocuğu olan, GameplaySFX bus'ındaki tüm player'larda (havuz + `play_path_dedicated`) `stream_paused = muted` yapıyor → ses pause'da DURAKLIYOR, devam edince kaldığı yerden sürüyor. `_play_stream()` yeni ses başlatırken `stream_paused=false` yapar. Not: Freezing Cold'un `storm_audio`'su ve boss teması `Sfx`'in çocuğu değil, onlar ayrı mantıkta.

## Cyber-404 rastgele atış mermileri elden çıkıyor (2026-10-03, oyunda denenmedi)
Mermiler boss merkezinden değil, `randomShot` karesindeki iki silahın namlu noktasından çıkıyor: `MUZZLE_OFFSETS` = sol (-32,+7) / sağ (+34,+7) (252×252 karede merkeze göre, flaş piksellerinden ölçüldü; dünya konumu `sprite.global_position + offset × sprite.global_scale`, boss ölçeği değişse de uyar). `_fire_from_hands(player, tip, açılar)`: her elden oyuncuya doğru, açı sapmalarıyla. **Tek atış**: her elden 1 (toplam 2); **pompalı**: her elden 3, huni -12°/0°/+12° (toplam 6, eskiden 7); **taramalı**: seri boyunca (5 atış) her atışta iki elden birer mermi (elden 5, toplam 10). Namlu yeri/huni açısı oyunda ince ayar isteyebilir.

## Cyber-404 saldırı çakışması çözüldü — tek seferde tek saldırı (2026-10-03, oyunda denenmedi)
Dört saldırının (ring 9sn, füze 15sn, shockwave 30sn, rastgele atış 4-8sn) sayaçları bağımsızdı; aynı anda tetiklenince animasyonlar birbirini eziyor, sesler/mermiler üst üste biniyordu. Artık `_physics_process`'te `_attacking` kilidi: boss meşgulken yeni saldırı başlamaz. Birden fazlası hazırsa öncelik **shockwave > füze > ring > rastgele atış**; hazır olup bekleyen saldırının sayacı sıfırlanmaz (boss serbest kalınca başlar). `_run_attack(fn)` saldırıyı bitirince `ATTACK_GAP=0.6sn` (animasyon toparlanması) bekleyip kilidi açar. Rastgele atış aralığı eskiden HER FRAME yeniden `randf_range(4,8)` ile çekiliyordu (fiilen hep ~4sn'ye yakın); artık `_random_next` bir kez çekiliyor, tetiklenince yenileniyor → gerçekten 4-8sn arası rastgele. Sonuç: pratikte saldırılar daha seyrek (bekleme süreleri eklenir); gerekirse ring/füze/shockwave aralıkları ayarlanır.

## Cyber-404 zırh görünümü + zırh kırılma efekti (2026-10-04, oyunda denenmedi)
Sprite'a shader (`ARMOR_SHADER`: `tint` + `saturation`) takıldı — kökün `modulate`'ini kullanan vuruş flaşıyla çakışmasın diye. **Zırhlıyken** çelik-mavi/parlak (`ARMOR_ON_TINT`), **zırh kırılınca** (`_armor_break_fx()`): beyaz parlama → 0.45sn'de soluk gri (`ARMOR_OFF_TINT`, doygunluk `ARMOR_OFF_SAT=0.28`) + dökülen metal parçaları (`_spawn_armor_debris()`, CPUParticles2D, sahnenin çocuğu, yer çekimli, gri degrade) + `screen_shake_heavy`. Renk/doygunluk sabitleri `cyber_404.gd` başında ayarlanır. `_armor_break()`'in 3sn sersemleme sayacı pause-safe yapıldı (`create_timer(3.0,false)`) + ölünce çıkar; eski ölü `ColorRect` satırı silindi.

## Boss durum etkisi kutusu (Sersemledi) — MMO tarzı (2026-10-04, oyunda denenmedi)
Boss can barının altına (x=800'den, element göstergesinin sağı, y=104) 40×40 durum kutusu: ikon (`assets/elemIndicators/stun.png`) + **saat yönünde süpürme** (12 yönünden başlar; kalan süre koyu bölge olarak azalır) + sarı çerçeve; **üzerine gelince** Silver fontlu açıklama kutusu (başlık "Sersemledi"/"Stunned", açıklama, kalan süre sn). `boss_status_icon.gd` (yeni Control) + `game_scene.gd::show_boss_status(id, ikon, süre, başlık, açıklama)` (aynı id yenilenir, birden fazla etki yan yana dizilir; süre dolunca kutu kendini siler, `PROCESS_MODE_PAUSABLE` → pause'da süre durur). Lang: `boss_stun_title`/`boss_stun_desc`. Şu an sadece **zırh kırılma sersemlemesi** (`cyber_404.gd::_armor_break`, `ARMOR_STUN_TIME=3.0`) kullanıyor. **Shockwave'de bilerek yok**: orada boss kendini kilitliyor (kanal/hazırlık), oyuncunun uyguladığı bir durum değil.
Sersemleme (zırh kırılması) ve shockwave kanalı sırasında yürüme animasyonu artık bulunduğu karede DONUYOR (`_freeze_walk()`/`_unfreeze_walk()`, `AnimatedSprite2D.pause()`), bitince devam ediyor — eskiden boss yerinde dururken bacakları oynamaya devam edip sersemlediği anlaşılmıyordu. Saldırı animasyonlarına dokunmaz (sadece "walk" ise).
**Renk yönü değişti (2026-10-04, kullanıcı isteği)**: zırhlıyken boss **koyu, metal kaplı** (`ARMOR_ON_TINT=(0.58,0.64,0.74)`, doygunluk 0.65), zırh kırılınca beyaz parlamanın ardından **sprite'ın orijinal rengine** dönüyor (`ARMOR_OFF_TINT` beyaz, doygunluk 1.0) — önceki "kırılınca gri" tasarımı iptal. Dökülen parçalar/sarsıntı aynen duruyor.
**Renk yönü değişti (2026-10-04, kullanıcı isteği)**: zırhlıyken boss **koyu, metal kaplı** (`ARMOR_ON_TINT=(0.58,0.64,0.74)`, doygunluk 0.65), zırh kırılınca beyaz parlamanın ardından **sprite'ın orijinal rengine** dönüyor (`ARMOR_OFF_TINT` beyaz, doygunluk 1.0) — önceki "kırılınca gri" tasarımı iptal. Dökülen parçalar/sarsıntı aynen duruyor.

## Cyber-404 yeni VFX'ler (shockwave + stunned) + boss müziği (2026-10-04, oyunda denenmedi)
Kullanıcı stun/shockwave görselinden memnun kalmadı, yeni animasyonlar ekledi: `assets/enemys/cyber404/animations/shockwave/` (13 kare: 0-2 hazırlık, 3-11 elektrik döngüsü, 12 toparlanma) ve `.../stunned/` (37 kare, kırmızı kor + kıvılcım). `_setup_sprite()` dinamik yüklüyor: `shockwaveWind` (3 kare, 8fps) → `shockwaveLoop` (9 kare, 14fps, döngü; 3 dalga bu sırada) → `shockwaveEnd` (toparlanma 0.3sn) → "walk"; `stunned` (döngü, hız = kare sayısı / `ARMOR_STUN_TIME` → tam stun süresine yayılır) zırh kırılınca oynuyor, bitince "walk". Dalga zamanlaması aynı (1.5sn arayla, ilk dalga animasyon hazırlığı sayılarak 1.5sn'de). Eski "yürüme karesinde dondur" mantığı (`_freeze_walk`) kaldırıldı; animasyon dosyası yoksa yürüme karesinde duruyor (yedek).
**Boss müziği**: `assets/sfx/ui/bossSceneTheme.ogg` (Vorbis, 178.6sn). `game_scene.gd::show_boss_bar()` → `_start_boss_music()`: oyun müziği (GameplayMusic) 1.2sn'de kısılıp DURAKLATILIR, "BossMusic" (Music bus, döngülü, -8dB) fade-in ile girer; `hide_boss_bar()` (boss ölünce) → `_stop_boss_music()`: boss müziği fade-out + oyun müziği kaldığı yerden geri gelir. Oyuncu ölürse ikisi de durur. Kullanıcı kararı: Cyber-404'ün kendi teması (`cyber404inthefield`, boss'un child'ı, GameplaySFX bus) bu müzikle BİRLİKTE çalmaya devam ediyor.

## Cyber-404 sersemleme sesleri (2026-10-04, oyunda denenmedi)
`assets/sfx/bosses/cyber404/stunned.ogg` (0.87sn) zırh kırıldığı an, hemen ardından `stunnedElectrified.ogg` (3.94sn, arızalı elektrik kısmı) çalıyor (`_armor_break()`; ikisi de `Sfx.play_path_dedicated`). Sersemleme 3sn olduğu için ikinci ses uzun kalıyor → sersemleme bitince 0.2sn fade ile kesilir. Boss ölürse ikinci ses hiç başlamaz / fade ile kesilir. Pause'da duraklar (Sfx `stream_paused` mantığı).
`stunnedElectrified` artık sersemleme bitmeden `ELEC_EARLY=0.6sn` önce 0.48sn fade ile kısılıyor (kullanıcı "biraz daha erken bitsin" dedi); daha erken için `ELEC_EARLY` büyütülür.
Zırh kırılma sarsıntısı güçlendirildi: `_armor_break_fx()` artık `game_scene._screen_shake_strong()` (±8px, ~0.4sn azalan genlik; Yard Engine çizgi anıyla aynı) çağırıyor — önceki `screen_shake_heavy` (±3px) zayıf kalıyordu. Daha güçlüsü için sarsıntı fonksiyonunun genliği `game_scene.gd::_screen_shake_strong`'dan ayarlanır.

## Boss kutudan çıkınca düşmanlar artık ölüm animasyonuyla ölüyor (2026-10-04, oyunda denenmedi)
`cyber_404.gd::_landing_wave()` eskiden sahadaki tüm `subjects`'a `queue_free()` yapıyordu (ölüm animasyonsuz, bir anda yok oluş). Artık canlı olanlara `die("brutal")` (brutal ölüm animasyonu) uygulanıyor; ölüm boss'tan uzaklığa göre kademeli (`LANDING_WAVE_SPEED=1500 px/sn` → yakındakiler önce, dalga hissi). Zaten ölü olanlara (cesetler) dokunulmuyor — eskiden onlar da siliniyordu, artık normal süreleriyle (15sn) kayboluyor. Not: `die()` normal ölüm gibi skor/data parçacığı (XP) veriyor → boss girişinde toplu ödül çıkar; istenmezse `die` yerine ödülsüz bir yol gerekir.
**Ödülsüz (2026-10-04)**: boss girişindeki toplu ölüm artık XP/skor/kill sayacı/veri parçacığı vermiyor — `game_scene.gd::kill_without_rewards(z)` (`_suppress_kill_rewards` bayrağı; `die()` `subject_died()`'ı eşzamanlı çağırdığı için `subject_died` başta erken dönüyor). Ölüm animasyonu aynen oynuyor. Not: `die()` içindeki kart etkileri (örn. Leech Nova Core +2 HP) bu ölümlerde de tetiklenebilir, ödül değil kart pasifi sayıldı.

## BUG FIX: zırh kırılınca süren saldırılar kesilmiyordu (2026-10-04, oyunda denenmedi)
Taramalı (veya ring/füze/rastgele atış) sürerken zırh kırılınca mermiler ve `machineGun` sesi devam ediyor, sersemleme animasyonu/sesleri üstüne biniyordu. Çözüm: `cyber_404.gd` — `_attack_id` sayacı; her saldırı fonksiyonu (`_ring_attack`, `_launch_missile`, `_shockwave`, `_random_weapon`, `_random_series`) başlarken `my_id := _attack_id` alır, her `await`'ten sonra `my_id != _attack_id` ise çıkar. `_armor_break()` başta `_interrupt_attacks()` çağırır: kimliği artırır, çalan taramalı sesini (`_gun_snd`, ring + seri) 0.06sn fade ile kesir, `speed_scale=1` yapar. Zırh kırılırken shockwave sürüyorsa o da iptal olur (stun animasyonu/süresi `_armor_break`'e kalır). Uçuştaki mermiler/füzeler devam eder, yeni mermi çıkmaz.

## Sandık çarpınca toz halkası (dustRing) — düşmanlar halkaya değince ölür (2026-10-04, oyunda denenmedi)
`assets/VFX/dustRing/` (25 kare, 256×256, izometrik elips halka: ~9 karede genişler, sonra söner). `game_scene.gd::_on_crate_landed()` (`crate.landed` sinyali = sandığın yere çarptığı kare, `IMPACT_FRAME=10`) → kamera sarsıntısı + `_spawn_dust_ring()` (sandığın ~90px altında, yere değdiği nokta; `DUST_SCALE=9`, `DUST_FPS=20`, z_index 1). Halka büyürken her kare değişiminde, o ana kadarki en geniş karenin **gerçek alfa sınırlarına** (`Image.get_used_rect`) göre elips içinde kalan canlı düşmanlar `kill_without_rewards(z, "normal")` ile ölür → **klasik ölüm animasyonu** (brutal değil), XP/skor yok. Boss'un kutudan çıkışındaki eski toplu ölüm (`cyber_404.gd::_landing_wave`, brutal) KALDIRILDI. Halka çok büyük/küçük gelirse `DUST_SCALE` ayarlanır (kenar-köşe düşmanlarına ulaşması için ≈9 gerekiyor).
BUG FIX: toz halkası kutudan çıkan boss'u da hedef alıyordu (halka 1.25sn sürüyor, boss ~1sn sonra çıkıyor ve `subjects` grubunda) → `die()` argüman hatası + `_suppress_kill_rewards` bayrağı takılı kalma riski. `_spawn_dust_ring` ve `kill_without_rewards` artık `boss`/`_cyber404_node`'u atlıyor.
Toz halkası ayarı (kullanıcı: "takılıyor ve aşırı büyük"): `DUST_SCALE` 9→**5**, `DUST_FPS` 20→**30**, ek olarak ömür boyunca sürekli yumuşak büyüme (scale 0.85×→1.1×, sine ease-out) eklendi; öldürme elipsi artık anlık gerçek scale'e göre hesaplanıyor. Halka yarıçapı ≈ 500×340px (sahanın merkezi etrafı; uzak köşelere ulaşmayabilir). Daha büyük/küçük için `DUST_SCALE`.

## KRİTİK BUG FIX: sandık sinyalleri her karede tekrar ateşleniyordu (2026-10-04, oyunda denenmedi)
`crate_intro.gd::_play_intro_sprite()` içindeki `_landed_fired`/`_visible_fired` YEREL `var`'lardı ve `frame_changed` lambda'sı içinde değiştiriliyordu. **GDScript lambda'ları yerel değişkenleri DEĞERE göre yakalar** — lambda içindeki `x = true` kalıcı olmaz, bayrak hep `false` kalır → `landed` (kare ≥10, ~27 kez) ve `boss_emerged` (kare ≥25) her karede yeniden yayınlanıyordu. Sonuçlar: toz halkası ~27 kez üst üste doğup ilk kareleri sürekli baştan oynuyordu ("sıkışma"), kamera sarsıntısı tekrarlıyordu; eski "kırılma sesi 7-8 kez tekrar ediyor" hatasının da muhtemel gerçek kökü bu (o zaman adlı fonksiyon + instance değişkeniyle dolaşılmıştı). Fix: iki bayrak sınıf (instance) değişkeni oldu. **Genel kural: bir lambda içinde değiştirilip dışarıda/sonraki çağrıda okunacak her durum instance değişkeni (veya Array/Dictionary) olmalı, yerel bool/int olmamalı.** Aynı kalıp başka yerde varsa aynı hata çıkar.
Aynı lambda-bool hatası `game_scene.gd::_vfx_yard_engine()` (`_bolts_fired`) ve `_vfx_yard_engine_to_point()` (`_bolt_fired`) içinde de vardı (animasyonun son 2 karesinde çizgi + sarsıntı + ses + `apply_fn` İKİ kez tetiklenebiliyordu) → bayraklar tek elemanlı Array (`[false]`) yapıldı, artık gerçekten bir kez ateşleniyor.
DEBUG: boss test tetikleyicisi 10sn → **20sn** (`game_scene.gd::_process`, `_debug_boss_triggered`) — kalabalık ortada toz halkasını görmek için. Yayına çıkmadan bu blok kaldırılacak.

## Canlı gölgeleri (2026-10-04, oyunda denenmedi)
Yeni `blob_shadow.gd` (`Polygon2D`, sahibin çocuğu): her canlıya ayak gölgesi (siyah, alfa 0.36, oval ry=0.38·rx). Boyut/konum sahibin `AnimatedSprite2D`'sinin ilk karesinin **gerçek alfa sınırlarından** hesaplanır (`Image.get_used_rect`: ayak hizası + gövde genişliği×0.40 = rx), script+scale bazında önbelleklenir (`_cache`). Sahip ölünce (`is_dead`) gölge kendini siler (ceset gölgesiz). `z_index=1` mutlak (düşmanlar 2-3 üstte, cesetler 0 altta). Takılan yerler: `base_enemy.gd::_ready` (7 temel düşman + onlardan türeyen her şey), `cyber_404.gd::_ready`, `nyx_09.gd`/`s_miler_79.gd` (`call_deferred("_attach_shadow")`). Oyuncunun gölgesi zaten `player.gd::_draw`'da vardı, dokunulmadı. Ayar: `COLOR`, `WIDTH_FACTOR`, `ASPECT`, `Z` (blob_shadow.gd başı). Boss gölgesi sahibin 2.43× ölçeğini otomatik miras alır.
Gölge ayarları (kullanıcı isteği): (1) Cyber-404 gölgesi `attach(self, sprite, 1.55, 7.0)` ile %55 genişletildi + 7 yerel px (≈17 dünya px) yukarı kaydırıldı (gövdenin arkasında kalsın, ayaklar kaplansın) — `blob_shadow.gd::attach(owner, sprite, width_mult, up)` yeni isteğe bağlı parametreler. (2) Düşen boss sandığının gölgesi artık **kare** (±64px, küçükten büyür) ve sandık yere değdiği karede (`IMPACT_FRAME`) tamamen kaldırılıyor (`crate_intro.gd::_update_fall_shadow`).
Gölge düzeltme 2: Cyber-404 gölgesi daha da arkaya (`up` 7→15 yerel px ≈ 36 dünya px). Sandık gölgesi sandığın yerdeki **izometrik ayak izine** (45° dönmüş kare / eşkenar dörtgen, ±118×±60px) çevrildi, merkezi `land_pos + (0,80)`; çarpınca yine kaybolur.
Cyber-404 gölge genişliği çarpanı 1.55 → **1.4** (hafif küçültüldü, konum `up=15` aynı).

## Player + Hasmen gölgesi, ceset süreleri, Vector'un 4 core'u (2026-10-04)
- **Player/Hasmen gölgesi**: `player.gd::_draw`'daki eski sabit gölge (ayak hizası 20px, büyük sprite'ların altında kalıyordu → görünmüyordu) silindi; Player (aktif karakterin sprite'ına göre) ve `hasmen_npc.gd` artık `blob_shadow.gd` kullanıyor. `blob_shadow.gd` sprite gizliyse (`is_visible_in_tree`) gölgeyi de gizliyor (Hasmen henüz görünmezken gölgesi çıkmasın diye) ve önbellek anahtarı sprite adını da içeriyor. Oyunda denenmedi.
- **Ceset süreleri**: temel düşmanlar (`base_enemy._register_corpse`) ölünce **15sn** yerde kalır + 1.5sn solma = ~16.5sn; Cyber-404, Nyx-09, Smiler-79: ölüm animasyonu bitince **1.5sn** sonra silinir.
- **Vector'un başlangıçta 4 core'u BUG DEĞİL**: Black Market'te `core_up` (Ekstra Orbit Slotu, "+1 Normal Core") alınmış (`ity_save.cfg [shop_vector] core_up=1`); başlangıç = 3 + shop bonusu (`ball_launcher.gd`: `_startup_balls_left = 2 + bonus` + hemen fırlatılan ilk top). Kaldırmak için save'den sıfırlanır / mağaza sıfırlama gerekir.

## Player + Hasmen gölgesi, ceset süreleri, Vector'un 4 core'u (2026-10-04)
- **Player/Hasmen gölgesi**: `player.gd::_draw`'daki eski sabit gölge (ayak hizası 20px, büyük sprite'ların altında kalıyordu → görünmüyordu) silindi; Player (aktif karakterin sprite'ına göre) ve `hasmen_npc.gd` artık `blob_shadow.gd` kullanıyor. `blob_shadow.gd` sprite gizliyse (`is_visible_in_tree`) gölgeyi de gizliyor (Hasmen henüz görünmezken gölgesi çıkmasın diye) ve önbellek anahtarı sprite adını da içeriyor. Oyunda denenmedi.
- **Ceset süreleri**: temel düşmanlar (`base_enemy._register_corpse`) ölünce **15sn** yerde kalır + 1.5sn solma = ~16.5sn; Cyber-404, Nyx-09, Smiler-79: ölüm animasyonu bitince **1.5sn** sonra silinir.
- **Vector'un başlangıçta 4 core'u BUG DEĞİL**: Black Market'te `core_up` (Ekstra Orbit Slotu, "+1 Normal Core") alınmış (`ity_save.cfg [shop_vector] core_up=1`); başlangıç = 3 + shop bonusu (`ball_launcher.gd`: `_startup_balls_left = 2 + bonus` + hemen fırlatılan ilk top). Kaldırmak için save'den sıfırlanır / mağaza sıfırlama gerekir.
**Ceset süresi değişti (2026-10-04, kullanıcı isteği)**: temel düşmanlar artık ölünce **1.5sn** (`CORPSE_STAY`) yerde kalıp 0.6sn'de (`CORPSE_FADE`) solarak siliniyor (eskiden 15sn + 1.5sn). `base_enemy.gd` başındaki sabitlerden ayarlanır. Vector'un başlangıç core'u (4) kullanıcı kararıyla olduğu gibi kaldı (Black Market `core_up` alımı).

## Toz halkası oyuncuya da hasar veriyor, dash ile atlatılır (2026-10-04, oyunda denenmedi)
`game_scene.gd::_spawn_dust_ring()`: düşmanlar ölürken oyuncu ölmez — halka **ilk kez oyuncunun üstüne geldiği anda BİR KEZ** `DUST_PLAYER_DAMAGE=3` hasar verir (`player_done` Array bayrağı; lambda yerel bool kuralı!). O anda oyuncu dash atıyorsa (`is_dashing`) ya da son dash'i `DUST_DODGE_GRACE_MS=220`ms içinde başlattıysa (dash ≈120ms + ~100ms tolerans) dalgayı atlatır, hasar almaz. `player.gd`'ye `last_dash_msec` eklendi. Halka sandık düşüşünün gölgesiyle önceden belli olur. Not: oyuncu sandığın hemen altındaysa halkanın ilk karesi anında kaplar (dash ile hâlâ atlatılabilir).

## Cyber-404 BOSS DENGESİ (2026-10-04, kullanıcı kararı — test bekliyor)
Amaç: boss ilk run'da yenilmesi neredeyse imkânsız olsun. Değerler: **Zırh 150, Can 150** (`cyber_404.gd::BOSS_ARMOR/BOSS_HEALTH`, eskiden 90/45), **mermi başına hasar 9** (`BOSS_BULLET_DAMAGE`, ring + rastgele atışların tümü; `bullet.damage` boss tarafında set edilir, diğer düşmanların mermisi 3 kalır), **füze hasarı 15** (`missile.gd::damage`), **shockwave dalga başına 15** (`game_scene.gd::BOSS_SHOCKWAVE_DAMAGE`, eskiden 2), **sandık toz halkası 15** (`DUST_PLAYER_DAMAGE`, eskiden 3). Oyuncu başlangıç canı 50 → toz halkası/füze/shockwave tek vuruşta %30. Not: ring attack (120 mermi × 9) pratikte dash/dokunulmazlık penceresine (0.3sn) bağlı; testte sertlik hissine göre bu sayılar ayarlanacak. Boss HP barı `max_armor/max_health` ile otomatik uyuyor.

## Global core hasarı -1 denendi ve GERİ ALINDI (2026-10-04, kullanıcı kararı)
Tüm core hasarlarını 1 azaltma denemesi (`CORE_DAMAGE_PENALTY`) kullanıcı isteğiyle geri alındı; core hasarları eskisi gibi. İleride gerekirse: ana isabette (`ball.gd::_hit_subject`, `take_damage(total_damage…)` öncesi) çarpanlardan SONRA düşülmesi ve `_defense_hit`'te aynı düşüş yeterliydi.
Boss can/zırh **175/175**'e çıkarıldı (kullanıcı kararı; `cyber_404.gd::BOSS_ARMOR/BOSS_HEALTH`). Diğer boss değerleri aynı.
Boss değerleri tekrar değişti: **Zırh 350, Can 150** (kullanıcı kararı; toplam 500). Zırh büyük olduğu için shockwave (zırh>0 şartı) ve zırh-kırılma sersemlemesi daha geç devreye girer.

## Core Mastery + Amp kartları TAMAMEN SİLİNDİ — core hasarı artık Black Market'ten (2026-10-04, kullanıcı kararı, oyunda denenmedi)
Kullanıcı: oyun içinde core hasarını artıran kart olmasın, oyuncu sinerjiye odaklansın; kalıcı hasar artışı Black Market'ten alınsın.
- **Silinen kartlar**: Core Mastery (11), Electric Amp (13), Cryo Amp (99), Hydro Amp (100), Pyro Amp (101), Pierce Amp (12), Split Amp (14) — kart satırları, `_UPGRADE_META`, pickup handler'lar (`elif index == 11/12/13/99/100/101/14`), `_apply_utility_level` case'leri, TEST_ELEMENTAL listesi. `player.gd`'den `pierce_bonus/electric_bonus/cryo_bonus/hydro_bonus/pyro_bonus/split_bonus` değişkenleri, `ball_launcher.gd` `max_damage` formüllerinden bu terimler, `lang.gd` Electric/Pyro/Hydro/Cryo Core dinamik açıklamalarından `*_bonus` terimleri kaldırıldı. (Kullanıcı "EMP" dedi — Amp kartları kastedildi; **EMP Pulse Calamity'sine (96) dokunulmadı**.) Cryostasis (70) orphan'ı da dokunulmadı (hasar değil).
- **Yeni Black Market öğesi**: `game_data.gd::SHOP_ITEMS` → `core_dmg_up` ("Çekirdek Güçlendirme", "Tüm core'lara +1 hasar", tüm karakterler, 100 CP +50/kademe, max 3 kademe → en çok +3 hasar). `GameData.get_shop_core_damage()`; `player.gd::_ready` bunu `ball_mastery`'ye yazıyor — `ball_mastery` zaten tüm core hasar hesaplarına (launcher `max_damage`, `_hit_subject` tipli core eklemesi, dinamik kart açıklamaları) bağlı olduğu için başka değişiklik gerekmedi. Fiyat/kademe kullanıcıya sorulmadan seçildi, ayarlanabilir.
- Kayıt dosyasında eski oyuncuların `core_dmg_up` değeri yok → 0; yeni öğe save'e satın alınınca yazılır.

## Black Market "Çekirdek Güçlendirme" kademeleri yeniden tanımlandı (2026-10-04, kullanıcı kararı, oyunda denenmedi)
`core_dmg_up` (3 kademe, 100 CP +50/kademe): **1. alım** normal core +1 hasar, **2. alım** normal core toplam +2, **3. alım** normal core toplam +3 **ve** diğer (özellikli) core'lara +1. Uygulama: `player.gd` iki ayrı değişken — `normal_core_bonus` (= alım sayısı, 0-3; normal core'un `max_damage`'ine: `ball_launcher.gd` varsayılan atama `ball_type == ""` ise, ve Mirror Image bonus core'ları `game_scene.gd`) ve `ball_mastery` (= alım ≥3 ise 1; tüm özellikli core hasar formüllerine/`_typed_core` eklemesine/dinamik açıklamalara zaten bağlıydı). Not: normal core'un hasarı `5 + normal_core_bonus` (Vector'da da 5 taban).

## Temizlik (2026-10-04, kullanıcı kararı)
Boss test tetikleyicisi (`_debug_boss_triggered`, 20sn) **kaldırıldı** — boss artık normal akışta, `BOSS_SPAWN_TIME` (600sn = 10. dakika) ile geliyor (`_spawn_section_boss`: Smiler → Cyber-404 → Nyx sırası). Kullanılmayan `assets/enemys/cyber404/sheets/cyber404_walk_S.png` (+`.import`) silindi. Cyber-404 teması (`cyber404inthefield`, mekanik robot sesi) boss müziğiyle birlikte çalmaya devam edecek — bilinçli tasarım. `× 8.0` XP/upgrade çarpanı ve `_ready()`'deki test Calamity slotları kullanıcı isteğiyle **şimdilik duruyor** (yayından önce kaldırılacak).
DEBUG (2026-10-04): S-Miler testi için `BOSS_SPAWN_TIME` **600 → 10.0** (oyunun 10. saniyesi; ilk boss sırası Smiler). **Test bitince 600.0'a geri alınmalı.**

## S-Miler-79 boyu büyütüldü — Cyber-404 gövdesi kadar (2026-10-04, oyunda denenmedi)
`s_miler_79.gd`: sprite ölçeği 0.9 → **1.84** (`SPRITE_SCALE`; 232px karede gövde 103×100px → dünya ≈ 190×182px, Cyber-404'ün görünen gövdesiyle aynı), çarpışma kapsülü `SIZE_MULT=SPRITE_SCALE/0.9≈2.04` ile orantılı büyüdü (yarıçap 45, yükseklik ~90). Gölge (`blob_shadow.gd`) sprite ölçeğinden otomatik hesaplandığı için kendiliğinden büyür. Füze VFX/uyarı çemberleri/hareket aralıkları dokunulmadı — büyük gövdeyle ayarı gerekebilir.

## Cyber-404 hareketi S-Miler gibi yapıldı — sadece yatay (2026-10-04, kullanıcı kararı, oyunda denenmedi)
Eski: dört yönlü (baskın eksende), oyuncudan `keep_distance=500` mesafe koruma. Yeni (`cyber_404.gd::_physics_process`): oyuncunun **X konumuna hizalanır** (24px ölü bölge, `speed=120`), **Y çıkış (sandık) konumunda sabit** (`_fixed_y`, ilk fizik karesinde yakalanır, her kare yeniden uygulanır). Zincir kısıtı (merkez (995,560), 450px) durur. Animasyon sorunu yok: Cyber-404'ün tek yönlü "walk" animasyonu var (flip yok), eskiden de yatay giderken aynısını oynuyordu. Saldırılar konumdan bağımsız (oyuncuya nişan alır). `keep_distance` değişkeni artık kullanılmıyor.
S-Miler füze uyarısı (`MISSILE_WARN`) 1.8sn → **0.65sn** (Swing'in `SWING_WARN`'ı ile aynı; kullanıcı: kaçma süresi çok geniş). Hedef noktası uyarı başında sabitlenir; uyarıdan sonra füze VFX'inin düşüşü (~0.45sn, hasar çarpma anında) devam eder → toplam kaçma penceresi ≈1.1sn. Daha kısası için düşüş gecikmesi (`_spawn_missile_vfx` içindeki 0.45sn bekleme + 0.38sn tween) kısaltılabilir.
S-Miler-79 canı 250 → **500** (kullanıcı kararı; zırhı yok, `s_miler_79.gd` başındaki `health/max_health`).
BUG FIX (S-Miler): core'lar bacaklara yandan çarpmadan geçiyordu — çarpışma şekli sprite büyütülürken orantılı büyütülen **kapsül** (yarıçap 45, yükseklik 90 → yalnızca 90px genişlik, gövde ±45px dikey) idi; görünen gövde ≈190×184px. Şimdi `RectangleShape2D` = gövde bbox (103×100px kare içi) × `SPRITE_SCALE` × 0.96 ≈ 182×176px, bacaklar dahil. (`SIZE_MULT` sabiti artık kullanılmıyor.)

## Oyuncu hasar sonrası dokunulmazlık (0.3sn) KALDIRILDI (2026-10-05, kullanıcı kararı, oyunda denenmedi)
Sebep: oyun "3 kalp" tarzı değil, zaten zor; oyuncu güçlenerek boss'a girmeli. 0.3sn pencere art arda gelen mermilerin (S-Miler Gatling 3'lü salvo + 0.18sn aralık, Cyber-404 ring/taramalı) çoğunu yutuyordu. `player.gd::take_damage` artık her çağrıda hasar işler (`invincible` bayrağı + timer silindi); tek istisna Ghost Step (`_ghost_step_active`) kartı. **Denge notu**: boss mermi hasarı (Cyber-404: 9, S-Miler: 3) ve toplu mermi paternleri (Cyber-404 ring: 120 mermi, S-Miler Gatling: 15) artık gerçek tam hasar verir — ring attack başta olmak üzere ayar gerekebilir; `BOSS_BULLET_DAMAGE` (cyber_404.gd) ve S-Miler mermisinin `bullet.damage` değeri düşürülebilir.

## S-Miler saldırı ritmi sıklaştırıldı (2026-10-05, kullanıcı: "animasyonlar arası çok uzun, çok boş duruyor", oyunda denenmedi)
`s_miler_79.gd`: bekleme süreleri Gatling **10→6sn**, Swing **18→9sn**, Missile **22→12sn**; ilk kullanım zamanları 5/14/10 → **3/7/5sn**. Yeni `ATTACK_GAP=1.5sn`: her saldırı bitince (`_attack_done()`) diğer saldırıların sayaçları en az 1.5sn'ye çekilir → saldırılar arka arkaya yığılmaz ama uzun boş yürüyüş de kalmaz. Öncelik sırası aynı (Gatling > Missile > Swing); bir saldırı sürerken diğeri başlamaz (`_*_busy` kilitleri). Ayrıca boss saldırı coroutine'lerindeki tüm `create_timer(x)` çağrıları pause-safe yapıldı (`, false`) — level-up/pause sırasında saldırı zamanlayıcıları akmıyordu. "İki saldırı aynı anda" gözleminin kodda mantıksal bir sebebi bulunamadı (kilitler çalışıyor); olası kaynak: füze patlama VFX'inin (~1.5sn animasyon) saldırı bittikten sonra da sürmesi. Tekrarlarsa hangi iki saldırı olduğu söylenmeli.

## S-Miler füzesi 3'lü seri (2026-10-05, kullanıcı isteği, oyunda denenmedi)
`s_miler_79.gd::_start_missile`: artık `MISSILE_COUNT=3` füze art arda. Her füze, **uyarısının başladığı andaki güncel oyuncu konumuna** gider (her seferinde yeniden alınır); uyarı 0.65sn (`MISSILE_WARN`), füzeler arası (uyarı başı → uyarı başı) `MISSILE_INTERVAL=1.0sn`. Kafa sallama animasyonu (`missile_pose`) tüm seri boyunca oynar; seri sonunda 1sn beklenip idle'a dönülür, bekleme sayacı (`MISSILE_CD=12sn`) o zaman başlar. Sayı/aralık sabitlerden ayarlanır. Not: uyarı çemberi/hedef tek değişkenle çiziliyor (`_missile_warn_*`) — aralık uyarı süresinden (0.65) kısa yapılırsa üst üste biner, 0.65'in altına inme.
S-Miler füzesi: uyarı bittikten sonraki süre kısaltıldı (kullanıcı: yürüyerek kaçılıyor) — `MISSILE_FALL_SPEED=2.0`: düşüş+patlama animasyonu, düşüş tween'i, hasar gecikmesi ve impact gölgesi 2× hızlı → uyarıdan hasara 0.45sn → ≈0.22sn. Toplam kaçma penceresi 0.65 (uyarı) + 0.22 ≈ 0.87sn (Swing: 0.77). Daha kısası için sabiti büyüt (3.0 → 0.15sn), `MISSILE_WARN` (0.65) de ayrıca kısaltılabilir.
