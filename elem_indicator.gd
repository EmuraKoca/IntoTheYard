extends Node2D

# Eleman göstergesi — H yarı-boyutunda koyu kare + renkli kenarlık + vektörel ikon
# position = ikonun merkezi (parent koordinatında)

var current_element: String = ""

const H := 9.0  # yarı-boyut → 18 x 18 px kutu

func set_element(elem: String) -> void:
	current_element = elem
	visible = true
	queue_redraw()

func clear_element() -> void:
	current_element = ""
	visible = false

func _draw() -> void:
	if current_element.is_empty():
		return
	_draw_icon(Vector2.ZERO)

func _draw_icon(c: Vector2) -> void:
	var ec: Color
	match current_element:
		"burn":        ec = Color(1.00, 0.28, 0.00)
		"frozen":      ec = Color(0.20, 0.62, 1.00)
		"wet":         ec = Color(0.00, 0.28, 0.90)
		"glitch":      ec = Color(0.70, 0.00, 1.00)
		"electrified": ec = Color(0.95, 0.90, 0.00)
		"slow":        ec = Color(0.28, 0.55, 0.92)
		_: return

	const W := Color(1.0, 1.0, 1.0, 0.96)

	# Dış parıltı
	draw_rect(
		Rect2(c - Vector2(H + 2.5, H + 2.5), Vector2((H + 2.5) * 2, (H + 2.5) * 2)),
		Color(ec.r, ec.g, ec.b, 0.18), true
	)
	# Koyu arka plan
	draw_rect(
		Rect2(c - Vector2(H, H), Vector2(H * 2, H * 2)),
		Color(0.04, 0.04, 0.09, 0.93), true
	)
	# Renkli kenarlık
	draw_rect(
		Rect2(c - Vector2(H, H), Vector2(H * 2, H * 2)),
		Color(ec.r, ec.g, ec.b, 0.90), false, 1.5
	)

	match current_element:

		"burn":
			# Ana alev üçgeni (beyaz)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2( 0.0, -6.5),
				c + Vector2( 5.5,  5.5),
				c + Vector2(-5.5,  5.5),
			]), W)
			# İç koyu oyuk — alev görünümü
			draw_colored_polygon(PackedVector2Array([
				c + Vector2( 0.0,  1.0),
				c + Vector2( 3.0,  5.5),
				c + Vector2(-3.0,  5.5),
			]), Color(0.55, 0.08, 0.00, 0.92))
			# Küçük üst alev dili
			draw_colored_polygon(PackedVector2Array([
				c + Vector2( 0.0, -6.5),
				c + Vector2( 1.6, -3.5),
				c + Vector2(-1.6, -3.5),
			]), Color(1.0, 0.72, 0.10, 0.88))

		"frozen":
			# 3 eksenli kar tanesi + uç çubukları + merkez
			for i in 3:
				var ang  := float(i) * PI / 3.0
				var d    := Vector2(cos(ang), sin(ang))
				var perp := d.rotated(PI * 0.5)
				draw_line(c - d * 6.8, c + d * 6.8, W, 1.5, true)
				# dış çubuklar
				for side in [-1, 1]:
					var tip := c + d * float(side) * 5.0
					draw_line(tip - perp * 2.2, tip + perp * 2.2, W, 1.2, true)
					# küçük V çubukları
					draw_line(tip, tip - (d + perp) * 1.5 * float(side), W, 1.0, true)
					draw_line(tip, tip - (d - perp) * 1.5 * float(side), W, 1.0, true)
			draw_circle(c, 2.0, W)

		"wet":
			# Su damlası: daire + sivri tepe
			draw_circle(c + Vector2(0, 2.5), 4.5, W)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2( 0.0, -7.0),
				c + Vector2( 3.8,  0.5),
				c + Vector2(-3.8,  0.5),
			]), W)
			# İç highlight
			draw_circle(c + Vector2(-1.5, 0.5), 1.5, Color(0.55, 0.75, 1.0, 0.55))

		"glitch":
			# Üç yatay tarama çizgisi — orta kesik (data bozulma efekti)
			draw_rect(Rect2(c + Vector2(-6.5, -6.0), Vector2(13.0, 2.8)), W, true)
			draw_rect(Rect2(c + Vector2(-6.5, -1.4), Vector2( 7.5, 2.8)), W, true)
			draw_rect(Rect2(c + Vector2( 1.5, -1.4), Vector2( 5.0, 2.8)), W, true)
			draw_rect(Rect2(c + Vector2(-6.5,  3.2), Vector2(10.5, 2.8)), W, true)
			# sağ uçta piksel kopukluğu
			draw_rect(Rect2(c + Vector2( 6.0,  3.2), Vector2( 2.5, 2.8)), Color(0.9, 0.1, 1.0, 0.7), true)

		"electrified":
			# Şimşek cıvatası — saat yönünde, self-intersect yok
			draw_colored_polygon(PackedVector2Array([
				c + Vector2( 2.5, -7.5),
				c + Vector2( 1.5, -0.5),
				c + Vector2( 2.0,  0.5),
				c + Vector2(-2.5,  7.5),
				c + Vector2(-1.0,  0.5),
				c + Vector2(-2.0, -0.5),
			]), W)
			# İnce iç çizgi (derinlik)
			draw_line(
				c + Vector2(1.2, -6.0),
				c + Vector2(-1.2, 5.5),
				Color(ec.r, ec.g, 0.2, 0.6), 0.8
			)

		"slow":
			# Kum saati
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-5.5, -7.5), c + Vector2(5.5, -7.5), c + Vector2(0.0, 0.0)
			]), W)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-5.5,  7.5), c + Vector2(5.5,  7.5), c + Vector2(0.0, 0.0)
			]), W)
			# Üst ve alt yatay çubuklar
			draw_rect(Rect2(c + Vector2(-5.5, -8.5), Vector2(11.0, 2.0)), W, true)
			draw_rect(Rect2(c + Vector2(-5.5,  6.5), Vector2(11.0, 2.0)), W, true)
			# Ortadaki ince nokta
			draw_circle(c, 1.3, Color(ec.r, ec.g, ec.b, 0.9))
