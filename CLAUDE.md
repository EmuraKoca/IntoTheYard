# IntoTheYard — Proje Notları

Farklı bilgisayarlar / telefon (Remote Control) oturumları arasında bağlam köprüsü. Her oturum başında oku, sonunda güncelle.
**Eski ayrıntılı günlük (2026-07 → 2026-10-22, 390k karakter) silinmedi:** `docs/ARSIV_CLAUDE_2026-10-22.md`. Bir sistemin geçmişi/gerekçesi gerekirse oraya `grep` at. Bu dosyayı kısa tut (hedef <40k karakter); bitmiş iş günlüğünü buraya yazma, sadece güncel durum + kurallar + açık işler.

## Çalışma kuralları
- Godot 4 / GDScript. Kullanıcı (Emre, Türkçe) test eder; "oyunda denenmedi" notu düş, kullanıcı "test ettim, oldu — commit + push" derse commit'le.
- Commit mesajı Türkçe, kısa özet + gerekirse madde listesi; sonuna `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- **Commit'leme**: `export_presets.cfg`, editörün değiştirdiği `project.godot` (editör `window/stretch/aspect="keep"` ve `default_clear_color` satırlarını silebilir — silinirse geri ekle: gri şerit çıkar), Vector `assets/charsRedesign/vector/rotations/*` değişiklikleri.
- `.gd` dosyaları CRLF: Python ile `newline=''` açıp `\r\n` ↔ `\n` dönüştürerek düzenle. Satır başı görünmez boşluk hataları için raw byte tara.
- Kart isimleri/tür adları her iki dilde İngilizce kalır; açıklama gövdesi `lang.gd` (TR) + `game_scene.gd` `upgrades` dizisi `desc` (EN). Dinamik sayılı açıklamalar `lang.gd::_dynamic_desc`.
- Yeni kart review süreci: implementasyon → requires → TR → EN. Tüm Vector/Leila/Cyclone kartları review edildi (bkz. arşiv).

## Kritik teknik dersler (tekrar yapma)
- **Lambda yerel değişkeni DEĞERE göre yakalar**: lambda içinde değişip dışarıda okunacak durum instance değişkeni veya Array olmalı (`[false]`). Lambda başka bir node'u yakalıyorsa ve o node önce silinebiliyorsa → adlı fonksiyon + member kullan ("Lambda capture was freed" spam'i).
- `Object.get("metod")` metodu okumaz → `has_method()`. Düşmanlar `"subjects"` grubunda ("enemies" yok). Alan hedefli Calamity'ler `_yard_subjects()` kullanır.
- `get_tree().create_timer(x)` varsayılan pause'da akar → daima `create_timer(x, false)`.
- Boss scriptleri `base_enemy`'den türemez: `base_enemy`'deki `apply_*`/`take_damage` imzasına parametre eklersen 3 boss'a da aynı imzayı ekle. Oyuncunun `take_damage`'i tek argüman alır.
- `:=` tip çıkarımı gevşek tipli (Node/Variant) değerlerde patlar → açık tip yaz. `add_child()` sonrası `_ready` scale/pozisyonu ezebilir.
- Uzun/kesilmemesi gereken SFX: `Sfx.play_path_dedicated` (paylaşımlı havuz round-robin ile keser). Pause/level-up'ta `Sfx.set_gameplay_muted` + `stream_paused`. İndirilen `.ogg` bazen Ogg-FLAC çıkar; Godot yalnız **Ogg Vorbis** import eder (`head` ile `vorbis` kontrol et, FLAC ise `soundfile` ile Vorbis'e çevir). Video: yalnız Ogg Theora.
- Bar frame PNG'lerinde dolgu alanına ölçülen interior + **1px güvenlik payı** ekle (yoksa arkadaki dünya dikişten görünür).
- Boss `Y`/arena sabitleri yazma; Survival'da `game_scene.play_bounds()` kullan.
- Yeni momentum kaynağı `player.gain_momentum(N)` çağırmalı. Core hasarı `ball_mastery` + `normal_core_bonus` (Black Market) üzerinden gelir; hasar-override `elif` zincirine core eklerken `max_damage`'i ezme.

## Mimari harita
- Autoload'lar: `GameData` (kayıt, `game_mode` "story"/"survival", `DEMO_MODE`, zorluk, boss ilerlemesi), `Lang`, `Sfx`.
- Ana sahne `game_scene.tscn/.gd` (5800+ satır) Story ve Survival için ortak. Diğer: `player.gd`, `ball.gd`, `ball_launcher.gd`, `base_enemy.gd` (+ 7 temel düşman scripti), boss'lar `cyber_404.gd`, `s_miler_79.gd`, `nyx_09.gd`, `crate_intro.gd`, `blob_shadow.gd`, `main_menu`, `character_select`, `boss_select`, `enemy_select` (demo).
- Menü akışı: Ana menü (YENİ HİKAYE / HİKAYEYE DEVAM / SURVIVAL / Ayarlar / Credits / Çıkış) → karakter seçimi → (Story: boss+zorluk seçimi; Survival: doğrudan oyun; Demo: düşman stili seçimi). `mode_select.*` artık kullanılmıyor (silinebilir).
- Ekran: stretch canvas_items + aspect keep (oyun 16:9 sabit, siyah şeritler); menü `expand` + `_fit_menu`/`_cover`.
- Yükleme ekranı: `_preload_all_assets` (threaded load, `_warm_refs`).
- Font: Silver (19px ızgara; boyutlar 19'un katı; CC BY 4.0, credits'te atıf var). Neon buton stili `_make_neon_button` / `_neon_btn`.
- Oyuncu ölüm: 3 karakterin ölüm animasyonu + iris-out + ölüm sesi; Game Over/zafer ekranı `winEndingScreen.png`.

## Güncel oyun sistemleri
**Demo bayrağı** `GameData.DEMO_MODE` (şu an false; demo build için true): ayrı kayıt (`ity_save_demo.cfg`), 3 karakter açık, sadece Cyber-404 (5. dk), düşman canı 1/3, düşman türleri zamanla açılır (`_enemy_gate`: 20/50/90/130/180/230 sn), açılış pop-up'ları, "tam sürümde daha fazla boss" notu, düşman stili seçimi (CyberHuman/CyberCreature).
**Story**: boss 5. dk (`BOSS_SPAWN_TIME` 300). Boss ve zorluk ekranı (Megabonk tarzı): `boss_progress` karakter+boss başına; boss N için boss N-1 Seviye 1; 3 zorluk (Kolay/Normal/Zor) `GameData.DIFFICULTY_TABLE` (`diff("...")`). S-Miler→Leila, Cyber-404→Cyclone karakter kilidi açar. Kolay 0.5x XP, Zor 1.5x.
**Core hasarı**: oyun içi Amp/Core Mastery kartları SİLİNDİ; kalıcı hasar Black Market `core_dmg_up` (3 kademe: normal core +1/+2/+3, 3. kademede özellikli core'lara +1).
**Oyuncu**: hasar sonrası dokunulmazlık yok (Ghost Step hariç). Düşmanlar birbirinin içinden geçer (collision_layer 8). Başlangıç Calamity karakterin kendi havuzundan.
**Gölgeler**: `blob_shadow.gd` (oyuncu, Hasmen, düşmanlar, Cyber-404, S-Miler; Nyx kendi `_draw` gölgesi). Ceset 1.5sn kalır.

### Boss'lar (güncel değerler)
- **Cyber-404**: zırh 350 + can 150; saldırılar ring/füze/shockwave/rastgele atış, tek seferde tek saldırı (`_attacking` kilidi + `_attack_id` iptali); zırh kırılınca sersemler (3sn, durum kutusu `boss_status_icon.gd`); mermi 9 hasar; sandık girişi + toz halkası (oyuncuya 15, dash ile atlatılır); yatay hareket (Story).
- **S-Miler-79**: can 700; Gatling/Swing/Füze(3'lü seri); zorluk yüksek (swing 28, füze 38); giriş fallingDown sesi + landing VFX.
- **Nyx-09**: can 700; yıldırım (18), lazer (5/0.1sn), ışınlanma+beam (25), Triple Shockwave (15, güdümlü→kilitlenip patlar); landing/tpBeam sprite'ları.
- Üçü de `free_roam` bayrağı taşır (Survival'da oyuncuyu 2B kovalar; Nyx oyuncu çevresine ışınlanır).
- Boss müziği `bossSceneTheme.ogg` (`show_boss_bar` başlatır, `hide_boss_bar` bitirir); Cyber-404/Nyx kendi temaları da çalar.

## SURVIVAL MODU (2026-10-22, aşama 1-4 kodlandı)
Sınırsız mod; oyuncu ölünce biter. `GameData.game_mode == "survival"`, `game_scene.is_survival()`.
- **Sahne**: `_setup_survival` Story dekorlarını/duvarları/zinciri/Hasmen/LED tabelayı kapatır, `survivalModeArea.png` sonsuz döşenir (`SurvivalFloor`), kamera oyuncuyu izler (`SURV_CAM_SHIFT` 145; sağ UI paneli x≥1630 kalır). `play_bounds()` = görünen pencere; core'lar `ball.gd::_play_bounds()` ile pencere kenarlarına çarpıp sekiyor (alt kenar = geri dönüş). Calamity hedefleme/`_yard_subjects`/`_calc_traj` pencereye uyarlı. `UIWall` Survival'da hiç eklenmez.
- **Kontroller**: Space = dash, sağ tık = uçan core'ları geri çağır (`_recall_cores`); dönüş hızı baştan 680 (yavaşlamaz). Story kontrolleri aynı (sağ tık dash).
- **Doğuş**: dört kenardan pencerenin 110px dışından (`_survival_spawn_pos`); ilk 2 tür baştan, her 2 level'da +1 (`SURV_TYPES`/`SURV_WEIGHTS`); doğuş aralığı ×0.6, tur başına `2 + elapsed/90` düşman (maks 8); düşman canı `1 + elapsed/900`. `bullet.gd` Survival'da kameradan 1400px uzakta siler.
- **Boss'lar** (`_survival_boss_tick`): level 3 S-Miler, 5 Cyber-404, 7 Nyx (`SURV_BOSS_LEVELS`), sonra her 2 level'da yeniden; ölünce 10sn (`SURV_BOSS_GAP`) bekler; zafer ekranı/karakter kilidi yok, sadece XP. Çıkış noktası `_surv_boss_anchor()` (görünen alanın merkezi).
- **Kalan (Aşama 5)**: skor/rekor kaydı (süre, öldürme), Survival'a özel ölüm ekranı, XP+chip kalıcılığı kontrolü. Survival kayıtlı ayrı dosya kullanmıyor (XP/chip Story ile ortak).
- **Test notu**: Survival boss'ları ve doğuş sıklığı kullanıcı tarafından henüz denenmedi (son tur).

## Ses sistemi
`Sfx` autoload: `play("ad")` UI sesleri (`assets/sfx/ui/`, her Button'a otomatik hover/click), `play_path(path, vol, pitch)` oyun içi (GameplaySFX bus), `play_path_dedicated(path, vol, pitch, start_at)` uzun sesler. Calamity sesleri `assets/sfx/calamitys/<karakter>/`, boss sesleri `assets/sfx/bosses/<boss>/`. Yard Engine ortak makinesi (`_vfx_yard_engine`, `_vfx_yard_engine_to_point`) ateşleme sesi `yardEngineImpact.ogg`.

## Kart / Calamity sistemi (özet)
- Her karakter: Identity (core'lar), Utility (Lv1-3 `_apply_utility_level`), Individuality, Calamity. Calamity kullanımı: sağ paneldeki hücrelere tıkla (hedefsizler anında, hedefli olanlar tıkla+sürükle+bırak veya tıkla+E; `_CALAMITY_TARGETED`). Süreli buff geri sayımı `_CALAMITY_TIMER_DEFS`.
- Keyword sözlüğü (`Lang.STATUS_KEYWORDS`: Electrified/Wet/Burning/Slowed/Frozen/Momentum/Glitched/Virus/Decay/Mark; hover popup). Connected Core açıklamasında px yazılmaz. "Antivirus" metinlerde "Virus" olarak geçer.
- Debuff süreleri `base_enemy.gd` başındaki sabitler (burn 6sn/2sn tick vb.). Decay süreli (3sn/stack).
- Debuff/element sistemi, Core Speed (`core_speed_mult`), Momentum (Momentum Engine tek kapı, yürürken üretir, 3sn hareketsizlikte tükenir) mimarisi için arşive bak.
- Kaldırılan kartlar: Iron Fortress, Catalyst Pulse Core, Virus Rain, Amp kartları, Core Mastery. Havuzdan çıkarılan (kod duruyor): Elemental Shield Core (191).
- Bilinen riskler (düşük öncelik): Volatile Mixture çift tetik, Perfect Catalyst+Volatile döngüsü, Cryostasis (70) orphan, kart rarity/weight tutarsızlıkları (Echo Core, Momentum Engine, Lightning/Flame, Deep Freeze).

## YAYIN ÖNCESİ yapılacaklar / kaldırılacak debug
- `game_scene.gd::_ready()` içindeki test Calamity slotları (calamity_slots debug bloğu + momentum debug override) kaldırılacak.
- Survival boss level değerleri / doğuş sıklığı denge testi.
- `boss_select.gd` ~236'da `if true:` kalıntısı; `mode_select.*` ve `assets/enemys/*` eski sheet'ler silinebilir; `assets/placeHolder/` belirsiz.
- Demo build için `DEMO_MODE=true`. Demo .exe 2026-10-10'da çıkarıldı.
- Pencereli mod başlık çubuğu sorunu (`_apply_resolution` düzeltmesi) arkadaşın monitöründe test bekliyor.

## Fikirler / değerlendirilecek
- Core "çarpma ömrü" mekaniği (isabet ömrü; oto-modda AFK engeller).
- Meydan Okumalar butonu (boss ekranında), Zor (Seviye 3) dengesi.
- Siege Rain / Rampart Collapse'ı Yard Engine'e bağlamak.
- Kart rarity/weight tutarlılığı, Black Market'e yeni öğeler, milestone ilerleme göstergesi.

## Kısa tarihçe (ayrıntı arşivde)
Temmuz: VFX/Calamity/Chip/Black Market/meta ilerleme. Ağustos-Eylül: Vector/Leila/Cyclone kart-kart review (tüm kartlar), Momentum yeniden tasarımı, Silver font, SFX sistemi, Calamity sesleri/VFX. Ekim: yeni düşman sprite'ları (creature stili), 3 boss'un tam sprite/ses/saldırı seti, demo (GameDev.ist başvurusu), zorluk + boss seçimi, yükleme ekranı, Survival modu (aşama 1-4).
