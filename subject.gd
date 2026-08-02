extends "res://melee_enemy.gd"

var _punching: bool = false

func _ready() -> void:
	speed = 28.0
	health = 15
	max_health = 15
	score_value = 1
	enemy_type = "subject"
	super._ready()

func get_sprite() -> AnimatedSprite2D:
	return $SubjectSprite

func get_walk_anim_prefix() -> String:
	return "walk_"

func _get_died_anim_base() -> String:
	return "res://assets/enemys/subject/animations/died/"

func _get_effective_death_base() -> String:
	return "res://assets/effectiveDeathAnimations/subject/"

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $SubjectSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var base := "res://assets/enemys/subject/sheets/"
	var dirs  := ["N","NE","E","SE","S","SW","W","NW"]
	var anims := [["walk", 6, true], ["punch", 7, false]]
	for a in anims:
		var anim_name: String = str(a[0])
		var frame_count: int  = int(a[1])
		var looping: bool     = bool(a[2])
		for d in dirs:
			var key: String = anim_name + "_" + str(d)
			var tex: Texture2D = load(base + "subject_" + anim_name + "_" + d + ".png")
			frames.add_animation(key)
			frames.set_animation_speed(key, 10.0)
			frames.set_animation_loop(key, looping)
			for i in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas  = tex
				atlas.region = Rect2(i * 60, 0, 60, 60)
				frames.add_frame(key, atlas)
	_add_died_anims(frames)
	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(1.8, 1.8)
	sprite.animation_finished.connect(_on_punch_finished)
	sprite.play("walk_S")

func _on_punch_finished() -> void:
	if is_dead: return
	_punching = false
	_update_walk_anim()

func _update_walk_anim() -> void:
	if _punching: return
	var spr := get_sprite()
	var anim := "walk_" + _anim_dir
	if spr.animation != anim: spr.play(anim)

func play_punch() -> void:
	if _punching: return
	_punching = true
	get_sprite().play("punch_" + _anim_dir)

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
		velocity = (target.global_position - global_position).normalized() * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	_update_anim_dir_from_velocity()
	_update_walk_anim()
	if dist < 60:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			target.take_damage(3 if is_glitched else 5)
			attack_cooldown = attack_rate
			play_punch()
