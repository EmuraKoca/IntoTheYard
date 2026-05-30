extends CharacterBody2D

const SURGERY_EXIT := Vector2(850, 1000)  # The only exit point from the living area

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
var _reached_living_area: bool = false
var _wander_timer: float = 0.0
var _wander_velocity: Vector2 = Vector2.ZERO
var _killed_by_ally: bool = false

# Animasyon
var _anim_dir: String = "S"   # başlangıç: güneye bakıyor (player'a doğru)
var _punching: bool = false

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
	_setup_sprite()

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $SubjectSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base := "res://assets/enemys/subject/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]
	var anims := [["walk", 6, true], ["punch", 7, false]]

	for a in anims:
		var anim_name: String = str(a[0])
		var frame_count: int  = int(a[1])
		var looping: bool     = bool(a[2])
		for d in dirs:
			var key: String = anim_name + "_" + str(d)
			var tex: Texture2D = load(base + "subject_" + anim_name + "_" + d + ".png")
			frames.add_animation(key)
			frames.set_animation_speed(key, 10.0)
			frames.set_animation_loop(key, looping)
			for i in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas  = tex
				atlas.region = Rect2(i * 60, 0, 60, 60)
				frames.add_frame(key, atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(1.8, 1.8)
	sprite.animation_finished.connect(_on_punch_finished)
	sprite.play("walk_S")

func _on_punch_finished() -> void:
	_punching = false
	_update_subject_anim()

func _update_subject_anim() -> void:
	if _punching:
		return
	var sprite: AnimatedSprite2D = $SubjectSprite
	var anim := "walk_" + _anim_dir
	if sprite.animation != anim:
		sprite.play(anim)

func _update_anim_dir_from_velocity() -> void:
	if velocity == Vector2.ZERO:
		return
	var angle := velocity.angle()      # radyan, +x = 0, saat yönü pozitif
	var deg   := rad_to_deg(angle)
	if   deg > -22.5  and deg <= 22.5:   _anim_dir = "E"
	elif deg > 22.5   and deg <= 67.5:   _anim_dir = "SE"
	elif deg > 67.5   and deg <= 112.5:  _anim_dir = "S"
	elif deg > 112.5  and deg <= 157.5:  _anim_dir = "SW"
	elif deg > 157.5  or  deg <= -157.5: _anim_dir = "W"
	elif deg > -157.5 and deg <= -112.5: _anim_dir = "NW"
	elif deg > -112.5 and deg <= -67.5:  _anim_dir = "N"
	elif deg > -67.5  and deg <= -22.5:  _anim_dir = "NE"

func play_punch() -> void:
	if _punching:
		return
	_punching = true
	$SubjectSprite.play("punch_" + _anim_dir)

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
	var dist = global_position.distance_to(target.global_position)
	if dist > 60:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	_update_anim_dir_from_velocity()
	_update_subject_anim()
	if dist < 60:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			if is_glitched:
				target.take_damage(3)
			else:
				target.take_damage(5)
			attack_cooldown = attack_rate
			play_punch()   # player'a vurunca punch animasyonu

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
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.8, 0.3), 0.3)
	await get_tree().create_timer(1.0).timeout

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
	modulate = Color(0.2, 1.0, 0.4)
	# Use game-level chip duration if available (respects Chip Boost upgrade)
	_ally_timer = game.ally_chip_duration if "ally_chip_duration" in game else chip_duration
	_is_exiting = false
	_reached_living_area = false
	_wander_timer = 0.0

	# Disable collision — ally moves freely through tribune walls etc.
	$CollisionShape2D.disabled = true
	set_physics_process(true)

func _start_exit() -> void:
	_is_exiting = true
	set_physics_process(false)
	# CollisionShape2D already disabled since _become_ally

	var nav_speed = max(speed * 3.0, 200.0)
	var exit_time = (global_position.x + 200.0) / nav_speed

	# Run straight left from current position → off-screen → queue_free
	var tween = create_tween()
	tween.tween_property(self, "global_position", Vector2(-200, global_position.y), exit_time)
	tween.tween_callback(queue_free)

func _ally_behavior() -> void:
	var delta = get_physics_process_delta_time()

	if _is_exiting:
		return

	_ally_timer -= delta
	if _ally_timer <= 0.0:
		_start_exit()
		return

	# Use at least 150 px/s so even slow subjects move purposefully
	var nav_speed = max(speed * 3.0, 150.0)

	# Phase 1: Navigate through Surgery door into the living area
	# Collision is disabled so we pass through everything freely
	if not _reached_living_area:
		if global_position.x >= 850.0:
			# Still in game field — head toward Surgery door first
			var dir = (SURGERY_EXIT - global_position).normalized()
			velocity = dir * nav_speed
		else:
			# Passed Surgery door — go straight left to living area
			velocity = Vector2(-nav_speed, 0)
		move_and_slide()
		_update_anim_dir_from_velocity()
		_update_subject_anim()
		if global_position.x < 490.0:
			_reached_living_area = true
			_wander_timer = 0.0
			velocity = Vector2.ZERO
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
			_update_subject_anim()
		else:
			velocity = Vector2.ZERO
			attack_cooldown -= delta
			if attack_cooldown <= 0:
				closest.take_damage(5, true)  # true = killed by ally, no ally chance
				attack_cooldown = attack_rate
				play_punch()
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
		_update_subject_anim()
