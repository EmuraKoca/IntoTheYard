extends Node2D

# Sabit kalınlıklı, dalgalı genişleyen dalga halkası (sprite'ı büyütmek kalınlığı da büyütüyordu).
# Kenar açıya göre iki sinüsle dalgalanır; dalgalar zamanla kayar (canlı, akışkan görünüm).
var radius := 0.0:
	set(v):
		radius = v
		queue_redraw()
var thickness := 5.0
var wave_amp := 12.0     # px — dalga yüksekliği
var wave_count := 9      # halka çevresindeki ana dalga sayısı
var alpha := 1.0:
	set(v):
		alpha = v
		queue_redraw()
var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	if radius < 2.0:
		return
	var n := maxi(64, int(radius / 3.0))
	var pts := PackedVector2Array()
	var amp := minf(wave_amp, radius * 0.25)
	for i in range(n + 1):
		var a := TAU * float(i) / float(n)
		var r := radius + amp * sin(a * wave_count + _t * 14.0) + amp * 0.5 * sin(a * (wave_count * 2 + 1) - _t * 9.0)
		pts.append(Vector2(cos(a), sin(a)) * r)
	draw_polyline(pts, Color(0.55, 0.6, 1.0, 0.25 * alpha), thickness * 3.0, true)
	draw_polyline(pts, Color(0.7, 0.75, 1.0, 0.9 * alpha), thickness, true)
	draw_polyline(pts, Color(1, 1, 1, alpha), maxf(1.0, thickness * 0.4), true)
