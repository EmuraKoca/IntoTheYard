extends Area2D

var speed     = 300.0
var target    = null
var damage    = 3
var max_range = 400.0
var traveled  = 0.0
var direction = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	z_index = 2

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return

	# Hedefe doğru git ama takip etme
	if traveled == 0.0:
		direction = (target.global_position - global_position).normalized()

	global_position += direction * speed * delta
	traveled += speed * delta

	if traveled >= max_range:
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
		_explode()

func _explode() -> void:
	var bodies = get_tree().get_nodes_in_group("player")
	for body in bodies:
		if global_position.distance_to(body.global_position) < 100:
			body.take_damage(damage)
	queue_free()
