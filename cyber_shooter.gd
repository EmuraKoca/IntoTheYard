extends CharacterBody2D

var speed = 42.0
var health = 15
var is_dead = false
var is_frozen = false
var is_slowed = false
var is_glitched = false
var _chip_t:    float  = 0.0
var _chip_node: Node2D = null
var is_wet = false
var is_burning = false
var original_speed = 60.0
var shoot_timer = 0.0
var shoot_interval = 3.0
var is_electrified = false
var max_health = 15
var _elem_indicator = null
var attack_cooldown = 0.0
var attack_rate = 1.0

var bullet_scene = preload("res://bullet.tscn")

# Animasyon
var _anim_dir: String = "S"

func _ready() -> void:
	z_index = 2
	_setup_sprite()
	_setup_element_indicator(-72.0)
	_chip_node = Node2D.new()
	_chip_node.z_as_relative = false
	_chip_node.z_index = 10
	add_child(_chip_node)
	_chip_node.draw.connect(_draw_chip)

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $ShooterSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base := "res://assets/enemys/cyberShooter/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]

	for d in dirs:
		var dd: String = str(d)
		var walk_key: String = "walk_" + dd
		var walk_tex: Texture2D = load(base + "cybershooter_walk_" + dd + ".png")
		frames.add_animation(walk_key)
		frames.set_animation_speed(walk_key, 10.0)
		frames.set_animation_loop(walk_key, true)
		for i in range(6):
			var atlas := AtlasTexture.new()
			atlas.atlas  = walk_tex
			atlas.region = Rect2(i * 128, 0, 128, 128)
			frames.add_frame(walk_key, atlas)
		var idle_key: String = "idle_" + dd
		var idle_tex: Texture2D = load(base + "cybershooter_idle_" + dd + ".png")
		frames.add_animation(idle_key)
		frames.set_animation_speed(idle_key, 2.0)
		frames.set_animation_loop(idle_key, true)
		for i in range(2):
			var atlas := AtlasTexture.new()
			atlas.atlas  = idle_tex
			atlas.region = Rect2(i * 128, 0, 128, 128)
			frames.add_frame(idle_key, atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.85, 0.85)
	sprite.play("idle_S")

func _update_anim_dir(vel: Vector2) -> void:
	if vel == Vector2.ZERO:
		return
	var deg := rad_to_deg(vel.angle())
	if   deg > -22.5  and deg <= 22.5:   _anim_dir = "E"
	elif deg > 22.5   and deg <= 67.5:   _anim_dir = "SE"
	elif deg > 67.5   and deg <= 112.5:  _anim_dir = "S"
	elif deg > 112.5  and deg <= 157.5:  _anim_dir = "SW"
	elif deg > 157.5  or  deg <= -157.5: _anim_dir = "W"
	elif deg > -157.5 and deg <= -112.5: _anim_dir = "NW"
	elif deg > -112.5 and deg <= -67.5:  _anim_dir = "N"
	elif deg > -67.5  and deg <= -22.5:  _anim_dir = "NE"

func _update_anim(moving: bool) -> void:
	var sprite: AnimatedSprite2D = $ShooterSprite
	var anim: String = ("walk_" if moving else "idle_") + _anim_dir
	if sprite.animation != anim:
		sprite.play(anim)

func _physics_process(delta: float) -> void:
	if is_in_group("allies"):
		_ally_behavior()
		return
	if not is_dead:
		_chip_t += delta
		_chip_node.queue_redraw()
	if is_frozen:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)
	var moving: bool = dist > 340

	if moving:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		_update_anim_dir(velocity)
	else:
		velocity = Vector2.ZERO
		var to_player = (player.global_position - global_position).normalized()
		_update_anim_dir(to_player)
	move_and_slide()
	_update_anim(moving)

	# Ateş
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		if is_glitched:
			var subjects = get_tree().get_nodes_in_group("subjects")
			var closest = null
			var glitch_closest_dist = 999999.0
			for z in subjects:
				if z == self:
					continue
				var d = global_position.distance_to(z.global_position)
				if d < glitch_closest_dist:
					glitch_closest_dist = d
					closest = z
			if closest:
				_shoot(closest)
		else:
			_shoot(player)

	if dist < 35:
		player.take_damage(1)

func _shoot(target: Node2D) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	var dir = (target.global_position - global_position).normalized()
	get_parent().add_child(bullet)
	bullet.launch(dir)

func take_damage(amount, from_ally: bool = false) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	if is_in_group("allies"):
		set_physics_process(false)
		$CollisionShape2D.set_deferred("disabled", true)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)
		await get_tree().create_timer(1.0).timeout
		queue_free()
		return
	var game = get_parent()
	if game.has_method("subject_died"):
		game.subject_died(5, global_position)
	_collapse()

func _collapse() -> void:
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(0.4).timeout
	if randf() < 0.10:
		_become_ally()
	else:
		_escape()

func apply_slow(amount, duration: float = 3.0) -> void:
	if is_slowed:
		return
	is_slowed = true
	original_speed = speed
	speed = speed * (1.0 - amount)
	_set_element("slow")
	await get_tree().create_timer(duration).timeout
	if not is_instance_valid(self):
		return
	speed = original_speed
	is_slowed = false
	_clear_element()

func apply_frozen() -> void:
	is_frozen = true
	is_wet = false
	_set_element("frozen")
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	is_frozen = false
	_clear_element()

func apply_wet() -> void:
	is_wet = true
	_set_element("wet")
	await get_tree().create_timer(5.0).timeout
	if not is_instance_valid(self):
		return
	is_wet = false
	_clear_element()

func apply_glitch() -> void:
	if is_glitched:
		return
	is_glitched = true
	_set_element("glitch")
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	is_glitched = false
	_clear_element()

func apply_electrified() -> void:
	if is_electrified:
		return
	is_electrified = true
	_set_element("electrified")
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		is_electrified = false
		_clear_element()

func apply_burn() -> void:
	if is_burning:
		return
	is_burning = true
	_set_element("burn")
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self) and health > 0:
			health -= 2
			if health <= 0:
				die()
	if not is_instance_valid(self):
		return
	is_burning = false
	_clear_element()

func _escape() -> void:
	if randf() < 0.3:
		var escape_dialogs = [
			"Hasmen... what have you done to us.",
			"I'm out of this, man.",
			"Mommyyy!"
		]
		var dialog = escape_dialogs[randi() % escape_dialogs.size()]
		var game = get_parent()
		if game.has_method("show_dialog"):
			game.show_dialog(dialog, global_position)
	var nav_speed: float = max(speed * 4.5, 200.0)
	var se_target: Vector2 = Vector2(global_position.x + 200.0, 900.0)
	var e_target:  Vector2 = Vector2(2000.0, 900.0)
	$ShooterSprite.play("walk_SE")
	var tween = create_tween()
	tween.tween_property(self, "global_position", se_target,
		global_position.distance_to(se_target) / nav_speed)
	await get_tree().create_timer(
		global_position.distance_to(se_target) / nav_speed).timeout
	if not is_instance_valid(self): return
	$ShooterSprite.play("walk_E")
	var tween2 = create_tween()
	tween2.tween_property(self, "global_position", e_target,
		global_position.distance_to(e_target) / nav_speed)
	await get_tree().create_timer(
		global_position.distance_to(e_target) / nav_speed).timeout
	if is_instance_valid(self): queue_free()

func _become_ally() -> void:
	if randf() < 0.3:
		var ally_dialogs = [
			"Vec, we're with you brother!",
			"Hasmen you rat, I'll finish these and come for you.",
			"Leila, I'd never leave you alone."
		]
		var dialog = ally_dialogs[randi() % ally_dialogs.size()]
		var game = get_parent()
		if game.has_method("show_dialog"):
			game.show_dialog(dialog, global_position)

	health = max_health * 0.25
	add_to_group("allies")
	remove_from_group("subjects")
	if is_instance_valid(_chip_node): _chip_node.queue_redraw()
	_clear_element()
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	scale    = Vector2(1.0, 1.0)

	# First run to the tribune gate
	var tween = create_tween()
	tween.tween_property(self, "global_position", Vector2(850, 1000), 1.5)
	await get_tree().create_timer(1.5).timeout

	# Then move to the living area
	var tween2 = create_tween()
	tween2.tween_property(self, "global_position", Vector2(490, 1000), 1.0)
	await get_tree().create_timer(1.0).timeout

	set_physics_process(true)
	$CollisionShape2D.disabled = false

func _ally_behavior() -> void:
	var subjects = get_tree().get_nodes_in_group("subjects")
	var closest = null
	var closest_dist = INF
	for z in subjects:
		var d = global_position.distance_to(z.global_position)
		if d < 200 and d < closest_dist:
			closest_dist = d
			closest = z
	if closest != null:
		var direction = (closest.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		if closest_dist < 60:
			attack_cooldown -= get_physics_process_delta_time()
			if attack_cooldown <= 0:
				closest.take_damage(5)
				attack_cooldown = attack_rate
	else:
		velocity = Vector2.ZERO

func _setup_element_indicator(y_offset: float) -> void:
	_elem_indicator = load("res://elem_indicator.gd").new()
	_elem_indicator.position = Vector2(0, y_offset)
	_elem_indicator.visible = false
	add_child(_elem_indicator)

func _set_element(elem: String) -> void:
	if _elem_indicator != null:
		_elem_indicator.set_element(elem)

func _clear_element() -> void:
	if _elem_indicator != null:
		_elem_indicator.clear_element()

func _draw_chip() -> void:
	if is_dead or is_in_group("allies"):
		return
	# Vücuda yayılmış elektrik kıvılcımları (sarı-turuncu + mor)
	var t := _chip_t
	var anchors := [
		Vector2(-7.0, -22.0), Vector2( 7.0, -19.0),
		Vector2(-5.0,  -8.0), Vector2( 6.0,  -5.0),
		Vector2(-4.0,   6.0), Vector2( 5.0,   9.0),
	]
	for i in anchors.size():
		var flicker: float = (sin(t * (14.0 + i * 6.7) + i * 1.3) + 1.0) * 0.5
		if flicker < 0.30:
			continue
		var p: Vector2  = anchors[i]
		var ex: float   = sin(t * (9.0 + i * 3.1) + i) * 6.5
		var ey: float   = cos(t * (7.0 + i * 2.5) + i) * 5.5
		var a:  float   = flicker * 0.95
		# Sarı-turuncu ana kıvılcım (kalın)
		_chip_node.draw_line(p, p + Vector2(ex, ey),
				Color(1.0, 1.0, 0.35, a), 2.2)
		# Mor parıltı — aynı yol üzerine bindirilmiş
		_chip_node.draw_line(p, p + Vector2(ex, ey),
				Color(0.75, 0.1, 1.0, a * 0.55), 1.2)
		# Sarı-turuncu ikinci segment
		var ex2: float = ex + sin(t * 11.0 + i) * 3.5
		var ey2: float = ey + 2.5
		_chip_node.draw_line(p + Vector2(ex, ey),
				p + Vector2(ex2, ey2),
				Color(1.0, 0.85, 0.1, a * 0.70), 1.8)
		# Mor ikinci segment
		_chip_node.draw_line(p + Vector2(ex, ey),
				p + Vector2(ex2, ey2),
				Color(0.6, 0.0, 1.0, a * 0.40), 1.0)
