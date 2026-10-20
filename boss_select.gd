extends Control
# Karakter seçiminden sonra: boss + zorluk seçimi (Megabonk harita seçimi tarzı).
# Seçim GameData.selected_boss / GameData.difficulty'e yazılır, ardından GameData.pending_scene açılır.

const CYAN := Color(0.0, 0.95, 1.0)
const PINK := Color(1.0, 0.18, 0.58)
const GREEN := Color(0.0, 0.9, 0.6)
const GOLD := Color(1.0, 0.85, 0.0)
var _font: Font = load("res://assets/silverfont/Silver.ttf")

var _char: String = "vector"
var _boss: int = 0
var _tier: int = 1
var _list_root: Control = null
var _right_root: Control = null

func _tr() -> bool:
	return Lang.locale == "tr"

func _ready() -> void:
	_char = GameData.selected_character
	# Başlangıç seçimi: kayıtlı boss açıksa o, değilse ilk boss
	_boss = GameData.selected_boss if GameData.is_boss_unlocked(_char, GameData.selected_boss) else 0
	_tier = clampi(GameData.difficulty_tier(), 1, 3)
	if not GameData.is_tier_unlocked(_char, _boss, _tier):
		_tier = 1

	var bg := TextureRect.new()
	bg.texture = load("res://assets/menuBackground/difficultySelectionScreenLive.png")
	bg.size = Vector2(1920, 1080)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0.01, 0.04, 0.25)
	dim.size = Vector2(1920, 1080)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var title := _label("BOSS SEÇ" if _tr() else "SELECT BOSS", 76, CYAN)
	title.position = Vector2(0, 28)
	title.size = Vector2(1920, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	# Sol panel: boss listesi
	var lp := Panel.new()
	lp.add_theme_stylebox_override("panel", _card_style(CYAN, true))
	lp.position = Vector2(90, 140)
	lp.size = Vector2(620, 830)
	lp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lp)
	var lh := _label("BOSSLAR" if _tr() else "BOSSES", 38, GOLD)
	lh.position = Vector2(120, 156)
	add_child(lh)
	var lsub := _label("Yendikçe yenileri açılır" if _tr() else "More unlock as you win", 19, Color(0.6, 0.65, 0.75))
	lsub.position = Vector2(120, 204)
	add_child(lsub)
	_list_root = Control.new()
	_list_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_list_root)

	# Ortada: seçili karakter (güneye bakar)
	var ctex: Texture2D = load("res://assets/SelectCharacterScreen/%sPickScreen.png" % _char)
	if ctex:
		var sp := TextureRect.new()
		sp.texture = ctex
		sp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.size = Vector2(480, 640)
		sp.position = Vector2(705, 350)
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sp)

	_right_root = Control.new()
	_right_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_right_root)

	_rebuild()

func _rebuild() -> void:
	for c in _list_root.get_children(): c.queue_free()
	for c in _right_root.get_children(): c.queue_free()
	_build_list()
	_build_right()

# ── Sol: boss listesi ─────────────────────────────────────────────────────────
func _build_list() -> void:
	for i in GameData.BOSSES.size():
		var b: Dictionary = GameData.BOSSES[i]
		var unlocked: bool = GameData.is_boss_unlocked(_char, i)
		var sel: bool = i == _boss
		var y: float = 250.0 + i * 170.0
		var col: Color = CYAN if unlocked else Color(0.4, 0.4, 0.5)
		var card := Panel.new()
		card.add_theme_stylebox_override("panel", _card_style(col, not sel))
		card.position = Vector2(110, y)
		card.size = Vector2(580, 150)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_list_root.add_child(card)
		var tex: Texture2D = load(b["thumb"]) if unlocked else null
		if tex:
			var th := TextureRect.new()
			th.texture = tex
			th.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			th.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			th.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			th.size = Vector2(130, 130)
			th.position = Vector2(122, y + 10)
			th.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_list_root.add_child(th)
		else:
			var lk := _label("?", 95, Color(0.4, 0.4, 0.5))
			lk.position = Vector2(150, y + 22)
			_list_root.add_child(lk)
		var nm := _label(b["name"] if unlocked else "???", 57, col)
		nm.position = Vector2(280, y + 46)
		_list_root.add_child(nm)
		if unlocked:
			var done: int = GameData.boss_cleared(_char, i)
			if done > 0:
				var tk := _label("✓ " + str(done) + "/3", 38, GREEN)
				tk.position = Vector2(280, y + 100)
				_list_root.add_child(tk)
		# tıklama alanı
		var btn := Button.new()
		btn.flat = true
		btn.position = card.position
		btn.size = card.size
		btn.set_meta("sfx_click", "menuClick" if unlocked else "errorBuzz")
		btn.pressed.connect(_on_boss_pressed.bind(i))
		_list_root.add_child(btn)

func _on_boss_pressed(i: int) -> void:
	if not GameData.is_boss_unlocked(_char, i):
		return
	_boss = i
	if not GameData.is_tier_unlocked(_char, _boss, _tier):
		_tier = 1
	_rebuild()

# ── Sağ: seçili boss bilgileri + zorluk ──────────────────────────────────────
func _build_right() -> void:
	var b: Dictionary = GameData.BOSSES[_boss]
	var rp := Panel.new()
	rp.add_theme_stylebox_override("panel", _card_style(CYAN, true))
	rp.position = Vector2(1210, 140)
	rp.size = Vector2(620, 830)
	rp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right_root.add_child(rp)

	# Başlık: küçük resim + ad + seviye + toplam run
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", _card_style(CYAN, false))
	frame.position = Vector2(1235, 165)
	frame.size = Vector2(140, 140)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right_root.add_child(frame)
	var tex: Texture2D = load(b["thumb"])
	if tex:
		var th := TextureRect.new()
		th.texture = tex
		th.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		th.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		th.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		th.size = Vector2(124, 124)
		th.position = Vector2(1243, 173)
		th.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_right_root.add_child(th)
	var done: int = GameData.boss_cleared(_char, _boss)
	var nm := _label(b["name"], 57, GOLD)
	nm.position = Vector2(1400, 165)
	_right_root.add_child(nm)
	var lv := _label(("Seviye %d" if _tr() else "Level %d") % maxi(done, 1), 38, GREEN)
	lv.position = Vector2(1400, 222)
	_right_root.add_child(lv)
	var runs := _label(("Toplam Run: %d" if _tr() else "Total Runs: %d") % GameData.boss_runs(_char, _boss), 38, Color(0.85, 0.85, 0.9))
	runs.position = Vector2(1400, 262)
	_right_root.add_child(runs)

	# İstatistik kutusu
	var sbox := Panel.new()
	sbox.add_theme_stylebox_override("panel", _card_style(CYAN, true))
	sbox.position = Vector2(1235, 335)
	sbox.size = Vector2(570, 110)
	sbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_right_root.add_child(sbox)
	var s1 := _label("Yüksek Skor" if _tr() else "High Score", 19, Color(0.0, 0.72, 0.82))
	s1.position = Vector2(1260, 348)
	_right_root.add_child(s1)
	var score: int = GameData.boss_best_score(_char, _boss)
	var v1 := _label(str(score) if score > 0 else "-", 38, Color(1, 1, 1))
	v1.position = Vector2(1260, 378)
	_right_root.add_child(v1)
	var s2 := _label("Speedrun", 19, Color(0.0, 0.72, 0.82))
	s2.position = Vector2(1530, 348)
	_right_root.add_child(s2)
	var t: float = GameData.boss_best_time(_char, _boss)
	var v2 := _label(("%02d:%02d" % [int(t / 60.0), int(t) % 60]) if t > 0.0 else "-", 38, PINK)
	v2.position = Vector2(1530, 378)
	_right_root.add_child(v2)

	# Zorluk seviyeleri
	var names := ["Kolay", "Normal", "Zor"] if _tr() else ["Easy", "Normal", "Hard"]
	var mults := ["0.5x", "1x", "1.5x"]
	var cols := [CYAN, GOLD, PINK]
	for tier in range(1, 4):
		var y: float = 470.0 + (tier - 1) * 82.0
		var open: bool = GameData.is_tier_unlocked(_char, _boss, tier)
		var sel: bool = tier == _tier
		var c: Color = cols[tier - 1] if open else Color(0.45, 0.46, 0.52)
		var row := Panel.new()
		row.add_theme_stylebox_override("panel", _card_style(c, not sel or not open))
		row.position = Vector2(1235, y)
		row.size = Vector2(570, 72)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_right_root.add_child(row)
		# onay kutusu (seçili = dolu)
		var box := Panel.new()
		var bs := StyleBoxFlat.new()
		bs.bg_color = c if (sel and open) else Color(0.02, 0.03, 0.08, 0.9)
		bs.border_color = c
		bs.set_border_width_all(2)
		bs.set_corner_radius_all(3)
		box.add_theme_stylebox_override("panel", bs)
		box.position = Vector2(1255, y + 22)
		box.size = Vector2(28, 28)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_right_root.add_child(box)
		var label_txt: String = ("Seviye %d · %s" if _tr() else "Level %d · %s") % [tier, names[tier - 1]]
		var tl := _label(label_txt, 38, c)
		tl.position = Vector2(1300, y + 14)
		_right_root.add_child(tl)
		if true:
			var ml := _label(mults[tier - 1] + " XP", 19, Color(0.7, 0.75, 0.85) if open else Color(0.4, 0.41, 0.46))
			ml.position = Vector2(1560, y + 26)
			_right_root.add_child(ml)
		if done >= tier:
			var tk := _label("✓", 57, GREEN)
			tk.position = Vector2(1740, y + 6)
			_right_root.add_child(tk)
		var btn := Button.new()
		btn.flat = true
		btn.position = row.position
		btn.size = row.size
		btn.set_meta("sfx_click", "menuClick" if open else "errorBuzz")
		btn.pressed.connect(_on_tier_pressed.bind(tier))
		_right_root.add_child(btn)

	# Alt butonlar
	var ok := _neon_button("ONAYLA" if _tr() else "CONFIRM", "play", CYAN, Vector2(1335, 745), Vector2(370, 70))
	ok.pressed.connect(_on_confirm)
	_right_root.add_child(ok)
	var back := _neon_button("GERİ" if _tr() else "BACK", "back", PINK, Vector2(1335, 840), Vector2(370, 70))
	back.pressed.connect(_on_back)
	_right_root.add_child(back)

func _on_tier_pressed(tier: int) -> void:
	if not GameData.is_tier_unlocked(_char, _boss, tier):
		return
	_tier = tier
	_rebuild()

func _on_confirm() -> void:
	GameData.selected_boss = _boss
	GameData.difficulty = GameData.DIFFICULTY_KEYS[_tier - 1]
	get_tree().change_scene_to_file(GameData.pending_scene)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://character_select.tscn")

# ── Yardımcılar ───────────────────────────────────────────────────────────────
func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _card_style(col: Color, dim: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if dim:
		sb.bg_color = Color(0.025, 0.03, 0.07, 0.85)
		sb.border_color = Color(col.r, col.g, col.b, 0.3)
	else:
		sb.bg_color = Color(col.r * 0.08 + 0.01, col.g * 0.08 + 0.015, col.b * 0.1 + 0.04, 0.92)
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
