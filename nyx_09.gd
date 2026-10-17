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
const LASER_HIT_W    := 42.0   # genis tutma — lazer hizli doner, dar olunca kaciriyor
const LASER_SPEED    := 1.75
const LASER_DURATION := 4.0
const LASER_COOLDOWN := 9.0
const LASER_DMG_INT  := 0.10   # her 0.1s kontrol — doner lazer icin gerekli
const LASER_DAMAGE   := 2      # daha sik carptigimiz icin hasar dusuruldu

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

	# Spin (rotation frame'leri, saat yonunde: E -> SE -> S -> SW -> W -> NW -> N -> NE)
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 10.0)
	frames.set_animation_loop("spin", true)
	for d in ["east","south-east","south","south-west","west","north-west","north","north-east"]:
		frames.add_frame("spin", load(BASE_ROT + d + ".png"))

	_sprite.sprite_frames = frames

func play_entry(land_pos: Vector2) -> void:
	_fixed_y = land_pos.y
	position  = Vector2(land_pos.x, -200.0)
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
		_laser_angle   += LASER_SPEED * delta
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

	# Hareket (lazer sirasinda dur)
	if _laser_active:
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
	_laser_dur_left = LASER_DURATION
	_laser_dmg_t    = 0.5   # ilk hasardan once kisa bekleme
	_warn_flash     = 0.0
	_laser_angle    = randf() * TAU   # rastgele baslangic acisi
	_sprite.play("spin")

func _stop_laser() -> void:
	_laser_active = false
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

	# Ilk sarj
	_sprite.play("charge")
	await get_tree().create_timer(0.45).timeout
	if not is_instance_valid(self) or is_dead: return

	# 3 kez tp + beam, 1.5s arayla
	for _strike in range(3):
		if not is_instance_valid(self) or is_dead: return

		# Hedef: player'in anlık X pozisyonu
		var pl := get_tree().get_first_node_in_group("player")
		_tele_pos = Vector2(
			clamp(pl.global_position.x if is_instance_valid(pl) else global_position.x, 420.0, 1570.0),
			_fixed_y
		)

		# --- KAYBOLIS ---
		_tele_flash = 1.0
		queue_redraw()
		var vanish := create_tween()
		vanish.set_parallel(true)
		vanish.tween_property(_sprite, "scale",    Vector2(0.0, 0.0),         0.28)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		vanish.tween_property(_sprite, "modulate", Color(0.2, 0.6, 2.0, 0.0), 0.28)
		await vanish.finished
		if not is_instance_valid(self) or is_dead: return
		_sprite.visible  = false
		_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		position         = _tele_pos

		# Uyari gostergesi (0.5s)
		_tele_warn_t = 1.0
		queue_redraw()
		await get_tree().create_timer(0.5).timeout
		if not is_instance_valid(self) or is_dead: return

		# --- BELIRIS ---
		_sprite.visible  = true
		_sprite.modulate = Color(0.2, 0.6, 2.0, 1.0)
		_sprite.scale    = Vector2(0.0, 0.0)
		_tele_flash      = 1.0
		_tele_ring_r     = 5.0
		queue_redraw()

		var appear := create_tween()
		appear.set_parallel(true)
		appear.tween_property(_sprite, "scale",    Vector2(NYX_SCALE, NYX_SCALE) * 1.235, 0.22)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		appear.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.22)
		var ring_tw := create_tween()
		ring_tw.tween_method(
			func(v: float): _tele_ring_r = v; queue_redraw(),
			5.0, TELE_RADIUS * 1.6, 0.45
		)
		await appear.finished
		if not is_instance_valid(self) or is_dead: return
		_sprite.scale = Vector2(NYX_SCALE, NYX_SCALE)

		# Kisa sarj (0.25s) — hedef uyarisi goster
		var pw := get_tree().get_first_node_in_group("player")
		if is_instance_valid(pw):
			_beam_warn_pos = pw.global_position
			_beam_warn_t   = 1.0
			queue_redraw()
		await get_tree().create_timer(0.25).timeout
		if not is_instance_valid(self) or is_dead: return

		# BEAM ATIS — mark pozisyonuna ates, oradan kacabilirsin
		_beam_target = _beam_warn_pos
		_beam_active = true
		_beam_t      = 0.0
		await get_tree().create_timer(BEAM_LIFETIME * 0.75).timeout
		if is_instance_valid(self) and not is_dead:
			var p2 := get_tree().get_first_node_in_group("player")
			if is_instance_valid(p2) and not p2.is_dashing:
				if p2.global_position.distance_to(_beam_warn_pos) < BEAM_HIT_RADIUS:
					p2.take_damage(TELE_DAMAGE)

		var game := get_parent()
		if game.has_method("_screen_shake"):
			game._screen_shake()
		_tele_ring_r = 0.0

		# Sonraki strike'a kadar 1.5s bekle (son strike'ta bekleme yok)
		if _strike < 2:
			await get_tree().create_timer(1.5).timeout

	# Sekans bitti
	_tele_active  = false
	_tele_timer   = TELE_COOLDOWN
	if _laser_timer < 5.0: _laser_timer = 5.0
	if _bolt_timer  < 5.0: _bolt_timer  = 5.0
	position.y = _fixed_y
	_sprite.play("walk")

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
	if dir.x < -0.001:
		max_len = min(max_len, (global_position.x - 360.0)  / abs(dir.x))
	if dir.x >  0.001:
		max_len = min(max_len, (1630.0 - global_position.x) /     dir.x)
	if dir.y < -0.001:
		max_len = min(max_len, (global_position.y - 260.0)  / abs(dir.y))
	if dir.y >  0.001:
		max_len = min(max_len, (1040.0 - global_position.y) /     dir.y)
	return maxf(max_len, 0.0)

func _check_laser_hit() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	var to_player : Vector2 = player.global_position - global_position
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

	# --- LAZER UYARI ---
	if _warn_flash > 0.01 and not _laser_active:
		draw_circle(Vector2.ZERO, 30.0, Color(0.1, 0.7, 1.0, _warn_flash * 0.55))

	# --- LAZER (3 kol koni) ---
	if _laser_active:
		for i in 3:
			var angle    : float   = _laser_angle + float(i) * TAU / 3.0
			var dir      : Vector2 = Vector2(cos(angle), sin(angle))
			var perp     : Vector2 = dir.rotated(PI * 0.5)
			var clip_len : float   = _laser_clip_length(dir)
			var tip      : Vector2 = dir * clip_len
			draw_colored_polygon(PackedVector2Array([Vector2.ZERO, tip + perp * 28.0, tip - perp * 28.0]),
				Color(0.0, 0.4, 1.0, 0.13))
			draw_colored_polygon(PackedVector2Array([Vector2.ZERO, tip + perp * 11.0, tip - perp * 11.0]),
				Color(0.1, 0.65, 1.0, 0.82))
			draw_colored_polygon(PackedVector2Array([Vector2.ZERO, tip + perp * 3.0, tip - perp * 3.0]),
				Color(0.75, 0.96, 1.0, 0.95))
		draw_circle(Vector2.ZERO, 11.0, Color(0.4, 0.85, 1.0, 0.95))

	# --- TELEPORT FLASH (mavi) ---
	if _tele_flash > 0.0:
		draw_circle(Vector2.ZERO, 42.0 * _tele_flash, Color(0.0, 0.4, 1.0, _tele_flash * 0.70))
		draw_circle(Vector2.ZERO, 18.0 * _tele_flash, Color(0.5, 0.9, 1.0, _tele_flash * 0.92))

	# --- TELEPORT HEDEF UYARI ---
	if _tele_active and _tele_warn_t > 0.0:
		var t_loc : Vector2 = to_local(_tele_pos)
		var pulse : float   = (sin(_bob_t * 14.0) + 1.0) * 0.5
		draw_circle(t_loc, TELE_RADIUS,
			Color(0.0, 0.4, 0.95, _tele_warn_t * (0.18 + pulse * 0.10)))
		draw_arc(t_loc, TELE_RADIUS, 0, TAU, 40,
			Color(0.1, 0.75, 1.0, _tele_warn_t * (0.70 + pulse * 0.20)), 2.5)
		for i in 4:
			var a  : float   = float(i) / 4.0 * TAU
			var cv : Vector2 = t_loc + Vector2(cos(a), sin(a)) * TELE_RADIUS
			draw_circle(cv, 5.0 * _tele_warn_t, Color(0.4, 0.9, 1.0, _tele_warn_t))

	# --- TELEPORT BELIRME HALKASI ---
	if _tele_ring_r > 0.0:
		var fade : float = max(0.0, 1.0 - _tele_ring_r / (TELE_RADIUS * 1.6))
		draw_arc(Vector2.ZERO, _tele_ring_r, 0, TAU, 40,
			Color(0.1, 0.65, 1.0, fade * 0.9), 3.0)
		draw_arc(Vector2.ZERO, _tele_ring_r * 0.6, 0, TAU, 40,
			Color(0.5, 0.90, 1.0, fade * 0.5), 1.5)

	# --- BEAM (tp sonrasi dalgali huzmesi) ---
	if _beam_active and not _beam_target.is_equal_approx(Vector2.ZERO):
		var alpha      : float   = 1.0 - _beam_t
		var tip_l      : Vector2 = to_local(_beam_target)
		var total_l    : float   = tip_l.length()
		if total_l > 1.0:
			var b_dir  : Vector2 = tip_l.normalized()
			var b_perp : Vector2 = b_dir.rotated(PI * 0.5)
			var segs   : int     = 14
			var centers: Array   = []
			centers.append(Vector2.ZERO)
			for si in range(1, segs):
				var t    : float   = float(si) / float(segs)
				var base : Vector2 = b_dir * total_l * t
				# Sin dalgasi — inceden kalin, _bob_t ile canli
				var jitter : float = sin(t * PI) * sin(t * 8.0 + _bob_t * 20.0) * 22.0 * (1.0 - t * 0.4)
				centers.append(base + b_perp * jitter)
			centers.append(tip_l)

			# Dal-branchler
			for bi in 3:
				var bst : int    = int(randf_range(3, segs - 2))
				var bpt : Vector2 = centers[bst]
				var ba  : float  = b_dir.angle() + randf_range(-0.7, 0.7)
				var blen : float = randf_range(18.0, 45.0)
				var bend : Vector2 = bpt + Vector2(cos(ba), sin(ba)) * blen
				var bw   : float = 3.0 * float(bst) / float(segs) * alpha
				draw_line(bpt, bend, Color(0.1, 0.7, 1.0, alpha * 0.65), max(bw, 0.8))
				draw_line(bpt, bend, Color(0.7, 0.95, 1.0, alpha * 0.80), 0.8)

			# Ana huzmesi: her segment ince baslar kalin biter
			for si in range(centers.size() - 1):
				var t   : float   = float(si) / float(centers.size() - 1)
				var ca  : Vector2 = centers[si]
				var cb  : Vector2 = centers[si + 1]
				var w   : float   = lerp(0.5, 14.0, t)   # ince → kalin
				# Dis parlama
				draw_line(ca, cb, Color(0.0, 0.45, 1.0, alpha * 0.28), w * 2.8)
				# Ana beam
				draw_line(ca, cb, Color(0.1, 0.65, 1.0, alpha * 0.88), w)
				# Parlak cekirdek
				draw_line(ca, cb, Color(0.75, 0.96, 1.0, alpha * 0.95), max(w * 0.25, 0.7))

			# Hedef noktasi carpma
			draw_circle(tip_l, 20.0 * alpha, Color(0.1, 0.7, 1.0, alpha * 0.6))
			draw_circle(tip_l, 9.0  * alpha, Color(0.8, 0.97, 1.0, alpha))

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
	_laser_active = false
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

func apply_slow(amount: float, duration: float = 3.0) -> void:
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

func apply_glitch() -> void:
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
