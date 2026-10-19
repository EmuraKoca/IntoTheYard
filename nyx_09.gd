extends CharacterBody2D

signal landed   # inis tamam → game_scene elektrik temizligi

const BASE     := "res://assets/enemys/Nyx_09 The Quantum Widow/animations/"
const BASE_ROT := "res://assets/enemys/Nyx_09 The Quantum Widow/rotations/"

# Boyut: görünen gövde (walk karesi ~89×124px) × NYX_SCALE ≈ 133×186 dünya px — Cyber-404 / S-Miler gövdesiyle aynı boy.
# Eski ölçek 0.85 idi; havada durma yüksekliği, sallanma ve gölge aynı oranda (NYX_K) büyütüldü.
const SFX_ELECTRIC_CHARGE      := "res://assets/sfx/bosses/nyx-09/electricCharge.ogg"
const SFX_ELECTRIC_CHARGE_SKIP := 2.7   # dosyanın baştaki sessiz kısmı (ses ~2.75sn'de başlıyor)
const SFX_ELECTRIC_CHARGE_PITCH := 0.8  # ses ~5.3sn → ~6.7sn: 5 yıldırımlık saldırının (~6.75sn) tamamını kaplar
const SFX_LIGHTNING := "res://assets/sfx/bosses/nyx-09/lightning.ogg"
var _bolt_snd: AudioStreamPlayer = null
var _laser_snd: AudioStreamPlayer = null   # lazer boyunca çalan şarj sesi (electricCharge, yıldırımla aynı dosya)
const SFX_FALLING := "res://assets/sfx/bosses/nyx-09/fallingDown.ogg"
const ENTRY_FALL_TIME  := 2.2    # yukarıdan iniş süresi (sn)
const LAND_IMPACT_FRAME := 26    # landing animasyonunda yere değiş karesi
const LAND_FPS := float(LAND_IMPACT_FRAME) / ENTRY_FALL_TIME   # ≈11.8: kare 26 iniş bitişine denk gelir
const NYX_SCALE := 1.5
const NYX_K     := NYX_SCALE / 0.85
const HOVER_H := 30.0 * NYX_K
const BOB_AMP := 3.5 * NYX_K
const BOB_SPD := 2.0

# Lazer parametreleri
const LASER_LENGTH   := 920.0
const LASER_HIT_W    := 33.0   # yarı genişlik (toplam 66px ≈ görünen huzme 60px + küçük pay); eski 42 görselden geniş kalıyordu
const LASER_SPEED    := 1.75
const LASER_DURATION := 4.0
const LASER_COOLDOWN := 9.0
const LASER_DMG_INT  := 0.10   # her 0.1s kontrol — doner lazer icin gerekli
const LASER_DAMAGE   := 2      # daha sik carptigimiz icin hasar dusuruldu
# Lazer animasyonu (animations/laser, 35 kare): 3'te sol el kalkmaya başlar, 5'te elektriklenme → pervane görünür/hasar verir,
# 12-34 arası döngüye girer. Lazer elden çıkar: elin kare merkezine (122,122) göre konumu ≈ (+34,-9) px (kareden ölçüldü).
const LASER_ANIM_FPS    := 12.0
# Işınlanma + beam animasyonları (animations/tpBeam): 1whileTeleporting (9, portal açılır Nyx girer) → ışınlanma →
# 2afterTeleporting (10, yeni yerde portal açılır Nyx çıkar) → 3fbeamCharge (3) → 4beam (19, göğüs önünde enerji küresi).
const TP_ANIM_FPS      := 12.0
const TP_BEAM_ANIM_FPS := 32.0   # 19 kare ≈ 0.6sn (beam ömrü BEAM_LIFETIME 0.55sn'ye denk; 12fps 1.6sn sürerdi)
# Portal karelerde Nyx'ten ~1.4× büyük (kare içinde çizili) → portalın göründüğü karelerde sprite küçültülür (kare başına çarpan).
# Nyx'in kendisinin tam göründüğü ilk/son karelerde 1.0 (boyut sıçraması olmasın).
const TP_OUT_SCALE := [1.0, 0.95, 0.75, 0.65, 0.65, 0.65, 0.65, 0.75, 1.0]
const TP_IN_SCALE  := [0.75, 0.65, 0.65, 0.65, 0.65, 0.78, 0.9, 1.0, 1.0, 1.0]
const TELE_MIN_DIST   := 450.0   # yeni konum eski konumdan en az bu kadar uzakta (tahmin edilemesin)
const TELE_MIN_PLAYER := 160.0   # ... ve oyuncunun üstüne inmesin
const BEAM_ORB_OFFSET  := Vector2(-6.0, 13.0)   # enerji küresi merkezi, kare merkezine (122,122) göre (kareden ölçüldü ≈ (116,135))
const LASER_BEAMS_FRAME := 5
const LASER_LOOP_FROM   := 12
const LASER_HAND_OFFSET := Vector2(34.0, -9.0)
# Lazer kolu görseli: animations/laser/laserShot (16 kare 128×128, yatay huzme, ortası y=64). Kol, aynalı tile'larla uzatılır
# (her ikinci parça yatay çevrilir → birleşim yerinde kopukluk olmaz); kare 0. sütun boş olduğu için 1-127 bölgesi kullanılır.
const LASER_BEAM_PATH    := "res://assets/enemys/Nyx_09 The Quantum Widow/animations/laser/laserShot/frame_%03d.png"
const LASER_BEAM_FRAMES  := 16
const LASER_BEAM_FPS     := 16.0
const LASER_BEAM_SCALE_Y := 2.0     # huzme kalınlığı ≈ 30px × 2 ≈ 60px (hasar genişliği LASER_HIT_W ile eşleşir)
const LASER_TILE_PX      := 127.0
const LASER_MAX_TILES    := 4        # 920px / (127×2) ≈ 3.6 → 4 parça
const LASER_TAPER_PX     := 150.0    # elden çıkışta huzme bu uzunlukta İNCEDEN kalına açılır (sonrası tam kalınlık)
# İlk tile'a takılan shader: huzmenin başı ince, LASER_TAPER_PX sonunda tam kalınlık (eski çizilen koni gibi). UV.x kare içinde
# 1/128..1 (0. sütun kesildi), UV.y 0..1; huzme y=0.5 etrafında, yarı kalınlığı ≈0.117 (+cila payı → 0.16).
const LASER_TAPER_SHADER := """
shader_type canvas_item;
uniform float taper = 0.5;
void fragment() {
	float fx = clamp((UV.x - 1.0 / 128.0) / (127.0 / 128.0), 0.0, 1.0);
	float k = clamp(fx / max(taper, 0.001), 0.0, 1.0);
	float limit = mix(0.008, 0.16, k);
	if (abs(UV.y - 0.5) > limit) {
		COLOR.a = 0.0;
	}
}
"""
static var _laser_taper_shader: Shader = null
static var _laser_beam_frames: SpriteFrames = null
# Işınlanma beam'i (tpBeam/4beam/beam: 8 kare 128×128 yatay çift-sarmal huzme, aynalı tile) + hedefe çarpma (beamShock: 20 kare 128×128)
const TPB_BEAM_PATH   := "res://assets/enemys/Nyx_09 The Quantum Widow/animations/tpBeam/4beam/beam/frame_%03d.png"
const TPB_BEAM_FRAMES := 8
const TPB_BEAM_FPS    := 16.0
const TPB_BEAM_SCALE_Y := 1.3     # huzme kalınlığı ≈38px × 1.3 ≈ 50px
const TPB_MAX_TILES   := 12
const TPB_SHOCK_PATH   := "res://assets/enemys/Nyx_09 The Quantum Widow/animations/tpBeam/4beam/beamShock/frame_%03d.png"
const TPB_SHOCK_FRAMES := 20
const TPB_SHOCK_FPS    := 36.0    # 20 kare ≈ 0.55sn (BEAM_LIFETIME); orijinal 12fps 1.7sn sürerdi
const TPB_SHOCK_SCALE  := 0.9     # halka ≈ 112px × 0.9 ≈ 100px ≈ BEAM_HIT_RADIUS (48) × 2
const TPB_SHOCK_DELAY  := 0.12    # çarpma efekti beam başladıktan bu kadar sonra (hasar 0.41sn'de, parlama tepesi ~0.3sn)
static var _tpb_beam_frames: SpriteFrames = null
static var _tpb_shock_frames: SpriteFrames = null
var _tpb_root: Node2D = null
var _tpb_tiles: Array = []
var _laser_arms: Array = []         # [{"root": Node2D, "tiles": Array[AnimatedSprite2D]}] — 3 kol

# Elektrik carpmasi parametreleri
const BOLT_WARN_DUR  := 1.0    # (eski sabit zaman; artık uyarı süresi animasyondan geliyor: BOLT_STRIKE_FRAME / BOLT_ANIM_FPS)
const BOLT_STRIKE_FRAME := 12  # electricStrike'ın bu karesinde elektrik düşer (hasar + yıldırım)
const BOLT_ANIM_FPS     := 12.0  # 12 kare / 12fps = 1.0sn uyarı (eskisiyle aynı)
const BOLT_COOLDOWN  := 13.0   # saldiriler arasi
const BOLT_DAMAGE    := 18
const BOLT_RADIUS    := 55.0   # hasar yarıcapı

var health        : int   = 200
var max_health    : int   = 200
var speed         : float = 58.0
var is_dead       : bool  = false
var is_frozen     : bool  = false
var is_slowed     : bool  = false
var is_glitched   : bool  = false
var is_wet        : bool  = false
var is_burning    : bool  = false
var is_electrified: bool  = false
var original_speed: float = 58.0
var attack_cooldown: float = 0.0

var _in_entry      : bool  = true
var _bob_t         : float = 0.0
var _shadow_alpha  : float = 0.0
var _entry_progress: float = 0.0
var _fixed_y       : float = 380.0   # sabit yükseklik çizgisi

# Lazer state
var _laser_active  : bool  = false
var _laser_beams_on: bool  = false   # kollar görünür + hasar veriyor (animasyonda elektriklenme karesinden sonra)
var _laser_angle   : float = 0.0
var _laser_timer   : float = 6.0
var _laser_dur_left: float = 0.0
var _laser_dmg_t   : float = 0.0
var _warn_flash    : float = 0.0

# Teleport + darbe state
const TELE_COOLDOWN := 16.0
const TELE_DAMAGE   := 22
const TELE_RADIUS   := 78.0

var _tele_active  : bool    = false
var _tele_timer   : float   = 20.0   # ilk tp (diger saldirilar once baslasin)
var _tele_flash   : float   = 0.0
var _tele_ring_r  : float   = 0.0
var _tele_warn_t  : float   = 0.0
var _tele_pos     : Vector2 = Vector2.ZERO

# Beam saldirisi (tp sonrasi)
const BEAM_LIFETIME  := 0.55
const BEAM_HIT_RADIUS := 48.0
var _beam_active   : bool    = false
var _beam_t        : float   = 0.0    # 0..1 yasam suresi
var _beam_target   : Vector2 = Vector2.ZERO  # dunya uzayi
var _beam_warn_t   : float   = 0.0    # uyari gostergesi (1→0)
var _beam_warn_pos : Vector2 = Vector2.ZERO

# Elektrik carpma state
var _bolt_active   : bool    = false
var _bolt_timer    : float   = 11.0   # ilk carpma (lazeri bekle)
var _bolt_target   : Vector2 = Vector2.ZERO
var _bolt_warn_t   : float   = 0.0
var _bolt_pts      : Array   = []     # zigzag noktalari (lokal uzay)
var _bolt_flash    : float   = 0.0   # carpma ani flash

var _sprite: AnimatedSprite2D = null

func _ready() -> void:
	z_index = 3
	add_to_group("subjects")
	# (BlobShadow kaldırıldı: Nyx'in gölgesi _draw'daki, bob ile büyüyüp küçülen oval)

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	# Görünen gövdeyi (89×124px kare içi) kapsayan dikdörtgen, havada duran sprite'ın merkezinde
	var shape := RectangleShape2D.new()
	shape.size   = Vector2(89.0, 124.0) * NYX_SCALE * 0.96
	col.shape    = shape
	col.position = Vector2(-1.5 * NYX_SCALE, -HOVER_H - 2.0 * NYX_SCALE)
	col.disabled = true
	add_child(col)

	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale          = Vector2(NYX_SCALE, NYX_SCALE)
	_sprite.position.y     = -HOVER_H
	add_child(_sprite)
	_setup_frames()

func _setup_frames() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	# (Eski "entry" animasyonu kaldırıldı — iniş artık "landing". entry/ klasöründe sadece 006-007 kaldı:
	#  "charge" animasyonu (lazer hazırlığı) onları kullanıyor.)

	# Walk
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 5.0)   # 8 → 5: yürüme animasyonu daha yavaş (hareket hızına dokunulmadı)
	frames.set_animation_loop("walk", true)
	for i in range(1, 9):
		frames.add_frame("walk", load(BASE + "walk/frame_%03d.png" % i))

	# Death
	frames.add_animation("death")
	frames.set_animation_speed("death", 5.0)
	frames.set_animation_loop("death", false)
	for i in range(11):
		frames.add_frame("death", load(BASE + "death/frame_%03d.png" % i))

	# Charge (elektrik carpma hazirlik — entry frame 006+007 loop)
	frames.add_animation("charge")
	frames.set_animation_speed("charge", 5.0)
	frames.set_animation_loop("charge", true)
	for fn in ["006", "007"]:
		frames.add_frame("charge", load(BASE + "entry/frame_" + fn + ".png"))

	# Landing (iniş VFX'i, 36 kare): 0-25 enerji aurasıyla süzülme, 26'da yere değiş (beyaz patlama),
	# 30'da ikinci patlama, 31-35 toparlanma. Hız öyle seçildi ki kare 26 tam iniş tween'inin bitişine denk gelir.
	frames.add_animation("landing")
	frames.set_animation_speed("landing", LAND_FPS)
	frames.set_animation_loop("landing", false)
	for i in range(36):
		frames.add_frame("landing", load(BASE + "landing/frame_%03d.png" % i))

	# Electric Strike (yıldırım): 0-11 hazırlık/şarj, 12+ elektrik düşmeye başlar (BOLT_STRIKE_FRAME)
	frames.add_animation("electric_strike")
	frames.set_animation_speed("electric_strike", BOLT_ANIM_FPS)
	frames.set_animation_loop("electric_strike", false)
	for i in range(40):
		frames.add_frame("electric_strike", load(BASE + "electricStrike/frame_%03d.png" % i))

	# Elektrik döngüsü: yıldırımlar sürerken 19-39 arası sürekli oynar
	frames.add_animation("electric_strike_loop")
	frames.set_animation_speed("electric_strike_loop", BOLT_ANIM_FPS)
	frames.set_animation_loop("electric_strike_loop", true)
	for i in range(19, 40):
		frames.add_frame("electric_strike_loop", load(BASE + "electricStrike/frame_%03d.png" % i))

	# Işınlanma / beam (tpBeam): portal girişi, portal çıkışı, beam şarjı, beam atışı
	var tp_base := BASE + "tpBeam/"
	frames.add_animation("tp_out")
	frames.set_animation_speed("tp_out", TP_ANIM_FPS)
	frames.set_animation_loop("tp_out", false)
	for i in range(9, 18):
		frames.add_frame("tp_out", load(tp_base + "1whileTeleporting/frame_%03d.png" % i))
	frames.add_animation("tp_in")
	frames.set_animation_speed("tp_in", TP_ANIM_FPS)
	frames.set_animation_loop("tp_in", false)
	for fn in ["017b","017c","017d","017e","017f","017g","017h","017i","017j","018"]:
		frames.add_frame("tp_in", load(tp_base + "2afterTeleporting/frame_" + fn + ".png"))
	frames.add_animation("tp_charge")
	frames.set_animation_speed("tp_charge", TP_ANIM_FPS)
	frames.set_animation_loop("tp_charge", false)
	for i in range(19, 22):
		frames.add_frame("tp_charge", load(tp_base + "3fbeamCharge/frame_%03d.png" % i))
	frames.add_animation("tp_beam")
	frames.set_animation_speed("tp_beam", TP_BEAM_ANIM_FPS)
	frames.set_animation_loop("tp_beam", false)
	for i in range(22, 41):
		frames.add_frame("tp_beam", load(tp_base + "4beam/frame_%03d.png" % i))

	# Laser (pervane lazer): 0-4 el kalkar/şarj, 5'te kollar başlar; sonra 12-34 döngü
	frames.add_animation("laser")
	frames.set_animation_speed("laser", LASER_ANIM_FPS)
	frames.set_animation_loop("laser", false)
	for i in range(35):
		frames.add_frame("laser", load(BASE + "laser/frame_%03d.png" % i))
	frames.add_animation("laser_loop")
	frames.set_animation_speed("laser_loop", LASER_ANIM_FPS)
	frames.set_animation_loop("laser_loop", true)
	for i in range(LASER_LOOP_FROM, 35):
		frames.add_frame("laser_loop", load(BASE + "laser/frame_%03d.png" % i))

	# Spin (rotation frame'leri, saat yonunde: E -> SE -> S -> SW -> W -> NW -> N -> NE)
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 10.0)
	frames.set_animation_loop("spin", true)
	for d in ["east","south-east","south","south-west","west","north-west","north","north-east"]:
		frames.add_frame("spin", load(BASE_ROT + d + ".png"))

	_sprite.sprite_frames = frames
	_sprite.frame_changed.connect(_apply_tp_scale)

func play_entry(land_pos: Vector2) -> void:
	_fixed_y = land_pos.y
	position  = Vector2(land_pos.x, -200.0)

	# Uyarı sesi: önce ses başlar, boss ekran dışında bekler; sesin SONU iniş anına denk gelir
	# (S-Miler / Cyber-404 girişindeki aynı desen: _pre_delay = ses süresi - iniş süresi).
	# Landing animasyonu bekleme BİTİNCE başlar ki kare 26 (yere değiş) iniş bitişine denk gelsin.
	var fall_stream: AudioStream = load(SFX_FALLING) if ResourceLoader.exists(SFX_FALLING) else null
	if fall_stream != null:
		Sfx.play_path_dedicated(SFX_FALLING)
		var pre_delay: float = maxf(0.0, fall_stream.get_length() - ENTRY_FALL_TIME)
		if pre_delay > 0.0:
			await get_tree().create_timer(pre_delay, false).timeout
			if not is_instance_valid(self):
				return

	_sprite.play("landing")

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", land_pos.y, ENTRY_FALL_TIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_entry_progress, 0.0, 1.0, ENTRY_FALL_TIME)
	await tw.finished

	_entry_progress = 1.0

	# Yere değiş (kare ~26): sahne temizliği + boss barı hemen; boss toparlanma karelerinin sonuna kadar
	# saldırmaz / vurulamaz (_in_entry)
	emit_signal("landed")
	var game := get_parent()
	if game.has_method("show_boss_bar"):
		game.show_boss_bar(self, "NYX-09  //  THE QUANTUM WIDOW")
	if game.has_method("update_boss_bar"):
		game.update_boss_bar(0, health, 0, max_health)

	await _sprite.animation_finished
	if not is_instance_valid(self) or is_dead:
		return
	_in_entry = false
	$CollisionShape2D.disabled = false
	_sprite.play("walk")

func _set_entry_progress(v: float) -> void:
	_entry_progress = v
	_shadow_alpha   = v * 0.38
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dead or _in_entry:
		return
	if is_frozen:
		return

	# Hover bob
	_bob_t += delta
	_sprite.position.y = -HOVER_H + sin(_bob_t * BOB_SPD) * BOB_AMP
	queue_redraw()

	# Beam yasam suresi
	if _beam_active:
		_beam_t += delta / BEAM_LIFETIME
		if _beam_t >= 1.0:
			_beam_active = false
			_beam_t = 0.0
			_set_tpbeam_visible(false)
		else:
			_update_tpbeam()
		queue_redraw()

	# Beam uyari solma
	if _beam_warn_t > 0.0:
		_beam_warn_t = max(0.0, _beam_warn_t - delta / (0.25 + BEAM_LIFETIME * 0.75))
		queue_redraw()

	# Flash solma
	if _bolt_flash > 0.0:
		_bolt_flash = max(0.0, _bolt_flash - delta * 8.0)
		queue_redraw()
	if _tele_flash > 0.0:
		_tele_flash = max(0.0, _tele_flash - delta * 5.0)
		queue_redraw()
	if _tele_warn_t > 0.0:
		_tele_warn_t = max(0.0, _tele_warn_t - delta * 2.0)
		queue_redraw()

	# Teleport zamanlayici
	if not _laser_active and not _bolt_active and not _tele_active:
		_tele_timer -= delta
		if _tele_timer <= 0.0:
			_start_teleport()

	# Elektrik carpma zamanlayici
	if not _laser_active and not _bolt_active and not _tele_active:
		_bolt_timer -= delta
		if _bolt_timer <= 0.0:
			_start_bolt()

	# Lazer saldiri zamanlayici
	if _laser_active:
		if _laser_beams_on:
			_laser_angle   += LASER_SPEED * delta
			_update_laser_arms()
			_laser_dur_left -= delta
			_laser_dmg_t   -= delta
			if _laser_dmg_t <= 0:
				_laser_dmg_t = LASER_DMG_INT
				_check_laser_hit()
			if _laser_dur_left <= 0:
				_stop_laser()
	elif not _bolt_active and not _tele_active:
		# Bolt veya TP aktifken laser zamanlayici durur
		_laser_timer -= delta
		if _laser_timer <= 1.0 and _laser_timer > 0:
			_warn_flash = abs(sin(_laser_timer * 18.0))
			queue_redraw()
		if _laser_timer <= 0:
			_start_laser()

	# Hareket (lazer ve ışınlanma sırasında dur — portal/beam animasyonu boss ile birlikte kaymasın)
	if _laser_active or _tele_active:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Sadece yatay hareket, Y sabit
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var dx : float = player.global_position.x - global_position.x
		if abs(dx) > 100:
			velocity = Vector2(sign(dx) * speed, 0.0)
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	global_position.y = _fixed_y   # Y'yi kilitle

func _start_laser() -> void:
	_laser_active   = true
	_laser_beams_on = false
	_laser_dur_left = LASER_DURATION
	_laser_dmg_t    = 0.5   # ilk hasardan once kisa bekleme
	_warn_flash     = 0.0
	_laser_angle    = randf() * TAU   # rastgele baslangic acisi
	# El kalkar, enerji birikir: kollar LASER_BEAMS_FRAME'de (elektriklenme) başlar. Süre o andan itibaren sayılır.
	_sprite.play("laser")
	_sprite.set_frame_and_progress(0, 0.0)
	# Şarj sesi: el kalkarken başlar (baştaki sessiz ~2.7sn atlanır), ~5.3sn → lazerin toplam süresini (≈0.4 + 4sn) kaplar
	_laser_snd = Sfx.play_path_dedicated(SFX_ELECTRIC_CHARGE, 0.0, 1.0, SFX_ELECTRIC_CHARGE_SKIP)
	if not _sprite.animation_finished.is_connected(_on_laser_anim_finished):
		_sprite.animation_finished.connect(_on_laser_anim_finished)
	while _sprite.frame < LASER_BEAMS_FRAME and _sprite.animation == "laser":
		await _sprite.frame_changed
		if not is_instance_valid(self) or is_dead or not _laser_active:
			return
	_laser_beams_on = true
	_ensure_laser_arms()
	_update_laser_arms()
	_set_laser_arms_visible(true)

func _get_laser_beam_frames() -> SpriteFrames:
	if _laser_beam_frames == null:
		var sf := SpriteFrames.new()
		if sf.has_animation("default"):
			sf.remove_animation("default")
		sf.add_animation("beam")
		sf.set_animation_speed("beam", LASER_BEAM_FPS)
		sf.set_animation_loop("beam", true)
		for i in range(LASER_BEAM_FRAMES):
			var at := AtlasTexture.new()
			at.atlas = load(LASER_BEAM_PATH % i)
			at.region = Rect2(1.0, 0.0, LASER_TILE_PX, 128.0)
			sf.add_frame("beam", at)
		_laser_beam_frames = sf
	return _laser_beam_frames

# 3 kolun (her biri birkaç aynalı AnimatedSprite2D tile) düğümlerini bir kez kurar. Boss sprite'ının ARKASINDA kalsınlar diye
# ilk çocuk olarak eklenir (boss gövdesi kolların üstünde çizilir).
func _get_laser_taper_shader() -> Shader:
	if _laser_taper_shader == null:
		var sh := Shader.new()
		sh.code = LASER_TAPER_SHADER
		_laser_taper_shader = sh
	return _laser_taper_shader

func _ensure_laser_arms() -> void:
	if not _laser_arms.is_empty():
		return
	var frames := _get_laser_beam_frames()
	for _i in 3:
		var root := Node2D.new()
		root.visible = false
		add_child(root)
		move_child(root, 0)
		var tiles: Array = []
		for _t in LASER_MAX_TILES:
			var spr := AnimatedSprite2D.new()
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			spr.sprite_frames = frames
			spr.centered = false
			spr.offset = Vector2(0.0, -64.0)   # huzmenin dikey merkezi karede y=64
			root.add_child(spr)
			tiles.append(spr)
		# İlk parça (elden çıkış): inceden kalına açılan uç
		var mat := ShaderMaterial.new()
		mat.shader = _get_laser_taper_shader()
		(tiles[0] as AnimatedSprite2D).material = mat
		_laser_arms.append({"root": root, "tiles": tiles, "mat": mat})

func _set_laser_arms_visible(v: bool) -> void:
	for arm in _laser_arms:
		var root: Node2D = arm["root"]
		root.visible = v
		for spr in arm["tiles"]:
			if v:
				spr.play("beam")
				spr.set_frame_and_progress(randi() % LASER_BEAM_FRAMES, 0.0)   # kollar farklı karede başlasın
			else:
				spr.stop()

# Her frame: kolun açısı/çıkışı + duvara kırpılmış uzunluğa göre tile sayısı ve yatay ölçek (parçalar eşit esnetilir)
func _update_laser_arms() -> void:
	if _laser_arms.is_empty():
		return
	var o : Vector2 = _laser_origin_local()
	for i in 3:
		var arm: Dictionary = _laser_arms[i]
		var root: Node2D = arm["root"]
		var tiles: Array = arm["tiles"]
		var angle : float = _laser_angle + float(i) * TAU / 3.0
		var length: float = maxf(_laser_clip_length(Vector2(cos(angle), sin(angle))), 8.0)
		root.position = o
		root.rotation = angle
		var n : int = clampi(roundi(length / (LASER_TILE_PX * LASER_BEAM_SCALE_Y)), 1, tiles.size())
		var w : float = length / float(n)           # her parçanın dünya genişliği
		var sx: float = w / LASER_TILE_PX
		(arm["mat"] as ShaderMaterial).set_shader_parameter("taper", clampf(LASER_TAPER_PX / w, 0.05, 1.0))
		for t in tiles.size():
			var spr: AnimatedSprite2D = tiles[t]
			if t < n:
				spr.visible = true
				if t % 2 == 1:                       # aynalı parça: x ölçeği negatif, sağ kenara oturur
					spr.scale = Vector2(-sx, LASER_BEAM_SCALE_Y)
					spr.position = Vector2(float(t + 1) * w, 0.0)
				else:
					spr.scale = Vector2(sx, LASER_BEAM_SCALE_Y)
					spr.position = Vector2(float(t) * w, 0.0)
			else:
				spr.visible = false

func _get_tpb_beam_frames() -> SpriteFrames:
	if _tpb_beam_frames == null:
		var sf := SpriteFrames.new()
		if sf.has_animation("default"):
			sf.remove_animation("default")
		sf.add_animation("beam")
		sf.set_animation_speed("beam", TPB_BEAM_FPS)
		sf.set_animation_loop("beam", true)
		for i in range(TPB_BEAM_FRAMES):
			sf.add_frame("beam", load(TPB_BEAM_PATH % i))
		_tpb_beam_frames = sf
	return _tpb_beam_frames

func _get_tpb_shock_frames() -> SpriteFrames:
	if _tpb_shock_frames == null:
		var sf := SpriteFrames.new()
		if sf.has_animation("default"):
			sf.remove_animation("default")
		sf.add_animation("shock")
		sf.set_animation_speed("shock", TPB_SHOCK_FPS)
		sf.set_animation_loop("shock", false)
		for i in range(TPB_SHOCK_FRAMES):
			sf.add_frame("shock", load(TPB_SHOCK_PATH % i))
		_tpb_shock_frames = sf
	return _tpb_shock_frames

# Beam tile düğümlerini bir kez kurar (boss sprite'ının ÜSTÜNDE: huzme göğüs önündeki küreden çıkar)
func _ensure_tpbeam() -> void:
	if _tpb_root != null:
		return
	_tpb_root = Node2D.new()
	_tpb_root.visible = false
	add_child(_tpb_root)
	var frames := _get_tpb_beam_frames()
	for _t in TPB_MAX_TILES:
		var spr := AnimatedSprite2D.new()
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.sprite_frames = frames
		spr.centered = false
		spr.offset = Vector2(0.0, -64.0)
		_tpb_root.add_child(spr)
		_tpb_tiles.append(spr)

func _set_tpbeam_visible(v: bool) -> void:
	if _tpb_root == null:
		return
	_tpb_root.visible = v
	for spr in _tpb_tiles:
		if v:
			spr.play("beam")
		else:
			spr.stop()

func _start_tpbeam_fx() -> void:
	_ensure_tpbeam()
	_set_tpbeam_visible(true)
	_update_tpbeam()
	# Hedefe çarpma efekti (dünya konumunda, boss'tan bağımsız; bitince kendini siler)
	var pos := _beam_target
	var game := get_parent()
	await get_tree().create_timer(TPB_SHOCK_DELAY, false).timeout
	if not is_instance_valid(self) or is_dead or not is_instance_valid(game):
		return
	var shock := AnimatedSprite2D.new()
	shock.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shock.sprite_frames = _get_tpb_shock_frames()
	shock.global_position = pos
	shock.scale = Vector2(TPB_SHOCK_SCALE, TPB_SHOCK_SCALE)
	shock.z_index = 4
	game.add_child(shock)
	shock.play("shock")
	shock.animation_finished.connect(shock.queue_free)

# Her frame: orb'dan hedefe uzanan huzme; aynalı tile'lar (t%2==1 x-ters), son yarıda solar
func _update_tpbeam() -> void:
	if _tpb_root == null or not _tpb_root.visible:
		return
	var o : Vector2 = _sprite.position + BEAM_ORB_OFFSET * NYX_SCALE
	var d : Vector2 = to_local(_beam_target) - o
	var length: float = maxf(d.length(), 8.0)
	_tpb_root.position = o
	_tpb_root.rotation = d.angle()
	_tpb_root.modulate.a = clampf((1.0 - _beam_t) * 2.0, 0.0, 1.0)
	var n : int = clampi(roundi(length / (128.0 * TPB_BEAM_SCALE_Y)), 1, _tpb_tiles.size())
	var w : float = length / float(n)
	var sx: float = w / 128.0
	for t in _tpb_tiles.size():
		var spr: AnimatedSprite2D = _tpb_tiles[t]
		if t < n:
			spr.visible = true
			if t % 2 == 1:
				spr.scale = Vector2(-sx, TPB_BEAM_SCALE_Y)
				spr.position = Vector2(float(t + 1) * w, 0.0)
			else:
				spr.scale = Vector2(sx, TPB_BEAM_SCALE_Y)
				spr.position = Vector2(float(t) * w, 0.0)
		else:
			spr.visible = false

func _on_laser_anim_finished() -> void:
	if _laser_active and not is_dead and _sprite.animation == "laser":
		_sprite.play("laser_loop")

# Lazerin çıkış noktası = Nyx'in sol eli (sprite'a bağlı, havada sallanmayı da izler)
func _laser_origin_local() -> Vector2:
	return _sprite.position + LASER_HAND_OFFSET * NYX_SCALE

func _stop_laser() -> void:
	_fade_laser_snd(0.4)
	_laser_active = false
	_laser_beams_on = false
	_set_laser_arms_visible(false)
	_laser_timer  = LASER_COOLDOWN
	# Bolt henuz hazirsa 5s bos birak
	if _bolt_timer < 5.0:
		_bolt_timer = 5.0
	_sprite.play("walk")

func _start_teleport() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		_tele_timer = TELE_COOLDOWN
		return
	_tele_active = true

	# 3 kez tp + beam, 1.5s arayla
	for _strike in range(3):
		if not is_instance_valid(self) or is_dead: return

		# Hedef: eski konumdan UZAK (≥ TELE_MIN_DIST), oyuncunun üstünde değil, rastgele X — oyuncu tahmin edemesin
		var pl := get_tree().get_first_node_in_group("player")
		_tele_pos = Vector2(_pick_tele_x(pl), _fixed_y)

		# --- KAYBOLIS: eski yerde portal açılır, Nyx içine girer (tp_out) ---
		_sprite.play("tp_out")
		_apply_tp_scale()
		await _sprite.animation_finished
		if not is_instance_valid(self) or is_dead: return
		_sprite.visible = false
		_sprite.scale   = Vector2(NYX_SCALE, NYX_SCALE)
		position        = _tele_pos

		# --- BELIRIS: yeni yerde portal açılır, Nyx çıkar (tp_in); hedef uyarısı portalla birlikte ---
		_sprite.visible = true
		_sprite.play("tp_in")
		_apply_tp_scale()
		await _sprite.animation_finished
		if not is_instance_valid(self) or is_dead: return
		_sprite.scale = Vector2(NYX_SCALE, NYX_SCALE)

		# Kisa sarj (tp_charge, 0.25s) — hedef uyarisi goster
		var pw := get_tree().get_first_node_in_group("player")
		if is_instance_valid(pw):
			_beam_warn_pos = pw.global_position
			_beam_warn_t   = 1.0
			queue_redraw()
		_sprite.play("tp_charge")
		await _sprite.animation_finished
		if not is_instance_valid(self) or is_dead: return

		# BEAM ATIS — mark pozisyonuna ates, oradan kacabilirsin (tp_beam, göğüs önündeki küreden)
		_beam_target = _beam_warn_pos
		_beam_active = true
		_beam_t      = 0.0
		_sprite.play("tp_beam")
		_start_tpbeam_fx()
		await get_tree().create_timer(BEAM_LIFETIME * 0.75, false).timeout
		if is_instance_valid(self) and not is_dead:
			var p2 := get_tree().get_first_node_in_group("player")
			if is_instance_valid(p2) and not p2.is_dashing:
				if p2.global_position.distance_to(_beam_warn_pos) < BEAM_HIT_RADIUS:
					p2.take_damage(TELE_DAMAGE)

		var game := get_parent()
		if game.has_method("_screen_shake"):
			game._screen_shake()

		# Beam animasyonunun kalanı bitsin, sonra yürüme
		if is_instance_valid(self) and not is_dead and _sprite.animation == "tp_beam" and _sprite.is_playing():
			await _sprite.animation_finished
		if not is_instance_valid(self) or is_dead: return
		_sprite.play("walk")

		# Sonraki strike'a kadar 1.5s bekle (son strike'ta bekleme yok)
		if _strike < 2:
			await get_tree().create_timer(1.5, false).timeout
			if not is_instance_valid(self) or is_dead: return

	# Sekans bitti
	_tele_active  = false
	_tele_timer   = TELE_COOLDOWN
	if _laser_timer < 5.0: _laser_timer = 5.0
	if _bolt_timer  < 5.0: _bolt_timer  = 5.0
	position.y = _fixed_y
	_sprite.play("walk")

# Işınlanma hedef X'i: eski konumdan en az TELE_MIN_DIST uzakta, oyuncudan en az TELE_MIN_PLAYER uzakta, rastgele
func _pick_tele_x(pl: Node) -> float:
	var px : float = pl.global_position.x if is_instance_valid(pl) else -9999.0
	for _i in 16:
		var x : float = randf_range(420.0, 1570.0)
		if absf(x - global_position.x) >= TELE_MIN_DIST and absf(x - px) >= TELE_MIN_PLAYER:
			return x
	# Uygun nokta bulunamadıysa: eski konuma göre arenanın uzak ucu
	return 420.0 if global_position.x > 995.0 else 1570.0

# Portal animasyonlarında (tp_out / tp_in) sprite ölçeğini kareye göre ayarlar (portal Nyx'ten büyük çizilmiş)
func _apply_tp_scale() -> void:
	var tbl: Array = []
	if _sprite.animation == "tp_out":
		tbl = TP_OUT_SCALE
	elif _sprite.animation == "tp_in":
		tbl = TP_IN_SCALE
	if tbl.is_empty():
		return
	var f : int = clampi(_sprite.frame, 0, tbl.size() - 1)
	var k : float = float(tbl[f])
	_sprite.scale = Vector2(NYX_SCALE * k, NYX_SCALE * k)

func _start_bolt() -> void:
	_bolt_active = true
	# Şarj sesi: dosyanın baştaki ~2.7sn'lik sessiz kısmı atlanıyor
	_bolt_snd = Sfx.play_path_dedicated(SFX_ELECTRIC_CHARGE, 0.0, SFX_ELECTRIC_CHARGE_PITCH, SFX_ELECTRIC_CHARGE_SKIP)

	# 5 carpi art arda, 1s arayla
	for _strike in range(5):
		if not is_instance_valid(self) or is_dead:
			return

		# Her carpma icin anlık player pozisyonunu hedefle
		var p := get_tree().get_first_node_in_group("player")
		if is_instance_valid(p):
			_bolt_target = p.global_position
		_bolt_pts.clear()
		queue_redraw()

		if _strike == 0:
			# electricStrike bir kez başlar: 0-11 şarj (uyarı), BOLT_STRIKE_FRAME'de ilk elektrik düşer;
			# animasyon sonuna (39) varınca 19-39 arası döngüye girer ve saldırı bitene kadar döner
			_sprite.play("electric_strike")
			_sprite.set_frame_and_progress(0, 0.0)
			if not _sprite.animation_finished.is_connected(_on_bolt_anim_finished):
				_sprite.animation_finished.connect(_on_bolt_anim_finished)
			while _sprite.frame < BOLT_STRIKE_FRAME and _sprite.animation == "electric_strike":
				await _sprite.frame_changed
				if not is_instance_valid(self) or is_dead:
					return
		else:
			# Sonraki yıldırımlar: animasyon (elektrik döngüsü) kesilmeden akar, sadece uyarı süresi beklenir
			await get_tree().create_timer(BOLT_WARN_DUR, false).timeout
			if not is_instance_valid(self) or is_dead:
				return

		# Carpma
		_generate_bolt()
		_spawn_bolt_vfx(_bolt_target)
		Sfx.play_path_dedicated(SFX_LIGHTNING)
		_bolt_flash = 1.0
		queue_redraw()

		var game := get_parent()
		if game.has_method("_screen_shake"):
			game._screen_shake()

		p = get_tree().get_first_node_in_group("player")
		if is_instance_valid(p):
			if p.global_position.distance_to(_bolt_target) < BOLT_RADIUS and not p.is_dashing:
				p.take_damage(BOLT_DAMAGE)

		# Bolt 0.35s gorunur
		await get_tree().create_timer(0.35, false).timeout
		if not is_instance_valid(self):
			return
		_bolt_pts.clear()

	# 5 carpma bitti
	_fade_bolt_snd(0.4)
	_bolt_active = false
	_bolt_timer  = BOLT_COOLDOWN
	# Lazer henuz hazirsa 5s bos birak
	if _laser_timer < 5.0:
		_laser_timer = 5.0
	_sprite.play("walk")

# Yıldırım sprite'ı (assets/VFX/calamitys/lightning, 5 kare 168×168, üstten düşer, patlama merkezi karede ~y=98).
# Patlama merkezi hedef noktaya oturur; ölçek 1.5 → patlama yarıçapı ≈ 63px ≈ BOLT_RADIUS (55).
const BOLT_VFX_PATH  := "res://assets/VFX/calamitys/lightning/frame_%03d.png"
const BOLT_VFX_SCALE := 1.5
const BOLT_VFX_BURST_Y := 98.0   # karede patlama merkezinin y'si (kare merkezi 84)
static var _bolt_vfx_frames: SpriteFrames = null

func _spawn_bolt_vfx(pos: Vector2) -> void:
	if _bolt_vfx_frames == null:
		if not ResourceLoader.exists(BOLT_VFX_PATH % 0):
			return
		var sf := SpriteFrames.new()
		if sf.has_animation("default"):
			sf.remove_animation("default")
		sf.add_animation("strike")
		sf.set_animation_speed("strike", 16.0)
		sf.set_animation_loop("strike", false)
		var i := 0
		while ResourceLoader.exists(BOLT_VFX_PATH % i):
			sf.add_frame("strike", load(BOLT_VFX_PATH % i))
			i += 1
		_bolt_vfx_frames = sf
	var bolt := AnimatedSprite2D.new()
	bolt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bolt.sprite_frames = _bolt_vfx_frames
	bolt.scale = Vector2(BOLT_VFX_SCALE, BOLT_VFX_SCALE)
	bolt.z_index = 9
	get_parent().add_child(bolt)
	bolt.global_position = pos - Vector2(0.0, (BOLT_VFX_BURST_Y - 84.0) * BOLT_VFX_SCALE)
	bolt.play("strike")
	bolt.animation_finished.connect(bolt.queue_free)

func _fade_laser_snd(dur: float) -> void:
	if is_instance_valid(_laser_snd):
		var s := _laser_snd
		_laser_snd = null
		var tw := s.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_STOP)   # player ALWAYS → tween pause'da da akardı
		tw.tween_property(s, "volume_db", -40.0, dur)
		tw.tween_callback(s.stop)

func _fade_bolt_snd(dur: float) -> void:
	if is_instance_valid(_bolt_snd):
		var s := _bolt_snd
		_bolt_snd = null
		var tw := s.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_STOP)   # player PROCESS_MODE_ALWAYS → tween pause'da da akardı
		tw.tween_property(s, "volume_db", -40.0, dur)
		tw.tween_callback(s.stop)

func _on_bolt_anim_finished() -> void:
	if _bolt_active and not is_dead and _sprite.animation == "electric_strike":
		_sprite.play("electric_strike_loop")

func _generate_bolt() -> void:
	_bolt_pts.clear()
	# Dunya koordinatlarindan lokal uzaya: to_local() kullaniyoruz _draw()'da
	# Noktalari dunya uzayinda sakliyoruz, _draw()'da to_local() ile ceviriyoruz
	var start := Vector2(_bolt_target.x + randf_range(-18.0, 18.0), _bolt_target.y - 380.0)
	var end   := _bolt_target
	_bolt_pts.append(start)
	for i in range(1, 9):
		var t    : float   = float(i) / 9.0
		var base : Vector2 = start.lerp(end, t)
		base.x += randf_range(-28.0, 28.0) * (1.0 - t * 0.6)
		_bolt_pts.append(base)
	_bolt_pts.append(end)

# Oyun alani sinirlarinda lazeri kirpar (tribun duvari dahil)
func _laser_clip_length(dir: Vector2) -> float:
	var max_len : float = LASER_LENGTH
	var o : Vector2 = global_position + _laser_origin_local()
	if dir.x < -0.001:
		max_len = min(max_len, (o.x - 360.0)  / abs(dir.x))
	if dir.x >  0.001:
		max_len = min(max_len, (1630.0 - o.x) /     dir.x)
	if dir.y < -0.001:
		max_len = min(max_len, (o.y - 260.0)  / abs(dir.y))
	if dir.y >  0.001:
		max_len = min(max_len, (1040.0 - o.y) /     dir.y)
	return maxf(max_len, 0.0)

func _check_laser_hit() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	var to_player : Vector2 = player.global_position - (global_position + _laser_origin_local())
	if to_player.length() > LASER_LENGTH:
		return
	for i in 3:
		var angle     : float   = _laser_angle + float(i) * TAU / 3.0
		var laser_dir : Vector2 = Vector2(cos(angle), sin(angle))
		var clip_len  : float   = _laser_clip_length(laser_dir)
		var along     : float   = to_player.dot(laser_dir)
		if along < 0 or along > clip_len:
			continue
		var perp : float = abs(to_player.dot(laser_dir.rotated(PI * 0.5)))
		if perp < LASER_HIT_W and not player.is_dashing:
			player.take_damage(LASER_DAMAGE)
			return

func _draw() -> void:
	if is_dead:
		return

	# --- GOLGE ---
	var scale_factor: float
	if _in_entry:
		scale_factor = _entry_progress
	else:
		scale_factor = lerp(0.68, 1.0, (sin(_bob_t * BOB_SPD * 2.2) + 1.0) * 0.5)
	var rx := 24.0 * NYX_K * scale_factor
	var ry :=  6.0 * NYX_K * scale_factor
	var pts := PackedVector2Array()
	for i in 24:
		var a := float(i) / 24.0 * TAU
		pts.append(Vector2(cos(a) * rx, 46.0 * NYX_K + sin(a) * ry))
	draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, _shadow_alpha))

	# (Eski gövde-merkezli lazer uyarı dairesi kaldırıldı: uyarı artık el kaldırma/şarj animasyonu)

	# (Lazer kolları artık sprite — _update_laser_arms / laserShot; eski çizilen koni kaldırıldı)

	# (Işınlanma hedef uyarı dairesi kaldırıldı: portal animasyonu zaten gösteriyor, konum rastgele)

	# (Işınlanma beam'i artık sprite: _update_tpbeam / tpBeam/4beam/beam + beamShock; eski çizilen dalgalı huzme kaldırıldı)

	# --- BEAM HEDEF UYARISI ---
	if _beam_warn_t > 0.0:
		var wl    : Vector2 = to_local(_beam_warn_pos)
		var pulse : float   = (sin(_bob_t * 16.0) + 1.0) * 0.5
		var alpha : float   = _beam_warn_t
		draw_circle(wl, 36.0, Color(0.8, 0.2, 1.0, alpha * (0.18 + pulse * 0.12)))
		draw_arc(wl, 36.0, 0, TAU, 40, Color(0.9, 0.3, 1.0, alpha * (0.75 + pulse * 0.20)), 2.5)
		var cs : float = 14.0
		draw_line(wl + Vector2(-cs, 0), wl + Vector2(cs, 0), Color(1.0, 0.5, 1.0, alpha * (0.85 + pulse * 0.15)), 2.5)
		draw_line(wl + Vector2(0, -cs), wl + Vector2(0, cs), Color(1.0, 0.5, 1.0, alpha * (0.85 + pulse * 0.15)), 2.5)

	# --- BOLT UYARI ---
	if _bolt_active and _bolt_pts.is_empty():
		var t_local : Vector2 = to_local(_bolt_target)
		var pulse   : float   = (sin(_bob_t * 10.0) + 1.0) * 0.5
		draw_circle(t_local, BOLT_RADIUS,       Color(0.0, 0.50, 1.0, 0.18 + pulse * 0.12))
		draw_circle(t_local, BOLT_RADIUS * 0.55, Color(0.1, 0.70, 1.0, 0.28 + pulse * 0.20))
		var cs : float = 12.0
		draw_line(t_local + Vector2(-cs, 0), t_local + Vector2(cs, 0),
			Color(0.4, 0.9, 1.0, 0.85 + pulse * 0.15), 2.5)
		draw_line(t_local + Vector2(0, -cs), t_local + Vector2(0, cs),
			Color(0.4, 0.9, 1.0, 0.85 + pulse * 0.15), 2.5)

	# --- BOLT CARPMA ---
	# Yıldırımın görseli artık sprite (_spawn_bolt_vfx, Calamity Lightning kareleri). Eski elle çizilen
	# zikzak/uç daireleri kaldırıldı; `_bolt_pts` sadece "çarpma oldu → uyarı dairesini gizle" bayrağı.

	if _bolt_flash > 0.0:
		draw_circle(Vector2.ZERO, 45.0 * _bolt_flash, Color(0.0, 0.55, 1.0, _bolt_flash * 0.45))

func take_damage(amount: int, _from_ally: bool = false, _kill_cause: String = "normal", physical: bool = false) -> void:
	if is_dead: return
	if physical: _physical_flash()
	health -= amount
	var game := get_parent()
	if game.has_method("update_boss_bar"):
		game.update_boss_bar(0, max(health, 0), 0, max_health)
	if health <= 0:
		die()

func die() -> void:
	if is_dead: return
	is_dead = true
	_fade_laser_snd(0.2)
	_sprite.scale = Vector2(NYX_SCALE, NYX_SCALE)   # ışınlanma portal ölçeği ortada kalmışsa ölüm animasyonu normal boyutta
	_laser_active = false
	_laser_beams_on = false
	_set_laser_arms_visible(false)
	_set_tpbeam_visible(false)
	_fade_bolt_snd(0.2)
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	var game := get_parent()
	if game.has_method("subject_died"):
		game.subject_died()
	if game.has_method("hide_boss_bar"):
		game.hide_boss_bar()
	_sprite.play("death")
	await _sprite.animation_finished
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(self):
		queue_free()

func apply_slow(amount: float, duration: float = 3.0, _source: String = "cryo", _anchor_pos: Vector2 = Vector2.ZERO) -> void:
	if is_slowed: return
	is_slowed = true; original_speed = speed; speed *= (1.0 - amount)
	_boss_set_element("slow")
	await get_tree().create_timer(duration).timeout
	if not is_instance_valid(self): return
	speed = original_speed; is_slowed = false; _boss_clear_element()

func apply_frozen() -> void:
	is_frozen = true; is_wet = false
	_boss_set_element("frozen")
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self): return
	is_frozen = false; _boss_clear_element()

func apply_wet() -> void:
	is_wet = true
	_boss_set_element("wet")
	await get_tree().create_timer(5.0).timeout
	if not is_instance_valid(self): return
	is_wet = false; _boss_clear_element()

func apply_glitch(_duration: float = 2.0) -> void:
	if is_glitched: return
	is_glitched = true
	_boss_set_element("glitch")
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self): return
	is_glitched = false; _boss_clear_element()

func apply_electrified() -> void:
	if is_electrified: return
	is_electrified = true
	_boss_set_element("electrified")
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		is_electrified = false; _boss_clear_element()

func apply_burn() -> void:
	if is_burning: return
	is_burning = true
	_boss_set_element("burn")
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self) and health > 0:
			health -= 2
			if health <= 0: die()
	if not is_instance_valid(self): return
	is_burning = false; _boss_clear_element()

func _boss_set_element(elem: String) -> void:
	var game := get_parent()
	if game.has_method("update_boss_element"):
		game.update_boss_element(elem)

func _boss_clear_element() -> void:
	var game := get_parent()
	if game.has_method("clear_boss_element"):
		game.clear_boss_element()

func _physical_flash() -> void:
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	await get_tree().create_timer(0.08, false).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1, 1)
