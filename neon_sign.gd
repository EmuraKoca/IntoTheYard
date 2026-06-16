extends Node2D

const COLOR_MAIN := Color(0.0, 3.5, 3.8)
const COLOR_SUB  := Color(2.2, 0.1, 2.8)
const COLOR_OFF  := Color(0.05, 0.05, 0.08)

const SIGN_W := 52.0
const SIGN_H := 160.0

var _label1: Label = null
var _label2: Label = null

var _flicker_timer: float = 0.0
var _flicker_next: float  = randf_range(2.0, 5.0)
var _base_y: float        = 0.0
var _swing_speed: float   = 0.6
var _swing_amount: float  = 2.0

func _ready() -> void:
	z_index       = 5
	z_as_relative = false
	await get_tree().process_frame
	_base_y = position.y

	var font_bold = load("res://assets/orbitronfont/Orbitron-Bold.ttf")
	var font_reg  = load("res://assets/orbitronfont/Orbitron-Regular.ttf")

	# ── Tabela arka plan ──────────────────────────────────────────
	var panel := ColorRect.new()
	panel.size     = Vector2(SIGN_W, SIGN_H)
	panel.position = Vector2(-SIGN_W * 0.5, 0)
	panel.color    = Color(0.04, 0.05, 0.10, 0.95)
	add_child(panel)

	# Çerçeve
	for side in [
		[Vector2(0, 0),            Vector2(SIGN_W, 2)],
		[Vector2(0, SIGN_H - 2),   Vector2(SIGN_W, 2)],
		[Vector2(0, 0),            Vector2(2, SIGN_H)],
		[Vector2(SIGN_W - 2, 0),   Vector2(2, SIGN_H)],
	]:
		var b := ColorRect.new()
		b.position = side[0]
		b.size     = side[1]
		b.color    = Color(0.0, 0.85, 1.0, 0.9)
		panel.add_child(b)

	# ── Duvara bağlayan yatay borular ────────────────────────────
	for pipe_y in [SIGN_H * 0.25, SIGN_H * 0.7]:
		var pipe := Line2D.new()
		pipe.default_color = Color(0.35, 0.35, 0.45, 1.0)
		pipe.width = 5.0
		pipe.add_point(Vector2(-SIGN_W * 0.5, pipe_y))
		pipe.add_point(Vector2(-SIGN_W * 0.5 - 28, pipe_y))
		add_child(pipe)

		var bolt := ColorRect.new()
		bolt.size     = Vector2(6, 10)
		bolt.position = Vector2(-SIGN_W * 0.5 - 31, pipe_y - 5)
		bolt.color    = Color(0.5, 0.5, 0.6, 1.0)
		add_child(bolt)

	# ── Ana yazı: ITY Corp. ───────────────────────────────────────
	_label1 = Label.new()
	_label1.text          = "ITY\nCorp.\nR&D\nUnit."
	_label1.add_theme_font_override("font", font_bold)
	_label1.add_theme_font_size_override("font_size", 11)
	_label1.add_theme_color_override("font_color", COLOR_MAIN)
	_label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label1.size     = Vector2(SIGN_W - 8, 110)
	_label1.position = Vector2(5, 8)
	panel.add_child(_label1)

	# ── Alt yazı ─────────────────────────────────────────────────
	_label2 = Label.new()
	_label2.text          = "For\nHuman ITY"
	_label2.add_theme_font_override("font", font_reg)
	_label2.add_theme_font_size_override("font_size", 9)
	_label2.add_theme_color_override("font_color", COLOR_SUB)
	_label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label2.size     = Vector2(SIGN_W - 8, 40)
	_label2.position = Vector2(5, 118)
	panel.add_child(_label2)

func _process(delta: float) -> void:
	_flicker_timer += delta
	if _flicker_timer >= _flicker_next:
		_flicker_timer = 0.0
		_flicker_next  = randf_range(2.0, 6.0)
		_do_blink(randi_range(1, 3))

func _do_blink(remaining: int) -> void:
	if remaining <= 0:
		_label1.add_theme_color_override("font_color", COLOR_MAIN)
		_label2.add_theme_color_override("font_color", COLOR_SUB)
		return
	_label1.add_theme_color_override("font_color", COLOR_OFF)
	_label2.add_theme_color_override("font_color", COLOR_OFF)
	get_tree().create_timer(randf_range(0.04, 0.12)).timeout.connect(func() -> void:
		_label1.add_theme_color_override("font_color", COLOR_MAIN)
		_label2.add_theme_color_override("font_color", COLOR_SUB)
		get_tree().create_timer(randf_range(0.06, 0.2)).timeout.connect(func() -> void:
			_do_blink(remaining - 1)
		)
	)
