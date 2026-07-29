extends "res://ranged_enemy.gd"

func _ready() -> void:
	speed = 42.0
	original_speed = 60.0
	health = 23
	max_health = 23
	score_value = 5
	enemy_type = "cyber_shooter"
	shoot_interval = 3.0
	super._ready()

func get_sprite() -> AnimatedSprite2D:
	return $ShooterSprite

func _get_died_anim_base() -> String:
	return "res://assets/enemys/cyberShooter/animations/died/"

func _get_died_frame_count() -> int:
	return 7

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
	_add_died_anims(frames)
	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.85, 0.85)
	sprite.play("idle_S")

func _update_anim(moving: bool) -> void:
	var sprite: AnimatedSprite2D = $ShooterSprite
	var anim: String = ("walk_" if moving else "idle_") + _anim_dir
	if sprite.animation != anim: sprite.play(anim)

func _shoot(target: Node2D) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.bullet_type = "smg"
	get_parent().add_child(bullet)
	bullet.launch((target.global_position - global_position).normalized())

func _enemy_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null: return
	var dist = global_position.distance_to(player.global_position)
	var moving: bool = dist > 340
	if moving:
		velocity = (player.global_position - global_position).normalized() * speed
		_update_anim_dir(velocity)
	else:
		velocity = Vector2.ZERO
		var to_player = (player.global_position - global_position).normalized()
		_update_anim_dir(to_player)
	move_and_slide()
	_update_anim(moving)
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		if is_glitched:
			var subjects = get_tree().get_nodes_in_group("subjects")
			var closest = null
			var closest_dist = 999999.0
			for z in subjects:
				if z == self: continue
				var d = global_position.distance_to(z.global_position)
				if d < closest_dist:
					closest_dist = d
					closest = z
			if closest: _shoot(closest)
		else:
			_shoot(player)
	if dist < 35:
		player.take_damage(1)
