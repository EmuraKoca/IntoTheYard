extends CharacterBody2D

const SURGERY_EXIT := Vector2(850, 1000)  # The only exit point from the living area

var speed = 63.0
var health = 20
var max_health = 20
var jump_timer = 0.0
var jump_interval = 2.0
var jump_direction = Vector2.ZERO
var is_dead = false
var original_speed = 0.0
var is_slowed = false
var is_glitched = false
var is_wet = false
var is_frozen = false
var is_burning = false
var _chip_t:    float   = 0.0
var _chip_node: Node2D  = null
var attack_cooldown = 0.0
var attack_rate = 1.0
var is_electrified = false
var chip_duration = 15.0  # Ally chip charge duration — upgradeable via card
var _elem_indicator = null
var _ally_timer = 0.0
var _is_exiting = false
var _reached_living_area: bool = false
var _wander_timer: float = 0.0
var _wander_velocity: Vector2 = Vector2.ZERO
var _killed_by_ally: bool = false

# Animasyon
var _anim_dir: String = "S"
var _kicking: bool = false

func apply_burn() -> void:
	if is_burning:
		return
	is_burning = true
	_set_element("burn")
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self) and health > 0:
			health -= 2
			if health <= 0:
				die()
	if not is_instance_valid(self):
		return
	is_burning = false
	_clear_element()

func apply_frozen() -> void:
	is_frozen = true
	is_wet = false
	_set_element("frozen")
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	is_frozen = false
	_clear_element()

func apply_wet() -> void:
	is_wet = true
	_set_element("wet")
	await get_tree().create_timer(5.0).timeout
	if not is_instance_valid(self):
		return
	is_wet = false
	_clear_element()

func apply_glitch() -> void:
	if is_glitched:
		return
	is_glitched = true
	_set_element("glitch")
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	is_glitched = false
	_clear_element()

func apply_electrified() -> void:
	if is_electrified:
		return
	is_electrified = true
	_set_element("electrified")
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		is_electrified = false
		_clear_element()

func apply_slow(amount) -> void:
	if is_slowed:
		return
	is_slowed = true
	original_speed = speed
	speed = speed * (1.0 - amount)
	_set_element("slow")
	await get_tree().create_timer(3.0).timeout
	if not is_instance_valid(self):
		return
	speed = original_speed
	is_slowed = false
	_clear_element()

func _ready() -> void:
	z_index = 2
	_setup_sprite()
	_setup_element_indicator(-68.0)
	_chip_node = Node2D.new()
	_chip_node.z_as_relative = false
	_chip_node.z_index = 10
	add_child(_chip_node)
	_chip_node.draw.connect(_draw_chip)

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $ArmedSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base := "res://assets/enemys/armedSubject/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]
	var anims := [["run", 8, true], ["kick", 6, false]]

	for a in anims:
		var anim_name: String = str(a[0])
		var frame_count: int  = int(a[1])
		var looping: bool     = bool(a[2])
		for d in dirs:
			var key: String = anim_name + "_" + str(d)
			var tex: Texture2D = load(base + "armed_" + anim_name + "_" + str(d) + ".png")
			frames.add_animation(key)
			frames.set_animation_speed(key, 12.0)
			frames.set_animation_loop(key, looping)
			for i in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas  = tex
				atlas.region = Rect2(i * 128, 0, 128, 128)
				frames.add_frame(key, atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.85, 0.85)
	sprite.animation_finished.connect(_on_kick_finished)
	sprite.play("run_S")

func _on_kick_finished() -> void:
	_kicking = false
	$ArmedSprite.speed_scale = 1.0
	_update_armed_anim()

func _update_armed_anim() -> void:
	if _kicking:
		return
	var sprite: AnimatedSprite2D = $ArmedSprite
	var anim := "run_" + _anim_dir
	if sprite.animation != anim:
		sprite.play(anim)

func _update_anim_dir_from_velocity() -> void:
	if velocity == Vector2.ZERO:
		return
	var angle := velocity.angle()
	var deg   := rad_to_deg(angle)
	if   deg > -22.5  and deg <= 22.5:   _anim_dir = "E"
	elif deg > 22.5   and deg <= 67.5:   _anim_dir = "SE"
	elif deg > 67.5   and deg <= 112.5:  _anim_dir = "S"
	elif deg > 112.5  and deg <= 157.5:  _anim_dir = "SW"
	elif deg > 157.5  or  deg <= -157.5: _anim_dir = "W"
	elif deg > -157.5 and deg <= -112.5: _anim_dir = "NW"
	elif deg > -112.5 and deg <= -67.5:  _anim_dir = "N"
	elif deg > -67.5  and deg <= -22.5:  _anim_dir = "NE"

func play_kick() -> void:
	if _kicking:
		return
	_kicking = true
	$ArmedSprite.play("kick_" + _anim_dir)

func _physics_process(delta: float) -> void:
	if is_in_group("allies"):
		_ally_behavior()
		return
	if not is_dead:
		_chip_t += delta
		_chip_node.queue_redraw()
	if is_frozen:
		return

	var target
	if is_glitched:
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
		target = get_tree().get_first_node_in_group("player")

	if target == null:
		return

	var dist = global_position.distance_to(target.global_position)

	if dist > 60:
		var direction = (target.global_position - global_position).normalized()
		var sprite: AnimatedSprite2D = $ArmedSprite
		var frame = sprite.frame

		# Frame 0-3: zıplama fazı — ileri atılış
		# Frame 4-7: iniş/yürüyüş fazı — normal hız
		var current_speed = speed * 2.5 if frame < 4 else speed
		velocity = direction * current_speed
		move_and_slide()
		_update_anim_dir_from_velocity()
		_update_armed_anim()
		sprite.speed_scale = 1.0
	else:
		velocity = Vector2.ZERO
		$ArmedSprite.speed_scale = 1.0
		_update_armed_anim()

	if dist < 60:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			if is_glitched:
				target.take_damage(3)
			else:
				target.take_damage(6)
			attack_cooldown = attack_rate
			play_kick()

func take_damage(amount, from_ally: bool = false) -> void:
	health -= amount
	if health <= 0:
		_killed_by_ally = from_ally
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
	await get_tree().create_timer(0.4).timeout
	# Killed by an ally — just run left, never become an ally
	if _killed_by_ally:
		var tween2 = create_tween()
		tween2.tween_property(self, "global_position", Vector2(-200, global_position.y), 1.5)
		await tween2.finished
		if is_instance_valid(self):
			queue_free()
		return

	# 60% ally chance
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
	_clear_element()
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	scale    = Vector2(1.0, 1.0)
	# Use game-level chip duration if available (respects Chip Boost upgrade)
	_ally_timer = game.ally_chip_duration if "ally_chip_duration" in game else chip_duration
	_is_exiting = false
	_reached_living_area = false
	_wander_timer = 0.0

	# Disable collision — ally moves freely through tribune walls etc.
	$CollisionShape2D.disabled = true
	set_physics_process(false)

	var nav_speed: float = max(speed * 3.0, 150.0)
	var gate:   Vector2  = Vector2(global_position.x, 1000.0)
	var door:   Vector2  = Vector2(850.0, 1000.0)
	var inside: Vector2  = Vector2(490.0, 1000.0)

	$ArmedSprite.play("walk_S")
	var tw1: Tween = create_tween()
	tw1.tween_property(self, "global_position", gate,
		max(abs(global_position.y - 1000.0) / nav_speed, 0.05))\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw1.finished
	if not is_instance_valid(self): return

	$ArmedSprite.play("walk_W")
	var tw2: Tween = create_tween()
	tw2.tween_property(self, "global_position", door,
		max(abs(global_position.x - 850.0) / nav_speed, 0.05))\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw2.finished
	if not is_instance_valid(self): return

	var tw3: Tween = create_tween()
	tw3.tween_property(self, "global_position", inside, 360.0 / nav_speed)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw3.finished
	if not is_instance_valid(self): return

	_reached_living_area = true
	_wander_timer        = 0.0
	set_physics_process(true)

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

	if _is_exiting:
		return

	if _reached_living_area:
		_ally_timer -= delta
		if _ally_timer <= 0.0:
			_start_exit()
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
			_update_anim_dir_from_velocity()
			_update_armed_anim()
		else:
			velocity = Vector2.ZERO
			attack_cooldown -= delta
			if attack_cooldown <= 0:
				closest.take_damage(5, true)
				attack_cooldown = attack_rate
				play_kick()
	else:
		# No enemies — wander upward toward the upper street
		_wander_timer -= delta
		if _wander_timer <= 0.0:
			_wander_timer = randf_range(1.5, 3.0)
			_wander_velocity = Vector2(randf_range(-speed * 0.3, speed * 0.3), -speed * 0.6)
		if global_position.y < 150.0:
			_wander_velocity.y = abs(_wander_velocity.y)
		if global_position.x < 50.0:
			_wander_velocity.x = abs(_wander_velocity.x)
		elif global_position.x > 470.0:
			_wander_velocity.x = -abs(_wander_velocity.x)
		velocity = _wander_velocity
		move_and_slide()
		_update_anim_dir_from_velocity()
		_update_armed_anim()

func _setup_element_indicator(y_offset: float) -> void:
	_elem_indicator = load("res://elem_indicator.gd").new()
	_elem_indicator.position = Vector2(0, y_offset)
	_elem_indicator.visible = false
	add_child(_elem_indicator)

func _set_element(elem: String) -> void:
	if _elem_indicator != null:
		_elem_indicator.set_element(elem)

func _clear_element() -> void:
	if _elem_indicator != null:
		_elem_indicator.clear_element()

func _draw_chip() -> void:
	if is_dead or is_in_group("allies"):
		return
	var pulse:   float = (sin(_chip_t * 6.0) + 1.0) * 0.5
	var flicker: float = (sin(_chip_t * 23.0) + 1.0) * 0.5
	# Parlak sarı nabız halkası
	var alpha:  float = 0.45 + pulse * 0.40
	var radius: float = 7.0  + pulse * 3.0
	_chip_node.draw_arc(Vector2(0.0, -16.0), radius, 0.0, TAU, 12,
			Color(1.0, 0.95, 0.15, alpha), 1.8)
	# Elektrik kıvılcımı — her yarı titremede görünür
	if flicker > 0.45:
		var sx: float = sin(_chip_t * 13.0) * 5.0
		var sy: float = -13.0 + cos(_chip_t * 9.0) * 4.0
		_chip_node.draw_line(Vector2(sx - 3.0, sy - 4.0), Vector2(sx,       sy),
				Color(1.0, 1.0, 0.5, 0.85), 1.2)
		_chip_node.draw_line(Vector2(sx,       sy),        Vector2(sx + 3.0, sy + 3.0),
				Color(1.0, 1.0, 0.5, 0.85), 1.2)
