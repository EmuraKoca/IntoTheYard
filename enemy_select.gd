extends Control
# Demo: karakter seçiminden sonra düşman türü seçimi (CyberHuman / CyberCreature).
# Seçim GameData.enemy_style'a yazılır; devamında GameData.pending_scene açılır.

const CYAN := Color(0, 0.95, 1, 1)
const PINK := Color(1, 0.18, 0.58, 1)
var _font: Font = load("res://assets/silverfont/Silver.ttf")

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.01, 0.04, 1)
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := _label(Lang.t("es_title"), 95, Color(1, 0.8, 0))
	title.position = Vector2(0, 90)
	title.size = Vector2(1920, 140)
	add_child(title)

	_make_card(Vector2(280, 270), "human", Lang.t("es_human"), Lang.t("es_human_desc"), _human_preview())
	_make_card(Vector2(1000, 270), "creature", Lang.t("es_creature"), Lang.t("es_creature_desc"), _creature_preview())

	var back := Button.new()
	back.text = Lang.t("ui_back")
	back.position = Vector2(755, 900)
	back.size = Vector2(410, 70)
	back.icon = load("res://assets/menuIcons/back.png")
	back.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	back.add_theme_font_override("font", _font)
	back.add_theme_font_size_override("font_size", 38)
	back.add_theme_color_override("font_color", PINK)
	back.add_theme_color_override("font_hover_color", Color(1, 0.6, 0.8))
	back.set_meta("sfx_click", "backQuitCancel")
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://character_select.tscn"))
	add_child(back)

func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.modulate = col
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _human_preview() -> Texture2D:
	var path := "res://assets/enemys/cyberRifle/sheets/cyberrifle_idle_S.png"
	if not ResourceLoader.exists(path): return null
	var at := AtlasTexture.new()
	at.atlas = load(path)
	at.region = Rect2(0, 0, 124, 124)
	return at

func _creature_preview() -> Texture2D:
	var path := "res://assets/newEnemies/cyberRifle/Idle/animations/walk/south/frame_000.png"
	if not ResourceLoader.exists(path): return null
	return load(path)

func _make_card(pos: Vector2, style: String, title: String, desc: String, preview: Texture2D) -> void:
	var btn := Button.new()
	btn.position = pos
	btn.size = Vector2(640, 560)
	btn.add_theme_stylebox_override("normal", _box(Color(0.02, 0.06, 0.1, 0.9), 0.35))
	btn.add_theme_stylebox_override("hover", _box(Color(0.04, 0.12, 0.2, 0.95), 1.0))
	btn.add_theme_stylebox_override("pressed", _box(Color(0.04, 0.12, 0.2, 0.95), 1.0))
	btn.set_meta("sfx_click", "characterSelect")
	btn.pressed.connect(func(): _choose(style))
	add_child(btn)
	if preview:
		var pic := TextureRect.new()
		pic.texture = preview
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.position = Vector2(120, 30)
		pic.size = Vector2(400, 330)
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(pic)
	var t := _label(title, 57, CYAN)
	t.position = Vector2(0, 385)
	t.size = Vector2(640, 70)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(t)
	var d := _label(desc, 38, Color(0.82, 0.92, 1, 1))
	d.position = Vector2(20, 465)
	d.size = Vector2(600, 80)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(d)

func _box(bg: Color, border_alpha: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = Color(CYAN.r, CYAN.g, CYAN.b, border_alpha)
	s.set_border_width_all(3)
	s.set_corner_radius_all(6)
	return s

func _choose(style: String) -> void:
	GameData.enemy_style = style
	get_tree().change_scene_to_file(GameData.pending_scene)
