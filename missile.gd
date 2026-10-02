extends Area2D

# Cyber-404 füzesi: oyuncuyu TAKİP eder (dönüş hızı sınırlı). Oyuncuya ARM_RADIUS kadar
# yaklaşınca "kurulur": takibi bırakıp düz gider ve ARM_DELAY sn sonra patlar — bu aralıkta
# dash atan oyuncu patlama yarıçapının dışına çıkar, hasar yemez ve füze de patlamış olur.
# Sprite: assets/VFX/homingMissile/ (24 kare, 32×32, burnu AŞAĞI/south bakıyor) — 0-18 uçuş,
# 19-23 patlama. Tek yönlü olduğu için uçuşta hareket yönüne göre döndürülüyor.
const BASE := "res://assets/VFX/homingMissile/"
const EXPLODE_FROM := 19
const SFX_LAUNCH  := "res://assets/sfx/bosses/cyber404/homingMissileLaunch.ogg"
const SFX_EXPLODE := "res://assets/sfx/bosses/cyber404/homingMissileExplosion.ogg"
const ARM_RADIUS := 110.0
const ARM_DELAY  := 0.35

var speed     = 300.0
var turn_rate = 2.2               # rad/sn — küçük = daha kolay kaçılır
var damage    = 3
var lifetime  = 7.0
var blast_radius = 70.0
var target    = null
var direction = Vector2.DOWN

var _age := 0.0
var _armed := false
var _arm_timer := 0.0
var _exploding := false
var _sprite: AnimatedSprite2D
var _launch_player: AudioStreamPlayer

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	z_index = 6
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(1.25, 1.25)
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("fly")
	sf.set_animation_speed("fly", 18.0)
	sf.set_animation_loop("fly", true)
	sf.add_animation("explode")
	sf.set_animation_speed("explode", 18.0)
	sf.set_animation_loop("explode", false)
	var i := 0
	while ResourceLoader.exists(BASE + "frame_%03d.png" % i):
		sf.add_frame("fly" if i < EXPLODE_FROM else "explode", load(BASE + "frame_%03d.png" % i))
		i += 1
	_sprite.sprite_frames = sf
	add_child(_sprite)
	_sprite.play("fly")
	if target != null and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
	_sprite.rotation = direction.angle() - PI / 2.0
	# Fırlatma sesi füzenin child'ı (patlayınca kesilebilsin diye); patlama sesi ise füze
	# silinse de bitsin diye Sfx havuzundan çalıyor (aşağıda _explode).
	if ResourceLoader.exists(SFX_LAUNCH):
		_launch_player = AudioStreamPlayer.new()
		_launch_player.stream = load(SFX_LAUNCH)
		_launch_player.bus = "GameplaySFX" if AudioServer.get_bus_index("GameplaySFX") >= 0 else "Master"
		add_child(_launch_player)
		_launch_player.play()

func _physics_process(delta: float) -> void:
	if _exploding:
		return
	if target == null or not is_instance_valid(target):
		_explode()
		return
	_age += delta
	if _armed:
		_arm_timer -= delta
		if _arm_timer <= 0.0:
			_explode()
			return
	else:
		var desired: Vector2 = (target.global_position - global_position).normalized()
		var step: float = turn_rate * delta
		direction = direction.rotated(clampf(direction.angle_to(desired), -step, step))
		if global_position.distance_to(target.global_position) < ARM_RADIUS:
			_armed = true
			_arm_timer = ARM_DELAY
	global_position += direction * speed * delta
	_sprite.rotation = direction.angle() - PI / 2.0
	if _armed:
		_sprite.modulate = Color(2, 2, 2) if int(_arm_timer * 20.0) % 2 == 0 else Color(1, 1, 1)
	if _age >= lifetime:
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if not _exploding and body.is_in_group("player"):
		_explode()

func _explode() -> void:
	if _exploding:
		return
	_exploding = true
	if is_instance_valid(_launch_player):
		var ftw := create_tween()
		ftw.tween_property(_launch_player, "volume_db", -40.0, 0.15)
		ftw.tween_callback(_launch_player.stop)
	Sfx.play_path(SFX_EXPLODE)
	for body in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(body.global_position) < blast_radius:
			body.take_damage(damage)
	_sprite.modulate = Color(1, 1, 1)
	_sprite.rotation = 0.0
	_sprite.scale = Vector2.ONE * (blast_radius * 2.0 / 32.0)
	_sprite.play("explode")
	await _sprite.animation_finished
	queue_free()
