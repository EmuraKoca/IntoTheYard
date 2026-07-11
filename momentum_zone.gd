extends Node2D

# ── Ayarlar ───────────────────────────────────────────────────────────────────
const POLE_WIDTH   : float = 6.0
const POLE_HEIGHT  : float = 70.0
const ZONE_WIDTH   : float = 90.0   # iki direk arası mesafe
const WAVE_POINTS  : int   = 24     # dalgadaki nokta sayısı
const WAVE_AMP     : float = 10.0   # dalga yüksekliği
const WAVE_FREQ    : float = 3.5    # dalga frekansı (rad/unit)
const WAVE_SPEED   : float = 4.0    # animasyon hızı
const RISE_DURATION: float = 0.9    # direklerin çıkma süresi
const ACTIVE_TIME  : float = 20.0   # aktif kalma süresi
const SINK_DURATION: float = 0.9    # direklerin inme süresi

const PASSES_PER_STACK: int = 5     # kaç geçişte 1 momentum stack

const COLOR_POLE  : Color = Color(0.2, 0.7, 1.0, 0.9)
const COLOR_WAVE  : Color = Color(0.1, 0.6, 1.0, 0.85)
const COLOR_GLOW  : Color = Color(0.3, 0.8, 1.0, 0.25)

# ── State ─────────────────────────────────────────────────────────────────────
enum State { HIDDEN, RISING, ACTIVE, SINKING }
var _state       : State = State.HIDDEN
var _timer       : float = 0.0
var _wave_t      : float = 0.0       # dalga animasyon zamanı
var _pole_ratio  : float = 0.0       # 0=yerde 1=tam çıkmış
var _pass_count  : int   = 0         # bu zone'dan geçen core sayısı
var _active_timer: float = 0.0

# ── Area2D (geçiş tespiti) ────────────────────────────────────────────────────
var _area        : Area2D
var _shape       : CollisionShape2D

func _ready() -> void:
	z_index = 3
	_build_area()

func _build_area() -> void:
	_area = Area2D.new()
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(ZONE_WIDTH - POLE_WIDTH * 2, POLE_HEIGHT * 0.8)
	_shape.shape = rect
	_shape.disabled = true
	_area.add_child(_shape)
	_area.position = Vector2(ZONE_WIDTH * 0.5, -POLE_HEIGHT * 0.5)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)

func activate() -> void:
	_state       = State.RISING
	_timer       = 0.0
	_pole_ratio  = 0.0
	_pass_count  = 0
	_active_timer = 0.0
	_shape.disabled = true
	queue_redraw()

func _physics_process(delta: float) -> void:
	match _state:
		State.RISING:
			_timer += delta
			_pole_ratio = clamp(_timer / RISE_DURATION, 0.0, 1.0)
			_pole_ratio = _ease_out(_pole_ratio)
			if _timer >= RISE_DURATION:
				_state = State.ACTIVE
				_pole_ratio = 1.0
				_shape.disabled = false
			queue_redraw()

		State.ACTIVE:
			_wave_t += delta * WAVE_SPEED
			_active_timer += delta
			if _active_timer >= ACTIVE_TIME:
				_state = State.SINKING
				_timer = 0.0
				_shape.disabled = true
			queue_redraw()

		State.SINKING:
			_timer += delta
			_pole_ratio = clamp(1.0 - _timer / SINK_DURATION, 0.0, 1.0)
			_pole_ratio = _ease_in(_pole_ratio)
			if _timer >= SINK_DURATION:
				_state = State.HIDDEN
				_pole_ratio = 0.0
				emit_signal("zone_finished")
			queue_redraw()

signal zone_finished

func _draw() -> void:
	if _pole_ratio <= 0.0:
		return

	var visible_h : float = POLE_HEIGHT * _pole_ratio
	var pole_top  : float = -visible_h

	# ── Sol direk ────────────────────────────────────────────────────────────
	_draw_pole(Vector2(0, 0), visible_h)
	# ── Sağ direk ────────────────────────────────────────────────────────────
	_draw_pole(Vector2(ZONE_WIDTH, 0), visible_h)

	# ── Dalgalı hat (sadece tam çıkmışsa) ────────────────────────────────────
	if _state == State.ACTIVE:
		_draw_wave(pole_top)

func _draw_pole(base: Vector2, h: float) -> void:
	# Glow
	draw_rect(Rect2(base.x - POLE_WIDTH, -h, POLE_WIDTH * 2, h), COLOR_GLOW)
	# Ana direk
	draw_rect(Rect2(base.x - POLE_WIDTH * 0.5, -h, POLE_WIDTH, h), COLOR_POLE)
	# Üst top
	draw_circle(Vector2(base.x, -h), POLE_WIDTH * 0.9, COLOR_POLE)

func _draw_wave(y_top: float) -> void:
	var points : PackedVector2Array = []
	for i in range(WAVE_POINTS + 1):
		var t     : float = float(i) / float(WAVE_POINTS)
		var x     : float = t * ZONE_WIDTH
		var noise : float = sin(_wave_t * 1.3 + i * 0.7) * 2.5   # küçük titreme
		var y     : float = y_top * 0.5 + sin(t * WAVE_FREQ * TAU + _wave_t) * WAVE_AMP + noise
		points.append(Vector2(x, y))

	# Glow (kalın, şeffaf)
	draw_polyline(points, Color(COLOR_GLOW.r, COLOR_GLOW.g, COLOR_GLOW.b, 0.3), 6.0, true)
	# Ana hat
	draw_polyline(points, COLOR_WAVE, 2.0, true)
	# İç parlak hat
	draw_polyline(points, Color(0.7, 0.95, 1.0, 0.6), 1.0, true)

func _on_body_entered(body: Node) -> void:
	if _state != State.ACTIVE: return
	if not body.is_in_group("player_balls"): return
	var player := _get_player()
	if player == null or player.character_type != "vector": return
	if not player.has_momentum_engine: return
	_pass_count += 1
	_flash()
	if _pass_count >= PASSES_PER_STACK:
		_pass_count = 0
		player.momentum_stacks = min(player.momentum_stacks + 1, player.momentum_max)

func _flash() -> void:
	var tween := create_tween()
	tween.tween_method(func(v: float): modulate.a = v, 1.5, 1.0, 0.15)

func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 2.5)

func _ease_in(t: float) -> float:
	return pow(t, 2.5)
