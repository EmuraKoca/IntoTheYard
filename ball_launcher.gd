extends Node2D

var ball_scene = preload("res://ball.tscn")
var player = null
var game   = null
var total_balls  = 50
var balls_fired  = 0

# ── Actual visual sprite (sibling node in game_scene) ──────────────────────────
var _sprite: Sprite2D = null
var _sprite_rest_pos: Vector2 = Vector2.ZERO

# ── Charge-up ─────────────────────────────────────────────────────────────────
var is_charging     := false
var charge_progress := 0.0        # 0.0 → 1.0 son 1 saniyede

# ── Muzzle Flash ──────────────────────────────────────────────────────────────
var flash_active := false
var flash_radius := 0.0
var flash_alpha  := 0.0
var flash_color  := Color(2.0, 2.0, 3.5, 1.0)

# ── Internal helpers ────────────────────────────────────────────────────────────
var _last_launch_type := ""
var _shake_tween: Tween = null

# Muzzle tip: in BallLauncher's local coordinates (same origin as sprite)
const MUZZLE_OFFSET := Vector2(0.0, 18.0)

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	$Timer.timeout.connect(_on_timer_timeout)
	player = get_parent().get_node("Player")
	game   = get_parent()

	# Hide white square — not used visually
	$ColorRect.visible = false

	# This node's _draw() output (charge glow + muzzle flash) renders above everything
	visible       = true
	z_index       = 10
	z_as_relative = false

	# Actual visual: sibling BallLauncherSprite in game_scene
	_sprite = get_parent().get_node_or_null("BallLauncherSprite") as Sprite2D
	if _sprite:
		_sprite_rest_pos = _sprite.position

# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	var tl: float = $Timer.time_left

	# ── Charge window: last 1 second ─────────────────────────────────────────
	if tl > 0.0 and tl <= 1.0:
		if not is_charging:
			is_charging = true

		charge_progress = clamp(1.0 - tl, 0.0, 1.0)
		var t := charge_progress
		var c := _get_charge_color()

		# Light up sprite with HDR color (on actual visual)
		if _sprite:
			_sprite.modulate = Color(
				lerp(1.0, c.r, t),
				lerp(1.0, c.g, t),
				lerp(1.0, c.b, t)
			)
			# Horizontal vibration: gets stronger as charge increases
			var vib := sin(Time.get_ticks_msec() * 0.026) * t * 3.5
			_sprite.position = _sprite_rest_pos + Vector2(vib, 0.0)

		queue_redraw()

	elif is_charging:
		is_charging = false
		charge_progress = 0.0

	# ── Muzzle flash soldurma ─────────────────────────────────────────────────
	if flash_active:
		flash_radius += 95.0 * delta
		flash_alpha  -=  5.0 * delta
		if flash_alpha <= 0.0:
			flash_active = false
			flash_radius = 0.0
			flash_alpha  = 0.0
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
func _on_timer_timeout() -> void:
	_launch_ball()

# ─────────────────────────────────────────────────────────────────────────────
func _launch_ball() -> void:
	# Early exit: limit reached or no player
	if balls_fired >= total_balls:
		return
	if player == null:
		return

	var ball        = ball_scene.instantiate()
	var player_node = get_parent().get_node("Player")
	ball.max_damage = 5 + player_node.ball_mastery

	if game and game.next_ball_upgrade != "":
		_last_launch_type = game.next_ball_upgrade   # save for flash color

		ball.can_split    = game.next_ball_upgrade == "split"
		ball.can_electric = game.next_ball_upgrade == "electric"
		ball.can_pierce   = game.next_ball_upgrade == "pierce"
		ball.can_cryo     = game.next_ball_upgrade == "cryo"
		ball.can_glitch   = game.next_ball_upgrade == "glitch"
		ball.can_water    = game.next_ball_upgrade == "water"
		ball.can_fire     = game.next_ball_upgrade == "fire"
		ball.can_leech    = game.next_ball_upgrade == "leech"

		if ball.can_fire:
			ball.max_damage = 6 + player_node.ball_mastery
		if ball.can_water:
			ball.max_damage = 3 + player_node.ball_mastery
		if ball.can_glitch:
			ball.max_damage = 4 + player_node.ball_mastery
		if ball.can_split:
			ball.max_damage = 7 + player_node.split_bonus + player_node.ball_mastery
		elif ball.can_electric:
			ball.max_damage = 9 + player_node.electric_bonus + player_node.ball_mastery
		elif ball.can_pierce:
			ball.max_damage = 10 + player_node.pierce_bonus + player_node.ball_mastery
		elif ball.can_cryo:
			ball.max_damage = 4 + player_node.ball_mastery
		elif ball.can_leech:
			ball.max_damage = 2

		game.next_ball_upgrade = ""
	else:
		if game and game.get_node("Player").has_mimic:
			ball.is_mimic = true
			_last_launch_type = "mimic"
		else:
			ball.is_mimic = false
			_last_launch_type = ""

	ball.global_position = global_position
	get_parent().add_child(ball)   # top sahneye eklendi

	# Increment counter only when ball is actually added to scene
	balls_fired += 1
	if game:
		game.update_ui()           # Update UI immediately

	var direction = (player.global_position - global_position).normalized()
	ball.queue_redraw()
	ball.launch(direction)

	# Charge color fades, sprite returns to rest; then recoil begins
	if _sprite:
		_sprite.modulate = Color(1.0, 1.0, 1.0)
		_sprite.position = _sprite_rest_pos

	_trigger_flash()
	_trigger_recoil()
	queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
# Muzzle flash: neon color based on ball type
func _trigger_flash() -> void:
	match _last_launch_type:
		"electric": flash_color = Color(0.4, 1.8, 4.5)
		"pierce":   flash_color = Color(4.5, 3.5, 0.2)
		"split":    flash_color = Color(4.5, 0.4, 0.3)
		"cryo":     flash_color = Color(0.4, 2.5, 4.5)
		"glitch":   flash_color = Color(3.5, 0.2, 4.0)
		"water":    flash_color = Color(0.2, 1.5, 4.5)
		"fire":     flash_color = Color(4.5, 2.0, 0.2)
		"leech":    flash_color = Color(0.2, 4.0, 0.5)
		"mimic":    flash_color = Color(3.0, 2.5, 4.0)
		_:          flash_color = Color(2.0, 2.0, 3.5)
	flash_active = true
	flash_radius = 3.0
	flash_alpha  = 1.0

# ─────────────────────────────────────────────────────────────────────────────
# Recoil kick: shake sprite back (up) then forward
func _trigger_recoil() -> void:
	if _sprite == null:
		return
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	_shake_tween = create_tween()
	_shake_tween.set_ease(Tween.EASE_OUT)
	_shake_tween.set_trans(Tween.TRANS_CUBIC)
	var rest := _sprite_rest_pos
	_shake_tween.tween_property(_sprite, "position", rest + Vector2(0.0, -9.0), 0.07)
	_shake_tween.tween_property(_sprite, "position", rest + Vector2(0.0,  6.0), 0.07)
	_shake_tween.tween_property(_sprite, "position", rest,                       0.15)

# ─────────────────────────────────────────────────────────────────────────────
# Charge color by ball type (HDR — triggers glow)
func _get_charge_color() -> Color:
	if game == null:
		return Color(2.0, 2.0, 3.5)
	match game.next_ball_upgrade:
		"electric": return Color(0.4, 1.8, 4.5)
		"pierce":   return Color(4.5, 3.5, 0.2)
		"split":    return Color(4.5, 0.4, 0.3)
		"cryo":     return Color(0.4, 2.5, 4.5)
		"glitch":   return Color(3.5, 0.2, 4.0)
		"water":    return Color(0.2, 1.5, 4.5)
		"fire":     return Color(4.5, 2.0, 0.2)
		"leech":    return Color(0.2, 4.0, 0.5)
		_:          return Color(2.0, 2.0, 3.5)

# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	# ── 1) Charged ball at muzzle tip (last 1 second) ─────────────────────────────
	if is_charging and charge_progress > 0.05:
		var t := charge_progress
		var c := _get_charge_color()

		# Outer diffuse ring
		draw_circle(MUZZLE_OFFSET,
			8.0 + t * 24.0,
			Color(c.r * 0.5, c.g * 0.35, c.b * 0.5, t * 0.22))
		# Middle energy sphere
		draw_circle(MUZZLE_OFFSET,
			4.5 + t * 13.0,
			Color(c.r * t, c.g * t * 0.75, c.b * t, t * 0.72))
		# Parlak merkez
		draw_circle(MUZZLE_OFFSET,
			2.0 + t * 5.5,
			Color(c.r * 1.6 * t, c.g * 1.4 * t, c.b * 1.6 * t, t * 0.95))

	# ── 2) Muzzle Flash burst ─────────────────────────────────────────────
	if flash_active and flash_alpha > 0.0:
		var c := flash_color
		var r := flash_radius
		var a := flash_alpha

		# Outer soft halo
		draw_circle(MUZZLE_OFFSET, r * 1.65,
			Color(c.r * 0.45, c.g * 0.35, c.b * 0.45, a * 0.16))
		# Ana patlama diski
		draw_circle(MUZZLE_OFFSET, r,
			Color(c.r, c.g, c.b, a * 0.78))
		# Hot center
		draw_circle(MUZZLE_OFFSET, r * 0.32,
			Color(c.r * 1.3, c.g * 1.2, c.b * 1.3, a))
		# 8 spark rays
		for i in 8:
			var angle   := float(i) * TAU / 8.0
			var ray_end := MUZZLE_OFFSET + Vector2(cos(angle), sin(angle)) * r * 2.1
			draw_line(MUZZLE_OFFSET, ray_end,
				Color(c.r, c.g, c.b, a * 0.42), 1.5)

	# ── 3) Ball type preview ────────────────────────────────────────────────
	if game == null or game.next_ball_upgrade == "":
		return

	var preview_pos = Vector2(0, 30)

	if game.next_ball_upgrade == "electric":
		draw_circle(preview_pos, 8, Color(0.2, 0.5, 1.0))
		draw_arc(preview_pos, 10, 0, TAU, 32, Color(0.5, 0.8, 1.0), 2)
	elif game.next_ball_upgrade == "pierce":
		var points = PackedVector2Array([
			preview_pos + Vector2(-10, 0),
			preview_pos + Vector2(0, -6),
			preview_pos + Vector2(10, 0),
			preview_pos + Vector2(0, 6)
		])
		draw_colored_polygon(points, Color(1.0, 0.8, 0.0))
	elif game.next_ball_upgrade == "split":
		draw_circle(preview_pos, 8, Color(1.0, 0.2, 0.2))
		for i in range(8):
			var angle = i * TAU / 8
			var start = preview_pos + Vector2(cos(angle), sin(angle)) * 8
			var end   = preview_pos + Vector2(cos(angle), sin(angle)) * 13
			draw_line(start, end, Color(1.0, 0.4, 0.0), 2)
	elif game.next_ball_upgrade == "cryo":
		var pts = PackedVector2Array([
			preview_pos + Vector2(0, -8),
			preview_pos + Vector2(5, -4),
			preview_pos + Vector2(5, 4),
			preview_pos + Vector2(0, 8),
			preview_pos + Vector2(-5, 4),
			preview_pos + Vector2(-5, -4)
		])
		draw_colored_polygon(pts, Color(0.5, 0.8, 1.0))
		draw_line(preview_pos + Vector2(0, -8),  preview_pos + Vector2(0, 8),   Color(0.8, 1.0, 1.0, 0.8), 1.5)
		draw_line(preview_pos + Vector2(-5, -4), preview_pos + Vector2(5, 4),   Color(0.8, 1.0, 1.0, 0.8), 1.5)
		draw_line(preview_pos + Vector2(5, -4),  preview_pos + Vector2(-5, 4),  Color(0.8, 1.0, 1.0, 0.8), 1.5)
	elif game.next_ball_upgrade == "glitch":
		draw_circle(preview_pos, 8, Color(0.8, 0.0, 0.8))
		draw_arc(preview_pos, 10, 0, TAU, 32, Color(1.0, 0.0, 1.0), 2)
		draw_line(preview_pos + Vector2(-6, -4), preview_pos + Vector2(6, 4),  Color(1.0, 0.5, 1.0, 0.8), 2)
		draw_line(preview_pos + Vector2(-6, 4),  preview_pos + Vector2(6, -4), Color(1.0, 0.5, 1.0, 0.8), 2)
	elif game.next_ball_upgrade == "water":
		draw_circle(preview_pos, 10, Color(0.0, 0.5, 1.0, 0.8))
		draw_circle(preview_pos, 7,  Color(0.3, 0.7, 1.0, 0.6))
		draw_circle(preview_pos + Vector2(3, -3), 3, Color(0.8, 0.9, 1.0, 0.5))
	elif game.next_ball_upgrade == "fire":
		draw_circle(preview_pos, 8, Color(1.0, 0.3, 0.0))
		draw_arc(preview_pos, 10, 0, TAU, 32, Color(1.0, 0.6, 0.0), 2)
	elif game.next_ball_upgrade == "leech":
		draw_circle(preview_pos, 8, Color(0.0, 0.8, 0.0, 0.9))
		draw_arc(preview_pos, 10, 0, TAU, 32, Color(0.0, 1.0, 0.0), 2)
		for i in range(6):
			var angle = i * TAU / 6
			var start = preview_pos + Vector2(cos(angle), sin(angle)) * 10
			var end   = preview_pos + Vector2(cos(angle), sin(angle)) * 15
			draw_line(start, end, Color(0.0, 1.0, 0.2), 2)
		draw_circle(preview_pos, 3, Color(0.5, 1.0, 0.5))
