extends "res://base_enemy.gd"

var shoot_timer: float = 0.0
var shoot_interval: float = 3.0
var bullet_scene = preload("res://bullet.tscn")

func _elem_indicator_y_offset() -> float:
	return -72.0

func _update_anim(_moving: bool) -> void:
	pass  # child override: walk_ veya idle_ prefix ile anim oynat


func _collapse() -> void:
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var game = get_parent()
	if game.has_method("subject_died"):
		game.subject_died(score_value, global_position)
	queue_free()

func _ally_behavior() -> void:
	var delta = get_physics_process_delta_time()
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
		_update_anim_dir(velocity)
		_update_anim(true)
		attack_cooldown -= delta
		if attack_cooldown <= 0 and closest_dist < 40:
			if closest.has_method("take_damage"): closest.take_damage(3)
			attack_cooldown = attack_rate
	else:
		velocity = Vector2.ZERO
		_update_anim(false)
