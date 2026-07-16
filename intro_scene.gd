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

var _panels:     Array[Node2D] = []
var _fx_layers:  Array[Node2D] = []
var _audio:      AudioStreamPlayer
var _done        := false
var _next_panel  := 0          # sıradaki açılacak panel indexi
var _auto_timer: SceneTreeTimer = null

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	var menu_music := get_tree().root.get_node_or_null("MenuMusic")
	if menu_music:
		menu_music.queue_free()
	_build_scene()
	_audio.play()
	_advance()

# ─────────────────────────────────────────────────────────────────────────────
func _build_scene() -> void:
	var screen := get_viewport_rect().size

	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size  = screen
	add_child(bg)

	var textures: Array[Texture2D] = []
	for path in PANELS:
		var tex: Texture2D = load(path)
		if tex == null:
			push_warning("Intro panel yüklenemedi: " + path)
		textures.append(tex)

	var half_w := screen.x * 0.5

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

	var total_h := row1_h + row2_h + row3_h
	var hs      := screen.y / total_h if total_h > 0.0 else 1.0
	row1_h *= hs;  row2_h *= hs;  row3_h *= hs

	# Sıra: 1(sağ üst), 2(sol üst), 3(sağ alt), 4(sol alt), 5(tam genişlik)
	var rects: Array[Rect2] = [
		Rect2(half_w, 0.0,             half_w,   row1_h),
		Rect2(0.0,    0.0,             half_w,   row1_h),
		Rect2(half_w, row1_h,          half_w,   row2_h),
		Rect2(0.0,    row1_h,          half_w,   row2_h),
		Rect2(0.0,    row1_h + row2_h, screen.x, row3_h),
	]

	for i in range(5):
		if not textures[i]: continue
		var r: Rect2 = rects[i]

		var spr := Sprite2D.new()
		spr.texture    = textures[i]
		spr.centered   = false
		spr.position   = r.position
		spr.scale      = Vector2(r.size.x / textures[i].get_width(),
								 r.size.y / textures[i].get_height())
		spr.modulate.a = 0.0
		add_child(spr)
		_panels.append(spr)

		var fx: Node2D = load("res://panel_fx.gd").new()
		fx.position      = r.position
		fx.set("size", r.size)
		fx.z_index       = 5
		fx.z_as_relative = false
		fx.modulate.a    = 0.0
		add_child(fx)
		_fx_layers.append(fx)

	_audio          = AudioStreamPlayer.new()
	_audio.stream   = load("res://assets/story/intro/audio/rainThunder.ogg")
	_audio.volume_db = -6.0
	add_child(_audio)

# ─────────────────────────────────────────────────────────────────────────────
# Sıradaki paneli göster; tümü bittiyse otomatik timer başlat
func _advance() -> void:
	if _done: return

	if _next_panel < _panels.size():
		var i := _next_panel
		_next_panel += 1

		var tw := create_tween()
		tw.tween_property(_panels[i], "modulate:a", 1.0, PANEL_FADE_IN)
		var tw2 := create_tween()
		tw2.tween_property(_fx_layers[i], "modulate:a", 1.0, PANEL_FADE_IN)

		# Son panel gösterildiyse otomatik çıkış sayacını başlat
		if _next_panel >= _panels.size():
			_auto_timer = get_tree().create_timer(HOLD_AFTER_LAST)
			_auto_timer.timeout.connect(_finish)
	else:
		# Tümü açık, tıklama çıkışı tetikledi
		_finish()

# ─────────────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _done: return
	var pressed: bool = (event is InputEventKey and (event as InputEventKey).pressed) or \
				   (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if not pressed: return

	# Otomatik sayacı iptal et — kullanıcı devralıyor
	if _auto_timer != null:
		_auto_timer.timeout.disconnect(_finish)
		_auto_timer = null

	_advance()

# ─────────────────────────────────────────────────────────────────────────────
func _finish() -> void:
	if _done: return
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.9)
	await tw.finished
	get_tree().change_scene_to_file(NEXT_SCENE)
