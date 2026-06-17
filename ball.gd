extends CharacterBody2D

var speed = 600.0
var damage = 0
var can_split = false
var can_electric = false
var has_split = false
var is_dead = false
var moving = false
var move_direction = Vector2.ZERO
var base_scale = 1.0
var target_scale = 1.0
var can_pierce = false
var hit_subjects = []
var catch_cooldown = 0.0
var _stuck_timer: float = 0.0
var is_active = false
var max_damage = 5
var crit_multiplier = 2.0
var crit_chance = 0.0
var can_cryo = false
var slow_amount = 0.25
var can_glitch = false
var can_water = false
var is_mimic = false
var mimic_done = false
var mimic_color_time = 0.0
var has_fused = false
var is_fused = false
var fusion_type = ""
var ball_scene = preload("res://ball.tscn")
var can_fire = false
var mimic_hits = 0
var max_mimic_hits = 5
var mimic_ring_time = 0.0
var hit_type = ""
var can_leech = false
var trail: Line2D = null
var _wall_bounce_count: int = 0  # sonsuz sekme önlemi
var trail_positions: Array = []
var trail_max_length: int = 24

# ── Orbit / State sistemi ─────────────────────────────────────────────────────
# "flying"   → normal fizik, düşmana çarpar
# "orbiting" → player etrafında döner, defans modu
# "returning"→ player'a geri döner (homing)
var state: String = "flying"

# Defense
var defense_life: int     = 0
var defense_life_max: int = 0
var defense_damage: int   = 0
var defense_cooldown: float = 0.0

# Brotato-style dart strike
var strike_offset: Vector2 = Vector2.ZERO   # player.gd orbit pozisyonuna eklenir
var _is_striking: bool     = false

# Önbellek — her frame grup sorgusu yerine bir kez alınır
var _cached_player: Node2D = null

var _sprite: AnimatedSprite2D = null

func _ready() -> void:
	z_index = 2
	$CollisionShape2D.disabled = false
	_setup_trail()
	_setup_ball_sprite()
	_update_modulate()
	_cached_player = get_tree().get_first_node_in_group("player")
	collision_layer = 2
	collision_mask  = 1

func _setup_ball_sprite() -> void:
	var folder: String
	var frame_count: int

	if is_fused:
		var fused_folders := {
			"absolute_zero":   ["absoluteZero",    17],
			"blue_screen":     ["blueScreen",       17],
			"conductive":      ["conductive",       17],
			"cryostatic":      ["cryoStatic",       17],
			"deep_freeze":     ["deepFreeze",       17],
			"electric_split":  ["electrifiedSplit", 17],
			"firework":        ["fireWork",         17],
			"frozen_split":    ["frozenSplit",      17],
			"glacier_spike":   ["glacierSpike",     17],
			"glitched_split":  ["glitchedSplit",    17],
			"hydro_jet":       ["hydroJet",         17],
			"meltdown":        ["meltDown",         17],
			"overclock":       ["overClock",        17],
			"phantom":         ["phantom",          17],
			"piercing_split":  ["piercingSplit",    17],
			"plasma_discharge":["plasmaDischarge",  17],
			"railgun":         ["railGun",          17],
			"steam_pressure":  ["steamPressure",    17],
			"thermal_shock":   ["thermalShock",     17],
			"thermite":        ["thermite",         17],
			"wet_split":       ["wetSplitBall",     17],
		}
		if fused_folders.has(fusion_type):
			var info = fused_folders[fusion_type]
			var fused_folder: String = info[0]
			var fused_count:  int    = info[1]
			var frames := SpriteFrames.new()
			if frames.has_animation("default"):
				frames.remove_animation("default")
			frames.add_animation("spin")
			frames.set_animation_speed("spin", 12.0)
			frames.set_animation_loop("spin", true)
			for i in range(fused_count):
				var tex: Texture2D = load("res://assets/fusedBalls/%s/frame_%03d.png" % [fused_folder, i])
				frames.add_frame("spin", tex)
			_sprite = AnimatedSprite2D.new()
			_sprite.sprite_frames  = frames
			_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			_sprite.scale          = Vector2(0.675, 0.675)
			_sprite.play("spin")
			add_child(_sprite)
		return
	elif can_electric:
		folder = "electricBall";  frame_count = 17
	elif can_fire:
		folder = "fireBall";      frame_count = 16
	elif can_leech:
		folder = "dataLeechBall"; frame_count = 15
	elif can_split:
		folder = "splitBall";     frame_count = 11
	elif can_cryo:
		folder = "cryoBall";      frame_count = 9
	elif can_glitch:
		folder = "glitchBall";    frame_count = 9
	elif can_pierce:
		folder = "pierceBall";    frame_count = 9
	elif can_water:
		folder = "waterBall";     frame_count = 9
	elif is_mimic:
		folder = "echoBall";      frame_count = 17
	else:
		folder = "normalBall";    frame_count = 9

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 12.0)
	frames.set_animation_loop("spin", true)
	for i in range(frame_count):
		var tex: Texture2D = load("res://assets/balls/%s/frame_%03d.png" % [folder, i])
		frames.add_frame("spin", tex)

	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames  = frames
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale          = Vector2(0.675, 0.675)
	_sprite.play("spin")
	add_child(_sprite)

func _get_player() -> Node2D:
	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player")
	return _cached_player

func launch(direction: Vector2, spd: float = 600.0) -> void:
	move_direction = direction.normalized()
	speed = spd
	moving = true
	state = "flying"
	catch_cooldown = 0.5
	$CollisionShape2D.disabled = false
	scale = Vector2(1.0, 1.0)
	z_index = 2
	_wall_bounce_count = 0

func launch_with_speed(direction: Vector2, spd: float) -> void:
	move_direction = direction.normalized()
	speed = spd
	moving = true
	state = "flying"
	catch_cooldown = 0.5
	$CollisionShape2D.disabled = false
	scale = Vector2(1.0, 1.0)
	z_index = 2
	_wall_bounce_count = 0

func caught() -> void:
	# Legacy uyumluluk — orbit join artık player.add_to_orbit() ile yapılıyor
	moving = false
	$CollisionShape2D.disabled = true
	trail_positions.clear()
	if is_instance_valid(trail):
		trail.points = PackedVector2Array()
		trail.visible = false

func absorb() -> void:
	# Fusion Zone tarafından çağrılır — returning'e geçmemesi için ayrı state
	state = "flying"   # fusion tween sırasında fizik çalışmasın
	moving = false
	$CollisionShape2D.disabled = true
	trail_positions.clear()
	if is_instance_valid(trail):
		trail.points = PackedVector2Array()
		trail.visible = false
	
func _copy_ball(other: Node2D) -> void:
	can_split = other.can_split
	can_electric = other.can_electric
	can_pierce = other.can_pierce
	can_cryo = other.can_cryo
	can_glitch = other.can_glitch
	can_water = other.can_water
	can_fire = other.can_fire
	can_leech = other.can_leech
	# max_damage is not copied!
	slow_amount = other.slow_amount
	is_mimic = false
	mimic_done = true
	_update_modulate()
	_update_trail_color()
	queue_redraw()

func _process(_delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	_update_trail(delta)

	match state:
		"orbiting":  _process_orbiting(delta); return
		"returning": _process_returning(delta); return

	# ── state == "flying" ─────────────────────────────────────────────────────
	if not moving:
		_stuck_timer += delta
		if _stuck_timer > 0.5:
			_stuck_timer = 0.0
			_start_returning()
		return
	_stuck_timer = 0.0

	# Player yakınında iken collision kapat — itme engeli
	var _fly_player := _get_player()
	if is_instance_valid(_fly_player):
		var _fly_dist := global_position.distance_to(_fly_player.global_position)
		if _fly_dist < 80:
			$CollisionShape2D.disabled = true
			# Orbit'e katılmaya hazırsa katıl
			if catch_cooldown <= 0 and _fly_dist < 55:
				_fly_player.add_to_orbit(self)
				return
		else:
			# catch_cooldown sadece orbit'e geri dönmeyi engeller,
			# düşmana çarpmayı engellemez — her zaman aç
			if $CollisionShape2D.disabled:
				$CollisionShape2D.disabled = false

	if catch_cooldown > 0:
		catch_cooldown -= delta

	# Duvar sınırları + sonsuz sekme koruması
	var _bounced := false
	if global_position.x <= 910:
		global_position.x = 910
		move_direction.x = abs(move_direction.x)
		_bounced = true
	if global_position.x >= 1580:
		global_position.x = 1580
		move_direction.x = -abs(move_direction.x)
		_bounced = true
	if global_position.y <= 260:
		global_position.y = 260
		move_direction.y = abs(move_direction.y)
		_bounced = true
	if global_position.y >= 1040:
		global_position.y = 1040
		move_direction.y = -abs(move_direction.y)
		_start_returning()
		return

	if _bounced:
		_wall_bounce_count += 1
		if _wall_bounce_count >= 6:
			_wall_bounce_count = 0
			_start_returning()
			return
	else:
		# Düşmana çarpınca sayaç sıfırlanır
		pass

	# Mimic
	if mimic_done and not is_mimic:
		mimic_ring_time += get_process_delta_time()
		queue_redraw()
	if is_mimic and not mimic_done:
		var balls = get_tree().get_nodes_in_group("balls")
		for other_ball in balls:
			if other_ball == self: continue
			var has_power = other_ball.can_split or other_ball.can_electric or other_ball.can_pierce or other_ball.can_cryo or other_ball.can_glitch or other_ball.can_fire or other_ball.can_water
			if has_power and other_ball.moving and not other_ball.is_fused:
				if global_position.distance_to(other_ball.global_position) < 200:
					_copy_ball(other_ball)
					mimic_done = true
					break
	if is_mimic:
		mimic_color_time += get_process_delta_time()
		queue_redraw()

	var collision = move_and_collide(move_direction * speed * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("subjects"):
			_wall_bounce_count = 0
			_hit_subject(collider)
			if can_pierce:
				move_and_collide(collision.get_remainder())
		elif collider.is_in_group("player"):
			if not collider.is_dashing:
				move_direction = move_direction.bounce(collision.get_normal())
				move_direction = move_direction.normalized()
		else:
			# Bariyer veya statik duvar — aninda geri don
			_start_returning()

	if is_fused and fusion_type == "phantom":
		var subjects = get_tree().get_nodes_in_group("subjects")
		for z in subjects:
			if z not in hit_subjects:
				if global_position.distance_to(z.global_position) < 40:
					_hit_subject(z)

# ── State: Orbiting ───────────────────────────────────────────────────────────
func _process_orbiting(delta: float) -> void:
	if _is_striking:
		return
	if defense_cooldown > 0:
		defense_cooldown -= delta
		return
	# Yakında düşman var mı? → dart strike başlat
	var subjects = get_tree().get_nodes_in_group("subjects")
	for subject in subjects:
		if is_instance_valid(subject):
			if global_position.distance_to(subject.global_position) < 78:
				_start_strike(subject)
				return

func _start_strike(target: Node2D) -> void:
	if _is_striking: return
	_is_striking = true

	# Hedefe doğru dart vektörü (max 45 px)
	var to_target := target.global_position - global_position
	var dart: Vector2 = to_target.normalized() * min(to_target.length() * 0.75, 45.0)

	# Dışarı fırlat
	var tw_out := create_tween()
	tw_out.tween_property(self, "strike_offset", dart, 0.07)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw_out.finished

	# Hedefe vur
	if is_instance_valid(target):
		_defense_hit(target)

	# Geri çek
	var tw_back := create_tween()
	tw_back.tween_property(self, "strike_offset", Vector2.ZERO, 0.11)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw_back.finished

	_is_striking  = false
	defense_cooldown = 0.50

# ── State: Returning ──────────────────────────────────────────────────────────
func _process_returning(delta: float) -> void:
	var player := _get_player()
	if not is_instance_valid(player):
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist < 40:
		if player.orbit_balls.size() < player.MAX_ORBIT:
			player.add_to_orbit(self)
			return
		# Orbit dolu — player etrafında küçük daire çizerek slot bekle
		move_direction = move_direction.lerp(to_player.normalized().rotated(PI * 0.5), 0.20)
		if move_direction.length() > 0.01:
			move_direction = move_direction.normalized()
		speed = 110.0
		move_and_collide(move_direction * speed * delta)
		return

	# Homing — her frame biraz daha player'a döner
	var target_dir = to_player.normalized()
	move_direction = move_direction.lerp(target_dir, 0.12)
	if move_direction.length() > 0.01:
		move_direction = move_direction.normalized()

	speed = min(speed + 220.0 * delta, 680.0)

	# Duvar sekme
	if global_position.x <= 910:
		global_position.x = 910
		move_direction.x = abs(move_direction.x)
	if global_position.x >= 1580:
		global_position.x = 1580
		move_direction.x = -abs(move_direction.x)
	if global_position.y <= 260:
		global_position.y = 260
		move_direction.y = abs(move_direction.y)
	if global_position.y >= 1040:
		global_position.y = 1040
		move_direction.y = -abs(move_direction.y)

	# Dönerken de düşmana çarpar (tam hasar)
	var collision = move_and_collide(move_direction * speed * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("subjects"):
			_hit_subject(collider)
			if can_pierce:
				move_and_collide(collision.get_remainder())
		elif not collider.is_in_group("player"):
			# Bariyer veya statik duvar — aninda geri don
			_start_returning()

# ── Defense helpers ───────────────────────────────────────────────────────────
func _defense_hit(subject: Node2D) -> void:
	if not is_instance_valid(subject): return
	subject.take_damage(defense_damage)
	if can_fire    and is_instance_valid(subject): subject.apply_burn()
	if can_water   and is_instance_valid(subject): subject.apply_wet()
	if can_electric and is_instance_valid(subject): subject.apply_electrified()
	if can_cryo    and is_instance_valid(subject): subject.apply_slow(slow_amount)
	if can_glitch  and is_instance_valid(subject): subject.apply_glitch()
	defense_life -= defense_damage
	if defense_life <= 0:
		_auto_fire()

func _auto_fire() -> void:
	var player := _get_player()
	if not is_instance_valid(player): return
	player.remove_from_orbit(self)
	launch(player.aim_direction, 650.0)

func _reset_defense_life() -> void:
	defense_damage    = _get_defense_base_damage()
	defense_life_max  = max(int(defense_damage * 3), 1)
	defense_life      = defense_life_max

func _get_defense_base_damage() -> int:
	var fd: int
	if is_fused:      fd = max_damage
	elif can_split:   fd = 7
	elif can_electric:fd = 9
	elif can_pierce:  fd = 10
	elif can_cryo:    fd = 4
	elif can_glitch:  fd = 4
	elif can_water:   fd = 3
	elif can_fire:    fd = 6
	elif can_leech:   fd = 2
	else:             fd = 5
	return max(int(fd * 0.5), 1)

func _start_returning() -> void:
	state         = "returning"
	moving        = true
	speed         = 200.0
	scale         = Vector2(1.0, 1.0)
	z_index       = 2
	strike_offset = Vector2.ZERO
	_is_striking  = false
	$CollisionShape2D.disabled = false
	hit_subjects.clear()
		
func _try_fusion(other: Node2D) -> void:
	var self_type = _get_type()
	var other_type = other._get_type()
	var fusion = _get_fusion_type(self_type, other_type)
	
	if fusion == "":
		return
	
	has_fused = true
	other.has_fused = true
	moving = false
	other.moving = false
	
	# Orta nokta
	var mid = (global_position + other.global_position) / 2.0
	
	# Animasyon
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", mid, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(other, "global_position", mid, 1.0).set_trans(Tween.TRANS_SINE)
	
	await get_tree().create_timer(1.0).timeout
	
	# Create fusion ball
	var new_ball = ball_scene.instantiate()
	new_ball.global_position = mid
	_apply_fusion(new_ball, fusion)
	get_parent().add_child(new_ball)
	new_ball.launch(move_direction)
	
	other.queue_free()
	queue_free()

func _get_type() -> String:
	if can_leech:
		return "leech"
	if can_split: return "split"
	if can_electric: return "electric"
	if can_pierce: return "pierce"
	if can_cryo: return "cryo"
	if can_glitch: return "glitch"
	if can_fire: return "fire"
	if can_water: return "water"
	return "normal"

func _get_fusion_type(a: String, b: String) -> String:
	var pair = [a, b]
	pair.sort()
	var key = pair[0] + "_" + pair[1]
	var fusions = {
		"cryo_split": "frozen_split",
		"glitch_split": "glitched_split",
		"electric_split": "electric_split",
		"pierce_split": "piercing_split",
		"cryo_electric": "cryostatic",
		"electric_glitch": "overclock",
		"electric_pierce": "railgun",
		"cryo_pierce": "glacier_spike",
		"glitch_pierce": "phantom",
		"cryo_glitch": "deep_freeze",
		"fire_water": "steam_pressure",
		"cryo_fire": "thermal_shock",
		"electric_fire": "plasma_discharge",
		"fire_pierce": "thermite",
		"fire_split": "firework",
		"fire_glitch": "meltdown",
		"split_water": "wet_split",
		"electric_water": "conductive",
		"pierce_water": "hydro_jet",
		"glitch_water": "blue_screen",
		"cryo_water": "absolute_zero",
		}
	return fusions.get(key, "")

func _apply_fusion(ball: Node2D, fusion: String) -> void:
	ball.is_fused = true
	ball.has_fused = true
	ball.fusion_type = fusion
	match fusion:
		"wet_split":
			ball.can_split = true
			ball.can_water = true
			ball.max_damage = 8
		"conductive":
			ball.can_electric = true
			ball.can_water = true
			ball.max_damage = 10
		"hydro_jet":
			ball.can_pierce = true
			ball.can_water = true
			ball.max_damage = 12
		"blue_screen":
			ball.can_glitch = true
			ball.can_water = true
			ball.max_damage = 9
		"absolute_zero":
			ball.can_cryo = true
			ball.can_water = true
			ball.max_damage = 11
		"frozen_split":
			ball.can_split = true
			ball.can_cryo = true
			ball.max_damage = 8
		"glitched_split":
			ball.can_split = true
			ball.can_glitch = true
			ball.max_damage = 8
		"electric_split":
			ball.can_split = true
			ball.can_electric = true
			ball.max_damage = 10
		"piercing_split":
			ball.can_split = true
			ball.can_pierce = true
			ball.max_damage = 10
		"cryostatic":
			ball.can_electric = true
			ball.can_cryo = true
			ball.max_damage = 11
		"overclock":
			ball.can_electric = true
			ball.can_glitch = true
			ball.max_damage = 11
		"railgun":
			ball.can_electric = true
			ball.can_pierce = true
			ball.max_damage = 12
		"glacier_spike":
			ball.can_pierce = true
			ball.can_cryo = true
			ball.max_damage = 12
		"phantom":
			ball.can_pierce = true
			ball.can_glitch = true
			ball.max_damage = 12
		"deep_freeze":
			ball.can_cryo = true
			ball.can_glitch = true
			ball.max_damage = 10
		"steam_pressure":
			ball.can_fire = true
			ball.can_water = true
			ball.max_damage = 8
		"thermal_shock":
			ball.can_fire = true
			ball.can_cryo = true
			ball.max_damage = 14
		"plasma_discharge":
			ball.can_fire = true
			ball.can_electric = true
			ball.max_damage = 13
		"thermite":
			ball.can_fire = true
			ball.can_pierce = true
			ball.max_damage = 13
		"firework":
			ball.can_fire = true
			ball.can_split = true
			ball.max_damage = 10
		"meltdown":
			ball.can_fire = true
			ball.can_glitch = true
			ball.max_damage = 12
	ball.queue_redraw()
	ball._refresh_sprite()

func _refresh_sprite() -> void:
	if is_instance_valid(_sprite):
		_sprite.queue_free()
		_sprite = null
	_setup_ball_sprite()

func _draw() -> void:
	if is_instance_valid(_sprite):
		return
	# Mimic RGB halka
	if mimic_done and not is_mimic:
		var r = (sin(mimic_ring_time * 2.0) + 1.0) / 2.0
		var g = (sin(mimic_ring_time * 2.0 + 2.094) + 1.0) / 2.0
		var b = (sin(mimic_ring_time * 2.0 + 4.189) + 1.0) / 2.0
		draw_arc(Vector2.ZERO, 14, 0, TAU, 32, Color(r, g, b), 2.0)
	if is_fused:
		match fusion_type:
			"wet_split":
				draw_circle(Vector2.ZERO, 10, Color(0.0, 0.5, 1.0))
				for i in range(8):
					var angle = i * TAU / 8
					var start = Vector2(cos(angle), sin(angle)) * 10
					var end = Vector2(cos(angle), sin(angle)) * 16
					draw_line(start, end, Color(0.3, 0.7, 1.0), 2)
			"conductive":
				draw_circle(Vector2.ZERO, 10, Color(0.0, 0.5, 1.0))
				draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color(0.2, 0.5, 1.0), 2)
				draw_line(Vector2(-8, -5), Vector2(8, 5), Color(1.0, 1.0, 0.0, 0.8), 2)
			"hydro_jet":
				var points = PackedVector2Array([
					Vector2(-15, 0), Vector2(0, -8),
					Vector2(15, 0), Vector2(0, 8)
				])
				draw_colored_polygon(points, Color(0.0, 0.5, 1.0))
				draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color(0.3, 0.7, 1.0), 2)
			"blue_screen":
				draw_circle(Vector2.ZERO, 10, Color(0.0, 0.3, 0.8))
				draw_line(Vector2(-8, -5), Vector2(8, 5), Color(0.8, 0.0, 0.8, 0.8), 2)
				draw_line(Vector2(-8, 5), Vector2(8, -5), Color(0.8, 0.0, 0.8, 0.8), 2)
			"absolute_zero":
				draw_circle(Vector2.ZERO, 12, Color(0.8, 1.0, 1.0))
				var pts = PackedVector2Array([
					Vector2(0, -14), Vector2(8, -7),
					Vector2(8, 7), Vector2(0, 14),
					Vector2(-8, 7), Vector2(-8, -7)
				])
				draw_colored_polygon(pts, Color(0.5, 0.8, 1.0, 0.5))
			"steam_pressure":
				draw_circle(Vector2.ZERO, 12, Color(0.8, 0.8, 1.0))
				draw_arc(Vector2.ZERO, 15, 0, TAU, 32, Color(1.0, 0.3, 0.0), 2)
			"thermal_shock":
				draw_circle(Vector2.ZERO, 12, Color(1.0, 0.3, 0.0))
				var pts = PackedVector2Array([
					Vector2(0, -12), Vector2(7, -6),
					Vector2(7, 6), Vector2(0, 12),
					Vector2(-7, 6), Vector2(-7, -6)
				])
				draw_colored_polygon(pts, Color(0.5, 0.8, 1.0, 0.5))
			"plasma_discharge":
				draw_circle(Vector2.ZERO, 12, Color(1.0, 0.5, 0.0))
				draw_arc(Vector2.ZERO, 15, 0, TAU, 32, Color(1.0, 1.0, 0.0), 2)
			"thermite":
				var points = PackedVector2Array([
					Vector2(-15, 0), Vector2(0, -8),
					Vector2(15, 0), Vector2(0, 8)
				])
				draw_colored_polygon(points, Color(1.0, 0.3, 0.0))
				draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color(1.0, 0.8, 0.0), 2)
			"firework":
				draw_circle(Vector2.ZERO, 10, Color(1.0, 0.3, 0.0))
				for i in range(8):
					var angle = i * TAU / 8
					var start = Vector2(cos(angle), sin(angle)) * 10
					var end = Vector2(cos(angle), sin(angle)) * 16
					draw_line(start, end, Color(1.0, 0.6, 0.0), 2)
			"firework_piece":
				draw_circle(Vector2.ZERO, 6, Color(1.0, 0.4, 0.0))
				draw_arc(Vector2.ZERO, 8, 0, TAU, 32, Color(1.0, 0.8, 0.0), 1.5)
			"meltdown":
				draw_circle(Vector2.ZERO, 10, Color(1.0, 0.3, 0.0))
				draw_line(Vector2(-8, -5), Vector2(8, 5), Color(0.8, 0.0, 0.8, 0.8), 2)
				draw_line(Vector2(-8, 5), Vector2(8, -5), Color(0.8, 0.0, 0.8, 0.8), 2)
			"frozen_split":
				# Mavi dikenli
				draw_circle(Vector2.ZERO, 10, Color(0.5, 0.8, 1.0))
				for i in range(8):
					var angle = i * TAU / 8
					var start = Vector2(cos(angle), sin(angle)) * 10
					var end = Vector2(cos(angle), sin(angle)) * 16
					draw_line(start, end, Color(0.8, 1.0, 1.0), 2)
			"glitched_split":
				# Mor dikenli
				draw_circle(Vector2.ZERO, 10, Color(0.8, 0.0, 0.8))
				for i in range(8):
					var angle = i * TAU / 8
					var start = Vector2(cos(angle), sin(angle)) * 10
					var end = Vector2(cos(angle), sin(angle)) * 16
					draw_line(start, end, Color(1.0, 0.5, 1.0), 2)
			"electric_split":
				# Yellow spiky
				draw_circle(Vector2.ZERO, 10, Color(1.0, 1.0, 0.0))
				for i in range(8):
					var angle = i * TAU / 8
					var start = Vector2(cos(angle), sin(angle)) * 10
					var end = Vector2(cos(angle), sin(angle)) * 16
					draw_line(start, end, Color(1.0, 0.8, 0.0), 2)
			"piercing_split":
				# Turuncu oval dikenli
				var points = PackedVector2Array([
					Vector2(-15, 0), Vector2(0, -8),
					Vector2(15, 0), Vector2(0, 8)
				])
				draw_colored_polygon(points, Color(1.0, 0.6, 0.0))
				for i in range(8):
					var angle = i * TAU / 8
					var start = Vector2(cos(angle), sin(angle)) * 10
					var end = Vector2(cos(angle), sin(angle)) * 16
					draw_line(start, end, Color(1.0, 0.4, 0.0), 2)
			"cryostatic":
				# Mavi elektrik kristali
				var pts = PackedVector2Array([
					Vector2(0, -12), Vector2(7, -6),
					Vector2(7, 6), Vector2(0, 12),
					Vector2(-7, 6), Vector2(-7, -6)
				])
				draw_colored_polygon(pts, Color(0.3, 0.6, 1.0))
				draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color(0.5, 0.8, 1.0), 2)
			"overclock":
				# Mor elektrik
				draw_circle(Vector2.ZERO, 10, Color(0.8, 0.0, 0.8))
				draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color(1.0, 0.5, 1.0), 2)
				draw_line(Vector2(-8, -5), Vector2(8, 5), Color(0.2, 0.5, 1.0, 0.8), 2)
				draw_line(Vector2(-8, 5), Vector2(8, -5), Color(0.2, 0.5, 1.0, 0.8), 2)
			"railgun":
				# Yellow oval electric
				var points = PackedVector2Array([
					Vector2(-15, 0), Vector2(0, -8),
					Vector2(15, 0), Vector2(0, 8)
				])
				draw_colored_polygon(points, Color(1.0, 1.0, 0.0))
				draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color(0.2, 0.5, 1.0), 2)
			"glacier_spike":
				# Mavi oval kristal
				var pts = PackedVector2Array([
					Vector2(-15, 0), Vector2(0, -8),
					Vector2(15, 0), Vector2(0, 8)
				])
				draw_colored_polygon(pts, Color(0.3, 0.8, 1.0))
				var crystal_pts = PackedVector2Array([
					Vector2(0, -12), Vector2(5, -6),
					Vector2(5, 6), Vector2(0, 12),
					Vector2(-5, 6), Vector2(-5, -6)
				])
				draw_colored_polygon(crystal_pts, Color(0.6, 0.9, 1.0, 0.5))
			"phantom":
				# Semi-transparent purple oval
				var points = PackedVector2Array([
					Vector2(-15, 0), Vector2(0, -8),
					Vector2(15, 0), Vector2(0, 8)
				])
				draw_colored_polygon(points, Color(0.6, 0.0, 0.8, 0.7))
				draw_line(Vector2(-8, -5), Vector2(8, 5), Color(1.0, 0.5, 1.0, 0.5), 2)
				draw_line(Vector2(-8, 5), Vector2(8, -5), Color(1.0, 0.5, 1.0, 0.5), 2)
			"deep_freeze":
				# Mor kristal
				var pts = PackedVector2Array([
					Vector2(0, -12), Vector2(7, -6),
					Vector2(7, 6), Vector2(0, 12),
					Vector2(-7, 6), Vector2(-7, -6)
				])
				draw_colored_polygon(pts, Color(0.6, 0.0, 0.8))
				draw_line(Vector2(0, -12), Vector2(0, 12), Color(0.5, 0.8, 1.0, 0.8), 1.5)
				draw_line(Vector2(-7, -6), Vector2(7, 6), Color(0.5, 0.8, 1.0, 0.8), 1.5)
				draw_line(Vector2(7, -6), Vector2(-7, 6), Color(0.5, 0.8, 1.0, 0.8), 1.5)
		draw_circle(Vector2(5, 8), 5, Color(0, 0, 0, 0.25))
		return
	var shadow_offset = Vector2(5, 8)
	draw_circle(shadow_offset, 8 * scale.x, Color(0, 0, 0, 0.35))
	
	if can_electric:
		draw_circle(Vector2.ZERO, 10, Color(0.2, 0.5, 1.0))
		draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color(0.5, 0.8, 1.0), 2)
	elif can_pierce:
		var points = PackedVector2Array([
			Vector2(-15, 0), Vector2(0, -8),
			Vector2(15, 0), Vector2(0, 8)
		])
		draw_colored_polygon(points, Color(1.0, 0.8, 0.0))
		var shadow_points = PackedVector2Array([
			Vector2(-12, 6), Vector2(0, 10),
			Vector2(12, 6), Vector2(0, 2)
		])
		draw_colored_polygon(shadow_points, Color(0, 0, 0, 0.25))
	elif can_water:
		draw_circle(Vector2.ZERO, 12, Color(0.0, 0.5, 1.0, 0.8))
		draw_circle(Vector2.ZERO, 8, Color(0.3, 0.7, 1.0, 0.6))
		draw_circle(Vector2(3, -3), 3, Color(0.8, 0.9, 1.0, 0.5))
		draw_circle(Vector2(5, 8), 5, Color(0, 0, 0, 0.25))
	elif can_split:
		draw_circle(Vector2.ZERO, 10, Color(1.0, 0.2, 0.2))
		for i in range(8):
			var angle = i * TAU / 8
			var start = Vector2(cos(angle), sin(angle)) * 10
			var end = Vector2(cos(angle), sin(angle)) * 16
			draw_line(start, end, Color(1.0, 0.4, 0.0), 2)
	elif can_fire:
		draw_circle(Vector2.ZERO, 10, Color(1.0, 0.3, 0.0))
		draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color(1.0, 0.6, 0.0), 2)
		draw_circle(Vector2(5, 8), 5, Color(0, 0, 0, 0.25))
	elif can_leech:
		draw_circle(Vector2.ZERO, 8, Color(0.0, 0.8, 0.0, 0.9))
		draw_arc(Vector2.ZERO, 10, 0, TAU, 32, Color(0.0, 1.0, 0.0), 2)
		for i in range(6):
			var angle = i * TAU / 6
			var start = Vector2(cos(angle), sin(angle)) * 10
			var end = Vector2(cos(angle), sin(angle)) * 15
			draw_line(start, end, Color(0.0, 1.0, 0.2), 2)
		draw_circle(Vector2.ZERO, 3, Color(0.5, 1.0, 0.5))
	elif can_cryo:
		var points = PackedVector2Array([
			Vector2(0, -12),
			Vector2(7, -6),
			Vector2(7, 6),
			Vector2(0, 12),
			Vector2(-7, 6),
			Vector2(-7, -6)
		])
		draw_colored_polygon(points, Color(0.5, 0.8, 1.0))
		draw_line(Vector2(0, -12), Vector2(0, 12), Color(0.8, 1.0, 1.0, 0.8), 1.5)
		draw_line(Vector2(-7, -6), Vector2(7, 6), Color(0.8, 1.0, 1.0, 0.8), 1.5)
		draw_line(Vector2(7, -6), Vector2(-7, 6), Color(0.8, 1.0, 1.0, 0.8), 1.5)
		draw_circle(Vector2(5, 8), 5, Color(0, 0, 0, 0.25))
	elif can_glitch:
		draw_circle(Vector2.ZERO, 10, Color(0.8, 0.0, 0.8))
		draw_arc(Vector2.ZERO, 13, 0, TAU, 32, Color(1.0, 0.0, 1.0), 2)
		draw_line(Vector2(-8, -5), Vector2(8, 5), Color(1.0, 0.5, 1.0, 0.8), 2)
		draw_line(Vector2(-8, 5), Vector2(8, -5), Color(1.0, 0.5, 1.0, 0.8), 2)
	else:
		if is_mimic:
			var r = (sin(mimic_color_time * 2.0) + 1.0) / 2.0
			var g = (sin(mimic_color_time * 2.0 + 2.094) + 1.0) / 2.0
			var b = (sin(mimic_color_time * 2.0 + 4.189) + 1.0) / 2.0
			draw_circle(Vector2.ZERO, 10, Color(r, g, b))
			draw_circle(Vector2(5, 8), 5, Color(0, 0, 0, 0.25))
		else:
			draw_circle(Vector2.ZERO, 10, Color(1.0, 1.0, 1.0))
		
func _hit_subject(subject: Node2D) -> void:
	var fusion_zone = get_tree().get_first_node_in_group("fusion_zone")
	if fusion_zone:
		fusion_zone.add_energy_from_hit(hit_type)
	if not is_instance_valid(subject):
		return
	if subject in hit_subjects:
		return
	hit_subjects.append(subject)

	# Hemen sekme — tüm await'lardan ÖNCE, top takılmasın
	if not (is_fused and fusion_type == "phantom") and not can_pierce:
		var _bn := (global_position - subject.global_position).normalized()
		if _bn.length_squared() < 0.01:
			_bn = -move_direction
		move_direction = move_direction.bounce(_bn).normalized()
		global_position += _bn * 8.0

	# Mimic reverts after 5 hits
	if mimic_done and not is_mimic:
		mimic_hits += 1
		if mimic_hits >= max_mimic_hits:
			can_split = false
			can_electric = false
			can_pierce = false
			can_cryo = false
			can_glitch = false
			can_water = false
			can_fire = false
			mimic_done = false
			mimic_hits = 0
			queue_redraw()
	# Calculate damage based on speed
	var base_damage = max_damage
	if can_split and not has_split:
		base_damage = 7
	elif can_electric:
		base_damage = 9
	elif can_pierce:
		base_damage = 10
	elif can_cryo:
		base_damage = 4
	elif can_glitch:
		base_damage = 4
	elif can_water:
		base_damage = 3
	elif can_fire:
		base_damage = 6
	elif can_leech:
		base_damage = 2
	var total_damage = base_damage

# Crit check
	var is_crit = randf() < crit_chance
	if is_crit:
		total_damage = int(total_damage * crit_multiplier)

	subject.take_damage(total_damage)

	# ── Veri Toplama ─────────────────────────────────────────
	# Data amount determined by Fusion > Enhanced > Basic ball order
	var data_amount: int = 100
	if is_fused:
		data_amount = 450
	elif can_electric or can_pierce:
		data_amount = 200
	elif can_split or can_cryo or can_glitch or can_fire or can_water or can_leech:
		data_amount = 150
	if is_crit:
		data_amount = int(data_amount * 1.5)
	var game_node = get_tree().get_first_node_in_group("game")
	if game_node and game_node.has_method("add_data"):
		game_node.add_data(data_amount)

	# Leila - top sektirme
	var game_player := _get_player()
	if game_player and game_player.character_type == "leila":
		if speed > 200:
			speed = min(speed + 150, 900.0)
		# Status effect interactions
	# Electrified interactions
	if subject.is_electrified:
		if can_pierce:
			# Convert to Railgun
			can_pierce = false
			can_electric = true
			has_fused = true
			is_fused = true
			fusion_type = "railgun"
			speed = 900.0
			max_damage = 15
			queue_redraw()
			await get_tree().create_timer(15.0).timeout
			if is_instance_valid(self):
				can_electric = false
				fusion_type = ""
				is_fused = false
				speed = 600.0
				max_damage = 10
				queue_redraw()
		elif can_cryo:
			# 3 saniye sonra Burst hasar
			subject.is_electrified = false
			subject.modulate = Color(1, 1, 1)
			await get_tree().create_timer(3.0).timeout
			if is_instance_valid(subject):
				subject.take_damage(20)
		elif can_glitch:
			# Overload - attacks surroundings until it drops
			subject.is_electrified = false
			subject.modulate = Color(1, 1, 1)
			subject.apply_glitch()
		elif can_water:
			# Chain Reaction - electrify nearby wet subjects
			subject.is_electrified = false
			subject.modulate = Color(1, 1, 1)
			subject.take_damage(10)
			var enemies = get_tree().get_nodes_in_group("subjects")
			for enemy in enemies:
				if enemy != subject and is_instance_valid(enemy):
					var dist = subject.global_position.distance_to(enemy.global_position)
					if dist < 200 and enemy.is_wet:
						enemy.take_damage(10)
						enemy.is_electrified = false
		elif can_fire:
			# Plasma bomb - AoE explosion
			subject.is_electrified = false
			subject.modulate = Color(1, 1, 1)
			var enemies = get_tree().get_nodes_in_group("subjects")
			for enemy in enemies:
				if is_instance_valid(enemy):
					var dist = subject.global_position.distance_to(enemy.global_position)
					if dist < 150:
						enemy.take_damage(15)
	if not is_instance_valid(subject):
		return
	if can_water and subject.is_burning:
		# Burn + Water = Steam
		subject.apply_wet()
		subject.take_damage(8)
		subject.is_burning = false
	elif can_electric and subject.is_wet:
		# Wet + Electric = Shock
		subject.take_damage(6)
		# Chain damage - also hits nearby subjects
		var enemies = get_tree().get_nodes_in_group("subjects")
		for enemy in enemies:
			if enemy != subject and is_instance_valid(enemy):
				var dist = subject.global_position.distance_to(enemy.global_position)
				if dist < 150:
					enemy.take_damage(4)
	elif can_cryo and subject.is_wet:
		# Wet + Cryo = Instant Frozen
		subject.apply_frozen()
	elif can_cryo and subject.is_burning:
		# Burn + Cryo = Thermal Shock
		subject.take_damage(12)
		subject.is_burning = false
	# Life steal ball 
	if can_leech:
		var game = get_tree().get_first_node_in_group("game")
		if game:
			game.player_hp = min(game.player_hp + 2, game.player_max_hp)
			game.update_ui()
	# Hydro Jet - vacuum corridor, accelerates nearby balls
	if is_fused and fusion_type == "hydro_jet" and is_instance_valid(subject):
		subject.apply_wet()
		var balls = get_tree().get_nodes_in_group("balls")
		for b in balls:
			if b != self and b.moving:
				var dist = global_position.distance_to(b.global_position)
				if dist < 150:
					b.speed = min(b.speed + 100, 800)
	# Cryostatic - leaks electricity along path
	if is_fused and fusion_type == "cryostatic" and is_instance_valid(subject):
		subject.apply_slow(slow_amount)
		var subjects = get_tree().get_nodes_in_group("subjects")
		for z in subjects:
			if z != subject:
				var dist = global_position.distance_to(z.global_position)
				if dist < 100:
					z.take_damage(total_damage / 2)
	# Wet Split piece - single hit, applies wet
	if is_fused and fusion_type == "wet_split_piece" and is_instance_valid(subject):
		subject.apply_wet()
		queue_free()
		return
	# Deep Freeze Error - freeze animation, slow nearby balls
	if is_fused and fusion_type == "deep_freeze" and is_instance_valid(subject):
		subject.apply_frozen()
		subject.apply_glitch()
	# Phantom - pass through and apply glitch
	if is_fused and fusion_type == "phantom" and is_instance_valid(subject):
		subject.apply_glitch()
	# Overclock - make them attack each other
	if is_fused and fusion_type == "overclock" and is_instance_valid(subject):
		subject.apply_glitch()
		var subjects = get_tree().get_nodes_in_group("subjects")
		for z in subjects:
			if z != subject:
				var dist = global_position.distance_to(z.global_position)
				if dist < 200:
					z.apply_glitch()
	# Railgun - electric line
	if is_fused and fusion_type == "railgun" and is_instance_valid(subject):
		var subjects = get_tree().get_nodes_in_group("subjects")
		for z in subjects:
			if z != subject:
				var dist = global_position.distance_to(z.global_position)
				if dist < 150:
					z.take_damage(total_damage / 2)
	# Glacier Spike - ice core
	if is_fused and fusion_type == "glacier_spike" and is_instance_valid(subject):
		var target_subject = subject
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(target_subject):
				target_subject.apply_slow(0.5)
				target_subject.take_damage(total_damage)
		)
	# Blue Screen - wet + glitch
	if is_fused and fusion_type == "blue_screen" and is_instance_valid(subject):
		subject.apply_wet()
		subject.apply_glitch()
	# Conductive - zincir elektrik
	if is_fused and fusion_type == "conductive" and is_instance_valid(subject):
		subject.apply_wet()
		var subjects = get_tree().get_nodes_in_group("subjects")
		for z in subjects:
			if z != subject and global_position.distance_to(z.global_position) < 200:
				if z.is_wet:
					z.take_damage(total_damage)
	# Absolute Zero - instant freeze
	if is_fused and fusion_type == "absolute_zero" and is_instance_valid(subject):
		subject.apply_frozen()
	# Firework piece - single hit explosion
	if is_fused and fusion_type == "firework_piece" and is_instance_valid(subject):
		subject.apply_burn()
		queue_free()
		return
	# Meltdown - glitch + burn
	if is_fused and fusion_type == "meltdown" and is_instance_valid(subject):
		subject.apply_burn()
		subject.apply_glitch()
	# Thermite - internal combustion
	if 	is_fused and fusion_type == "thermite" and is_instance_valid(subject):
		subject.apply_burn()
	# Steam Pressure - Knockback
	if is_fused and fusion_type == "steam_pressure" and is_instance_valid(subject):
		var push_dir = (subject.global_position - global_position).normalized()
		subject.global_position += push_dir * 200
		subject.apply_wet()
	# Thermal Shock - Burst hasar
	if is_fused and fusion_type == "thermal_shock" and is_instance_valid(subject):
		if subject.is_frozen or subject.is_slowed:
			subject.take_damage(total_damage * 2)
	# Plasma Discharge - area damage
	if is_fused and fusion_type == "plasma_discharge" and is_instance_valid(subject):
		var subjects = get_tree().get_nodes_in_group("subjects")
		for z in subjects:
			if global_position.distance_to(z.global_position) < 120:
				z.take_damage(total_damage)
	if can_fire and is_instance_valid(subject):
		subject.apply_burn()
	if can_water and is_instance_valid(subject):
		subject.apply_wet()
		#queue_free()
		#return
	if can_glitch and is_instance_valid(subject):
		subject.apply_glitch()
	if can_electric and is_instance_valid(subject):
		subject.apply_electrified()
	if can_cryo and is_instance_valid(subject):
		if subject.is_wet:
			subject.apply_frozen()
		else:
			subject.apply_slow(slow_amount)
	
	if can_split and not has_split:
		has_split = true
		can_split = false
		queue_redraw()
		_split()
		if is_fused and fusion_type == "firework":
			queue_free()
			return

	
	# hit_subjects temizleme — tip bazlı cooldown
	if is_fused and fusion_type == "phantom":
		hit_subjects.erase(subject)  # anında geçer
	elif can_pierce:
		await get_tree().create_timer(0.18).timeout
		if subject in hit_subjects:
			hit_subjects.erase(subject)
	else:
		await get_tree().create_timer(0.5).timeout
		if subject in hit_subjects:
			hit_subjects.erase(subject)

func _split() -> void:
	var ball_scene_local = load("res://ball.tscn")
	var directions = [
		move_direction.rotated(deg_to_rad(30)),
		move_direction.rotated(deg_to_rad(-30))
	]
	for dir in directions:
		var new_ball = ball_scene_local.instantiate()
		new_ball.has_split = true
		new_ball.can_split = false
		new_ball.can_electric = false
		new_ball.can_pierce = false
		new_ball.can_cryo = false
		new_ball.can_glitch = false
		new_ball.can_water = false
		new_ball.is_mimic = false
		
		if is_fused and fusion_type == "firework":
			new_ball.can_fire = true
			new_ball.is_fused = true
			new_ball.has_fused = true
			new_ball.fusion_type = "firework_piece"
			new_ball.max_damage = 4
		elif is_fused and fusion_type == "wet_split":
			new_ball.can_water = true
			new_ball.is_fused = true
			new_ball.has_fused = true
			new_ball.fusion_type = "wet_split_piece"
			new_ball.max_damage = 3
		else:
			new_ball.can_fire = false
			new_ball.is_fused = false
			new_ball.has_fused = true
			new_ball.max_damage = 5
			
		get_parent().add_child(new_ball)
		new_ball.global_position = global_position
		new_ball.launch(dir)

func _electric_blast() -> void:
	var subjects = get_tree().get_nodes_in_group("subjects")
	for z in subjects:
		if z in hit_subjects:
			continue
		if global_position.distance_to(z.global_position) < 150:
			z.take_damage(5)

# ─────────────────────────────────────────────
# CYBERPUNK TRAIL SYSTEM
# ─────────────────────────────────────────────

func _setup_trail() -> void:
	trail = Line2D.new()
	# top_level=true: does not inherit parent transform, drawn in world coordinates
	trail.top_level = true
	trail.z_index = 1
	trail.width = 10.0
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode   = Line2D.LINE_CAP_ROUND
	trail.joint_mode     = Line2D.LINE_JOINT_ROUND

	# Width curve: from tail (0 = thin) to head (1 = thick)
	var wc := Curve.new()
	wc.add_point(Vector2(0.0, 0.04))
	wc.add_point(Vector2(0.55, 0.28))
	wc.add_point(Vector2(1.0, 1.0))
	trail.width_curve = wc

	# Color gradient: tail transparent → head HDR bright
	var grad := Gradient.new()
	grad.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	grad.set_color(1, _get_trail_color())
	trail.gradient = grad

	trail.visible = false
	add_child(trail)

func _get_trail_color() -> Color:
	# HDR values (>1.0) → trigger bloom with WorldEnvironment Glow
	if is_fused:
		return Color(2.5, 2.0, 4.5, 0.9)
	elif can_electric:
		return Color(0.4, 1.8, 4.5, 0.9)
	elif can_pierce:
		return Color(4.5, 3.5, 0.2, 0.9)
	elif can_split:
		return Color(4.5, 0.4, 0.3, 0.9)
	elif can_cryo:
		return Color(0.4, 2.5, 4.5, 0.9)
	elif can_glitch:
		return Color(3.5, 0.2, 4.0, 0.9)
	elif can_water:
		return Color(0.2, 1.5, 4.5, 0.9)
	elif can_fire:
		return Color(4.5, 2.0, 0.2, 0.9)
	elif can_leech:
		return Color(0.2, 4.0, 0.5, 0.9)
	elif is_mimic:
		# RGB shift effect (different color each frame)
		var t := Time.get_ticks_msec() / 500.0
		return Color(
			(sin(t)          + 1.5) * 1.5,
			(sin(t + 2.094)  + 1.5) * 1.5,
			(sin(t + 4.189)  + 1.5) * 1.5,
			0.9
		)
	return Color(2.0, 2.0, 2.5, 0.9)  # Normal ball: cool white HDR

func _update_modulate() -> void:
	# CanvasItem.modulate > 1.0 → HDR → Glow bloom'u tetikler
	if is_fused:
		modulate = Color(2.0, 1.8, 4.0)
	elif can_electric:
		modulate = Color(0.5, 1.5, 4.0)
	elif can_pierce:
		modulate = Color(4.0, 3.0, 0.2)
	elif can_split:
		modulate = Color(4.0, 0.5, 0.3)
	elif can_cryo:
		modulate = Color(0.5, 2.0, 4.0)
	elif can_glitch:
		modulate = Color(3.0, 0.2, 3.5)
	elif can_water:
		modulate = Color(0.2, 1.5, 4.0)
	elif can_fire:
		modulate = Color(4.0, 2.0, 0.2)
	elif can_leech:
		modulate = Color(0.2, 3.5, 0.5)
	else:
		modulate = Color(1.8, 1.8, 2.2)

func _update_trail_color() -> void:
	if is_instance_valid(trail) and trail.gradient != null:
		trail.gradient.set_color(1, _get_trail_color())

func _update_trail(_delta: float) -> void:
	if not is_instance_valid(trail):
		return

	# Dynamically update gradient color for Mimic & copied balls
	if is_mimic or mimic_done:
		_update_trail_color()

	if state == "flying" or state == "returning":
		trail_positions.append(global_position)
		if trail_positions.size() > trail_max_length:
			trail_positions.pop_front()
		trail.points = PackedVector2Array(trail_positions)
		if not trail.visible:
			trail.visible = true
	else:
		# Orbiting / durmuş — trail yavaşça söner
		if trail_positions.size() > 0:
			trail_positions.pop_front()
			trail.points = PackedVector2Array(trail_positions)
			if trail_positions.is_empty():
				trail.visible = false
