extends "res://melee_enemy.gd"

var jump_timer: float = 0.0
var jump_interval: float = 2.0
var jump_direction: Vector2 = Vector2.ZERO
var _kicking: bool = false

func _ready() -> void:
	speed = 63.0
	health = 30
	max_health = 30
	score_value = 5
	enemy_type = "armored_subject"
	super._ready()

func get_sprite() -> AnimatedSprite2D:
	return $ArmedSprite

func get_walk_anim_prefix() -> String:
	return "run_"

func _get_died_anim_base() -> String:
	return "res://assets/enemys/armedSubject/animations/died/"

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $ArmedSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var base := "res://assets/enemys/armedSubject/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]
	var anims := [["run", 8, true], ["kick", 6, false]]
	for a in anims:
		var anim_name: String = str(a[0])
		var frame_count: int  = int(a[1])
		var looping: bool     = bool(a[2])
		for d in dirs:
			var key: String = anim_name + "_" + str(d)
			var tex: Texture2D = load(base + "armed_" + anim_name + "_" + str(d) + ".png")
			frames.add_animation(key)
			frames.set_animation_speed(key, 12.0)
			frames.set_animation_loop(key, looping)
			for i in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas  = tex
				atlas.region = Rect2(i * 128, 0, 128, 128)
				frames.add_frame(key, atlas)
	_add_died_anims(frames)
	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.85, 0.85)
	sprite.animation_finished.connect(_on_kick_finished)
	sprite.play("run_S")

func _on_kick_finished() -> void:
	if is_dead: return
	_kicking = false
	$ArmedSprite.speed_scale = 1.0
	_update_walk_anim()

func _update_walk_anim() -> void:
	if _kicking: return
	var spr := get_sprite()
	var anim := "run_" + _anim_dir
	if spr.animation != anim: spr.play(anim)

func play_kick() -> void:
	if _kicking: return
	_kicking = true
	get_sprite().play("kick_" + _anim_dir)

func _enemy_process(delta: float) -> void:
	var target
	if is_glitched:
		var subjects = get_tree().get_nodes_in_group("subjects")
		var closest = null
		var closest_dist = 999999.0
		for z in subjects:
			if z == self: continue
			var d = global_position.distance_to(z.global_position)
			if d < closest_dist:
				closest_dist = d
				closest = z
		target = closest
	else:
		target = get_tree().get_first_node_in_group("player")
	if target == null: return
	var dist = global_position.distance_to(target.global_position)
	if dist > 60:
		var direction = (target.global_position - global_position).normalized()
		var sprite: AnimatedSprite2D = $ArmedSprite
		var current_speed = speed * 2.5 if sprite.frame < 4 else speed
		velocity = direction * current_speed
		move_and_slide()
		_update_anim_dir_from_velocity()
		_update_walk_anim()
		sprite.speed_scale = 1.0
	else:
		velocity = Vector2.ZERO
		$ArmedSprite.speed_scale = 1.0
		_update_walk_anim()
	if dist < 60:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			target.take_damage(3 if is_glitched else 6)
			attack_cooldown = attack_rate
			play_kick()
