extends CharacterBody2D

signal landed

const BASE := "res://assets/enemys/S_Miler_79/"

# Hover yok — yerde yürüyen boss
const BOB_SPD := 3.0   # sadece uyarı efektlerinde kullanılır

# --- Stats ---
var health        : int   = 700
var max_health    : int   = 700
var speed         : float = 68.0
var original_speed: float = 68.0
var is_dead       : bool  = false
var is_frozen     : bool  = false
var is_slowed     : bool  = false
var is_wet        : bool  = false
var is_burning    : bool  = false
var is_electrified: bool  = false
var is_glitched   : bool  = false

# --- Giriş & hareket ---
var _in_entry      : bool   = true
var _entry_progress: float  = 0.0
var _fixed_y       : float  = 300.0   # play_entry tarafından ayarlanır
var _bob_t         : float  = 0.0
var _shadow_alpha  : float  = 0.0

var _sprite: AnimatedSprite2D = null

# Missile VFX sırasında gölge — frame 10'a (≈0.56s) kadar küçülür, sonra yok olur
var _missile_impact_shadow_t  : float  = 0.0
var _missile_impact_shadow_pos: Vector2 = Vector2.ZERO
# Füze düşüş+patlama hızlandırması: uyarı bittikten sonra hasara kadar geçen süre 0.45sn / MISSILE_FALL_SPEED.
# (1.0 = eski hız; yürüyerek kaçılabildiği için 2.0 — bu değeri büyüt = uyarıdan sonra daha az kaçma süresi)
const MISSILE_FALL_SPEED := 2.0
const MISSILE_IMPACT_SHADOW_DUR := 0.556 / MISSILE_FALL_SPEED  # 10 frame @ 18fps (hızlandırılmış)

# ─────────────────────────────────────────────────────────
# GATLING  — 3'lü mermi salvosu × 5 burst
# ─────────────────────────────────────────────────────────
const GATLING_CD      := 4.5     # 6 -> 4.5 (daha sık)
const SFX_MACHINEGUN  := "res://assets/sfx/bosses/s-miler79/machineGun.ogg"
const SFX_SWORD_SWING := "res://assets/sfx/bosses/s-miler79/swordSwing.ogg"
const SFX_MISSILE_EXPLOSION := "res://assets/sfx/bosses/s-miler79/homingMissileExplosion.ogg"
const SFX_FALLING     := "res://assets/sfx/bosses/s-miler79/fallingDown.ogg"
const ENTRY_FALL_TIME := 2.5   # girişte yukarıdan iniş süresi (sn)
const ENTRY_SHADOW_ALPHA := 0.36   # iniş gölgesinin son opaklığı (BlobShadow.COLOR ile aynı)
const LAND_Y_OFFSET := -18.5 * SPRITE_SCALE   # iniş karelerini idle ile hizalar (son iniş karesi idle'dan ~18-19px aşağıda)
const LAND_IMPACT_FPS := 14.0  # iniş VFX'inin (30 kare) toparlanma hızı ≈ 2.1sn
const GATLING_BURSTS  := 5
const GATLING_SPREAD  := 10.0   # derece
var _gatling_t    : float = 3.0
var _gatling_busy : bool  = false

# ─────────────────────────────────────────────────────────
# SWING SWORD  — TP → kılıç → geri TP
# ─────────────────────────────────────────────────────────
const SWING_CD     := 7.0     # 9 -> 7
const SWING_DMG    := 28
const SWING_RADIUS := 78.0
const SWING_STANDOFF := 150.0  # boss ışınlanınca uyarı dairesinin merkezine bu kadar uzakta durur
const SWING_WARN   := 0.65   # uyarı süresi (s)
var _swing_t      : float   = 7.0
var _swing_busy      : bool    = false
var _swing_at_player : bool    = false  # TP sonrası player yanında → Y sabitleme kapalı
var _swing_warn_t    : float   = 0.0   # 1→0 uyarı alpha
var _swing_pos       : Vector2 = Vector2.ZERO
var _home_pos        : Vector2 = Vector2.ZERO

# ─────────────────────────────────────────────────────────
# MISSILE  — kafasını sallayarak füze çağırır
# ─────────────────────────────────────────────────────────
const MISSILE_CD   := 9.0     # 12 -> 9
const MISSILE_WARN := 0.65   # uyarı süresi (s) — Swing ile aynı (SWING_WARN); eskiden 1.8sn çok genişti
const MISSILE_COUNT    := 3     # art arda füze sayısı
const MISSILE_INTERVAL := 1.0   # füzeler arası (uyarı başlangıcından uyarı başlangıcına, sn)
const MISSILE_DMG  := 38
const MISSILE_R    := 95.0
var _missile_t       : float   = 5.0
var _missile_busy    : bool    = false
var _missile_warn_t  : float   = 0.0   # 1→0
var _missile_warn_pos: Vector2 = Vector2.ZERO

var _bullet_scene = preload("res://bullet.tscn")

# Bir saldırı bitince diğer hepsinin sayacı en az bu kadar sürer → ardışık saldırılar arasında kısa nefes,
# ama uzun boş yürüyüş de yok.
const ATTACK_GAP := 0.8   # 1.5 -> 0.8 (saldırılar arası nefes payı)
func _attack_done() -> void:
	_gatling_t = maxf(_gatling_t, ATTACK_GAP)
	_swing_t   = maxf(_swing_t,   ATTACK_GAP)
	_missile_t = maxf(_missile_t, ATTACK_GAP)

# ══════════════════════════════════════════════════════════
# READY / SETUP
# ══════════════════════════════════════════════════════════
# Boss boyu: gövde ≈ Cyber-404 ile aynı (görünen gövde ~190×182px). 232px karede gövde 103×100px →
# 190/103 ≈ 1.84 sprite ölçeği (eskiden 0.9). Çarpışma kapsülü de aynı oranda büyür.
const SPRITE_SCALE := 1.84
const SIZE_MULT := SPRITE_SCALE / 0.9

func _ready() -> void:
	z_index = 3
	add_to_group("subjects")
	_apply_difficulty_hp()
	call_deferred("_attach_shadow")

	var col  := CollisionShape2D.new()
	col.name  = "CollisionShape2D"
	# Görünen gövdenin tamamını (bacaklar dahil) kapsayan dikdörtgen: kare içinde gövde 103×100px × SPRITE_SCALE.
	# Eski kapsül yarıçap 45 / yükseklik 90 idi → gövdenin yarısı genişlikte, alt yarısı (bacaklar) dışarıda kalıyordu.
	var shape := RectangleShape2D.new()
	shape.size = Vector2(103.0, 100.0) * SPRITE_SCALE * 0.96
	col.shape    = shape
	col.disabled = true
	add_child(col)

	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale          = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.position.y     = 0.0   # yerde — hover yok
	add_child(_sprite)
	_setup_frames()

func _setup_frames() -> void:
	var f := SpriteFrames.new()
	if f.has_animation("default"):
		f.remove_animation("default")

	# Idle — 9 frame
	f.add_animation("idle")
	f.set_animation_speed("idle", 8.0)
	f.set_animation_loop("idle", true)
	for i in range(9):
		f.add_frame("idle", load(BASE + "idle/frame_%03d.png" % i))

	# Walk South — giriş inişi (6 frame)
	f.add_animation("walk_s")
	f.set_animation_speed("walk_s", 8.0)
	f.set_animation_loop("walk_s", true)
	for i in range(6):
		f.add_frame("walk_s", load(BASE + "walk/south/frame_%03d.png" % i))

	# Walk South-East — sağa hareket (6 frame)
	f.add_animation("walk_se")
	f.set_animation_speed("walk_se", 8.0)
	f.set_animation_loop("walk_se", true)
	for i in range(6):
		f.add_frame("walk_se", load(BASE + "walk/south-east/frame_%03d.png" % i))

	# Walk South-West — sola hareket (6 frame)
	f.add_animation("walk_sw")
	f.set_animation_speed("walk_sw", 8.0)
	f.set_animation_loop("walk_sw", true)
	for i in range(6):
		f.add_frame("walk_sw", load(BASE + "walk/south-west/frame_%03d.png" % i))

	# Gatling — 14 frame @12fps ≈ 1.17sn, tek seferlik (saldırı süresi ≈ 0.3+0.9+0.1 = 1.3sn)
	f.add_animation("gatling")
	f.set_animation_speed("gatling", 12.0)
	f.set_animation_loop("gatling", false)
	for i in range(14):
		f.add_frame("gatling", load(BASE + "skillGatling/frame_%03d.png" % i))

	# Missile duruş — 9 frame, döngülü (uyarı boyunca)
	f.add_animation("missile_pose")
	f.set_animation_speed("missile_pose", 9.0)   # 6 → 9: kafa sallama 1.5× hızlı (füze zamanlamalarına dokunulmadı)
	f.set_animation_loop("missile_pose", true)
	for i in range(9):
		f.add_frame("missile_pose", load(BASE + "skillMissile/frame_%03d.png" % i))

	# Swing Sword — 4 frame, tek seferlik
	f.add_animation("swing")
	f.set_animation_speed("swing", 9.0)
	f.set_animation_loop("swing", false)
	for i in range(4):
		f.add_frame("swing", load(BASE + "skillSwingSword/frame_%03d.png" % i))

	# Death — 9 frame, tek seferlik
	f.add_animation("death")
	f.set_animation_speed("death", 5.0)
	f.set_animation_loop("death", false)
	for i in range(9):
		f.add_frame("death", load(BASE + "death/frame_%03d.png" % i))

	# İniş VFX'i (landing/frame_001..036): 1-6 jet alevleriyle süzülme (iniş boyunca döngü),
	# 7-36 yere değiş + alev + toz + toparlanma (tek seferlik, iniş anında)
	f.add_animation("land_fall")
	f.set_animation_speed("land_fall", 12.0)
	f.set_animation_loop("land_fall", true)
	for i in range(1, 7):
		f.add_frame("land_fall", load(BASE + "landing/frame_%03d.png" % i))
	f.add_animation("land_impact")
	f.set_animation_speed("land_impact", LAND_IMPACT_FPS)
	f.set_animation_loop("land_impact", false)
	for i in range(7, 37):
		f.add_frame("land_impact", load(BASE + "landing/frame_%03d.png" % i))

	_sprite.sprite_frames = f

# ══════════════════════════════════════════════════════════
# GİRİŞ SEKANSİ
# ══════════════════════════════════════════════════════════
func play_entry(land_pos: Vector2) -> void:
	_fixed_y = land_pos.y
	position  = Vector2(land_pos.x, -200.0)
	_sprite.play("land_fall")   # jetlerle süzülüyor

	# İniş boyunca boss'a bağlı BlobShadow gizli (boss'la birlikte düşüyordu); yerine yerde sabit,
	# küçükten büyüyen bir iniş gölgesi var
	await get_tree().process_frame
	_set_blob_alpha(0.0)
	# İniş karelerinde karakter idle'dan ~18.5px (kare içi) aşağı çizilmiş → sprite'ı yukarı al, yoksa
	# animasyon bitip idle'a geçince boss "gölgesine doğru" yukarı zıplıyor. BlobShadow ölçümünü
	# (sprite.position.y'yi hesaba katar ve önbelleğe alır) bozmasın diye ölçümden SONRA (2. kare) uygulanır.
	await get_tree().process_frame
	_sprite.position.y = LAND_Y_OFFSET

	# Uyarı sesi: önce ses başlar, boss ekran dışında bekler; sesin SONU iniş anına denk gelir
	# (Cyber-404 sandık girişindeki aynı desen — _pre_delay = ses süresi - iniş süresi)
	var fall_stream: AudioStream = load(SFX_FALLING) if ResourceLoader.exists(SFX_FALLING) else null
	if fall_stream != null:
		Sfx.play_path_dedicated(SFX_FALLING)
		var pre_delay: float = maxf(0.0, fall_stream.get_length() - ENTRY_FALL_TIME)
		if pre_delay > 0.0:
			await get_tree().create_timer(pre_delay, false).timeout
			if not is_instance_valid(self):
				return

	_set_blob_alpha(0.0)   # BlobShadow geç eklenmişse diye tekrar
	var ground := _make_entry_shadow(land_pos)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", land_pos.y, ENTRY_FALL_TIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_entry_progress, 0.0, 1.0, ENTRY_FALL_TIME)
	tw.tween_property(ground, "scale", Vector2.ONE, ENTRY_FALL_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(ground, "color:a", ENTRY_SHADOW_ALPHA, ENTRY_FALL_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished

	# Gölge el değiştirir: iniş gölgesi gider, aynı konumdaki BlobShadow açılır
	if is_instance_valid(ground):
		ground.queue_free()
	_set_blob_alpha(1.0)
	_entry_progress = 1.0
	_sprite.play("land_impact")

	# Yere değiş: sahne temizliği/sarsıntı + boss barı hemen, boss toparlanana kadar saldırmaz
	emit_signal("landed")
	var game := get_parent()
	if game.has_method("show_boss_bar"):
		game.show_boss_bar(self, "S-MILER  //  79")
	if game.has_method("update_boss_bar"):
		game.update_boss_bar(0, health, 0, max_health)

	await _sprite.animation_finished
	if not is_instance_valid(self) or is_dead:
		return
	_in_entry = false
	$CollisionShape2D.disabled = false
	_sprite.position.y = 0.0
	_sprite.play("idle")

func _set_blob_alpha(a: float) -> void:
	var blob := get_node_or_null("BlobShadow")
	if blob != null:
		blob.modulate.a = a

# Yerde sabit, küçükten büyüyen iniş gölgesi — boyut/konum BlobShadow'la aynı hesap (gövde 103px ×
# SPRITE_SCALE × 0.40 = rx; ayak hizası idle karesinin alt sınırı), böylece iniş anında kesintisiz devralır.
func _make_entry_shadow(land_pos: Vector2) -> Polygon2D:
	# BlobShadow ile BİREBİR aynı ölçüm: ilk animasyonun (get_animation_names()[0]) ilk karesinin alfa sınırı.
	# (Önceden "idle" ölçülüyordu → farklı karede ayak hizası değişip gölge iniş sonrası kayıyordu)
	var rx := 103.0 * SPRITE_SCALE * 0.40
	var feet := 71.0 * SPRITE_SCALE
	var cx := 0.0
	var names := _sprite.sprite_frames.get_animation_names()
	if not names.is_empty() and _sprite.sprite_frames.get_frame_count(names[0]) > 0:
		var tex: Texture2D = _sprite.sprite_frames.get_frame_texture(names[0], 0)
		if tex != null:
			var img := tex.get_image()
			if img != null:
				var r := img.get_used_rect()
				if r.size.x > 0:
					cx = (float(r.position.x) + float(r.size.x) * 0.5 - float(tex.get_width()) * 0.5) * SPRITE_SCALE
					feet = (float(r.position.y + r.size.y) - float(tex.get_height()) * 0.5) * SPRITE_SCALE
					rx = maxf(float(r.size.x) * SPRITE_SCALE * 0.40, 8.0)
	var ry := rx * 0.38
	var pts := PackedVector2Array()
	for i in 24:
		var a := float(i) / 24.0 * TAU
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	var sh := Polygon2D.new()
	sh.polygon = pts
	sh.color = Color(0.0, 0.0, 0.0, 0.05)
	sh.top_level = true
	sh.z_as_relative = false
	sh.z_index = 1
	sh.scale = Vector2(0.12, 0.12)
	add_child(sh)
	sh.global_position = land_pos + Vector2(cx, feet - ry * 0.35)
	return sh

func _set_entry_progress(v: float) -> void:
	_entry_progress = v
	_shadow_alpha   = v * 0.38
	queue_redraw()

# ══════════════════════════════════════════════════════════
# PHYSICS PROCESS
# ══════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	if is_dead or _in_entry:
		return
	if is_frozen:
		return

	# _bob_t sadece uyarı efektleri için
	_bob_t += delta
	queue_redraw()

	# Uyarı göstergelerini zamanla güncelle
	if _missile_warn_t > 0.0:
		_missile_warn_t = max(0.0, _missile_warn_t - delta / MISSILE_WARN)
		queue_redraw()
	if _missile_impact_shadow_t > 0.0:
		_missile_impact_shadow_t = max(0.0, _missile_impact_shadow_t - delta / MISSILE_IMPACT_SHADOW_DUR)
		queue_redraw()
	if _swing_warn_t > 0.0:
		_swing_warn_t = max(0.0, _swing_warn_t - delta / SWING_WARN)
		queue_redraw()

	if not _gatling_busy and not _swing_busy and not _missile_busy:
		# Saldırı zamanlayıcıları
		_gatling_t -= delta
		_swing_t   -= delta
		_missile_t -= delta

		if _gatling_t <= 0.0:
			_start_gatling()
		elif _missile_t <= 0.0:
			_start_missile()
		elif _swing_t <= 0.0:
			_start_swing()

		# Yetenek bu frame'de başladıysa hareket kodunu atla
		if _gatling_busy or _swing_busy or _missile_busy:
			velocity = Vector2.ZERO
			global_position.y = _fixed_y
			return

		# Yatay hareket — player'ın X konumuna hizalanır
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player:
			var dx: float = player.global_position.x - global_position.x
			if abs(dx) > 24.0:
				var dir: float = sign(dx)
				velocity = Vector2(dir * speed, 0)
				var anim := "walk_se" if dir > 0 else "walk_sw"
				if _sprite.animation != anim:
					_sprite.play(anim)
			else:
				velocity = Vector2.ZERO
				if _sprite.animation in ["walk_se", "walk_sw"]:
					_sprite.play("idle")
		else:
			velocity = Vector2.ZERO

		# Y sabit çizgisini koru
		move_and_slide()
		global_position.y = _fixed_y
	else:
		# Saldırı sırasında hareketsiz kal
		velocity = Vector2.ZERO
		# Swing TP sırasında Y sabitleme KAPALI — player yanında duruyoruz
		if not _swing_at_player:
			global_position.y = _fixed_y

# ══════════════════════════════════════════════════════════
# SALDIRI — GATLING
# Animasyon boyunca 5 × 3 mermi salvosu
# ══════════════════════════════════════════════════════════
func _start_gatling() -> void:
	if _gatling_busy or _swing_busy or _missile_busy:
		return
	_gatling_busy = true
	_sprite.play("gatling")

	# Animasyonun başlaması için kısa ön hazırlık
	await get_tree().create_timer(0.3, false).timeout

	# Ateş sesi: salvolar başlarken çalar, bitince kısılıp kesilir
	var gun_snd: AudioStreamPlayer = Sfx.play_path_dedicated(SFX_MACHINEGUN)

	for _b in range(GATLING_BURSTS):
		if is_dead or not is_instance_valid(self):
			break
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			break
		var dir: Vector2 = (player.global_position - global_position).normalized()
		# 3 mermi: -spread, 0, +spread
		for i in range(3):
			var spread := deg_to_rad(-GATLING_SPREAD + i * GATLING_SPREAD)
			var bullet  = _bullet_scene.instantiate()
			bullet.global_position = global_position
			get_parent().add_child(bullet)
			bullet.launch(dir.rotated(spread))
		await get_tree().create_timer(0.18, false).timeout

	if is_instance_valid(gun_snd):
		var ftw := gun_snd.create_tween()
		ftw.tween_property(gun_snd, "volume_db", -40.0, 0.35)
		ftw.tween_callback(gun_snd.stop)

	await get_tree().create_timer(0.1, false).timeout
	if not is_instance_valid(self) or is_dead:
		return

	_gatling_busy = false
	_gatling_t    = GATLING_CD
	_attack_done()
	_sprite.play("idle")

# ══════════════════════════════════════════════════════════
# SALDIRI — SWING SWORD
# Kısa uyarı → TP player yanına → kılıç → TP geri
# ══════════════════════════════════════════════════════════
func _start_swing() -> void:
	if _gatling_busy or _swing_busy or _missile_busy:
		return
	_swing_busy = true
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_swing_busy = false
		_swing_t    = SWING_CD
		return

	_home_pos     = global_position
	_swing_pos    = player.global_position
	_swing_warn_t = 1.0
	queue_redraw()

	# Uyarı süresi
	await get_tree().create_timer(SWING_WARN, false).timeout
	if not is_instance_valid(self) or is_dead:
		return

	_swing_warn_t = 0.0
	queue_redraw()

	# Player'ın yanına TP — Y sabitleme kapalı
	# Oyuncunun üstüne değil, uyarı alanının SWING_STANDOFF px önüne (kendi tarafına) ışınlan
	var back: Vector2 = _home_pos - _swing_pos
	back = back.normalized() if back.length() > 1.0 else Vector2.UP
	var tp: Vector2 = _swing_pos + back * SWING_STANDOFF
	tp.x = clampf(tp.x, 420.0, 1570.0)
	tp.y = clampf(tp.y, 300.0, 1020.0)
	_swing_at_player = true
	global_position  = tp
	_sprite.play("swing")
	Sfx.play_path_dedicated(SFX_SWORD_SWING)

	# Kılıç iner — kısa gecikme sonrası hasar
	await get_tree().create_timer(0.12, false).timeout
	if not is_instance_valid(self) or is_dead:
		_swing_at_player = false
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	# Hasar alanı = uyarıda gösterilen kırmızı daire (boss'un konumu değil)
	if p and _swing_pos.distance_to(p.global_position) < SWING_RADIUS:
		p.take_damage(SWING_DMG)

	# Animasyon bitmesini bekle
	await _sprite.animation_finished
	if not is_instance_valid(self) or is_dead:
		_swing_at_player = false
		return

	# Sabit Y çizgisine geri TP
	_swing_at_player = false
	global_position  = Vector2(_home_pos.x, _fixed_y)

	_swing_busy = false
	_swing_t    = SWING_CD
	_attack_done()
	_sprite.play("idle")

# ══════════════════════════════════════════════════════════
# SALDIRI — MISSILE
# Kafasını sallar → uyarı halkası → füze VFX düşer
# ══════════════════════════════════════════════════════════
func _start_missile() -> void:
	if _gatling_busy or _swing_busy or _missile_busy:
		return
	_missile_busy = true
	if get_tree().get_first_node_in_group("player") == null:
		_missile_busy = false
		_missile_t    = MISSILE_CD
		return

	# Füze pozunu tüm seri boyunca koru (kafa sallama animasyonu)
	_sprite.play("missile_pose")

	# MISSILE_COUNT füze art arda; her biri uyarı başladığı andaki GÜNCEL oyuncu konumuna gider.
	# Füzeler arası (uyarı başlangıcından uyarı başlangıcına) MISSILE_INTERVAL sn.
	for i in range(MISSILE_COUNT):
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player == null or not is_instance_valid(self) or is_dead:
			break
		_missile_warn_pos = player.global_position
		_missile_warn_t   = 1.0
		queue_redraw()

		# Uyarı süresi — player kaçma şansı
		await get_tree().create_timer(MISSILE_WARN, false).timeout
		if not is_instance_valid(self) or is_dead:
			return

		_missile_warn_t = 0.0
		queue_redraw()

		# Impact gölgesini başlat — VFX frame 10'a kadar küçülür
		_missile_impact_shadow_pos = _missile_warn_pos
		_missile_impact_shadow_t   = 1.0

		# VFX'i hedefe bırak (bağımsız coroutine)
		_spawn_missile_vfx(_missile_warn_pos)

		if i < MISSILE_COUNT - 1:
			await get_tree().create_timer(maxf(MISSILE_INTERVAL - MISSILE_WARN, 0.0), false).timeout
			if not is_instance_valid(self) or is_dead:
				return
	# Son füze bırakıldı → kafa sallama içinde bulunduğu döngüyü TAMAMLAYIP biter (ne yarım kalır ne erken kesilir)
	var t0 := Time.get_ticks_msec()
	await _sprite.animation_looped
	if not is_instance_valid(self) or is_dead:
		return
	_sprite.play("idle")

	# Son füzenin düşüş/patlaması bitsin (toplam bekleme yine ≥ 1.0sn)
	var left := 1.0 - float(Time.get_ticks_msec() - t0) / 1000.0
	if left > 0.0:
		await get_tree().create_timer(left, false).timeout
		if not is_instance_valid(self) or is_dead:
			return

	_missile_busy = false
	_missile_t    = MISSILE_CD
	_attack_done()
	_sprite.play("idle")

# ──────────────────────────────────────────────────────────
# Füze VFX — hedef konumda patlama animasyonu + hasar
# ──────────────────────────────────────────────────────────
func _spawn_missile_vfx(pos: Vector2) -> void:
	var vfx := AnimatedSprite2D.new()
	vfx.texture_filter  = CanvasItem.TEXTURE_FILTER_NEAREST
	vfx.z_index         = 4
	vfx.scale           = Vector2(2.2, 2.2)          # 2x büyük
	vfx.global_position = Vector2(pos.x, pos.y - 240.0)  # tepeden başlar

	var vframes := SpriteFrames.new()
	if vframes.has_animation("default"):
		vframes.remove_animation("default")
	vframes.add_animation("explode")
	vframes.set_animation_speed("explode", 18.0 * MISSILE_FALL_SPEED)
	vframes.set_animation_loop("explode", false)
	for i in range(28):
		vframes.add_frame("explode", load(BASE + "skillMissile/VFX/frame_%03d.png" % i))
	vfx.sprite_frames = vframes

	get_parent().add_child(vfx)
	vfx.play("explode")

	# Yukarıdan aşağıya hızlanan düşüş
	var fall := vfx.create_tween()
	fall.tween_property(vfx, "global_position:y", pos.y, 0.38 / MISSILE_FALL_SPEED)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Çarpma anında hasar (düşüşün bitiminde)
	await get_tree().create_timer(0.45 / MISSILE_FALL_SPEED, false).timeout
	if is_dead or not is_instance_valid(self):
		return
	Sfx.play_path_dedicated(SFX_MISSILE_EXPLOSION)
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p and p.global_position.distance_to(pos) < MISSILE_R:
		p.take_damage(MISSILE_DMG)

	# Patlama animasyonu bitince temizle
	if is_instance_valid(vfx):
		await vfx.animation_finished
		if is_instance_valid(vfx):
			vfx.queue_free()

# ══════════════════════════════════════════════════════════
# HASAR & ÖLÜM
# ══════════════════════════════════════════════════════════
func take_damage(amount: int, _from_ally: bool = false, _kill_cause: String = "normal", physical: bool = false) -> void:
	if is_dead:
		return
	if physical: _physical_flash()
	health -= amount
	var game := get_parent()
	if game.has_method("update_boss_bar"):
		game.update_boss_bar(0, max(health, 0), 0, max_health)
	if health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	var game := get_parent()
	if game.has_method("subject_died"):
		game.subject_died()
	if game.has_method("hide_boss_bar"):
		game.hide_boss_bar()
	_sprite.play("death")
	await _sprite.animation_finished
	await get_tree().create_timer(1.5, false).timeout
	if is_instance_valid(self):
		queue_free()

# ══════════════════════════════════════════════════════════
# _DRAW — gölge + saldırı uyarıları
# ══════════════════════════════════════════════════════════
func _draw() -> void:
	if is_dead:
		return

	# (Eski sabit gövde-ortası gölgesi kaldırıldı: ayak gölgesi BlobShadow, iniş gölgesi _make_entry_shadow)

	# ── Swing Sword uyarısı — kırmızı halka ──
	if _swing_warn_t > 0.0 and not _swing_pos.is_equal_approx(Vector2.ZERO):
		var sloc  := to_local(_swing_pos)
		var pulse := (sin(_bob_t * 16.0) + 1.0) * 0.5
		draw_circle(sloc, SWING_RADIUS,
			Color(0.85, 0.05, 0.08, _swing_warn_t * (0.18 + pulse * 0.10)))
		draw_arc(sloc, SWING_RADIUS, 0, TAU, 48,
			Color(1.0, 0.15, 0.2, _swing_warn_t * (0.80 + pulse * 0.18)), 2.5)
		var cs := 10.0
		draw_line(sloc + Vector2(-cs, -cs), sloc + Vector2( cs,  cs),
			Color(1.0, 0.3, 0.3, _swing_warn_t * 0.9), 2.0)
		draw_line(sloc + Vector2( cs, -cs), sloc + Vector2(-cs,  cs),
			Color(1.0, 0.3, 0.3, _swing_warn_t * 0.9), 2.0)

	# ── Missile uyarısı — büyük gölge küçülür (füze yaklaşıyor) ──
	if _missile_warn_t > 0.0 and not _missile_warn_pos.is_equal_approx(Vector2.ZERO):
		var mloc   := to_local(_missile_warn_pos)
		# t=1.0 (başlangıç): gölge büyük (155px) ve soluk
		# t=0.0 (düşmek üzere): gölge küçük (22px) ve koyu
		var radius : float = lerp(22.0, 155.0, _missile_warn_t)
		var alpha  : float = lerp(0.78, 0.10, _missile_warn_t)
		draw_circle(mloc, radius, Color(0.0, 0.0, 0.0, alpha))
		# Merkez nokta — tam isabet yeri
		draw_circle(mloc, 5.0, Color(0.0, 0.0, 0.0,
			clamp(_missile_warn_t * -1.5 + 1.0, 0.3, 0.9)))

	# ── Missile çarptıktan sonra gölge VFX frame 10'a kadar küçülür ──
	if _missile_impact_shadow_t > 0.0 and not _missile_impact_shadow_pos.is_equal_approx(Vector2.ZERO):
		var mloc   := to_local(_missile_impact_shadow_pos)
		# t=1.0: gölge 22px koyu   →   t=0.0: yok
		var radius : float = lerp(0.0, 22.0, _missile_impact_shadow_t)
		var alpha  : float = lerp(0.0, 0.78, _missile_impact_shadow_t)
		draw_circle(mloc, radius, Color(0.0, 0.0, 0.0, alpha))

# ══════════════════════════════════════════════════════════
# ELEMENT ETKİLERİ  (boss barından gösterilir)
# ══════════════════════════════════════════════════════════
func apply_slow(amount: float, duration: float = 3.0, _source: String = "cryo", _anchor_pos: Vector2 = Vector2.ZERO) -> void:
	if is_slowed: return
	is_slowed = true; original_speed = speed; speed *= (1.0 - amount)
	_boss_set_element("slow")
	await get_tree().create_timer(duration, false).timeout
	if not is_instance_valid(self): return
	speed = original_speed; is_slowed = false; _boss_clear_element()

func apply_frozen() -> void:
	is_frozen = true
	_boss_set_element("frozen")
	await get_tree().create_timer(3.0, false).timeout
	if not is_instance_valid(self): return
	is_frozen = false; _boss_clear_element()

func apply_wet() -> void:
	is_wet = true
	_boss_set_element("wet")
	await get_tree().create_timer(5.0, false).timeout
	if not is_instance_valid(self): return
	is_wet = false; _boss_clear_element()

func apply_glitch(_duration: float = 2.0) -> void:
	if is_glitched: return
	is_glitched = true
	_boss_set_element("glitch")
	await get_tree().create_timer(3.0, false).timeout
	if not is_instance_valid(self): return
	is_glitched = false; _boss_clear_element()

func apply_electrified() -> void:
	if is_electrified: return
	is_electrified = true
	_boss_set_element("electrified")
	await get_tree().create_timer(5.0, false).timeout
	if is_instance_valid(self):
		is_electrified = false; _boss_clear_element()

func apply_burn() -> void:
	if is_burning: return
	is_burning = true
	_boss_set_element("burn")
	for i in range(3):
		await get_tree().create_timer(1.0, false).timeout
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

func _attach_shadow() -> void:
	preload("res://blob_shadow.gd").attach(self, _sprite)

# Zorluk: boss can (ve varsa zırh) çarpanı
func _apply_difficulty_hp() -> void:
	var m: float = GameData.diff("boss_hp")
	if m == 1.0: return
	health = maxi(1, int(round(float(health) * m)))
	max_health = maxi(1, int(round(float(max_health) * m)))
	if get("armor") != null:
		set("armor", maxi(0, int(round(float(get("armor")) * m))))
		set("max_armor", maxi(1, int(round(float(get("max_armor")) * m))))
