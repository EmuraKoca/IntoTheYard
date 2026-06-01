extends Node2D
# Mr. Hasmen — sahaya giriş sekansı
# Kullanım: play_entrance(start_pos, mid_pos, chair_pos)

const WALK_BASE := "res://assets/npcs/mrHasmen/animations/animation-eb40b4de/"
const IDLE_BASE := "res://assets/npcs/mrHasmen/animations/Breathing_Idle-7fa09e2e/"
const WALK_SPEED := 72.0   # px/s

var _sprite: AnimatedSprite2D = null

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	z_index = 4

	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale          = Vector2(0.9, 0.9)
	_sprite.visible        = false
	add_child(_sprite)

	_setup_frames()

# ─────────────────────────────────────────────────────────────────────────────
func _setup_frames() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	# [anim_name, klasör_yolu, frame_sayısı, fps]
	var defs := [
		["walk_north", WALK_BASE + "north/", 6, 8.0],
		["walk_west",  WALK_BASE + "west/",  6, 8.0],
		["idle_east",  IDLE_BASE + "east/",  4, 4.0],
	]

	for d in defs:
		var anim  : String  = d[0]
		var path  : String  = d[1]
		var count : int     = d[2]
		var fps   : float   = d[3]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, fps)
		frames.set_animation_loop(anim, true)
		for i in range(count):
			var tex: Texture2D = load(path + "frame_%03d.png" % i)
			frames.add_frame(anim, tex)

	_sprite.sprite_frames = frames

# ─────────────────────────────────────────────────────────────────────────────
# start_pos  → giriş noktası (ekran dışı güney)
# mid_pos    → kuzey koridoru sonu (sağa dönüş noktası)
# chair_pos  → sandalye (doğuya bakarak idle)
func play_entrance(start_pos: Vector2, mid_pos: Vector2, chair_pos: Vector2) -> void:
	position        = start_pos
	_sprite.visible = true

	# 1 ── Kuzey'e yürü
	_sprite.play("walk_north")
	var t1: float = start_pos.distance_to(mid_pos) / WALK_SPEED
	var tw1 := create_tween()
	tw1.tween_property(self, "position", mid_pos, t1)\
		.set_trans(Tween.TRANS_LINEAR)
	await tw1.finished

	# Köşe dönüşünde kısa durakla
	await get_tree().create_timer(0.12).timeout

	# 2 ── Batı'ya yürü (sandalyeye doğru)
	_sprite.play("walk_west")
	var t2: float = mid_pos.distance_to(chair_pos) / WALK_SPEED
	var tw2 := create_tween()
	tw2.tween_property(self, "position", chair_pos, t2)\
		.set_trans(Tween.TRANS_LINEAR)
	await tw2.finished

	# 3 ── Sandalyeye oturdu, doğuya bakıyor — oyunu izliyor
	_sprite.play("idle_east")
