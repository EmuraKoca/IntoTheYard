extends Node2D
# Nyx-09 "Triple Shockwave": elden çıkan, küçük başlayıp büyüyen, oyuncuyu YAVAŞ takip eden şok dalgası.
# Cyber-404 füzesi gibi: oyuncuya LOCK_RADIUS kadar yaklaşınca takibi bırakıp düz gider, ARM_DELAY sn sonra PATLAR
# (blast_radius içindeki oyuncuya hasar; dash ile atlatılır). Temas, duvar ve ömür sonu da patlatır.

const FRAMES_PATH := "res://assets/enemys/Nyx_09 The Quantum Widow/animations/tripleShockWave/guidedShock Wave/frame_%03d.png"
const FRAME_COUNT := 20
const FLY_FRAMES := [0, 11, 13, 14, 19, 18]   # sakin küre kareleri (uçuş döngüsü); patlama karelerin tamamı
const FLY_FPS := 12.0
const EXPLODE_FPS := 36.0       # 20 kare ≈ 0.55sn
const SPEED := 260.0
const TURN_RATE := 1.2          # rad/sn (Cyber-404 füzesi 2.2; dash ile atlatılabilsin diye düşük)
const LIFETIME := 3.5
const LOCK_RADIUS := 170.0      # bu kadar yaklaşınca takip biter, düz gider
const ARM_DELAY := 0.35         # takip bittikten bu kadar sonra patlar
const DAMAGE := 15
const R_START := 20.0           # uçuşta temas yarıçapı başlangıç → bitiş
const R_END := 55.0
const BLAST_RADIUS := 80.0      # patlama hasar yarıçapı
const VISUAL_RADIUS := 50.0     # karelerin ortalama görünür yarıçapı (ölçek = yarıçap / bu)
const BOUNDS := Rect2(360.0, 240.0, 1270.0, 840.0)
const SFX_LAUNCH := "res://assets/sfx/bosses/nyx-09/electricCharge.ogg"   # ilk ~2.7sn sessiz → atla
const SFX_LAUNCH_SKIP := 2.7
const SFX_EXPLODE := "res://assets/sfx/bosses/nyx-09/guidedShockWaveExplotion.ogg"

static var _frames: SpriteFrames = null

var dir := Vector2.RIGHT
var _age := 0.0
var _locked := false
var _arm_t := 0.0
var _exploded := false
var _spr: AnimatedSprite2D
var _snd: AudioStreamPlayer = null

static func _get_frames() -> SpriteFrames:
	if _frames == null:
		var sf := SpriteFrames.new()
		if sf.has_animation("default"):
			sf.remove_animation("default")
		sf.add_animation("fly")
		sf.set_animation_speed("fly", FLY_FPS)
		sf.set_animation_loop("fly", true)
		for i in FLY_FRAMES:
			sf.add_frame("fly", load(FRAMES_PATH % i))
		sf.add_animation("explode")
		sf.set_animation_speed("explode", EXPLODE_FPS)
		sf.set_animation_loop("explode", false)
		for i in FRAME_COUNT:
			sf.add_frame("explode", load(FRAMES_PATH % i))
		_frames = sf
	return _frames

func _ready() -> void:
	add_to_group("nyx_waves")
	z_index = 4
	_spr = AnimatedSprite2D.new()
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spr.sprite_frames = _get_frames()
	add_child(_spr)
	_spr.play("fly")
	_apply_size()
	# Ateş edildiği andan itibaren şarj sesi (patlayınca / silinince kısılır)
	_snd = Sfx.play_path_dedicated(SFX_LAUNCH, 0.0, 1.0, SFX_LAUNCH_SKIP)

func _radius() -> float:
	return lerpf(R_START, R_END, clampf(_age / LIFETIME, 0.0, 1.0))

func _apply_size() -> void:
	var s := _radius() / VISUAL_RADIUS
	_spr.scale = Vector2(s, s)

func _physics_process(delta: float) -> void:
	if _exploded:
		return
	_age += delta
	if _age >= LIFETIME:
		_explode()
		return
	var pl := get_tree().get_first_node_in_group("player")
	if is_instance_valid(pl) and not _locked and pl.global_position.distance_to(global_position) < LOCK_RADIUS:
		_locked = true
		_arm_t = ARM_DELAY
	if _locked:
		_arm_t -= delta
		if _arm_t <= 0.0:
			_explode()
			return
	elif is_instance_valid(pl):
		var want: float = (pl.global_position - global_position).angle()
		var diff: float = angle_difference(dir.angle(), want)
		dir = dir.rotated(clampf(diff, -TURN_RATE * delta, TURN_RATE * delta))
	global_position += dir * SPEED * delta
	_apply_size()
	if not BOUNDS.has_point(global_position):
		_explode()
		return
	if is_instance_valid(pl) and not pl.is_dashing and pl.global_position.distance_to(global_position) < _radius():
		_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var pl := get_tree().get_first_node_in_group("player")
	if is_instance_valid(pl) and not pl.is_dashing and pl.global_position.distance_to(global_position) < BLAST_RADIUS:
		pl.take_damage(DAMAGE)
	# Şarj sesi kısılır, patlama sesi çalar
	if is_instance_valid(_snd):
		var tw := _snd.create_tween()
		tw.tween_property(_snd, "volume_db", -40.0, 0.2)
		tw.tween_callback(_snd.stop)
	Sfx.play_path_dedicated(SFX_EXPLODE)
	var s := BLAST_RADIUS / VISUAL_RADIUS
	_spr.scale = Vector2(s, s)
	_spr.play("explode")
	_spr.animation_finished.connect(queue_free)

func _exit_tree() -> void:
	if is_instance_valid(_snd):
		_snd.stop()
