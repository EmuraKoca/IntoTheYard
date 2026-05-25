extends Node2D

func _ready() -> void:
	draw_tribune()

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
