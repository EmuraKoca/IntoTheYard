extends Area2D

var lost_balls := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Ball" or body.is_in_group("balls"):
		lost_balls += 1
		body.queue_free()
