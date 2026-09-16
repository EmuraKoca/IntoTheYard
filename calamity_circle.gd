extends Node2D

var radius = 100.0
var color  = Color(1, 1, 0, 0.2)
var aim_texture: Texture2D = null   # Karaktere özel nişan sprite'ı (varsa daire yerine çizilir)

func _draw() -> void:
	if aim_texture:
		draw_texture(aim_texture, -aim_texture.get_size() / 2.0)
		return
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(color.r, color.g, color.b, 0.8), 2.0)
