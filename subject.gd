extends CharacterBody2D

var speed = 40.0
var health = 10
var is_dead = false
var max_health = 10
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
				target.take_damage(5)
			attack_cooldown = attack_rate

func take_damage(amount) -> void:
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

	# 15% ally chance
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

	# Re-enable physics so ally can follow the player
	set_physics_process(true)
	$CollisionShape2D.disabled = false

func _start_exit() -> void:
	_is_exiting = true
	set_physics_process(false)
	$CollisionShape2D.disabled = true

	# Step 1: Move to the tribune gate (right edge of the tribune)
	var gate_pos = Vector2(870, 900)
	var step1_time = clamp(global_position.distance_to(gate_pos) / (speed * 3.0), 0.4, 2.5)
	var tween = create_tween()
	tween.tween_property(self, "global_position", gate_pos, step1_time)
	await tween.finished
	if not is_instance_valid(self):
		return

	# Step 2: Move left through the tribune
	var tween2 = create_tween()
	tween2.tween_property(self, "global_position", Vector2(490, 900), 1.2)
	await tween2.finished
	if not is_instance_valid(self):
		return

	# Step 3: Fade out as ally enters the living area
	var tween3 = create_tween()
	tween3.tween_property(self, "modulate", Color(0.2, 1.0, 0.4, 0.0), 0.6)
	tween3.parallel().tween_property(self, "global_position", Vector2(350, 900), 0.8)
	await tween3.finished
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

	# Follow the player closely during chip duration
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist > 80.0:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO
