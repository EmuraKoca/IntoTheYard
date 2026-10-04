extends Node2D
# Boss intro sandığı — düşme + iniş + parçalanma sekansı
# Kullanım: crate.play_intro(land_pos: Vector2)
# Sinyaller: "landed" (kamera sarsıntısı), "boss_emerged" (boss spawn zamanı)
#
# Öncelik: assets/VFX/bossCrate/frame_000.png.. (gerçek sprite animasyonu — düşüş,
# çarpma, sarsılma, parçalanma tek sürekli animasyon olarak). Sprite yoksa eski
# procedural (_draw ile çizilen) sekansa düşülüyor, crash yok.

signal landed
signal boss_emerged
var _landed_fired := false
var _visible_fired := false

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

# Animasyon state (sadece procedural fallback için)
var _lid_angle    : float   = 0.0
var _lid_offset_y : float   = 0.0
var _show_lid     : bool    = true
var _flash        : float   = 0.0
var _dust_t       : float   = -1.0
var _boss_rise    : float   = 0.0
var _shake_ofs    : Vector2 = Vector2.ZERO
var _use_fallback_draw : bool = false
var _shadow : Polygon2D = null
var _owns_cleanup : bool = false  # true ise game_scene.gd kutuyu erken silmez

# Kırılma sesi için self-disconnecting dinleyici — adlı (named) fonksiyon + instance
# değişkenleri kullanıyor (bkz. _on_smash_frame_check). Lambda içinde kendi kendine
# referans veren bir Callable denenmişti ama GDScript'te closure, dış değişkeni atama
# TAMAMLANMADAN ÖNCEKİ (null) hâliyle yakalıyor — disconnect() "callable is null" hatası
# veriyordu, guard devre dışı kalıp ses art arda birden fazla kez tetikleniyordu.
var _smash_check_sprite : AnimatedSprite2D = null
var _smash_check_player : AudioStreamPlayer = null

# Sprite animasyonunda kutu görsel olarak küçük kaldığı için büyütme çarpanı
const CRATE_SPRITE_SCALE := 1.76  # 1.3 × 1.35 (boss büyümesiyle aynı %35 oran)

# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _use_fallback_draw:
		return
	if _flash > 0.0:
		_flash = max(0.0, _flash - delta * 3.5)
	if _dust_t >= 0.0 and _dust_t < 1.0:
		_dust_t = min(1.0, _dust_t + delta * 0.9)
	queue_redraw()

func _draw() -> void:
	if not _use_fallback_draw:
		return
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
	if ResourceLoader.exists("res://assets/VFX/bossCrate/frame_000.png"):
		await _play_intro_sprite(land_pos)
	else:
		await _play_intro_fallback(land_pos)

# Gerçek sprite animasyonu — düşüş + çarpma + sarsılma + parçalanma tek sürekli
# animasyon olarak (37 kare). Kullanıcının kare kare tarif ettiği kesin zamanlama:
# 0-9: düşüş, 10: çarpma, 14: ilk kırılma, 25: boss deliklerden görünür hale geliyor.
# Kutunun kendisi düşme boyunca sabit dünya pozisyonunda kalıyor (Y ekseninde
# tween'lenmiyor — düşüş hareketi animasyonun kendi kareleri içinde).
const IMPACT_FRAME  := 10
const CRACK_FRAME   := 14  # sadece düşüş sesinin bitişini senkronlamak için (_pre_delay), kırılma sesi kaldırıldı
const VISIBLE_FRAME := 25  # boss bu kareden itibaren deliklerden görünüyor → spawn edilir

const FALL_FPS := 14.0
const FALL_START_OFFSET := 700.0  # ekran dışı yukarıdan düşüş mesafesi

func _play_intro_sprite(land_pos: Vector2) -> void:
	# Düşüş sesi (3.5sn) çok daha ERKEN başlıyor — sesin SONU tam çarpma anına
	# (IMPACT_FRAME) denk gelecek şekilde geriye doğru hesaplanmış bir gecikmeyle.
	# Kullanıcı: "falling'in sonunu tam smash'e denk getir" — kutu bu bekleme süresi
	# boyunca henüz görünmüyor (hiç sprite/tween kurulmadı), sadece ses çalıyor.
	# NOT (2026-10-01): KÖK SEBEP BULUNDU — kırılma sesi hiç bozuk/takılı DEĞİLDİ, sorun
	# _smash_player'ın kutunun (self) child'ı olmasıydı: kutu ~5sn civarında kendini
	# queue_free() ediyor, child olan ses node'u da onunla birlikte siliniyor/kesiliyor —
	# "takılmış/üst üste binmiş" gibi duyulan şey buydu. Sabit 5sn'lik zamanlayıcı testinde
	# ses TERTEMİZ çaldı (kutuyla aynı parent'a bağlanınca) — artık tekrar frame'e (10,
	# IMPACT_FRAME — çarpma anıyla aynı kare) bağlanıyor, SADECE kutudan bağımsız bir
	# parent'a (gölgedeki desenin aynısı) eklenerek.
	const FALL_SFX_PATH  := "res://assets/sfx/cyber404BossCrate/fallingdown.ogg"
	const SMASH_SFX_PATH := "res://assets/sfx/cyber404BossCrate/woodSmash.ogg"
	var _fall_stream: AudioStream = load(FALL_SFX_PATH)
	var _fall_dur: float = _fall_stream.get_length() if _fall_stream else 3.2
	var _crack_time: float = float(CRACK_FRAME) / FALL_FPS
	var _pre_delay: float = max(0.0, _fall_dur - _crack_time)

	Sfx.play_path(FALL_SFX_PATH)

	# Kutunun (self) child'ı DEĞİL — kutuyla aynı parent'a (gölgedeki desenin aynısı)
	# bağlanıyor, kutu kendini queue_free() etse bile bu node hayatta kalıyor.
	var _smash_player := AudioStreamPlayer.new()
	_smash_player.stream = load(SMASH_SFX_PATH) if ResourceLoader.exists(SMASH_SFX_PATH) else null
	_smash_player.bus = "GameplaySFX" if AudioServer.get_bus_index("GameplaySFX") >= 0 else "Master"
	_smash_player.process_mode = Node.PROCESS_MODE_ALWAYS
	# Dosya kısa kalıyordu (1.44sn) — pitch_scale ile (Gravitational Force/WormHole'deki
	# aynı yöntem) dosyaya dokunmadan ~2.1sn'ye uzatılıyor (kullanıcı: "2, 2.3sn gibi").
	_smash_player.pitch_scale = 0.68
	get_parent().add_child(_smash_player)
	_smash_player.finished.connect(func():
		if is_instance_valid(_smash_player): _smash_player.queue_free()
	)

	if _pre_delay > 0.0:
		await get_tree().create_timer(_pre_delay, false).timeout

	# Ekran dışı yukarıdan başlayıp land_pos'a düşüyor — sprite'ın kendi kareleri
	# görsel olarak yeterli düşüş hissi vermiyordu (kullanıcı: "bir anda beliriyor"),
	# gerçek bir Y-tween eklendi. Tween süresi çarpma karesiyle (IMPACT_FRAME) senkron.
	position = Vector2(land_pos.x, land_pos.y - FALL_START_OFFSET)
	z_index  = 5

	_setup_fall_shadow(land_pos)

	var spr := AnimatedSprite2D.new()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(CRATE_SPRITE_SCALE, CRATE_SPRITE_SCALE)
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("crate")
	sf.set_animation_loop("crate", false)
	var total := 0
	while ResourceLoader.exists("res://assets/VFX/bossCrate/frame_%03d.png" % total):
		sf.add_frame("crate", load("res://assets/VFX/bossCrate/frame_%03d.png" % total))
		total += 1
	sf.set_animation_speed("crate", FALL_FPS)
	spr.sprite_frames = sf
	add_child(spr)
	spr.play("crate")

	var fall_tw := create_tween()
	fall_tw.tween_property(self, "position:y", land_pos.y, float(IMPACT_FRAME) / FALL_FPS)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# DİKKAT: bayraklar INSTANCE değişkeni (aşağıda) — yerel `var x := false` olsaydı lambda onu
	# DEĞERE göre kopyalar, `x = true` kalıcı olmaz ve sinyal her karede yeniden ateşlenirdi
	# ("landed"/"boss_emerged" 10+ kez → toz halkası üst üste, ses tekrarı hatalarının asıl sebebi).
	spr.frame_changed.connect(func():
		_update_fall_shadow(spr.frame)
		if not _landed_fired and spr.frame >= IMPACT_FRAME:
			_landed_fired = true
			emit_signal("landed")
		if not _visible_fired and spr.frame >= VISIBLE_FRAME:
			_visible_fired = true
			# game_scene.gd::_on_boss_emerged() bu bayrağı görünce kutuyu HEMEN
			# soldurup silmiyor — animasyonun kalan kareleri (25→36) oynamaya devam
			# etsin diye temizlik bu fonksiyonun sonunda (animasyon bitince) yapılıyor.
			_owns_cleanup = true
			emit_signal("boss_emerged")
	)

	# Kırılma sesi AYRI, kendi kendine bağlantıyı kesen (self-disconnecting) bir
	# tetikleyiciyle çalıyor — bool bayrak (`_landed_fired` deseni) `frame_changed`
	# beklenenden fazla ateşlendiğinde (sahne yoğunluğu/hitch şüphesi) yine de ikinci bir
	# `.play()` çağrısına açık kalabiliyordu ("7-8 kere taramalı tüfek gibi" — her çağrı
	# öncekini kesiyordu). Self-reference içeren bir lambda (`_smash_cb = func(): ...
	# disconnect(_smash_cb)`) denenmişti ama GDScript closure'ı dış değişkeni ATAMA
	# TAMAMLANMADAN ÖNCEKİ (null) hâliyle yakalıyor — disconnect() "callable is null"
	# hatası verip guard'ı devre dışı bırakıyordu. Adlı (named) bir fonksiyon + instance
	# değişkeni kullanınca bu sorun ortadan kalkıyor (self-reference yok, Callable hep geçerli).
	_smash_check_sprite = spr
	_smash_check_player = _smash_player
	spr.frame_changed.connect(_on_smash_frame_check)

	await spr.animation_finished
	var fade_tw := create_tween()
	fade_tw.tween_property(self, "modulate:a", 0.0, 0.3)
	await fade_tw.finished
	if is_instance_valid(self): queue_free()

func _on_smash_frame_check() -> void:
	if not is_instance_valid(_smash_check_sprite) or _smash_check_sprite.frame < IMPACT_FRAME:
		return
	if _smash_check_sprite.frame_changed.is_connected(_on_smash_frame_check):
		_smash_check_sprite.frame_changed.disconnect(_on_smash_frame_check)
	if is_instance_valid(_smash_check_player) and _smash_check_player.stream:
		_smash_check_player.play()
	elif is_instance_valid(_smash_check_player):
		_smash_check_player.queue_free()

# ─── Düşüş gölgesi — küçük başlayıp çarpma anına kadar büyüyen elips ──────────
# Kutunun kendisi hareket ederken gölge YERDE (land_pos'ta) sabit kalmalı, bu yüzden
# kutunun child'ı değil, kutuyla aynı parent'a (game_scene) ekleniyor.
func _setup_fall_shadow(land_pos: Vector2) -> void:
	_shadow = Polygon2D.new()
	_shadow.color = Color(0.0, 0.0, 0.0, 0.42)
	_shadow.z_index = -1
	# Sandık izometrik küp → yerdeki izi 45° döndürülmüş kare (eşkenar dörtgen, 2:1). Düşerken küçükten
	# büyür, çarpınca kaybolur. Boyut sprite'ın taban ayak izinden (≈142px × CRATE_SPRITE_SCALE) ölçüldü.
	var hx := 118.0
	var hy := 60.0
	_shadow.polygon = PackedVector2Array([Vector2(0, -hy), Vector2(hx, 0), Vector2(0, hy), Vector2(-hx, 0)])
	_shadow.scale = Vector2(0.15, 0.15)
	_shadow.global_position = land_pos + Vector2(0.0, 80.0)   # taban ayak izinin merkezi
	get_parent().add_child(_shadow)
	tree_exiting.connect(func():
		if is_instance_valid(_shadow): _shadow.queue_free()
	)

func _update_fall_shadow(frame: int) -> void:
	if _shadow == null: return
	if frame >= IMPACT_FRAME:
		# Sandık yere değdiği an gölge yok olur (artık yerde duran bir şey yok, kırılıyor)
		_shadow.queue_free()
		_shadow = null
		return
	var t: float = clamp(float(frame) / float(IMPACT_FRAME), 0.0, 1.0)
	var s: float = lerp(0.15, 1.0, t)
	_shadow.scale = Vector2(s, s)

# Eski procedural (elle _draw ile çizilen) sekans — sprite eksikse fallback.
func _play_intro_fallback(land_pos: Vector2) -> void:
	_use_fallback_draw = true
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
