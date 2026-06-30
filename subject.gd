extends CharacterBody2D

const SURGERY_EXIT := Vector2(850, 1000)  # The only exit point from the living area

var speed = 28.0
var health = 10
var is_dead = false
var max_health = 10
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
var _anim_dir: String = "S"   # başlangıç: güneye bakıyor (player'a doğru)
var _punching: bool = false

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

func apply_slow(amount, duration: float = 3.0) -> void:
	if is_slowed:
		return
	is_slowed = true
	original_speed = speed
	speed = speed * (1.0 - amount)
	_set_element("slow")
	await get_tree().create_timer(duration).timeout
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
		game.subject_died(1, global_position)
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
	if randf() < 0.25:
		_become_ally()
	else:
		_escape()

func _escape() -> void:
	if is_instance_valid(_chip_node): _chip_node.queue_free()
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
	var _escape_doors: Array = [Vector2(1585, 395), Vector2(1585, 550), Vector2(1585, 710), Vector2(1585, 865)]
	var _nearest_escape: Vector2 = _escape_doors[0]
	var _min_escape_dist: float = global_position.distance_to(_escape_doors[0])
	for _ed in _escape_doors:
		var _d: float = global_position.distance_to(_ed)
		if _d < _min_escape_dist:
			_min_escape_dist = _d
			_nearest_escape = _ed
	var nav_speed: float = max(speed * 4.5, 200.0)
	$SubjectSprite.play("walk_SE")
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.tween_property(self, "global_position", _nearest_escape,
		global_position.distance_to(_nearest_escape) / nav_speed)
	await tween.finished
	if is_instance_valid(self): queue_free()

func _become_ally() -> void:
	set_physics_process(false)
	var game = get_parent()
	if game.has_method("subject_rescued"):
		game.subject_rescued()
	var _ally_doors: Array = [Vector2(875, 395), Vector2(875, 550), Vector2(875, 710), Vector2(875, 865)]
	var _nearest: Vector2 = _ally_doors[0]
	var _min_d: float = global_position.distance_to(_ally_doors[0])
	for _ad in _ally_doors:
		var _d: float = global_position.distance_to(_ad)
		if _d < _min_d:
			_min_d = _d
			_nearest = _ad
	var _aspeed: float = max(speed * 4.5, 200.0)
	$SubjectSprite.play("walk_W")
	# Kapıya 80px kala küçülmeye başla
	var _pre_shrink_pos: Vector2 = _nearest + (_nearest - global_position).normalized() * -80.0
	if global_position.distance_to(_nearest) > 80.0:
		var _pre_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
		_pre_tween.tween_property(self, "global_position", _pre_shrink_pos,
			global_position.distance_to(_pre_shrink_pos) / _aspeed)
		await _pre_tween.finished
		if not is_instance_valid(self): return
	if is_instance_valid(_chip_node): _chip_node.queue_free()
	var _early_shrink = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	_early_shrink.tween_property(self, "scale", Vector2(0.35, 0.35), 0.4)

	# 1 — Kapıya yürü
	var _atween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	_atween.tween_property(self, "global_position", _nearest,
		global_position.distance_to(_nearest) / _aspeed)
	await _atween.finished
	if not is_instance_valid(self): return

	# 2 — Kapıda küçül, yürümeye devam et, 1.5 sn sonra tribün altında eski boyuta dön
	var _dest: Vector2 = Vector2(randf_range(50.0, 680.0), randf_range(720.0, 1020.0))
	var _walk_dur: float = _nearest.distance_to(_dest) / _aspeed
	if is_instance_valid(_chip_node): _chip_node.queue_free()
	var _shrink = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	_shrink.tween_property(self, "scale", Vector2(0.35, 0.35), 0.3)
	var _walk2 = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	_walk2.tween_property(self, "global_position", _dest, _walk_dur)
	await get_tree().create_timer(1.5, false).timeout
	if not is_instance_valid(self): return
	var _grow = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	_grow.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	await _walk2.finished
	if not is_instance_valid(self): return

	add_to_group("allies")
	remove_from_group("subjects")
	_clear_element()
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	scale    = Vector2(1.0, 1.0)
	_is_exiting = false
	_reached_living_area = true
	_wander_timer = 0.0
	$CollisionShape2D.disabled = false
	set_physics_process(true)

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
	_update_subject_anim()

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
		var flicker: float = (sin(t * (18.0 + i * 6.7) + i * 1.3) + 1.0) * 0.5
		if flicker < 0.15:
			continue
		var p: Vector2  = anchors[i]
		var ex: float   = sin(t * (11.0 + i * 3.1) + i) * 9.0
		var ey: float   = cos(t * (9.0  + i * 2.5) + i) * 8.0
		var a:  float   = flicker * 1.0
		# Cyan ana kıvılcım
		_chip_node.draw_line(p, p + Vector2(ex, ey),
				Color(0.0, 0.9, 1.0, a * 0.9), 1.2)
		# Neon mor üst katman
		_chip_node.draw_line(p, p + Vector2(ex, ey),
				Color(0.55, 0.0, 0.85, a * 0.65), 0.7)
		# İkinci segment — elektrik mavisi
		var ex2: float = ex + sin(t * 13.0 + i) * 4.0
		var ey2: float = ey + cos(t * 10.0 + i) * 3.5
		_chip_node.draw_line(p + Vector2(ex, ey),
				p + Vector2(ex2, ey2),
				Color(0.1, 0.75, 1.0, a * 0.75), 1.0)
		# İkinci segment — neon mor
		_chip_node.draw_line(p + Vector2(ex, ey),
				p + Vector2(ex2, ey2),
				Color(0.45, 0.0, 0.75, a * 0.50), 0.6)
