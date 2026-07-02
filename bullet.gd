extends Area2D

var speed       = 400.0
var direction   = Vector2.ZERO
var damage      = 3
var bullet_type = "glock"  # "glock", "smg", "shotgun"

# Renk paleti — bullet_type'a göre
var _col_core:  Color
var _col_mid:   Color
var _col_outer: Color

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	z_index = 2
	# ColorRect ve AnimatedSprite2D'yi gizle
	var rect := get_node_or_null("ColorRect")
	if rect: rect.visible = false
	var spr := get_node_or_null("AnimatedSprite2D")
	if spr: spr.visible = false

func launch(dir: Vector2) -> void:
	direction = dir.normalized()
	_pick_colors()
	queue_redraw()

func _pick_colors() -> void:
	match bullet_type:
		"smg":
			_col_core  = Color(1.0, 1.0, 1.0)       # parlak beyaz merkez
			_col_mid   = Color(0.3, 0.6, 1.0)        # mavi
			_col_outer = Color(0.1, 0.2, 0.6, 0.6)   # koyu mavi glow
		"shotgun":
			_col_core  = Color(1.0, 1.0, 0.8)        # parlak sarı merkez
			_col_mid   = Color(1.0, 0.4, 0.05)       # turuncu
			_col_outer = Color(0.5, 0.1, 0.0, 0.6)   # koyu kırmızı glow
		_:  # glock
			_col_core  = Color(1.0, 1.0, 0.6)        # sarı merkez
			_col_mid   = Color(0.9, 0.75, 0.1)       # altın
			_col_outer = Color(0.4, 0.3, 0.0, 0.6)   # koyu sarı glow

func _draw() -> void:
	# Pixel art mermi: 3 katman, keskin kenar, tam piksel
	# Dış glow — 5px, yarı saydam
	draw_circle(Vector2.ZERO, 5.0, _col_outer)
	# Orta halka — 3px
	draw_circle(Vector2.ZERO, 3.0, _col_mid)
	# Parlak merkez — 1px
	draw_circle(Vector2.ZERO, 1.0, _col_core)

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
