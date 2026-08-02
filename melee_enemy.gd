extends "res://base_enemy.gd"

func take_damage(amount, from_ally: bool = false, kill_cause: String = "normal") -> void:
	health -= amount
	if is_electrified and not from_ally:
		var p := _get_player()
		if p and p.get("has_static_charge") and p.has_static_charge:
			for body in get_tree().get_nodes_in_group("subjects"):
				if body != self and is_instance_valid(body) and body.get("is_electrified") and body.is_electrified:
					if global_position.distance_to(body.global_position) < 150.0:
						body.health -= int(amount * 0.4)
						if body.health <= 0: body.die("electric")
	if health <= 0:
		die()
