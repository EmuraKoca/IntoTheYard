extends CharacterBody2D

const SURGERY_EXIT := Vector2(850, 1000)  # The only exit point from the living area

var speed = 110.0
var health = 8
var max_health = 8
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
	var sprite: AnimatedSprite2D = $FranticSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base := "res://assets/enemys/franticSubject/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]
	var anims := [["run", 8, true], ["kick", 7, false]]

	for a in anims:
		var anim_name: String = str(a[0])
		var frame_count: int  = int(a[1])
		var looping: bool     = bool(a[2])
		for d in dirs:
			var key: String = anim_name + "_" + str(d)
			var tex: Texture2D = load(base + "frantic_" + anim_name + "_" + str(d) + ".png")
			frames.add_animation(key)
			frames.set_animation_speed(key, 12.0)
			frames.set_animation_loop(key, looping)
			for i in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas  = tex
				atlas.region = Rect2(i * 124, 0, 124, 124)
				frames.add_frame(key, atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.9, 0.9)
	sprite.animation_finished.connect(_on_kick_finished)
	sprite.play("run_S")

func _on_kick_finished() -> void:
	_kicking = false
	_update_frantic_anim()

func _update_frantic_anim() -> void:
	if _kicking:
		return
	var sprite: AnimatedSprite2D = $FranticSprite
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
	$FranticSprite.play("kick_" + _anim_dir)

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
	_update_frantic_anim()
	if dist < 60:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			if is_glitched:
				target.take_damage(3)
			else:
				target.take_damage(4)
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
		game.subject_died(3)
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
	if randf() < 0.10:
		_become_ally()
	else:
		_escape()

func _escape() -> void:
	$FranticSprite.play("run_E")
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "global_position", Vector2(2100.0, global_position.y), 1.2)
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	await tw.finished
	if is_instance_valid(self): queue_free()

func _become_ally() -> void:
	var game = get_parent()
	if game.has_method("subject_rescued"):
		game.subject_rescued()

	add_to_group("allies")
	remove_from_group("subjects")
	if is_instance_valid(_chip_node): _chip_node.queue_redraw()
	_clear_element()
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	scale    = Vector2(1.0, 1.0)
	_is_exiting = false
	_reached_living_area = false
	_wander_timer = 0.0

	$CollisionShape2D.disabled = true
	set_physics_process(false)

	var nav_speed: float = max(speed * 3.0, 150.0)
	var inside: Vector2  = Vector2(randf_range(50.0, 720.0), randf_range(720.0, 1040.0))

	$FranticSprite.play("run_SW")
	var tw: Tween = create_tween()
	tw.tween_property(self, "global_position", inside,
		max(global_position.distance_to(inside) / nav_speed, 0.05))\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	if not is_instance_valid(self): return

	_reached_living_area = true
	_wander_timer = 0.0
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

	if not _reached_living_area:
		return

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 3.5)
		_wander_velocity = Vector2(randf_range(-speed * 0.6, speed * 0.6), randf_range(-speed * 0.5, speed * 0.5))
	if global_position.x < 80.0:
		_wander_velocity.x = abs(_wander_velocity.x)
	elif global_position.x > 750.0:
		_wander_velocity.x = -abs(_wander_velocity.x)
	if global_position.y < 700.0:
		_wander_velocity.y = abs(_wander_velocity.y)
	elif global_position.y > 1050.0:
		_wander_velocity.y = -abs(_wander_velocity.y)
	velocity = _wander_velocity
	move_and_slide()
	_update_anim_dir_from_velocity()
	_update_frantic_anim()

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
	# Vücuda yayılmış elektrik kıvılcımları (sarı-turuncu + mor)
	var t := _chip_t
	var anchors := [
		Vector2(-7.0, -22.0), Vector2( 7.0, -19.0),
		Vector2(-5.0,  -8.0), Vector2( 6.0,  -5.0),
		Vector2(-4.0,   6.0), Vector2( 5.0,   9.0),
	]
	for i in anchors.size():
		var flicker: float = (sin(t * (14.0 + i * 6.7) + i * 1.3) + 1.0) * 0.5
		if flicker < 0.30:
			continue
		var p: Vector2  = anchors[i]
		var ex: float   = sin(t * (9.0 + i * 3.1) + i) * 6.5
		var ey: float   = cos(t * (7.0 + i * 2.5) + i) * 5.5
		var a:  float   = flicker * 0.95
		# Sarı-turuncu ana kıvılcım (kalın)
		_chip_node.draw_line(p, p + Vector2(ex, ey),
				Color(1.0, 1.0, 0.35, a), 2.2)
		# Mor parıltı — aynı yol üzerine bindirilmiş
		_chip_node.draw_line(p, p + Vector2(ex, ey),
				Color(0.75, 0.1, 1.0, a * 0.55), 1.2)
		# Sarı-turuncu ikinci segment
		var ex2: float = ex + sin(t * 11.0 + i) * 3.5
		var ey2: float = ey + 2.5
		_chip_node.draw_line(p + Vector2(ex, ey),
				p + Vector2(ex2, ey2),
				Color(1.0, 0.85, 0.1, a * 0.70), 1.8)
		# Mor ikinci segment
		_chip_node.draw_line(p + Vector2(ex, ey),
				p + Vector2(ex2, ey2),
				Color(0.6, 0.0, 1.0, a * 0.40), 1.0)
