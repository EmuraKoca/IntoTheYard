extends Node2D

@onready var _font_bold    = preload("res://assets/orbitronfont/Orbitron-Bold.ttf")
@onready var _font_regular = preload("res://assets/orbitronfont/Orbitron-Regular.ttf")

# ── Ayarlar kalıcı depolama ───────────────────────────────────────────────────
const SETTINGS_PATH := "user://settings.cfg"
var _cfg := ConfigFile.new()

var master_vol: float = 1.0
var music_vol:  float = 0.8
var sfx_vol:    float = 0.8
var fullscreen:  bool = false

# ── Aktif tab ─────────────────────────────────────────────────────────────────
var _active_tab: int = 0   # 0=Controls  1=Audio  2=Display  3=Language
var _settings_canvas: CanvasLayer = null
var _tab_panels: Array = []
var _tab_buttons: Array = []

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_settings()
	_apply_settings()
	_apply_menu_lang()
	$BtnNewGame.pressed.connect(_on_new_game)
	$BtnLoadGame.pressed.connect(_on_load_game)
	$BtnSettings.pressed.connect(_on_settings)
	$BtnQuit.pressed.connect(_on_quit)

func _apply_menu_lang() -> void:
	$BtnNewGame.text  = Lang.t("mm_new_game")
	$BtnLoadGame.text = Lang.t("mm_load_game")
	$BtnSettings.text = Lang.t("mm_settings")
	$BtnQuit.text     = Lang.t("mm_quit")
	if has_node("LabelSubtitle"):
		$LabelSubtitle.text = Lang.t("mm_subtitle")
	if has_node("LabelVersion"):
		$LabelVersion.text  = Lang.t("mm_version")

# ── Menü işlemleri ────────────────────────────────────────────────────────────
func _on_new_game() -> void:
	GameData.unlocked_characters = ["vector"]
	GameData.char_xp = {"vector": 0, "leila": 0, "cyclone": 0}
	GameData.save_data()
	get_tree().change_scene_to_file("res://character_select.tscn")

func _on_load_game() -> void:
	GameData.load_data()
	get_tree().change_scene_to_file("res://character_select.tscn")

func _on_quit() -> void:
	get_tree().quit()

# ══════════════════════════════════════════════════════════════════════════════
# SETTINGS OVERLAY
# ══════════════════════════════════════════════════════════════════════════════
func _on_settings() -> void:
	if _settings_canvas != null:
		return
	_settings_canvas = CanvasLayer.new()
	_settings_canvas.layer = 10
	add_child(_settings_canvas)
	_build_settings_ui()

func _build_settings_ui() -> void:
	var W := 860
	var H := 580
	var cx := (1920 - W) / 2
	var cy := (1080 - H) / 2

	# ── Koyu arkaplan overlay ─────────────────────────────────────────────────
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_canvas.add_child(dim)

	# ── Panel ─────────────────────────────────────────────────────────────────
	var panel := Panel.new()
	panel.position = Vector2(cx, cy)
	panel.size     = Vector2(W, H)
	var ps := StyleBoxFlat.new()
	ps.bg_color          = Color(0.02, 0.03, 0.12, 0.97)
	ps.border_width_left = 2
	ps.border_width_right = 2
	ps.border_width_top = 2
	ps.border_width_bottom = 2
	ps.border_color      = Color(0, 0.9, 1, 1)
	ps.corner_radius_top_left = 6
	ps.corner_radius_top_right = 6
	ps.corner_radius_bottom_left = 6
	ps.corner_radius_bottom_right = 6
	ps.shadow_color = Color(0, 0.9, 1, 0.35)
	ps.shadow_size  = 16
	panel.add_theme_stylebox_override("panel", ps)
	_settings_canvas.add_child(panel)

	# ── Başlık ────────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = Lang.t("set_title")
	title.position = Vector2(0, 18)
	title.size = Vector2(W, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font_bold)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0, 0.95, 1, 1))
	panel.add_child(title)

	# ── Ayıraç ────────────────────────────────────────────────────────────────
	var sep := ColorRect.new()
	sep.position = Vector2(20, 64)
	sep.size     = Vector2(W - 40, 2)
	sep.color    = Color(0, 0.72, 0.82, 0.5)
	panel.add_child(sep)

	# ── Tab butonları ─────────────────────────────────────────────────────────
	var tab_names := [Lang.t("set_tab_controls"), Lang.t("set_tab_audio"), Lang.t("set_tab_display"), Lang.t("set_tab_language")]
	_tab_buttons.clear()
	for i in range(tab_names.size()):
		var tb := _make_tab_btn(tab_names[i], i)
		tb.position = Vector2(20 + i * 210, 78)
		tb.size     = Vector2(200, 38)
		panel.add_child(tb)
		_tab_buttons.append(tb)

	# ── Tab panelleri ─────────────────────────────────────────────────────────
	_tab_panels.clear()
	var content_rect := Rect2(20, 130, W - 40, H - 200)

	_tab_panels.append(_build_controls_tab(panel, content_rect))
	_tab_panels.append(_build_audio_tab(panel, content_rect))
	_tab_panels.append(_build_display_tab(panel, content_rect))
	_tab_panels.append(_build_language_tab(panel, content_rect))

	_switch_tab(_active_tab)

	# ── Kapat butonu ─────────────────────────────────────────────────────────
	var close_btn := _make_button(Lang.t("set_close"), Color(1, 0.18, 0.58, 1), Color(0.08, 0.02, 0.05, 0.92), Color(1, 0.18, 0.58, 1))
	close_btn.position = Vector2(W / 2 - 100, H - 62)
	close_btn.size     = Vector2(200, 44)
	close_btn.pressed.connect(_close_settings)
	panel.add_child(close_btn)

# ── Tab geçişi ────────────────────────────────────────────────────────────────
func _switch_tab(idx: int) -> void:
	_active_tab = idx
	for i in range(_tab_panels.size()):
		_tab_panels[i].visible = (i == idx)
	for i in range(_tab_buttons.size()):
		var tb: Button = _tab_buttons[i]
		if i == idx:
			tb.add_theme_color_override("font_color", Color(0, 0, 0, 1))
			var s := StyleBoxFlat.new()
			s.bg_color     = Color(0, 0.88, 1, 1)
			s.border_width_left = 0
			s.border_width_right = 0
			s.border_width_top = 0
			s.border_width_bottom = 0
			s.corner_radius_top_left = 4
			s.corner_radius_top_right = 4
			s.corner_radius_bottom_left = 4
			s.corner_radius_bottom_right = 4
			tb.add_theme_stylebox_override("normal", s)
			tb.add_theme_stylebox_override("hover",  s)
		else:
			tb.add_theme_color_override("font_color", Color(0, 0.75, 0.85, 1))
			var s := StyleBoxFlat.new()
			s.bg_color     = Color(0.04, 0.06, 0.14, 0.85)
			s.border_width_left = 1
			s.border_width_right = 1
			s.border_width_top = 1
			s.border_width_bottom = 1
			s.border_color = Color(0, 0.55, 0.65, 0.6)
			s.corner_radius_top_left = 4
			s.corner_radius_top_right = 4
			s.corner_radius_bottom_left = 4
			s.corner_radius_bottom_right = 4
			tb.add_theme_stylebox_override("normal", s)
			tb.add_theme_stylebox_override("hover",  s)

# ══════════════════════════════════════════════════════════════════════════════
# TAB 1 — CONTROLS
# ══════════════════════════════════════════════════════════════════════════════
func _build_controls_tab(parent: Control, rect: Rect2) -> Control:
	var cont := Control.new()
	cont.position = rect.position
	cont.size     = rect.size
	parent.add_child(cont)

	var controls := [
		[Lang.t("set_ctrl_movement"), "W  A  S  D"],
		[Lang.t("set_ctrl_aim"),      "Mouse"],
		[Lang.t("set_ctrl_launch"),   "Left Click"],
		[Lang.t("set_ctrl_rts"),      "Tab"],
		[Lang.t("set_ctrl_pause"),    "Escape"],
		[Lang.t("set_ctrl_debug"),    "C"],
		[Lang.t("set_ctrl_interact"), "E"],
	]

	var row_h := 46
	var col1  := 0.0
	var col2  := 380.0

	_add_label(cont, Lang.t("set_ctrl_header_action"), Vector2(col1, 0), 13, Color(0, 0.7, 0.8, 0.7), _font_bold)
	_add_label(cont, Lang.t("set_ctrl_header_key"),    Vector2(col2, 0), 13, Color(0, 0.7, 0.8, 0.7), _font_bold)

	var line := ColorRect.new()
	line.position = Vector2(0, 22)
	line.size     = Vector2(rect.size.x, 1)
	line.color    = Color(0, 0.6, 0.7, 0.3)
	cont.add_child(line)

	for i in range(controls.size()):
		var y := 30.0 + i * row_h
		var bg := ColorRect.new()
		bg.position = Vector2(-8, y - 6)
		bg.size     = Vector2(rect.size.x + 16, row_h - 4)
		bg.color    = Color(0, 0.5, 0.6, 0.06) if i % 2 == 0 else Color(0, 0, 0, 0)
		cont.add_child(bg)
		_add_label(cont, controls[i][0], Vector2(col1, y), 15, Color(0.82, 0.92, 1, 0.9), _font_regular)
		_add_label(cont, controls[i][1], Vector2(col2, y), 15, Color(0, 0.95, 1, 1), _font_bold)

	# Not
	var note := Label.new()
	note.text = Lang.t("set_ctrl_note")
	note.position = Vector2(0, rect.size.y - 30)
	note.size = Vector2(rect.size.x, 26)
	note.add_theme_font_override("font", _font_regular)
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7, 0.55))
	cont.add_child(note)

	return cont

# ══════════════════════════════════════════════════════════════════════════════
# TAB 2 — AUDIO
# ══════════════════════════════════════════════════════════════════════════════
func _build_audio_tab(parent: Control, rect: Rect2) -> Control:
	var cont := Control.new()
	cont.position = rect.position
	cont.size     = rect.size
	cont.visible  = false
	parent.add_child(cont)

	var buses := [
		[Lang.t("set_audio_master"), "Master", master_vol],
		[Lang.t("set_audio_music"),  "Music",  music_vol],
		[Lang.t("set_audio_sfx"),    "SFX",    sfx_vol],
	]

	for i in range(buses.size()):
		var y := 30.0 + i * 90
		_add_label(cont, buses[i][0], Vector2(0, y), 16, Color(0.82, 0.92, 1, 0.9), _font_bold)

		var slider := HSlider.new()
		slider.position   = Vector2(0, y + 30)
		slider.size       = Vector2(600, 28)
		slider.min_value  = 0.0
		slider.max_value  = 1.0
		slider.step       = 0.01
		slider.value      = buses[i][2]
		_style_slider(slider)
		cont.add_child(slider)

		var val_lbl := Label.new()
		val_lbl.position = Vector2(615, y + 30)
		val_lbl.size     = Vector2(60, 28)
		val_lbl.add_theme_font_override("font", _font_bold)
		val_lbl.add_theme_font_size_override("font_size", 15)
		val_lbl.add_theme_color_override("font_color", Color(0, 0.95, 1, 1))
		val_lbl.text = "%d%%" % int(buses[i][2] * 100)
		cont.add_child(val_lbl)

		var bus_name: String = buses[i][1]
		var lbl_ref := val_lbl
		slider.value_changed.connect(func(v: float):
			lbl_ref.text = "%d%%" % int(v * 100)
			var bus_idx := AudioServer.get_bus_index(bus_name)
			if bus_idx >= 0:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(v))
			match bus_name:
				"Master": master_vol = v
				"Music":  music_vol  = v
				"SFX":    sfx_vol    = v
			_save_settings()
		)

	return cont

# ══════════════════════════════════════════════════════════════════════════════
# TAB 3 — DISPLAY
# ══════════════════════════════════════════════════════════════════════════════
func _build_display_tab(parent: Control, rect: Rect2) -> Control:
	var cont := Control.new()
	cont.position = rect.position
	cont.size     = rect.size
	cont.visible  = false
	parent.add_child(cont)

	_add_label(cont, Lang.t("set_display_fs"), Vector2(0, 30), 16, Color(0.82, 0.92, 1, 0.9), _font_bold)

	var fs_btn := _make_button(
		"ON" if fullscreen else "OFF",
		Color(0, 0.95, 1, 1),
		Color(0.02, 0.03, 0.12, 0.92),
		Color(0, 0.9, 1, 1)
	)
	fs_btn.position = Vector2(0, 60)
	fs_btn.size     = Vector2(160, 44)
	fs_btn.pressed.connect(func():
		fullscreen = not fullscreen
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			fs_btn.text = "ON"
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			fs_btn.text = "OFF"
		_save_settings()
	)
	cont.add_child(fs_btn)

	_add_label(cont, Lang.t("set_display_note"),
		Vector2(0, rect.size.y - 30), 12, Color(0.5, 0.6, 0.7, 0.55), _font_regular)

	return cont

# ══════════════════════════════════════════════════════════════════════════════
# TAB 4 — LANGUAGE
# ══════════════════════════════════════════════════════════════════════════════
func _build_language_tab(parent: Control, rect: Rect2) -> Control:
	var cont := Control.new()
	cont.position = rect.position
	cont.size     = rect.size
	cont.visible  = false
	parent.add_child(cont)

	_add_label(cont, Lang.t("set_lang_title"), Vector2(0, 20), 18, Color(0.82, 0.92, 1, 0.9), _font_bold)

	var langs := [["English", "en"], ["Türkçe", "tr"]]
	for i in range(langs.size()):
		var lname: String = langs[i][0]
		var lcode: String = langs[i][1]
		var is_active := Lang.locale == lcode
		var fc  := Color(0, 0, 0, 1)      if is_active else Color(0, 0.88, 1, 1)
		var bg  := Color(0, 0.88, 1, 1)   if is_active else Color(0.02, 0.04, 0.14, 0.9)
		var brd := Color(0, 0.88, 1, 1)
		var lb  := _make_button(lname, fc, bg, brd)
		lb.position = Vector2(i * 220, 65)
		lb.size     = Vector2(200, 50)
		lb.pressed.connect(func():
			Lang.locale = lcode
			_cfg.set_value("lang", "locale", lcode)
			_cfg.save(SETTINGS_PATH)
			_close_settings()
			_apply_menu_lang()
			_on_settings()
			_switch_tab(3)
		)
		cont.add_child(lb)

	_add_label(cont, Lang.t("set_lang_note"),
		Vector2(0, rect.size.y - 30), 12, Color(0.5, 0.6, 0.7, 0.55), _font_regular)

	return cont

# ── Kapatma ───────────────────────────────────────────────────────────────────
func _close_settings() -> void:
	if _settings_canvas:
		_settings_canvas.queue_free()
		_settings_canvas = null

# ── Ayar kaydetme/yükleme ─────────────────────────────────────────────────────
func _save_settings() -> void:
	_cfg.set_value("audio",   "master", master_vol)
	_cfg.set_value("audio",   "music",  music_vol)
	_cfg.set_value("audio",   "sfx",    sfx_vol)
	_cfg.set_value("display", "fullscreen", fullscreen)
	_cfg.save(SETTINGS_PATH)

func _load_settings() -> void:
	if _cfg.load(SETTINGS_PATH) == OK:
		master_vol   = _cfg.get_value("audio",   "master",     1.0)
		music_vol    = _cfg.get_value("audio",   "music",      0.8)
		sfx_vol      = _cfg.get_value("audio",   "sfx",        0.8)
		fullscreen   = _cfg.get_value("display", "fullscreen", false)
		Lang.locale  = _cfg.get_value("lang",    "locale",     "en")

func _apply_settings() -> void:
	for bus_data in [["Master", master_vol], ["Music", music_vol], ["SFX", sfx_vol]]:
		var idx := AudioServer.get_bus_index(bus_data[0])
		if idx >= 0:
			AudioServer.set_bus_volume_db(idx, linear_to_db(bus_data[1]))
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

# ── Yardımcı UI builder'lar ───────────────────────────────────────────────────
func _make_tab_btn(label: String, idx: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_override("font", _font_bold)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func(): _switch_tab(idx))
	return btn

func _make_button(label: String, font_color: Color, bg: Color, border: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_override("font", _font_bold)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", font_color)
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = border
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate()
	sh.bg_color = bg.lightened(0.12)
	btn.add_theme_stylebox_override("hover",   sh)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_stylebox_override("focus",   s)
	return btn

func _add_label(parent: Control, txt: String, pos: Vector2, size: int, color: Color, font: FontFile) -> Label:
	var l := Label.new()
	l.text     = txt
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.05, 0.12, 0.18, 0.9)
	track.border_width_left = 1
	track.border_width_right = 1
	track.border_width_top = 1
	track.border_width_bottom = 1
	track.border_color = Color(0, 0.6, 0.75, 0.6)
	track.corner_radius_top_left = 3
	track.corner_radius_top_right = 3
	track.corner_radius_bottom_left = 3
	track.corner_radius_bottom_right = 3
	slider.add_theme_stylebox_override("slider", track)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0, 0.85, 1, 0.85)
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	slider.add_theme_stylebox_override("grabber_area", fill)

