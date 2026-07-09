extends CharacterBody2D

var SPEED = 150.0
var aim_direction = Vector2(0, -1)
var chain_anchor = Vector2(1240, 1040)
var chain_length = 355.0
var invincible = false
var ball_mastery = 0
var pierce_bonus = 0
var electric_bonus = 0
var cryo_bonus = 0
var hydro_bonus = 0
var pyro_bonus = 0
var split_bonus = 0
var has_mimic = false
var dash_charges = 1
var max_dash_charges = 1
var dash_recharge_time = 0.8
var dash_empty_recharge_time = 0.8
var dash_recharge_timer = 0.0
var dash_is_empty = false
var dash_distance = 120.0
var is_dashing = false
var dash_velocity = Vector2.ZERO
var dash_duration = 0.12
var dash_timer = 0.0

# ── RTS / Tactical Mode ───────────────────────────────────────────────────────
var rts_mode: bool = false
const RTS_FIRE_INTERVAL := 0.30
var _rts_fire_timer: float = 0.0

# ── Auto Mode ─────────────────────────────────────────────────────────────────
var auto_mode: bool = false
var _firing_all: bool = false

# ── Orbit sistemi ─────────────────────────────────────────────────────────────
var orbit_balls: Array  = []
const MAX_ORBIT: int    = 8
const ORBIT_RADIUS: float = 65.0
const ORBIT_SPEED: float  = 2.2   # rad/s
var orbit_angle: float  = 0.0
var fire_index: int     = 0

# Legacy — bazı upgrade kodları hâlâ bunları okuyabilir
var held_balls: Array   = []
var held_ball           = null
var catch_mode: bool    = false
var has_next_one: bool  = false

# Vector animation
var _anim_dir: String = "N"
var _vector_oneshot: bool = false

# ── Vector Armor & Stack sistemi ─────────────────────────────────────────────
var has_armor_core: bool = false
var armor_gain_per_hit: int = 1
var has_pain_converter: bool = false

var has_momentum_engine: bool = false
var momentum_stacks: int = 0
var momentum_max: int = 20
var momentum_speed_bonus: float = 0.03  # Lv1:%3  Lv2:%5  Lv3:%7
const MOMENTUM_MAX: int = 20            # geriye uyumluluk alias

var has_impact_feedback: bool = false
var impact_hit_count: int = 0
var impact_stacks: int = 0
var impact_feedback_threshold: int = 10  # Lv1:10  Lv2:7  Lv3:5
const IMPACT_STACK_MAX: int = 10

var has_chain_density: bool = false
var chain_density_bonus_per_hit: int = 1  # Lv1:1  Lv2:2  Lv3:3
var has_last_stand: bool = false
var last_stand_hp_mult: float = 0.005     # Lv1:0.5%  Lv2:0.8%  Lv3:1.2%
var last_stand_armor_mult: float = 0.0    # Lv3'te devreye girer
var has_adrenal_surge: bool = false

# ── Yeni Individuality kart değişkenleri ──────────────────────────────────────
var orbit_speed_mult: float       = 1.0   # Reinforced Frame, Overclocked Reflex, vb.
var armor_gain_mult: float        = 1.0   # Iron Constitution, Overclocked Reflex, vb.
var momentum_gain_mult: float     = 1.0   # Fortified Core System
var damage_mult: float            = 1.0   # Fractured Frame
var knockback_force_mult: float   = 1.0   # Magnetic Weight
var slow_duration_mult: float     = 1.0   # Battlefield Anchor
var return_speed_mult: float      = 1.0   # Hyper Recovery Loop
var hyper_loop_max_bounce: int    = 6     # Hyper Recovery Loop: max bounce (4 olur)
var has_blood_circuit: bool       = false
var has_glass_engine: bool        = false
var has_adrenal_armor: bool       = false # Adrenal Armor System
var has_kinetic_nervous: bool     = false # Momentum reset olmaz
var has_risk_engine: bool         = false # Hasar alınca momentum
var has_pressure_valve: bool      = false # Her 5 momentum → +1 armor
var _pressure_valve_acc: int      = 0     # Momentum sayacı
var has_momentum_cascade: bool    = false # 10+ momentum → Armor Gain ×1.5
var has_steel_rhythm: bool        = false # Armor = Cap iken hit → +1 momentum
var has_bulwark_surge: bool       = false # Armor ≥ %75 cap → Core Speed +%15
var bulwark_surge_active: bool    = false # _process tarafından güncellenir
var has_severance_protocol: bool  = false # HP < %40 → Armor Cap +10 (bir kez)
var _severance_triggered: bool    = false # Severance Protocol tetiklendi mi
var has_overclock_threshold: bool = false # 20 momentum → Core Dmg ×1.3 kalıcı
var _overclock_triggered: bool    = false # Overclock tetiklendi mi

var has_chain_catalyst: bool      = false # 2+ element → +%30 reaksiyon hasarı
var has_volatile_mixture: bool    = false # 3. element → anında reaksiyon

# ── Cyclone — Rogue ──────────────────────────────────────────────────────────
var has_ricochet_strike: bool     = false
var has_data_exploit: bool        = false
var has_shadow_strike: bool       = false
var has_exploit_network: bool     = false
var has_phantom_circuit: bool     = false
var _phantom_hit_counter: int     = 0
# Glitch Assassin
var has_extended_glitch: bool     = false # Glitch 3→5s
var has_signal_jam: bool          = false # Glitch → -25% move speed
var has_data_siphon: bool         = false # Data Leech +2 on Glitched
var has_exploit_stack: bool       = false # Konsekütif Glitch vur → +1 (max +5)
var _exploit_stack_target         = null  # Son Glitch hedefi
var _exploit_stack_count: int     = 0
var has_virus_spread: bool        = false # Network range 350px
var has_interference: bool        = false # Glitch'li → -%20 dmg
var has_exploit_mastery: bool     = false # Data Exploit +3→+6
var has_system_overload: bool     = false # 3+ Glitch aktif → +%20 dmg
var has_mind_hack: bool           = false # 3 ardışık hit → ally saldırsın
var _mind_hack_target             = null
var _mind_hack_count: int         = 0
var has_neural_overwrite: bool    = false # Glitch timer reset
var has_data_siphon_active: bool  = false # (internal flag, not card)
# Ricochet Master
var has_angular_precision: bool   = false # İlk vuruş +%15
var has_wallrunner: bool          = false # +%8 speed per bounce
var has_bounce_mastery: bool      = false # Ricochet +4→+7
var has_pinball_protocol: bool    = false # 3+ bounce → pierce
var has_ricochet_memory: bool     = false # Ricochet bonus sıfırlanmaz
var has_kinetic_rogue: bool       = false # Her 3 bounce → +1 kalıcı base dmg
var _kinetic_rogue_bounce_acc: int = 0
var kinetic_rogue_bonus: int      = 0     # Kalıcı biriken bonus
var has_pinpoint_strike: bool     = false # 5 bounce → ×2 crit
var has_shadow_dance: bool        = false # 2 bounce same flight → +3% speed kalıcı
var _shadow_dance_acc: float      = 0.0   # Biriken hız bonusu
# Phantom Infiltrator
var has_stealth_pass: bool        = false # Phantom 4. (5 yerine)
var has_ghost_protocol: bool      = false # Phantom → 1.5s stun
var has_phase_shift: bool         = false # Phantom → ×2 dmg
var has_interference_cloak: bool  = false # Phantom → Glitch 3s
var has_circuit_breaker: bool     = false # Her 10. hit → tüm Glitch
var _circuit_breaker_counter: int = 0
# Cross-build
var has_rogues_instinct: bool     = false # Arındırma → +1 HP
# Antivirus sistemi
var has_virus_injection: bool     = false # Core hit → Antivirus stack uygular
var has_stack_overflow: bool      = false # Stack cap 3→5
var has_viral_load: bool          = false # Glitch'li hedef 2× stack alır
var has_memory_leak: bool         = false # Antivirus süresi 5→8s
var has_corruption_protocol: bool = false # Antivirused → +%15 hasar alır
var has_cascade_delete: bool      = false # Antivirus yayılır (150px)
var has_root_access: bool         = false # Max stack → +5 burst
var has_zero_day: bool            = false # Antivirused + Glitched → stack iki katı
var has_kernel_panic: bool        = false # Her tick %5 Glitch şansı

# ── Leila — Elemental ────────────────────────────────────────────────────────
var debuff_duration_mult: float   = 1.0   # Elemental Mastery, Arcane Mind, Arcane Focus
var first_debuff_duration_mult: float = 1.0  # Arcane Focus / Arcane Mind (ilk debuff)
var reaction_core_speed_bonus: float  = 0.0  # Resonance Engine: reaksiyon başına hız
var reaction_heal_amount: int         = 0    # Resonant Soul: reaksiyon başına HP
var electric_reaction_range_mult: float = 1.0 # Conduction
var arc_chain_targets: int            = 1    # Arc Amplifier
var freeze_duration_mult: float       = 1.0  # Cryostasis, Frozen Time
var cryo_slow_mult: float             = 1.0  # Supercooling
var burn_damage_mult: float           = 1.0  # Thermal Vision
var mystic_flow_stacks: int           = 0    # Mystic Flow: unique element sayısı
var mystic_flow_elements: Array       = []   # Mystic Flow: hangi elementler uygulandı
var move_speed_bonus_pct: float       = 0.0  # Mystic Flow hız bonusu
var has_static_charge: bool           = false  # Electrified → hasar aktarır
var has_hydro_pressure: bool          = false  # Wet core'lar hızlı döner
var has_condensation: bool            = false  # Wet core'lar hızlı döner (tümü)
var has_living_storm: bool            = false  # Electrified yaklaşınca şimşek
var has_overheat: bool                = false  # Burn 7 stackte patlar
var _overheat_counter: int            = 0
var has_elemental_harmony_util: bool  = false  # 3 element aktifse hız bonusu
var has_mana_overflow: bool           = false  # Calamity → core'lar güçlenir
var mana_overflow_timer: float        = 0.0   # Mana Overflow süreci
var has_pyroblast: bool               = false
var has_thermal_expansion: bool       = false
var elemental_harmony_bonus: float    = 0.0   # Elemental Harmony: unique element başına +5% hız
var has_perfect_catalyst: bool        = false  # Reaksiyon → son element tekrar
var last_applied_element: String      = ""    # Perfect Catalyst için
var has_elemental_harmony_ind: bool   = false  # Individuality: per-element hız
var has_catalyst_mind: bool           = false  # Reaksiyon → sonraki element 2x
var catalyst_mind_ready: bool         = false  # Catalyst Mind tetiklenme hazır
var catalyst_mind_cooldown: float     = 0.0   # 5s cooldown aralarında
var has_resonant_soul_ind: bool       = false  # Individuality: reaksiyon → +1 HP
var has_elemental_memory: bool        = false  # Reaksiyon sonrası debuff 50% uzar
var damage_mult_leila: float          = 1.0   # Thermal Vision vb. hasar çarpanı

# ── Pranga sistemi ────────────────────────────────────────────────────────────
var _chain_links: Array[Sprite2D] = []
const _CHAIN_DIR_NAMES: Array[String] = ["east","south-east","south","south-west","west","north-west","north","north-east"]
const _LINK_SPACING: float = 14.0
const _MAX_LINKS: int = 21
var _link_textures: Dictionary = {}
# Catenary simülasyonu — her halkanın fizik pozisyonu
var _chain_positions: Array[Vector2] = []
const _CHAIN_GRAVITY: float = 0.0
const _CHAIN_DAMPING: float = 8.0
const _CHAIN_TENSION: float = 120.0
var _chain_velocities: Array[Vector2] = []
var _vector_dead: bool = false
var _lmb_was_pressed: bool = false
var _footstep_timer: float = 0.0  # melee sadece tıklama anında tetiklensin

# Leila animation
var _leila_anim_dir: String = "S"
var _leila_oneshot: bool = false

# Cyclone animation
var _cyclone_anim_dir: String = "S"
var _cyclone_crouched: bool = false
const LEILA_RUN_SPEED: float = 200.0  # Bu hızın üstünde run animasyonu oynar

# Dash trail
const DASH_TRAIL_COLOR       := Color(0.0, 0.82, 1.0, 0.9)  # Vector — neon cyan
const DASH_TRAIL_COLOR_LEILA := Color(1.0, 0.08, 0.58, 0.9)  # Leila — neon pink
const DASH_TRAIL_INTERVAL    := 0.02
var   _dash_trail_timer: float = 0.0

# Karakter tipi
var character_type = "vector"

# ── Orbit API ────────────────────────────────────────────────────────────────
func add_to_orbit(ball: Node2D) -> void:
	if ball in orbit_balls: return
	if orbit_balls.size() >= MAX_ORBIT: return
	orbit_balls.append(ball)
	ball.state         = "orbiting"
	ball.moving        = false
	ball.scale         = Vector2(1.0, 1.0)
	ball.z_index       = 5
	ball.strike_offset = Vector2.ZERO
	ball._is_striking  = false
	ball.get_node("CollisionShape2D").disabled = true
	ball._reset_defense_life()
	# Auto mode: orbit'e giren top hemen fırlatılır (Orbit Core hariç)
	if auto_mode and not ball.get("can_orbit"):
		_fire_ball()

func remove_from_orbit(ball: Node2D) -> void:
	orbit_balls.erase(ball)
	if fire_index >= orbit_balls.size() and orbit_balls.size() > 0:
		fire_index = 0

func _rts_fire_at_nearest() -> void:
	if orbit_balls.is_empty(): return
	var subjects := get_tree().get_nodes_in_group("subjects")
	var nearest: Node2D = null
	var nearest_dist := INF
	for s in subjects:
		if not is_instance_valid(s): continue
		var d := global_position.distance_to(s.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = s
	if nearest == null: return
	aim_direction = (nearest.global_position - global_position).normalized()
	_fire_ball()

func _fire_ball() -> void:
	if orbit_balls.is_empty(): return
	fire_index = fire_index % orbit_balls.size()
	var ball = orbit_balls[fire_index]
	# Orbit Core atla — bir sonrakine geç
	if ball.get("can_orbit"):
		fire_index = (fire_index + 1) % orbit_balls.size()
		ball = orbit_balls[fire_index]
		if ball.get("can_orbit"): return  # hepsi Orbit Core ise fırlatma
	orbit_balls.remove_at(fire_index)
	if fire_index >= orbit_balls.size():
		fire_index = 0

	# Tık anındaki yönü yakala (await sırasında mouse kaymasın)
	var captured_aim: Vector2 = aim_direction

	# Orbit'ten çıkar — collision kapat, state durdur
	ball.state         = "flying"
	ball.moving        = false
	ball.strike_offset = Vector2.ZERO
	ball._is_striking  = false
	ball.catch_cooldown = 1.0  # snap sırasında _physics_process tekrar orbit'e almasın
	ball.get_node("CollisionShape2D").disabled = true

	# Hızla merkeze çek
	var snap: Tween = ball.create_tween()
	snap.tween_property(ball, "global_position", global_position, 0.07)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await snap.finished

	if not is_instance_valid(ball):
		return

	# Merkezden fırlat (collision kapalı — player'dan uzaklaşsın)
	ball.move_direction = captured_aim.normalized()
	ball.speed          = 700.0
	ball.moving         = true
	ball.state          = "flying"
	ball.catch_cooldown = 0.5
	ball.scale          = Vector2(1.0, 1.0)
	ball.z_index        = 5

	# ~0.09s sonra collision aç (70 px uzakta olur)
	await get_tree().create_timer(0.09).timeout
	if is_instance_valid(ball):
		ball.get_node("CollisionShape2D").disabled = false

func _fire_all_balls() -> void:
	if orbit_balls.is_empty() or _firing_all: return
	_firing_all = true
	var count := orbit_balls.size()
	for i in count:
		if orbit_balls.is_empty(): break
		_fire_ball()
		await get_tree().create_timer(0.12).timeout
	_firing_all = false

# Legacy uyumluluk
func catch_ball(_ball: Node2D) -> void:
	pass


func _ready() -> void:
	# _process'i AnimatedSprite2D'den (priority 0) SONRA çalıştır
	# Böylece aynı frame'de animasyon durduğu an is_playing() false görürüz
	process_priority = 1
	z_index = 2
	character_type = GameData.selected_character
	# Each character shows its own visual; others remain hidden in tscn
	match character_type:
		"vector":
			$VectorSprite.visible = true
			_setup_vector_sprite_new()
		"leila":
			$LeilaSprite.visible = true
			_setup_leila_sprite()
		"cyclone":
			$CycloneSprite.visible = true
			_setup_cyclone_sprite()
	_setup_pranga()

func _setup_pranga() -> void:
	for d in _CHAIN_DIR_NAMES:
		_link_textures[d] = load("res://assets/chain/chainLink/%s.png" % d)
	for i in range(_MAX_LINKS):
		var lnk := Sprite2D.new()
		lnk.visible = false
		lnk.z_index = 1
		lnk.z_as_relative = false
		lnk.scale = Vector2(0.50, 0.50)
		add_child(lnk)
		_chain_links.append(lnk)
		_chain_positions.append(Vector2.ZERO)
		_chain_velocities.append(Vector2.ZERO)

func _update_pranga(delta: float) -> void:
	queue_redraw()
	# Anchor ve player pozisyonları global koordinatlarda
	var anchor_g: Vector2 = chain_anchor
	var player_g: Vector2 = global_position + Vector2(0, 18)

	# Zincir uzunluğu — her halka arası mesafe
	var seg_len: float = _LINK_SPACING

	# Başlangıçta pozisyonları başlat (sıfırsa)
	if _chain_positions[0] == Vector2.ZERO:
		for i in range(_MAX_LINKS):
			var t: float = float(i) / float(_MAX_LINKS - 1)
			_chain_positions[i] = anchor_g.lerp(player_g, t)

	# Verlet entegrasyonu — yer çekimi yok, sadece atalet + sönümleme
	for i in range(1, _MAX_LINKS - 1):
		_chain_velocities[i] *= (1.0 - _CHAIN_DAMPING * delta)
		_chain_positions[i] += _chain_velocities[i] * delta

	# Kısıt: anchor sabit, player ucu player'a bağlı
	_chain_positions[0] = anchor_g
	_chain_positions[_MAX_LINKS - 1] = player_g

	# Kısıt iterasyonu — halka mesafelerini koru, hız güncelle
	for _iter in range(12):
		for i in range(_MAX_LINKS - 1):
			var diff: Vector2 = _chain_positions[i + 1] - _chain_positions[i]
			var d: float = diff.length()
			if d > 0.001:
				var correction: Vector2 = diff * ((d - seg_len) / d) * 0.5
				if i > 0:
					_chain_positions[i] += correction
					_chain_velocities[i] += correction / delta * 0.05
				if i + 1 < _MAX_LINKS - 1:
					_chain_positions[i + 1] -= correction
					_chain_velocities[i + 1] -= correction / delta * 0.05
		_chain_positions[0] = anchor_g
		_chain_positions[_MAX_LINKS - 1] = player_g

	# Sprite'ları pozisyonlara yerleştir
	for i in range(_MAX_LINKS):
		var pos_local: Vector2 = to_local(_chain_positions[i])
		# Yön hesapla
		var dir_vec: Vector2 = Vector2.DOWN
		if i < _MAX_LINKS - 1:
			dir_vec = (_chain_positions[i + 1] - _chain_positions[i]).normalized()
		elif i > 0:
			dir_vec = (_chain_positions[i] - _chain_positions[i - 1]).normalized()
		var dir_name: String = _angle_to_chain_dir(dir_vec.angle())
		_chain_links[i].visible = true
		_chain_links[i].global_position = _chain_positions[i]
		_chain_links[i].texture = _link_textures[dir_name]

func _angle_to_chain_dir(angle: float) -> String:
	var deg: float = fmod(rad_to_deg(angle) + 360.0, 360.0)
	var sector: int = int((deg + 22.5) / 45.0) % 8
	return _CHAIN_DIR_NAMES[sector]

func _process(_delta: float) -> void:
	if character_type != "vector" or _vector_dead:
		return
	var sprite: AnimatedSprite2D = $VectorSprite
	# Güvenlik: sprite hiçbir zaman görünmez kalmasın
	if not sprite.visible:
		sprite.visible = true
	# AnimatedSprite2D (priority 0) bu frame'de durmuşsa, biz (priority 1) hemen yakalayız
	if not sprite.is_playing():
		if _vector_oneshot:
			_vector_oneshot = false
		var anim = ("walk_" + _anim_dir) if velocity != Vector2.ZERO else "idle_N"
		sprite.play(anim)
		# Frame'i anında 0'a ayarla — play() iç gecikmesi olmadan
		sprite.set_frame_and_progress(0, 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if auto_mode:
			return  # auto mode'da tık devre dışı
		_fire_all_balls()

	# Sağ tık → dash
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if dash_charges > 0:
			_dash()

func _dash() -> void:
	var dash_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): dash_dir.y -= 1
	if Input.is_key_pressed(KEY_S): dash_dir.y += 1
	if Input.is_key_pressed(KEY_A): dash_dir.x -= 1
	if Input.is_key_pressed(KEY_D): dash_dir.x += 1

	if dash_dir == Vector2.ZERO:
		return

	is_dashing = true
	$CollisionShape2D.disabled = true
	dash_velocity = dash_dir.normalized() * (dash_distance / dash_duration)
	dash_timer = dash_duration
	dash_charges -= 1
	dash_recharge_timer = 0.0
	if dash_charges <= 0:
		dash_is_empty = true

func _physics_process(delta: float) -> void:
	if catalyst_mind_cooldown > 0.0:
		catalyst_mind_cooldown -= delta
	# RTS modu — en yakın düşmana otomatik ateş
	if rts_mode and not orbit_balls.is_empty():
		_rts_fire_timer -= delta
		if _rts_fire_timer <= 0.0:
			_rts_fire_timer = RTS_FIRE_INTERVAL
			_rts_fire_at_nearest()

	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): direction.y = -1
	if Input.is_key_pressed(KEY_S): direction.y = 1
	if Input.is_key_pressed(KEY_A): direction.x = -1
	if Input.is_key_pressed(KEY_D): direction.x = 1

	velocity = direction.normalized() * SPEED
	move_and_slide()

	# Vector footstep toz bulutu
	if character_type == "vector" and direction != Vector2.ZERO and not is_dashing:
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			_footstep_timer = 0.18
			_spawn_footstep_dust(global_position + Vector2(0, 22))

	# Dash hareketi
	if is_dashing:
		dash_timer -= delta
		global_position += dash_velocity * delta
		# Dash trail — ghost spawn
		if character_type == "vector" or character_type == "leila":
			_dash_trail_timer -= delta
			if _dash_trail_timer <= 0.0:
				_dash_trail_timer = DASH_TRAIL_INTERVAL
				_spawn_dash_ghost()
		if dash_timer <= 0:
			is_dashing = false
			dash_velocity = Vector2.ZERO
			_dash_trail_timer = 0.0
			$CollisionShape2D.disabled = false

	# Wall boundaries
	global_position.x = clamp(global_position.x, 910, 1580)
	global_position.y = clamp(global_position.y, 330, 1035)

	# Chain constraint check

	aim_direction = (get_global_mouse_position() - global_position).normalized()

	var dist_to_anchor = global_position.distance_to(chain_anchor)
	if dist_to_anchor > chain_length:
		var dir_to_anchor = (chain_anchor - global_position).normalized()
		global_position = chain_anchor - dir_to_anchor * chain_length

	_update_pranga(delta)

	# ── Orbit pozisyonlama ────────────────────────────────────────────────────
	var _effective_orbit_speed: float = ORBIT_SPEED * orbit_speed_mult
	var game_node := get_tree().get_first_node_in_group("game")
	if has_momentum_engine and momentum_stacks > 0:
		# Last Stand: eksik HP başına ekstra bonus
		var last_stand_bonus: float = 0.0
		if has_last_stand and game_node:
			last_stand_bonus = float(game_node.player_max_hp - game_node.player_hp) * last_stand_hp_mult
		# Adrenal Surge: HP %30 altında Momentum x2
		var stack_mult: float = 1.0
		if has_adrenal_surge and game_node and float(game_node.player_hp) / float(max(game_node.player_max_hp, 1)) < 0.3:
			stack_mult = 2.0
		_effective_orbit_speed = ORBIT_SPEED * orbit_speed_mult * (1.0 + float(momentum_stacks) * momentum_speed_bonus * stack_mult + last_stand_bonus)
	# Blood Circuit: HP <= %70 iken hız artar (max +%50 at 0 HP)
	if has_blood_circuit and game_node:
		var hp_ratio: float = float(game_node.player_hp) / float(max(game_node.player_max_hp, 1))
		if hp_ratio <= 0.7:
			_effective_orbit_speed *= 1.0 + (0.7 - hp_ratio) / 0.7 * 0.5
	# Adrenal Armor System: HP > %70 → Core Speed +%10
	if has_adrenal_armor and game_node:
		var hp_r: float = float(game_node.player_hp) / float(max(game_node.player_max_hp, 1))
		if hp_r > 0.7:
			_effective_orbit_speed *= 1.1
	# Bulwark Surge: Armor ≥ %75 cap → Core Speed +%15
	if get("has_bulwark_surge") != null and has_bulwark_surge and game_node:
		var _armor_ratio: float = float(game_node.player_armor) / float(max(game_node.player_armor_cap, 1))
		if _armor_ratio >= 0.75:
			_effective_orbit_speed *= 1.15
	# Mana Overflow: Calamity sonrası 5s boyunca Core Speed +%50
	if mana_overflow_timer > 0.0:
		mana_overflow_timer -= delta
		_effective_orbit_speed *= 1.5
	# Elemental Harmony: aktif unique element başına +%5 Core Speed
	if has_elemental_harmony_util and elemental_harmony_bonus > 0.0:
		_effective_orbit_speed *= (1.0 + elemental_harmony_bonus)
	orbit_angle += _effective_orbit_speed * delta
	var n := orbit_balls.size()
	for i in range(n - 1, -1, -1):
		if not is_instance_valid(orbit_balls[i]):
			orbit_balls.remove_at(i)
			continue
		var angle: float = orbit_angle + (TAU / max(n, 1)) * i
		orbit_balls[i].global_position = global_position + Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS + orbit_balls[i].strike_offset

	# ── Animasyon yön güncellemeleri ──────────────────────────────────────────
	_update_anim_dir()

	# ── Animasyon oynatma ─────────────────────────────────────────────────────
	if character_type == "vector":
		_update_vector_animation()
	elif character_type == "leila":
		_update_leila_animation()
	elif character_type == "cyclone":
		_update_cyclone_animation()

	queue_redraw()

	# Dash charge recharge
	if dash_charges < max_dash_charges:
		dash_recharge_timer += delta
		var recharge = dash_empty_recharge_time if dash_is_empty else dash_recharge_time
		if dash_recharge_timer >= recharge:
			dash_recharge_timer = 0.0
			dash_charges += 1
			if dash_charges >= max_dash_charges:
				dash_is_empty = false




func _setup_cyclone_sprite() -> void:
	var sprite: AnimatedSprite2D = $CycloneSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base := "res://assets/charsRedesign/cyclone/animations/"
	var dirs := ["N","NE","E","SE","S","SW","W","NW"]
	var dir_folder := {"N":"north","NE":"north-east","E":"east","SE":"south-east","S":"south","SW":"south-west","W":"west","NW":"north-west"}

	frames.add_animation("idle_N")
	frames.set_animation_speed("idle_N", 8.0)
	frames.set_animation_loop("idle_N", true)
	for i in range(4):
		frames.add_frame("idle_N", load(base + "Breathing_Idle/north/frame_%03d.png" % i))

	for d in dirs:
		var key: String = "walk_" + d
		frames.add_animation(key)
		frames.set_animation_speed(key, 10.0)
		frames.set_animation_loop(key, true)
		for i in range(6):
			frames.add_frame(key, load(base + "walk/" + dir_folder[d] + "/frame_%03d.png" % i))

	for d in dirs:
		var key: String = "crouched_walk_" + d
		var count: int = 4 if d in ["SE","SW"] else 6
		frames.add_animation(key)
		frames.set_animation_speed(key, 10.0)
		frames.set_animation_loop(key, true)
		for i in range(count):
			frames.add_frame(key, load(base + "Crouched_Walking/" + dir_folder[d] + "/frame_%03d.png" % i))

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(1.0, 1.0)
	sprite.play("idle_N")


func _setup_vector_sprite_new() -> void:
	var sprite: AnimatedSprite2D = $VectorSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base := "res://assets/charsRedesign/vector/animations/"
	var dirs := ["N","NE","E","SE","S","SW","W","NW"]
	var dir_folder := {"N":"north","NE":"north-east","E":"east","SE":"south-east","S":"south","SW":"south-west","W":"west","NW":"north-west"}

	frames.add_animation("idle_N")
	frames.set_animation_speed("idle_N", 8.0)
	frames.set_animation_loop("idle_N", true)
	for i in range(8):
		frames.add_frame("idle_N", load(base + "Idle/north/frame_%03d.png" % i))

	for d in dirs:
		var key: String = "walk_" + d
		frames.add_animation(key)
		frames.set_animation_speed(key, 10.0)
		frames.set_animation_loop(key, true)
		for i in range(6):
			frames.add_frame(key, load(base + "Walk/" + dir_folder[d] + "/frame_%03d.png" % i))

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(1.0, 1.0)
	sprite.animation_finished.connect(_on_vector_anim_finished)
	sprite.play("idle_N")


func _setup_leila_sprite() -> void:
	var sprite: AnimatedSprite2D = $LeilaSprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	var base := "res://assets/charsRedesign/leila/animations/"
	var dirs := ["N","NE","E","SE","S","SW","W","NW"]
	var dir_folder := {"N":"north","NE":"north-east","E":"east","SE":"south-east","S":"south","SW":"south-west","W":"west","NW":"north-west"}

	# idle — north only, 4 frames (klasör adı Türkçe ı ile: ıdle/North)
	frames.add_animation("idle_N")
	frames.set_animation_speed("idle_N", 8.0)
	frames.set_animation_loop("idle_N", true)
	for i in range(4):
		frames.add_frame("idle_N", load(base + "ıdle/North/frame_%03d.png" % i))

	# walk — 8 yön; north=4 frame, diğerleri=8 frame
	for d in dirs:
		var key: String = "walk_" + d
		var count: int = 4 if d == "N" else 8
		frames.add_animation(key)
		frames.set_animation_speed(key, 10.0)
		frames.set_animation_loop(key, true)
		for i in range(count):
			frames.add_frame(key, load(base + "walk/" + dir_folder[d] + "/frame_%03d.png" % i))

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(1.0, 1.0)
	sprite.animation_finished.connect(_on_leila_anim_finished)
	sprite.play("idle_N")

func _update_leila_animation() -> void:
	if _leila_oneshot:
		return
	var sprite: AnimatedSprite2D = $LeilaSprite
	var anim: String = ("walk_" + _anim_dir) if velocity != Vector2.ZERO else "idle_N"
	if sprite.animation != anim:
		sprite.play(anim)

func _update_cyclone_animation() -> void:
	_cyclone_crouched = Input.is_key_pressed(KEY_CTRL)
	var sprite: AnimatedSprite2D = $CycloneSprite
	var anim: String
	if velocity != Vector2.ZERO:
		anim = ("crouched_walk_" if _cyclone_crouched else "walk_") + _anim_dir
	else:
		anim = "idle_N"
	if sprite.animation != anim:
		sprite.play(anim)

func _play_leila_oneshot(anim_name: String) -> void:
	_leila_oneshot = true
	var sprite: AnimatedSprite2D = $LeilaSprite
	# Atış ve vurma animasyonları mouse yönünde
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _on_leila_anim_finished() -> void:
	_leila_oneshot = false

func _update_anim_dir() -> void:
	var w = Input.is_key_pressed(KEY_W)
	var s = Input.is_key_pressed(KEY_S)
	var a = Input.is_key_pressed(KEY_A)
	var d = Input.is_key_pressed(KEY_D)
	if   w and d: _anim_dir = "NE"
	elif w and a: _anim_dir = "NW"
	elif s and d: _anim_dir = "SE"
	elif s and a: _anim_dir = "SW"
	elif w:       _anim_dir = "N"
	elif s:       _anim_dir = "S"
	elif d:       _anim_dir = "E"
	elif a:       _anim_dir = "W"
	else:         _anim_dir = "N"


func _update_vector_animation() -> void:
	if _vector_dead or _vector_oneshot:
		return
	var anim := ("walk_" + _anim_dir) if velocity != Vector2.ZERO else "idle_N"
	if $VectorSprite.animation != anim:
		$VectorSprite.play(anim)


func _play_vector_oneshot(anim_name: String) -> void:
	if _vector_dead:
		return
	if not $VectorSprite.sprite_frames.has_animation(anim_name):
		return
	_vector_oneshot = true
	$VectorSprite.play(anim_name)


func _on_vector_anim_finished() -> void:
	# Yalnızca bayrağı temizle.
	# Geçişi (idle/run oynatma) _process (priority 1) üstleniyor —
	# AnimatedSprite2D'nin kendi signal'inden play() çağırmak iç-state
	# çakışmasına yol açıyordu ve bir frame boşluk bırakıyordu.
	_vector_oneshot = false



func _spawn_dash_ghost() -> void:
	var sprite: AnimatedSprite2D
	var trail_color: Color
	if character_type == "leila":
		sprite      = $LeilaSprite
		trail_color = DASH_TRAIL_COLOR_LEILA
	else:
		sprite      = $VectorSprite
		trail_color = DASH_TRAIL_COLOR
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation(sprite.animation):
		return
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if not tex:
		return
	var ghost := Sprite2D.new()
	ghost.texture         = tex
	ghost.global_position = sprite.global_position
	ghost.scale           = sprite.global_scale
	ghost.z_index         = 1
	ghost.z_as_relative   = false
	ghost.modulate        = trail_color
	get_parent().add_child(ghost)
	var tw: Tween = ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(ghost.queue_free)


func play_death() -> void:
	if character_type != "vector":
		return
	_vector_dead = true
	_vector_oneshot = true
	$VectorSprite.play("death")


func _no_ball_nearby() -> bool:
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		if ball.moving and global_position.distance_to(ball.global_position) < 100:
			return false
	return true


func take_damage(amount) -> void:
	if invincible:
		return
	invincible = true
	if false:
		pass  # take_damage animasyonları kaldırıldı
	var game = get_parent()
	if game.has_method("player_damaged"):
		game.player_damaged(amount)
	await get_tree().create_timer(0.3).timeout
	invincible = false

func _draw() -> void:
	# Karakter gölgesi — tüm karakterler için ayakların altında oval
	var shadow_pts := PackedVector2Array()
	var s_rx: float = 18.0; var s_ry: float = 7.0
	var s_cy: float = 20.0  # ayak seviyesi
	for i in range(32):
		var a: float = (float(i) / 32.0) * TAU
		shadow_pts.append(Vector2(cos(a) * s_rx, s_cy + sin(a) * s_ry))
	draw_colored_polygon(shadow_pts, Color(0.0, 0.0, 0.0, 0.38))

	# ── Zincir elektrik efekti ───────────────────────────────────────────────
	if _chain_positions.size() >= 2:
		var t := Time.get_ticks_msec() * 0.001
		for i in range(_chain_positions.size() - 1):
			var a := to_local(_chain_positions[i])
			var b := to_local(_chain_positions[i + 1])
			var gap := a.distance_to(b)
			if gap < 6.0:
				continue
			var intensity: float = clamp((gap - 6.0) / 18.0, 0.0, 1.0)
			var mid: Vector2 = (a + b) * 0.5
			var perp: Vector2 = (b - a).normalized().rotated(PI * 0.5)
			# Ark sapması — zaman + halka indeksine göre titreşir
			var wobble: float = sin(t * 9.0 + float(i) * 1.3) * gap * 0.22 * intensity
			var ctrl: Vector2 = mid + perp * wobble
			# Dış sarı ark (parlak)
			draw_line(a, ctrl, Color(1.0, 0.9, 0.1, 0.55 * intensity), 1.8)
			draw_line(ctrl, b,  Color(1.0, 0.9, 0.1, 0.55 * intensity), 1.8)
			# İç mavi-beyaz ark (sıcak merkez)
			draw_line(a, ctrl, Color(0.6, 0.9, 1.0, 0.85 * intensity), 0.8)
			draw_line(ctrl, b,  Color(0.6, 0.9, 1.0, 0.85 * intensity), 0.8)

	# Orbit halkası — soluk gösterge
	if orbit_balls.size() > 0:
		draw_arc(Vector2.ZERO, ORBIT_RADIUS, 0, TAU, 64, Color(0.0, 0.9, 1.0, 0.08), 1.5)

	# Nişan çizgisi — sol tık basılıyken
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not orbit_balls.is_empty():
		var drawn := 0.0
		var draw_dash := true
		while drawn < 150.0:
			var seg := 10.0 if draw_dash else 6.0
			seg = min(seg, 150.0 - drawn)
			if draw_dash:
				draw_line(aim_direction * drawn, aim_direction * (drawn + seg), Color(0, 0.9, 1.0, 0.7), 2.0)
			drawn += seg
			draw_dash = not draw_dash


func _spawn_footstep_dust(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.top_level = true
	p.global_position = pos
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.85
	p.amount = 5
	p.lifetime = 0.4
	p.initial_velocity_min = 15.0
	p.initial_velocity_max = 45.0
	p.spread = 70.0
	p.direction = Vector2(0, -1)
	p.gravity = Vector2(0, 80)
	p.scale_amount_min = 2.5
	p.scale_amount_max = 5.0
	p.color = Color(0.55, 0.6, 0.7, 0.55)
	p.z_index = -1
	get_tree().current_scene.add_child(p)
	p.emitting = true
	get_tree().create_timer(0.7).timeout.connect(p.queue_free)
