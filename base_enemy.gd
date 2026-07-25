extends CharacterBody2D

static var _freeze_sf: SpriteFrames = null

const SURGERY_EXIT := Vector2(850, 1000)

var speed: float = 28.0
var health: int = 15
var max_health: int = 15
var is_dead: bool = false
var original_speed: float = 0.0
var is_slowed: bool = false
var is_glitched: bool = false
var is_antivirused: bool = false
var is_marked: bool = false
var antivirus_stacks: int = 0
var _antivirus_duration: float = 0.0
var _antivirus_tick: float = 0.0
var is_wet: bool = false
var is_frozen: bool = false
var is_burning: bool = false
var is_electrified: bool = false
var is_stunned: bool = false
var _stun_timer: float = 0.0
var decay_stacks: int = 0
var _decay_slow_applied: float = 0.0
var _chip_t: float = 0.0
var _chip_node: Node2D = null
var attack_cooldown: float = 0.0
var attack_rate: float = 1.0
var chip_duration: float = 15.0
var _elem_indicator = null
var _anim_dir: String = "S"
var _freeze_sprite: AnimatedSprite2D = null
var _reactions_cancelled: bool = false
var _last_reaction_type: String = ""  # Primal Instinct / Void Resonance takibi
var _cryo_sprite: AnimatedSprite2D = null
var _melt_frozen_sprite: AnimatedSprite2D = null
var _electrocute_sprite: AnimatedSprite2D = null
var _had_reaction: bool = false
var score_value: int = 1

# ── Virtual fonksiyonlar ─────────────────────────────────────────────────────

func get_sprite() -> AnimatedSprite2D:
	return null

func get_walk_anim_prefix() -> String:
	return "walk_"

func _elem_indicator_y_offset() -> float:
	return -68.0

func _setup_sprite() -> void:
	pass

func _enemy_process(_delta: float) -> void:
	pass

func _update_walk_anim() -> void:
	pass

func _on_became_ally() -> void:
	pass

func _on_lethal_damage(_from_ally: bool) -> void:
	pass

# ── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	z_index = 2
	_setup_sprite()
	_setup_element_indicator(_elem_indicator_y_offset())
	_chip_node = Node2D.new()
	_chip_node.z_as_relative = false
	_chip_node.z_index = 10
	add_child(_chip_node)
	_chip_node.draw.connect(_draw_chip)

# ── Physics ──────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if is_in_group("allies"):
		_ally_behavior()
		return
	if not is_dead:
		_chip_t += delta
		_chip_node.queue_redraw()
	if is_frozen or is_stunned:
		if is_stunned:
			_stun_timer -= delta
			if _stun_timer <= 0.0:
				is_stunned = false
		return
	_process_antivirus(delta)
	_enemy_process(delta)

func _ally_behavior() -> void:
	pass

# ── Helpers ──────────────────────────────────────────────────────────────────

func _get_player() -> Node:
	var game := get_node_or_null("/root/GameScene")
	return game.get_node_or_null("Player") if game else null

func _had_any_element() -> bool:
	return is_burning or is_wet or is_electrified or is_slowed or is_frozen

func _update_anim_dir(vel: Vector2) -> void:
	if vel == Vector2.ZERO:
		return
	var deg := rad_to_deg(vel.angle())
	if   deg > -22.5  and deg <= 22.5:   _anim_dir = "E"
	elif deg > 22.5   and deg <= 67.5:   _anim_dir = "SE"
	elif deg > 67.5   and deg <= 112.5:  _anim_dir = "S"
	elif deg > 112.5  and deg <= 157.5:  _anim_dir = "SW"
	elif deg > 157.5  or  deg <= -157.5: _anim_dir = "W"
	elif deg > -157.5 and deg <= -112.5: _anim_dir = "NW"
	elif deg > -112.5 and deg <= -67.5:  _anim_dir = "N"
	elif deg > -67.5  and deg <= -22.5:  _anim_dir = "NE"

func _update_anim_dir_from_velocity() -> void:
	_update_anim_dir(velocity)

# ── Hasar & Ölüm ─────────────────────────────────────────────────────────────

func take_damage(amount, from_ally: bool = false) -> void:
	if get("is_marked") and is_marked:
		amount = int(amount * 1.1)
	# Primal Instinct: 3 farklı reaksiyon tetiklendiyse +10% hasar (5s)
	var _pi_player := _get_player()
	if _pi_player and _pi_player.get("has_primal_instinct") and _pi_player.has_primal_instinct and _pi_player._primal_instinct_timer > 0.0:
		amount = int(amount * 1.1)
	# Cryo Burst: Yavaşlatılmış düşmana +8 bonus hasar (1 kez / vuruş)
	if not from_ally and _pi_player and _pi_player.get("has_cryo_burst") and _pi_player.has_cryo_burst:
		if get("is_slowed") and is_slowed:
			amount += 8
	health -= amount
	if is_electrified and not from_ally:
		var p := _get_player()
		if p and p.get("has_static_charge") and p.has_static_charge:
			for body in get_tree().get_nodes_in_group("subjects"):
				if body != self and is_instance_valid(body) and body.get("is_electrified") and body.is_electrified:
					if global_position.distance_to(body.global_position) < 150.0:
						body.health -= int(amount * 0.4)
						if body.health <= 0: body.die()
	if health <= 0:
		_on_lethal_damage(from_ally)
		die()

func die() -> void:
	# Virus Beacon Core: Antivirus'lü düşman ölürse 3s boyunca yakına stack yay
	if is_antivirused and antivirus_stacks > 0:
		for ball in get_tree().get_nodes_in_group("player_balls"):
			if not is_instance_valid(ball): continue
			if ball.get("is_inner_core") and ball.is_inner_core and ball.get("inner_core_type") and ball.inner_core_type == "virus_beacon_core":
				if ball.global_position.distance_to(global_position) <= 80.0:
					var _vb_ref := ball
					for _vb_tick in range(3):
						await get_tree().create_timer(_vb_tick * 1.0).timeout
						if not is_instance_valid(_vb_ref): break
						for s in _vb_ref.get_tree().get_nodes_in_group("subjects"):
							if not is_instance_valid(s): continue
							if _vb_ref.global_position.distance_to(s.global_position) <= 100.0:
								if s.has_method("apply_antivirus"):
									s.apply_antivirus(1)
				break
	_on_decay_death()
	# Leech Nova Core: öldürünce +2 HP + 80px Glitch
	var _lnc_player := _get_player()
	if _lnc_player and _lnc_player.get("has_leech_nova_core") and _lnc_player.has_leech_nova_core:
		var _lnc_game := get_node_or_null("/root/GameScene")
		if _lnc_game and _lnc_game.has_method("heal_player"): _lnc_game.heal_player(2)
		for s in get_tree().get_nodes_in_group("subjects"):
			if not is_instance_valid(s): continue
			if global_position.distance_to(s.global_position) <= 80.0:
				if s.get("apply_glitch"): s.apply_glitch()
	is_dead = true
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var game = get_parent()
	if game.has_method("subject_died"):
		game.subject_died(score_value, global_position)
	var spr := get_sprite()
	if spr: spr.play(get_walk_anim_prefix() + _anim_dir)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.4)
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(self): queue_free()

# ── Element sistemi ──────────────────────────────────────────────────────────

func apply_burn() -> void:
	if is_burning:
		return
	_check_reaction("fire")
	if not is_instance_valid(self): return
	is_burning = true
	_set_element("burn")
	var p := _get_player()
	var tick_dmg: int = 2
	if p and p.get("burn_damage_mult"):
		tick_dmg = max(1, int(2.0 * p.burn_damage_mult))
	var burn_ticks := 3
	if p and p.get("has_elemental_memory") and p.has_elemental_memory and _had_reaction:
		burn_ticks = 6
		_had_reaction = false
	for i in range(burn_ticks):
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self) and health > 0:
			health -= tick_dmg
			if p and p.get("has_overheat") and p.has_overheat:
				if not p.get("_overheat_counter"):
					p.set("_overheat_counter", 0)
				p._overheat_counter += 1
				if p._overheat_counter >= 13:
					p._overheat_counter = 0
					_react_overheat()
			if health <= 0:
				die()
	if not is_instance_valid(self):
		return
	is_burning = false
	_clear_element()

func _react_overheat() -> void:
	_spawn_overheat_vfx()
	var p := _get_player()
	var _oh_radius := 150.0
	if p and p.get("has_pyroblast") and p.has_pyroblast:
		_oh_radius = 150.0 + float(p.get("_overheat_counter") if p.get("_overheat_counter") != null else 0) * 8.0
	for body in get_tree().get_nodes_in_group("subjects"):
		if is_instance_valid(body) and global_position.distance_to(body.global_position) < _oh_radius:
			body.health -= 15
			body._react_flash(Color(1.0, 0.3, 0.0))
			if body.health <= 0: body.die()

func apply_frozen() -> void:
	if is_frozen:
		return
	is_frozen = true
	is_wet = false
	_set_element("frozen")
	var spr := get_sprite()
	if spr: spr.stop()
	_spawn_freeze_vfx()
	var p := _get_player()
	var dur := 3.0
	if p and p.get("freeze_duration_mult"):
		dur *= p.freeze_duration_mult
	await get_tree().create_timer(dur).timeout
	if not is_instance_valid(self):
		return
	if is_instance_valid(_freeze_sprite):
		_freeze_sprite.play("freeze")
		await _freeze_sprite.animation_finished
	if is_instance_valid(_freeze_sprite):
		_freeze_sprite.queue_free()
		_freeze_sprite = null
	is_frozen = false
	var spr2 := get_sprite()
	if spr2 and is_instance_valid(spr2): spr2.play(get_walk_anim_prefix() + _anim_dir)
	_clear_element()

func apply_wet() -> void:
	_check_reaction("wet")
	if not is_instance_valid(self): return
	is_wet = true
	_set_element("wet")
	var p := _get_player()
	var dur := 5.0
	if p and p.get("has_elemental_memory") and p.has_elemental_memory and _had_reaction:
		dur *= 2.0
		_had_reaction = false
	if p and p.get("first_debuff_duration_mult") and not _had_any_element():
		dur *= p.first_debuff_duration_mult
	await get_tree().create_timer(dur).timeout
	if not is_instance_valid(self):
		return
	is_wet = false
	_clear_element()

func apply_antivirus(stacks: int = 1) -> void:
	var _ap := get_tree().get_first_node_in_group("player")
	var _cap: int = 5 if (_ap and _ap.get("has_stack_overflow") and _ap.has_stack_overflow) else 3
	antivirus_stacks = min(antivirus_stacks + stacks, _cap)
	var _dur: float = 8.0 if (_ap and _ap.get("has_memory_leak") and _ap.has_memory_leak) else 5.0
	_antivirus_duration = max(_antivirus_duration, _dur)
	_antivirus_tick = min(_antivirus_tick if _antivirus_tick > 0 else 0.5, 0.5)
	is_antivirused = true

func _process_antivirus(delta: float) -> void:
	if not is_antivirused:
		return
	_antivirus_tick -= delta
	_antivirus_duration -= delta
	if _antivirus_tick <= 0.0:
		_antivirus_tick = 0.5
		health -= antivirus_stacks
		var _ap2 := get_tree().get_first_node_in_group("player")
		if _ap2 and _ap2.get("has_root_access") and _ap2.has_root_access:
			var _cap2: int = 5 if (_ap2.get("has_stack_overflow") and _ap2.has_stack_overflow) else 3
			if antivirus_stacks >= _cap2:
				health -= 5
		if _ap2 and _ap2.get("has_kernel_panic") and _ap2.has_kernel_panic:
			if randf() < 0.05 and not is_glitched:
				apply_glitch()
		if health <= 0: die()
	if _antivirus_duration <= 0.0:
		is_antivirused = false
		antivirus_stacks = 0

func apply_glitch(duration: float = 3.0) -> void:
	if is_glitched:
		return
	var _gp := get_tree().get_first_node_in_group("player")
	var _dur := duration
	if _gp and _gp.get("has_extended_glitch") and _gp.has_extended_glitch:
		_dur = max(_dur, 5.0)
	is_glitched = true
	_set_element("glitch")
	await get_tree().create_timer(_dur).timeout
	if not is_instance_valid(self):
		return
	is_glitched = false
	_clear_element()

func apply_electrified() -> void:
	if is_electrified:
		return
	_check_reaction("electric")
	if not is_instance_valid(self): return
	is_electrified = true
	_set_element("electrified")
	var p := _get_player()
	var dur := 5.0
	if p and p.get("has_elemental_memory") and p.has_elemental_memory and _had_reaction:
		dur *= 2.0
		_had_reaction = false
	if p and p.get("first_debuff_duration_mult") and not _had_any_element():
		dur *= p.first_debuff_duration_mult
	var _ls_p := _get_player()
	if _ls_p and _ls_p.get("has_living_storm") and _ls_p.has_living_storm:
		_living_storm_loop()
	await get_tree().create_timer(dur).timeout
	if is_instance_valid(self):
		is_electrified = false
		_clear_element()

func _living_storm_loop() -> void:
	while is_instance_valid(self) and is_electrified:
		await get_tree().create_timer(1.5).timeout
		if not is_instance_valid(self) or not is_electrified: break
		var _target := get_tree().get_first_node_in_group("player")
		if _target and global_position.distance_to(_target.global_position) < 120.0:
			health -= 3
			_react_flash(Color(0.2, 0.5, 4.0))
			if health <= 0: die(); break

func apply_slow(amount, duration: float = 3.0, source: String = "cryo", anchor_pos: Vector2 = Vector2.ZERO) -> void:
	if is_slowed:
		return
	_check_reaction("cryo")
	if not is_instance_valid(self): return
	is_slowed = true
	original_speed = speed
	var p := _get_player()
	var slow_amount: float = float(amount)
	if p and p.get("cryo_slow_mult"):
		slow_amount = min(amount * p.cryo_slow_mult, 0.9)
	speed = speed * (1.0 - slow_amount)
	_set_element("slow")
	if source != "anchor":
		_spawn_cryo_vfx()
	var dur := duration
	if p and p.get("has_elemental_memory") and p.has_elemental_memory and _had_reaction:
		dur *= 2.0
		_had_reaction = false
	if p and p.get("first_debuff_duration_mult") and not _had_any_element():
		dur *= p.first_debuff_duration_mult
	# Static Link: Glitch'li hedef ise slow süresi 2× uzar
	if p and p.get("has_static_link") and p.has_static_link:
		if get("is_glitched") and is_glitched:
			dur *= 2.0
	await get_tree().create_timer(dur).timeout
	if not is_instance_valid(self):
		return
	if is_instance_valid(_cryo_sprite):
		_cryo_sprite.queue_free()
		_cryo_sprite = null
	speed = original_speed
	is_slowed = false
	_clear_element()

# ── Reaksiyon sistemi ────────────────────────────────────────────────────────

func apply_stun(duration: float = 1.0) -> void:
	if is_dead: return
	is_stunned = true
	_stun_timer = maxf(_stun_timer, duration)

func apply_decay() -> void:
	if is_dead: return
	var _max_stacks: int = 3
	if decay_stacks >= _max_stacks: return
	decay_stacks += 1
	var _slow_per_stack: float = 0.05
	var _new_slow: float = decay_stacks * _slow_per_stack
	var _delta_slow: float = _new_slow - _decay_slow_applied
	_decay_slow_applied = _new_slow
	if original_speed == 0.0:
		original_speed = speed
	speed = maxf(speed * (1.0 - _delta_slow), original_speed * 0.1)
	# Spike Core: 3. stack'e ulaşınca anında patlama tetikle
	if decay_stacks >= _max_stacks:
		var _sp := _get_player()
		if _sp and _sp.get("has_spike_core") and _sp.has_spike_core:
			_on_decay_death()
			decay_stacks = 0
			_decay_slow_applied = 0.0

func _on_decay_death() -> void:
	if decay_stacks <= 0: return
	var _p := _get_player()
	var _dmg_per_stack: int = 3 if (_p and _p.get("has_decay_amp") and _p.has_decay_amp) else 2
	var _dmg: int = decay_stacks * _dmg_per_stack
	for body in get_tree().get_nodes_in_group("subjects"):
		if body == self or not is_instance_valid(body): continue
		if global_position.distance_to(body.global_position) < 80.0:
			body.take_damage(_dmg)
	# Decay Harvest: patlama → +2 HP
	if _p and _p.get("has_decay_harvest") and _p.has_decay_harvest:
		var _g := get_node_or_null("/root/GameScene")
		if _g and _g.has_method("heal_player"): _g.heal_player(2)

func _check_reaction(incoming: String) -> void:
	var game := get_node_or_null("/root/GameScene")
	var player := game.get_node_or_null("Player") if game else null
	var dmg_mult: float = 1.0

	if player and player.get("has_volatile_mixture") and player.has_volatile_mixture:
		var active := 0
		if is_burning:     active += 1
		if is_wet:         active += 1
		if is_electrified: active += 1
		if is_slowed:      active += 1
		if active >= 2:
			if is_wet and is_electrified:
				is_wet = false; is_electrified = false
				_react_electrocute(dmg_mult, game, player); return
			elif is_wet and is_slowed:
				is_wet = false; is_slowed = false
				speed = original_speed if original_speed > 0 else speed
				apply_frozen(); _react_flash(Color(0.5, 0.9, 1.0))
				_notify_reaction(game, player); return
			elif is_burning and is_wet:
				is_wet = false; is_burning = false
				_react_steam(dmg_mult, game, player); return
			elif is_burning and is_slowed:
				is_burning = false; is_slowed = false
				speed = original_speed if original_speed > 0 else speed
				_react_melt(dmg_mult); return

	if player and player.get("has_chain_catalyst") and player.has_chain_catalyst:
		var active := 0
		if is_burning:    active += 1
		if is_wet:        active += 1
		if is_electrified: active += 1
		if is_slowed:     active += 1
		if active >= 2:
			dmg_mult = 1.3

	if incoming == "electric" and is_wet:
		is_wet = false; is_electrified = false
		_react_electrocute(dmg_mult, game, player); return
	if incoming == "wet" and is_electrified:
		is_wet = false; is_electrified = false
		_react_electrocute(dmg_mult, game, player); return

	if incoming == "cryo" and is_wet:
		is_wet = false; is_slowed = false
		apply_frozen(); _react_flash(Color(0.5, 0.9, 1.0))
		_notify_reaction(game, player); return
	if incoming == "wet" and is_slowed:
		is_wet = false; is_slowed = false
		speed = original_speed if original_speed > 0 else speed
		apply_frozen(); _react_flash(Color(0.5, 0.9, 1.0))
		_notify_reaction(game, player); return

	if incoming == "fire" and is_frozen:
		_react_melt_frozen(dmg_mult, game, player); return

	if incoming == "electric" and is_frozen:
		is_frozen = false; is_electrified = false
		_react_shatter(dmg_mult, game, player); return
	if incoming == "cryo" and is_electrified and is_frozen:
		is_frozen = false; is_electrified = false
		_react_shatter(dmg_mult, game, player); return

	if incoming == "electric" and is_slowed and not is_frozen:
		is_slowed = false; is_electrified = false
		speed = original_speed if original_speed > 0 else speed
		_react_cryostatic(dmg_mult, game, player); return
	if incoming == "cryo" and is_electrified and not is_frozen:
		is_slowed = false; is_electrified = false
		speed = original_speed if original_speed > 0 else speed
		_react_cryostatic(dmg_mult, game, player); return

	if incoming == "wet" and is_burning:
		is_wet = false; is_burning = false
		_react_steam(dmg_mult, game, player); return
	if incoming == "fire" and is_wet:
		is_wet = false; is_burning = false
		_react_steam(dmg_mult, game, player); return

	if incoming == "fire" and is_slowed:
		is_burning = false; is_slowed = false
		speed = original_speed if original_speed > 0 else speed
		_react_melt(dmg_mult); return
	if incoming == "cryo" and is_burning:
		is_burning = false; is_slowed = false
		speed = original_speed if original_speed > 0 else speed
		_react_melt(dmg_mult); return

	if incoming == "fire" and is_electrified:
		is_burning = false; is_electrified = false
		_react_overcharge(dmg_mult, game, player); return
	if incoming == "electric" and is_burning:
		is_burning = false; is_electrified = false
		_react_overcharge(dmg_mult, game, player); return

func _react_electrocute(mult: float, game: Node, player: Node) -> void:
	_last_reaction_type = "electrocute"
	_spawn_electrocute_vfx()
	var dmg := int(12 * mult)
	health -= dmg
	_react_flash(Color(0.2, 0.5, 4.0))
	var _ao_limit: int = 1 if (player and player.get("has_arc_overload") and player.has_arc_overload) else 0
	var _ao_spread: int = 0
	for body in get_tree().get_nodes_in_group("subjects"):
		if body == self: continue
		if is_instance_valid(body) and global_position.distance_to(body.global_position) < 100.0:
			if body.get("apply_electrified"): body.apply_electrified()
		# Arc Overload: +2 ek düşmana 5 hasar zinciri
		if _ao_spread < _ao_limit and is_instance_valid(body) and global_position.distance_to(body.global_position) < 180.0:
			body.health -= 5
			if body.health <= 0: body.die()
			_ao_spread += 1
	var prev_speed: float = float(speed)
	speed = 0.0
	await get_tree().create_timer(0.8).timeout
	if not is_instance_valid(self): return
	if _reactions_cancelled: _reactions_cancelled = false; return
	speed = prev_speed
	_clear_element()
	if player and player.get("has_shock_reflex") and player.has_shock_reflex:
		player._shock_reflex_timer = 3.0
	_notify_reaction(game, player)
	if health <= 0: die()

func _react_steam(mult: float, game: Node, player: Node) -> void:
	_last_reaction_type = "steam"
	_spawn_steam_vfx()
	var dmg := int(8 * mult)
	var _steam_radius := 120.0
	var _thermal: bool = player and player.get("has_thermal_expansion") and player.has_thermal_expansion
	if _thermal:
		_steam_radius = 200.0
	for body in get_tree().get_nodes_in_group("subjects"):
		if body == self: continue
		if is_instance_valid(body) and global_position.distance_to(body.global_position) < _steam_radius:
			body.health -= dmg
			if _thermal and body.get("apply_wet"): body.apply_wet(0.3, 2.0)
			if body.health <= 0: body.die()
	health -= dmg
	_react_flash(Color(0.9, 0.9, 1.0))
	_clear_element()
	if player and player.get("has_steam_surge") and player.has_steam_surge:
		player._steam_surge_timer = 3.0
	_notify_reaction(game, player)
	if health <= 0: die()

func _react_cryostatic(mult: float, game: Node, player: Node) -> void:
	_last_reaction_type = "freeze"
	_spawn_cryostatic_vfx()
	var dmg := int(10 * mult)
	var aoe_radius := 120.0
	for body in get_tree().get_nodes_in_group("subjects"):
		if body == self: continue
		if is_instance_valid(body) and global_position.distance_to(body.global_position) < aoe_radius:
			body.take_damage(dmg)
			if body.get("apply_slow"): body.apply_slow(0.4, 2.0)
			if body.health <= 0: body.die()
	health -= dmg
	_react_flash(Color(0.5, 0.8, 1.0))
	_clear_element()
	if player and player.get("has_frost_barrier") and player.has_frost_barrier:
		player.frost_barrier_hp = 5
		player._frost_barrier_timer = 4.0
	_notify_reaction(game, player)
	if health <= 0: die()

func _react_shatter(mult: float, game: Node, player: Node) -> void:
	_spawn_shatter_vfx()
	var dmg := int(22 * mult)
	health -= dmg
	_react_flash(Color(0.6, 0.9, 1.0))
	_clear_element()
	_notify_reaction(game, player)
	if health <= 0: die()

func _react_melt_frozen(mult: float, game: Node, player: Node) -> void:
	if is_instance_valid(_freeze_sprite):
		_freeze_sprite.queue_free()
		_freeze_sprite = null
	is_frozen = false
	_spawn_melt_frozen_vfx()
	var dmg := int(20 * mult)
	health -= dmg
	_react_flash(Color(1.0, 0.5, 0.2))
	_clear_element()
	_notify_reaction(game, player)
	if health <= 0: die()

func _react_overcharge(mult: float, game: Node, player: Node) -> void:
	_spawn_overcharge_vfx()
	var dmg := int(14 * mult)
	var aoe_radius := 110.0
	for body in get_tree().get_nodes_in_group("subjects"):
		if body == self: continue
		if is_instance_valid(body) and global_position.distance_to(body.global_position) < aoe_radius:
			body.health -= dmg
			if body.health <= 0: body.die()
	health -= dmg
	_react_flash(Color(1.0, 0.6, 0.0))
	_clear_element()
	_notify_reaction(game, player)
	if health <= 0: die()

func _react_melt(mult: float) -> void:
	_last_reaction_type = "melt"
	_spawn_melt_vfx()
	var dmg := int(18 * mult)
	health -= dmg
	_react_flash(Color(1.0, 0.6, 0.1))
	_clear_element()
	if health <= 0: die()

func _react_flash(color: Color) -> void:
	modulate = color
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1, 1)

func _notify_reaction(game: Node, player: Node) -> void:
	if not player: return
	_had_reaction = true
	if player.get("reaction_heal_amount") and player.reaction_heal_amount > 0:
		if game and game.has_method("heal_player"):
			game.heal_player(player.reaction_heal_amount)
	if player.get("reaction_core_speed_bonus") and player.reaction_core_speed_bonus > 0:
		if player.get("momentum_stacks") and player.get("momentum_max"):
			player.momentum_stacks = mini(player.momentum_stacks + 1, player.momentum_max)
		if player.get("orbit_speed_mult"):
			player.orbit_speed_mult += player.reaction_core_speed_bonus
	if player.get("has_perfect_catalyst") and player.has_perfect_catalyst:
		var last_elem: String = player.get("last_applied_element") if player.get("last_applied_element") else ""
		if last_elem == "fire" and not is_burning:
			apply_burn()
		elif last_elem == "wet" and not is_wet:
			apply_wet()
		elif last_elem == "electric" and not is_electrified:
			apply_electrified()
		elif last_elem == "cryo" and not is_slowed:
			apply_slow(0.25)
	if player.get("has_catalyst_mind") and player.has_catalyst_mind and player.catalyst_mind_cooldown <= 0.0:
		player.catalyst_mind_ready = true
		player.catalyst_mind_cooldown = 5.0
	# Volatile Aura Core hook
	for ball in get_tree().get_nodes_in_group("player_balls"):
		if not is_instance_valid(ball): continue
		if not ball.get("is_inner_core") or not ball.is_inner_core: continue
		if ball.inner_core_type == "volatile_aura_core":
			for s in get_tree().get_nodes_in_group("subjects"):
				if not is_instance_valid(s): continue
				if ball.global_position.distance_to(s.global_position) <= 80.0:
					s.take_damage(2, false)
	# Melt Spiral: Melt reaksiyonu → düşman konumunda 2s alev bırakır
	if _last_reaction_type == "melt" and player.get("has_melt_spiral") and player.has_melt_spiral:
		var spiral_pos := global_position
		var fire_zone := ColorRect.new()
		fire_zone.color = Color(1.0, 0.3, 0.0, 0.35)
		fire_zone.size = Vector2(30, 30)
		fire_zone.position = spiral_pos - Vector2(15, 15)
		fire_zone.z_index = 2
		if game: game.add_child(fire_zone)
		var spiral_timer := game.get_tree().create_timer(2.0)
		spiral_timer.timeout.connect(func():
			if is_instance_valid(fire_zone): fire_zone.queue_free()
		)
		var tick_count := 0
		var tick_timer := game.get_tree().create_timer(0.5)
		tick_timer.timeout.connect(func():
			tick_count += 1
			if not is_instance_valid(fire_zone): return
			for s in game.get_tree().get_nodes_in_group("subjects"):
				if s.global_position.distance_to(spiral_pos) <= 20.0:
					s.take_damage(1, false)
			if tick_count < 4:
				var t2 := game.get_tree().create_timer(0.5)
				t2.timeout.connect(func():
					if not is_instance_valid(fire_zone): return
					for s2 in game.get_tree().get_nodes_in_group("subjects"):
						if s2.global_position.distance_to(spiral_pos) <= 20.0:
							s2.take_damage(1, false)
				)
		)
	# Primal Instinct + Void Resonance: reaksiyon tipi takibi
	if player.get("has_primal_instinct") and player.has_primal_instinct:
		if not player._wave_reaction_types.has(_last_reaction_type) and _last_reaction_type != "":
			player._wave_reaction_types.append(_last_reaction_type)
		if player._wave_reaction_types.size() >= 3 and player._primal_instinct_timer <= 0.0:
			player._primal_instinct_timer = 5.0
	if player.get("has_void_resonance") and player.has_void_resonance:
		if not player._wave_reaction_types.has(_last_reaction_type) and _last_reaction_type != "":
			pass  # _wave_reaction_types already updated above
		if player._wave_reaction_types.size() >= 4:
			player._void_resonance_ready = true

# ── VFX ──────────────────────────────────────────────────────────────────────

func _spawn_cryo_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("cryo")
	sf.set_animation_speed("cryo", 8.0)
	sf.set_animation_loop("cryo", true)
	for i in range(1, 10):
		sf.add_frame("cryo", load("res://assets/VFX/cryoEffect/%d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 3
	spr.z_as_relative = true
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("cryo")
	_cryo_sprite = spr

func _spawn_freeze_vfx() -> void:
	if _freeze_sf == null:
		_freeze_sf = SpriteFrames.new()
		if _freeze_sf.has_animation("default"): _freeze_sf.remove_animation("default")
		_freeze_sf.add_animation("freeze")
		_freeze_sf.set_animation_speed("freeze", 8.0)
		_freeze_sf.set_animation_loop("freeze", false)
		for i in range(15):
			_freeze_sf.add_frame("freeze", load("res://assets/VFX/crashFreeze/frame_%03d.png" % i))
	_freeze_sprite = AnimatedSprite2D.new()
	_freeze_sprite.sprite_frames = _freeze_sf
	_freeze_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_freeze_sprite.z_index = -1
	_freeze_sprite.position = Vector2(0, 0)
	_freeze_sprite.scale = Vector2(0.5, 0.5)
	add_child(_freeze_sprite)
	_freeze_sprite.frame = 0
	_freeze_sprite.stop()

func _spawn_steam_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("steam")
	sf.set_animation_speed("steam", 12.0)
	sf.set_animation_loop("steam", false)
	for i in range(17):
		sf.add_frame("steam", load("res://assets/VFX/steam/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("steam")
	spr.animation_finished.connect(spr.queue_free)

func _spawn_cryostatic_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("cryostatic")
	sf.set_animation_speed("cryostatic", 12.0)
	sf.set_animation_loop("cryostatic", false)
	for i in range(3, 16):
		sf.add_frame("cryostatic", load("res://assets/VFX/slowElectricCryostatic/%d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.65, 0.65)
	add_child(spr)
	spr.play("cryostatic")
	spr.animation_finished.connect(spr.queue_free)

func _spawn_shatter_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("shatter")
	sf.set_animation_speed("shatter", 12.0)
	sf.set_animation_loop("shatter", false)
	for i in range(17):
		sf.add_frame("shatter", load("res://assets/VFX/cryoFrozenShatter/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.65, 0.65)
	add_child(spr)
	spr.play("shatter")
	spr.animation_finished.connect(spr.queue_free)

func _spawn_melt_frozen_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("melt_frozen")
	sf.set_animation_speed("melt_frozen", 12.0)
	sf.set_animation_loop("melt_frozen", false)
	for i in range(17):
		sf.add_frame("melt_frozen", load("res://assets/VFX/meltTheFrozen/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("melt_frozen")
	_melt_frozen_sprite = spr
	spr.animation_finished.connect(func(): _melt_frozen_sprite = null; spr.queue_free())

func _spawn_melt_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("melt")
	sf.set_animation_speed("melt", 10.0)
	sf.set_animation_loop("melt", false)
	for i in range(4):
		sf.add_frame("melt", load("res://assets/VFX/melt/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("melt")
	spr.animation_finished.connect(spr.queue_free)

func _spawn_electrocute_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("electrocute")
	sf.set_animation_speed("electrocute", 12.0)
	sf.set_animation_loop("electrocute", false)
	for i in range(17):
		sf.add_frame("electrocute", load("res://assets/VFX/electrocute/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("electrocute")
	_electrocute_sprite = spr
	spr.animation_finished.connect(func(): _electrocute_sprite = null; spr.queue_free())

func _spawn_overheat_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("overheat")
	sf.set_animation_speed("overheat", 12.0)
	sf.set_animation_loop("overheat", false)
	for i in range(15):
		sf.add_frame("overheat", load("res://assets/VFX/overheat/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	spr.play("overheat")
	spr.animation_finished.connect(spr.queue_free)

func _spawn_overcharge_vfx() -> void:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("overcharge")
	sf.set_animation_speed("overcharge", 12.0)
	sf.set_animation_loop("overcharge", false)
	for i in range(10):
		sf.add_frame("overcharge", load("res://assets/VFX/overcharge/frame_%03d.png" % i))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.z_index = 1
	spr.z_as_relative = false
	spr.position = Vector2(0, 0)
	spr.scale = Vector2(0.65, 0.65)
	add_child(spr)
	spr.play("overcharge")
	spr.animation_finished.connect(spr.queue_free)

# ── Element göstergesi ───────────────────────────────────────────────────────

func _setup_element_indicator(y_offset: float) -> void:
	_elem_indicator = load("res://elem_indicator.gd").new()
	_elem_indicator.position = Vector2(0, y_offset)
	_elem_indicator.visible = false
	add_child(_elem_indicator)

func _set_element(elem: String) -> void:
	if _elem_indicator != null:
		_elem_indicator.set_element(elem)

func _clear_element() -> void:
	if _elem_indicator != null:
		_elem_indicator.clear_element()

# ── Chip çizimi ──────────────────────────────────────────────────────────────

func _draw_chip() -> void:
	if is_dead or is_in_group("allies"):
		return
	var t := _chip_t
	var anchors := [
		Vector2(-7.0, -22.0), Vector2( 7.0, -19.0),
		Vector2(-5.0,  -8.0), Vector2( 6.0,  -5.0),
		Vector2(-4.0,   6.0), Vector2( 5.0,   9.0),
	]
	for i in anchors.size():
		var flicker: float = (sin(t * (18.0 + i * 6.7) + i * 1.3) + 1.0) * 0.5
		if flicker < 0.15:
			continue
		var p: Vector2  = anchors[i]
		var ex: float   = sin(t * (11.0 + i * 3.1) + i) * 9.0
		var ey: float   = cos(t * (9.0  + i * 2.5) + i) * 8.0
		var a:  float   = flicker * 1.0
		_chip_node.draw_line(p, p + Vector2(ex, ey), Color(0.0, 0.9, 1.0, a * 0.9), 1.2)
		_chip_node.draw_line(p, p + Vector2(ex, ey), Color(0.55, 0.0, 0.85, a * 0.65), 0.7)
		var ex2: float = ex + sin(t * 13.0 + i) * 4.0
		var ey2: float = ey + cos(t * 10.0 + i) * 3.5
		_chip_node.draw_line(p + Vector2(ex, ey), p + Vector2(ex2, ey2), Color(0.1, 0.75, 1.0, a * 0.75), 1.0)
		_chip_node.draw_line(p + Vector2(ex, ey), p + Vector2(ex2, ey2), Color(0.45, 0.0, 0.75, a * 0.50), 0.6)
