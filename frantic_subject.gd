extends "res://melee_enemy.gd"

var _kicking: bool = false

func _ready() -> void:
	speed = 110.0
	health = 12
	max_health = 12
	score_value = 3
	enemy_type = "frantic_subject"
	super._ready()

func get_sprite() -> AnimatedSprite2D:
	return $FranticSprite

func get_walk_anim_prefix() -> String:
	return "run_"

func _get_died_anim_base() -> String:
	return "res://assets/enemys/franticSubject/Top-down_pixel_art_game_sprite/animations/died/"

func _get_effective_death_base() -> String:
	return "res://assets/effectiveDeathAnimations/franticSubject/"

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $FranticSprite
	sprite.sprite_frames = _load_monster_frames("franticSubject", {
		"run_": ["walk", 12.0, true],
		"kick_": ["attack", 12.0, false],
	})
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(1.5, 1.5)
	sprite.animation_finished.connect(_on_kick_finished)
	sprite.play("run_S")

func _on_kick_finished() -> void:
	if is_dead: return
	_kicking = false
	_update_walk_anim()

func _update_walk_anim() -> void:
	if _kicking: return
	var spr := get_sprite()
	var anim := "run_" + _anim_dir
	if spr.animation != anim: spr.play(anim)

func play_kick() -> void:
	if _kicking: return
	_kicking = true
	get_sprite().play("kick_" + _anim_dir)

func _enemy_process(delta: float) -> void:
	var target
	if is_glitched:
		var subjects = get_tree().get_nodes_in_group("subjects")
		var closest = null
		var closest_dist = 999999.0
		for z in subjects:
			if z == self or not is_instance_valid(z) or z.get("is_dead"): continue
			var d = global_position.distance_to(z.global_position)
			if d < closest_dist:
				closest_dist = d
				closest = z
		target = closest
	else:
		target = get_tree().get_first_node_in_group("player")
	if target == null: return
	var dist = global_position.distance_to(target.global_position)
	if dist > 60:
		velocity = (target.global_position - global_position).normalized() * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	_update_anim_dir_from_velocity()
	_update_walk_anim()
	if dist < 60:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			if is_glitched:
				target.take_damage(3, false, "normal", true)
			else:
				target.take_damage(4)
			attack_cooldown = attack_rate
			play_kick()
