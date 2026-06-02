extends CharacterBody2D

var armor = 90
var health = 90
var max_armor = 90
var max_health = 90
var is_dead = false
var is_frozen = false
var is_slowed = false
var is_glitched = false
var is_wet = false
var is_burning = false
var is_stunned = false
var original_speed = 120.0
var speed = 120.0
var keep_distance = 500.0
var chain_anchor = Vector2(1240, 500)
var chain_length = 300.0
var shotgun_timer = 0.0
var missile_timer = 0.0
var shockwave_timer = 0.0
var random_weapon_timer = 0.0
var is_electrified = false

var bullet_scene = preload("res://bullet.tscn")
var missile_scene = preload("res://missile.tscn")

func _ready() -> void:
	z_index = 3
	add_to_group("subjects")
	scale = Vector2(0.1, 0.1)
	_setup_sprite()
	await get_tree().process_frame
	var game = get_parent()
	if game.has_method("show_boss_bar"):
		game.show_boss_bar(self)

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $Boss404Sprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	# Walk animasyonu (sheet'ten)
	var base := "res://assets/enemys/cyber404/sheets/"
	var tex: Texture2D = load(base + "cyber404_walk_S.png")
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 8.0)
	frames.set_animation_loop("walk", true)
	for i in range(6):
		var atlas := AtlasTexture.new()
		atlas.atlas  = tex
		atlas.region = Rect2(i * 252, 0, 252, 252)
		frames.add_frame("walk", atlas)

	# Death animasyonu (tek tek frame'ler)
	var death_base := "res://assets/enemys/cyber404/animations/death/"
	frames.add_animation("death")
	frames.set_animation_speed("death", 10.0)
	frames.set_animation_loop("death", false)
	for i in range(9):
		var t: Texture2D = load(death_base + "frame_%03d.png" % i)
		frames.add_frame("death", t)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.7, 0.7)
	sprite.play("walk")

func _landing_wave() -> void:
	var subjects = get_tree().get_nodes_in_group("subjects")
	for z in subjects:
		if z != self and is_instance_valid(z):
			z.queue_free()

func _physics_process(delta: float) -> void:
	if is_frozen or is_stunned or is_dead:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > keep_distance:
		var diff = player.global_position - global_position
		if abs(diff.x) > abs(diff.y):
			velocity = Vector2(sign(diff.x) * speed, 0)
		else:
			velocity = Vector2(0, sign(diff.y) * speed)
	elif dist < keep_distance - 50:
		var diff = global_position - player.global_position
		if abs(diff.x) > abs(diff.y):
			velocity = Vector2(sign(diff.x) * speed, 0)
		else:
			velocity = Vector2(0, sign(diff.y) * speed)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Chain constraint
	var dist_to_anchor = global_position.distance_to(chain_anchor)
	if dist_to_anchor > chain_length:
		var dir_to_anchor = (chain_anchor - global_position).normalized()
		global_position = chain_anchor - dir_to_anchor * chain_length

	shotgun_timer += delta
	missile_timer += delta
	shockwave_timer += delta
	random_weapon_timer += delta

	if shotgun_timer >= 9.0:
		shotgun_timer = 0.0
		_shotgun_burst(player)

	if missile_timer >= 15.0:
		missile_timer = 0.0
		_launch_missile(player)

	if shockwave_timer >= 30.0 and armor > 0:
		shockwave_timer = 0.0
		_shockwave()

	if random_weapon_timer >= randf_range(4.0, 8.0):
		random_weapon_timer = 0.0
		_random_weapon(player)

func _shotgun_burst(_player: Node2D) -> void:
	for burst in range(5):
		for i in range(8):
			var angle = i * TAU / 8
			var base_dir = Vector2(cos(angle), sin(angle))
			for j in range(3):
				var bullet = bullet_scene.instantiate()
				bullet.global_position = global_position
				var spread = deg_to_rad(-10 + j * 10)
				get_parent().add_child(bullet)
				bullet.launch(base_dir.rotated(spread))
		await get_tree().create_timer(0.3).timeout

func _launch_missile(player: Node2D) -> void:
	var missile = missile_scene.instantiate()
	missile.global_position = global_position
	missile.target = player
	get_parent().add_child(missile)

func _shockwave() -> void:
	is_stunned = true
	for i in range(3):
		await get_tree().create_timer(1.5).timeout
		var game = get_parent()
		if game.has_method("boss_shockwave"):
			game.boss_shockwave(global_position, (i + 1) * 150)
	is_stunned = false

func _random_weapon(player: Node2D) -> void:
	var dir = (player.global_position - global_position).normalized()
	var choice = randi() % 3
	match choice:
		0:
			var bullet = bullet_scene.instantiate()
			bullet.global_position = global_position
			get_parent().add_child(bullet)
			bullet.launch(dir)
		1:
			for i in range(7):
				var bullet = bullet_scene.instantiate()
				bullet.global_position = global_position
				var angle = deg_to_rad(-30 + i * 10)
				get_parent().add_child(bullet)
				bullet.launch(dir.rotated(angle))
		2:
			for i in range(5):
				var bullet = bullet_scene.instantiate()
				bullet.global_position = global_position
				get_parent().add_child(bullet)
				bullet.launch(dir)
				await get_tree().create_timer(0.15).timeout

func take_damage(amount) -> void:
	if armor > 0:
		armor -= amount
		if armor <= 0:
			armor = 0
			_armor_break()
	else:
		health -= amount
		if health <= 0:
			die()
	var game = get_parent()
	if game.has_method("update_boss_bar"):
		game.update_boss_bar(armor, health, max_armor, max_health)

func _armor_break() -> void:
	is_stunned = true
	var cr = get_node_or_null("ColorRect")
	if cr:
		cr.color = Color(0.8, 0.1, 0.1)
	await get_tree().create_timer(3.0).timeout
	is_stunned = false

func die() -> void:
	is_dead = true
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	var game = get_parent()
	if game.has_method("subject_died"):
		game.subject_died()
	if game.has_method("hide_boss_bar"):
		game.hide_boss_bar()
	_play_death()

func _play_death() -> void:
	var sprite: AnimatedSprite2D = $Boss404Sprite
	sprite.play("death")
	# Animasyon bitince son frame'de 1.5s bekle, sonra yok ol
	await sprite.animation_finished
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(self):
		queue_free()

func apply_slow(amount) -> void:
	if is_slowed:
		return
	is_slowed = true
	original_speed = speed
	speed = speed * (1.0 - amount)
	await get_tree().create_timer(3.0).timeout
	speed = original_speed
	is_slowed = false

func apply_frozen() -> void:
	# Boss is immune to freeze
	return

func apply_wet() -> void:
	is_wet = true
	await get_tree().create_timer(5.0).timeout
	is_wet = false

func apply_glitch() -> void:
	# Boss is immune to glitch
	return

func apply_electrified() -> void:
	if is_electrified:
		return
	is_electrified = true
	var game := get_parent()
	if game.has_method("update_boss_element"):
		game.update_boss_element("electrified")
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		is_electrified = false
		if game.has_method("clear_boss_element"):
			game.clear_boss_element()

func apply_burn() -> void:
	if is_burning:
		return
	is_burning = true
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self) and health > 0:
			health -= 2
			if health <= 0:
				die()
				return
	is_burning = false
