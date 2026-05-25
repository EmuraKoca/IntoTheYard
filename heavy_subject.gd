extends CharacterBody2D

var speed = 45.0
var health = 30
var max_health = 30
var is_dead = false
var original_speed = 0.0
var is_slowed = false
var is_glitched = false
var is_wet = false
var is_frozen = false
var is_burning = false
var attack_cooldown = 0.0
var attack_rate = 1.0
var is_electrified = false
var chip_duration = 15.0  # Ally chip charge duration — upgradeable via card
var _ally_timer = 0.0
var _is_exiting = false
var _reached_living_area: bool = false
var _wander_timer: float = 0.0
var _wander_velocity: Vector2 = Vector2.ZERO

func take_damage(amount) -> void:
	health -= amount
	if health <= 0:
		die()

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
	is_burning = false
	modulate = Color(1, 1, 1)

func apply_frozen() -> void:
	is_frozen = true
	is_wet = false
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.5, 0.8, 1.0), 0.2)
	await get_tree().create_timer(3.0).timeout
	is_frozen = false
	modulate = Color(1, 1, 1)

func apply_wet() -> void:
	is_wet = true
	modulate = Color(0.3, 0.6, 1.0)
	await get_tree().create_timer(5.0).timeout
	is_wet = false
	modulate = Color(1, 1, 1)

func apply_glitch() -> void:
	if is_glitched:
		return
	is_glitched = true
	modulate = Color(0.8, 0.2, 1.0)
	await get_tree().create_timer(3.0).timeout
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

func apply_slow(amount) -> void:
	if is_slowed:
		return
	is_slowed = true
	original_speed = speed
	speed = speed * (1.0 - amount)
	modulate = Color(0.7, 0.9, 1.0)
	await get_tree().create_timer(3.0).timeout
	speed = original_speed
	is_slowed = false
	modulate = Color(1, 1, 1)

func _ready() -> void:
	z_index = 2

func _physics_process(delta: float) -> void:
	if is_in_group("allies"):
		_ally_behavior()
		return
	if is_frozen:
		return
	var target
	if is_glitched:
		# Attack nearby subject
		var subjects = get_tree().get_nodes_in_group("subjects")
		var closest = null
		var closest_dist = 999999.0
		for z in subjects:
			if z == self:
				continue
			var d = global_position.distance_to(z.global_position)
			if d < closest_dist:
				closest_dist = d
				closest = z
		target = closest
	else:
		# Enemies focus only on the player — allies are never targeted
		var player = get_tree().get_first_node_in_group("player")
		target = player

		if target == null:
			return
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	var dist = global_position.distance_to(target.global_position)
	if dist < 60:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			if is_glitched:
				target.take_damage(3)
			else:
				target.take_damage(8)
			attack_cooldown = attack_rate

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
	var game = get_parent()
	if randf() < 0.3:
		var ally_dialogs = [
			"Vec, we're with you brother!",
			"Hasmen you rat, I'll finish these and come for you.",
			"Leila, I'd never leave you alone."
		]
		var dialog = ally_dialogs[randi() % ally_dialogs.size()]
		if game.has_method("show_dialog"):
			game.show_dialog(dialog, global_position)

	add_to_group("allies")
	remove_from_group("subjects")
	modulate = Color(0.2, 1.0, 0.4)
	# Use game-level chip duration if available (respects Chip Boost upgrade)
	_ally_timer = game.ally_chip_duration if "ally_chip_duration" in game else chip_duration
	_is_exiting = false
	_reached_living_area = false
	_wander_timer = 0.0

	# Re-enable physics — ally immediately heads to living area
	set_physics_process(true)
	$CollisionShape2D.disabled = false

func _start_exit() -> void:
	_is_exiting = true
	set_physics_process(false)
	$CollisionShape2D.disabled = true

	# If somehow still in the game field, push through the tribune first
	if global_position.x > 490.0:
		var gate_pos = Vector2(870, clamp(global_position.y, 300, 900))
		var step1_time = clamp(global_position.distance_to(gate_pos) / (speed * 2.0), 0.3, 2.0)
		var tween = create_tween()
		tween.tween_property(self, "global_position", gate_pos, step1_time)
		await tween.finished
		if not is_instance_valid(self):
			return
		var tween2 = create_tween()
		tween2.tween_property(self, "global_position", Vector2(350, gate_pos.y), 1.0)
		await tween2.finished
		if not is_instance_valid(self):
			return

	# Run off-screen to the left at a brisk pace
	var exit_speed = max(speed * 2.5, 180.0)
	var exit_time = (global_position.x + 200.0) / exit_speed
	var tween_exit = create_tween()
	tween_exit.tween_property(self, "global_position", Vector2(-200, global_position.y), exit_time)
	await tween_exit.finished
	if is_instance_valid(self):
		queue_free()

func _ally_behavior() -> void:
	var delta = get_physics_process_delta_time()

	if _is_exiting:
		return

	# Count down the chip duration, then exit
	_ally_timer -= delta
	if _ally_timer <= 0.0:
		_start_exit()
		return

	# Phase 1: Navigate to the living area (left of the tribune) at full enemy speed
	if not _reached_living_area:
		if global_position.x > 870.0:
			# Still in game field — head toward tribune gate
			velocity = (Vector2(870, global_position.y) - global_position).normalized() * speed
		elif global_position.x > 490.0:
			# In the tribune — push straight left
			velocity = Vector2(-speed, 0)
		else:
			# Arrived in living area
			_reached_living_area = true
			_wander_timer = 0.0
			velocity = Vector2.ZERO
		move_and_slide()
		return

	# Phase 2: In living area — attack nearby enemies or wander upward
	var subjects = get_tree().get_nodes_in_group("subjects")
	var closest = null
	var closest_dist = INF
	for s in subjects:
		var d = global_position.distance_to(s.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = s

	if closest != null and closest_dist < 400.0:
		# Chase and attack
		if closest_dist > 60.0:
			var direction = (closest.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			attack_cooldown -= delta
			if attack_cooldown <= 0:
				closest.take_damage(5)
				attack_cooldown = attack_rate
	else:
		# No enemies — wander upward toward the upper street
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_wander_timer = randf_range(1.5, 3.0)
			_wander_velocity = Vector2(randf_range(-speed * 0.4, speed * 0.4), -speed * 0.7)
		# Clamp to living area bounds
		if global_position.y < 150.0:
			_wander_velocity.y = abs(_wander_velocity.y)
		if global_position.x < 50.0:
			_wander_velocity.x = abs(_wander_velocity.x)
		elif global_position.x > 470.0:
			_wander_velocity.x = -abs(_wander_velocity.x)
		velocity = _wander_velocity
		move_and_slide()
