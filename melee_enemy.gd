extends "res://base_enemy.gd"

var _ally_timer: float = 0.0
var _is_exiting: bool = false
var _reached_living_area: bool = false
var _wander_timer: float = 0.0
var _wander_velocity: Vector2 = Vector2.ZERO
var _killed_by_ally: bool = false

func _on_lethal_damage(from_ally: bool) -> void:
	_killed_by_ally = from_ally

func _on_became_ally() -> void:
	_is_exiting = false
	_reached_living_area = true
	_wander_timer = 0.0

func take_damage(amount, from_ally: bool = false) -> void:
	health -= amount
	if is_electrified and not from_ally:
		var p := _get_player()
		if p and p.get("has_static_charge") and p.has_static_charge:
			for body in get_tree().get_nodes_in_group("subjects"):
				if body != self and is_instance_valid(body) and body.get("is_electrified") and body.is_electrified:
					if global_position.distance_to(body.global_position) < 150.0:
						body.health -= int(amount * 0.4)
						if body.health <= 0: body.die()
	if health <= 0:
		_killed_by_ally = from_ally
		die()

func _collapse() -> void:
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(0.4).timeout

	if _killed_by_ally:
		var tween2 = create_tween()
		tween2.tween_property(self, "global_position", Vector2(-200, global_position.y), 1.5)
		await tween2.finished
		if is_instance_valid(self): queue_free()
		return

	if randf() < 0.01:
		_become_ally()
	else:
		_escape()

func _start_exit() -> void:
	_is_exiting = true
	set_physics_process(false)
	var nav_speed = max(speed * 3.0, 200.0)
	var exit_time = (global_position.x + 200.0) / nav_speed
	var tween = create_tween()
	tween.tween_property(self, "global_position", Vector2(-200, global_position.y), exit_time)
	tween.tween_callback(queue_free)

func _ally_behavior() -> void:
	var delta = get_physics_process_delta_time()
	if _is_exiting: return
	if not _reached_living_area: return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 3.5)
		_wander_velocity = Vector2(randf_range(-speed * 0.6, speed * 0.6), randf_range(-speed * 0.5, speed * 0.5))
	if global_position.x < 80.0: _wander_velocity.x = abs(_wander_velocity.x)
	elif global_position.x > 750.0: _wander_velocity.x = -abs(_wander_velocity.x)
	if global_position.y < 700.0: _wander_velocity.y = abs(_wander_velocity.y)
	elif global_position.y > 1050.0: _wander_velocity.y = -abs(_wander_velocity.y)
	velocity = _wander_velocity
	move_and_slide()
	_update_anim_dir_from_velocity()
	_update_walk_anim()
