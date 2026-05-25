extends Node2D

var radius = 100.0
var color  = Color(1, 1, 0, 0.2)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(color.r, color.g, color.b, 0.8), 2.0)
