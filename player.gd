extends CharacterBody2D

var SPEED = 150.0
var aim_direction = Vector2(0, -1)
var chain_anchor = Vector2(1240, 1040)
var chain_length = 355.0
var invincible = false
var ball_mastery = 0
var pierce_bonus = 0
var electric_bonus = 0
var split_bonus = 0
var has_mimic = false
var dash_charges = 1
var max_dash_charges = 1
var dash_recharge_time = 0.8
var dash_empty_recharge_time = 0.8
var dash_recharge_timer = 0.0
var dash_is_empty = false
var dash_distance = 120.0
var is_dashing = false
var dash_velocity = Vector2.ZERO
var dash_duration = 0.12
var dash_timer = 0.0

# ── RTS / Tactical Mode ───────────────────────────────────────────────────────
var rts_mode: bool = false
const RTS_FIRE_INTERVAL := 0.30
var _rts_fire_timer: float = 0.0

# ── Auto Mode ─────────────────────────────────────────────────────────────────
var auto_mode: bool = false
var _firing_all: bool = false

# ── Orbit sistemi ─────────────────────────────────────────────────────────────
var orbit_balls: Array  = []
const MAX_ORBIT: int    = 8
const ORBIT_RADIUS: float = 65.0
const ORBIT_SPEED: float  = 2.2   # rad/s
var orbit_angle: float  = 0.0
var fire_index: int     = 0

# Legacy — bazı upgrade kodları hâlâ bunları okuyabilir
var held_balls: Array   = []
var held_ball           = null
var catch_mode: bool    = false
var has_next_one: bool  = false

# Vector animation
var _anim_dir: String = "N"
var _vector_oneshot: bool = false

# ── Vector Armor & Stack sistemi ─────────────────────────────────────────────
var has_armor_core: bool = false
var armor_gain_per_hit: int = 1
var has_pain_converter: bool = false

var has_momentum_engine: bool = false
var momentum_stacks: int = 0
var momentum_max: int = 20
var momentum_speed_bonus: float = 0.03  # Lv1:%3  Lv2:%5  Lv3:%7
const MOMENTUM_MAX: int = 20            # geriye uyumluluk alias

var has_impact_feedback: bool = false
var impact_hit_count: int = 0
var impact_stacks: int = 0
var impact_feedback_threshold: int = 10  # Lv1:10  Lv2:7  Lv3:5
const IMPACT_STACK_MAX: int = 10

var has_chain_density: bool = false
var chain_density_bonus_per_hit: int = 1  # Lv1:1  Lv2:2  Lv3:3
var has_last_stand: bool = false
var last_stand_hp_mult: float = 0.005     # Lv1:0.5%  Lv2:0.8%  Lv3:1.2%
var last_stand_armor_mult: float = 0.0    # Lv3'te devreye girer
var has_adrenal_surge: bool = false

# ── Yeni Individuality kart değişkenleri ──────────────────────────────────────
var orbit_speed_mult: float       = 1.0   # Reinforced Frame, Overclocked Reflex, vb.
var armor_gain_mult: float        = 1.0   # Iron Constitution, Overclocked Reflex, vb.
var momentum_gain_mult: float     = 1.0   # Fortified Core System
var damage_mult: float            = 1.0   # Fractured Frame
var knockback_force_mult: float   = 1.0   # Magnetic Weight
var slow_duration_mult: float     = 1.0   # Battlefield Anchor
var return_speed_mult: float      = 1.0   # Hyper Recovery Loop
var hyper_loop_no_damage: bool    = false # Hyper Recovery Loop: hasar = 0
var has_blood_circuit: bool       = false
var has_glass_engine: bool        = false
var has_adrenal_armor: bool       = false # Adrenal Armor System
var has_kinetic_nervous: bool     = false # Momentum reset olmaz
var has_risk_engine: bool         = false # Hasar alınca momentum

# ── Pranga sistemi ────────────────────────────────────────────────────────────
var _chain_links: Array[Sprite2D] = []
const _CHAIN_DIR_NAMES: Array[String] = ["east","south-east","south","south-west","west","north-west","north","north-east"]
const _LINK_SPACING: float = 14.0
const _MAX_LINKS: int = 21
var _link_textures: Dictionary = {}
# Catenary simülasyonu — her halkanın fizik pozisyonu
var _chain_positions: Array[Vector2] = []
const _CHAIN_GRAVITY: float = 0.0
const _CHAIN_DAMPING: float = 8.0
const _CHAIN_TENSION: float = 120.0
var _chain_velocities: Array[Vector2] = []
var _vector_dead: bool = false
var _lmb_was_pressed: bool = false  # melee sadece tıklama anında tetiklensin

# Leila animation
var _leila_anim_dir: String = "S"
var _leila_oneshot: bool = false

# Cyclone animation
var _cyclone_anim_dir: String = "S"
const LEILA_RUN_SPEED: float = 200.0  # Bu hızın üstünde run animasyonu oynar

# Dash trail
const DASH_TRAIL_COLOR       := Color(0.0, 0.82, 1.0, 0.9)  # Vector — neon cyan
const DASH_TRAIL_COLOR_LEILA := Color(1.0, 0.08, 0.58, 0.9)  # Leila — neon pink
const DASH_TRAIL_INTERVAL    := 0.02
var   _dash_trail_timer: float = 0.0

# Karakter tipi
var character_type = "vector"

# ── Orbit API ────────────────────────────────────────────────────────────────
func add_to_orbit(ball: Node2D) -> void:
	if ball in orbit_balls: return
	if orbit_balls.size() >= MAX_ORBIT: return
	orbit_balls.append(ball)
	ball.state         = "orbiting"
	ball.moving        = false
	ball.scale         = Vector2(1.0, 1.0)
	ball.z_index       = 5
	ball.strike_offset = Vector2.ZERO
	ball._is_striking  = false
	ball.get_node("CollisionShape2D").disabled = true
	ball._reset_defense_life()
	# Auto mode: orbit'e giren top hemen fırlatılır
	if auto_mode:
		_fire_ball()

func remove_from_orbit(ball: Node2D) -> void:
	orbit_balls.erase(ball)
	if fire_index >= orbit_balls.size() and orbit_balls.size() > 0:
		fire_index = 0

func _rts_fire_at_nearest() -> void:
	if orbit_balls.is_empty(): return
	var subjects := get_tree().get_nodes_in_group("subjects")
	var nearest: Node2D = null
	var nearest_dist := INF
	for s in subjects:
		if not is_instance_valid(s): continue
		var d := global_position.distance_to(s.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = s
	if nearest == null: return
	aim_direction = (nearest.global_position - global_position).normalized()
	_fire_ball()

func _fire_ball() -> void:
	if orbit_balls.is_empty(): return
	fire_index = fire_index % orbit_balls.size()
	var ball = orbit_balls[fire_index]
	orbit_balls.remove_at(fire_index)
	if fire_index >= orbit_balls.size():
		fire_index = 0

	# Tık anındaki yönü yakala (await sırasında mouse kaymasın)
	var captured_aim: Vector2 = aim_direction

	# Orbit'ten çıkar — collision kapat, state durdur
	ball.state         = "flying"
	ball.moving        = false
	ball.strike_offset = Vector2.ZERO
	ball._is_striking  = false
	ball.get_node("CollisionShape2D").disabled = true

	# Hızla merkeze çek
	var snap: Tween = ball.create_tween()
	snap.tween_property(ball, "global_position", global_position, 0.07)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await snap.finished

	if not is_instance_valid(ball):
		return

	# Merkezden fırlat (collision kapalı — player'dan uzaklaşsın)
	ball.move_direction = captured_aim.normalized()
	ball.speed          = 700.0
	ball.moving         = true
	ball.state          = "flying"
	ball.catch_cooldown = 0.5
	ball.scale          = Vector2(1.0, 1.0)
	ball.z_index        = 5

	# ~0.09s sonra collision aç (70 px uzakta olur)
	await get_tree().create_timer(0.09).timeout
	if is_instance_valid(ball):
		ball.get_node("CollisionShape2D").disabled = false

func _fire_all_balls() -> void:
	if orbit_balls.is_empty() or _firing_all: return
	_firing_all = true
	var count := orbit_balls.size()
	for i in count:
		if orbit_balls.is_empty(): break
		_fire_ball()
		await get_tree().create_timer(0.12).timeout
	_firing_all = false

# Legacy uyumluluk
func catch_ball(_ball: Node2D) -> void:
	pass


func _ready() -> void:
	# _process'i AnimatedSprite2D'den (priority 0) SONRA çalıştır
	# Böylece aynı frame'de animasyon durduğu an is_playing() false görürüz
	process_priority = 1
	z_index = 2
	character_type = GameData.selected_character
	# Each character shows its own visual; others remain hidden in tscn
	match character_type:
		"vector":
			$VectorSprite.visible = true
			_setup_vector_sprite_new()
		"leila":
			$LeilaSprite.visible = true
			_setup_leila_sprite()
		"cyclone":
			$CycloneSprite.visible = true
			_setup_cyclone_sprite()
	_setup_pranga()

func _setup_pranga() -> void:
	for d in _CHAIN_DIR_NAMES:
		_link_textures[d] = load("res://assets/chain/chainLink/%s.png" % d)
	for i in range(_MAX_LINKS):
		var lnk := Sprite2D.new()
		lnk.visible = false
		lnk.z_index = 1
		lnk.scale = Vector2(0.50, 0.50)
		add_child(lnk)
		_chain_links.append(lnk)
		_chain_positions.append(Vector2.ZERO)
		_chain_velocities.append(Vector2.ZERO)

func _update_pranga(delta: float) -> void:
	queue_redraw()
	# Anchor ve player pozisyonları global koordinatlarda
	var anchor_g: Vector2 = chain_anchor
	var player_g: Vector2 = global_position + Vector2(0, 18)

	# Zincir uzunluğu — her halka arası mesafe
	var seg_len: float = _LINK_SPACING

	# Başlangıçta pozisyonları başlat (sıfırsa)
	if _chain_positions[0] == Vector2.ZERO:
		for i in range(_MAX_LINKS):
			var t: float = float(i) / float(_MAX_LINKS - 1)
			_chain_positions[i] = anchor_g.lerp(player_g, t)

	# Verlet entegrasyonu — yer çekimi yok, sadece atalet + sönümleme
	for i in range(1, _MAX_LINKS - 1):
		_chain_velocities[i] *= (1.0 - _CHAIN_DAMPING * delta)
		_chain_positions[i] += _chain_velocities[i] * delta

	# Kısıt: anchor sabit, player ucu player'a bağlı
	_chain_positions[0] = anchor_g
	_chain_positions[_MAX_LINKS - 1] = player_g

	# Kısıt iterasyonu — halka mesafelerini koru, hız güncelle
	for _iter in range(12):
		for i in range(_MAX_LINKS - 1):
			var diff: Vector2 = _chain_positions[i + 1] - _chain_positions[i]
			var d: float = diff.length()
			if d > 0.001:
				var correction: Vector2 = diff * ((d - seg_len) / d) * 0.5
				if i > 0:
					_chain_positions[i] += correction
					_chain_velocities[i] += correction / delta * 0.05
				if i + 1 < _MAX_LINKS - 1:
					_chain_positions[i + 1] -= correction
					_chain_velocities[i + 1] -= correction / delta * 0.05
		_chain_positions[0] = anchor_g
		_chain_positions[_MAX_LINKS - 1] = player_g

	# Sprite'ları pozisyonlara yerleştir
	for i in range(_MAX_LINKS):
		var pos_local: Vector2 = to_local(_chain_positions[i])
		# Yön hesapla
		var dir_vec: Vector2 = Vector2.DOWN
		if i < _MAX_LINKS - 1:
			dir_vec = (_chain_positions[i + 1] - _chain_positions[i]).normalized()
		elif i > 0:
			dir_vec = (_chain_positions[i] - _chain_positions[i - 1]).normalized()
		var dir_name: String = _angle_to_chain_dir(dir_vec.angle())
		_chain_links[i].visible = true
		_chain_links[i].global_position = _chain_positions[i]
		_chain_links[i].texture = _link_textures[dir_name]

func _angle_to_chain_dir(angle: float) -> String:
	var deg: float = fmod(rad_to_deg(angle) + 360.0, 360.0)
	var sector: int = int((deg + 22.5) / 45.0) % 8
	return _CHAIN_DIR_NAMES[sector]

func _process(_delta: float) -> void:
	if character_type != "vector" or _vector_dead:
		return
	var sprite: AnimatedSprite2D = $VectorSprite
	# Güvenlik: sprite hiçbir zaman görünmez kalmasın
	if not sprite.visible:
		sprite.visible = true
	# AnimatedSprite2D (priority 0) bu frame'de durmuşsa, biz (priority 1) hemen yakalayız
	if not sprite.is_playing():
		if _vector_oneshot:
			_vector_oneshot = false
		var moving = velocity != Vector2.ZERO
		var anim = _resolve_anim(("run" if moving else "idle"), _anim_dir)
		sprite.scale = _get_vector_scale(anim)
		sprite.play(anim)
		# Frame'i anında 0'a ayarla — play() iç gecikmesi olmadan
		sprite.set_frame_and_progress(0, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if auto_mode:
			return  # auto mode'da tık devre dışı
		_fire_all_balls()

	# Sağ tık → dash
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if dash_charges > 0:
			_dash()

func _dash() -> void:
	var dash_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): dash_dir.y -= 1
	if Input.is_key_pressed(KEY_S): dash_dir.y += 1
	if Input.is_key_pressed(KEY_A): dash_dir.x -= 1
	if Input.is_key_pressed(KEY_D): dash_dir.x += 1

	if dash_dir == Vector2.ZERO:
		return

	is_dashing = true
	$CollisionShape2D.disabled = true
	dash_velocity = dash_dir.normalized() * (dash_distance / dash_duration)
	dash_timer = dash_duration
	dash_charges -= 1
	dash_recharge_timer = 0.0
	if dash_charges <= 0:
		dash_is_empty = true

func _physics_process(delta: float) -> void:
	# RTS modu — en yakın düşmana otomatik ateş
	if rts_mode and not orbit_balls.is_empty():
		_rts_fire_timer -= delta
		if _rts_fire_timer <= 0.0:
			_rts_fire_timer = RTS_FIRE_INTERVAL
			_rts_fire_at_nearest()

	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): direction.y = -1
	if Input.is_key_pressed(KEY_S): direction.y = 1
	if Input.is_key_pressed(KEY_A): direction.x = -1
	if Input.is_key_pressed(KEY_D): direction.x = 1

	velocity = direction.normalized() * SPEED
	move_and_slide()

	# Dash hareketi
	if is_dashing:
		dash_timer -= delta
		global_position += dash_velocity * delta
		# Dash trail — ghost spawn
		if character_type == "vector" or character_type == "leila":
			_dash_trail_timer -= delta
			if _dash_trail_timer <= 0.0:
				_dash_trail_timer = DASH_TRAIL_INTERVAL
				_spawn_dash_ghost()
		if dash_timer <= 0:
			is_dashing = false
			dash_velocity = Vector2.ZERO
			_dash_trail_timer = 0.0
			$CollisionShape2D.disabled = false

	# Wall boundaries
	global_position.x = clamp(global_position.x, 910, 1580)
	global_position.y = clamp(global_position.y, 330, 1035)

	# Chain constraint check

	aim_direction = (get_global_mouse_position() - global_position).normalized()

	var dist_to_anchor = global_position.distance_to(chain_anchor)
	if dist_to_anchor > chain_length:
		var dir_to_anchor = (chain_anchor - global_position).normalized()
		global_position = chain_anchor - dir_to_anchor * chain_length

	_update_pranga(delta)

	# ── Orbit pozisyonlama ────────────────────────────────────────────────────
	var _effective_orbit_speed: float = ORBIT_SPEED * orbit_speed_mult
	var game_node := get_tree().get_first_node_in_group("game")
	if has_momentum_engine and momentum_stacks > 0:
		# Last Stand: eksik HP başına ekstra bonus
		var last_stand_bonus: float = 0.0
		if has_last_stand and game_node:
			last_stand_bonus = float(game_node.player_max_hp - game_node.player_hp) * last_stand_hp_mult
		# Adrenal Surge: HP %30 altında Momentum x2
		var stack_mult: float = 1.0
		if has_adrenal_surge and game_node and float(game_node.player_hp) / float(max(game_node.player_max_hp, 1)) < 0.3:
			stack_mult = 2.0
		_effective_orbit_speed = ORBIT_SPEED * orbit_speed_mult * (1.0 + float(momentum_stacks) * momentum_speed_bonus * stack_mult + last_stand_bonus)
	# Blood Circuit: HP <= %70 iken hız artar (max +%50 at 0 HP)
	if has_blood_circuit and game_node:
		var hp_ratio: float = float(game_node.player_hp) / float(max(game_node.player_max_hp, 1))
		if hp_ratio <= 0.7:
			_effective_orbit_speed *= 1.0 + (0.7 - hp_ratio) / 0.7 * 0.5
	# Adrenal Armor System: HP > %70 → Core Speed +%10
	if has_adrenal_armor and game_node:
		var hp_r: float = float(game_node.player_hp) / float(max(game_node.player_max_hp, 1))
		if hp_r > 0.7:
			_effective_orbit_speed *= 1.1
	orbit_angle += _effective_orbit_speed * delta
	var n := orbit_balls.size()
	for i in range(n - 1, -1, -1):
		if not is_instance_valid(orbit_balls[i]):
			orbit_balls.remove_at(i)
			continue
		var angle: float = orbit_angle + (TAU / max(n, 1)) * i
		orbit_balls[i].global_position = global_position + Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS + orbit_balls[i].strike_offset

	# ── Animasyon yön güncellemeleri ──────────────────────────────────────────
	if character_type == "vector":
		_update_anim_dir()
	elif character_type == "leila":
		_update_leila_anim_dir()
	elif character_type == "cyclone":
		_update_cyclone_anim_dir()

	# ── Animasyon oynatma ─────────────────────────────────────────────────────
	if character_type == "vector":
		_update_vector_animation()
	elif character_type == "leila":
		_update_leila_animation()
	elif character_type == "cyclone":
		_update_cyclone_animation()

	queue_redraw()

	# Dash charge recharge
	if dash_charges < max_dash_charges:
		dash_recharge_timer += delta
		var recharge = dash_empty_recharge_time if dash_is_empty else dash_recharge_time
		if dash_recharge_timer >= recharge:
			dash_recharge_timer = 0.0
			dash_charges += 1
			if dash_charges >= max_dash_charges:
				dash_is_empty = false




func _setup_cyclone_sprite() -> void:
	var sprite: AnimatedSprite2D = $CycloneSprite  # tscn'de ColorRect yerine eklendi
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base  := "res://assets/characters/cyclone/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]

	var anims := [
		["idle", 8,  8.0,  true],
		["run",  6, 10.0, true],
	]

	for a in anims:
		var anim_key: String  = str(a[0])
		var frame_count: int  = int(a[1])
		var fps: float        = float(a[2])
		var looping: bool     = bool(a[3])
		for d in dirs:
			var key: String = anim_key + "_" + d
			var tex: Texture2D = load(base + "cyclone_" + anim_key + "_" + d + ".png")
			frames.add_animation(key)
			frames.set_animation_speed(key, fps)
			frames.set_animation_loop(key, looping)
			for i in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas  = tex
				atlas.region = Rect2(i * 224, 0, 224, 224)
				frames.add_frame(key, atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.58, 0.58)
	sprite.play("idle_S")


func _setup_vector_sprite_new() -> void:
	var sprite: AnimatedSprite2D = $VectorSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base  := "res://assets/characters/vector/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]

	var anims := [
		["idle", 4,  8.0,  true],
		["run",  6, 10.0, true],
	]

	for a in anims:
		var anim_key: String  = str(a[0])
		var frame_count: int  = int(a[1])
		var fps: float        = float(a[2])
		var looping: bool     = bool(a[3])
		for d in dirs:
			var key: String = anim_key + "_" + d
			var tex: Texture2D = load(base + "vector_" + anim_key + "_" + d + ".png")
			frames.add_animation(key)
			frames.set_animation_speed(key, fps)
			frames.set_animation_loop(key, looping)
			for i in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas  = tex
				atlas.region = Rect2(i * 208, 0, 208, 208)
				frames.add_frame(key, atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.60, 0.60)
	sprite.animation_finished.connect(_on_vector_anim_finished)
	sprite.play("idle_S")


func _setup_leila_sprite() -> void:
	var sprite: AnimatedSprite2D = $LeilaSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base := "res://assets/characters/leila/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]

	# [key, frame_count, fps, loop]
	var anims := [
		["idle",        4,  8.0,  true],
		["walk",        6,  10.0, true],
		["run",         6,  13.0, true],
		["punch",       6,  14.0, false],
		["throw",       7,  14.0, false],
		["take_damage", 6,  12.0, false],
	]

	for a in anims:
		var anim_key: String  = str(a[0])
		var frame_count: int  = int(a[1])
		var fps: float        = float(a[2])
		var looping: bool     = bool(a[3])
		for d in dirs:
			var dd: String = str(d)
			var key: String = anim_key + "_" + dd
			var tex: Texture2D = load(base + "leila_" + anim_key + "_" + dd + ".png")
			frames.add_animation(key)
			frames.set_animation_speed(key, fps)
			frames.set_animation_loop(key, looping)
			for i in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas  = tex
				atlas.region = Rect2(i * 224, 0, 224, 224)
				frames.add_frame(key, atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.58, 0.58)
	sprite.animation_finished.connect(_on_leila_anim_finished)
	sprite.play("idle_S")

func _update_leila_anim_dir() -> void:
	# Hareket varsa yöne göre, yoksa mouse yönüne göre
	var deg: float
	if velocity != Vector2.ZERO:
		deg = rad_to_deg(velocity.angle())
	else:
		deg = rad_to_deg(aim_direction.angle())
	if   deg > -22.5  and deg <= 22.5:   _leila_anim_dir = "E"
	elif deg > 22.5   and deg <= 67.5:   _leila_anim_dir = "SE"
	elif deg > 67.5   and deg <= 112.5:  _leila_anim_dir = "S"
	elif deg > 112.5  and deg <= 157.5:  _leila_anim_dir = "SW"
	elif deg > 157.5  or  deg <= -157.5: _leila_anim_dir = "W"
	elif deg > -157.5 and deg <= -112.5: _leila_anim_dir = "NW"
	elif deg > -112.5 and deg <= -67.5:  _leila_anim_dir = "N"
	elif deg > -67.5  and deg <= -22.5:  _leila_anim_dir = "NE"

func _update_leila_animation() -> void:
	if _leila_oneshot:
		return
	var sprite: AnimatedSprite2D = $LeilaSprite
	var anim: String
	if velocity != Vector2.ZERO:
		anim = ("run_" if SPEED >= LEILA_RUN_SPEED else "walk_") + _leila_anim_dir
	else:
		anim = "idle_" + _leila_anim_dir
	if sprite.animation != anim:
		sprite.play(anim)

func _update_cyclone_anim_dir() -> void:
	var deg: float
	if velocity != Vector2.ZERO:
		deg = rad_to_deg(velocity.angle())
	else:
		deg = rad_to_deg(aim_direction.angle())
	if   deg > -22.5  and deg <= 22.5:   _cyclone_anim_dir = "E"
	elif deg > 22.5   and deg <= 67.5:   _cyclone_anim_dir = "SE"
	elif deg > 67.5   and deg <= 112.5:  _cyclone_anim_dir = "S"
	elif deg > 112.5  and deg <= 157.5:  _cyclone_anim_dir = "SW"
	elif deg > 157.5  or  deg <= -157.5: _cyclone_anim_dir = "W"
	elif deg > -157.5 and deg <= -112.5: _cyclone_anim_dir = "NW"
	elif deg > -112.5 and deg <= -67.5:  _cyclone_anim_dir = "N"
	elif deg > -67.5  and deg <= -22.5:  _cyclone_anim_dir = "NE"

func _update_cyclone_animation() -> void:
	var sprite: AnimatedSprite2D = $CycloneSprite
	var anim: String = ("run_" if velocity != Vector2.ZERO else "idle_") + _cyclone_anim_dir
	if sprite.animation != anim:
		sprite.play(anim)

func _play_leila_oneshot(anim_name: String) -> void:
	_leila_oneshot = true
	var sprite: AnimatedSprite2D = $LeilaSprite
	# Atış ve vurma animasyonları mouse yönünde
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _on_leila_anim_finished() -> void:
	_leila_oneshot = false

func _update_anim_dir() -> void:
	var w = Input.is_key_pressed(KEY_W)
	var s = Input.is_key_pressed(KEY_S)
	var a = Input.is_key_pressed(KEY_A)
	var d = Input.is_key_pressed(KEY_D)
	if   w and d: _anim_dir = "NE"
	elif w and a: _anim_dir = "NW"
	elif s and d: _anim_dir = "SE"
	elif s and a: _anim_dir = "SW"
	elif w:       _anim_dir = "N"
	elif s:       _anim_dir = "S"
	elif d:       _anim_dir = "E"
	elif a:       _anim_dir = "W"
	# tuş basılı değilse mevcut yön korunur


func _get_vector_scale(anim_name: String) -> Vector2:
	# Piksel art modu: küçük scale + NEAREST filter → blursuz keskin pikseller
	# Oranlar korunuyor, sadece baz değer 0.60 → 0.18'e düşürüldü
	var s: float
	if   "melee_kick"  in anim_name: s = 0.46
	elif "throw_ball"  in anim_name: s = 0.51
	elif "take_damage" in anim_name: s = 0.53
	elif "death"       in anim_name: s = 0.55
	elif "idle"        in anim_name: s = 0.54
	else:                             s = 0.60  # run
	return Vector2(s, s)


# Animasyon adı + yön → mevcut spritesheet yoksa en yakın yöne düşer
# idle/run: 8 yön tam mevcut
# throw_ball / take_damage: sadece N, NE, NW → E/SE/S/SW/W → N'e eşlenir
func _resolve_anim(base: String, dir: String) -> String:
	var full = base + "_" + dir
	if $VectorSprite.sprite_frames.has_animation(full):
		return full
	# Fallback tablosu: mevcut olmayan yönü en yakın mevcut yöne eşle
	var fallback := {"E": "NE", "SE": "NE", "S": "N", "SW": "NW", "W": "NW"}
	var fb_dir: String = fallback.get(dir, "N")
	return base + "_" + fb_dir


func _update_vector_animation() -> void:
	if _vector_dead or _vector_oneshot:
		return
	var moving = velocity != Vector2.ZERO
	var anim = _resolve_anim(("run" if moving else "idle"), _anim_dir)
	if $VectorSprite.animation != anim:
		$VectorSprite.scale = _get_vector_scale(anim)
		$VectorSprite.play(anim)


func _play_vector_oneshot(anim_name: String) -> void:
	if _vector_dead:
		return
	if not $VectorSprite.sprite_frames.has_animation(anim_name):
		return
	_vector_oneshot = true
	$VectorSprite.scale = _get_vector_scale(anim_name)
	$VectorSprite.play(anim_name)


func _on_vector_anim_finished() -> void:
	# Yalnızca bayrağı temizle.
	# Geçişi (idle/run oynatma) _process (priority 1) üstleniyor —
	# AnimatedSprite2D'nin kendi signal'inden play() çağırmak iç-state
	# çakışmasına yol açıyordu ve bir frame boşluk bırakıyordu.
	_vector_oneshot = false



func _spawn_dash_ghost() -> void:
	var sprite: AnimatedSprite2D
	var trail_color: Color
	if character_type == "leila":
		sprite      = $LeilaSprite
		trail_color = DASH_TRAIL_COLOR_LEILA
	else:
		sprite      = $VectorSprite
		trail_color = DASH_TRAIL_COLOR
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation(sprite.animation):
		return
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not tex:
		return
	var ghost := Sprite2D.new()
	ghost.texture         = tex
	ghost.global_position = sprite.global_position
	ghost.scale           = sprite.global_scale
	ghost.z_index         = 1
	ghost.z_as_relative   = false
	ghost.modulate        = trail_color
	get_parent().add_child(ghost)
	var tw: Tween = ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(ghost.queue_free)


func play_death() -> void:
	if character_type != "vector":
		return
	_vector_dead = true
	_vector_oneshot = true
	$VectorSprite.play("death")


func _no_ball_nearby() -> bool:
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		if ball.moving and global_position.distance_to(ball.global_position) < 100:
			return false
	return true


func take_damage(amount) -> void:
	if invincible:
		return
	invincible = true
	if character_type == "vector" and not _vector_dead:
		_play_vector_oneshot(_resolve_anim("take_damage", _anim_dir))
	elif character_type == "leila":
		_play_leila_oneshot("take_damage_" + _leila_anim_dir)
	var game = get_parent()
	if game.has_method("player_damaged"):
		game.player_damaged(amount)
	await get_tree().create_timer(0.3).timeout
	invincible = false

func _draw() -> void:
	# Karakter gölgesi — tüm karakterler için ayakların altında oval
	var shadow_pts := PackedVector2Array()
	var s_rx: float = 18.0; var s_ry: float = 7.0
	var s_cy: float = 20.0  # ayak seviyesi
	for i in range(32):
		var a: float = (float(i) / 32.0) * TAU
		shadow_pts.append(Vector2(cos(a) * s_rx, s_cy + sin(a) * s_ry))
	draw_colored_polygon(shadow_pts, Color(0.0, 0.0, 0.0, 0.38))

	# ── Zincir elektrik efekti ───────────────────────────────────────────────
	if _chain_positions.size() >= 2:
		var t := Time.get_ticks_msec() * 0.001
		for i in range(_chain_positions.size() - 1):
			var a := to_local(_chain_positions[i])
			var b := to_local(_chain_positions[i + 1])
			var gap := a.distance_to(b)
			if gap < 6.0:
				continue
			var intensity: float = clamp((gap - 6.0) / 18.0, 0.0, 1.0)
			var mid: Vector2 = (a + b) * 0.5
			var perp: Vector2 = (b - a).normalized().rotated(PI * 0.5)
			# Ark sapması — zaman + halka indeksine göre titreşir
			var wobble: float = sin(t * 9.0 + float(i) * 1.3) * gap * 0.22 * intensity
			var ctrl: Vector2 = mid + perp * wobble
			# Dış sarı ark (parlak)
			draw_line(a, ctrl, Color(1.0, 0.9, 0.1, 0.55 * intensity), 1.8)
			draw_line(ctrl, b,  Color(1.0, 0.9, 0.1, 0.55 * intensity), 1.8)
			# İç mavi-beyaz ark (sıcak merkez)
			draw_line(a, ctrl, Color(0.6, 0.9, 1.0, 0.85 * intensity), 0.8)
			draw_line(ctrl, b,  Color(0.6, 0.9, 1.0, 0.85 * intensity), 0.8)

	# Orbit halkası — soluk gösterge
	if orbit_balls.size() > 0:
		draw_arc(Vector2.ZERO, ORBIT_RADIUS, 0, TAU, 64, Color(0.0, 0.9, 1.0, 0.08), 1.5)

	# Nişan çizgisi — sol tık basılıyken
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not orbit_balls.is_empty():
		var drawn := 0.0
		var draw_dash := true
		while drawn < 150.0:
			var seg := 10.0 if draw_dash else 6.0
			seg = min(seg, 150.0 - drawn)
			if draw_dash:
				draw_line(aim_direction * drawn, aim_direction * (drawn + seg), Color(0, 0.9, 1.0, 0.7), 2.0)
			drawn += seg
			draw_dash = not draw_dash
