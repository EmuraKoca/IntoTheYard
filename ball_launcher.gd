extends Node2D

var ball_scene = preload("res://ball.tscn")
var player = null
var game   = null

# ── Başlangıç sekansı: 3 top, 2'şer saniye arayla ────────────────────────────
var _startup_balls_left: int  = 0
var _startup_timer: float     = 0.0
var _startup_active: bool     = false
var _startup_fired: int       = 0   # kaç top fırlatıldı (tip hesabı için)

# Upgrade'den gelen top kuyruğu
var _pending_upgrades: Array  = []
var _upgrade_timer: float     = 0.0

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

# ── Preview sprite ────────────────────────────────────────────────────────────
var _preview_sprite: AnimatedSprite2D = null
var _preview_shown_type: String = ""
const _PREVIEW_FOLDER_MAP: Dictionary = {
	"electric":   ["electricBall",    9],
	"pierce":     ["pierceBall",      9],
	"split":      ["splitBall",       9],
	"cryo":       ["cryoBall",        9],
	"glitch":     ["glitchBall",      9],
	"water":      ["waterBall",       9],
	"fire":       ["fireBall",        9],
	"leech":      ["dataLeechBall",   9],
	"mimic":      ["echoBall",        9],
	"armor":      ["armorCore",       9],
	"anchor":     ["anchorCore",      9],
	"crusher":    ["crusherCore",     9],
	"kinetic":    ["kineticCore",     9],
	"bulwark":    ["bulwarkCore",     9],
	"siege":      ["siegeCore",       9],
	"bloodbound": ["bloodboundCore",  9],
	"tempered":   ["temperedCore",    9],
}

# Muzzle tip in sprite-local space (tune Y to match the visual barrel tip)
const MUZZLE_SPRITE_LOCAL := Vector2(0.0, 60.0)

# ─────────────────────────────────────────────────────────────────────────────
# Returns the muzzle tip in global space, derived from the sprite's transform.
# This accounts for the sprite's rotation so the flash and ball origin are exact.
func _get_muzzle_global() -> Vector2:
	if _sprite:
		return _sprite.to_global(MUZZLE_SPRITE_LOCAL)
	return global_position

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	player = get_parent().get_node("Player")
	game   = get_parent()

	$ColorRect.visible = false
	visible       = true
	z_index       = 10
	z_as_relative = false

	_sprite = get_parent().get_node_or_null("BallLauncherSprite") as Sprite2D
	if _sprite:
		_sprite_rest_pos = _sprite.position

	_preview_sprite = AnimatedSprite2D.new()
	_preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview_sprite.scale = Vector2(0.55, 0.55)
	_preview_sprite.position = Vector2(0, 30)
	_preview_sprite.visible = false
	add_child(_preview_sprite)

	# Başlangıç sekansı: ilk top hemen, sonrakiler 2s arayla
	_startup_balls_left = 2      # ilkini hemen fırlatacağız, kalan 2
	_startup_active     = true
	_startup_timer      = 2.0    # process döngüsü 2s bekleyecek (anında ikinci top gitmesin)
	_startup_fired      = 0
	_launch_startup_ball()       # 1. top hemen

func _launch_startup_ball() -> void:
	if player == null: return
	var type := _get_character_start_type()
	_launch_typed_ball(type)
	_last_launch_type = type
	_startup_fired += 1

func _get_character_start_type() -> String:
	# _startup_fired: 0 → normal, 1 → normal, 2 → karaktere özel
	if _startup_fired < 2:
		return ""   # normal
	match player.character_type:
		"vector":  return ""
		"leila":
			var pool := ["fire", "water", "cryo", "electric"]
			return pool[randi() % pool.size()]
		"cyclone": return "glitch"
	return ""

func queue_upgrade_ball(ball_type: String) -> void:
	_pending_upgrades.append(ball_type)
	if _pending_upgrades.size() == 1:
		_upgrade_timer = 2.0   # ilk upgrade bekleme

func _update_preview_sprite() -> void:
	var next_type: String = game.next_ball_upgrade if game else ""
	if next_type == _preview_shown_type:
		return
	_preview_shown_type = next_type
	if next_type == "" or not _PREVIEW_FOLDER_MAP.has(next_type):
		_preview_sprite.visible = false
		return
	var info: Array = _PREVIEW_FOLDER_MAP[next_type]
	var folder: String = info[0]
	var frame_count: int = info[1]
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 12.0)
	frames.set_animation_loop("spin", true)
	for i in range(frame_count):
		frames.add_frame("spin", load("res://assets/balls/%s/frame_%03d.png" % [folder, i]))
	_preview_sprite.sprite_frames = frames
	_preview_sprite.play("spin")
	_preview_sprite.visible = true

# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	_update_preview_sprite()

	# ── Başlangıç sekansı ─────────────────────────────────────────────────────
	if _startup_active and _startup_balls_left > 0:
		_startup_timer -= delta
		if _startup_timer <= 0.0:
			_startup_balls_left -= 1
			_launch_startup_ball()
			if _startup_balls_left > 0:
				_startup_timer = 2.0
			else:
				_startup_active = false

	# ── Upgrade top kuyruğu ───────────────────────────────────────────────────
	if not _pending_upgrades.is_empty():
		_upgrade_timer -= delta
		if _upgrade_timer <= 0.0:
			var utype: String = _pending_upgrades.pop_front()
			_launch_typed_ball(utype)
			_last_launch_type = utype
			if not _pending_upgrades.is_empty():
				_upgrade_timer = 2.0

	# ── Charge window: last 1 second (artık Timer yerine upgrade zaman) ───────
	var tl: float = _upgrade_timer if not _pending_upgrades.is_empty() else 0.0

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
func _launch_typed_ball(ball_type: String) -> void:
	if player == null: return
	var player_node = get_parent().get_node("Player")
	var _current_balls := get_tree().get_nodes_in_group("player_balls")
	_current_balls = _current_balls.filter(func(b): return is_instance_valid(b))
	# İç yörünge core'ları MAX_ORBIT limitine dahil değil
	var is_inner := ball_type in ["antivirus"]
	if not is_inner and _current_balls.size() >= player_node.MAX_ORBIT:
		return

	var ball = ball_scene.instantiate()
	var vector_bonus: int = 3 if player_node.character_type == "vector" else 0
	ball.max_damage = 5 + player_node.ball_mastery + vector_bonus

	match ball_type:
		"split":
			ball.can_split    = true
			ball.max_damage   = 7 + player_node.split_bonus + player_node.ball_mastery
		"electric":
			ball.can_electric = true
			ball.max_damage   = 9 + player_node.electric_bonus + player_node.ball_mastery
		"pierce":
			ball.can_pierce   = true
			ball.max_damage   = 10 + player_node.pierce_bonus + player_node.ball_mastery
		"cryo":
			ball.can_cryo     = true
			ball.max_damage   = 4 + player_node.cryo_bonus + player_node.ball_mastery
		"glitch":
			ball.can_glitch   = true
			ball.max_damage   = 4 + player_node.ball_mastery
		"water":
			ball.can_water    = true
			ball.max_damage   = 3 + player_node.hydro_bonus + player_node.ball_mastery
		"fire":
			ball.can_fire     = true
			ball.max_damage   = 6 + player_node.pyro_bonus + player_node.ball_mastery
		"leech":
			ball.can_leech    = true
			ball.max_damage   = 2
		"mimic":
			ball.is_mimic     = true
		# ── Vector yeni core'lar ──────────────────────────────────────────────
		"armor":
			ball.can_armor    = true
			ball.max_damage   = 5 + player_node.ball_mastery
		"anchor":
			ball.can_anchor   = true
			ball.max_damage   = 8 + player_node.ball_mastery
		"crusher":
			ball.can_crusher  = true
			ball.max_damage   = 12 + player_node.ball_mastery
		"kinetic":
			ball.can_kinetic  = true
			ball.max_damage   = 7 + player_node.ball_mastery
		"bulwark":
			ball.can_bulwark  = true
			ball.max_damage   = 6 + player_node.ball_mastery
		"siege":
			ball.can_siege    = true
			ball.max_damage   = 15 + player_node.ball_mastery
		"bloodbound":
			ball.can_bloodbound = true
			ball.max_damage   = 8 + player_node.ball_mastery
		"tempered":
			ball.can_tempered = true
			ball.max_damage   = 9 + player_node.ball_mastery
		# ── Leila yeni core'lar ───────────────────────────────────────────────
		"plasma":
			ball.can_plasma   = true
			ball.can_electric = true
			ball.max_damage   = 7 + player_node.ball_mastery
		"steam":
			ball.can_steam    = true
			ball.can_water    = true
			ball.max_damage   = 5 + player_node.ball_mastery
		"arc":
			ball.can_arc      = true
			ball.can_electric = true
			ball.max_damage   = 6 + player_node.ball_mastery
		"echo":
			ball.can_echo     = true
			ball.max_damage   = 5 + player_node.ball_mastery
		"orbit":
			ball.can_orbit    = true
			ball.max_damage   = 4 + player_node.ball_mastery
		"scatter":
			ball.can_scatter  = true
			ball.max_damage   = 4 + player_node.ball_mastery
		"catalyst":
			ball.can_catalyst = true
			ball.max_damage   = 5 + player_node.ball_mastery
		"voltaic":
			ball.can_voltaic  = true
			ball.can_electric = true
			ball.max_damage   = 8 + player_node.ball_mastery
		"tempest":
			ball.can_tempest  = true
			ball.max_damage   = 6 + player_node.ball_mastery
		"prismatic":
			ball.can_prismatic = true
			ball.max_damage    = 5 + player_node.ball_mastery
		# ── Cyclone iç yörünge core'ları ─────────────────────────────────────
		"antivirus":
			ball.is_inner_core = true
			ball.max_damage    = 0  # Hasar vermez, sadece Antivirus uygular

	var direction  = (player.global_position - global_position).normalized()
	var spawn_pos  = _get_muzzle_global()
	if spawn_pos.x < 875.0 and direction.x > 0.0:
		var t = (875.0 - spawn_pos.x) / direction.x
		spawn_pos += direction * (t + 2.0)

	ball.global_position = spawn_pos
	ball.add_to_group("player_balls")
	get_parent().add_child.call_deferred(ball)
	ball.queue_redraw()
	ball.launch(direction)

	if _sprite:
		_sprite.modulate = Color(1.0, 1.0, 1.0)
		_sprite.position = _sprite_rest_pos

	_trigger_flash()
	_trigger_recoil()
	queue_redraw()

	if game:
		game.update_ui()

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
	# Muzzle position in this node's local space (sprite-aware)
	var muzzle := to_local(_get_muzzle_global())

	# ── 1) Charged ball at muzzle tip (last 1 second) ─────────────────────────────
	if is_charging and charge_progress > 0.05:
		var t := charge_progress
		var c := _get_charge_color()

		# Outer diffuse ring
		draw_circle(muzzle,
			8.0 + t * 24.0,
			Color(c.r * 0.5, c.g * 0.35, c.b * 0.5, t * 0.22))
		# Middle energy sphere
		draw_circle(muzzle,
			4.5 + t * 13.0,
			Color(c.r * t, c.g * t * 0.75, c.b * t, t * 0.72))
		# Parlak merkez
		draw_circle(muzzle,
			2.0 + t * 5.5,
			Color(c.r * 1.6 * t, c.g * 1.4 * t, c.b * 1.6 * t, t * 0.95))

	# ── 2) Muzzle Flash burst ─────────────────────────────────────────────
	if flash_active and flash_alpha > 0.0:
		var c := flash_color
		var r := flash_radius
		var a := flash_alpha

		# Outer soft halo
		draw_circle(muzzle, r * 1.65,
			Color(c.r * 0.45, c.g * 0.35, c.b * 0.45, a * 0.16))
		# Ana patlama diski
		draw_circle(muzzle, r,
			Color(c.r, c.g, c.b, a * 0.78))
		# Hot center
		draw_circle(muzzle, r * 0.32,
			Color(c.r * 1.3, c.g * 1.2, c.b * 1.3, a))
		# 8 spark rays
		for i in 8:
			var angle   := float(i) * TAU / 8.0
			var ray_end := muzzle + Vector2(cos(angle), sin(angle)) * r * 2.1
			draw_line(muzzle, ray_end,
				Color(c.r, c.g, c.b, a * 0.42), 1.5)
