extends "res://melee_enemy.gd"

var _uppercutting: bool = false

func _ready() -> void:
	speed = 32.0
	health = 45
	max_health = 45
	enemy_armor = int(health * 0.5)
	enemy_armor_max = enemy_armor
	score_value = 3
	enemy_type = "heavy_subject"
	super._ready()
	if enemy_armor > 0:
		get_sprite().modulate = Color(0.55, 0.55, 0.55)

func get_sprite() -> AnimatedSprite2D:
	return $HeavySprite

func get_walk_anim_prefix() -> String:
	return "walk_"

func _get_died_anim_base() -> String:
	return "res://assets/enemys/heavySubject/animations/died/"

func _get_effective_death_base() -> String:
	return "res://assets/effectiveDeathAnimations/heavySubject/"

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $HeavySprite
	sprite.sprite_frames = _load_monster_frames("heavySubject", {
		"walk_": ["walk", 8.0, true],
		"uppercut_": ["attack", 8.0, false],
	})
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(1.7, 1.7)
	sprite.animation_finished.connect(_on_uppercut_finished)
	sprite.play("walk_S")

func _on_uppercut_finished() -> void:
	if is_dead: return
	_uppercutting = false
	_update_walk_anim()

func _update_walk_anim() -> void:
	if _uppercutting: return
	var spr := get_sprite()
	var anim := "walk_" + _anim_dir
	if spr.animation != anim: spr.play(anim)

func play_uppercut() -> void:
	if _uppercutting: return
	_uppercutting = true
	get_sprite().play("uppercut_" + _anim_dir)

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
				target.take_damage(8)
			attack_cooldown = attack_rate
			play_uppercut()
