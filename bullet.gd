extends Area2D

var speed     = 400.0
var direction = Vector2.ZERO
var damage    = 3

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	z_index = 2

func launch(dir: Vector2) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	# Oyun alanı sınırları
	if global_position.x <= 840:  queue_free()
	if global_position.x >= 1640: queue_free()
	if global_position.y <= -60:  queue_free()
	if global_position.y >= 1100: queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("allies"):
		body.take_damage(damage)
		queue_free()
