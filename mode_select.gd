extends Control
# Yeni Oyun → mod seçimi (Story / Survival). Seçim GameData.game_mode'a yazılır, ardından karakter seçimi açılır.

const CYAN := Color(0.0, 0.95, 1.0)
const PINK := Color(1.0, 0.18, 0.58)
var _font: Font = load("res://assets/silverfont/Silver.ttf")

func _tr() -> bool:
	return Lang.locale == "tr"

func _ready() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/menuBackground/mainMenuBackground.png")
	bg.size = Vector2(1920, 1080)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0.01, 0.04, 0.6)
	dim.size = Vector2(1920, 1080)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var title := _label("OYUN MODU" if _tr() else "GAME MODE", 95, Color(1.0, 0.85, 0.0))
	title.position = Vector2(0, 90)
	title.size = Vector2(1920, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	_make_card(Vector2(310, 270), CYAN, "story",
		"HİKAYE" if _tr() else "STORY",
		"Boss'ları sırayla yen, zorluk seviyelerini aç.\nSabit arenada, sandıktan çıkan boss'a karşı." if _tr() \
		else "Beat the bosses in order and unlock difficulty levels.\nFixed arena, boss crashes in from a crate.")
	_make_card(Vector2(1010, 270), PINK, "survival",
		"HAYATTA KALMA" if _tr() else "SURVIVAL",
		"Sınırsız mod: düşmanlar dört bir yandan gelir.\nKamera seni takip eder. Ölene kadar dayan, sonunda boss'lar gelir." if _tr() \
		else "Endless mode: enemies swarm from every side.\nThe camera follows you. Last as long as you can; bosses come at the end.")

	var back := _neon_button("GERİ" if _tr() else "BACK", "back", PINK, Vector2(775, 900), Vector2(370, 70))
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://main_menu.tscn"))
	add_child(back)

func _make_card(pos: Vector2, col: Color, mode: String, name_txt: String, desc: String) -> void:
	var card := Panel.new()
	card.position = pos
	card.size = Vector2(600, 520)
	card.add_theme_stylebox_override("panel", _card_style(col, false))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	var nm := _label(name_txt, 76, col)
	nm.position = Vector2(pos.x, pos.y + 70)
	nm.size = Vector2(600, 100)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(nm)
	var ds := _label(desc, 19, Color(0.8, 0.85, 0.95))
	ds.position = Vector2(pos.x + 40, pos.y + 210)
	ds.size = Vector2(520, 180)
	ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(ds)
	var btn := _neon_button("SEÇ" if _tr() else "SELECT", "play", col, Vector2(pos.x + 115, pos.y + 400), Vector2(370, 70))
	btn.pressed.connect(_choose.bind(mode))
	add_child(btn)

func _choose(mode: String) -> void:
	GameData.game_mode = mode
	get_tree().change_scene_to_file("res://character_select.tscn")

func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _card_style(col: Color, dim: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r * 0.08 + 0.01, col.g * 0.08 + 0.015, col.b * 0.1 + 0.04, 0.9)
	sb.border_color = Color(col.r, col.g, col.b, 0.85)
	sb.shadow_color = Color(col.r, col.g, col.b, 0.25)
	sb.shadow_size = 8
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	return sb

func _neon_button(text: String, icon_name: String, col: Color, pos: Vector2, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = sz
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 38)
	btn.add_theme_constant_override("h_separation", 16)
	for c in ["font_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		btn.add_theme_color_override(c, col)
	var icon_path := "res://assets/menuIcons/%s.png" % icon_name
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)
	var defs := {
		"normal":  [Color(col.r * 0.06, col.g * 0.06, col.b * 0.1 + 0.02, 0.92), col, 10],
		"hover":   [Color(col.r * 0.2, col.g * 0.2, col.b * 0.2 + 0.03, 0.97), Color(minf(col.r + 0.2, 1.0), minf(col.g + 0.2, 1.0), minf(col.b + 0.2, 1.0), 1.0), 18],
		"pressed": [Color(col.r * 0.12, col.g * 0.12, col.b * 0.12 + 0.02, 0.97), Color(col.r, col.g, col.b, 0.8), 0],
	}
	for key in defs:
		var sb := StyleBoxFlat.new()
		sb.bg_color = defs[key][0]
		sb.border_color = defs[key][1]
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 14.0
		sb.content_margin_right = 14.0
		sb.content_margin_top = 22.0
		sb.content_margin_bottom = 10.0
		if defs[key][2] > 0:
			sb.shadow_color = Color(col.r, col.g, col.b, 0.45)
			sb.shadow_size = defs[key][2]
		btn.add_theme_stylebox_override(key, sb)
	btn.add_theme_stylebox_override("focus", btn.get_theme_stylebox("normal"))
	return btn
