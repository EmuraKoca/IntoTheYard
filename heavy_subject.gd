extends CharacterBody2D

static var _freeze_sf: SpriteFrames = null

const SURGERY_EXIT := Vector2(850, 1000)  # The only exit point from the living area

var speed = 32.0
var health = 90
var max_health = 90
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
var _freeze_sprite: AnimatedSprite2D = null
var _cryo_sprite: AnimatedSprite2D = null
var _melt_frozen_sprite: AnimatedSprite2D = null
var _had_reaction: bool = false
var _uppercutting: bool = false

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

func apply_burn() -> void:
	if is_burning:
		return
	_check_reaction("fire")
	if not is_instance_valid(self): return
	is_burning = true
	_set_element("burn")
	var p := _get_player()
	var tick_dmg: int = 2
	if p and p.get("burn_damage_mult"):
		tick_dmg = max(1, int(2.0 * p.burn_damage_mult))
	var burn_ticks := 3
	if p and p.get("has_elemental_memory") and p.has_elemental_memory and _had_reaction:
		burn_ticks = 6
	for i in range(burn_ticks):
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self) and health > 0:
			health -= tick_dmg
			if p and p.get("has_overheat") and p.has_overheat:
				if not p.get("_overheat_counter"):
					p.set("_overheat_counter", 0)
				p._overheat_counter += 1
				if p._overheat_counter >= 13:
					p._overheat_counter = 0
					_react_overheat()
			if health <= 0:
				die()
	if not is_instance_valid(self):
		return
	is_burning = false
	_clear_element()

func _react_overheat() -> void:
	_spawn_overheat_vfx()
	var p := _get_player()
	var _oh_radius := 150.0
	if p and p.get("has_pyroblast") and p.has_pyroblast:
		_oh_radius = 150.0 + float(p.get("_overheat_counter") if p.get("_overheat_counter") != null else 0) * 8.0
	for body in get_tree().get_nodes_in_group("subjects"):
		if is_instance_valid(body) and global_position.distance_to(body.global_position) < _oh_radius:
			body.health -= 15
			body._react_flash(Color(1.0, 0.3, 0.0))
			if body.health <= 0: body.die()

func apply_frozen() -> void:
	if is_frozen:
		return
	is_frozen = true
	is_wet = false
	_set_element("frozen")
	$HeavySprite.stop()
	_spawn_freeze_vfx()
	var p := _get_player()
	var dur := 3.0
	if p and p.get("freeze_duration_mult"):
		dur *= p.freeze_duration_mult
	await get_tree().create_timer(dur).timeout
	if not is_instance_valid(self):
		return
	if is_instance_valid(_freeze_sprite):
		_freeze_sprite.play("freeze")
		await _freeze_sprite.animation_finished
	if is_instance_valid(_freeze_sprite):
		_freeze_sprite.queue_free()
		_freeze_sprite = null
	is_frozen = false
	$HeavySprite.play("walk_" + _anim_dir)
	_clear_element()

func _spawn_cryo_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("cryo")
	sf.set_animation_speed("cryo", 1.0)
	sf.set_animation_loop("cryo", false)
	sf.add_frame("cryo", load("res://assets/VFX/cryoEffect/frame_000.png"))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("cryo")
	_cryo_sprite = spr

func _spawn_freeze_vfx() -> void:
	if _freeze_sf == null:
		_freeze_sf = SpriteFrames.new()
		if _freeze_sf.has_animation("default"): _freeze_sf.remove_animation("default")
		_freeze_sf.add_animation("freeze")
		_freeze_sf.set_animation_speed("freeze", 8.0)
		_freeze_sf.set_animation_loop("freeze", false)
		for i in range(15):
			_freeze_sf.add_frame("freeze", load("res://assets/VFX/crashFreeze/frame_%03d.png" % i))
	_freeze_sprite = AnimatedSprite2D.new()
	_freeze_sprite.sprite_frames = _freeze_sf
	_freeze_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_freeze_sprite.z_index = -1
	_freeze_sprite.position = Vector2(0, 0)
	_freeze_sprite.scale = Vector2(0.5, 0.5)
	add_child(_freeze_sprite)
	_freeze_sprite.frame = 0
	_freeze_sprite.stop()

func apply_wet() -> void:
	_check_reaction("wet")
	if not is_instance_valid(self): return
	is_wet = true
	_set_element("wet")
	var p := _get_player()
	var dur := 5.0
	if p and p.get("has_elemental_memory") and p.has_elemental_memory and _had_reaction:
		dur *= 2.0
	if p and p.get("first_debuff_duration_mult") and not _had_any_element():
		dur *= p.first_debuff_duration_mult
	await get_tree().create_timer(dur).timeout
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
	_check_reaction("electric")
	if not is_instance_valid(self): return
	is_electrified = true
	_set_element("electrified")
	var p := _get_player()
	var dur := 5.0
	if p and p.get("has_elemental_memory") and p.has_elemental_memory and _had_reaction:
		dur *= 2.0
	if p and p.get("first_debuff_duration_mult") and not _had_any_element():
		dur *= p.first_debuff_duration_mult
	# Living Storm: electrified iken player yakınsa periyodik hasar
	var _ls_p := _get_player()
	if _ls_p and _ls_p.get("has_living_storm") and _ls_p.has_living_storm:
		_living_storm_loop()
	await get_tree().create_timer(dur).timeout
	if is_instance_valid(self):
		is_electrified = false
		_clear_element()

func apply_slow(amount, duration: float = 3.0) -> void:
	if is_slowed:
		return
	_check_reaction("cryo")
	if not is_instance_valid(self): return
	is_slowed = true
	original_speed = speed
	var p := _get_player()
	var slow_amount: float = float(amount)
	if p and p.get("cryo_slow_mult"):
		slow_amount = min(amount * p.cryo_slow_mult, 0.9)
	speed = speed * (1.0 - slow_amount)
	_set_element("slow")
	_spawn_cryo_vfx()
	var dur := duration
	if p and p.get("has_elemental_memory") and p.has_elemental_memory and _had_reaction:
		dur *= 2.0
	if p and p.get("first_debuff_duration_mult") and not _had_any_element():
		dur *= p.first_debuff_duration_mult
	await get_tree().create_timer(dur).timeout
	if not is_instance_valid(self):
		return
	if is_instance_valid(_cryo_sprite):
		_cryo_sprite.queue_free()
		_cryo_sprite = null
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
	var sprite: AnimatedSprite2D = $HeavySprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base := "res://assets/enemys/heavySubject/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]
	var anims := [["walk", 6, true], ["uppercut", 7, false]]

	for a in anims:
		var anim_name: String = str(a[0])
		var frame_count: int  = int(a[1])
		var looping: bool     = bool(a[2])
		for d in dirs:
			var key: String = anim_name + "_" + str(d)
			var tex: Texture2D = load(base + "heavy_" + anim_name + "_" + str(d) + ".png")
			frames.add_animation(key)
			frames.set_animation_speed(key, 8.0)
			frames.set_animation_loop(key, looping)
			for i in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas  = tex
				atlas.region = Rect2(i * 128, 0, 128, 128)
				frames.add_frame(key, atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.85, 0.85)
	sprite.animation_finished.connect(_on_uppercut_finished)
	sprite.play("walk_S")

func _on_uppercut_finished() -> void:
	_uppercutting = false
	_update_heavy_anim()

func _update_heavy_anim() -> void:
	if _uppercutting:
		return
	var sprite: AnimatedSprite2D = $HeavySprite
	var anim := "walk_" + _anim_dir
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

func play_uppercut() -> void:
	if _uppercutting:
		return
	_uppercutting = true
	$HeavySprite.play("uppercut_" + _anim_dir)

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
	_update_heavy_anim()
	if dist < 60:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			if is_glitched:
				target.take_damage(3)
			else:
				target.take_damage(8)
			attack_cooldown = attack_rate
			play_uppercut()

func die() -> void:
	is_dead = true
	if is_in_group("allies"):
		set_physics_process(false)
		$CollisionShape2D.set_deferred("disabled", true)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 1.0)
		await get_tree().create_timer(1.0).timeout
		queue_free()
		return
	var game = get_parent()
	if game.has_method("subject_died"):
		game.subject_died(3, global_position)
	_collapse()

func _collapse() -> void:
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
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
	if randf() < 0.01:
		_become_ally()
	else:
		_escape()

func _escape() -> void:
	is_burning = false
	is_wet = false
	is_electrified = false
	is_slowed = false
	is_frozen = false
	_clear_element()
	if is_instance_valid(_freeze_sprite):
		_freeze_sprite.queue_free()
		_freeze_sprite = null
	if is_instance_valid(_cryo_sprite):
		_cryo_sprite.queue_free()
		_cryo_sprite = null
	if is_instance_valid(_melt_frozen_sprite):
		_melt_frozen_sprite.queue_free()
		_melt_frozen_sprite = null
	$HeavySprite.play("walk_" + _anim_dir)
	if is_instance_valid(_chip_node): _chip_node.queue_free()
	var _escape_doors: Array = [Vector2(1585, 395), Vector2(1585, 550), Vector2(1585, 710), Vector2(1585, 865)]
	var _nearest_escape: Vector2 = _escape_doors[0]
	var _min_escape_dist: float = global_position.distance_to(_escape_doors[0])
	for _ed in _escape_doors:
		var _d: float = global_position.distance_to(_ed)
		if _d < _min_escape_dist:
			_min_escape_dist = _d
			_nearest_escape = _ed
	var nav_speed: float = max(speed * 4.5, 200.0)
	$HeavySprite.play("walk_SE")
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.tween_property(self, "global_position", _nearest_escape,
		global_position.distance_to(_nearest_escape) / nav_speed)
	await tween.finished
	if is_instance_valid(self): queue_free()

func _become_ally() -> void:
	is_burning = false
	is_wet = false
	is_electrified = false
	is_slowed = false
	is_frozen = false
	_clear_element()
	if is_instance_valid(_freeze_sprite):
		_freeze_sprite.queue_free()
		_freeze_sprite = null
	if is_instance_valid(_cryo_sprite):
		_cryo_sprite.queue_free()
		_cryo_sprite = null
	if is_instance_valid(_melt_frozen_sprite):
		_melt_frozen_sprite.queue_free()
		_melt_frozen_sprite = null
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
	$HeavySprite.play("walk_W")
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
	$CollisionShape2D.set_deferred("disabled", false)
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
	_update_heavy_anim()

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

func _get_player() -> Node:
	var game := get_node_or_null("/root/GameScene")
	return game.get_node_or_null("Player") if game else null

func _had_any_element() -> bool:
	return is_burning or is_wet or is_electrified or is_slowed or is_frozen


func _living_storm_loop() -> void:
	while is_instance_valid(self) and is_electrified:
		await get_tree().create_timer(1.5).timeout
		if not is_instance_valid(self) or not is_electrified: break
		var _target := get_tree().get_first_node_in_group("player")
		if _target and global_position.distance_to(_target.global_position) < 120.0:
			health -= 3
			_react_flash(Color(0.2, 0.5, 4.0))
			if health <= 0: die(); break
func _check_reaction(incoming: String) -> void:
	var game := get_node_or_null("/root/GameScene")
	var player := game.get_node_or_null("Player") if game else null
	var dmg_mult: float = 1.0

	if player and player.get("has_volatile_mixture") and player.has_volatile_mixture:
		var active := 0
		if is_burning:     active += 1
		if is_wet:         active += 1
		if is_electrified: active += 1
		if is_slowed:      active += 1
		if active >= 2:
			if is_wet and is_electrified:
				is_wet = false; is_electrified = false
				_react_electrocute(dmg_mult, game, player); return
			elif is_wet and is_slowed:
				is_wet = false; is_slowed = false
				speed = original_speed if original_speed > 0 else speed
				apply_frozen(); _react_flash(Color(0.5, 0.9, 1.0))
				_notify_reaction(game, player); return
			elif is_burning and is_wet:
				is_wet = false; is_burning = false
				_react_steam(dmg_mult, game, player); return
			elif is_burning and is_slowed:
				is_burning = false; is_slowed = false
				speed = original_speed if original_speed > 0 else speed
				_react_melt(dmg_mult); return

	if player and player.get("has_chain_catalyst") and player.has_chain_catalyst:
		var active := 0
		if is_burning:     active += 1
		if is_wet:         active += 1
		if is_electrified: active += 1
		if is_slowed:      active += 1
		if active >= 2:
			dmg_mult = 1.3

	if incoming == "electric" and is_wet:
		is_wet = false; is_electrified = false
		_react_electrocute(dmg_mult, game, player); return
	if incoming == "wet" and is_electrified:
		is_wet = false; is_electrified = false
		_react_electrocute(dmg_mult, game, player); return
	if incoming == "cryo" and is_wet:
		is_wet = false; is_slowed = false
		apply_frozen(); _react_flash(Color(0.5, 0.9, 1.0))
		_notify_reaction(game, player); return
	if incoming == "wet" and is_slowed:
		is_wet = false; is_slowed = false
		speed = original_speed if original_speed > 0 else speed
		apply_frozen(); _react_flash(Color(0.5, 0.9, 1.0))
		_notify_reaction(game, player); return
	if incoming == "wet" and is_burning:
		is_wet = false; is_burning = false
		_react_steam(dmg_mult, game, player); return
	if incoming == "fire" and is_wet:
		is_wet = false; is_burning = false
		_react_steam(dmg_mult, game, player); return
	# frozen + fire → melt the frozen
	if incoming == "fire" and is_frozen:
		_react_melt_frozen(dmg_mult, game, player)
		return
	if incoming == "fire" and is_slowed:
		is_burning = false; is_slowed = false
		speed = original_speed if original_speed > 0 else speed
		_react_melt(dmg_mult); return
	if incoming == "cryo" and is_burning:
		is_burning = false; is_slowed = false
		speed = original_speed if original_speed > 0 else speed
		_react_melt(dmg_mult); return

func _react_electrocute(mult: float, game: Node, player: Node) -> void:
	_spawn_electrocute_vfx()
	var dmg := int(12 * mult)
	health -= dmg
	_react_flash(Color(0.2, 0.5, 4.0))
	var prev_speed: float = float(speed)
	speed = 0.0
	await get_tree().create_timer(0.8).timeout
	if not is_instance_valid(self): return
	speed = prev_speed
	_clear_element()
	_notify_reaction(game, player)
	if health <= 0: die()

func _react_steam(mult: float, game: Node, player: Node) -> void:
	_spawn_steam_vfx()
	var dmg := int(8 * mult)
	var _steam_radius := 120.0
	var _thermal: bool = player and player.get("has_thermal_expansion") and player.has_thermal_expansion
	if _thermal:
		_steam_radius = 200.0
	for body in get_tree().get_nodes_in_group("subjects"):
		if body == self: continue
		if is_instance_valid(body) and global_position.distance_to(body.global_position) < _steam_radius:
			body.health -= dmg
			if _thermal and body.get("apply_wet"): body.apply_wet(0.3, 2.0)
			if body.health <= 0: body.die()
	health -= dmg
	_react_flash(Color(0.9, 0.9, 1.0))
	_clear_element()
	_notify_reaction(game, player)
	if health <= 0: die()

func _spawn_steam_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("steam")
	sf.set_animation_speed("steam", 12.0)
	sf.set_animation_loop("steam", false)
	for i in range(17):
		sf.add_frame("steam", load("res://assets/VFX/steam/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("steam")
	spr.animation_finished.connect(spr.queue_free)

func _react_melt_frozen(mult: float, game: Node, player: Node) -> void:
	if is_instance_valid(_freeze_sprite):
		_freeze_sprite.queue_free()
		_freeze_sprite = null
	is_frozen = false
	_spawn_melt_frozen_vfx()
	var dmg := int(20 * mult)
	health -= dmg
	_react_flash(Color(1.0, 0.5, 0.2))
	_clear_element()
	_notify_reaction(game, player)
	if health <= 0: die()

func _spawn_melt_frozen_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("melt_frozen")
	sf.set_animation_speed("melt_frozen", 12.0)
	sf.set_animation_loop("melt_frozen", false)
	for i in range(17):
		sf.add_frame("melt_frozen", load("res://assets/VFX/meltTheFrozen/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("melt_frozen")
	_melt_frozen_sprite = spr
	spr.animation_finished.connect(func(): _melt_frozen_sprite = null; spr.queue_free())

func _spawn_melt_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("melt")
	sf.set_animation_speed("melt", 10.0)
	sf.set_animation_loop("melt", false)
	for i in range(4):
		sf.add_frame("melt", load("res://assets/VFX/melt/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("melt")
	spr.animation_finished.connect(spr.queue_free)

func _spawn_electrocute_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("electrocute")
	sf.set_animation_speed("electrocute", 12.0)
	sf.set_animation_loop("electrocute", false)
	for i in range(17):
		sf.add_frame("electrocute", load("res://assets/VFX/electrocute/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("electrocute")
	spr.animation_finished.connect(spr.queue_free)

func _spawn_overheat_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("overheat")
	sf.set_animation_speed("overheat", 12.0)
	sf.set_animation_loop("overheat", false)
	for i in range(15):
		sf.add_frame("overheat", load("res://assets/VFX/overheat/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("overheat")
	spr.animation_finished.connect(spr.queue_free)

func _react_melt(mult: float) -> void:
	_spawn_melt_vfx()
	var dmg := int(18 * mult)
	health -= dmg
	_react_flash(Color(1.0, 0.6, 0.1))
	_clear_element()
	if health <= 0: die()

func _react_flash(color: Color) -> void:
	modulate = color
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1, 1)

func _notify_reaction(game: Node, player: Node) -> void:
	if not player: return
	_had_reaction = true

	if player.get("reaction_heal_amount") and player.reaction_heal_amount > 0:
		if game and game.has_method("heal_player"):
			game.heal_player(player.reaction_heal_amount)

	if player.get("reaction_core_speed_bonus") and player.reaction_core_speed_bonus > 0:
		if player.get("momentum_stacks") and player.get("momentum_max"):
			player.momentum_stacks = mini(player.momentum_stacks + 1, player.momentum_max)
		if player.get("orbit_speed_mult"):
			player.orbit_speed_mult += player.reaction_core_speed_bonus

	if player.get("has_perfect_catalyst") and player.has_perfect_catalyst:
		var last_elem: String = player.get("last_applied_element") if player.get("last_applied_element") else ""
		if last_elem == "fire" and not is_burning:
			apply_burn()
		elif last_elem == "wet" and not is_wet:
			apply_wet()
		elif last_elem == "electric" and not is_electrified:
			apply_electrified()
		elif last_elem == "cryo" and not is_slowed:
			apply_slow(0.25)

	if player.get("has_catalyst_mind") and player.has_catalyst_mind and player.catalyst_mind_cooldown <= 0.0:
		player.catalyst_mind_ready = true
		player.catalyst_mind_cooldown = 5.0
