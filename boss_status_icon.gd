extends Control

# Boss can barının altındaki durum etkisi kutusu (MMO tarzı): ikon + saat yönünde dolan
# "cooldown" süpürmesi (kalan süre koyu bölge olarak azalır) + üzerine gelince açıklama.
# Kullanım: game_scene.gd::show_boss_status(id, ikon_yolu, süre, başlık, açıklama).

const SIZE_PX := 40.0
var _tex: Texture2D
var _duration := 1.0
var _elapsed := 0.0
var _title := ""
var _desc := ""
var _tip: PanelContainer
var _tip_time: Label

func setup(icon_path: String, duration: float, title: String, desc: String) -> void:
	_tex = load(icon_path) if ResourceLoader.exists(icon_path) else null
	_duration = maxf(duration, 0.05)
	_title = title
	_desc = desc
	custom_minimum_size = Vector2(SIZE_PX, SIZE_PX)
	size = Vector2(SIZE_PX, SIZE_PX)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Üst canvas PROCESS_MODE_ALWAYS — süre oyunla birlikte (pause'da) dursun
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_tip()
	mouse_entered.connect(func(): _tip.visible = true)
	mouse_exited.connect(func(): _tip.visible = false)

func _build_tip() -> void:
	_tip = PanelContainer.new()
	_tip.visible = false
	_tip.z_index = 50
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.09, 0.95)
	sb.border_color = Color(0.9, 0.7, 0.25)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(10)
	_tip.add_theme_stylebox_override("panel", sb)
	var font = load("res://assets/silverfont/Silver.ttf")
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_child(box)
	var t := Label.new()
	t.text = _title
	t.add_theme_font_override("font", font)
	t.add_theme_font_size_override("font_size", 38)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	box.add_child(t)
	var d := Label.new()
	d.text = _desc
	d.add_theme_font_override("font", font)
	d.add_theme_font_size_override("font_size", 19)
	box.add_child(d)
	_tip_time = Label.new()
	_tip_time.add_theme_font_override("font", font)
	_tip_time.add_theme_font_size_override("font_size", 19)
	_tip_time.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	box.add_child(_tip_time)
	_tip.position = Vector2(0, SIZE_PX + 6)
	add_child(_tip)

func _process(delta: float) -> void:
	_elapsed += delta
	if _tip.visible:
		_tip_time.text = "%.1f sn" % maxf(_duration - _elapsed, 0.0)
	queue_redraw()
	if _elapsed >= _duration:
		queue_free()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(SIZE_PX, SIZE_PX))
	draw_rect(r, Color(0.12, 0.13, 0.17, 0.95))
	if _tex != null:
		draw_texture_rect(_tex, r.grow(-3.0), false)
	# Saat yönünde süpürme: geçen süre kadar açık, kalan kısım koyu (12 yönünden başlar)
	var frac := clampf(_elapsed / _duration, 0.0, 1.0)
	if frac < 1.0:
		var c := r.get_center()
		var a0 := -PI / 2.0 + frac * TAU
		var a1 := -PI / 2.0 + TAU
		var pts := PackedVector2Array([c])
		var steps := maxi(4, int((a1 - a0) / TAU * 48.0))
		var rad := SIZE_PX * 0.75   # köşeleri de kapsasın, kare dışına taşan kısım clip edilmez ama kutu içinde çizilir
		for i in range(steps + 1):
			var a := a0 + (a1 - a0) * float(i) / float(steps)
			var p := c + Vector2(cos(a), sin(a)) * rad
			pts.append(Vector2(clampf(p.x, 0.0, SIZE_PX), clampf(p.y, 0.0, SIZE_PX)))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.6))
	draw_rect(r, Color(0.9, 0.7, 0.25), false, 2.0)
