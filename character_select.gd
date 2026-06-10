extends Control

var _font_bold    = preload("res://assets/orbitronfont/Orbitron-Bold.ttf")
var _font_regular = preload("res://assets/orbitronfont/Orbitron-Regular.ttf")

var selected_character = "vector"
var cards = []

var vector_card
var leila_card
var cyclone_card

# ── Matrix rain hover efekti ──────────────────────────────────────────────────
var _matrix_drops: Dictionary = {}
var _matrix_active: Dictionary = {}

const _MATRIX_N: int = 24
const _MATRIX_FONT: int = 14
const _MATRIX_SPD_MIN: float = 90.0
const _MATRIX_SPD_MAX: float = 210.0
const _CARD_H: float = 800.0
const _CARD_W: float = 400.0
const _RAIN_Y: float = 400.0

func _setup_char_sprite(card: Panel, sheet_path: String, frame_w: int, frame_count: int, sprite_scale: float) -> void:
	var sprite: AnimatedSprite2D = card.get_node("CharSprite")
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var tex: Texture2D = load(sheet_path)
	frames.add_animation("spin")
	frames.set_animation_speed("spin", 8.0)
	frames.set_animation_loop("spin", true)
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas  = tex
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_w)
		frames.add_frame("spin", atlas)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(sprite_scale, sprite_scale)
	sprite.animation      = "spin"
	sprite.frame          = 0
	sprite.stop()

func _ready() -> void:
	vector_card  = $HBoxContainer/CharacterPanel/CardsContainer/VectorCard
	leila_card   = $HBoxContainer/CharacterPanel/CardsContainer/LeilaCard
	cyclone_card = $HBoxContainer/CharacterPanel/CardsContainer/CycloneCard

	cards = [vector_card, leila_card, cyclone_card]

	_setup_char_sprite(vector_card,  "res://assets/selectCharacters/vector_sheet.png",  208, 8, 1.65)
	_setup_char_sprite(leila_card,   "res://assets/selectCharacters/leila_sheet.png",   224, 8, 1.50)
	_setup_char_sprite(cyclone_card, "res://assets/selectCharacters/cyclone_sheet.png", 224, 8, 1.50)

	for card in cards:
		card.mouse_entered.connect(_on_hover.bind(card))
		card.mouse_exited.connect(_on_hover_exit.bind(card))
		card.connect("gui_input", _on_card_clicked.bind(card))

	$Button.pressed.connect(_on_back)
	$Button2.pressed.connect(_on_confirm)

	for card in cards:
		card.set_meta("selected", false)
		var char_id := _card_to_id(card)
		var locked  := not GameData.is_unlocked(char_id)
		card.set_meta("locked", locked)
		_apply_lock_visual(card, locked)
		


func _card_to_id(card: Panel) -> String:
	match card.name:
		"VectorCard":  return "vector"
		"LeilaCard":   return "leila"
		"CycloneCard": return "cyclone"
	return ""

func _apply_lock_visual(card: Panel, locked: bool) -> void:
	var sprite: AnimatedSprite2D = card.get_node("CharSprite")
	var name_lbl: Label = card.get_node("LabelName")
	if locked:
		sprite.modulate = Color(0.0, 0.0, 0.0, 1.0)
		name_lbl.text = "???"
		if not card.has_node("LockLabel"):
			var lbl := Label.new()
			lbl.name = "LockLabel"
			lbl.text = "🔒  KİLİTLİ"
			lbl.add_theme_font_size_override("font_size", 18)
			lbl.add_theme_font_override("font", _font_bold)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			lbl.position = Vector2(90, 540)
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(lbl)
	else:
		sprite.modulate = Color(0.4, 0.4, 0.4)
		match card.name:
			"LeilaCard":   name_lbl.text = "Name : Leila"
			"CycloneCard": name_lbl.text = "Name : Cyclone"
		if card.has_node("LockLabel"):
			card.get_node("LockLabel").queue_free()

func _on_hover(card) -> void:
	if card.get_meta("selected", false):
		return
	if card.get_meta("locked", false):
		return  # Kilitli karta hover efekti yok
	var sprite: AnimatedSprite2D = card.get_node("CharSprite")
	sprite.scale = Vector2(sprite.scale.x * 1.08, sprite.scale.y * 1.08)
	sprite.modulate = Color(1.2, 1.2, 1.2)
	sprite.play("spin")
	_start_matrix(card)

func _on_hover_exit(card) -> void:
	if card.get_meta("selected", false):
		return
	if card.get_meta("locked", false):
		return
	var sprite: AnimatedSprite2D = card.get_node("CharSprite")
	var base_scale := _get_base_scale(card)
	sprite.scale = Vector2(base_scale, base_scale)
	sprite.modulate = Color(0.4, 0.4, 0.4)
	sprite.stop()
	sprite.frame = 0
	_stop_matrix(card)

func _get_base_scale(card: Panel) -> float:
	match card.name:
		"VectorCard":  return 1.65
		"LeilaCard":   return 1.50
		"CycloneCard": return 1.50
	return 1.5

func _select_card(selected) -> void:
	for card in cards:
		var sprite: AnimatedSprite2D = card.get_node("CharSprite")
		var base_scale := _get_base_scale(card)
		var locked: bool = card.get_meta("locked", false)
		if card == selected:
			card.set_meta("selected", true)
			sprite.scale    = Vector2(base_scale * 1.1, base_scale * 1.1)
			sprite.modulate = Color(1, 1, 1)
			sprite.stop()
			sprite.frame = 0
		else:
			card.set_meta("selected", false)
			sprite.scale = Vector2(base_scale, base_scale)
			sprite.modulate = Color(0.0, 0.0, 0.0, 1.0) if locked else Color(0.4, 0.4, 0.4)
			sprite.stop()
			sprite.frame = 0

func _on_card_clicked(event: InputEvent, card) -> void:
	if event is InputEventMouseButton and event.pressed:
		if card.get_meta("locked", false):
			_update_info("???", "???", "Bu karakter henüz kilitli.")
			return
		for c in cards:
			_stop_matrix(c)
		_select_card(card)
		if card == vector_card:
			selected_character = "vector"
			_update_info("Vector", "Normal Toplarda ustadır. Kaba kuvvete bayılır.", "Normal Ball'lar aynı hedefe 5 kez vurursa kritik darbe oluşturur.")
		elif card == leila_card:
			selected_character = "leila"
			_update_info("Leila", "Elemental Ball'larda ustadır.", "Elemental Ball düşmana vurduğunda %20 ihtimalle ikinci bir elemental patlama oluşturur.")
		elif card == cyclone_card:
			selected_character = "cyclone"
			_update_info("Cyclone", "Pierce, Glitch ve Mimic toplarında ustadır.", "Glitch etkisindeki düşman öldüğünde Glitch başka bir düşmana sıçrar.")

func _update_info(char_name: String, passive_title: String, passive_desc: String) -> void:
	var info = $InfoPanel
	info.get_node("LabelName").text = "İsim: " + char_name
	info.get_node("LabelPassive").text = "Pasif: " + passive_title
	info.get_node("LabelDescription").text = passive_desc
	if info.has_node("LabelTalent"):
		info.get_node("LabelTalent").visible = false

func _on_confirm() -> void:
	GameData.selected_character = selected_character
	get_tree().change_scene_to_file("res://game_scene.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")

# ── Matrix Rain ───────────────────────────────────────────────────────────────

func _get_matrix_color(card: Panel) -> Color:
	match card.name:
		"VectorCard":  return Color(0.0,  0.749, 1.0,   1.0)  # #00BFFF
		"LeilaCard":   return Color(1.0,  0.176, 0.471, 1.0)  # #FF2D78
		"CycloneCard": return Color(0.224, 1.0,  0.078, 1.0)  # #39FF14
	return Color.WHITE

func _start_matrix(card: Panel) -> void:
	_matrix_active[card] = true
	if _matrix_drops.has(card):
		return  # Already created, just re-activate
	var base: Color = _get_matrix_color(card)
	var drops: Array = []
	for i in range(_MATRIX_N):
		var lbl := Label.new()
		lbl.text = str(randi() % 10)
		lbl.add_theme_font_size_override("font_size", _MATRIX_FONT)
		lbl.add_theme_font_override("font", _font_regular)
		var c := base
		c.a = randf_range(0.28, 0.72)
		lbl.add_theme_color_override("font_color", c)
		lbl.position = Vector2(
			randf_range(4.0, _CARD_W - 12.0),
			randf_range(_RAIN_Y, _CARD_H - 10.0)
		)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lbl)
		drops.append({ "label": lbl, "speed": randf_range(_MATRIX_SPD_MIN, _MATRIX_SPD_MAX) })
	_matrix_drops[card] = drops

func _stop_matrix(card: Panel) -> void:
	_matrix_active[card] = false
	if not _matrix_drops.has(card):
		return
	for drop in _matrix_drops[card]:
		if is_instance_valid(drop["label"]):
			drop["label"].queue_free()
	_matrix_drops.erase(card)

func _process(delta: float) -> void:
	var active_cards: Array = _matrix_drops.keys()
	for card in active_cards:
		if not _matrix_active.get(card, false):
			continue
		var base: Color = _get_matrix_color(card)
		for drop in _matrix_drops[card]:
			var lbl: Label = drop["label"]
			if not is_instance_valid(lbl):
				continue
			lbl.position.y += drop["speed"] * delta
			# Random digit change (~12% chance per frame)
			if randf() < 0.12:
				lbl.text = str(randi() % 10)
			# Reset to upper half when below lower bound
			if lbl.position.y > _CARD_H:
				lbl.position.y = _RAIN_Y
				lbl.position.x  = randf_range(4.0, _CARD_W - 12.0)
				var c := base
				c.a = randf_range(0.28, 0.72)
				lbl.add_theme_color_override("font_color", c)
				drop["speed"] = randf_range(_MATRIX_SPD_MIN, _MATRIX_SPD_MAX)
