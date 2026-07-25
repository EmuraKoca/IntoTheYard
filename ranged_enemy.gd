extends "res://base_enemy.gd"

var shoot_timer: float = 0.0
var shoot_interval: float = 3.0
var bullet_scene = preload("res://bullet.tscn")

func _elem_indicator_y_offset() -> float:
	return -72.0

func _update_anim(_moving: bool) -> void:
	pass  # child override: walk_ veya idle_ prefix ile anim oynat
