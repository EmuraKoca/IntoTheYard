extends CharacterBody2D

var SPEED = 300.0
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

# Leila yön takibi
var _leila_last_dir: String = "down"

# Leila raket referansları
var _racket: Sprite2D = null
var _racket_default_rot: float = 0.0
var _racket_swing_tween: Tween = null

func _cyclone_process(delta: float) -> void:
	# Yerdeki topa yaklaşınca işaret
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
			# Kısa tık - normal vuruş
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
			# Tek tık mı basılı tutma mı kontrol et
			leila_hold_timer += delta
			if leila_hold_timer >= 0.15:
				leila_is_holding = true
		if leila_is_holding:
			# Raket modu - yakın topu tut
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
			# Basılı tutma süresi dolunca otomatik fırlat
			if held_ball != null:
				charge += delta
				if charge >= 0.5:
					_leila_throw()
	else:
		if leila_hold_timer > 0 and leila_hold_timer < 0.15:
			# Kısa tık - normal vuruş
			if _no_ball_nearby():
				_bat_swing()
			else:
				_swing()
		elif leila_is_holding and held_ball != null:
			# Bırakınca fırlat
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
	_racket_swing()

# Vector için
var auto_catch_timer = 0.0
var auto_catch_ball = null

# Karakter tipi
var character_type = "vector"

func _ready() -> void:
	z_index = 2
	character_type = GameData.selected_character
	if character_type == "leila":
		# Vector placeholder'ı gizle, Leila animasyonunu aç
		$VectorRect.visible = false
		$AnimatedSprite2D.visible = true
		# Sprite büyütme ve piksel art filtresi
		$AnimatedSprite2D.scale         = Vector2(3.0, 3.0)
		$AnimatedSprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_setup_leila_frames()
		# Raket düğümünü etkinleştir
		_racket         = $AnimatedSprite2D.get_node("Racket") as Sprite2D
		_racket.visible = true
	elif character_type == "cyclone":
		# Vector placeholder'ı gizle, Cyclone animasyonunu aç
		$VectorRect.visible = false
		$AnimatedSprite2D.visible = true
	# Vector: VectorRect varsayılan olarak görünür kalır (tscn'de zaten açık)
	_play_anim("idle")

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
	
	if velocity != Vector2.ZERO:
		if SPEED >= 400:
			_play_anim("run")
		else:
			_play_anim("walk")
	else:
		_play_anim("idle")

	# Yalnızca Cyclone için: AnimatedSprite2D yatay çevirme
	# (Vector dikdörtgen kullanıyor, Leila yönlü sprite'lara sahip)
	if character_type == "cyclone":
		if velocity.x < 0:
			$AnimatedSprite2D.flip_h = true
		elif velocity.x > 0:
			$AnimatedSprite2D.flip_h = false
	
	# Dash hareketi
	if is_dashing:
		dash_timer -= delta
		global_position += dash_velocity * delta
		if dash_timer <= 0:
			is_dashing = false
			dash_velocity = Vector2.ZERO
			$CollisionShape2D.disabled = false

	# Duvar sınırları
	global_position.x = clamp(global_position.x, 870, 1620)
	global_position.y = clamp(global_position.y, 260, 1040)

	# Kelepçe kontrolü
	var dist_to_anchor = global_position.distance_to(chain_anchor)
	if dist_to_anchor > chain_length:
		var dir_to_anchor = (chain_anchor - global_position).normalized()
		global_position = chain_anchor - dir_to_anchor * chain_length
	
	aim_direction = (get_global_mouse_position() - global_position).normalized()
	
	if is_charging:
		charge = min(charge + delta * 1.5, max_charge)
	
	# Karakter tipine göre vuruş sistemi
	if character_type == "vector":
		_vector_process(delta)
	elif character_type == "leila":
		_leila_process(delta)
		_update_racket(delta)
	elif character_type == "cyclone":
		_cyclone_process(delta)
	
	for idx in range(held_balls.size()):
		held_balls[idx].global_position = global_position + Vector2(-20 + idx * 40, -40)
		if has_next_one and idx == active_ball_index:
			held_balls[idx].is_active = true
		else:
			held_balls[idx].is_active = false
		held_balls[idx].queue_redraw()
	
	queue_redraw()
	
	# Dash yük dolumu
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
				auto_catch_timer = 0.5
				break
	
	if auto_catch_ball != null:
		auto_catch_ball.global_position = global_position + Vector2(0, -40)
		auto_catch_timer -= delta
		if auto_catch_timer <= 0:
			var ball = auto_catch_ball
			auto_catch_ball = null
			ball.catch_cooldown = 1.0
			ball.launch_with_speed(aim_direction, 750.0)
			ball.hit_type = "perfect"
			recently_launched.append(ball)
			await get_tree().create_timer(1.0).timeout
			recently_launched.erase(ball)
			
	# Yakın dövüş - sol tık ile yumruk
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if bat_cooldown <= 0:
			var zombies = get_tree().get_nodes_in_group("zombies")
			for zombie in zombies:
				var dist = global_position.distance_to(zombie.global_position)
				if dist < bat_range:
					zombie.take_damage(bat_damage)
					var push_dir = (zombie.global_position - global_position).normalized()
					zombie.global_position += push_dir * 40
					bat_cooldown = 1.0
					break

	if bat_cooldown > 0:
		bat_cooldown -= get_process_delta_time()

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
	var zombies = get_tree().get_nodes_in_group("zombies")
	for zombie in zombies:
		var dist = global_position.distance_to(zombie.global_position)
		if dist < bat_range:
			zombie.take_damage(bat_damage)
			var push_dir = (zombie.global_position - global_position).normalized()
			zombie.global_position += push_dir * 40
	if character_type == "leila":
		_racket_swing()

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
	if character_type == "leila":
		_racket_swing()

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
	_play_anim("hurt")
	var game = get_parent()
	if game.has_method("player_damaged"):
		game.player_damaged(amount)
	await get_tree().create_timer(0.3).timeout
	invincible = false
	_play_anim("idle")

func _draw() -> void:
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


# ─── Leila Karakter Sistemi ──────────────────────────────────────────────────

## Tüm Leila spritesheet'leri aynı ızgarayı paylaşır:
##   48 × 64 piksel / kare  |  8 sütun (hFrames)  |  6 satır (vFrames)
##   Satır düzeni → 0:Aşağı  1:Sol  2:Sol-Yukarı  3:Yukarı  4:Sağ-Yukarı  5:Sağ
func _setup_leila_frames() -> void:
	var frames := SpriteFrames.new()

	# Varsayılan boş animasyonu kaldır
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var sheets: Dictionary = {
		"idle":  {"path": "res://assets/characters/leila/leila_Idle.png", "fps": 8.0,  "loop": true},
		"walk":  {"path": "res://assets/characters/leila/leila_walk.png",  "fps": 10.0, "loop": true},
		"dash":  {"path": "res://assets/characters/leila/leila_dash.png",  "fps": 12.0, "loop": false},
		"death": {"path": "res://assets/characters/leila/leila_death.png", "fps": 8.0,  "loop": false},
	}
	var dir_names: Array = ["down", "left", "upper_left", "up", "upper_right", "right"]

	for base_anim: String in sheets:
		var info: Dictionary = sheets[base_anim]
		var tex: Texture2D   = load(info["path"])
		for row: int in range(6):
			var anim_name: String = base_anim + "_" + dir_names[row]
			frames.add_animation(anim_name)
			frames.set_animation_speed(anim_name, info["fps"])
			frames.set_animation_loop(anim_name, info["loop"])
			for col: int in range(8):
				var atlas := AtlasTexture.new()
				atlas.atlas   = tex
				atlas.region  = Rect2(col * 48, row * 64, 48, 64)
				frames.add_frame(anim_name, atlas)

	$AnimatedSprite2D.sprite_frames = frames


## Anlık tuş durumuna bakarak Leila'nın yüz yönünü döndürür.
## Hareket yoksa son yönü korur (idle animasyonunda yön kayması olmaz).
func _leila_get_dir() -> String:
	var up_key    := Input.is_key_pressed(KEY_W)
	var down_key  := Input.is_key_pressed(KEY_S)
	var left_key  := Input.is_key_pressed(KEY_A)
	var right_key := Input.is_key_pressed(KEY_D)

	var dir: String
	if up_key and right_key:
		dir = "upper_right"
	elif up_key and left_key:
		dir = "upper_left"
	elif up_key:
		dir = "up"
	elif down_key and right_key:
		dir = "right"        # alt-sağ çapraz → sağ satırı kullan
	elif down_key and left_key:
		dir = "left"         # alt-sol çapraz → sol satırı kullan
	elif down_key:
		dir = "down"
	elif right_key:
		dir = "right"
	elif left_key:
		dir = "left"
	else:
		return _leila_last_dir  # boşta: son yönü koru

	_leila_last_dir = dir
	return dir


## Her physics frame'de raketin rotasyonunu günceller.
##   • Top yaklaşıyorsa: raket topa bakar (lerp ile yumuşak geçiş)
##   • Top yoksa: karakterin baktığı yönde tutulma pozisyonu
##   • Swing tweeni çalışıyorsa: tweenin bitmesine izin verir, müdahale etmez
##
## Yön → açı dönüşümü:
##   Raket spritei dikey (baş en üstte = yerel -Y yönü).
##   Başın dünya koordinatlarında hedefi işaret etmesi için:
##   rotation = direction.angle() + PI/2
##   (Vector2.angle() sağı 0 sayar; +PI/2 ile -Y ekseni hedefe hizalanır)
func _update_racket(delta: float) -> void:
	if _racket == null or not is_instance_valid(_racket):
		return
	# Swing tweeni çalışıyorken müdahale etme
	if _racket_swing_tween != null and _racket_swing_tween.is_running():
		return

	# En yakın hareket eden topu bul (150 px eşiği)
	var closest_ball: Node2D = null
	var closest_dist: float  = 150.0
	for ball: Node2D in get_tree().get_nodes_in_group("balls"):
		if not ball.get("moving"):
			continue
		var d: float = global_position.distance_to(ball.global_position)
		if d < closest_dist:
			closest_dist = d
			closest_ball = ball

	var target_rot: float
	if closest_ball != null:
		# Top varsa: raket başını topa döndür
		var dir: Vector2 = (closest_ball.global_position - _racket.global_position).normalized()
		target_rot = dir.angle() + PI / 2.0
	else:
		# Top yoksa: Leila'nın baktığı yönde tut
		var dir_vecs: Dictionary = {
			"right":       Vector2(1.0,  0.0),
			"left":        Vector2(-1.0, 0.0),
			"up":          Vector2(0.0,  -1.0),
			"down":        Vector2(0.0,   1.0),
			"upper_right": Vector2(0.7071, -0.7071),
			"upper_left":  Vector2(-0.7071, -0.7071),
		}
		var facing: Vector2 = dir_vecs.get(_leila_last_dir, Vector2(1.0, 0.0))
		target_rot = facing.angle() + PI / 2.0

	# Yumuşak geçiş (delta × 10 → ~100 ms'de hedefe ulaşır)
	_racket.rotation    = lerp_angle(_racket.rotation, target_rot, delta * 10.0)
	_racket_default_rot = _racket.rotation


## Raket savurma animasyonu:
##   Faz 1 (0.08 s): ~108° hızlı dönüş + 6 birim ileri uzanma (EASE_OUT)
##   Faz 2 (0.22 s): başlangıç rotasyon ve pozisyonuna yumuşak dönüş (EASE_IN_OUT)
##   Tween paraleldir → iki mülk eş zamanlı, gecikme ile sıralama sağlanır
func _racket_swing() -> void:
	if _racket == null or not is_instance_valid(_racket):
		return
	# Önceki tamamlanmamış swing varsa iptal et
	if _racket_swing_tween != null and _racket_swing_tween.is_running():
		_racket_swing_tween.kill()

	var base_pos: Vector2  = _racket.position
	var base_rot: float    = _racket_default_rot
	var swing_rot: float   = base_rot + PI * 0.60          # ~108° ileri savurma
	var lunge_dir: Vector2 = Vector2.from_angle(base_rot - PI / 2.0)  # raket başının yönü
	var lunge_pos: Vector2 = base_pos + lunge_dir * 6.0    # 6 birim ileri uzan

	# Tüm tweener'lar aynı anda başlar; gecikme ile sıralama yapılır
	_racket_swing_tween = create_tween().set_parallel(true)

	# ── Faz 1: Swing çıkışı (0 → 0.08 s) ─────────────────────────────────────
	_racket_swing_tween.tween_property(_racket, "rotation", swing_rot, 0.08)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_racket_swing_tween.tween_property(_racket, "position", lunge_pos, 0.08)\
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	# ── Faz 2: Geri dönüş (0.08 → 0.30 s) ────────────────────────────────────
	_racket_swing_tween.tween_property(_racket, "rotation", base_rot, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.08)
	_racket_swing_tween.tween_property(_racket, "position", base_pos, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.08)


## Karakter tipine göre doğru animasyonu çalar.
##   Leila  → yönlü sprite satırına (walk_up, idle_right, …) yönlendirir
##   Vector / Cyclone → doğrudan animasyon adıyla çalar (mevcut davranış)
func _play_anim(anim: String) -> void:
	if character_type == "vector":
		return  # Vector geçici dikdörtgen kullanıyor; animasyon yok
	elif character_type == "leila":
		var dir: String = _leila_get_dir()
		var leila_anim: String
		match anim:
			"walk", "run":
				leila_anim = "walk_" + dir
			"idle":
				leila_anim = "idle_" + dir
			"hurt":
				leila_anim = "death_" + dir  # ayrı hurt sheet yok; death ilk kareleri kullanılır
			_:
				leila_anim = "idle_" + dir
		if $AnimatedSprite2D.animation != leila_anim:
			$AnimatedSprite2D.play(leila_anim)
		$AnimatedSprite2D.flip_h = false   # Leila'nın yönlü sprite'ları var, çevirmeye gerek yok
	else:
		$AnimatedSprite2D.play(anim)
