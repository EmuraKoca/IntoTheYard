extends CharacterBody2D

var speed = 49.0
var health = 12
var is_dead = false
var is_frozen = false
var is_slowed = false
var is_glitched = false
var is_wet = false
var is_burning = false
var original_speed = 70.0
var shoot_timer = 0.0
var shoot_interval = 3.0
var is_electrified = false
var max_health = 12
var attack_cooldown = 0.0
var attack_rate = 1.0

var bullet_scene = preload("res://bullet.tscn")

# Animasyon
var _anim_dir: String = "S"

func _ready() -> void:
	z_index = 2
	_setup_sprite()

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $RifleSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base := "res://assets/enemys/cyberRifle/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]

	for d in dirs:
		var dd: String = str(d)
		var walk_key: String = "walk_" + dd
		var walk_tex: Texture2D = load(base + "cyberrifle_walk_" + dd + ".png")
		frames.add_animation(walk_key)
		frames.set_animation_speed(walk_key, 10.0)
		frames.set_animation_loop(walk_key, true)
		for i in range(6):
			var atlas := AtlasTexture.new()
			atlas.atlas  = walk_tex
			atlas.region = Rect2(i * 124, 0, 124, 124)
			frames.add_frame(walk_key, atlas)
		var idle_key: String = "idle_" + dd
		var idle_tex: Texture2D = load(base + "cyberrifle_idle_" + dd + ".png")
		frames.add_animation(idle_key)
		frames.set_animation_speed(idle_key, 2.0)
		frames.set_animation_loop(idle_key, true)
		for i in range(2):
			var atlas := AtlasTexture.new()
			atlas.atlas  = idle_tex
			atlas.region = Rect2(i * 124, 0, 124, 124)
			frames.add_frame(idle_key, atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.88, 0.88)
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
	var sprite: AnimatedSprite2D = $RifleSprite
	var anim: String = ("walk_" if moving else "idle_") + _anim_dir
	if sprite.animation != anim:
		sprite.play(anim)

func _physics_process(delta: float) -> void:
	if is_in_group("allies"):
		_ally_behavior()
		return
	if is_frozen:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)
	var moving: bool = dist > 420

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

	# Fire
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
	var dir = (target.global_position - global_position).normalized()
	# 5 mermi art arda
	for i in range(5):
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		get_parent().add_child(bullet)
		bullet.launch(dir)
		await get_tree().create_timer(0.15).timeout

func take_damage(amount, from_ally: bool = false) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	if is_in_group("allies"):
		set_physics_process(false)
		$CollisionShape2D.disabled = true
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)
		await get_tree().create_timer(1.0).timeout
		queue_free()
		return
	var game = get_parent()
	if game.has_method("subject_died"):
		game.subject_died()
	_collapse()

func _collapse() -> void:
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.8, 0.3), 0.3)
	await get_tree().create_timer(1.0).timeout
	if randf() < 0.60:
		_become_ally()
	else:
		_escape()

func apply_slow(amount) -> void:
	if is_slowed:
		return
	is_slowed = true
	original_speed = speed
	speed = speed * (1.0 - amount)
	modulate = Color(0.7, 0.9, 1.0)
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	speed = original_speed
	is_slowed = false
	modulate = Color(1, 1, 1)

func apply_frozen() -> void:
	is_frozen = true
	is_wet = false
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.5, 0.8, 1.0), 0.2)
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	is_frozen = false
	modulate = Color(1, 1, 1)

func apply_wet() -> void:
	is_wet = true
	modulate = Color(0.3, 0.6, 1.0)
	await get_tree().create_timer(5.0).timeout
	if not is_instance_valid(self):
		return
	is_wet = false
	modulate = Color(1, 1, 1)

func apply_glitch() -> void:
	if is_glitched:
		return
	is_glitched = true
	modulate = Color(0.8, 0.2, 1.0)
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	is_glitched = false
	modulate = Color(1, 1, 1)

func apply_electrified() -> void:
	if is_electrified:
		return
	is_electrified = true
	modulate = Color(0.8, 1.0, 0.2)
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		is_electrified = false
		modulate = Color(1, 1, 1)

func apply_burn() -> void:
	if is_burning:
		return
	is_burning = true
	modulate = Color(1.0, 0.4, 0.1)
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self) and health > 0:
			health -= 2
			if health <= 0:
				die()
	if not is_instance_valid(self):
		return
	is_burning = false
	modulate = Color(1, 1, 1)

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
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(1700, 1100), 1.0)
	await get_tree().create_timer(1.0).timeout
	queue_free()

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
	modulate = Color(0.2, 1.0, 0.4)

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
