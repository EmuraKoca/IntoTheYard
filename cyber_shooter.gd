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

func _get_effective_death_base() -> String:
	return "res://assets/effectiveDeathAnimations/cyberShooter/"

func _get_died_frame_count() -> int:
	return 7

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $ShooterSprite
	sprite.sprite_frames = _load_monster_frames("cyberShooter", {
		"walk_": ["walk", 10.0, true],
		"idle_": ["walk", 2.0, true, 1],
		"attack_": ["attack", ATTACK_FPS, false],
	})
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(1.5, 1.5)
	sprite.play("idle_S")

func _update_anim(moving: bool) -> void:
	if _attacking: return
	var sprite: AnimatedSprite2D = $ShooterSprite
	var anim: String = ("walk_" if moving else "idle_") + _anim_dir
	if sprite.animation != anim: sprite.play(anim)

func _fire(target: Node2D) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.bullet_type = "smg"
	get_parent().add_child(bullet)
	bullet.launch((target.global_position - global_position).normalized())

func _enemy_process(delta: float) -> void:
	if is_glitched:
		_glitch_melee(delta)
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null: return
	var dist = global_position.distance_to(player.global_position)
	var moving: bool = _ranged_move(player, 340.0)
	move_and_slide()
	_update_anim(moving)
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		_shoot(player)
	if dist < 35:
		player.take_damage(1)
