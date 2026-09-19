extends "res://base_enemy.gd"

var shoot_timer: float = 0.0
var shoot_interval: float = 3.0
var bullet_scene = preload("res://bullet.tscn")

func _elem_indicator_y_offset() -> float:
	return -72.0

func _update_anim(_moving: bool) -> void:
	pass  # child override: walk_ veya idle_ prefix ile anim oynat

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
