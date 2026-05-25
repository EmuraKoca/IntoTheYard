extends Node2D

var _data_label: Label = null
var _font_bold    = preload("res://assets/orbitronfont/Orbitron-Bold.ttf")
var _font_regular = preload("res://assets/orbitronfont/Orbitron-Regular.ttf")

func _ready() -> void:
	z_index = 5  # BG_Tribune (z_index 3) üzerinde görünsün
	draw_tribune()
	_add_hasmen_presence()

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

func _add_hasmen_presence() -> void:
	# ── VIP Kutu ─────────────────────────────────────────────
	var vip_bg = ColorRect.new()
	vip_bg.position = Vector2(505, 250)
	vip_bg.size     = Vector2(336, 390)
	vip_bg.color    = Color(0.03, 0.01, 0.05, 0.88)
	add_child(vip_bg)

	# Sol neon pembe kenar şerit
	var border_left = ColorRect.new()
	border_left.position = Vector2(505, 250)
	border_left.size     = Vector2(2, 390)
	border_left.color    = Color(1.0, 0.08, 0.58, 0.9)
	add_child(border_left)

	# Üst ince çizgi
	var border_top = ColorRect.new()
	border_top.position = Vector2(505, 250)
	border_top.size     = Vector2(336, 1)
	border_top.color    = Color(1.0, 0.08, 0.58, 0.5)
	add_child(border_top)

	# İsim etiketi
	var name_lbl = Label.new()
	name_lbl.text = "MR. HASMEN"
	name_lbl.position = Vector2(512, 254)
	name_lbl.add_theme_font_override("font", _font_bold)
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.08, 0.58, 0.8))
	add_child(name_lbl)

	# Hasmen görseli
	var hasmen = TextureRect.new()
	hasmen.texture      = load("res://assets/mrHasmen.png")
	hasmen.position     = Vector2(555, 268)
	hasmen.size         = Vector2(240, 368)
	hasmen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hasmen.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	add_child(hasmen)

	# ── Holografik Veri Ekranı ────────────────────────────────
	var screen_bg = ColorRect.new()
	screen_bg.position = Vector2(507, 648)
	screen_bg.size     = Vector2(332, 78)
	screen_bg.color    = Color(0.0, 0.05, 0.04, 0.95)
	add_child(screen_bg)

	# Üst neon çizgi
	var screen_top = ColorRect.new()
	screen_top.position = Vector2(507, 648)
	screen_top.size     = Vector2(332, 1)
	screen_top.color    = Color(0.0, 1.0, 0.55, 0.85)
	add_child(screen_top)

	# "DATA HARVESTED" başlığı
	var screen_title = Label.new()
	screen_title.text = "DATA HARVESTED"
	screen_title.position = Vector2(514, 652)
	screen_title.add_theme_font_override("font", _font_bold)
	screen_title.add_theme_font_size_override("font_size", 9)
	screen_title.add_theme_color_override("font_color", Color(0.0, 0.85, 0.5, 0.7))
	add_child(screen_title)

	# Veri değeri
	_data_label = Label.new()
	_data_label.text = "0 units"
	_data_label.position = Vector2(514, 665)
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
