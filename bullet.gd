extends Area2D

var speed       = 400.0
var direction   = Vector2.ZERO
var damage      = 3
var bullet_type = "glock"  # "glock", "smg", "shotgun"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	z_index = 2

func launch(dir: Vector2) -> void:
	direction = dir.normalized()
	_setup_sprite()

func _setup_sprite() -> void:
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	if not sprite:
		return

	var folder_s  := "res://assets/projectiles/" + _folder_name() + "/"
	var folder_se := "res://assets/projectiles/" + _folder_name() + "_SE/"
	var folder_sw := "res://assets/projectiles/" + _folder_name() + "_SW/"

	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for anim in [["S", folder_s], ["SE", folder_se], ["SW", folder_sw]]:
		var key: String   = anim[0]
		var folder: String = anim[1]
		frames.add_animation(key)
		frames.set_animation_speed(key, 12.0)
		frames.set_animation_loop(key, true)
		for i in range(10):
			var path := folder + "frame_%03d.png" % i
			if ResourceLoader.exists(path):
				frames.add_frame(key, load(path))

	sprite.sprite_frames = frames
	sprite.scale = Vector2(0.4, 0.4)  # Sprite boyutu küçültme

	# Yöne göre animasyon seç
	# Godot angle(): East=0°, S(aşağı)=90°, SE=45°, SW=135°
	var angle := rad_to_deg(direction.angle())
	var anim_key := "S"
	if angle >= 25.0 and angle < 70.0:
		anim_key = "SE"   # sağ-aşağı
	elif angle >= 110.0 and angle < 155.0:
		anim_key = "SW"   # sol-aşağı

	if frames.has_animation(anim_key) and frames.get_frame_count(anim_key) > 0:
		sprite.play(anim_key)
	elif frames.get_frame_count("S") > 0:
		sprite.play("S")

	# ColorRect'i gizle — sprite var
	var rect := get_node_or_null("ColorRect")
	if rect:
		rect.visible = false

func _folder_name() -> String:
	match bullet_type:
		"smg":     return "smg"
		"shotgun": return "shotgunAmmo"
		_:         return "glock"

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

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
