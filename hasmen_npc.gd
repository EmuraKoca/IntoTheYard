extends Node2D
# Mr. Hasmen — sahaya giriş sekansı
# Kullanım: play_entrance(start_pos, mid_pos, chair_pos)

const WALK_BASE := "res://assets/npcs/mrHasmen/animations/animation-eb40b4de/"
const SIT_BASE      := "res://assets/npcs/mrHasmen/animations/sit/"
const SIT_IDLE_BASE := "res://assets/npcs/mrHasmen/animations/sitIdle/"
const WALK_SPEED := 72.0   # px/s

# Oturma animasyonu frame aralıkları (saniye)
const SIT_IDLE_INTERVAL_MIN := 2.0
const SIT_IDLE_INTERVAL_MAX := 4.5

var _sprite: AnimatedSprite2D = null

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	z_index = 20

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

	# Yürüyüş animasyonları (loop)
	var walk_defs := [
		["walk_north", WALK_BASE + "north/", 6, 8.0],
		["walk_west",  WALK_BASE + "west/",  6, 8.0],
	]
	for d in walk_defs:
		var anim  : String = d[0]
		var path  : String = d[1]
		var count : int    = d[2]
		var fps   : float  = d[3]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, fps)
		frames.set_animation_loop(anim, true)
		for i in range(count):
			var tex: Texture2D = load(path + "frame_%03d.png" % i)
			frames.add_frame(anim, tex)

	# sit_intro: frame 000-004 — bir kez oynuyor (oturma eylemi)
	frames.add_animation("sit_intro")
	frames.set_animation_speed("sit_intro", 8.0)
	frames.set_animation_loop("sit_intro", false)
	for i in range(5):
		var tex: Texture2D = load(SIT_BASE + "frame_%03d.png" % i)
		frames.add_frame("sit_intro", tex)

	# sit_idle: sitIdle klasöründen — aralıklı oynuyor (nefes/hareket)
	frames.add_animation("sit_idle")
	frames.set_animation_speed("sit_idle", 8.0)
	frames.set_animation_loop("sit_idle", false)
	for i in range(6, 17):
		var tex: Texture2D = load(SIT_IDLE_BASE + "frame_%03d.png" % i)
		frames.add_frame("sit_idle", tex)

	_sprite.sprite_frames = frames

# ─────────────────────────────────────────────────────────────────────────────
# start_pos → giriş noktası (ekran dışı güney)
# mid_pos   → kuzey koridoru sonu (dönüş noktası)
# chair_pos → sandalye
func play_entrance(start_pos: Vector2, mid_pos: Vector2, chair_pos: Vector2) -> void:
	position        = start_pos
	_sprite.visible = true

	# 1 ── Kuzey'e yürü
	_sprite.play("walk_north")
	var t1: float = start_pos.distance_to(mid_pos) / WALK_SPEED
	var tw1: Tween = create_tween()
	tw1.tween_property(self, "position", mid_pos, t1)\
		.set_trans(Tween.TRANS_LINEAR)
	await tw1.finished

	# Köşe dönüşünde kısa durakla
	await get_tree().create_timer(0.12).timeout

	# 2 ── Batı'ya yürü (sandalyeye doğru)
	_sprite.play("walk_west")
	var t2: float = mid_pos.distance_to(chair_pos) / WALK_SPEED
	var tw2: Tween = create_tween()
	tw2.tween_property(self, "position", chair_pos, t2)\
		.set_trans(Tween.TRANS_LINEAR)
	await tw2.finished

	# 3 ── Oturma açılış animasyonu (ilk 5 frame, bir kez)
	_sprite.play("sit_intro")
	await _sprite.animation_finished

	# 4 ── Son frame'de bekle ve aralıklı sit_idle oyna
	_sit_idle_loop()

# ─────────────────────────────────────────────────────────────────────────────
func _sit_idle_loop() -> void:
	while is_instance_valid(self):
		# Rastgele aralıkta bekle
		var wait: float = randf_range(SIT_IDLE_INTERVAL_MIN, SIT_IDLE_INTERVAL_MAX)
		await get_tree().create_timer(wait).timeout

		if not is_instance_valid(self):
			return

		# 3 frame'lik idle hareketi — bir kez oynat
		_sprite.play("sit_idle")
		await _sprite.animation_finished
