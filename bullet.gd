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

	# Game area boundaries
	if global_position.x <= 910:  queue_free()
	if global_position.x >= 1580: queue_free()
	if global_position.y <= 0:    queue_free()
	if global_position.y >= 1080: queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("subjects") and not body.name.begins_with("Cyber404"):
		body.set_physics_process(false)
		if body.has_node("CollisionShape2D"):
			body.get_node("CollisionShape2D").set_deferred("disabled", true)
		body.queue_free()
		queue_free()
