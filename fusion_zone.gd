extends Node2D

var vacuum_radius = 80.0
var is_processing = false
var pending_types = []
var display_types = []
var ball_scene = preload("res://ball.tscn")
var loading = false
var load_timer = 0.0
var load_duration = 5.0
var is_active = true
var energy = 0.0
var max_energy = 50.0
var energy_timer = 0.0
var energy_tick = 2.0

# ── Visual effect references ───────────────────────────────────────────────
var _sprite: Sprite2D = null          # ProcessorSprite — otomatik tespit
var _sprite_local: Vector2 = Vector2.ZERO  # Sprite position in FusionZone local space
var _arc_lines: Array = []            # Active lightning Line2D nodes
var _arc_targets: Array = []          # Target ball reference for each Line2D
var _idle_angle: float = 0.0          # Plasma vortex rotation angle (radians)
var _flash_intensity: float = 0.0     # Fusion explosion brightness (0.0 - 1.0)

func _ready() -> void:
	_sprite = get_parent().get_node_or_null("ProcessorSprite") as Sprite2D
	if _sprite:
		_sprite_local = to_local(_sprite.global_position)

func toggle_active() -> void:
	is_active = !is_active
	queue_redraw()

func _physics_process(delta: float) -> void:
	queue_redraw()
	# Update plasma rotation angle
	_idle_angle = fmod(_idle_angle + delta * 1.8, TAU)
	# Recalculate sprite position every frame — tracks during parachute animation
	if _sprite:
		_sprite_local = to_local(_sprite.global_position)
	# Fade out fusion flash
	if _flash_intensity > 0.0:
		_flash_intensity = max(0.0, _flash_intensity - delta * 2.5)
	# Update lightning arcs (is_processing check inside _update_arcs)
	_update_arcs()
	if is_processing:
		return
	energy_timer += delta
	if energy_timer >= energy_tick:
		energy_timer = 0.0
		energy = min(energy + 1.0, max_energy)
		_update_energy_bar()
		queue_redraw()
	
	if not is_active:
		return
	
	if not loading and pending_types.size() < 2:
		var balls = get_tree().get_nodes_in_group("balls")
		for ball in balls:
			if not ball.moving:
				continue
			if ball.is_fused:
				continue
			var has_power = ball.can_split or ball.can_electric or ball.can_pierce \
				or ball.can_cryo or ball.can_glitch or ball.can_fire or ball.can_water
			if not has_power:
				continue
			var dist = global_position.distance_to(ball.global_position)
			if dist < vacuum_radius:
				_absorb_ball(ball)
				break
	if loading:
		load_timer += delta
		# Let energy decrease slowly
		energy = max(energy - (10.0 / load_duration) * delta, 0.0)
		_update_energy_bar()
		queue_redraw()  # Draw every frame — required for lightning animation
		if load_timer >= load_duration:
				loading = false
				load_timer = 0.0
				is_processing = true
				var type_a = pending_types[0]
				var type_b = pending_types[1]
				pending_types.clear()
				display_types.clear()
				queue_redraw()
				await _spawn_fused_ball(type_a, type_b)
				is_processing = false
				_trigger_fusion_flash()

func _absorb_ball(ball: Node2D) -> void:
	is_processing = true
	var ball_type = ball._get_type()
	pending_types.append(ball_type)
	display_types.append(ball_type)
	
	ball.absorb()
	# (absorb() collision ve state'i temizler)
	
	# Spiral absorption: ball is pulled rotating toward the visual center of the sprite
	# (not FusionZone logical center; sprite position is more consistent with rotation)
	var sp_target: Vector2 = _sprite.global_position if _sprite else global_position
	var sp_dist = ball.global_position.distance_to(sp_target)
	var sp_tw = create_tween()
	sp_tw.tween_method(_spiral_to.bind(ball, sp_target, sp_dist), 0.0, 1.0, 0.45)

	await get_tree().create_timer(0.50).timeout
	sp_tw.kill()  # Tween durdurulur — freed ball referansına erişim engellenir
	if is_instance_valid(ball):
		ball.queue_free()
	
	queue_redraw()
	
	if pending_types.size() < 2:
		is_processing = false
	else:
		if energy < 10.0:
			# Insufficient energy, return balls
			var type_a = pending_types[0]
			var type_b = pending_types[1]
			pending_types.clear()
			display_types.clear()
			queue_redraw()
			is_processing = false
			_refund_balls(type_a, type_b)
		else:
			loading = true
			load_timer = 0.0
			is_processing = false

func _spawn_fused_ball(type_a: String, type_b: String) -> void:
	var pair = [type_a, type_b]
	pair.sort()
	var key = pair[0] + "_" + pair[1]
	
	var fusions = {
		"cryo_split": "frozen_split",
		"glitch_split": "glitched_split",
		"electric_split": "electric_split",
		"pierce_split": "piercing_split",
		"cryo_electric": "cryostatic",
		"electric_glitch": "overclock",
		"electric_pierce": "railgun",
		"cryo_pierce": "glacier_spike",
		"glitch_pierce": "phantom",
		"cryo_glitch": "deep_freeze",
		"fire_water": "steam_pressure",
		"cryo_fire": "thermal_shock",
		"electric_fire": "plasma_discharge",
		"fire_pierce": "thermite",
		"fire_split": "firework",
		"fire_glitch": "meltdown",
		"split_water": "wet_split",
		"electric_water": "conductive",
		"pierce_water": "hydro_jet",
		"glitch_water": "blue_screen",
		"cryo_water": "absolute_zero"
	}
	
	# Aynı tip gelirse reddet — ikisi de iade edilir
	if type_a == type_b:
		_refund_balls(type_a, type_b)
		return

	var fusion_result = fusions.get(key, "")
	if fusion_result == "":
		_refund_balls(type_a, type_b)
		return

	var player = get_tree().get_first_node_in_group("player")
	var dir = Vector2(0, 1)
	if player:
		dir = (player.global_position - global_position).normalized()

	var new_ball = ball_scene.instantiate()
	_apply_fusion_to_ball(new_ball, fusion_result)
	new_ball.global_position = global_position + dir * 30
	get_parent().add_child(new_ball)
	await get_tree().process_frame
	new_ball.get_node("CollisionShape2D").disabled = false
	new_ball.state = "flying"
	new_ball.moving = true
	new_ball.move_direction = dir
	new_ball.speed = 600.0

func _draw() -> void:
	# ── Idle plasma vortex (on ProcessorSprite) ──────────────────────────────
	if is_active and not loading and not is_processing and _sprite:
		_draw_plasma_vortex(_sprite_local)

	# ── Fusion explosion ring ────────────────────────────────────────────────
	if _flash_intensity > 0.0:
		_draw_fusion_flash()

	# ── Ball icons: aligned to sprite center, rotation-aware ────────────────
	var center: Vector2    = _sprite_local
	var sprite_rot: float  = _sprite.rotation if _sprite else 0.0
	var side_dir: Vector2  = Vector2(1.0, 0.0).rotated(sprite_rot)

	var positions: Array = []
	if display_types.size() == 1:
		positions = [center]
	elif display_types.size() == 2:
		# When fuse starts (loading = true) two balls move toward each other
		var progress: float = load_timer / load_duration if loading else 0.0
		var offset: float   = lerp(22.0, 0.0, progress)
		positions = [center - side_dir * offset, center + side_dir * offset]

	for i in range(display_types.size()):
		_draw_ball_icon(positions[i], display_types[i])

	# ── Loading bar: aligned with sprite rotation, below visual ─────────────
	if loading:
		var down_dir: Vector2  = Vector2(0.0, 1.0).rotated(sprite_rot)
		var bar_center: Vector2 = center + down_dir * 38.0
		draw_set_transform(bar_center, sprite_rot, Vector2.ONE)
		var bar_w: float = 56.0
		var bar_h: float = 6.0
		draw_rect(Rect2(-bar_w * 0.5, -bar_h * 0.5, bar_w, bar_h), Color(0.2, 0.2, 0.2))
		var fill_w: float = bar_w * (load_timer / load_duration)
		draw_rect(Rect2(-bar_w * 0.5, -bar_h * 0.5, fill_w, bar_h), Color(0.0, 1.0, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# ── Lightning animation: at sprite center, during loading ────────────────
	if loading:
		var time: float = Time.get_ticks_msec() / 1000.0
		for i in range(6):
			var angle: float  = i * TAU / 6.0 + time * 3.0
			var arc_s: Vector2 = center + Vector2(cos(angle), sin(angle)) * 20.0
			var arc_e: Vector2 = center + Vector2(cos(angle + 0.5), sin(angle + 0.5)) * 35.0
			var arc_m: Vector2 = center + Vector2(cos(angle + 0.5), sin(angle + 0.5)) * 24.5
			draw_line(arc_s, arc_e, Color(0.0, 1.0, 1.0, 0.8), 1.5)
			draw_line(arc_s, arc_m, Color(1.0, 1.0, 1.0, 0.5), 1.0)

func _draw_ball_icon(p: Vector2, t: String) -> void:
	match t:
		"split":
			draw_circle(p, 8, Color(1.0, 0.2, 0.2))
			for j in range(8):
				var angle = j * TAU / 8
				draw_line(p + Vector2(cos(angle), sin(angle)) * 8, p + Vector2(cos(angle), sin(angle)) * 12, Color(1.0, 0.4, 0.0), 2)
		"electric":
			draw_circle(p, 8, Color(0.2, 0.5, 1.0))
			draw_arc(p, 10, 0, TAU, 32, Color(0.5, 0.8, 1.0), 2)
		"pierce":
			var pts = PackedVector2Array([p + Vector2(-10, 0), p + Vector2(0, -6), p + Vector2(10, 0), p + Vector2(0, 6)])
			draw_colored_polygon(pts, Color(1.0, 0.8, 0.0))
		"cryo":
			var pts = PackedVector2Array([p + Vector2(0, -8), p + Vector2(5, -4), p + Vector2(5, 4), p + Vector2(0, 8), p + Vector2(-5, 4), p + Vector2(-5, -4)])
			draw_colored_polygon(pts, Color(0.5, 0.8, 1.0))
		"glitch":
			draw_circle(p, 8, Color(0.8, 0.0, 0.8))
			draw_arc(p, 10, 0, TAU, 32, Color(1.0, 0.0, 1.0), 2)
		"water":
			draw_circle(p, 10, Color(0.0, 0.5, 1.0, 0.8))
			draw_circle(p, 7, Color(0.3, 0.7, 1.0, 0.6))
		"fire":
			draw_circle(p, 8, Color(1.0, 0.3, 0.0))
			draw_arc(p, 10, 0, TAU, 32, Color(1.0, 0.6, 0.0), 2)

func _apply_fusion_to_ball(ball: Node2D, fusion_type: String) -> void:
	ball.is_fused = true
	ball.has_fused = true
	ball.fusion_type = fusion_type
	
	match fusion_type:
		"frozen_split":
			ball.can_split = true
			ball.can_cryo = true
			ball.max_damage = 10
		"glitched_split":
			ball.can_split = true
			ball.can_glitch = true
			ball.max_damage = 9
		"electric_split":
			ball.can_split = true
			ball.can_electric = true
			ball.max_damage = 11
		"piercing_split":
			ball.can_split = true
			ball.can_pierce = true
			ball.max_damage = 12
		"wet_split":
			ball.can_split = true
			ball.can_water = true
			ball.max_damage = 8
		"cryostatic":
			ball.can_cryo = true
			ball.can_electric = true
			ball.max_damage = 13
		"overclock":
			ball.can_electric = true
			ball.can_glitch = true
			ball.max_damage = 12
		"railgun":
			ball.can_electric = true
			ball.can_pierce = true
			ball.max_damage = 15
			ball.speed = 900.0
		"glacier_spike":
			ball.can_cryo = true
			ball.can_pierce = true
			ball.max_damage = 12
		"phantom":
			ball.can_glitch = true
			ball.can_pierce = true
			ball.max_damage = 11
		"deep_freeze":
			ball.can_cryo = true
			ball.can_glitch = true
			ball.max_damage = 10
		"absolute_zero":
			ball.can_cryo = true
			ball.can_water = true
			ball.max_damage = 14
		"conductive":
			ball.can_electric = true
			ball.can_water = true
			ball.max_damage = 13
		"blue_screen":
			ball.can_glitch = true
			ball.can_water = true
			ball.max_damage = 10
		"hydro_jet":
			ball.can_pierce = true
			ball.can_water = true
			ball.max_damage = 12
		"steam_pressure":
			ball.can_fire = true
			ball.can_water = true
			ball.max_damage = 11
		"thermal_shock":
			ball.can_cryo = true
			ball.can_fire = true
			ball.max_damage = 14
		"plasma_discharge":
			ball.can_electric = true
			ball.can_fire = true
			ball.max_damage = 15
		"thermite":
			ball.can_fire = true
			ball.can_pierce = true
			ball.max_damage = 14
		"firework":
			ball.can_fire = true
			ball.can_split = true
			ball.max_damage = 12
		"meltdown":
			ball.can_fire = true
			ball.can_glitch = true
			ball.max_damage = 13

func _refund_balls(type_a: String, type_b: String) -> void:
	for t in [type_a, type_b]:
		var new_ball = ball_scene.instantiate()
		new_ball.global_position = global_position
		get_parent().add_child(new_ball)
		match t:
			"split": new_ball.can_split = true
			"electric": new_ball.can_electric = true
			"pierce": new_ball.can_pierce = true
			"cryo": new_ball.can_cryo = true
			"glitch": new_ball.can_glitch = true
			"fire": new_ball.can_fire = true
			"water": new_ball.can_water = true
		var player = get_tree().get_first_node_in_group("player")
		var dir = Vector2(0, -1)
		if player:
			dir = (player.global_position - global_position).normalized()
		new_ball.launch(dir)
		
func add_energy_from_hit(hit_type: String) -> void:
	if hit_type == "perfect":
		energy = min(energy + 4.0, max_energy)
	elif hit_type == "great":
		energy = min(energy + 2.0, max_energy)
	_update_energy_bar()
	queue_redraw()

func _update_energy_bar() -> void:
	var game = get_tree().get_first_node_in_group("game")
	if game:
		var bar = game.get_node_or_null("UI/FusionEnergyBar")
		var label = game.get_node_or_null("UI/LabelFusionEnergy")
		if bar:
			bar.value = energy
		if label:
			label.text = "⚡ Fusion Energy: " + str(int(energy)) + "/" + str(int(max_energy))

# ════════════════════════════════════════════════════════════════════════════
# VISUAL EFFECT FUNCTIONS
# ════════════════════════════════════════════════════════════════════════════

# ── Spinning neon plasma vortex ──────────────────────────────────────────
# Drawn around 'center' point in FusionZone's local coordinates.
# HDR color values (>1.0) trigger glow with WorldEnvironment Glow.
func _draw_plasma_vortex(center: Vector2) -> void:
	var a := _idle_angle
	var sprite_rot: float = _sprite.rotation if _sprite else 0.0

	# Move drawing context to sprite's center + rotation
	# So all draw_* calls align with sprite's tilt
	draw_set_transform(center, sprite_rot, Vector2.ONE)

	# Outer ring — neon pink (HDR) — zero-centered, transform already applied
	draw_arc(Vector2.ZERO, 38.0, a,              a + TAU * 0.65, 36, Color(2.2, 0.1, 1.8, 0.85), 2.5)
	draw_arc(Vector2.ZERO, 38.0, a + PI,         a + PI + TAU * 0.28, 16, Color(2.2, 0.1, 1.8, 0.35), 4.0)

	# Inner ring — cyan/blue (HDR), rotates in opposite direction
	draw_arc(Vector2.ZERO, 23.0, -a * 1.5,       -a * 1.5 + TAU * 0.55, 28, Color(0.1, 1.9, 2.3, 0.90), 2.0)
	draw_arc(Vector2.ZERO, 23.0, -a * 1.5 + PI, -a * 1.5 + PI + TAU * 0.35, 14, Color(0.1, 1.9, 2.3, 0.40), 3.0)

	# Core glow
	draw_circle(Vector2.ZERO, 9.0, Color(2.5, 0.6, 2.5, 0.55))
	draw_circle(Vector2.ZERO, 4.5, Color(3.0, 1.2, 3.5, 0.80))

	# Spinning spark particles
	for s in range(5):
		var spark_a := a * 2.3 + s * (TAU / 5.0)
		var spark_r := 30.0 + sin(a * 3.0 + s) * 6.0
		draw_circle(Vector2(cos(spark_a), sin(spark_a)) * spark_r, 2.5, Color(2.8, 1.0, 3.2, 0.75))

	# Reset drawing context — so subsequent draw_* calls are not affected
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ── Fusion explosion: expanding neon ring ───────────────────────────────
func _draw_fusion_flash() -> void:
	var fi := _flash_intensity
	var r: float = lerp(20.0, 115.0, 1.0 - fi)   # small at explosion moment → expands
	draw_circle(_sprite_local, r,         Color(3.0, 1.2, 3.5, fi * 0.55))
	draw_arc(_sprite_local, r * 1.30, 0.0, TAU, 48, Color(2.5, 0.5, 3.0, fi * 0.90), 3.5)
	draw_arc(_sprite_local, r * 0.60, 0.0, TAU, 32, Color(3.5, 2.0, 4.0, fi * 0.70), 2.0)

# ── Lightning arc: zigzag Line2D points from point A to point B ──────────
func _make_lightning(a: Vector2, b: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var segments := 9
	var perp := (b - a).normalized().rotated(PI * 0.5)
	pts.append(a)
	for i in range(1, segments):
		var t := float(i) / float(segments)
		pts.append(a.lerp(b, t) + perp * randf_range(-15.0, 15.0))
	pts.append(b)
	return pts

# ── Lightning arc update: creates/updates Line2D for nearby balls ──────────
func _update_arcs() -> void:
	# Clear invalid / stopped ball arcs
	for i in range(_arc_lines.size() - 1, -1, -1):
		if not is_instance_valid(_arc_targets[i]) or not _arc_targets[i].moving:
			_arc_lines[i].queue_free()
			_arc_lines.remove_at(i)
			_arc_targets.remove_at(i)

	# If device is passive, loading or processing, disable all arcs
	if is_processing or loading or not is_active:
		for arc_line in _arc_lines:
			arc_line.queue_free()
		_arc_lines.clear()
		_arc_targets.clear()
		return

	# Scan for powered balls within 1.6x vacuum radius
	var nearby: Array = []
	for ball in get_tree().get_nodes_in_group("balls"):
		if not ball.moving or ball.is_fused:
			continue
		var has_power: bool = ball.can_split or ball.can_electric or ball.can_pierce \
			or ball.can_cryo or ball.can_glitch or ball.can_fire or ball.can_water
		if not has_power:
			continue
		if global_position.distance_to(ball.global_position) < vacuum_radius * 1.6:
			nearby.append(ball)

	# Create Line2D arc for new balls
	for ball in nearby:
		if not _arc_targets.has(ball):
			var arc := Line2D.new()
			arc.width = 1.8
			arc.default_color = Color(1.6, 0.4, 2.6, 0.9)
			arc.joint_mode = Line2D.LINE_JOINT_ROUND
			arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
			arc.end_cap_mode  = Line2D.LINE_CAP_ROUND
			add_child(arc)
			_arc_lines.append(arc)
			_arc_targets.append(ball)

	# Disable arc for balls that leave range
	for i in range(_arc_targets.size() - 1, -1, -1):
		if not nearby.has(_arc_targets[i]):
			_arc_lines[i].queue_free()
			_arc_lines.remove_at(i)
			_arc_targets.remove_at(i)

	# Update points and colors of remaining arcs every frame (flicker)
	var t := Time.get_ticks_msec() / 1000.0
	for i in range(_arc_lines.size()):
		if not is_instance_valid(_arc_targets[i]):
			continue
		_arc_lines[i].points = _make_lightning(
			_sprite_local,
			to_local(_arc_targets[i].global_position)
		)
		var flicker := 0.65 + 0.35 * sin(t * 22.0 + i * 2.1)
		_arc_lines[i].default_color = Color(1.6 * flicker, 0.3 * flicker, 2.6 * flicker, 0.85)

# ── Spiral absorption: Callable for tween_method (p: 0->1) ──────────────
# Godot 4 bind() order: callable(p, ...bound_args)
func _spiral_to(p: float, ball: Node2D, target: Vector2, dist: float) -> void:
	if not is_instance_valid(ball):
		return
	var angle := p * TAU * 1.6 - PI * 0.5
	var radius: float = lerp(dist * 0.75, 0.0, p)
	ball.global_position = target + Vector2(cos(angle), sin(angle)) * radius
	ball.scale = Vector2.ONE * lerp(1.0, 0.05, ease(p, 2.0))

# ── Fusion Flash tetikleyici ──────────────────────────────────────────────
func _trigger_fusion_flash() -> void:
	_flash_intensity = 1.0
	if not _sprite:
		return
	# Pull ProcessorSprite to top and give instant neon glow
	var prev_z := _sprite.z_index
	_sprite.z_index = 10
	var flash_tw := create_tween()
	flash_tw.tween_property(_sprite, "modulate", Color(3.0, 1.5, 3.5), 0.04)\
		.set_trans(Tween.TRANS_LINEAR)
	flash_tw.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0), 0.55)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	flash_tw.tween_callback(func() -> void: _sprite.z_index = prev_z)
