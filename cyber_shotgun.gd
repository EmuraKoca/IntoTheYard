extends "res://ranged_enemy.gd"

func _ready() -> void:
	speed = 35.0
	original_speed = 50.0
	health = 30
	max_health = 30
	score_value = 5
	enemy_type = "cyber_shotgun"
	shoot_interval = 5.5
	super._ready()

func get_sprite() -> AnimatedSprite2D:
	return $ShotgunSprite

func _get_died_anim_base() -> String:
	return "res://assets/enemys/cyberShotgun/animations/died/"

func _get_effective_death_base() -> String:
	return "res://assets/effectiveDeathAnimations/cyberShotgun/"

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $ShotgunSprite
	sprite.sprite_frames = _load_monster_frames("cyberShotgun", {
		"walk_": ["walk", 10.0, true],
		"idle_": ["walk", 2.0, true, 1],
		"attack_": ["attack", ATTACK_FPS, false],
	})
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(1.5, 1.5)
	sprite.play("idle_S")

func _update_anim(moving: bool) -> void:
	if _attacking: return
	var sprite: AnimatedSprite2D = $ShotgunSprite
	var anim: String = ("walk_" if moving else "idle_") + _anim_dir
	if sprite.animation != anim: sprite.play(anim)

func _fire(target: Node2D) -> void:
	var dir = (target.global_position - global_position).normalized()
	for i in range(3):
		var bullet = bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.bullet_type = "shotgun"
		var spread_dir = dir.rotated(deg_to_rad(-20 + i * 20))
		get_parent().add_child(bullet)
		bullet.launch(spread_dir)

func _enemy_process(delta: float) -> void:
	if is_glitched:
		_glitch_melee(delta)
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null: return
	var dist = global_position.distance_to(player.global_position)
	var moving: bool = dist > 270
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
		_shoot(player)
	if dist < 35:
		player.take_damage(1)
