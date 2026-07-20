extends Node2D

const START_X: float = 360.0
const END_X:   float = 1630.0
const Y:       float = 255.0
const STEPS:   int   = 180      # Nokta sayısı — ne çok o kadar pürüzsüz

const WAVE_AMP:   float = 2.0   # Dalga yüksekliği (px)
const WAVE_FREQ:  float = 0.07  # Dalga sıklığı
const WAVE_SPEED: float = 3.5   # Akış hızı

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var pulse: float = 0.75 + 0.25 * sin(_time * 2.1)

	# Glow katmanı — kalın, yarı saydam
	var glow_pts := PackedVector2Array()
	for i in range(STEPS + 1):
		var t: float = float(i) / float(STEPS)
		var x: float = START_X + t * (END_X - START_X)
		var y: float = Y + sin((x * WAVE_FREQ) + _time * WAVE_SPEED) * WAVE_AMP
		glow_pts.append(Vector2(x, y))
	draw_polyline(glow_pts, Color(0.35, 0.05, 0.8, 0.18 * pulse), 9.0, true)

	# Orta katman
	draw_polyline(glow_pts, Color(0.5, 0.1, 1.0, 0.45 * pulse), 3.5, true)

	# Ana çizgi — parlak mor
	draw_polyline(glow_pts, Color(0.65, 0.25, 1.0, pulse), 1.8, true)

	# Çekirdek — ince beyaz
	draw_polyline(glow_pts, Color(0.9, 0.8, 1.0, pulse * 0.7), 0.8, true)

	# Uç düğümler
	var p0 := glow_pts[0]
	var p1 := glow_pts[glow_pts.size() - 1]
	for p in [p0, p1]:
		draw_circle(p, 4.0, Color(0.5, 0.1, 1.0, pulse))
		draw_circle(p, 1.8, Color(1.0, 0.9, 1.0, pulse))
