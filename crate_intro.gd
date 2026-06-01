extends Node2D
# Procedurel tahta sandık — boss intro sekansı
# Kullanım: crate.play_intro(land_pos: Vector2)
# Sinyaller: "landed" (kamera sarsıntısı), "boss_emerged" (boss spawn zamanı)

signal landed
signal boss_emerged

const CRATE_W := 108.0
const CRATE_H := 108.0
const HW      := CRATE_W * 0.5
const HH      := CRATE_H * 0.5
const LID_H   := 13.0

const C_WOOD_DARK  := Color(0.24, 0.13, 0.04)
const C_WOOD_MID   := Color(0.40, 0.24, 0.08)
const C_WOOD_LIGHT := Color(0.54, 0.34, 0.13)
const C_METAL      := Color(0.50, 0.52, 0.56)
const C_METAL_DARK := Color(0.28, 0.30, 0.33)
const C_RIVET      := Color(0.68, 0.70, 0.74)
const C_DANGER     := Color(0.95, 0.72, 0.04)

# Animasyon state
var _lid_angle    : float   = 0.0
var _lid_offset_y : float   = 0.0
var _show_lid     : bool    = true
var _flash        : float   = 0.0
var _dust_t       : float   = -1.0
var _boss_rise    : float   = 0.0
var _shake_ofs    : Vector2 = Vector2.ZERO

# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = max(0.0, _flash - delta * 3.5)
	if _dust_t >= 0.0 and _dust_t < 1.0:
		_dust_t = min(1.0, _dust_t + delta * 0.9)
	queue_redraw()

func _draw() -> void:
	var b := _shake_ofs
	_draw_shadow(b)
	_draw_body(b)
	if _show_lid:
		_draw_lid(b)
	if _flash > 0.0:
		draw_circle(b, HW * 2.1, Color(1.0, 0.82, 0.35, _flash * 0.55))
	if _dust_t >= 0.0 and _dust_t < 1.0:
		_draw_dust(b)
	if _boss_rise > 0.0:
		_draw_boss_rise(b)

# ─── Gölge ───────────────────────────────────────────────────────────────────
func _draw_shadow(b: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := float(i) / 24.0 * TAU
		pts.append(b + Vector2(cos(a) * HW * 1.1, HH + 5.0 + sin(a) * 9.0))
	draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, 0.42))

# ─── Gövde ───────────────────────────────────────────────────────────────────
func _draw_body(b: Vector2) -> void:
	# Zemin rengi
	draw_rect(Rect2(b.x - HW, b.y - HH, CRATE_W, CRATE_H), C_WOOD_DARK)

	# 3 yatay tahta tahtası
	var ph := CRATE_H / 3.0
	for i in 3:
		var py  : float = b.y - HH + i * ph
		var col : Color = C_WOOD_MID if i % 2 == 0 else C_WOOD_LIGHT
		draw_rect(Rect2(b.x - HW + 3.0, py + 2.0, CRATE_W - 6.0, ph - 4.0), col)
		draw_line(Vector2(b.x - HW + 3.0, py), Vector2(b.x + HW - 3.0, py),
				  C_WOOD_DARK, 2.0)

	# Ahşap damar — ince dikey çizgiler
	for xo in [-30.0, 2.0, 30.0]:
		draw_line(
			Vector2(b.x + xo,       b.y - HH + 8.0),
			Vector2(b.x + xo + 5.0, b.y + HH - 8.0),
			Color(C_WOOD_DARK.r, C_WOOD_DARK.g, C_WOOD_DARK.b, 0.36), 1.5
		)

	# Yatay metal bant (ortada)
	draw_rect(Rect2(b.x - HW, b.y - 7.0, CRATE_W, 14.0), C_METAL_DARK)
	draw_rect(Rect2(b.x - HW, b.y - 5.0, CRATE_W, 10.0), C_METAL)
	draw_line(Vector2(b.x - HW, b.y - 5.0), Vector2(b.x + HW, b.y - 5.0),
			  Color(0.76, 0.78, 0.82), 1.5)

	_draw_corners(b)
	_draw_warning(b)

func _draw_corners(b: Vector2) -> void:
	var arm := 17.0
	var th  := 6.0
	for sxi in [-1, 1]:
		for syi in [-1, 1]:
			var sx : float = float(sxi)
			var sy : float = float(syi)
			# Köşe başlangıç noktası (sandığın iç yönünde)
			var bkx : float = b.x - HW         if sx < 0.0 else b.x + HW - arm
			var bky : float = b.y - HH         if sy < 0.0 else b.y + HH - arm
			# Koyu arka plan kare
			draw_rect(Rect2(bkx, bky, arm, arm), C_METAL_DARK)
			# Yatay kol
			var hy : float  = bky               if sy < 0.0 else bky + arm - th
			draw_rect(Rect2(bkx, hy, arm, th), C_METAL)
			# Dikey kol
			var vx : float  = bkx               if sx < 0.0 else bkx + arm - th
			draw_rect(Rect2(vx, bky, th, arm), C_METAL)
			# Perçin
			draw_circle(b + Vector2(sx * (HW - 9.5), sy * (HH - 9.5)), 2.5, C_RIVET)

func _draw_warning(b: Vector2) -> void:
	# Sarı uyarı üçgeni
	var s   := 21.0
	var tri := PackedVector2Array([
		b + Vector2(0.0,        -s),
		b + Vector2(s * 0.866,   s * 0.5),
		b + Vector2(-s * 0.866,  s * 0.5)
	])
	draw_colored_polygon(tri, C_DANGER)
	# İç (koyu alan)
	var si    := s * 0.66
	var tri_i := PackedVector2Array([
		b + Vector2(0.0,               -si + 5.0),
		b + Vector2(si * 0.866 - 3.5,   si * 0.5 - 1.0),
		b + Vector2(-si * 0.866 + 3.5,  si * 0.5 - 1.0)
	])
	draw_colored_polygon(tri_i, C_WOOD_DARK)
	# Ünlem işareti
	draw_line(b + Vector2(0.0, -s * 0.28), b + Vector2(0.0, s * 0.15), C_DANGER, 4.0)
	draw_circle(b + Vector2(0.0, s * 0.32), 2.8, C_DANGER)

# ─── Kapak ───────────────────────────────────────────────────────────────────
func _draw_lid(b: Vector2) -> void:
	var pivot := b + Vector2(0.0, -HH)
	var hw_l  := HW + 4.0
	var pts   := PackedVector2Array([
		Vector2(-hw_l,  0.0),
		Vector2( hw_l,  0.0),
		Vector2( hw_l, -LID_H),
		Vector2(-hw_l, -LID_H),
	])
	var res := PackedVector2Array()
	for p in pts:
		res.append(pivot + p.rotated(_lid_angle) + Vector2(0.0, _lid_offset_y))

	draw_colored_polygon(res, C_WOOD_MID)
	draw_line(res[0], res[1], C_WOOD_DARK, 2.5)
	draw_line(res[3], res[2], C_WOOD_DARK, 1.5)
	# Metal şerit
	var ma := res[0].lerp(res[3], 0.5)
	var mb := res[1].lerp(res[2], 0.5)
	draw_line(ma, mb, C_METAL, 3.0)
	# Kilit
	var lp := res[0].lerp(res[1], 0.5)
	draw_circle(lp, 4.5, C_METAL_DARK)
	draw_circle(lp, 3.0, C_METAL)
	draw_circle(lp, 1.5, C_METAL_DARK)

# ─── Toz bulutu ──────────────────────────────────────────────────────────────
func _draw_dust(b: Vector2) -> void:
	var t := _dust_t
	for i in 10:
		var angle : float = float(i) / 10.0 * TAU
		var dist  : float = t * HW * 1.55
		var sz    : float = (1.0 - t) * 9.0 + 2.0
		var alpha : float = (1.0 - t) * 0.65
		draw_circle(
			b + Vector2(cos(angle) * dist, HH - 3.0 + sin(angle) * dist * 0.28),
			sz, Color(0.60, 0.49, 0.33, alpha)
		)

# ─── Boss gözleri yükseliyor ──────────────────────────────────────────────────
func _draw_boss_rise(b: Vector2) -> void:
	var t   := _boss_rise
	var ey  : float = b.y + HH * (1.0 - t * 1.55) - 6.0
	var esp : float = 13.0 * min(t * 2.0, 1.0)
	var er  : float = 4.5 * t
	for ex in [b.x - esp, b.x + esp]:
		draw_circle(Vector2(ex, ey), er * 2.3, Color(1.0, 0.04, 0.04, t * 0.32))
		draw_circle(Vector2(ex, ey), er,        Color(1.0, 0.08, 0.08))
		if t > 0.25:
			draw_circle(Vector2(ex - 1.0, ey - 1.0), er * 0.32,
						Color(1.0, 0.75, 0.75, 0.85))

# ─── Ana sekans ───────────────────────────────────────────────────────────────
func play_intro(land_pos: Vector2) -> void:
	position = Vector2(land_pos.x, -160.0)
	z_index  = 5

	# 1 — Düşüş
	var fall := create_tween()
	fall.tween_property(self, "position:y", land_pos.y, 0.88)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fall.finished

	# 2 — Çarpma: flash + toz + sinyal
	_flash  = 1.0
	_dust_t = 0.0
	emit_signal("landed")

	await get_tree().create_timer(0.90).timeout

	# 3 — Sandık titriyor (kapak açılmak üzere)
	for _i in 4:
		var shk := create_tween()
		shk.tween_property(self, "_shake_ofs",
			Vector2(randf_range(-5.0, 5.0), randf_range(-2.0, 2.0)), 0.05)
		shk.tween_property(self, "_shake_ofs", Vector2.ZERO, 0.05)
		await shk.finished
		await get_tree().create_timer(0.11).timeout

	# 4 — Kapak fırlar
	var lid_open := create_tween()
	lid_open.set_parallel(true)
	lid_open.tween_property(self, "_lid_angle",    -PI * 0.82, 0.20)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lid_open.tween_property(self, "_lid_offset_y", -55.0,      0.20)
	await lid_open.finished

	# Kapak uçup gider
	var lid_fly := create_tween()
	lid_fly.set_parallel(true)
	lid_fly.tween_property(self, "_lid_offset_y", -340.0,     0.55)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	lid_fly.tween_property(self, "_lid_angle",    -PI * 1.45, 0.55)

	await get_tree().create_timer(0.18).timeout

	# 5 — Boss gözleri sandıktan yükselir
	var rise := create_tween()
	rise.tween_property(self, "_boss_rise", 1.0, 0.78)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await rise.finished

	await get_tree().create_timer(0.35).timeout

	_show_lid = false
	emit_signal("boss_emerged")
