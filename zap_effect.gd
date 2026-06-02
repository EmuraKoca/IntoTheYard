extends Node2D
# Kisa sureli elektrik kivircima efekti — dusmanin uzerinde spawn edilir

var _t      : float = 0.0
var _life   : float = 0.35
var _lines  : Array = []   # [Vector2 start, Vector2 end] ciftleri

func _ready() -> void:
	z_index = 12
	_generate()

func _generate() -> void:
	_lines.clear()
	for i in 10:
		var angle  : float   = randf() * TAU
		var length : float   = randf_range(12.0, 36.0)
		var mid    : Vector2 = Vector2(cos(angle), sin(angle)) * length * 0.45
		mid += Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		_lines.append([Vector2.ZERO, mid,
			Vector2(cos(angle), sin(angle)) * length])

func _process(delta: float) -> void:
	_t += delta
	if _t > _life * 0.4:
		_generate()   # kivircik yeniden uretilir (canlilik hissi)
	queue_redraw()
	if _t >= _life:
		queue_free()

func _draw() -> void:
	var alpha : float = 1.0 - clamp(_t / _life, 0.0, 1.0)
	for seg in _lines:
		var a : Vector2 = seg[0]
		var m : Vector2 = seg[1]
		var b : Vector2 = seg[2]
		# Dis parlama
		draw_line(a, b, Color(0.8, 1.0, 0.1, alpha * 0.35), 6.0)
		# Ana seg (kivrik)
		draw_line(a, m, Color(1.8, 2.0, 0.2, alpha * 0.95), 2.2)
		draw_line(m, b, Color(1.8, 2.0, 0.2, alpha * 0.95), 2.2)
		# Parlak cekirdek
		draw_line(a, m, Color(2.5, 2.5, 0.8, alpha), 0.9)
		draw_line(m, b, Color(2.5, 2.5, 0.8, alpha), 0.9)
	# Merkez parlama noktasi
	draw_circle(Vector2.ZERO, 8.0 * alpha, Color(2.0, 2.2, 0.3, alpha * 0.8))
