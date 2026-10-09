extends "res://base_enemy.gd"

var shoot_timer: float = 0.0
var shoot_interval: float = 3.0
var bullet_scene = preload("res://bullet.tscn")

func _elem_indicator_y_offset() -> float:
	return -72.0

func _update_anim(_moving: bool) -> void:
	pass  # child override: walk_ veya idle_ prefix ile anim oynat

# Ates animasyonu: attack_<yon> oynar, mermi FIRE_FRAME karesinde cikar (_fire alt sinifta)
const ATTACK_FPS: float = 12.0
const FIRE_FRAME: int = 4
var _attacking: bool = false

# Menzile gelene kadar yaklaşır; menzildeyken yaklaşmaz, sadece yatay eksende
# oyuncunun X'ine hizalanır. Menzilden ancak HOLD_MARGIN kadar uzaklaşılırsa
# tekrar yaklaşır (histerezis → oyuncu kıpırdadıkça sürekli yaklaşmaz).
const HOLD_MARGIN: float = 450.0
const STRAFE_FACTOR: float = 0.7
const STRAFE_DEADZONE: float = 30.0
var _in_position: bool = false

func _ranged_move(player: Node2D, range_px: float) -> bool:
	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()
	if _in_position:
		if dist > range_px + HOLD_MARGIN:
			_in_position = false
	elif dist <= range_px:
		_in_position = true
	if not _in_position:
		velocity = to_player.normalized() * speed
		_update_anim_dir(velocity)
		return true
	var dx: float = to_player.x
	if _attacking or absf(dx) < STRAFE_DEADZONE:
		velocity = Vector2.ZERO
		_update_anim_dir(to_player.normalized())
		return false
	velocity = Vector2(signf(dx) * speed * STRAFE_FACTOR, 0.0)
	_update_anim_dir(velocity)
	return true

func _fire(_target: Node2D) -> void:
	pass

func _shoot(target: Node2D) -> void:
	if _attacking or is_dead: return
	_attacking = true
	var spr := get_sprite()
	_update_anim_dir((target.global_position - global_position).normalized())
	var key := "attack_" + _anim_dir
	var has_anim: bool = spr != null and spr.sprite_frames != null and spr.sprite_frames.has_animation(key)
	if has_anim:
		spr.play(key)
	await get_tree().create_timer(float(FIRE_FRAME) / ATTACK_FPS, false).timeout
	if not is_instance_valid(self) or is_dead:
		return
	if is_instance_valid(target) and not is_glitched:
		_fire(target)
	if has_anim and spr.animation == key and spr.is_playing():
		await spr.animation_finished
	if not is_instance_valid(self) or is_dead:
		return
	_attacking = false

# Glitchli silahlı düşman: mermi atmaz, en yakın düşmana yürüyüp yakın dövüş hasarı verir
var _glitch_atk_cd: float = 0.0

func _glitch_melee(delta: float) -> void:
	var closest = null
	var closest_dist := 999999.0
	for z in get_tree().get_nodes_in_group("subjects"):
		if z == self or not is_instance_valid(z) or z.get("is_dead"): continue
		var d := global_position.distance_to(z.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = z
	_glitch_atk_cd -= delta
	if closest == null:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_anim(false)
		return
	var dir: Vector2 = (closest.global_position - global_position).normalized()
	if closest_dist > 40.0:
		velocity = dir * speed
		_update_anim_dir(velocity)
		move_and_slide()
		_update_anim(true)
		return
	velocity = Vector2.ZERO
	_update_anim_dir(dir)
	_update_anim(false)
	if _glitch_atk_cd <= 0.0:
		_glitch_atk_cd = 1.0
		closest.take_damage(3, false, "normal", true)
		# Saldırı animasyonu yok: hedefe doğru kısa bir atılma
		var spr := get_sprite()
		if spr:
			var base_pos := spr.position
			var tw := create_tween()
			tw.tween_property(spr, "position", base_pos + dir * 8.0, 0.05)
			tw.tween_property(spr, "position", base_pos, 0.05)
