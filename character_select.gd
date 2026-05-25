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

func _ready() -> void:
	vector_card = $HBoxContainer/CharacterPanel/CardsContainer/VectorCard
	leila_card = $HBoxContainer/CharacterPanel/CardsContainer/LeilaCard
	cyclone_card = $HBoxContainer/CharacterPanel/CardsContainer/CycloneCard
	
	cards = [vector_card, leila_card, cyclone_card]
	
	for card in cards:
		card.mouse_entered.connect(_on_hover.bind(card))
		card.mouse_exited.connect(_on_hover_exit.bind(card))
		card.connect("gui_input", _on_card_clicked.bind(card))
	
	$Button.pressed.connect(_on_back)
	$Button2.pressed.connect(_on_confirm)
	
	# None selected at start
	for card in cards:
		card.set_meta("selected", false)
		var texture = card.get_node("TextureRect")
		texture.modulate = Color(1, 1, 1)
		


func _on_hover(card) -> void:
	if card.get_meta("selected", false):
		return
	var texture = card.get_node("TextureRect")
	texture.scale = Vector2(1.08, 1.08)
	texture.modulate = Color(1.2, 1.2, 1.2)
	_start_matrix(card)

func _on_hover_exit(card) -> void:
	if card.get_meta("selected", false):
		return
	var texture = card.get_node("TextureRect")
	texture.scale = Vector2(1.0, 1.0)
	texture.modulate = Color(0.4, 0.4, 0.4)
	_stop_matrix(card)

func _select_card(selected) -> void:
	for card in cards:
		var texture = card.get_node("TextureRect")
		if card == selected:
			card.set_meta("selected", true)
			card.scale = Vector2(1.0, 1.0)
			texture.scale = Vector2(1.1, 1.1)
			texture.modulate = Color(1, 1, 1)
		else:
			card.set_meta("selected", false)
			card.scale = Vector2(1.0, 1.0)
			texture.scale = Vector2(1.0, 1.0)
			texture.modulate = Color(0.4, 0.4, 0.4)

func _on_card_clicked(event: InputEvent, card) -> void:
	if event is InputEventMouseButton and event.pressed:
		for c in cards:
			_stop_matrix(c)
		_select_card(card)
		if card == vector_card:
			selected_character = "vector"
			_update_info("Vector", "Jai Alai", "Catch Master", "Caught balls are automatically empowered. Balls hit with the Cesta launch faster and deal more damage.")
		elif card == leila_card:
			selected_character = "leila"
			_update_info("Leila", "Tennis", "Ball Bounce", "Dropped balls bounce once off the ground and return. Racket angle can add spin to balls.")
		elif card == cyclone_card:
			selected_character = "cyclone"
			_update_info("Cyclone", "Sepak Takraw", "Chaotic Strike", "Kicks balls instead of hitting them. Each kick sends balls in unpredictable angles — wild but powerful.")

func _update_info(char_name: String, talent: String, passive: String, description: String) -> void:
	var info = $InfoPanel
	info.get_node("LabelName").text = "Name: " + char_name
	info.get_node("LabelTalent").text = "Talent: " + talent
	info.get_node("LabelPassive").text = "Passive: " + passive
	info.get_node("LabelDescription").text = description

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
