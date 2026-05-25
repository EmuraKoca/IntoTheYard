extends Node2D

var _data_label: Label = null
var _font_bold    = preload("res://assets/orbitronfont/Orbitron-Bold.ttf")
var _font_regular = preload("res://assets/orbitronfont/Orbitron-Regular.ttf")

func _ready() -> void:
	draw_tribune()
	_add_data_display()

func draw_tribune() -> void:
	# Koltuk sıraları
	for i in range(15):
		var line = Line2D.new()
		var y = 280 + i * 56
		line.add_point(Vector2(490, y))
		line.add_point(Vector2(850, y))
		line.width = 2.0
		line.default_color = Color(0.25, 0.15, 0.15)
		add_child(line)
	# Dikey bölücüler
	for i in range(5):
		var line = Line2D.new()
		var x = 490 + i * 72
		line.add_point(Vector2(x, 240))
		line.add_point(Vector2(x, 1080))
		line.width = 1.0
		line.default_color = Color(0.2, 0.12, 0.12)
		add_child(line)

func _add_data_display() -> void:
	# ── Holografik Veri Ekranı (tribünün alt kısmı) ──────────
	var screen_bg = ColorRect.new()
	screen_bg.position = Vector2(507, 900)
	screen_bg.size     = Vector2(332, 72)
	screen_bg.color    = Color(0.0, 0.05, 0.04, 0.95)
	add_child(screen_bg)

	# Üst neon yeşil çizgi
	var screen_top = ColorRect.new()
	screen_top.position = Vector2(507, 900)
	screen_top.size     = Vector2(332, 1)
	screen_top.color    = Color(0.0, 1.0, 0.55, 0.85)
	add_child(screen_top)

	# "DATA HARVESTED" başlığı
	var title_lbl = Label.new()
	title_lbl.text = "DATA HARVESTED"
	title_lbl.position = Vector2(514, 904)
	title_lbl.add_theme_font_override("font", _font_bold)
	title_lbl.add_theme_font_size_override("font_size", 9)
	title_lbl.add_theme_color_override("font_color", Color(0.0, 0.85, 0.5, 0.7))
	add_child(title_lbl)

	# Veri değeri
	_data_label = Label.new()
	_data_label.text = "0 units"
	_data_label.position = Vector2(514, 918)
	_data_label.add_theme_font_override("font", _font_bold)
	_data_label.add_theme_font_size_override("font_size", 22)
	_data_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.55, 1.0))
	add_child(_data_label)

func update_data(amount: int) -> void:
	if _data_label:
		_data_label.text = _format_data(amount) + " units"

func _format_data(n: int) -> String:
	if n >= 1_000_000:
		return "%.2f M" % (n / 1_000_000.0)
	elif n >= 1_000:
		return "%.1f K" % (n / 1_000.0)
	return str(n)
