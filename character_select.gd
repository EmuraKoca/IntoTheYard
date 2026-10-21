extends Control

var _font_bold    = preload("res://assets/silverfont/Silver.ttf")
var _font_regular = preload("res://assets/silverfont/Silver.ttf")

const CHARS: Array = [
	{"id":"vector",  "name":"Vector",      "color":Color(0,0.75,1,1),             "sc":2.5},
	{"id":"leila",   "name":"Leila",    "color":Color(1,0.18,0.47,1), "sc":2.5},
	{"id":"cyclone", "name":"Cyclone", "color":Color(0.22,1,0.08,1),         "sc":2.5},
]

var _cur: int = 0
var _dots: Array = []
var _prev_card: Panel = null
var _center_card: Panel = null
var _next_card: Panel = null

var _matrix_drops: Array = []
var _matrix_active: bool = false
const _MATRIX_N:       int   = 28
const _MATRIX_FONT:    int   = 13
const _MATRIX_SPD_MIN: float = 80.0
const _MATRIX_SPD_MAX: float = 200.0

func _ready() -> void:
	var old := get_node_or_null("HBoxContainer")
	if old: old.visible = false

	# Arka plan: ana menüdeki görsel (video yok), üstüne okunurluk için karartma
	var _bgimg := TextureRect.new()
	_bgimg.texture      = load("res://assets/menuBackground/mainMenuBackground.png")
	_bgimg.size         = Vector2(1920, 1080)
	_bgimg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_bgimg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bgimg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bgimg)
	var _bgdim := ColorRect.new()
	_bgdim.color        = Color(0, 0.01, 0.04, 0.5)
	_bgdim.size         = Vector2(1920, 1080)
	_bgdim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bgdim)
	var _base := get_node_or_null("ColorRect")
	if _base:
		move_child(_bgimg, _base.get_index() + 1)
		move_child(_bgdim, _base.get_index() + 2)

	# Alt butonlar ekranın altında ortada (ONAYLA solda, GERİ sağda)
	$Button2.position = Vector2(715, 983)
	$Button2.size = Vector2(250, 70)
	$Button.position = Vector2(985, 983)
	$Button.size = Vector2(220, 70)
	$InfoPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Button.pressed.connect(_on_back)
	$Button2.set_meta("sfx_click", "characterSelect")
	$Button2.pressed.connect(_on_confirm)
	$Label.text = Lang.t("cs_title")
	$Button.text = "◀  " + Lang.t("cs_back_btn")
	$Button2.text = Lang.t("cs_confirm_btn") + "  ▶"

	_build_ui()
	_refresh()
	_build_left_menu()

# ── UI inşası ─────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var root := Control.new()
	root.name = "CarouselRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var btn_l := _make_arrow("◀")
	btn_l.position = Vector2(840, 420)
	btn_l.pressed.connect(_slide.bind(-1))
	root.add_child(btn_l)

	var btn_r := _make_arrow("▶")
	btn_r.position = Vector2(1720, 420)
	btn_r.pressed.connect(_slide.bind(1))
	root.add_child(btn_r)

	_prev_card   = _make_panel(Vector2(990,  210), Vector2(170, 400))
	_center_card = _make_panel(Vector2(1180, 150), Vector2(260, 520))
	_next_card   = _make_panel(Vector2(1460, 210), Vector2(170, 400))
	root.add_child(_prev_card)
	root.add_child(_center_card)
	root.add_child(_next_card)

	var dots_box := HBoxContainer.new()
	dots_box.position = Vector2(1290, 700)
	dots_box.add_theme_constant_override("separation", 8)
	root.add_child(dots_box)
	_dots.clear()
	for i in CHARS.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dots_box.add_child(dot)
		_dots.append(dot)


func _make_arrow(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.set_meta("sfx_click", "")   # ses _slide içinde
	b.size = Vector2(60, 60)
	b.add_theme_font_override("font", _font_bold)
	b.add_theme_font_size_override("font_size", 38)
	_neon_btn(b, Color(0, 0.9, 1))
	return b

func _make_panel(pos: Vector2, sz: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size     = sz
	return p

# ── Güncelleme ────────────────────────────────────────────────────────────────
func _slide(dir: int) -> void:
	Sfx.play("characterSwipe")
	_cur = (_cur + dir + CHARS.size()) % CHARS.size()
	_stop_matrix()
	_refresh()

func _refresh() -> void:
	var prev_i := (_cur - 1 + CHARS.size()) % CHARS.size()
	var next_i := (_cur + 1) % CHARS.size()
	_fill_side(_prev_card,   CHARS[prev_i])
	_fill_center(_center_card, CHARS[_cur])
	_fill_side(_next_card,   CHARS[next_i])
	_update_dots()
	_update_info()
	var c: Dictionary = CHARS[_cur]
	if not _is_locked(c):
		_start_matrix(_center_card, c["color"])
	else:
		_stop_matrix()

# ── Yan kart ─────────────────────────────────────────────────────────────────
func _fill_side(card: Panel, c: Dictionary) -> void:
	for ch in card.get_children(): ch.queue_free()
	var locked: bool = _is_locked(c)
	var col: Color   = c["color"]

	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(col.r*0.06, col.g*0.06, col.b*0.1, 0.55) if not locked else Color(0.02, 0.02, 0.05, 0.45)
	sb.border_width_left = 1; sb.border_width_top = 1
	sb.border_width_right = 1; sb.border_width_bottom = 1
	sb.border_color = Color(col.r, col.g, col.b, 0.35) if not locked else Color(0.3, 0.3, 0.3, 0.25)
	sb.corner_radius_top_left = 6; sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6; sb.corner_radius_bottom_left = 6
	card.add_theme_stylebox_override("panel", sb)
	card.modulate = Color(1, 1, 1, 0.55)

	if not locked:
		var sprite := AnimatedSprite2D.new()
		sprite.position = card.size / 2 + Vector2(0, -30)
		_setup_sprite(sprite, c["id"], 260.0)
		card.add_child(sprite)
	elif locked:
		var lk := Label.new()
		lk.text = "🔒"
		lk.position = Vector2(0, card.size.y / 2 - 18)
		lk.size     = Vector2(card.size.x, 36)
		lk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lk.add_theme_font_size_override("font_size", 38)
		card.add_child(lk)

	var nm := Label.new()
	nm.text = c["name"] if not locked else "???"
	nm.position = Vector2(0, card.size.y - 62)
	nm.size     = Vector2(card.size.x, 44)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", _font_bold)
	nm.add_theme_font_size_override("font_size", 38)
	nm.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.65) if not locked else Color(0.4, 0.4, 0.4))
	card.add_child(nm)

# ── Orta kart ────────────────────────────────────────────────────────────────
func _fill_center(card: Panel, c: Dictionary) -> void:
	for ch in card.get_children(): ch.queue_free()
	var locked: bool = _is_locked(c)
	var col: Color   = c["color"]

	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(col.r*0.09, col.g*0.09, col.b*0.14, 0.92) if not locked else Color(0.03, 0.03, 0.08, 0.85)
	sb.border_width_left = 2; sb.border_width_top = 2
	sb.border_width_right = 2; sb.border_width_bottom = 2
	sb.border_color  = col if not locked else Color(0.35, 0.35, 0.35)
	sb.shadow_color  = Color(col.r, col.g, col.b, 0.38) if not locked else Color(0,0,0,0)
	sb.shadow_size   = 12
	sb.corner_radius_top_left = 8; sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8; sb.corner_radius_bottom_left = 8
	card.add_theme_stylebox_override("panel", sb)
	card.modulate = Color(1, 1, 1, 1)

	if not locked:
		var sprite := AnimatedSprite2D.new()
		sprite.position = card.size / 2 + Vector2(0, -62)
		_setup_sprite(sprite, c["id"], 390.0)
		card.add_child(sprite)
	elif locked:
		var lk := Label.new()
		lk.text = "🔒"
		lk.position = Vector2(0, card.size.y / 2 - 30)
		lk.size     = Vector2(card.size.x, 60)
		lk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lk.add_theme_font_size_override("font_size", 57)
		card.add_child(lk)

	var nm := Label.new()
	nm.text = c["name"] if not locked else "???"
	nm.position = Vector2(0, card.size.y - 130)
	nm.size     = Vector2(card.size.x, 44)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", _font_bold)
	nm.add_theme_font_size_override("font_size", 38)
	nm.add_theme_color_override("font_color", col if not locked else Color(0.5, 0.5, 0.5))
	card.add_child(nm)

	var th := Label.new()
	th.text = Lang.t("cs_theme_" + c["id"]) if not locked else "???"
	th.position = Vector2(0, card.size.y - 82)
	th.size     = Vector2(card.size.x, 44)
	th.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	th.add_theme_font_override("font", _font_regular)
	th.add_theme_font_size_override("font_size", 38)
	th.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.6) if not locked else Color(0.4, 0.4, 0.4))
	card.add_child(th)

	if not locked:
		var char_id: String = c["id"]
		var lv: int = GameData.get_level(char_id)
		var xp_cur: int = GameData.xp_in_current_level(char_id)
		var xp_need: int = GameData.xp_needed_for_level(char_id)

		# Level badge
		var lv_lbl := Label.new()
		lv_lbl.text = "LV %d" % lv
		lv_lbl.position = Vector2(4, 6)
		lv_lbl.size     = Vector2(card.size.x - 8, 22)
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lv_lbl.add_theme_font_override("font", _font_bold)
		lv_lbl.add_theme_font_size_override("font_size", 19)
		lv_lbl.add_theme_color_override("font_color", col)
		card.add_child(lv_lbl)

		# XP bar arkaplan
		var xp_bg := ColorRect.new()
		xp_bg.size     = Vector2(card.size.x - 16, 6)
		xp_bg.position = Vector2(8, card.size.y - 14)
		xp_bg.color    = Color(0.15, 0.15, 0.15, 0.8)
		card.add_child(xp_bg)

		# XP bar doluluk
		var fill_ratio: float = clampf(float(xp_cur) / float(max(xp_need, 1)), 0.0, 1.0)
		var xp_fill := ColorRect.new()
		xp_fill.size     = Vector2((card.size.x - 16) * fill_ratio, 6)
		xp_fill.position = Vector2(8, card.size.y - 14)
		xp_fill.color    = Color(col.r, col.g, col.b, 0.85)
		card.add_child(xp_fill)

# ── Dots ──────────────────────────────────────────────────────────────────────
func _update_dots() -> void:
	var col: Color = CHARS[_cur]["color"]
	for i in _dots.size():
		var dot: ColorRect = _dots[i]
		if i == _cur:
			dot.color = col
			dot.custom_minimum_size = Vector2(10, 10)
		else:
			dot.color = Color(0.3, 0.3, 0.3, 0.55)
			dot.custom_minimum_size = Vector2(7, 7)

# ── Info panel ────────────────────────────────────────────────────────────────
func _update_info() -> void:
	var c:      Dictionary = CHARS[_cur]
	var locked: bool       = _is_locked(c)
	var col: Color = c["color"]

	var info := $InfoPanel
	var lbl_name: Label = info.get_node("LabelName")
	lbl_name.text = Lang.t("cs_name") + (c["name"] if not locked else "???")
	lbl_name.add_theme_color_override("font_color", col if not locked else Color(0.5, 0.5, 0.5))

	info.get_node("LabelPassive").visible = false  # eski tasarımdan kalma pasif satırı artık kullanılmıyor

	var lbl_desc: Label = info.get_node("LabelDescription")
	if locked:
		lbl_desc.text = Lang.t("cs_locked")
	else:
		var char_id: String = c["id"]
		var lv: int      = GameData.get_level(char_id)
		var xp_cur: int  = GameData.xp_in_current_level(char_id)
		var xp_need: int = GameData.xp_needed_for_level(char_id)
		var unlock_str := ""
		if lv < 6:
			var next_unlock: String = GameData.get_unlock_for_level(char_id, lv + 1)
			if next_unlock != "":
				unlock_str = Lang.t("cs_next_unlock") + next_unlock + " (Lv%d)" % (lv + 1)
		var level_line: String
		if xp_need <= 1:
			level_line = Lang.t("cs_level_max") % lv
		else:
			level_line = Lang.t("cs_level_line") % [lv, xp_cur, xp_need]
		lbl_desc.text = level_line + unlock_str
		if GameData.game_mode == "survival":
			var rec: Dictionary = GameData.get_survival_record(char_id)
			var rt: int = int(rec["time"])
			lbl_desc.text += Lang.t("cs_survival_record") % ["%02d:%02d" % [rt / 60, rt % 60], int(rec["kills"])]

	if info.has_node("LabelTalent"):
		info.get_node("LabelTalent").visible = false

# ── Sprite kurulum ────────────────────────────────────────────────────────────
func _setup_sprite(sprite: AnimatedSprite2D, char_id: String, target_h: float) -> void:
	# Tek kare (south): animasyon/stop/hover hangi karede olursa olsun karakter hep güneye bakar
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 1.0)
	frames.set_animation_loop("spin", false)
	var tex: Texture2D = load("res://assets/SelectCharacterScreen/%sPickScreen.png" % char_id)
	frames.add_frame("spin", tex)
	var sc: float = target_h / float(tex.get_height())
	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(sc, sc)
	sprite.animation      = "spin"
	sprite.frame          = 0

# ── Matrix rain ───────────────────────────────────────────────────────────────
func _start_matrix(card: Panel, base_color: Color) -> void:
	_stop_matrix()
	_matrix_active = true
	for i in range(_MATRIX_N):
		var lbl := Label.new()
		lbl.text = str(randi() % 10)
		lbl.add_theme_font_size_override("font_size", _MATRIX_FONT)
		lbl.add_theme_font_override("font", _font_regular)
		var c := base_color; c.a = randf_range(0.18, 0.55)
		lbl.add_theme_color_override("font_color", c)
		lbl.position = Vector2(randf_range(4.0, card.size.x - 14.0), randf_range(card.size.y * 0.45, card.size.y - 10.0))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lbl)
		_matrix_drops.append({"label": lbl, "card": card, "speed": randf_range(_MATRIX_SPD_MIN, _MATRIX_SPD_MAX)})

func _stop_matrix() -> void:
	_matrix_active = false
	for drop in _matrix_drops:
		if is_instance_valid(drop["label"]): drop["label"].queue_free()
	_matrix_drops.clear()

func _process(delta: float) -> void:
	if not _matrix_active: return
	var col: Color = CHARS[_cur]["color"]
	for drop in _matrix_drops:
		var lbl: Label  = drop["label"]
		var card: Panel = drop["card"]
		if not is_instance_valid(lbl): continue
		lbl.position.y += drop["speed"] * delta
		if randf() < 0.09: lbl.text = str(randi() % 10)
		if lbl.position.y > card.size.y:
			lbl.position.y = card.size.y * 0.45
			lbl.position.x = randf_range(4.0, card.size.x - 14.0)
			var c := col; c.a = randf_range(0.18, 0.55)
			lbl.add_theme_color_override("font_color", c)
			drop["speed"] = randf_range(_MATRIX_SPD_MIN, _MATRIX_SPD_MAX)

# ── Yardımcı ──────────────────────────────────────────────────────────────────
func _is_locked(c: Dictionary) -> bool:
	return c["id"] == "???" or not GameData.is_unlocked(c["id"])

func _on_confirm() -> void:
	var c: Dictionary = CHARS[_cur]
	if _is_locked(c): return
	GameData.selected_character = c["id"]
	var next_scene := "res://game_scene.tscn"
	if GameData.show_intro:
		GameData.show_intro = false
		next_scene = "res://intro_scene.tscn"
	GameData.pending_scene = next_scene
	if GameData.game_mode == "survival" and not GameData.DEMO_MODE:
		# Survival: boss/zorluk ekranı yok, doğrudan oyun (şimdilik Story sahnesi — Aşama 2'de ayrışacak)
		GameData.enemy_style = "creature"
		get_tree().change_scene_to_file(next_scene)
		return
	if GameData.DEMO_MODE:
		# Demo: karakterden sonra düşman türü seçimi, ardından next_scene
		get_tree().change_scene_to_file("res://enemy_select.tscn")
	else:
		# Tam sürüm: karakterden sonra boss + zorluk seçim ekranı, ardından next_scene
		GameData.enemy_style = "creature"
		get_tree().change_scene_to_file("res://boss_select.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")

# ── Chip Mağazası ─────────────────────────────────────────────────────────────
func _make_left_btn(label_text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = label_text
	b.add_theme_font_override("font", _font_bold)
	b.add_theme_font_size_override("font_size", 38)
	b.custom_minimum_size = Vector2(380, 64)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_neon_btn(b, col)
	# 38px yazı için Silver dikey ortalama payı
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := b.get_theme_stylebox(key) as StyleBoxFlat
		if sb:
			sb.content_margin_top = 14.0
			sb.content_margin_bottom = 4.0
	return b

func _build_left_menu() -> void:
	var info := $InfoPanel

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	info.add_child(spacer)

	var pending := GameData.completed_milestones.size()
	var gorev_text := Lang.t("cs_quests") + ("  [%d]" % pending if pending > 0 else "")
	var gorev_col  := Color(1.0, 0.85, 0.0) if pending > 0 else Color(0.7, 0.7, 0.75)
	var gorev_btn  := _make_left_btn(gorev_text, gorev_col)
	gorev_btn.name = "AchievBtn"
	gorev_btn.pressed.connect(_open_achievements)
	info.add_child(gorev_btn)

	var market_btn := _make_left_btn(Lang.t("cs_market"), Color(0.0, 1.0, 0.8))
	market_btn.name = "ShopBtn"
	market_btn.pressed.connect(_open_shop)
	info.add_child(market_btn)

func _milestone_display(key: String) -> Dictionary:
	var ENEMY_NAMES := {
		"subject": "Subject", "armored_subject": "Armored Subject",
		"frantic_subject": "Frantic Subject", "heavy_subject": "Heavy Subject",
		"cyber_shotgun": "Cyber Shotgun", "cyber_shooter": "Cyber Shooter",
		"cyber_rifle": "Cyber Rifle", "boss": "Boss"
	}
	var CORE_NAMES := {
		"normal": "Normal Core", "split": "Split Core", "electric": "Electric Core",
		"pierce": "Pierce Core", "cryo": "Cryo Core", "glitch": "Glitch Core",
		"water": "Water Core", "fire": "Fire Core", "mimic": "Mimic Core",
		"leech": "Leech Core", "armor": "Armor Core", "anchor": "Anchor Core",
		"crusher": "Crusher Core", "kinetic": "Kinetic Core", "bulwark": "Bulwark Core",
		"siege": "Siege Core", "bloodbound": "Bloodbound Core", "tempered": "Tempered Core",
		"iron_aura_core": "Iron Aura Core"
	}
	var reward := GameData._get_milestone_reward(key)
	var label := ""
	if key.begins_with("kill_boss_"):
		var threshold := key.split("_")[2]
		label = "Boss — %s öldür" % threshold
	elif key.begins_with("kill_"):
		var parts := key.split("_")
		var threshold := parts[parts.size() - 1]
		var etype := "_".join(parts.slice(1, parts.size() - 1))
		var ename: String = ENEMY_NAMES.get(etype, etype)
		label = "%s — %s öldür" % [ename, threshold]
	elif key.begins_with("core_"):
		var parts := key.split("_")
		var threshold := parts[parts.size() - 1]
		var ctype := "_".join(parts.slice(1, parts.size() - 1))
		var cname: String = CORE_NAMES.get(ctype, ctype)
		label = "%s — %s atış" % [cname, threshold]
	elif key.begins_with("react_steam_"):
		label = "Steam reaksiyonu — %s kez" % key.split("_")[2]
	elif key.begins_with("react_overheat_"):
		label = "Overheat reaksiyonu — %s kez" % key.split("_")[2]
	elif key.begins_with("react_electrocute_"):
		label = "Electrocute reaksiyonu — %s kez" % key.split("_")[2]
	elif key.begins_with("react_frozen_"):
		label = "Frozen reaksiyonu — %s kez" % key.split("_")[2]
	elif key.begins_with("survival_5min_"):
		label = "5 dakika hayatta kal — %s kez" % key.split("_")[2]
	elif key.begins_with("survival_10min_"):
		label = "10 dakika hayatta kal — %s kez" % key.split("_")[2]
	elif key.begins_with("survival_20min_"):
		label = "20 dakika hayatta kal — %s kez" % key.split("_")[2]
	elif key.begins_with("run_3element_"):
		label = "Bir run'da 3+ element kullan — %s kez" % key.split("_")[2]
	elif key.begins_with("charkill_vector_"):
		label = "Vector ile %s düşman öldür" % key.split("_")[2]
	elif key.begins_with("charkill_leila_"):
		label = "Leila ile %s düşman öldür" % key.split("_")[2]
	elif key.begins_with("charkill_cyclone_"):
		label = "Cyclone ile %s düşman öldür" % key.split("_")[2]
	elif key.begins_with("upgrade_total_"):
		label = "Toplam %s kart al" % key.split("_")[2]
	elif key.begins_with("calamity_filled_"):
		label = "Calamity slotunu %s kez doldur" % key.split("_")[2]
	return {"label": label, "reward": reward}

# ── Neon stil yardımcıları (ana menü buton paletiyle uyumlu) ───────────────────
func _card_style(col: Color, dim: bool = false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if dim:
		sb.bg_color = Color(0.025, 0.03, 0.07, 0.85)
		sb.border_color = Color(col.r, col.g, col.b, 0.25)
	else:
		sb.bg_color = Color(col.r * 0.08 + 0.01, col.g * 0.08 + 0.015, col.b * 0.1 + 0.04, 0.92)
		sb.border_color = Color(col.r, col.g, col.b, 0.75)
		sb.shadow_color = Color(col.r, col.g, col.b, 0.22)
		sb.shadow_size = 6
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	return sb

func _neon_btn(btn: Button, col: Color, dim: bool = false) -> void:
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var fcol := Color(col.r, col.g, col.b, 0.45) if dim else col
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		btn.add_theme_color_override(c, fcol)
	var defs := {
		"normal":   [Color(0.025, 0.03, 0.07, 0.9) if dim else Color(0.02, 0.03, 0.1, 0.92), Color(col.r, col.g, col.b, 0.3) if dim else col, 0],
		"hover":    [Color(0.03, 0.035, 0.08, 0.92) if dim else Color(col.r * 0.2, col.g * 0.2, col.b * 0.2 + 0.03, 0.97), Color(col.r, col.g, col.b, 0.4) if dim else Color(minf(col.r + 0.2, 1.0), minf(col.g + 0.2, 1.0), minf(col.b + 0.2, 1.0), 1.0), 0 if dim else 14],
		"pressed":  [Color(col.r * 0.12, col.g * 0.12, col.b * 0.12 + 0.02, 0.97), Color(col.r, col.g, col.b, 0.8), 0],
		"disabled": [Color(0.025, 0.03, 0.07, 0.9), Color(col.r, col.g, col.b, 0.22), 0],
	}
	for key in defs:
		var sb := StyleBoxFlat.new()
		sb.bg_color = defs[key][0]
		sb.border_color = defs[key][1]
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 12.0
		sb.content_margin_right = 12.0
		sb.content_margin_top = 8.0     # Silver'ın dikey ortalama farkı
		sb.content_margin_bottom = 3.0
		if defs[key][2] > 0:
			sb.shadow_color = Color(col.r, col.g, col.b, 0.4)
			sb.shadow_size = defs[key][2]
		btn.add_theme_stylebox_override(key, sb)
	btn.add_theme_stylebox_override("focus", btn.get_theme_stylebox("normal"))

func _open_achievements(restore_scroll: int = 0) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 90
	add_child(canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.07, 0.97)
	bg.size  = Vector2(1920, 1080)
	canvas.add_child(bg)

	var title := Label.new()
	title.text = "★  BAŞARIMLAR"
	title.add_theme_font_override("font", _font_bold)
	title.add_theme_font_size_override("font_size", 57)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	title.position = Vector2(600, 60)
	canvas.add_child(title)

	var chip_lbl := Label.new()
	chip_lbl.name = "ChipLbl"
	chip_lbl.text = Lang.t("shop_balance") % GameData.chips
	chip_lbl.add_theme_font_override("font", _font_bold)
	chip_lbl.add_theme_font_size_override("font_size", 38)
	chip_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	chip_lbl.position = Vector2(600, 120)
	canvas.add_child(chip_lbl)

	# Tüm milestone'ları kategoriye göre topla
	var categories: Array = [
		{"title": "─── Düşman Öldürme ───", "keys": []},
		{"title": "─── Boss ───",            "keys": []},
		{"title": "─── Reaksiyonlar ───",    "keys": []},
		{"title": "─── Hayatta Kalma ───",   "keys": []},
		{"title": "─── Karaktere Özel ───",  "keys": []},
		{"title": "─── Upgrade ───",         "keys": []},
	]
	var ENEMY_TYPES := ["subject","armored_subject","frantic_subject","heavy_subject","cyber_shotgun","cyber_shooter","cyber_rifle"]
	for etype in ENEMY_TYPES:
		for t in GameData.ENEMY_MILESTONES:
			categories[0]["keys"].append("kill_%s_%d" % [etype, t])
	for t in GameData.BOSS_MILESTONES:
		categories[1]["keys"].append("kill_boss_%d" % t)
	for rtype in ["steam","overheat","electrocute","frozen"]:
		for t in GameData.REACTION_MILESTONES:
			categories[2]["keys"].append("react_%s_%d" % [rtype, t])
	for t in GameData.SURVIVAL_5MIN_MILESTONES:
		categories[3]["keys"].append("survival_5min_%d" % t)
	for t in GameData.SURVIVAL_10MIN_MILESTONES:
		categories[3]["keys"].append("survival_10min_%d" % t)
	for t in GameData.SURVIVAL_20MIN_MILESTONES:
		categories[3]["keys"].append("survival_20min_%d" % t)
	for t in GameData.RUN3ELEM_MILESTONES:
		categories[3]["keys"].append("run_3element_%d" % t)
	for char_id in ["vector","leila","cyclone"]:
		for t in GameData.CHAR_KILL_MILESTONES:
			categories[4]["keys"].append("charkill_%s_%d" % [char_id, t])
	for t in GameData.UPGRADE_MILESTONES:
		categories[5]["keys"].append("upgrade_total_%d" % t)
	for t in GameData.CALAMITY_MILESTONES:
		categories[5]["keys"].append("calamity_filled_%d" % t)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(460, 185)
	scroll.size     = Vector2(1000, 720)
	canvas.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	for cat in categories:
		var cat_lbl := Label.new()
		cat_lbl.text = cat["title"]
		cat_lbl.add_theme_font_override("font", _font_bold)
		cat_lbl.add_theme_font_size_override("font_size", 19)
		cat_lbl.add_theme_color_override("font_color", Color(0.0, 0.72, 0.82, 0.9))
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 6)
		vbox.add_child(spacer)
		vbox.add_child(cat_lbl)
		for key in cat["keys"]:
			var info := _milestone_display(key)
			var is_completed: bool = key in GameData.completed_milestones
			var is_claimed: bool   = key in GameData.claimed_milestones

			var card_col := Color(0.0, 0.9, 0.6) if is_completed else Color(0.0, 0.72, 0.82)
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", _card_style(card_col, is_claimed or not is_completed))
			vbox.add_child(card)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 16)
			card.add_child(row)

			var lbl := Label.new()
			lbl.text = info["label"]
			lbl.custom_minimum_size = Vector2(620, 0)
			lbl.add_theme_font_override("font", _font_bold)
			lbl.add_theme_font_size_override("font_size", 19)
			if is_completed:
				lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.7))
			elif is_claimed:
				lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
			else:
				lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
			row.add_child(lbl)

			var reward_lbl := Label.new()
			reward_lbl.text = "+%d Chip" % info["reward"]
			reward_lbl.custom_minimum_size = Vector2(120, 0)
			reward_lbl.add_theme_font_override("font", _font_bold)
			reward_lbl.add_theme_font_size_override("font_size", 19)
			reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0) if not is_claimed else Color(0.3, 0.3, 0.3))
			row.add_child(reward_lbl)

			var collect_btn := Button.new()
			collect_btn.custom_minimum_size = Vector2(160, 36)
			collect_btn.add_theme_font_override("font", _font_bold)
			collect_btn.add_theme_font_size_override("font_size", 19)
			if is_claimed:
				collect_btn.text     = "ALINDI ✓"
				collect_btn.disabled = true
				collect_btn.add_theme_color_override("font_color", Color(0.3, 0.5, 0.3))
			elif is_completed:
				collect_btn.text = "COLLECT"
				collect_btn.set_meta("sfx_click", "chipCollect")
				collect_btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.7))
				var k: String = key
				var scroll_ref := scroll
				collect_btn.pressed.connect(func():
					var pos: int = scroll_ref.scroll_vertical
					GameData.claim_milestone(k)
					canvas.queue_free()
					_open_achievements(pos)
					_refresh_header_buttons()
				)
			else:
				collect_btn.text     = "COLLECT"
				collect_btn.disabled = true
				collect_btn.add_theme_color_override("font_color", Color(0.25, 0.25, 0.28))
			if is_claimed:
				_neon_btn(collect_btn, Color(0.0, 0.9, 0.6), true)
			elif is_completed:
				_neon_btn(collect_btn, Color(0.0, 0.9, 0.6))
			else:
				_neon_btn(collect_btn, Color(0.0, 0.72, 0.82), true)
			row.add_child(collect_btn)

	var close_btn := Button.new()
	close_btn.text = Lang.t("shop_close")
	close_btn.add_theme_font_override("font", _font_bold)
	close_btn.add_theme_font_size_override("font_size", 19)
	close_btn.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	close_btn.size     = Vector2(200, 50)
	_neon_btn(close_btn, Color(1, 0.18, 0.58))
	close_btn.position = Vector2(860, 940)
	close_btn.pressed.connect(func(): canvas.queue_free(); _refresh_header_buttons())
	canvas.add_child(close_btn)

	if restore_scroll > 0:
		scroll.scroll_vertical = restore_scroll
		scroll.call_deferred("set", "scroll_vertical", restore_scroll)

func _refresh_header_buttons() -> void:
	var ab := $InfoPanel.get_node_or_null("AchievBtn")
	if ab:
		var pending := GameData.completed_milestones.size()
		ab.text = Lang.t("cs_quests") + ("  [%d]" % pending if pending > 0 else "")
		ab.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0) if pending > 0 else Color(0.7, 0.7, 0.75))

func _open_shop(restore_scroll: int = 0) -> void:
	Sfx.play_path("res://assets/sfx/ui/blackMarketEntrance.ogg")
	var char_id: String = CHARS[_cur]["id"]
	var char_col: Color = CHARS[_cur]["color"]

	var canvas := CanvasLayer.new()
	canvas.layer = 90
	add_child(canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.07, 0.97)
	bg.size  = Vector2(1920, 1080)
	canvas.add_child(bg)

	var title := Label.new()
	title.text = "⬡  " + Lang.t("shop_title") + "  —  " + CHARS[_cur]["name"].to_upper()
	title.add_theme_font_override("font", _font_bold)
	title.add_theme_font_size_override("font_size", 57)
	title.add_theme_color_override("font_color", char_col)
	title.position = Vector2(510, 30)
	canvas.add_child(title)

	var chip_lbl := Label.new()
	chip_lbl.text = Lang.t("shop_balance") % GameData.chips
	chip_lbl.add_theme_font_override("font", _font_bold)
	chip_lbl.add_theme_font_size_override("font_size", 38)
	chip_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	chip_lbl.position = Vector2(514, 120)
	canvas.add_child(chip_lbl)

	# Sadece bu karaktere uygun itemları filtrele
	var visible_items: Array = []
	for item in GameData.SHOP_ITEMS:
		var allowed: Array = item.get("chars", [])
		if allowed.size() == 0 or char_id in allowed:
			visible_items.append(item)

	# Ürün listesi kaydırılabilir (ürün sayısı arttıkça Kapat butonuna binmesin)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(480, 185)
	scroll.size     = Vector2(960, 760)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	var content := Control.new()
	content.custom_minimum_size = Vector2(960, visible_items.size() * 92 + 12)
	scroll.add_child(content)

	for i in visible_items.size():
		var item: Dictionary = visible_items[i]
		var row_y := 6 + i * 92
		var col: Color = item["color"]
		var stack: int     = GameData.shop_stack(item["id"], char_id)
		var max_s: int     = item["max_stack"]
		var maxed: bool    = stack >= max_s
		var cost: int      = GameData.get_item_cost(item, char_id)
		var affordable: bool = GameData.chips >= cost

		var box := Panel.new()
		box.add_theme_stylebox_override("panel", _card_style(col, maxed))
		box.size     = Vector2(900, 80)
		box.position = Vector2(30, row_y)
		content.add_child(box)

		var name_lbl := Label.new()
		name_lbl.text = Lang.t("shop_" + item["id"] + "_name")
		name_lbl.add_theme_font_override("font", _font_bold)
		name_lbl.add_theme_font_size_override("font_size", 19)
		name_lbl.add_theme_color_override("font_color", col if not maxed else Color(0.3,0.3,0.3))
		name_lbl.position = Vector2(56, row_y + 6)
		content.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = Lang.t("shop_" + item["id"] + "_desc")
		desc_lbl.add_theme_font_override("font", _font_regular)
		desc_lbl.add_theme_font_size_override("font_size", 19)
		desc_lbl.add_theme_color_override("font_color", Color(0.6,0.6,0.65) if not maxed else Color(0.28,0.28,0.28))
		desc_lbl.position = Vector2(56, row_y + 32)
		content.add_child(desc_lbl)

		# Stack göstergesi (0/3 kutucuklar)
		for si in max_s:
			var sq := ColorRect.new()
			sq.size     = Vector2(16, 16)
			sq.position = Vector2(580 + si * 26, row_y + 32)
			sq.color    = col if si < stack else Color(0.1, 0.12, 0.2)
			content.add_child(sq)

		var buy_btn := Button.new()
		buy_btn.add_theme_font_override("font", _font_bold)
		buy_btn.add_theme_font_size_override("font_size", 19)
		buy_btn.size     = Vector2(150, 44)
		buy_btn.position = Vector2(760, row_y + 18)
		if maxed:
			buy_btn.text     = "MAX ✓"
			buy_btn.disabled = true
			buy_btn.add_theme_color_override("font_color", Color(0.3,0.6,0.3))
		elif not affordable:
			buy_btn.text     = "%d Chip" % cost
			buy_btn.set_meta("sfx_click", "errorBuzz")   # disabled değil: tıklayınca hata sesi
			buy_btn.add_theme_color_override("font_color", Color(0.38,0.38,0.38))
		else:
			buy_btn.text = "%d Chip" % cost
			buy_btn.add_theme_color_override("font_color", Color(0.0,1.0,0.8))
			var iid: String = item["id"]
			buy_btn.set_meta("sfx_click", "")
			buy_btn.pressed.connect(func():
				if GameData.buy_item(iid):
					Sfx.play("purchase")
					var pos: int = scroll.scroll_vertical
					canvas.queue_free()
					_open_shop(pos)
			)
		if maxed:
			_neon_btn(buy_btn, Color(0.0, 0.9, 0.6), true)
		elif not affordable:
			_neon_btn(buy_btn, Color(1, 0.18, 0.58), true)
		else:
			_neon_btn(buy_btn, Color(0.0, 0.95, 1.0))
		content.add_child(buy_btn)

	if restore_scroll > 0:
		scroll.scroll_vertical = restore_scroll
		scroll.call_deferred("set", "scroll_vertical", restore_scroll)

	var close_btn := Button.new()
	close_btn.text = Lang.t("shop_close")
	close_btn.add_theme_font_override("font", _font_bold)
	close_btn.add_theme_font_size_override("font_size", 19)
	close_btn.add_theme_color_override("font_color", Color(0.8,0.2,0.2))
	close_btn.size     = Vector2(200, 50)
	_neon_btn(close_btn, Color(1, 0.18, 0.58))
	close_btn.position = Vector2(860, 960)
	close_btn.pressed.connect(func(): canvas.queue_free())
	canvas.add_child(close_btn)
