extends CharacterBody2D

var SPEED = 150.0
var held_ball = null
var aim_direction = Vector2(0, -1)
var charge = 0.0
var max_charge = 1.0
var is_charging = false
var catch_mode = false
var chain_anchor = Vector2(1240, 1040)
var chain_length = 355.0
var invincible = false
var max_held_balls = 1
var held_balls = []
var active_ball_index = 0
var has_next_one = false
var ball_mastery = 0
var pierce_bonus = 0
var electric_bonus = 0
var split_bonus = 0
var bat_cooldown = 0.0
var bat_damage = 3
var bat_range = 150.0
var has_mimic = false
var dash_charges = 1
var max_dash_charges = 1
var dash_recharge_time = 1.0
var dash_empty_recharge_time = 1.5
var dash_recharge_timer = 0.0
var dash_is_empty = false
var dash_distance = 120.0
var is_dashing = false
var dash_velocity = Vector2.ZERO
var dash_duration = 0.12
var dash_timer = 0.0
var recently_launched = []
var leila_hold_timer = 0.0
var leila_is_holding = false
var cyclone_hold_timer = 0.0
var cyclone_is_holding = false
var cyclone_ground_ball = null

# For Vector
var auto_catch_timer = 0.0
var auto_catch_ball = null

# Vector animation
var _anim_dir: String = "N"
var _vector_oneshot: bool = false
var _vector_dead: bool = false
var _lmb_was_pressed: bool = false  # melee sadece tıklama anında tetiklensin

# Dash trail
const DASH_TRAIL_COLOR    := Color(0.0, 0.82, 1.0, 0.9)  # neon cyan — buradan değiştirebilirsin
const DASH_TRAIL_INTERVAL := 0.02                          # her 20ms'de bir ghost
var   _dash_trail_timer: float = 0.0

# Karakter tipi
var character_type = "vector"

func _cyclone_process(delta: float) -> void:
	# Detect ground ball when approaching
	var ground_ball = _find_ground_ball()
	cyclone_ground_ball = ground_ball

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not cyclone_is_holding:
			cyclone_hold_timer += delta
			if cyclone_hold_timer >= 0.15:
				cyclone_is_holding = true

		if cyclone_is_holding:
			if held_ball == null:
				if cyclone_ground_ball != null:
					# Yerdeki top
					cyclone_ground_ball.scale = Vector2(1.0, 1.0)
					cyclone_ground_ball.z_index = 2
					held_ball = cyclone_ground_ball
					held_balls.append(cyclone_ground_ball)
					charge = 0.0
				else:
					# Havadaki top
					var balls = get_tree().get_nodes_in_group("balls")
					for ball in balls:
						if ball.moving and global_position.distance_to(ball.global_position) < 100:
							ball.moving = false
							ball.get_node("CollisionShape2D").disabled = true
							held_ball = ball
							held_balls.append(ball)
							charge = 0.0
							break

			if held_ball != null:
				charge += delta
				var hold_time = 0.3 if cyclone_ground_ball != null else 0.5
				if charge >= hold_time:
					_cyclone_throw()
	else:
		if cyclone_hold_timer > 0 and cyclone_hold_timer < 0.15:
			# Short tap - normal hit
			if _no_ball_nearby():
				_bat_swing()
			else:
				_swing()
		elif cyclone_is_holding and held_ball != null:
			_cyclone_throw()
		cyclone_hold_timer = 0.0
		cyclone_is_holding = false

	if bat_cooldown > 0:
		bat_cooldown -= delta

func _find_ground_ball() -> Node2D:
	var balls = get_tree().get_nodes_in_group("balls")
	var closest = null
	var closest_dist = INF
	for ball in balls:
		if not ball.moving and held_ball != ball:
			var dist = global_position.distance_to(ball.global_position)
			if dist < 80 and dist < closest_dist:
				closest_dist = dist
				closest = ball
	return closest

func _cyclone_throw() -> void:
	if held_ball == null:
		return
	held_ball.get_node("CollisionShape2D").disabled = false
	held_ball.catch_cooldown = 1.0
	held_ball.scale = Vector2(1.0, 1.0)
	held_ball.launch_with_speed(aim_direction, 800.0)
	held_ball.hit_type = "great"
	held_balls.erase(held_ball)
	held_ball = null
	charge = 0.0
	cyclone_is_holding = false
	cyclone_hold_timer = 0.0

func _leila_process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not leila_is_holding:
			leila_hold_timer += delta
			if leila_hold_timer >= 0.15:
				leila_is_holding = true
		if leila_is_holding:
			# Racket mode - hold nearby ball
			if held_ball == null:
				var balls = get_tree().get_nodes_in_group("balls")
				for ball in balls:
					if ball.moving and global_position.distance_to(ball.global_position) < 100:
						ball.moving = false
						ball.get_node("CollisionShape2D").disabled = true
						held_ball = ball
						held_balls.append(ball)
						charge = 0.0
						break
			# Auto-throw when hold timer expires
			if held_ball != null:
				charge += delta
				if charge >= 0.5:
					_leila_throw()
	else:
		if leila_hold_timer > 0 and leila_hold_timer < 0.15:
			# Short tap - normal hit
			if _no_ball_nearby():
				_bat_swing()
			else:
				_swing()
		elif leila_is_holding and held_ball != null:
			# Throw on release
			_leila_throw()
		leila_hold_timer = 0.0
		leila_is_holding = false

	if bat_cooldown > 0:
		bat_cooldown -= delta

func _leila_throw() -> void:
	if held_ball == null:
		return
	held_ball.get_node("CollisionShape2D").disabled = false
	held_ball.catch_cooldown = 1.0
	held_ball.launch_with_speed(aim_direction, 800.0)
	held_ball.hit_type = "great"
	held_balls.erase(held_ball)
	held_ball = null
	charge = 0.0
	leila_is_holding = false
	leila_hold_timer = 0.0

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
			_setup_vector_sprite()
		"leila":
			$LeilaRect.visible = true
		"cyclone":
			$CycloneRect.visible = true

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

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_E and event.pressed:
		if character_type != "vector":
			catch_mode = !catch_mode

	if character_type != "vector":
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and catch_mode:
			if event.pressed and held_ball != null:
				is_charging = true
			if not event.pressed and is_charging:
				is_charging = false
				_throw_ball()

	if event is InputEventKey and event.keycode == KEY_R and event.pressed:
		if has_next_one and held_balls.size() > 1:
			active_ball_index = (active_ball_index + 1) % held_balls.size()
			held_ball = held_balls[active_ball_index]

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
		if character_type == "vector":
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
	global_position.x = clamp(global_position.x, 870, 1620)
	global_position.y = clamp(global_position.y, 260, 1040)

	# Chain constraint check
	var dist_to_anchor = global_position.distance_to(chain_anchor)
	if dist_to_anchor > chain_length:
		var dir_to_anchor = (chain_anchor - global_position).normalized()
		global_position = chain_anchor - dir_to_anchor * chain_length

	aim_direction = (get_global_mouse_position() - global_position).normalized()

	if is_charging:
		charge = min(charge + delta * 1.5, max_charge)

	# Update animation direction for Vector (before _vector_process so it's current)
	if character_type == "vector":
		_update_anim_dir()

	# Hit system based on character type
	if character_type == "vector":
		_vector_process(delta)
	elif character_type == "leila":
		_leila_process(delta)
	elif character_type == "cyclone":
		_cyclone_process(delta)

	# Update Vector idle/run animation state
	if character_type == "vector":
		_update_vector_animation()

	for idx in range(held_balls.size()):
		held_balls[idx].global_position = global_position + Vector2(-20 + idx * 40, -40)
		if has_next_one and idx == active_ball_index:
			held_balls[idx].is_active = true
		else:
			held_balls[idx].is_active = false
		held_balls[idx].queue_redraw()

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

func _vector_process(delta: float) -> void:
	if auto_catch_ball == null:
		var balls = get_tree().get_nodes_in_group("balls")
		for ball in balls:
			if ball in recently_launched:
				continue
			if ball.moving and global_position.distance_to(ball.global_position) < 80:
				auto_catch_ball = ball
				ball.moving = false
				ball.get_node("CollisionShape2D").disabled = true
				ball.visible = false
				_play_vector_oneshot(_resolve_anim("throw_ball", _anim_dir))  # animasyon hemen başlar
				break

	# Topu animasyon boyunca player'a sabit tut (görünmez)
	if auto_catch_ball != null:
		auto_catch_ball.global_position = global_position + Vector2(0, -40)

	# Melee - punch with left click (sadece tıklama ANında tetikle, basılı tutunca değil)
	var lmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var lmb_just = lmb and not _lmb_was_pressed
	_lmb_was_pressed = lmb

	if lmb_just and bat_cooldown <= 0:
		bat_cooldown = 1.0
		_play_vector_oneshot(_resolve_anim("melee_kick", _anim_dir))
		var subjects = get_tree().get_nodes_in_group("subjects")
		for subject in subjects:
			var dist = global_position.distance_to(subject.global_position)
			if dist < bat_range:
				subject.take_damage(bat_damage)
				var push_dir = (subject.global_position - global_position).normalized()
				subject.global_position += push_dir * 40
				break

	if bat_cooldown > 0:
		bat_cooldown -= get_process_delta_time()

func _setup_vector_sprite() -> void:
	var sprite: AnimatedSprite2D = $VectorSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var FW := 256; var FH := 256
	var sbase := "res://assets/characters/Vector/sheets/"

	var MAX_COLS := 64  # GPU limiti: 64 × 256 = 16384px

	# [sheet_dosyası, fps, loop, frame_sayısı, animasyon_adı]
	var defs = [
		["idle_n",          30.0,  true,  49, "idle_N"],
		["idle_ne",         30.0,  true,  49, "idle_NE"],
		["idle_nw",         30.0,  true,  49, "idle_NW"],
		["run_n",           30.0,  true,  21, "run_N"],
		["run_ne",          30.0,  true,  21, "run_NE"],
		["run_e",           30.0,  true,  21, "run_E"],
		["run_se",          30.0,  true,  21, "run_SE"],
		["run_s",           30.0,  true,  21, "run_S"],
		["run_sw",          30.0,  true,  21, "run_SW"],
		["run_w",           30.0,  true,  21, "run_W"],
		["run_nw",          30.0,  true,  21, "run_NW"],
		["take_damage_n",   30.0,  false, 31, "take_damage_N"],
		["take_damage_ne",  30.0,  false, 31, "take_damage_NE"],
		["take_damage_nw",  30.0,  false, 31, "take_damage_NW"],
		["throw_ball_n",    85.0,  false, 85, "throw_ball_N"],
		["throw_ball_ne",   85.0,  false, 85, "throw_ball_NE"],
		["throw_ball_nw",   85.0,  false, 85, "throw_ball_NW"],
		["melee_kick_n",    98.0,  false, 49, "melee_kick_N"],
		["melee_kick_ne",   98.0,  false, 49, "melee_kick_NE"],
		["melee_kick_nw",   98.0,  false, 49, "melee_kick_NW"],
		["melee_kick_e",    98.0,  false, 45, "melee_kick_E"],
		["melee_kick_se",   98.0,  false, 45, "melee_kick_SE"],
		["melee_kick_s",    98.0,  false, 45, "melee_kick_S"],
		["melee_kick_sw",   98.0,  false, 45, "melee_kick_SW"],
		["melee_kick_w",    98.0,  false, 45, "melee_kick_W"],
		["death",           30.0,  false, 57, "death"],
	]

	for d in defs:
		var tex: Texture2D    = load(sbase + d[0] + ".png")
		var anim_name: String = d[4]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, d[1])
		frames.set_animation_loop(anim_name, d[2])
		for i in range(d[3]):
			var col          := i % MAX_COLS
			var row          := i / MAX_COLS
			var atlas        := AtlasTexture.new()
			atlas.atlas       = tex
			atlas.region      = Rect2(col * FW, row * FH, FW, FH)
			frames.add_frame(anim_name, atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale          = Vector2(0.6, 0.6)
	sprite.animation_finished.connect(_on_vector_anim_finished)
	sprite.play("idle_N")


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
	# Her animasyonun Blender render boyutu farklı — run (120px) referans alındı
	var s: float
	if   "melee_kick"  in anim_name: s = 0.46  # 158px → 0.4557
	elif "throw_ball"  in anim_name: s = 0.51  # 140px → 0.5143
	elif "take_damage" in anim_name: s = 0.53  # 135px → 0.5333
	elif "death"       in anim_name: s = 0.55  # 130px → 0.5539
	elif "idle"        in anim_name: s = 0.54  # 133px → 0.5414
	else:                             s = 0.60  # run 120px — referans
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


## Topun animasyonun kaçıncı yüzdesinde elden çıkacağı (0.0 - 1.0)
const THROW_RELEASE_RATIO: float = 0.50

func _play_vector_oneshot(anim_name: String) -> void:
	if _vector_dead:
		return
	_vector_oneshot = true
	$VectorSprite.scale = _get_vector_scale(anim_name)
	$VectorSprite.play(anim_name)

	# Throw animasyonunda topu %80'de bırak, kalan %20 toparlama fazı
	if "throw_ball" in anim_name and auto_catch_ball != null:
		var sf: SpriteFrames = $VectorSprite.sprite_frames
		var fps: float       = sf.get_animation_speed(anim_name)
		var frames: int      = sf.get_frame_count(anim_name)
		var release_t := (frames / fps) * THROW_RELEASE_RATIO
		get_tree().create_timer(release_t).timeout.connect(
			func():
				if auto_catch_ball != null:
					_release_throw_ball(),
			CONNECT_ONE_SHOT
		)


func _on_vector_anim_finished() -> void:
	# Yalnızca bayrağı temizle.
	# Geçişi (idle/run oynatma) _process (priority 1) üstleniyor —
	# AnimatedSprite2D'nin kendi signal'inden play() çağırmak iç-state
	# çakışmasına yol açıyordu ve bir frame boşluk bırakıyordu.
	_vector_oneshot = false


func _release_throw_ball() -> void:
	var ball = auto_catch_ball
	auto_catch_ball = null
	ball.visible = true
	ball.catch_cooldown = 1.0
	ball.launch_with_speed(aim_direction, 750.0)
	ball.hit_type = "perfect"
	recently_launched.append(ball)
	get_tree().create_timer(1.0).timeout.connect(
		func(): recently_launched.erase(ball), CONNECT_ONE_SHOT
	)


func _spawn_dash_ghost() -> void:
	var sprite: AnimatedSprite2D = $VectorSprite
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation(sprite.animation):
		return
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not tex:
		return
	var ghost := Sprite2D.new()
	ghost.texture        = tex
	ghost.global_position = sprite.global_position
	ghost.scale          = sprite.global_scale
	ghost.z_index        = 1          # karakterin (z=2) arkasında
	ghost.z_as_relative  = false
	ghost.modulate       = DASH_TRAIL_COLOR
	get_parent().add_child(ghost)
	# Kısa sürede solar ve yok olur
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

func _bat_swing() -> void:
	if bat_cooldown > 0:
		return
	bat_cooldown = 1.0
	var subjects = get_tree().get_nodes_in_group("subjects")
	for subject in subjects:
		var dist = global_position.distance_to(subject.global_position)
		if dist < bat_range:
			subject.take_damage(bat_damage)
			var push_dir = (subject.global_position - global_position).normalized()
			subject.global_position += push_dir * 40

func _swing() -> void:
	var balls = get_tree().get_nodes_in_group("balls")
	var closest_ball = null
	var closest_dist = INF

	for ball in balls:
		if not ball.moving:
			continue
		var dist = global_position.distance_to(ball.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_ball = ball

	if closest_ball == null:
		return

	var hit_type = ""
	if closest_dist < 50:
		closest_ball.launch_with_speed(aim_direction, 850.0)
		closest_ball.crit_chance = 0.4
		hit_type = "perfect"
	elif closest_dist < 100:
		closest_ball.launch_with_speed(aim_direction, 650.0)
		hit_type = "great"
	else:
		closest_ball.launch_with_speed(aim_direction, 400.0)
		hit_type = "miss"

	closest_ball.hit_type = hit_type

func catch_ball(ball: Node2D) -> void:
	if not catch_mode:
		return
	if held_balls.size() >= max_held_balls:
		return
	held_balls.append(ball)
	held_ball = ball
	ball.caught()
	charge = 0.0

func _throw_ball() -> void:
	if held_balls.is_empty():
		return
	var throw_speed = lerp(200.0, 700.0, charge)
	if has_next_one:
		var ball = held_balls[active_ball_index]
		held_balls.remove_at(active_ball_index)
		ball.is_active = false
		ball.queue_redraw()
		ball.launch_with_speed(aim_direction, throw_speed)
		if held_balls.is_empty():
			held_ball = null
			active_ball_index = 0
		else:
			active_ball_index = clamp(active_ball_index, 0, held_balls.size() - 1)
			held_ball = held_balls[active_ball_index]
	else:
		for ball in held_balls:
			ball.is_active = false
			ball.queue_redraw()
			ball.launch_with_speed(aim_direction, throw_speed)
		held_balls.clear()
		held_ball = null
		active_ball_index = 0
	charge = 0.0
	is_charging = false

func take_damage(amount) -> void:
	if invincible:
		return
	invincible = true
	if character_type == "vector" and not _vector_dead:
		_play_vector_oneshot(_resolve_anim("take_damage", _anim_dir))
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

	if character_type != "vector":
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or catch_mode:
			var dash_length = 10
			var gap_length = 6
			var total_length = 150
			var drawn = 0
			var draw_dash = true
			var line_color = Color(1, 1, 0, 0.8) if not catch_mode else Color(0, 1, 1, 0.8)
			while drawn < total_length:
				var segment = dash_length if draw_dash else gap_length
				segment = min(segment, total_length - drawn)
				if draw_dash:
					draw_line(
						aim_direction * drawn,
						aim_direction * (drawn + segment),
						line_color, 2.0
					)
				drawn += segment
				draw_dash = not draw_dash

	if is_charging:
		var bar_width = 40.0
		var bar_height = 6.0
		var offset = Vector2(-bar_width / 2, -45)
		draw_rect(Rect2(offset, Vector2(bar_width, bar_height)), Color(0.3, 0.3, 0.3))
		var fill_color = Color(0.2, 1.0, 0.2) if charge < 0.7 else Color(1.0, 0.3, 0.1)
		draw_rect(Rect2(offset, Vector2(bar_width * charge, bar_height)), fill_color)

	if catch_mode and character_type != "vector":
		draw_circle(Vector2(0, -35), 5, Color(0, 1, 1, 0.8))
