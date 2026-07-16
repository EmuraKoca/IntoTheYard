extends Control

const PANELS: Array[String] = [
	"res://assets/story/intro/visuals/opening_001.png",
	"res://assets/story/intro/visuals/opening_002.png",
	"res://assets/story/intro/visuals/opening_003.png",
	"res://assets/story/intro/visuals/opening_004.png",
	"res://assets/story/intro/visuals/opening_005.png",
]
const NEXT_SCENE      := "res://game_scene.tscn"
const PANEL_FADE_IN   := 0.7
const PANEL_DELAY     := 1.3
const HOLD_AFTER_LAST := 2.5

var _panels: Array[Node2D] = []
var _flash:  ColorRect
var _audio:  AudioStreamPlayer
var _done := false

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Viewport boyutu _ready'de hazır
	_build_scene()
	_audio.play()
	_show_panels_sequence()
	_lightning_loop()

# ─────────────────────────────────────────────────────────────────────────────
func _build_scene() -> void:
	var screen := get_viewport_rect().size   # örn. Vector2(1280, 720)

	# Siyah arka plan
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size  = screen
	add_child(bg)

	# Layout:
	#  [1] [2]
	#  [3] [4]
	#  [ 5 ]

	var textures: Array[Texture2D] = []
	for path in PANELS:
		var tex: Texture2D = load(path)
		if tex == null:
			push_warning("Intro panel yüklenemedi: " + path)
		textures.append(tex)

	var half_w := screen.x * 0.5

	# Her satırın doğal yüksekliği (yarı genişliğe göre)
	var row1_h := 0.0
	var row2_h := 0.0
	for i in [0, 1]:
		if textures[i]:
			row1_h = max(row1_h, half_w * textures[i].get_height() / textures[i].get_width())
	for i in [2, 3]:
		if textures[i]:
			row2_h = max(row2_h, half_w * textures[i].get_height() / textures[i].get_width())

	var row3_h := 0.0
	if textures[4]:
		row3_h = screen.x * textures[4].get_height() / textures[4].get_width()

	# Tümü ekran yüksekliğine sığsın
	var total_h := row1_h + row2_h + row3_h
	var hs      := screen.y / total_h if total_h > 0.0 else 1.0
	row1_h *= hs;  row2_h *= hs;  row3_h *= hs

	# Hedef pos + size — kırpma yok, tam ölçek
	var cell_pos := [
		Vector2(0.0,    0.0),
		Vector2(half_w, 0.0),
		Vector2(0.0,    row1_h),
		Vector2(half_w, row1_h),
	]
	var cell_size := [
		Vector2(half_w, row1_h),
		Vector2(half_w, row1_h),
		Vector2(half_w, row2_h),
		Vector2(half_w, row2_h),
	]

	for i in range(4):
		if not textures[i]: continue
		var spr := Sprite2D.new()
		spr.texture    = textures[i]
		spr.centered   = false
		spr.position   = cell_pos[i]
		spr.scale      = Vector2(
			cell_size[i].x / textures[i].get_width(),
			cell_size[i].y / textures[i].get_height()
		)
		spr.modulate.a = 0.0
		add_child(spr)
		_panels.append(spr)

	# Panel 5 — tam genişlik
	if textures[4]:
		var spr5 := Sprite2D.new()
		spr5.texture    = textures[4]
		spr5.centered   = false
		spr5.position   = Vector2(0.0, row1_h + row2_h)
		spr5.scale      = Vector2(
			screen.x / textures[4].get_width(),
			row3_h   / textures[4].get_height()
		)
		spr5.modulate.a = 0.0
		add_child(spr5)
		_panels.append(spr5)

	# Yağmur efekti
	_build_rain(screen)

	# Şimşek flash overlay
	_flash          = ColorRect.new()
	_flash.color    = Color(1.0, 1.0, 1.0, 0.0)
	_flash.size     = screen
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	# Ses
	_audio        = AudioStreamPlayer.new()
	_audio.stream = load("res://assets/story/intro/audio/rainThunder.ogg")
	_audio.volume_db = -6.0
	add_child(_audio)

# ─────────────────────────────────────────────────────────────────────────────
func _build_rain(screen: Vector2) -> void:
	var rain := CPUParticles2D.new()
	rain.amount        = 250
	rain.lifetime      = 1.0
	rain.emitting      = true
	rain.z_index       = 20
	rain.z_as_relative = false
	rain.position      = Vector2(screen.x * 0.5, -5.0)

	rain.emission_shape        = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(screen.x * 0.5, 2.0)

	rain.direction             = Vector2(0.15, 1.0)
	rain.spread                = 3.0
	rain.initial_velocity_min  = 480.0
	rain.initial_velocity_max  = 640.0
	rain.gravity               = Vector2.ZERO
	rain.scale_amount_min      = 2.0
	rain.scale_amount_max      = 4.0
	rain.color                 = Color(0.75, 0.88, 1.0, 0.28)
	add_child(rain)

# ─────────────────────────────────────────────────────────────────────────────
func _show_panels_sequence() -> void:
	for i in range(_panels.size()):
		var tw := create_tween()
		tw.tween_interval(i * PANEL_DELAY)
		tw.tween_property(_panels[i], "modulate:a", 1.0, PANEL_FADE_IN)

	var total := (_panels.size() - 1) * PANEL_DELAY + PANEL_FADE_IN + HOLD_AFTER_LAST
	await get_tree().create_timer(total).timeout
	_finish()

# ─────────────────────────────────────────────────────────────────────────────
func _lightning_loop() -> void:
	while not _done:
		await get_tree().create_timer(randf_range(1.8, 4.5)).timeout
		if _done: break
		_flash.color.a = randf_range(0.4, 0.75)
		var tw := create_tween()
		tw.tween_property(_flash, "color:a", 0.0, randf_range(0.10, 0.22))

# ─────────────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _done: return
	if event is InputEventKey        and event.pressed: _finish()
	if event is InputEventMouseButton and event.pressed: _finish()

# ─────────────────────────────────────────────────────────────────────────────
func _finish() -> void:
	if _done: return
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.9)
	await tw.finished
	get_tree().change_scene_to_file(NEXT_SCENE)
