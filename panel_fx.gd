extends Node2D

var size := Vector2.ZERO
var _drops: Array = []
var _flash_alpha := 0.0
var _flash_timer := 0.0

func _ready() -> void:
	_flash_timer = randf_range(1.5, 4.0)
	for i in range(55):
		_drops.append({
			"x":     randf_range(0.0, size.x),
			"y":     randf_range(0.0, size.y),
			"speed": randf_range(280.0, 460.0),
			"len":   randf_range(7.0, 15.0),
		})

func _process(delta: float) -> void:
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		_flash_alpha = randf_range(0.22, 0.50)
		var tw := create_tween()
		tw.tween_property(self, "_flash_alpha", 0.0, randf_range(0.08, 0.18))
		_flash_timer = randf_range(2.0, 6.0)

	for d in _drops:
		d.y += float(d.speed) * delta
		if float(d.y) > size.y + float(d.len):
			d.y = -float(d.len)
			d.x = randf_range(0.0, size.x)
	queue_redraw()

func _draw() -> void:
	# Yağmur — koordinatlar panel sınırına kırpılır
	for d in _drops:
		var x:    float = float(d.x)
		var ybot: float = clamp(float(d.y),                   0.0, size.y)
		var ytop: float = clamp(float(d.y) - float(d.len),    0.0, size.y)
		if ybot <= ytop: continue
		var seg: float = ybot - ytop
		draw_line(
			Vector2(x - seg * 0.06, ytop),
			Vector2(x + seg * 0.06, ybot),
			Color(0.75, 0.88, 1.0, 0.30),
			1.2
		)

	# Şimşek flash
	if _flash_alpha > 0.005:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, _flash_alpha))
