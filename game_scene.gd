extends Node2D

var _font_bold    = preload("res://assets/orbitronfont/Orbitron-Bold.ttf")
var _font_regular = preload("res://assets/orbitronfont/Orbitron-Regular.ttf")
var _gameplay_music_stream = preload("res://assets/music/gameplayTheme.ogg")

var level = 1
var player_hp = 50
var player_max_hp = 50

# ── Armor sistemi ─────────────────────────────────────────────────────────────
var player_armor: int = 0
var player_max_armor: int = 0
var player_armor_gain: int = 1        # Armor Core başına kazanılan armor
var player_armor_cap: int = 20        # Armor üst sınırı
var player_armor_regen_rate: float = 0.0
var _armor_regen_acc: float = 0.0
var _armor_was_full: bool = false
var _armor_bar: ColorRect = null
var _armor_label: Label = null
var _frost_barrier_bar: ColorRect = null
var _frost_barrier_label: Label = null
var _armor_gain_boost: float = 1.0    # Pain Converter / Emergency Protocol çarpanı
var _armor_gain_boost_timer: float = 0.0

# ── Core Envanter sistemi ──────────────────────────────────────────────────────
var _core_panel: Control = null
var _core_cells: Array = []
var _connected_core_cells: Array = []
var _pending_core_type: String = ""

# ── Tooltip sistemi ────────────────────────────────────────────────────────────
var _tooltip_label: Label = null
var _low_hp_vignette: TextureRect = null
var _calamity_cells: Array = []

const _CORE_DISPLAY_NAMES: Dictionary = {
	"normal":     "Normal Core",     "electric":   "Electric Core",
	"arc":        "Arc Core",       "plasma":     "Plasma Core",
	"steam":      "Steam Core",     "echo":       "Echo Core",
	"orbit":      "Prism Core",     "scatter":    "Scatter Core",
	"catalyst":   "Catalyst Core",  "voltaic":    "Voltaic Core",
	"pierce":     "Pierce Core",     "split":      "Split Core",
	"cryo":       "Cryo Core",      "glitch":     "Glitch Core",
	"water":      "Hydro Core",     "fire":       "Pyro Core",
	"leech":      "Data Leech",     "mimic":      "Echo Ball",
	"armor":      "Armor Core",     "anchor":     "Anchor Core",
	"crusher":    "Crusher Core",   "kinetic":    "Kinetic Core",
	"bulwark":    "Bulwark Core",   "siege":      "Siege Core",
	"bloodbound": "Bloodbound Core","tempered":   "Tempered Core",
	"antivirus_core": "Virus Core", "decay":   "Decay Core",
	"static_core":    "Static Core",    "ricochet_core": "Ricochet Core",
	"phantom_circuit": "Phantom Circuit Core",
	"mist_core":             "Mist Core",
	"frost_aura_core":       "Frost Aura Core",
	"static_aura_core":      "Static Aura Core",
	"catalyst_pulse_core":   "Catalyst Pulse Core",
	"echo_resonance_core":   "Echo Resonance Core",
	"volatile_aura_core":    "Volatile Aura Core",
	"elemental_shield_core": "Elemental Shield Core",
	"glitch_pulse_core":    "Glitch Pulse Core",
	"shadow_core":          "Shadow Core",
	"data_drain_core":      "Data Drain Core",
	"virus_beacon_core":    "Virus Beacon Core",
	"rogues_eye_core":      "Rogue's Eye Core",
	"circuit_overload_core":"Circuit Overload Core",
}

const _CALAMITY_DISPLAY_NAMES: Dictionary = {
	"⚡":  "Calamity Lightning",
	"🔥":  "Calamity Flame",
	"🌀":  "Gravitational Force",
	"❄️": "Calamity Blizzard",
	"🌊":  "Calamity Flood",
	"🔋":  "Calamity Battery",
	"🌋":  "Calamity Volcanic Rift",
	"⛈️": "Calamity Storm",
	"💾":  "Data Storm",
	"👾":  "Backdoor",
	"🎱":  "Bounce Barrage",
	"🪞":  "Mirror Image",
	"🧪":  "Systemic Failure",
	"💥":  "Shockwave",
	"🔓":  "Full Breach",
	"💨":  "Momentum Burst",
	"🏚️": "Rampart Collapse",
	"🕳️": "WormHole",
	"🌧️": "Siege Rain",
	"🔥💥": "Wildfire",
	"💣":   "Glitch Bomb",
	"💻💥": "System Crash",
	"🦠":   "Virus Rain",
	"☠️":  "Decay Field",
}

# ── Upgrade kart takip sistemi ─────────────────────────────────────────────────
var _seen_individualities: Array = []   # seçilen Individuality kart isimleri
var _utility_levels: Dictionary = {}    # {kart_adı: int}  0-3
var upgrades: Array = []
var _all_upgrades: Array = []
var _owned_indices: Array = []  # alınan kart index'leri — requires filtresi için
var _run_start_level: int = 0

var _player_node: Node = null  # önbellek — her frame get_node çağrısını önler
var _lmb_clear_pending: bool = false  # LMB bırakılınca bir kez daha redraw
var _hex_east: Sprite2D = null
var _hex_west: Sprite2D = null
var _hex_textures_east: Array = []
var _hex_textures_west: Array = []
var _hex_anim_textures_east: Array = []
var _hex_anim_textures_west: Array = []
var _hex_anim_frame: int = 0
var _hex_anim_timer: Timer = null

const _CORE_FOLDER_MAP: Dictionary = {
	"normal":     "normalBall",    "electric": "electricBall",
	"arc":        "arcCore",       "plasma":   "plasmaCore",
	"steam":      "steamCore",     "echo":     "echoCore",
	"orbit":      "orbitCore",     "scatter":  "scatterCore",
	"catalyst":   "catalystCore",  "voltaic":  "voltaicCore",
	"pierce":     "pierceBall",    "split":    "splitBall",
	"cryo":       "cryoBall",      "glitch":   "glitchBall",
	"water":      "waterBall",     "fire":     "fireBall",
	"leech":      "dataLeechBall", "mimic":    "echoBall",
	"armor":      "armorCore",     "anchor":   "anchorCore",
	"crusher":    "crusherCore",   "kinetic":  "kineticCore",
	"bulwark":    "bulwarkCore",   "siege":    "siegeCore",
	"bloodbound": "bloodboundCore","tempered": "temperedCore",
	# Vector Connected Cores
	"iron_aura_core":        "ironAuraCore",
	"momentum_field_core":   "momentumFieldCore",
	"regen_pulse_core":      "regenPulseCore",
	"fortress_core":         "fortressCore",
	"bloodwall_core":        "bloodWallCore",
	"overcharge_core":       "overchargeCore",
	"anchor_pulse_core":     "anchorPulseCore",
	# Leila Connected Cores
	"mist_core":             "mistCore",
	"frost_aura_core":       "frostAuraCore",
	"static_aura_core":      "staticAuraCore",
	"catalyst_pulse_core":   "catalystPulseCore",
	"echo_resonance_core":   "echoResonanceCore",
	"volatile_aura_core":    "volatileAuraCore",
	"elemental_shield_core": "elementalShieldCore",
	# Cyclone Connected Cores
	"glitch_pulse_core":     "glitchPulseCore",
	"shadow_core":           "shadowCore",
	"data_drain_core":       "dataDrainCore",
	"virus_beacon_core":     "virusBeaconCore",
	"rogues_eye_core":       "roguesEyeCore",
	"circuit_overload_core": "circuitOverloadCore",
}

const _CORE_INDEX_MAP: Dictionary = {
	0: "split",   1: "electric",  2: "pierce",   15: "cryo",
	16: "glitch", 17: "water",   18: "fire",    19: "mimic",
	22: "leech",  40: "armor",   41: "anchor",  42: "crusher",
	43: "kinetic",44: "bulwark", 45: "siege",   46: "bloodbound",
	47: "tempered",
	61: "plasma", 62: "steam",   63: "arc",     64: "echo",
	65: "orbit",  77: "scatter", 78: "catalyst",87: "voltaic",
	180: "regen_pulse_core", 181: "fortress_core", 182: "bloodwall_core",
	183: "overcharge_core", 184: "anchor_pulse_core",
	185: "mist_core", 186: "frost_aura_core", 187: "static_aura_core",
	188: "catalyst_pulse_core", 189: "echo_resonance_core",
	190: "volatile_aura_core", 191: "elemental_shield_core",
	192: "glitch_pulse_core", 193: "shadow_core", 194: "data_drain_core",
	195: "virus_beacon_core", 196: "rogues_eye_core", 197: "circuit_overload_core",
}

# Connected Core (iç yörünge) index'leri — kart UI'da badge göstermek için
const _CONNECTED_CORE_INDICES: Array = [
	178, 179, 180, 181, 182, 183, 184, # Vector
	65,                                # Leila (Prism Core — orbit'te kalır, Connected Core)
	185, 186, 187, 188, 189, 190, 191, # Leila
	192, 193, 194, 195, 196, 197,      # Cyclone
]

# index → {name, category}  (Identity kart izleme gerekmez, sadece Individuality+Utility)
const _UPGRADE_META: Dictionary = {
	4:  {"name": "Speed Upgrade",       "category": "Individuality"},
	5:  {"name": "Orbit +1",            "category": "Individuality"},
	11: {"name": "Core Mastery",        "category": "Utility"},
	13: {"name": "Electric Amp",        "category": "Utility"},
	99: {"name": "Cryo Amp",           "category": "Utility"},
	100: {"name": "Hydro Amp",         "category": "Utility"},
	101: {"name": "Pyro Amp",          "category": "Utility"},
	102: {"name": "Pyroblast",         "category": "Utility"},
	14: {"name": "Split Amp",           "category": "Utility"},
	20: {"name": "Medkit",              "category": "Individuality"},
	21: {"name": "Max Health Up",       "category": "Individuality"},
	30: {"name": "Blood for Steel",     "category": "Individuality"},
	31: {"name": "Pain Converter",      "category": "Individuality"},
	32: {"name": "Adrenal Surge",       "category": "Individuality"},
	33: {"name": "Scar Tissue",         "category": "Individuality"},
	34: {"name": "Emergency Protocol",  "category": "Individuality"},
	35: {"name": "Momentum Engine",     "category": "Utility"},
	36: {"name": "Impact Feedback",     "category": "Utility"},
	37: {"name": "Chain Density",       "category": "Utility"},
	38: {"name": "Last Stand",              "category": "Utility"},
	48: {"name": "Reinforced Frame",        "category": "Individuality"},
	49: {"name": "Iron Constitution",       "category": "Individuality"},
	50: {"name": "Fortified Core System",   "category": "Individuality"},
	51: {"name": "Blood Circuit",           "category": "Individuality"},
	52: {"name": "Fractured Frame",         "category": "Individuality"},
	53: {"name": "Glass Engine",            "category": "Individuality"},
	54: {"name": "Overclocked Reflex",      "category": "Individuality"},
	55: {"name": "Kinetic Nervous System",  "category": "Individuality"},
	56: {"name": "Hyper Recovery Loop",     "category": "Individuality"},
	57: {"name": "Magnetic Weight",         "category": "Individuality"},
	58: {"name": "Battlefield Anchor",      "category": "Individuality"},
	59: {"name": "Adrenal Armor System",    "category": "Individuality"},
	60: {"name": "Risk Engine",             "category": "Individuality"},
	# ── Leila ────────────────────────────────────────────────────────────────
	66: {"name": "Conduction",          "category": "Utility"},
	67: {"name": "Hydro Pressure",      "category": "Utility"},
	68: {"name": "Arc Amplifier",       "category": "Utility"},
	69: {"name": "Static Charge",       "category": "Utility"},
	70: {"name": "Cryostasis",          "category": "Utility"},
	71: {"name": "Supercooling",        "category": "Utility"},
	73: {"name": "Thermal Vision",      "category": "Utility"},

	76: {"name": "Mystic Flow",         "category": "Individuality"},
	80: {"name": "Arcane Mind",         "category": "Utility"},
	81: {"name": "Resonance Engine",    "category": "Utility"},
	82: {"name": "Frozen Time",         "category": "Utility"},
	83: {"name": "Overheat",            "category": "Utility"},
	84: {"name": "Elemental Harmony",   "category": "Utility"},
	85: {"name": "Resonant Soul",       "category": "Individuality"},
	86: {"name": "Elemental Memory",    "category": "Individuality"},
	90: {"name": "Mana Overflow",       "category": "Utility"},
	91: {"name": "Perfect Catalyst",    "category": "Utility"},
}

var subject_scene = preload("res://subject.tscn")
var upgrading = false
var heavy_subject_scene = preload("res://heavy_subject.tscn")
var armored_subject_scene = preload("res://armored_subject.tscn")
var frantic_subject_scene = preload("res://frantic_subject.tscn")
var next_ball_upgrade = ""
var calamity_slots = []
var max_calamity_slots = 3
var calamity_index = 0
var calamity_aiming = false
var subjects_killed = 0
var kills_to_level = 7
var spawn_timer = 0.0
var spawn_interval = 2.0
var min_spawn_interval = 0.6
var selected_upgrade_index = -1
var selected_card_bg = null
var elapsed_time = 0.0
var _survival_5_recorded: bool  = false
var _survival_10_recorded: bool = false
var _survival_20_recorded: bool = false
var _elements_used_run: Array   = []
var cyber_shooter_scene = preload("res://cyber_shooter.tscn")
var cyber_shotgun_scene = preload("res://cyber_shotgun.tscn")
var cyber_rifle_scene = preload("res://cyber_rifle.tscn")
var cyber_404_scene = preload("res://cyber_404.tscn")
var boss_bar_canvas = null
var _boss_elem_indicator = null
var boss = null
var boss_defeated = false
var _crate_node = null
var _processor_btn: Button = null
var _hasmen_npc = null
var _nyx_spawned: bool = false
var _nyx_node = null
var _smiler_spawned: bool = false
var _smiler_node = null
var data_collected: int = 0
var total_subjects_killed: int = 0
var _run_start_chips: int = 0
var ally_chip_duration: float = 15.0  # Upgradeable via card (index 23)

# ── RTS / Tactical Mode ───────────────────────────────────────────────────────
var _rts_mode:    bool        = false
var _rts_overlay: CanvasLayer = null

# ── Veri Barı ─────────────────────────────────────────────────────────────────
var _data_current:    float      = 0.0
var _data_max:        float      = 150.0
var _data_bar_canvas: CanvasLayer = null
var _data_bar_fill:   ColorRect   = null
var _data_bar_label:  Label       = null
var _data_particle_canvas: CanvasLayer = null
var _active_particles: int = 0
const _MAX_PARTICLES: int = 20
const _DATA_BAR_POS  := Vector2(1640, 698)
const _DATA_BAR_H    := 14.0
const _DATA_BAR_W    := 272.0

# ── Boss sırası — her bölümde 10. dakikada boss gelir ────────────────────────
const BOSS_SPAWN_TIME: float = 600.0
var _boss_check_index:  int  = 0
var _boss_spawned:      bool = false
var _cyber404_node = null
var _cyber404_spawned: bool = false

func _start_boss_intro() -> void:
	var crate = load("res://crate_intro.gd").new()
	crate.name   = "BossCrate"
	_crate_node  = crate
	add_child(crate)
	crate.landed.connect(_screen_shake)
	crate.boss_emerged.connect(_on_boss_emerged)
	crate.play_intro(Vector2(995, 570))

func _on_boss_emerged() -> void:
	var crate: Node2D = _crate_node
	_crate_node = null
	if not is_instance_valid(crate):
		return
	var spawn_pos: Vector2 = crate.position
	# Sandık solar ve kaybolur
	var tw := create_tween()
	tw.tween_property(crate, "modulate:a", 0.0, 0.30)
	tw.tween_callback(crate.queue_free)
	_spawn_boss_at(spawn_pos)

func _spawn_boss_at(spawn_pos: Vector2) -> void:
	var b = cyber_404_scene.instantiate()
	b.position = spawn_pos
	b.scale    = Vector2(0.4, 0.4)
	add_child(b)
	boss = b
	_cyber404_node = b
	b.get_node("CollisionShape2D").disabled = true

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(b, "position", Vector2(995, 400), 0.75)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(b, "scale", Vector2(1.8, 1.8), 0.75)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished

	_screen_shake()
	if is_instance_valid(b):
		b.get_node("CollisionShape2D").disabled = false
		if b.has_method("_landing_wave"):
			b._landing_wave()
	
func _screen_shake() -> void:
	var camera = get_node("Camera2D")
	var original_pos = camera.offset
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(camera, "offset", Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.05)
	tween.tween_property(camera, "offset", original_pos, 0.05)

func screen_shake_heavy() -> void:
	var camera = get_node("Camera2D")
	var original_pos = camera.offset
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(camera, "offset", Vector2(randf_range(-3, 3), randf_range(-3, 3)), 0.05)
	tween.tween_property(camera, "offset", original_pos, 0.05)

func _screen_shake_small() -> void:
	var camera = get_node("Camera2D")
	var original_pos = camera.offset
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(camera, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)), 0.04)
	tween.tween_property(camera, "offset", original_pos, 0.04)

func show_boss_bar(boss_node: Node2D, boss_name: String = "CYBER 404") -> void:
	boss = boss_node
	boss_bar_canvas = CanvasLayer.new()
	boss_bar_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(boss_bar_canvas)

	var name_label = Label.new()
	name_label.name = "BossName"
	name_label.text = boss_name
	name_label.position = Vector2(760, 20)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_font_override("font", _font_bold)
	name_label.modulate = Color(1, 0.3, 0.3)
	boss_bar_canvas.add_child(name_label)
	
	# Armor bar
	var armor_bg = ColorRect.new()
	armor_bg.name = "ArmorBG"
	armor_bg.size = Vector2(400, 20)
	armor_bg.position = Vector2(760, 50)
	armor_bg.color = Color(0.2, 0.2, 0.2)
	boss_bar_canvas.add_child(armor_bg)
	
	var armor_bar = ColorRect.new()
	armor_bar.name = "ArmorBar"
	armor_bar.size = Vector2(400, 20)
	armor_bar.position = Vector2(760, 50)
	armor_bar.color = Color(0.6, 0.6, 0.6)
	boss_bar_canvas.add_child(armor_bar)
	
	# Health bar
	var health_bg = ColorRect.new()
	health_bg.name = "HealthBG"
	health_bg.size = Vector2(400, 20)
	health_bg.position = Vector2(760, 75)
	health_bg.color = Color(0.2, 0.2, 0.2)
	boss_bar_canvas.add_child(health_bg)
	
	var health_bar = ColorRect.new()
	health_bar.name = "HealthBar"
	health_bar.size = Vector2(400, 20)
	health_bar.position = Vector2(760, 75)
	health_bar.color = Color(0.8, 0.1, 0.1)
	health_bar.visible = false  # Hidden at start
	boss_bar_canvas.add_child(health_bar)

func update_boss_bar(armor: int, health: int, max_armor: int, max_health: int) -> void:
	if boss_bar_canvas == null:
		return
	var armor_bar = boss_bar_canvas.get_node("ArmorBar")
	var health_bar = boss_bar_canvas.get_node("HealthBar")

	if max_armor > 0:
		armor_bar.size.x = 400 * (float(armor) / float(max_armor))

	if armor <= 0 or max_armor == 0:
		armor_bar.visible = false
		health_bar.visible = true
		health_bar.size.x = 400 * (float(health) / float(max_health))

func hide_boss_bar() -> void:
	boss_defeated = true
	if boss_bar_canvas:
		boss_bar_canvas.queue_free()
		boss_bar_canvas = null
	boss = null
	_boss_elem_indicator = null

func _show_cards_unlocked(lv_from: int, lv_to: int) -> void:
	var char_id: String = GameData.selected_character
	if _all_upgrades.is_empty():
		_build_all_upgrades()
	var new_cards: Array = []
	for u in _all_upgrades:
		var ul: int = u.get("min_level", 0)
		if ul > lv_from and ul <= lv_to:
			if u["chars"].is_empty() or char_id in u["chars"]:
				new_cards.append(u)
	if new_cards.is_empty():
		return

	get_tree().paused = true
	var canvas := CanvasLayer.new()
	canvas.layer = 110
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	# ── Arka plan — görseli olduğu gibi kullan ───────────────────────────────
	var bg_tex := TextureRect.new()
	bg_tex.name = "UnlockBg"
	bg_tex.size = Vector2(1920, 1080)
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.texture = load("res://assets/upgradesUnlocked.png")
	canvas.add_child(bg_tex)

	# ── Sayfalı kart gösterimi (sayfa başına max 5) ───────────────────────────
	var char_id2: String = GameData.selected_character
	var char_folder: String = ({"vector": "vectorUpgradeCards", "leila": "leilaUpgradeCards",
		"cyclone": "cycloneUpgradeCards"} as Dictionary).get(char_id2, "vectorUpgradeCards")
	var char_suffix: String = ({"vector": "VectorCard", "leila": "LeilaCard",
		"cyclone": "CycloneCard"} as Dictionary).get(char_id2, "VectorCard")

	const PAGE_SIZE: int = 5
	var total_pages: int = ceili(float(new_cards.size()) / PAGE_SIZE)

	for page in range(total_pages):
		# Önceki sayfanın kartlarını temizle (bg hariç)
		for child in canvas.get_children():
			if child != bg_tex:
				child.queue_free()
		await get_tree().process_frame

		var display_cards: Array = new_cards.slice(page * PAGE_SIZE, min((page + 1) * PAGE_SIZE, new_cards.size()))
		var card_w: float  = 280.0
		var card_h: float  = 400.0
		var gap: float     = 40.0
		var total_w: float = display_cards.size() * card_w + (display_cards.size() - 1) * gap
		var start_x: float = (1920.0 - total_w) / 2.0
		var card_y: float  = 310.0

		for i in display_cards.size():
			var u = display_cards[i]
			var rarity: String = u.get("rarity", "common")
			var tx: float = start_x + i * (card_w + gap)

			var rarity_prefix: String = ({"common": "001_common", "uncommon": "002_uncommon",
				"rare": "003_rare", "epic": "004_epic", "legendary": "005_legendary"} as Dictionary).get(rarity, "001_common")
			var card_filename: String
			if char_id2 == "cyclone" and rarity == "uncommon":
				card_filename = "002_uncommonCyclone.png"
			else:
				card_filename = "%s%s.png" % [rarity_prefix, char_suffix]
			var card_tex: Texture2D = load("res://assets/upgradeCardsLabel/%s/%s" % [char_folder, card_filename])
			var card_sprite := TextureRect.new()
			card_sprite.texture = card_tex
			card_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			card_sprite.size = Vector2(card_w, card_h)
			card_sprite.position = Vector2(tx, card_y)
			# Kart art görseli (card_sprite'dan önce eklenir, altında kalır)
			var _art_path := _get_card_art_path(u, char_id2)
			if _art_path != "" and ResourceLoader.exists(_art_path):
				var art_tex: Texture2D = load(_art_path)
				var art_rect := TextureRect.new()
				art_rect.texture = art_tex
				art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				art_rect.size = Vector2(card_w - 40, 200)
				art_rect.position = Vector2(tx + 20, card_y + 30)
				art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				canvas.add_child(art_rect)

			canvas.add_child(card_sprite)

			var name_panel := Panel.new()
			name_panel.size = Vector2(card_w - 52, 44)
			name_panel.position = Vector2(tx + 26, card_y + card_h - 116)
			name_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			name_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			canvas.add_child(name_panel)

			var name_lbl := Label.new()
			name_lbl.text = u["name"]
			name_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			name_lbl.clip_contents = true
			var _nfs: int = 17
			if u["name"].length() > 14: _nfs = 14
			name_lbl.add_theme_font_size_override("font_size", _nfs)
			name_lbl.add_theme_font_override("font", _font_bold)
			name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			name_panel.add_child(name_lbl)

			var desc_panel := Panel.new()
			desc_panel.size = Vector2(card_w - 52, 80)
			desc_panel.position = Vector2(tx + 26, card_y + card_h - 88)
			desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			desc_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			canvas.add_child(desc_panel)

			var desc_lbl := Label.new()
			desc_lbl.text = u.get("desc", "")
			desc_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			desc_lbl.clip_contents = true
			var _dfs: int = 13
			if u.get("desc", "").length() > 40: _dfs = 11
			if u.get("desc", "").length() > 60: _dfs = 10
			desc_lbl.add_theme_font_size_override("font_size", _dfs)
			desc_lbl.add_theme_font_override("font", _font_regular)
			desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
			desc_panel.add_child(desc_lbl)

		# Sayfa göstergesi (birden fazla sayfa varsa)
		if total_pages > 1:
			var page_lbl := Label.new()
			page_lbl.text = "%d / %d" % [page + 1, total_pages]
			page_lbl.add_theme_font_override("font", _font_regular)
			page_lbl.add_theme_font_size_override("font_size", 14)
			page_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 0.7))
			page_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			page_lbl.size     = Vector2(200, 24)
			page_lbl.position = Vector2((1920 - 200) / 2.0, 750)
			canvas.add_child(page_lbl)

		var hint_lbl := Label.new()
		hint_lbl.text = Lang.t("unlock_hint")
		hint_lbl.add_theme_font_override("font", _font_regular)
		hint_lbl.add_theme_font_size_override("font_size", 16)
		hint_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 0.8))
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.size     = Vector2(900, 30)
		hint_lbl.position = Vector2((1920 - 900) / 2.0, 778)
		canvas.add_child(hint_lbl)

		var btn := Button.new()
		var is_last_page: bool = (page == total_pages - 1)
		btn.text = Lang.t("unlock_continue") if is_last_page else ("SONRAKI  ▶" if Lang.locale == "tr" else "NEXT  ▶")
		btn.add_theme_font_override("font", _font_bold)
		btn.add_theme_font_size_override("font_size", 24)
		btn.size     = Vector2(360, 60)
		btn.position = Vector2((1920 - 360) / 2.0, 812)
		canvas.add_child(btn)

		await btn.pressed

	get_tree().paused = false
	canvas.queue_free()

func _check_survival_milestones(minutes: int) -> void:
	if not _survival_5_recorded and minutes >= 5:
		_survival_5_recorded = true
		GameData.record_survival(5)
	if not _survival_10_recorded and minutes >= 10:
		_survival_10_recorded = true
		GameData.record_survival(10)
	if not _survival_20_recorded and minutes >= 20:
		_survival_20_recorded = true
		GameData.record_survival(20)

func record_element_used(element: String) -> void:
	if element not in _elements_used_run:
		_elements_used_run.append(element)
		if _elements_used_run.size() >= 3:
			GameData.record_run_3element()

func _show_run_end_screen() -> void:
	get_tree().paused = true
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.06, 0.95)
	bg.size  = Vector2(1920, 1080)
	canvas.add_child(bg)

	var minutes := int(elapsed_time / 60)
	var seconds  := int(elapsed_time) % 60

	var title := Label.new()
	title.text = Lang.t("run_end_title")
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_font_override("font", _font_bold)
	title.modulate = Color(0.2, 1.0, 0.6)
	title.position = Vector2(660, 200)
	canvas.add_child(title)

	var stats_text := (Lang.t("run_end_time") + "\n\n" + Lang.t("run_end_enemies") + "\n\n" + Lang.t("run_end_allies")) % [
		minutes, seconds, total_subjects_killed, GameData.rescued_total
	]
	var stats := Label.new()
	stats.text = stats_text
	stats.add_theme_font_size_override("font_size", 28)
	stats.add_theme_font_override("font", _font_bold)
	stats.modulate = Color(0.85, 0.85, 0.9)
	stats.position = Vector2(760, 340)
	canvas.add_child(stats)

	var chips_earned := GameData.chips - _run_start_chips
	var chip_lbl := Label.new()
	chip_lbl.add_theme_font_size_override("font_size", 32)
	chip_lbl.add_theme_font_override("font", _font_bold)
	if chips_earned > 0:
		chip_lbl.text = "+ %d Chip" % chips_earned
		chip_lbl.modulate = Color(0.0, 1.0, 0.8)
	else:
		chip_lbl.text = "Chip kazanılmadı"
		chip_lbl.modulate = Color(0.5, 0.5, 0.6)
	chip_lbl.position = Vector2(760, 520)
	canvas.add_child(chip_lbl)

	var chip_total_lbl := Label.new()
	chip_total_lbl.text = "Toplam: %d Chip" % GameData.chips
	chip_total_lbl.add_theme_font_size_override("font_size", 22)
	chip_total_lbl.add_theme_font_override("font", _font_bold)
	chip_total_lbl.modulate = Color(0.6, 0.6, 0.7)
	chip_total_lbl.position = Vector2(760, 560)
	canvas.add_child(chip_total_lbl)

	var btn := Button.new()
	btn.text = Lang.t("go_continue")
	btn.add_theme_font_size_override("font_size", 26)
	btn.position = Vector2(760, 620)
	btn.size     = Vector2(400, 60)
	canvas.add_child(btn)
	await btn.pressed
	canvas.queue_free()
	get_tree().paused = false
	var _lv_now: int = GameData.get_level(GameData.selected_character)
	if _lv_now > _run_start_level:
		await _show_cards_unlocked(_run_start_level, _lv_now)
	get_tree().change_scene_to_file("res://character_select.tscn")

func update_boss_element(elem: String) -> void:
	if boss_bar_canvas == null:
		return
	if _boss_elem_indicator == null:
		_boss_elem_indicator = load("res://elem_indicator.gd").new()
		# Can barının (y=75, yükseklik=20) hemen altına, soldan 9px içeride
		_boss_elem_indicator.position = Vector2(769, 107)
		boss_bar_canvas.add_child(_boss_elem_indicator)
	_boss_elem_indicator.set_element(elem)

func clear_boss_element() -> void:
	if _boss_elem_indicator != null:
		_boss_elem_indicator.clear_element()

func _on_card_selected(index: int, _canvas: CanvasLayer, bg: TextureRect) -> void:
	selected_upgrade_index = index
	if selected_card_bg:
		selected_card_bg.modulate = Color(1.0, 1.0, 1.0)
	selected_card_bg = bg
	bg.modulate = Color(1.3, 1.3, 1.6)

func _on_confirm(canvas: CanvasLayer) -> void:
	if selected_upgrade_index == -1:
		return
	_on_upgrade_selected(selected_upgrade_index, canvas)
	selected_upgrade_index = -1
	selected_card_bg = null

func _on_skip(canvas: CanvasLayer) -> void:
	canvas.queue_free()
	upgrading = false
	get_tree().paused = false
	level += 1
	update_ui()
	selected_upgrade_index = -1
	selected_card_bg = null

func _show_hasmen_selection() -> void:
	var canvas = CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	# ── BACKGROUND (koyu cyberpunk zemin) ────────────────────────────────
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.06, 0.97)
	bg.size = Vector2(1920, 1080)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	# ── MR. HASMEN — character visual (right area) ──────────────────────────
	var hasmen_img = TextureRect.new()
	hasmen_img.texture = load("res://assets/mrHasmen.png")
	hasmen_img.size = Vector2(580, 900)
	hasmen_img.position = Vector2(1310, 160)
	hasmen_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hasmen_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hasmen_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hasmen_img)

	# Name label — above visual, centered
	var hasmen_label = Label.new()
	hasmen_label.text = "MR. HASMEN"
	hasmen_label.size = Vector2(580, 40)
	hasmen_label.position = Vector2(1310, 108)
	hasmen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hasmen_label.add_theme_font_size_override("font_size", 26)
	hasmen_label.add_theme_font_override("font", _font_bold)
	hasmen_label.add_theme_color_override("font_color", Color(1, 0.18, 0.58, 1))
	canvas.add_child(hasmen_label)

	# ── VERTICAL DIVIDER (card area | Hasmen area) ──────────────────────────
	var divider = ColorRect.new()
	divider.color = Color(0, 0.72, 0.82, 0.32)
	divider.size = Vector2(2, 960)
	divider.position = Vector2(797, 60)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(divider)

	# ── SPEECH BUBBLE — body ────────────────────────────────────────────────
	var bubble = Panel.new()
	bubble.size = Vector2(458, 196)
	bubble.position = Vector2(820, 64)
	var bubble_style = StyleBoxFlat.new()
	bubble_style.bg_color = Color(0.05, 0.05, 0.14, 0.97)
	bubble_style.set_border_width_all(2)
	bubble_style.border_color = Color(0, 0.92, 1, 1)
	bubble_style.set_corner_radius_all(10)
	bubble_style.shadow_color = Color(0, 0.92, 1, 0.35)
	bubble_style.shadow_size = 10
	bubble.add_theme_stylebox_override("panel", bubble_style)
	canvas.add_child(bubble)

	# Tail — outer (cyan border, pointing toward Mr. Hasmen)
	var tail_outer = ColorRect.new()
	tail_outer.color = Color(0, 0.92, 1, 1)
	tail_outer.size = Vector2(22, 22)
	tail_outer.position = Vector2(1270, 151)
	tail_outer.rotation_degrees = 45.0
	tail_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tail_outer)

	# Tail — inner (dark fill, creates border effect)
	var tail_inner = ColorRect.new()
	tail_inner.color = Color(0.05, 0.05, 0.14, 0.97)
	tail_inner.size = Vector2(16, 16)
	tail_inner.position = Vector2(1274, 155)
	tail_inner.rotation_degrees = 45.0
	tail_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tail_inner)

	# Speech text
	var dialog = Label.new()
	dialog.text = "Hey Vec, let me make you look good!\nPick one of these and benefit from\nthe gifts of technology !!!!!"
	dialog.size = Vector2(426, 180)
	dialog.position = Vector2(836, 78)
	dialog.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialog.add_theme_font_size_override("font_size", 18)
	dialog.add_theme_font_override("font", _font_regular)
	dialog.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 1.0))
	canvas.add_child(dialog)

	# ── CARD SECTION HEADER ─────────────────────────────────────────────────
	var section_label = Label.new()
	section_label.text = Lang.t("ui_avail_upgrades")
	section_label.position = Vector2(50, 388)
	section_label.add_theme_font_size_override("font_size", 18)
	section_label.add_theme_font_override("font", _font_bold)
	section_label.add_theme_color_override("font_color", Color(0, 0.88, 1, 0.72))
	canvas.add_child(section_label)

	# ── KART 1: Synergy Protocol (aktif, cyan neon border) ────────────────
	var card1_glow = ColorRect.new()
	card1_glow.color = Color(0, 0.82, 0.92, 0.75)
	card1_glow.size = Vector2(704, 104)
	card1_glow.position = Vector2(48, 428)
	card1_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card1_glow)

	var card1 = ColorRect.new()
	card1.color = Color(0.06, 0.08, 0.18)
	card1.size = Vector2(700, 100)
	card1.position = Vector2(50, 430)
	card1.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(card1)

	var title1 = Label.new()
	title1.text = "Synergy Protocol"
	title1.position = Vector2(65, 440)
	title1.add_theme_font_size_override("font_size", 20)
	title1.add_theme_font_override("font", _font_bold)
	title1.add_theme_color_override("font_color", Color(0, 0.95, 1, 1))
	canvas.add_child(title1)

	var desc1 = Label.new()
	desc1.text = "An 'ITY RE-Processor device' is airdropped onto the field."
	desc1.size = Vector2(660, 50)
	desc1.position = Vector2(65, 472)
	desc1.add_theme_font_size_override("font_size", 15)
	desc1.add_theme_font_override("font", _font_regular)
	desc1.add_theme_color_override("font_color", Color(0.70, 0.75, 0.85))
	canvas.add_child(desc1)

	card1.mouse_entered.connect(func():
		card1.color = Color(0.1, 0.15, 0.28)
		card1_glow.color = Color(0, 1, 1, 1)
	)
	card1.mouse_exited.connect(func():
		card1.color = Color(0.06, 0.08, 0.18)
		card1_glow.color = Color(0, 0.82, 0.92, 0.75)
	)
	card1.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			canvas.queue_free()
			get_tree().paused = false
			if get_node("Player").character_type == "leila":
				_activate_fusion_zone()
			_spawn_hasmen_entrance()
	)

	# ── KART 2: ??? (kilitli, gri) ───────────────────────────────────────
	var card2_glow = ColorRect.new()
	card2_glow.color = Color(0.35, 0.35, 0.42, 0.55)
	card2_glow.size = Vector2(704, 104)
	card2_glow.position = Vector2(48, 558)
	card2_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card2_glow)

	var card2 = ColorRect.new()
	card2.color = Color(0.04, 0.04, 0.1)
	card2.size = Vector2(700, 100)
	card2.position = Vector2(50, 560)
	card2.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(card2)

	var title2 = Label.new()
	title2.text = "???????????????????"
	title2.position = Vector2(65, 600)
	title2.add_theme_font_size_override("font_size", 20)
	title2.add_theme_font_override("font", _font_regular)
	title2.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	canvas.add_child(title2)

	# ── KART 3: ??? (kilitli, gri) ───────────────────────────────────────
	var card3_glow = ColorRect.new()
	card3_glow.color = Color(0.35, 0.35, 0.42, 0.55)
	card3_glow.size = Vector2(704, 104)
	card3_glow.position = Vector2(48, 688)
	card3_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(card3_glow)

	var card3 = ColorRect.new()
	card3.color = Color(0.04, 0.04, 0.1)
	card3.size = Vector2(700, 100)
	card3.position = Vector2(50, 690)
	card3.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(card3)

	var title3 = Label.new()
	title3.text = "???????????????????"
	title3.position = Vector2(65, 730)
	title3.add_theme_font_size_override("font_size", 20)
	title3.add_theme_font_override("font", _font_regular)
	title3.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	canvas.add_child(title3)

func _activate_fusion_zone() -> void:
	var fusion_zone = get_tree().get_first_node_in_group("fusion_zone")
	var processor_sprite = get_node("ProcessorSprite")

	if fusion_zone and processor_sprite:
		fusion_zone.visible = true
		fusion_zone.set_physics_process(true)

		# Landing animation
		var start_y = -150
		var end_pos = processor_sprite.position
		processor_sprite.position.y = start_y

		var tween = create_tween()
		tween.tween_property(processor_sprite, "position:y", end_pos.y, 2.0)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		# UI toggle butonu oluştur (FusionEnergyBar'ın altında)
		_processor_btn = Button.new()
		_processor_btn.name = "BtnProcessor"
		_processor_btn.offset_left   = 1640.0
		_processor_btn.offset_top    = 460.0
		_processor_btn.offset_right  = 1912.0
		_processor_btn.offset_bottom = 488.0
		_processor_btn.add_theme_font_override("font", _font_bold)
		_processor_btn.add_theme_font_size_override("font_size", 12)
		_processor_btn.pressed.connect(_on_processor_toggle)
		$UI.add_child(_processor_btn)
		_update_processor_btn()

func _on_processor_toggle() -> void:
	var fusion_zone = get_tree().get_first_node_in_group("fusion_zone")
	if fusion_zone:
		fusion_zone.toggle_active()
	_update_processor_btn()

func _update_processor_btn() -> void:
	if _processor_btn == null:
		return
	var fusion_zone = get_tree().get_first_node_in_group("fusion_zone")
	var active: bool = fusion_zone.is_active if fusion_zone else false
	if active:
		_processor_btn.text = "⚙  ITY PROCESSOR   ■ ON"
		_processor_btn.add_theme_color_override("font_color",         Color(0.0, 0.95, 1.0))
		_processor_btn.add_theme_color_override("font_hover_color",   Color(0.4, 1.0,  1.0))
		_processor_btn.add_theme_color_override("font_pressed_color", Color(0.0, 0.7,  0.8))
	else:
		_processor_btn.text = "⚙  ITY PROCESSOR   □ OFF"
		_processor_btn.add_theme_color_override("font_color",         Color(0.45, 0.45, 0.50))
		_processor_btn.add_theme_color_override("font_hover_color",   Color(0.65, 0.65, 0.70))
		_processor_btn.add_theme_color_override("font_pressed_color", Color(0.30, 0.30, 0.35))

func _spawn_section_boss() -> void:
	match _boss_check_index - 1:
		0:  # Bölüm 1 — Smiler
			if not _smiler_spawned:
				_smiler_spawned = true
				_spawn_smiler()
		1:  # Bölüm 2 — Cyber404
			if not _cyber404_spawned and _crate_node == null:
				_cyber404_spawned = true
				_start_boss_intro()
		2:  # Bölüm 3 — Nyx
			if not _nyx_spawned:
				_nyx_spawned = true
				_spawn_nyx()

func _spawn_nyx() -> void:
	var nyx = load("res://nyx_09.gd").new()
	nyx.name   = "Nyx09"
	_nyx_node  = nyx
	add_child(nyx)
	nyx.landed.connect(_on_nyx_landed)
	nyx.play_entry(Vector2(995, 380))

func _spawn_smiler() -> void:
	var smiler = load("res://s_miler_79.gd").new()
	smiler.name = "SMiler79"
	_smiler_node = smiler
	add_child(smiler)
	smiler.landed.connect(_on_smiler_landed)
	smiler.play_entry(Vector2(995, 500))

func _on_smiler_landed() -> void:
	# Sahayı temizle — normal düşmanları siler
	var subjects := get_tree().get_nodes_in_group("subjects")
	var delay    := 0.0
	for s in subjects:
		if not is_instance_valid(s): continue
		if s == _smiler_node:        continue
		_zap_and_kill(s, delay)
		delay += 0.06
	spawn_interval = 25.0   # S-Miler sırasında seyrek spawn

func _on_nyx_landed() -> void:
	var subjects := get_tree().get_nodes_in_group("subjects")
	var delay    := 0.0
	for s in subjects:
		if not is_instance_valid(s): continue
		if s == _nyx_node:           continue
		_zap_and_kill(s, delay)
		delay += 0.06
	spawn_interval = 20.0

func _zap_and_kill(s: Node2D, delay: float) -> void:
	if not is_instance_valid(s): return
	s.set_physics_process(false)
	if s.has_node("CollisionShape2D"):
		s.get_node("CollisionShape2D").set_deferred("disabled", true)

	var tw := s.create_tween()
	tw.tween_interval(delay)
	# Uc hizli elektrik parlamasi
	for _i in 3:
		tw.tween_property(s, "modulate", Color(2.5, 2.5, 0.2, 1.0), 0.06)
		tw.tween_property(s, "modulate", Color(1.0, 1.0, 1.0, 1.0),  0.05)
	# Solarken kaybol
	tw.tween_property(s, "modulate", Color(1.5, 1.8, 0.1, 0.0), 0.22)
	tw.tween_callback(func():
		if is_instance_valid(s): s.queue_free()
	)

	# Elektrik kivircima efekti — delay sonra spawn
	var ZapScript = load("res://zap_effect.gd")
	var zap := Node2D.new()
	zap.set_script(ZapScript)
	zap.global_position = s.global_position
	add_child(zap)
	if delay > 0.001:
		zap.modulate.a = 0.0
		var ztw := zap.create_tween()
		ztw.tween_interval(delay)
		ztw.tween_property(zap, "modulate:a", 1.0, 0.01)

func _spawn_hasmen_entrance() -> void:
	if _hasmen_npc != null:
		return
	var npc = load("res://hasmen_npc.gd").new()
	npc.name  = "HasmenNPC"
	_hasmen_npc = npc
	add_child(npc)
	# ── Koordinatları sahana göre ayarla ──────────────────────────────────
	# start_pos : güney girişi (ekran dışından gelir)
	# mid_pos   : kuzey koridoru sonu (dönüş noktası)
	# chair_pos : sandalye — doğuya bakıyor, oyunu izliyor
	npc.play_entrance(
		Vector2(325, 1260),   # giriş — güney (ekran altı)
		Vector2(325, 865),    # kuzey sonu
		Vector2(250, 855)     # sandalye
	)

func _ready() -> void:
	GameData.rescued_total = 0
	_player_node = get_node("Player")
	_setup_hex_shield()

	var menu_music := get_tree().root.get_node_or_null("MenuMusic")
	if menu_music:
		menu_music.queue_free()

	var music := AudioStreamPlayer.new()
	music.stream        = _gameplay_music_stream
	music.volume_db     = -8.0
	music.bus           = "Music"
	music.autoplay      = true
	music.process_mode  = Node.PROCESS_MODE_ALWAYS
	music.get_stream().set("loop", true)
	add_child(music)
	# UI sınırında görünmez duvar — düşmanların UI alanına girmesini engeller
	var wall := StaticBody2D.new()
	wall.name = "UIWall"
	var wall_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20.0, 1080.0)
	wall_shape.shape = rect
	wall.add_child(wall_shape)
	wall.position = Vector2(360.0, 540.0)
	add_child(wall)

	# Karakter bazlı başlangıç değerleri
	var char_type: String = get_node("Player").character_type
	var _shop_hp: int    = GameData.get_shop_hp_bonus()
	var _shop_arm: int   = GameData.get_shop_armor_bonus()
	var _p_node := get_node("Player")
	_p_node.max_dash_charges += GameData.get_shop_dash_bonus()
	_p_node.dash_charges = _p_node.max_dash_charges
	if char_type == "vector":
		player_hp        = 40 + _shop_hp
		player_max_hp    = 40 + _shop_hp
		player_armor     = 20 + _shop_arm
		player_armor_cap = 20 + _shop_arm
		player_max_armor = 20 + _shop_arm
		_update_hex_shield()
	else:
		if _shop_hp > 0:
			player_hp     += _shop_hp
			player_max_hp += _shop_hp

	# Yeni sol üst HUD bar'ları şimdilik sadece Vector'da hazır
	if char_type == "vector":
		$UI/IntegrityBar.visible = false
		$UI/HealthBar2.visible = true
	else:
		$UI/IntegrityBar.visible = true
		$UI/HealthBar2.visible = false
		$UI/MomentumBar.visible = false

	$UI/BtnPause.pressed.connect(_show_pause_menu)
	$UI/FusionEnergyBar.max_value = 50
	$UI/FusionEnergyBar.value = 0
	# Fusion Zone şimdilik tüm karakterler için kapalı (ITY 2'ye ertelendi)
	var _fz := get_tree().get_first_node_in_group("fusion_zone")
	if _fz:
		_fz.visible = false
		_fz.set_physics_process(false)
	var _ps := get_node_or_null("ProcessorSprite")
	if _ps:
		_ps.visible = false
	$UI/FusionEnergyBar.visible = false
	_setup_data_bar()
	_setup_auto_toggle()
	_setup_neon_sign()
	_setup_armor_bar()
	max_calamity_slots = 3 + GameData.get_shop_calamity_slot_bonus()
	_setup_frost_barrier_ui()
	_setup_core_panel()
	_setup_low_hp_vignette()
	update_ui()
	_update_armor_ui()
	_run_start_level = GameData.get_level(GameData.selected_character)
	_run_start_chips = GameData.chips
	var _cal_start := GameData.get_shop_start_calamity_count()
	if _cal_start > 0:
		var _cal_pool := ["⚡", "🔥", "🌀", "❄️", "💧", "☠️"]
		_cal_pool.shuffle()
		for _ci in range(min(_cal_start, max_calamity_slots)):
			calamity_slots.append(_cal_pool[_ci])
	$UI/CalamityCircle.visible = false

	await get_tree().process_frame
	_spawn_hasmen_entrance()
	


func update_ui() -> void:
	$UI/LabelLevel.text = Lang.t("ui_level") + str(level)
	$UI/IntegrityBar.max_value = player_max_hp
	$UI/IntegrityBar.value = player_hp
	var _ui_p := get_node("Player")
	$UI/LabelBalls.text = Lang.t("ui_balls") + str(_ui_p.orbit_balls.size()) + " / " + str(_ui_p.MAX_ORBIT)
	$UI/IntegrityBar.max_value = player_max_hp
	$UI/IntegrityBar.value = player_hp
	if player_armor > 0:
		$UI/IntegrityBar/LabelIntegrity.text = "♥ " + str(player_hp) + "/" + str(player_max_hp) + "   ⬡ " + str(player_armor)
	else:
		$UI/IntegrityBar/LabelIntegrity.text = "♥  " + str(player_hp) + " / " + str(player_max_hp)

	# ── Yeni sol üst HUD: Health bar ────────────────────────────────────────
	$UI/HealthBar2/Fill.max_value = player_max_hp
	$UI/HealthBar2/Fill.value = player_hp
	if player_armor > 0:
		$UI/HealthBar2/Label.text = str(player_hp) + "/" + str(player_max_hp) + "  ⬡" + str(player_armor)
	else:
		$UI/HealthBar2/Label.text = str(player_hp) + " / " + str(player_max_hp)

	# Aktif upgrade'ler
	var upgrade_text = Lang.t("ui_upgrades_header") + "\n"
	if get_node("Player").SPEED > 300:
		upgrade_text += Lang.t("ui_upgrades_speed") + "\n"
	if get_node("Player").chain_length > 220:
		upgrade_text += Lang.t("ui_upgrades_chain") + "\n"
	if get_node("Player").has_next_one:
		upgrade_text += Lang.t("ui_upgrades_next") + "\n"
	if upgrade_text == Lang.t("ui_upgrades_header") + "\n":
		upgrade_text += Lang.t("ui_upgrades_none")
	$UI/LabelUpgrades.text = upgrade_text

	var catch_lbl = get_node_or_null("UI/LabelCatch")
	if catch_lbl:
		catch_lbl.visible = false

	# Calamity slots — tıklamalı hücreler (_calamity_cells) kullanılıyor, Label sadece başlık
	$UI/LabelCalamity.text = Lang.t("ui_calamity_header")
	_update_calamity_cells()
	_update_processor_btn()

func subject_died(xp_reward: int = 1, death_pos: Vector2 = Vector2.ZERO, etype: String = "subject") -> void:
	subjects_killed += 1
	total_subjects_killed += 1
	var _xp := int(float(xp_reward) * GameData.get_shop_xp_mult())
	GameData.add_xp(GameData.selected_character, _xp)
	GameData.record_kill(etype)
	GameData.record_char_kill(GameData.selected_character)

	var _rip := get_node_or_null("Player")
	if _rip and _rip.get("has_rogues_instinct") and _rip.has_rogues_instinct:
		player_hp = min(player_hp + 1, player_max_hp)
	update_ui()
	# Level sayacı boss kontrolü için devam ediyor
	if subjects_killed >= kills_to_level:
		subjects_killed = 0
		kills_to_level = int(kills_to_level * 1.3)
		spawn_interval = max(spawn_interval - 0.1, min_spawn_interval)
	# Veri parçacıkları: hasar miktarına göre 3-7 parçacık
	var particle_count := clampi(xp_reward + 2, 3, 7)
	_spawn_data_particles(death_pos, float(xp_reward) * 10.0, particle_count)

func _get_hp_bar_rect() -> Rect2:
	# Vector: yeni sol üst Health bar'ın iç dolgu alanı (UI CanvasLayer'a göre mutlak)
	if get_node("Player").character_type == "vector":
		var _fill: Control = $UI/HealthBar2/Fill
		return Rect2($UI/HealthBar2.position + _fill.position, _fill.size)
	# Diğer karakterler: eski sağ panel bar'ı
	var integrity_bar: ProgressBar = $UI/IntegrityBar
	return Rect2(integrity_bar.position, integrity_bar.size)

func _setup_armor_bar() -> void:
	# Can barının üzerine binen gri zırh overlay'i (Armor, canın üzerinde gri katman)
	var _hp_rect := _get_hp_bar_rect()
	var ab := ColorRect.new()
	ab.name = "ArmorOverlay"
	ab.color = Color(0.55, 0.55, 0.6, 0.88)
	ab.size = Vector2(0.0, _hp_rect.size.y)
	ab.position = _hp_rect.position  # sola hizalı, genişlik 0 başlangıçta
	ab.visible = false
	ab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# HP barının üstüne çıksın
	ab.z_index = 5
	$UI.add_child(ab)
	_armor_bar = ab
	# Label: HP barının üzerinde göster
	var lbl := Label.new()
	lbl.name = "LabelArmor"
	lbl.size = Vector2(_hp_rect.size.x, _hp_rect.size.y)
	lbl.position = _hp_rect.position
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _font_bold)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = ab.z_index + 1
	lbl.visible = false
	$UI.add_child(lbl)
	_armor_label = lbl

func _setup_frost_barrier_ui() -> void:
	var integrity_bar: ProgressBar = $UI/IntegrityBar
	var fb := ColorRect.new()
	fb.name = "FrostBarrierOverlay"
	fb.color = Color(0.4, 0.85, 1.0, 0.75)
	fb.size = Vector2(0.0, integrity_bar.size.y)
	fb.position = integrity_bar.position
	fb.visible = false
	fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fb.z_index = integrity_bar.z_index + 2
	$UI.add_child(fb)
	_frost_barrier_bar = fb
	var lbl2 := Label.new()
	lbl2.name = "LabelFrostBarrier"
	lbl2.size = Vector2(integrity_bar.size.x, integrity_bar.size.y)
	lbl2.position = integrity_bar.position
	lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl2.add_theme_font_override("font", _font_bold)
	lbl2.add_theme_font_size_override("font_size", 10)
	lbl2.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl2.z_index = fb.z_index + 1
	lbl2.visible = false
	$UI.add_child(lbl2)
	_frost_barrier_label = lbl2

func _update_frost_barrier_ui() -> void:
	if _frost_barrier_bar == null: return
	var _p := get_node_or_null("Player")
	var hp: int = _p.frost_barrier_hp if (_p and _p.get("frost_barrier_hp")) else 0
	if hp <= 0:
		_frost_barrier_bar.visible = false
		_frost_barrier_label.visible = false
		return
	var integrity_bar: ProgressBar = $UI/IntegrityBar
	var bar_w: float = integrity_bar.size.x
	var bar_h: float = integrity_bar.size.y
	var ratio: float = clampf(float(hp) / 20.0, 0.0, 1.0)
	_frost_barrier_bar.size = Vector2(bar_w * ratio, bar_h)
	_frost_barrier_bar.position = integrity_bar.position
	_frost_barrier_bar.visible = true
	_frost_barrier_label.visible = false

func _update_armor_ui() -> void:
	if _armor_bar == null:
		return
	var _hp_rect := _get_hp_bar_rect()
	if player_max_armor <= 0 or player_armor <= 0:
		_armor_bar.visible = false
		_armor_label.visible = false
		_update_hex_shield()
		return
	# Armor, max_hp üzerinden oran hesaplanır
	# Örnek: max_hp=40, armor=20 → oran=0.5 → barın %50'si gri
	var bar_w: float = _hp_rect.size.x
	var bar_h: float = _hp_rect.size.y
	var ratio: float = clampf(float(player_armor) / float(max(player_max_hp, 1)), 0.0, 1.0)
	var overlay_w: float = bar_w * ratio
	# Gri overlay soldan başlar (armor, canın üzerinde oturur)
	(_armor_bar as ColorRect).size = Vector2(overlay_w, bar_h)
	(_armor_bar as ColorRect).position = _hp_rect.position
	_armor_bar.visible = true
	_armor_label.visible = false
	$UI/IntegrityBar/LabelIntegrity.text = "♥ " + str(player_hp) + "/" + str(player_max_hp) + "   ⬡ " + str(player_armor)
	_update_hex_shield()

func heal_player(amount: int) -> void:
	player_hp = min(player_hp + amount, player_max_hp)
	update_ui()

func gain_armor(amount: int) -> void:
	var mult := _armor_gain_boost
	var p := get_node_or_null("Player")
	var hp_ratio: float = float(player_hp) / float(max(player_max_hp, 1))
	# Pain Converter: HP %50 altındaysa +%50 Armor Gain
	if p and p.get("has_pain_converter") != null and p.has_pain_converter:
		if hp_ratio < 0.5:
			mult *= 1.5
	# Iron Constitution / Overclocked Reflex / Risk Engine kümülatif çarpanı
	if p:
		mult *= p.armor_gain_mult
	# Glass Engine: HP < %50 → +%50, HP > %70 → -%30
	if p and p.get("has_glass_engine") != null and p.has_glass_engine:
		if hp_ratio < 0.5:
			mult *= 1.5
		elif hp_ratio > 0.7:
			mult *= 0.7
	# Adrenal Armor System: HP < %50 → +%30
	if p and p.get("has_adrenal_armor") != null and p.has_adrenal_armor:
		if hp_ratio < 0.5:
			mult *= 1.3
	# Momentum Cascade: 10+ momentum → Armor Gain ×1.5
	if p and p.get("has_momentum_cascade") != null and p.has_momentum_cascade:
		if p.momentum_stacks >= p.momentum_cascade_threshold:
			mult *= 1.5
	var boosted := int(float(amount) * mult)
	# Armor Rush: Momentum eşiğin üzerindeyse +1 bonus Armor (kalıcı değil, anlık kontrol)
	if boosted > 0 and p and p.get("has_armor_rush") and p.has_armor_rush:
		if p.momentum_stacks >= p.armor_rush_threshold:
			boosted += 1
	player_armor = min(player_armor + boosted, player_armor_cap)
	player_max_armor = max(player_max_armor, player_armor_cap)
	_update_armor_ui()
	# Armor/Bulwark Core: kazanım anında altın shield flash
	if is_instance_valid(_player_node):
		var _spr := _player_node.get_node_or_null("VectorSprite")
		if not _spr:
			_spr = _player_node.get_node_or_null("LeilaSprite")
		if not _spr:
			_spr = _player_node.get_node_or_null("CycloneSprite")
		if is_instance_valid(_spr):
			var _tw := create_tween()
			_tw.tween_property(_spr, "modulate", Color(1.0, 0.9, 0.3, 1.0), 0.06)
			_tw.tween_property(_spr, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	_update_hex_shield()
	if player_armor < player_armor_cap:
		_spawn_hex_particles()
		_armor_was_full = false
	elif player_armor >= player_armor_cap and is_instance_valid(_player_node):
		if not _armor_was_full:
			_armor_was_full = true
			_spawn_armor_full_ring(_player_node.global_position)


func _spawn_armor_full_ring(pos: Vector2) -> void:
	var line := Line2D.new()
	line.top_level = true
	line.global_position = pos
	line.width = 3.0
	line.default_color = Color(1.0, 0.85, 0.2, 0.9)
	line.z_index = 15
	var pts := PackedVector2Array()
	var segs := 28
	for i in range(segs + 1):
		var angle := i * TAU / segs
		pts.append(Vector2(cos(angle), sin(angle)) * 12.0)
	line.points = pts
	add_child(line)
	var tw := line.create_tween()
	tw.set_parallel(true)
	tw.tween_property(line, "scale", Vector2(7.5, 7.5), 0.38)
	tw.tween_property(line, "modulate:a", 0.0, 0.38)
	tw.set_parallel(false)
	tw.tween_callback(line.queue_free)

func _setup_hex_shield() -> void:
	for i in range(1, 6):
		_hex_textures_east.append(load("res://assets/VFX/hexShieldWest/%d.png" % i))
		_hex_textures_west.append(load("res://assets/VFX/hexShieldEast/%d.png" % i))
	for i in range(6, 11):
		_hex_anim_textures_east.append(load("res://assets/VFX/hexShieldWest/%d.png" % i))
		_hex_anim_textures_west.append(load("res://assets/VFX/hexShieldEast/%d.png" % i))
	_hex_east = Sprite2D.new()
	_hex_east.centered = true
	_hex_east.visible = false
	_hex_east.z_index = 3
	_hex_east.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hex_east.position = Vector2(9, 0)
	_player_node.add_child(_hex_east)
	_hex_west = Sprite2D.new()
	_hex_west.centered = true
	_hex_west.visible = false
	_hex_west.z_index = 3
	_hex_west.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hex_west.position = Vector2(-9, 0)
	_player_node.add_child(_hex_west)
	_hex_anim_timer = Timer.new()
	_hex_anim_timer.wait_time = 0.1
	_hex_anim_timer.autostart = false
	_hex_anim_timer.timeout.connect(_on_hex_anim_tick)
	add_child(_hex_anim_timer)
	# Pulse tween — sürekli döner
	_hex_pulse_loop()

func _update_hex_shield() -> void:
	if not is_instance_valid(_hex_east) or not is_instance_valid(_hex_west):
		return
	if player_armor <= 0 or player_armor_cap <= 0:
		_hex_east.visible = false
		_hex_west.visible = false
		_hex_anim_timer.stop()
		return
	_hex_east.visible = true
	_hex_west.visible = true
	if player_armor >= 30:
		# Animasyon modu — timer çalışıyorsa dokunma, yoksa başlat
		if _hex_anim_timer.is_stopped():
			_hex_anim_frame = 0
			_hex_anim_timer.start()
	else:
		_hex_anim_timer.stop()
		var frame_idx: int = clamp(player_armor / 6 - 1, 0, 4)
		_hex_east.texture = _hex_textures_east[frame_idx]
		_hex_west.texture = _hex_textures_west[frame_idx]

func _on_hex_anim_tick() -> void:
	if player_armor < 30:
		_hex_anim_timer.stop()
		_update_hex_shield()
		return
	_hex_east.texture = _hex_anim_textures_east[_hex_anim_frame]
	_hex_west.texture = _hex_anim_textures_west[_hex_anim_frame]
	_hex_anim_frame = (_hex_anim_frame + 1) % 5

func _hex_pulse_loop() -> void:
	if not is_instance_valid(_hex_east): return
	for spr in [_hex_east, _hex_west]:
		var tw := create_tween().set_loops()
		tw.tween_property(spr, "scale", Vector2(1.06, 1.06), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(spr, "scale", Vector2(1.0,  1.0),  0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _hex_shield_hit_flash() -> void:
	if not is_instance_valid(_hex_east): return
	for spr in [_hex_east, _hex_west]:
		var tw := create_tween()
		tw.tween_property(spr, "modulate", Color(1.8, 1.8, 2.5, 1.0), 0.05)
		tw.tween_property(spr, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25).set_trans(Tween.TRANS_SINE)

func _spawn_hex_particles() -> void:
	if not is_instance_valid(_player_node): return
	var count := 5
	for i in range(count):
		var angle := randf() * TAU
		var dist: float = randf_range(55.0, 100.0)
		var offset := Vector2(cos(angle), sin(angle)) * dist
		var start_pos: Vector2 = _player_node.global_position + offset
		var dot := ColorRect.new()
		dot.size = Vector2(4, 4)
		dot.color = Color(0.3, 0.65, 1.0, 1.0)
		dot.z_index = 10
		# Player'ın child'ı olarak eklenir — player hareket edince hedef de kayar
		_player_node.add_child(dot)
		# Başlangıç pozisyonu player'a göre relative
		# İçten dışa: merkezden başlayıp dışa uçar
		dot.position = -dot.size * 0.5
		var duration: float = randf_range(0.25, 0.45)
		var tw := create_tween()
		tw.tween_property(dot, "position", offset - dot.size * 0.5, duration).set_ease(Tween.EASE_OUT)
		tw.tween_callback(dot.queue_free)

func _spawn_emergency_vfx() -> void:
	if not is_instance_valid(_player_node): return
	# Aktivasyon patlaması
	var p := CPUParticles2D.new()
	p.top_level = true
	p.global_position = _player_node.global_position
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 24
	p.lifetime = 0.5
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 180.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = Color(0.9, 0.1, 0.1)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)
	# 10s kırmızı kriz aura — sprite'ı pulse et
	var _spr := _player_node.get_node_or_null("VectorSprite")
	if not _spr:
		_spr = _player_node.get_node_or_null("LeilaSprite")
	if not _spr:
		_spr = _player_node.get_node_or_null("CycloneSprite")
	if not is_instance_valid(_spr): return
	var _aura_tw := create_tween().set_loops(10)
	_aura_tw.tween_property(_spr, "modulate", Color(1.0, 0.35, 0.35, 1.0), 0.5)
	_aura_tw.tween_property(_spr, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

func _get_ball_core_type(ball) -> String:
	if not is_instance_valid(ball): return "normal"
	var _ft = ball.get("fusion_type")
	if ball.get("is_fused") and _ft != null and _ft != "":
		return "fused:" + str(_ft)
	if ball.get("can_armor"):      return "armor"
	if ball.get("can_anchor"):     return "anchor"
	if ball.get("can_crusher"):    return "crusher"
	if ball.get("can_kinetic"):    return "kinetic"
	if ball.get("can_bulwark"):    return "bulwark"
	if ball.get("can_siege"):      return "siege"
	if ball.get("can_bloodbound"): return "bloodbound"
	if ball.get("can_tempered"):   return "tempered"
	if ball.get("can_arc"):        return "arc"
	if ball.get("can_plasma"):     return "plasma"
	if ball.get("can_steam"):      return "steam"
	if ball.get("can_echo"):       return "echo"
	if ball.get("can_orbit"):      return "orbit"
	if ball.get("can_scatter"):    return "scatter"
	if ball.get("can_catalyst"):   return "catalyst"
	if ball.get("can_voltaic"):         return "voltaic"
	if ball.get("can_echo_resonance"):  return "echo_resonance_core"
	if ball.get("can_electric"):   return "electric"
	if ball.get("can_pierce"):     return "pierce"
	if ball.get("can_split"):      return "split"
	if ball.get("can_cryo"):       return "cryo"
	if ball.get("can_glitch"):     return "glitch"
	if ball.get("can_water"):      return "water"
	if ball.get("can_fire"):       return "fire"
	if ball.get("can_leech"):      return "leech"
	if ball.get("is_mimic"):       return "mimic"
	if ball.get("is_inner_core") and ball.is_inner_core:
		return ball.get("inner_core_type") if ball.get("inner_core_type") else "normal"
	return "normal"

const _FUSED_FOLDER_MAP: Dictionary = {
	"conductive":       "conductive",
	"cryostatic":       "cryoStatic",
	"electric_split":   "electrifiedSplit",
	"firework":         "fireWork",
	"frozen_split":     "frozenSplit",
	"glacier_spike":    "glacierSpike",
	"glitched_split":   "glitchedSplit",
	"hydro_jet":        "hydroJet",
	"meltdown":         "meltDown",
	"overclock":        "overClock",
	"phantom":          "phantom",
	"piercing_split":   "piercingSplit",
	"plasma_discharge": "plasmaDischarge",
	"railgun":          "railGun",
	"steam_pressure":   "steamPressure",
	"thermal_shock":    "thermalShock",
	"thermite":         "thermite",
	"wet_split":        "wetSplitBall",
}

func _get_core_icon_texture(core_type: String) -> Texture2D:
	if core_type.begins_with("fused:"):
		var fusion_name: String = core_type.substr(6)
		var folder: String = _FUSED_FOLDER_MAP.get(fusion_name, "")
		if folder != "":
			return load("res://assets/fusedBalls/%s/frame_000.png" % folder)
	var folder: String = _CORE_FOLDER_MAP.get(core_type, "normalBall")
	return load("res://assets/balls/%s/frame_000.png" % folder)

func _setup_core_panel() -> void:
	const CELL := 40
	const GAP  := 5
	const PX   := 1640.0
	const PY   := 344.0
	const PW   := 272.0

	# ── Launchable Cores başlığı + 5 hücre ──────────────────────────────────
	var lbl_launch := Label.new()
	lbl_launch.text = "Launchable Cores"
	lbl_launch.size = Vector2(PW, 16.0)
	lbl_launch.position = Vector2(PX, PY)
	lbl_launch.add_theme_font_override("font", _font_bold)
	lbl_launch.add_theme_font_size_override("font_size", 11)
	lbl_launch.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0, 0.9))
	lbl_launch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(lbl_launch)

	_core_cells = []
	var panel_launch := Panel.new()
	panel_launch.name = "CoreInventoryPanel"
	panel_launch.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel_launch.size = Vector2(5 * CELL + 4 * GAP, CELL)
	panel_launch.position = Vector2(PX, PY + 18.0)
	panel_launch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(panel_launch)
	for c in range(5):
		var cell := Panel.new()
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0.07, 0.07, 0.15, 0.9)
		csb.corner_radius_top_left = 3; csb.corner_radius_top_right = 3
		csb.corner_radius_bottom_right = 3; csb.corner_radius_bottom_left = 3
		csb.border_width_top = 1; csb.border_width_bottom = 1
		csb.border_width_left = 1; csb.border_width_right = 1
		csb.border_color = Color(0.2, 0.3, 0.55, 0.55)
		cell.add_theme_stylebox_override("panel", csb)
		cell.size = Vector2(CELL, CELL)
		cell.position = Vector2(c * (CELL + GAP), 0.0)
		panel_launch.add_child(cell)
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.size = Vector2(CELL - 6, CELL - 6)
		icon.position = Vector2(3.0, 3.0)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)
		_core_cells.append(cell)
		var ci := _core_cells.size() - 1
		cell.mouse_entered.connect(func(): _on_core_cell_hover(ci))
		cell.mouse_exited.connect(_hide_tooltip)

	# ── Connected Cores başlığı + 3 hücre ───────────────────────────────────
	var lbl_conn := Label.new()
	lbl_conn.text = "Connected Cores"
	lbl_conn.size = Vector2(PW, 16.0)
	lbl_conn.position = Vector2(PX, PY + 18.0 + CELL + 10.0)
	lbl_conn.add_theme_font_override("font", _font_bold)
	lbl_conn.add_theme_font_size_override("font_size", 11)
	lbl_conn.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0, 0.9))
	lbl_conn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(lbl_conn)

	_connected_core_cells = []
	var panel_conn := Panel.new()
	panel_conn.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel_conn.size = Vector2(3 * CELL + 2 * GAP, CELL)
	panel_conn.position = Vector2(PX, PY + 18.0 + CELL + 10.0 + 18.0)
	panel_conn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(panel_conn)
	for c in range(3):
		var cell := Panel.new()
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0.07, 0.07, 0.15, 0.9)
		csb.corner_radius_top_left = 3; csb.corner_radius_top_right = 3
		csb.corner_radius_bottom_right = 3; csb.corner_radius_bottom_left = 3
		csb.border_width_top = 1; csb.border_width_bottom = 1
		csb.border_width_left = 1; csb.border_width_right = 1
		csb.border_color = Color(0.4, 0.3, 0.7, 0.55)
		cell.add_theme_stylebox_override("panel", csb)
		cell.size = Vector2(CELL, CELL)
		cell.position = Vector2(c * (CELL + GAP), 0.0)
		panel_conn.add_child(cell)
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.size = Vector2(CELL - 6, CELL - 6)
		icon.position = Vector2(3.0, 3.0)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)
		_connected_core_cells.append(cell)

	_core_panel = panel_launch
	_setup_tooltip()
	_setup_calamity_cells()

func _setup_low_hp_vignette() -> void:
	if _low_hp_vignette != null:
		return
	var grad := Gradient.new()
	grad.set_color(0, Color(0.9, 0.0, 0.0, 0.0))  # merkez: şeffaf
	grad.set_color(1, Color(0.9, 0.0, 0.0, 1.0))  # kenar: opak kırmızı
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 512
	tex.height = 512
	var rect := TextureRect.new()
	rect.name = "LowHPVignette"
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 12
	rect.modulate = Color(1, 1, 1, 0.0)
	$UI.add_child(rect)
	_low_hp_vignette = rect

func _update_low_hp_vignette() -> void:
	if _low_hp_vignette == null or player_max_hp <= 0:
		return
	var _ratio: float = float(player_hp) / float(player_max_hp)
	var _threshold := 0.3
	if _ratio > _threshold or player_hp <= 0 or upgrading:
		_low_hp_vignette.modulate.a = 0.0
		return
	# 0 (eşikte) → 1 (0 HP'de) arası şiddet
	var _severity: float = clamp(1.0 - _ratio / _threshold, 0.0, 1.0)
	var _base_alpha: float = lerp(0.12, 0.55, _severity)
	var _pulse_speed: float = lerp(2.0, 5.0, _severity)
	var _pulse_amp: float = lerp(0.05, 0.18, _severity)
	var _t := Time.get_ticks_msec() / 1000.0
	_low_hp_vignette.modulate.a = _base_alpha + _pulse_amp * (sin(_t * _pulse_speed) * 0.5 + 0.5)

func _setup_tooltip() -> void:
	if _tooltip_label != null:
		return
	var lbl := Label.new()
	lbl.name = "TooltipLabel"
	lbl.visible = false
	lbl.z_index = 100
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", _font_bold)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85, 1.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.12, 0.95)
	sb.corner_radius_top_left = 4; sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4; sb.corner_radius_bottom_left = 4
	sb.border_width_top = 1; sb.border_width_bottom = 1
	sb.border_width_left = 1; sb.border_width_right = 1
	sb.border_color = Color(0.4, 0.7, 1.0, 0.7)
	sb.content_margin_left = 6; sb.content_margin_right = 6
	sb.content_margin_top = 3; sb.content_margin_bottom = 3
	lbl.add_theme_stylebox_override("normal", sb)
	$UI.add_child(lbl)
	_tooltip_label = lbl

func _setup_calamity_cells() -> void:
	const CAL_PX := 1640.0
	const CAL_PY := 636.0
	const CELL_W := 40.0
	const CELL_H := 34.0
	const GAP    := 6.0
	_calamity_cells = []
	for i in range(5):  # 3 + max shop bonus (cal_slot max_stack:2)
		var cell := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.07, 0.07, 0.15, 0.9)
		sb.corner_radius_top_left = 4; sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_right = 4; sb.corner_radius_bottom_left = 4
		sb.border_width_top = 1; sb.border_width_bottom = 1
		sb.border_width_left = 1; sb.border_width_right = 1
		sb.border_color = Color(0.3, 0.6, 0.9, 0.55)
		cell.add_theme_stylebox_override("panel", sb)
		cell.size = Vector2(CELL_W, CELL_H)
		cell.position = Vector2(CAL_PX + i * (CELL_W + GAP), CAL_PY)
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		cell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		$UI.add_child(cell)
		var icon := Label.new()
		icon.name = "Icon"
		icon.text = "◻"
		icon.size = Vector2(CELL_W, CELL_H)
		icon.position = Vector2.ZERO
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_override("font", _font_bold)
		icon.add_theme_font_size_override("font_size", 18)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)
		_calamity_cells.append(cell)
		var ci := i
		cell.mouse_entered.connect(func(): _on_calamity_cell_hover(ci))
		cell.mouse_exited.connect(_hide_tooltip)
		cell.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_on_calamity_cell_clicked(ci)
		)

func _on_core_cell_hover(index: int) -> void:
	if _tooltip_label == null:
		return
	var balls := get_tree().get_nodes_in_group("player_balls")
	balls = balls.filter(func(b): return is_instance_valid(b))
	var special_balls := balls.filter(func(b): return b.get("is_normal_core") != true and b.get("is_inner_core") != true)
	if index >= special_balls.size():
		_hide_tooltip()
		return
	var btype := _get_ball_core_type(special_balls[index])
	var display_name: String = _CORE_DISPLAY_NAMES.get(btype, btype.capitalize() + " Core")
	var cell: Panel = _core_cells[index]
	var pos := cell.global_position + Vector2(0, -28)
	_show_tooltip(display_name, pos)

func _update_calamity_cells() -> void:
	for i in range(_calamity_cells.size()):
		var cell: Panel = _calamity_cells[i]
		var icon: Label = cell.get_node_or_null("Icon")
		var sb := cell.get_theme_stylebox("panel") as StyleBoxFlat
		if i >= max_calamity_slots:
			cell.visible = false
			continue
		cell.visible = true
		if i < calamity_slots.size():
			if icon: icon.text = calamity_slots[i]
			if icon: icon.modulate = Color(1, 1, 1, 1)
			cell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		else:
			if icon: icon.text = "◻"
			if icon: icon.modulate = Color(1, 1, 1, 0.35)
			cell.mouse_default_cursor_shape = Control.CURSOR_ARROW
		if sb:
			if calamity_aiming and calamity_index == i:
				sb.border_color = Color(1.0, 0.9, 0.2, 1.0)
				sb.bg_color = Color(0.25, 0.2, 0.05, 0.9)
			else:
				sb.border_color = Color(0.3, 0.6, 0.9, 0.55)
				sb.bg_color = Color(0.07, 0.07, 0.15, 0.9)

# Bir Calamity hedefleme gerektiriyor mu (mouse_pos parametresi kullanan tipler)?
const _CALAMITY_TARGETED := ["⚡", "🔥", "🌀", "🌋", "🌧️", "💣", "☠️", "🏚️", "🕳️"]
func _calamity_needs_target(calamity: String) -> bool:
	return calamity in _CALAMITY_TARGETED

func _on_calamity_cell_clicked(index: int) -> void:
	if index >= calamity_slots.size():
		return
	var calamity: String = calamity_slots[index]
	if _calamity_needs_target(calamity):
		if calamity_aiming and calamity_index == index:
			# Aynı slota tekrar tıklama → nişanı iptal et
			calamity_aiming = false
		else:
			calamity_index = index
			calamity_aiming = true
		update_ui()
	else:
		calamity_index = index
		_consume_calamity(index, get_viewport().get_mouse_position())

func _dispatch_calamity_effect(calamity: String, mouse_pos: Vector2) -> void:
	if calamity == "⚡":
		_activate_lightning(mouse_pos)
	elif calamity == "🔥":
		_activate_flame(mouse_pos)
	elif calamity == "🌀":
		_activate_gravity(mouse_pos)
	elif calamity == "❄️":
		_activate_blizzard()
	elif calamity == "🌊":
		_activate_monsoon()
	elif calamity == "🌋":
		_activate_volcanic_rift(mouse_pos)
	elif calamity == "⛈️":
		_activate_thunderstorm()
	elif calamity == "🔋":
		_activate_emp()
	elif calamity == "💾":  # Data Storm
		_activate_data_storm()
	elif calamity == "👾":  # Backdoor
		_activate_backdoor()
	elif calamity == "🎱":  # Bounce Barrage
		_activate_bounce_barrage()
	elif calamity == "🪞":  # Mirror Image
		_activate_mirror_image()
	elif calamity == "🧪":  # Systemic Failure
		_activate_systemic_failure()
	elif calamity == "💥":  # Shockwave
		_activate_shockwave()
	elif calamity == "🔓":  # Full Breach
		_activate_full_breach()
	elif calamity == "💨":  # Momentum Burst
		_activate_momentum_burst()
	elif calamity == "🏚️":  # Rampart Collapse
		_activate_rampart_collapse(mouse_pos)
	elif calamity == "🕳️":  # WormHole
		_activate_wormhole()
	elif calamity == "🌧️":  # Siege Rain
		_activate_siege_rain(mouse_pos)
	elif calamity == "🔥💥":  # Wildfire
		_activate_wildfire()
	elif calamity == "💣":  # Glitch Bomb
		_activate_glitch_bomb(mouse_pos)
	elif calamity == "💻💥":  # System Crash
		_activate_system_crash()
	elif calamity == "🦠":  # Virus Rain
		_activate_antivirus_rain()
	elif calamity == "☠️":  # Decay Field
		_activate_decay_field(mouse_pos)

func _consume_calamity(index: int, mouse_pos: Vector2) -> void:
	if index < 0 or index >= calamity_slots.size():
		return
	var calamity: String = calamity_slots[index]
	_dispatch_calamity_effect(calamity, mouse_pos)
	# Void Resonance: 4 farklı reaksiyon olduysa slot tüketme
	var _vr_skip := false
	if _player_node and _player_node.get("has_void_resonance") and _player_node.has_void_resonance:
		if _player_node.get("_void_resonance_ready") and _player_node._void_resonance_ready:
			_vr_skip = true
			_player_node._void_resonance_ready = false
			_player_node._wave_reaction_types.clear()
	if not _vr_skip:
		calamity_slots.remove_at(index)
	calamity_index = clamp(calamity_index, 0, max(calamity_slots.size() - 1, 0))
	if _player_node and _player_node.get("has_mana_overflow") and _player_node.has_mana_overflow:
		_player_node.mana_overflow_timer += 5.0
	calamity_aiming = false
	update_ui()

func _on_calamity_cell_hover(index: int) -> void:
	if _tooltip_label == null or index >= calamity_slots.size():
		_hide_tooltip()
		return
	var emoji: String = calamity_slots[index]
	var display_name: String = _CALAMITY_DISPLAY_NAMES.get(emoji, "Calamity")
	var cell: Panel = _calamity_cells[index]
	var pos := cell.global_position + Vector2(0, -28)
	_show_tooltip(display_name, pos)

func _show_tooltip(text: String, pos: Vector2) -> void:
	if _tooltip_label == null:
		return
	_tooltip_label.text = text
	_tooltip_label.position = pos
	_tooltip_label.visible = true

func _hide_tooltip() -> void:
	if _tooltip_label != null:
		_tooltip_label.visible = false

func _update_core_panel() -> void:
	if _core_panel == null:
		return
	var balls := get_tree().get_nodes_in_group("player_balls")
	balls = balls.filter(func(b): return is_instance_valid(b))
	# Normal core'ları ayır
	var special_balls := balls.filter(func(b): return b.get("is_normal_core") != true and b.get("is_inner_core") != true)
	var connected_balls := balls.filter(func(b): return b.get("is_inner_core") == true)
	# Launchable cores (özellikli)
	for i in range(_core_cells.size()):
		var cell: Panel = _core_cells[i]
		var icon: TextureRect = cell.get_node("Icon")
		if i < special_balls.size():
			icon.texture = _get_core_icon_texture(_get_ball_core_type(special_balls[i]))
		else:
			icon.texture = null
	# Connected cores
	for i in range(_connected_core_cells.size()):
		var cell: Panel = _connected_core_cells[i]
		var icon: TextureRect = cell.get_node("Icon")
		if i < connected_balls.size():
			icon.texture = _get_core_icon_texture(_get_ball_core_type(connected_balls[i]))
		else:
			icon.texture = null

func _show_discard_overlay(new_core_name: String) -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "DiscardOverlay"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	get_tree().paused = true
	upgrading = true

	# Karartma
	var bg := ColorRect.new()
	bg.size = Vector2(1920.0, 1080.0)
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
	canvas.add_child(bg)

	# Başlık
	var title := Label.new()
	title.text = Lang.t("ui_release_core")
	title.position = Vector2(760.0, 200.0)
	title.size = Vector2(400.0, 60.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font_bold)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.2))
	canvas.add_child(title)

	# Alt yazı
	var sub := Label.new()
	sub.text = "Incoming: %s  —  Select a core to release" % new_core_name.capitalize()
	sub.position = Vector2(560.0, 270.0)
	sub.size = Vector2(800.0, 36.0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", _font_regular)
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	canvas.add_child(sub)

	# 4×2 grid (daha büyük, tıklanabilir)
	const CELL := 90
	const GAP  := 14
	const COLS := 4
	var balls := get_tree().get_nodes_in_group("player_balls")
	balls = balls.filter(func(b): return is_instance_valid(b))
	var grid_w: float = COLS * CELL + (COLS - 1) * GAP
	var start_x: float = (1920.0 - grid_w) / 2.0
	var start_y: float = 340.0

	for i in range(balls.size()):
		var ball = balls[i]
		var col := i % COLS
		var row := i / COLS
		var cx: float = start_x + col * (CELL + GAP)
		var cy: float = start_y + row * (CELL + GAP + 24)

		# Hücre arka planı
		var cell_bg := Panel.new()
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0.08, 0.08, 0.18, 0.95)
		csb.corner_radius_top_left = 6; csb.corner_radius_top_right = 6
		csb.corner_radius_bottom_right = 6; csb.corner_radius_bottom_left = 6
		csb.border_width_top = 2; csb.border_width_bottom = 2
		csb.border_width_left = 2; csb.border_width_right = 2
		csb.border_color = Color(0.3, 0.4, 0.6, 0.8)
		cell_bg.add_theme_stylebox_override("panel", csb)
		cell_bg.size = Vector2(CELL, CELL + 24)
		cell_bg.position = Vector2(cx, cy)
		canvas.add_child(cell_bg)

		# Core ikonu
		var btype := _get_ball_core_type(ball)
		var icon := TextureRect.new()
		icon.texture = _get_core_icon_texture(btype)
		icon.size = Vector2(CELL - 8, CELL - 8)
		icon.position = Vector2(4.0, 4.0)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell_bg.add_child(icon)

		# Core isim etiketi
		var name_lbl := Label.new()
		name_lbl.text = btype.capitalize()
		name_lbl.size = Vector2(CELL, 20.0)
		name_lbl.position = Vector2(0.0, float(CELL) + 2.0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_override("font", _font_regular)
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell_bg.add_child(name_lbl)

		# Tıklama alanı (şeffaf Button)
		var btn := Button.new()
		btn.size = Vector2(CELL, CELL + 24)
		btn.position = Vector2(0.0, 0.0)
		btn.modulate = Color(1.0, 1.0, 1.0, 0.0)
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		# Hover: kırmızı border highlight
		btn.mouse_entered.connect(func():
			csb.border_color = Color(1.0, 0.3, 0.2, 1.0)
			csb.bg_color = Color(0.2, 0.05, 0.05, 0.95)
		)
		btn.mouse_exited.connect(func():
			csb.border_color = Color(0.3, 0.4, 0.6, 0.8)
			csb.bg_color = Color(0.08, 0.08, 0.18, 0.95)
		)
		btn.pressed.connect(_discard_ball.bind(ball, canvas))
		cell_bg.add_child(btn)

	# İptal butonu
	var cancel_btn := Button.new()
	cancel_btn.text = Lang.t("ui_cancel")
	cancel_btn.size = Vector2(160.0, 48.0)
	cancel_btn.position = Vector2(880.0, 800.0)
	cancel_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	cancel_btn.add_theme_font_override("font", _font_bold)
	cancel_btn.pressed.connect(func():
		canvas.queue_free()
		get_tree().paused = false
		upgrading = false
		_pending_core_type = ""
	)
	canvas.add_child(cancel_btn)

func _discard_ball(ball_node, canvas: CanvasLayer) -> void:
	canvas.queue_free()
	get_tree().paused = false
	upgrading = false

	# Orbit'ten çıkar
	var player := get_node("Player")
	if ball_node in player.orbit_balls:
		player.remove_from_orbit(ball_node)
	ball_node.remove_from_group("player_balls")

	# Shrink + düşme animasyonu
	var fall_pos: Vector2 = ball_node.global_position + Vector2(0.0, 90.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ball_node, "scale", Vector2.ZERO, 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(ball_node, "global_position", fall_pos, 0.35)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		if is_instance_valid(ball_node):
			ball_node.queue_free()
		$BallLauncher.queue_upgrade_ball(_pending_core_type)
		_pending_core_type = ""
		update_ui()
	)

func _setup_neon_sign() -> void:
	var sign: Node2D = load("res://neon_sign.gd").new()
	# Oyun alanı ortası, üst duvara monte: x=1240, y=248 (duvarın hemen altı)
	# Tribün sağ duvarına monte, cadde şeridinde dikey tabela
	sign.position = Vector2(450, 120)
	add_child(sign)

func _setup_auto_toggle() -> void:
	var btn := Button.new()
	btn.name = "BtnAutoMode"
	btn.text = Lang.t("ui_auto_off")
	btn.position = Vector2(1762, 22)
	btn.size     = Vector2(88, 28)
	btn.add_theme_font_override("font", _font_bold)
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	$UI.add_child(btn)
	btn.pressed.connect(func() -> void:
		var player = get_node("Player")
		player.auto_mode = not player.auto_mode
		if player.auto_mode:
			btn.text = Lang.t("ui_auto_on")
			btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.45))
			player._fire_all_balls()
		else:
			btn.text = Lang.t("ui_auto_off")
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	)

func _setup_data_bar() -> void:
	_data_particle_canvas = $UI
	_data_bar_canvas      = $UI

	# Arka plan
	var border := ColorRect.new()
	border.size     = Vector2(_DATA_BAR_W + 2, _DATA_BAR_H + 2)
	border.position = _DATA_BAR_POS - Vector2(1, 1)
	border.color    = Color(0.0, 0.45, 0.18, 0.6)
	_data_bar_canvas.add_child(border)

	var bg := ColorRect.new()
	bg.size     = Vector2(_DATA_BAR_W, _DATA_BAR_H)
	bg.position = _DATA_BAR_POS
	bg.color    = Color(0.01, 0.04, 0.01, 0.88)
	_data_bar_canvas.add_child(bg)

	# Dolum (sola sıfır, sağa doğru büyür)
	_data_bar_fill = ColorRect.new()
	_data_bar_fill.size     = Vector2(0, _DATA_BAR_H)
	_data_bar_fill.position = _DATA_BAR_POS
	_data_bar_fill.color    = Color(0.0, 1.0, 0.35, 0.9)
	_data_bar_canvas.add_child(_data_bar_fill)

	# "UPGRADE" etiketi — bar dolunca yanıp söner (başta gizli)
	_data_bar_label = Label.new()
	_data_bar_label.text = Lang.t("ui_upgrade_ready")
	_data_bar_label.visible = false
	_data_bar_label.position = _DATA_BAR_POS + Vector2(50, -18)
	_data_bar_label.add_theme_font_override("font", _font_bold)
	_data_bar_label.add_theme_font_size_override("font_size", 10)
	_data_bar_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.55))
	_data_bar_canvas.add_child(_data_bar_label)

func _update_data_bar() -> void:
	if _data_bar_fill == null: return
	var ratio := clampf(_data_current / _data_max, 0.0, 1.0)
	_data_bar_fill.size  = Vector2(_DATA_BAR_W * ratio, _DATA_BAR_H)
	_data_bar_fill.color = Color(0.0, 1.0 - ratio * 0.2, 0.2 + ratio * 0.5, 0.9)

func _spawn_data_particles(world_pos: Vector2, amount: float, count: int) -> void:
	# Limit aşıldıysa görsel atla, veriyi direkt ekle
	if _active_particles >= _MAX_PARTICLES:
		_data_current += amount
		_update_data_bar()
		if _data_current >= _data_max:
			_data_current = 0.0
			_data_max     = _data_max * 2.0
			get_tree().paused = true
			show_upgrade_menu()
		return

	var canvas_tf: Transform2D = get_viewport().get_canvas_transform()
	var screen_pos: Vector2    = canvas_tf * world_pos
	var bar_target: Vector2    = _DATA_BAR_POS + Vector2(_DATA_BAR_W * 0.5, _DATA_BAR_H * 0.5) + Vector2(0, 7)
	var chars := ["0","1","▓","▒","░","#","@","$","%","&","■","▲"]
	# Aktif parçacık sayısına göre count'u kısalt
	var spawn_count := mini(count, _MAX_PARTICLES - _active_particles)
	var per_particle := amount / float(spawn_count)

	for i in spawn_count:
		_active_particles += 1
		var lbl := Label.new()
		lbl.text = chars[randi() % chars.size()]
		lbl.add_theme_font_override("font", _font_regular)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.35, 0.9))
		lbl.position = screen_pos + Vector2(randf_range(-18, 18), randf_range(-18, 18))
		_data_particle_canvas.add_child(lbl)

		var delay := i * 0.06
		var duration := randf_range(0.45, 0.75)
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(lbl, "position", bar_target, duration)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(lbl, "modulate:a", 0.0, duration * 0.4)\
			.set_delay(duration * 0.7)
		tw.tween_callback(func() -> void:
			_active_particles -= 1
			_data_current += per_particle
			_update_data_bar()
			if _data_current >= _data_max:
				_data_current = 0.0
				_data_max     = _data_max * 2.0
				get_tree().paused = true
				show_upgrade_menu()
			lbl.queue_free()
		)

func subject_rescued() -> void:
	GameData.add_xp(GameData.selected_character, 2)

func player_damaged(amount: int = 1) -> void:
	var _p := get_node_or_null("Player")
	# Shock Reflex: Electrocute sonrası 3s için %8 kaçınma
	if _p and _p.get("has_shock_reflex") and _p.has_shock_reflex and _p._shock_reflex_timer > 0.0:
		if randf() < 0.08:
			return
	# Frost Barrier: 5 HP kalkan absorbe eder
	if _p and _p.get("has_frost_barrier") and _p.has_frost_barrier and _p.frost_barrier_hp > 0:
		_p.frost_barrier_hp = maxi(0, _p.frost_barrier_hp - amount)
		_update_frost_barrier_ui()
		return
	# Wet Armor: Islak düşman varken %10 az hasar
	if _p and _p.get("has_wet_armor") and _p.has_wet_armor:
		var has_wet_enemy := false
		for _we in get_tree().get_nodes_in_group("subjects"):
			if _we.get("is_wet") and _we.is_wet:
				has_wet_enemy = true; break
		if has_wet_enemy:
			amount = maxi(1, int(amount * 0.9))
	# Elemental Shield Core: aktif element varsa hasarı %20 azalt
	for _esb in get_tree().get_nodes_in_group("player_balls"):
		if not is_instance_valid(_esb): continue
		if _esb.get("is_inner_core") and _esb.is_inner_core and _esb.get("inner_core_type") and _esb.inner_core_type == "elemental_shield_core":
			var _lae: String = get_node_or_null("Player").get("last_applied_element") if get_node_or_null("Player") else ""
			if _lae != "":
				amount = maxi(1, int(amount * 0.8))
			break
	# Armor önce absorbe eder
	if player_armor > 0:
		var absorbed: int = mini(player_armor, amount)
		player_armor -= absorbed
		amount -= absorbed
		_update_armor_ui()
		_hex_shield_hit_flash()
		# Momentum Transfer: Armor İLK KEZ sıfırlandığında (run başına 1 kez) tüm
		# Momentum stack'i ×2 Armor'a çevrilir — acil durum güvenlik ağı
		if player_armor <= 0:
			var _mt := get_node_or_null("Player")
			if _mt and _mt.get("has_momentum_transfer") and _mt.has_momentum_transfer and not _mt._momentum_transfer_used:
				_mt._momentum_transfer_used = true
				var _consumed: int = _mt.momentum_stacks
				if _consumed > 0:
					_mt.momentum_stacks = 0
					gain_armor(_consumed * 2)
	if amount <= 0:
		return
	# Risk Engine: HP hasarı kadar Momentum stack kazan
	var _re_player := get_node_or_null("Player")
	if _re_player and _re_player.get("has_risk_engine") and _re_player.has_risk_engine:
		_re_player.gain_momentum(amount)
	player_hp -= amount
	update_ui()
	if player_hp <= 0:
		get_tree().paused = true
		show_game_over()

func show_game_over() -> void:
	await get_tree().create_timer(0.5).timeout

	var canvas = CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	# ── Koyu arka plan ────────────────────────────────────────
	var bg = ColorRect.new()
	bg.color    = Color(0.01, 0.01, 0.04, 0.96)
	bg.size     = Vector2(1920, 1080)
	canvas.add_child(bg)

	# ── Hasmen visual (right side) ─────────────────────────────
	var hasmen_img = TextureRect.new()
	hasmen_img.texture      = load("res://assets/mrHasmen.png")
	hasmen_img.size         = Vector2(500, 900)
	hasmen_img.position     = Vector2(1380, 180)
	hasmen_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hasmen_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	canvas.add_child(hasmen_img)

	# Neon pink vertical divider
	var divider = ColorRect.new()
	divider.size     = Vector2(2, 1080)
	divider.position = Vector2(1360, 0)
	divider.color    = Color(1.0, 0.08, 0.58, 0.4)
	canvas.add_child(divider)

	# "MR. HASMEN" isim etiketi
	var hasmen_name = Label.new()
	hasmen_name.text     = "MR. HASMEN"
	hasmen_name.position = Vector2(1385, 150)
	hasmen_name.add_theme_font_override("font", _font_bold)
	hasmen_name.add_theme_font_size_override("font_size", 18)
	hasmen_name.add_theme_color_override("font_color", Color(1.0, 0.08, 0.58, 0.85))
	canvas.add_child(hasmen_name)

	# ── Header ─────────────────────────────────────────────────
	var header = Label.new()
	header.text     = Lang.t("go_header")
	header.position = Vector2(80, 70)
	header.add_theme_font_override("font", _font_bold)
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(1.0, 0.08, 0.58, 1.0))
	canvas.add_child(header)

	# ── Rapor kutusu ──────────────────────────────────────────
	var report_bg = ColorRect.new()
	report_bg.position = Vector2(80, 148)
	report_bg.size     = Vector2(1240, 320)
	report_bg.color    = Color(0.03, 0.05, 0.08, 0.92)
	canvas.add_child(report_bg)

	var report_border = ColorRect.new()
	report_border.position = Vector2(80, 148)
	report_border.size     = Vector2(3, 320)
	report_border.color    = Color(0.0, 0.9, 1.0, 0.85)
	canvas.add_child(report_border)

	# Report rows: [title, value, color]
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	var rows = [
		[Lang.t("go_data"),    _format_data(data_collected) + Lang.t("go_units"), Color(0.0, 1.0, 0.55)],
		[Lang.t("go_time"),    "%02d:%02d" % [minutes, seconds],                  Color(0.0, 0.9, 1.0)],
		[Lang.t("go_threats"), str(total_subjects_killed),                         Color(0.0, 0.9, 1.0)],
		[Lang.t("go_level"),   str(level),                                         Color(0.0, 0.9, 1.0)],
	]
	for i in range(rows.size()):
		var row = rows[i]
		var key = Label.new()
		key.text     = row[0]
		key.position = Vector2(110, 172 + i * 72)
		key.add_theme_font_override("font", _font_regular)
		key.add_theme_font_size_override("font_size", 13)
		key.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		canvas.add_child(key)

		var val = Label.new()
		val.text     = row[1]
		val.position = Vector2(110, 190 + i * 72)
		val.add_theme_font_override("font", _font_bold)
		val.add_theme_font_size_override("font_size", 28)
		val.add_theme_color_override("font_color", row[2])
		canvas.add_child(val)

	# ── Hasmen quote ────────────────────────────────────────────
	var quote_bg = ColorRect.new()
	quote_bg.position = Vector2(80, 506)
	quote_bg.size     = Vector2(1240, 110)
	quote_bg.color    = Color(0.05, 0.02, 0.07, 0.92)
	canvas.add_child(quote_bg)

	var quote_lbl = Label.new()
	quote_lbl.text          = "\"" + _get_hasmen_quote() + "\""
	quote_lbl.position      = Vector2(110, 518)
	quote_lbl.size          = Vector2(1190, 60)
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	quote_lbl.add_theme_font_override("font", _font_regular)
	quote_lbl.add_theme_font_size_override("font_size", 17)
	quote_lbl.add_theme_color_override("font_color", Color(0.85, 0.80, 1.0))
	canvas.add_child(quote_lbl)

	var attr_lbl = Label.new()
	attr_lbl.text     = "— Mr. Hasmen, ITY Corp."
	attr_lbl.position = Vector2(110, 584)
	attr_lbl.add_theme_font_override("font", _font_bold)
	attr_lbl.add_theme_font_size_override("font_size", 12)
	attr_lbl.add_theme_color_override("font_color", Color(1.0, 0.08, 0.58, 0.75))
	canvas.add_child(attr_lbl)

	# ── Butonlar ──────────────────────────────────────────────
	var continue_btn = Button.new()
	continue_btn.text         = Lang.t("go_continue")
	continue_btn.position     = Vector2(340, 760)
	continue_btn.size         = Vector2(300, 55)
	continue_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	continue_btn.add_theme_font_override("font", _font_bold)
	canvas.add_child(continue_btn)

	await continue_btn.pressed
	canvas.queue_free()
	get_tree().paused = false
	var _lv_now: int = GameData.get_level(GameData.selected_character)
	if _lv_now > _run_start_level:
		await _show_cards_unlocked(_run_start_level, _lv_now)
	get_tree().change_scene_to_file("res://character_select.tscn")

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# ── Veri Sistemi ─────────────────────────────────────────────────────────────

func add_data(amount: int) -> void:
	data_collected += amount
	var lbl = get_node_or_null("UI/LabelData")
	if lbl:
		lbl.text = _format_data(data_collected) + Lang.t("ui_data_units")

func _format_data(n: int) -> String:
	if n >= 1_000_000:
		return "%.2f M" % (n / 1_000_000.0)
	elif n >= 1_000:
		return "%.1f K" % (n / 1_000.0)
	return str(n)

func _get_hasmen_quote() -> String:
	if data_collected < 500:
		return Lang.t("quote_0")
	elif data_collected < 2_000:
		return Lang.t("quote_1")
	elif data_collected < 8_000:
		return Lang.t("quote_2")
	elif data_collected < 25_000:
		return Lang.t("quote_3")
	else:
		return Lang.t("quote_4")

func _weighted_pick(pool: Array, count: int) -> Array:
	var result: Array = []
	var remaining := pool.duplicate()
	for _i in range(count):
		if remaining.is_empty():
			break
		var total: int = 0
		for item in remaining:
			total += item.get("weight", 10)
		var roll := randi() % total
		var acc: int = 0
		for j in range(remaining.size()):
			acc += remaining[j].get("weight", 10)
			if roll < acc:
				result.append(remaining[j])
				remaining.remove_at(j)
				break
	return result

func _build_all_upgrades() -> void:
	upgrades = [
	# ── Vector (Kinetik) — min_level: öğrenme eğrisi ─────────────────────────
	# Lv0: Vector nedir?
	{"name": "Pierce Core",         "category": "Identity",      "color": Color(1.0, 0.8, 0.0), "desc": "5 damage.\nPierces through unarmored enemies.",        "index": 2,  "weight": 10, "rarity": "common",   "chars": ["vector"], "min_level": 0},
	{"name": "Armor Core",          "category": "Identity",      "color": Color(0.5, 0.6, 0.8), "desc": "4 damage.\nHit → gain Armor",                          "index": 40, "weight": 10, "rarity": "common",   "chars": ["vector"], "min_level": 0},
	{"name": "Anchor Core",         "category": "Identity",      "color": Color(0.3, 0.4, 0.6), "desc": "8 damage.\nHit → slow enemy 60% (3s)",                 "index": 41, "weight": 10, "rarity": "common",   "chars": ["vector"], "min_level": 0},
	{"name": "Crusher Core",        "category": "Identity",      "color": Color(0.6, 0.3, 0.1), "desc": "9 damage.\nHit → instantly breaks enemy Armor",                 "index": 42, "weight": 10, "rarity": "common",   "chars": ["vector"], "min_level": 0},
	{"name": "Siege Core",          "category": "Identity",      "color": Color(0.4, 0.4, 0.5), "desc": "15 damage.\nHighest damage core",                       "index": 45, "weight": 6,  "rarity": "uncommon", "chars": ["vector"], "min_level": 2},
	{"name": "Momentum Engine",     "category": "Utility",       "color": Color(0.0, 0.7, 1.0), "desc": "Unlocks the Momentum system.\nWhile walking, every 4s: +1 Stack\n+3% Core Speed per stack (max 20)", "index": 35, "weight": 4,   "rarity": "uncommon", "chars": ["vector"], "min_level": 1},
	{"name": "Chain Density",       "category": "Utility",       "color": Color(0.0, 0.9, 0.5), "desc": "New enemy hit mid-flight:\n+dmg ramp, resets on return",     "index": 37, "weight": 8, "rarity": "common", "chars": ["vector"], "min_level": 0},
	{"name": "Reinforced Frame",    "category": "Individuality", "color": Color(0.5, 0.7, 0.5), "desc": "+20 Max Armor / Core Speed -%10",           "index": 48, "weight": 8, "rarity": "common",   "chars": ["vector"], "min_level": 1},
	{"name": "Iron Constitution",   "category": "Individuality", "color": Color(0.7, 0.8, 0.6), "desc": "Armor gain efficiency +%25",                 "index": 49, "weight": 8, "rarity": "common",   "chars": ["vector"], "min_level": 1},
	{"name": "Speed Upgrade",       "category": "Individuality", "color": Color(0.6, 0.2, 0.8), "desc": "Kalıcı: Hareket hızı +50",                  "index": 4,  "weight": 8, "rarity": "common",   "chars": [],         "min_level": 0},
	{"name": "Max Health Up",       "category": "Individuality", "color": Color(0.8, 0.2, 0.2), "desc": "Maximum HP +5",                             "index": 21, "weight": 8, "rarity": "common",   "chars": [],         "min_level": 0},
	{"name": "Medkit",              "category": "Individuality", "color": Color(0.9, 0.1, 0.1), "desc": "+10 HP restored",                           "index": 20, "weight": 8, "rarity": "common",   "chars": [],         "min_level": 0},
	{"name": "Gravitational Force", "category": "Calamity",      "color": Color(0.5, 0.0, 1.0), "desc": "Pulls enemies toward the center for 5s",                     "index": 9,  "weight": 8, "rarity": "common",   "chars": ["vector"], "min_level": 0},
	{"name": "Hyper Recovery Loop", "category": "Individuality", "color": Color(0.3, 0.7, 1.0), "desc": "Core Return Speed ×1.5",        "index": 56, "weight": 8, "rarity": "common",   "chars": ["vector"], "min_level": 1},
	# Lv1: Core davranışlarını öğretir
	{"name": "Kinetic Core",        "category": "Identity",      "color": Color(0.2, 0.8, 0.6), "desc": "7 damage.\nEach wall bounce → +dmg",                   "index": 43, "weight": 8, "rarity": "uncommon", "chars": ["vector"], "min_level": 1},
	{"name": "Bulwark Core",        "category": "Identity",      "color": Color(0.4, 0.5, 0.7), "desc": "3 damage.\nHit → +2 Armor",                            "index": 44, "weight": 8, "rarity": "uncommon", "chars": ["vector"], "min_level": 1},
	{"name": "Impact Feedback",     "category": "Utility",       "color": Color(0.5, 0.3, 0.9), "desc": "Every 10 hits:\nArmor Core gain permanently +1 (max 10)", "index": 36, "weight": 6, "rarity": "uncommon", "chars": ["vector"], "min_level": 2, "requires": [40]},
	{"name": "Battlefield Anchor",  "category": "Individuality", "color": Color(0.3, 0.5, 0.7), "desc": "Enemy slow duration ×2 / Player Speed -%10",       "index": 58, "weight": 6, "rarity": "uncommon", "chars": ["vector"], "min_level": 2, "requires": [41]},
	{"name": "Blood for Steel",     "category": "Individuality", "color": Color(0.7, 0.1, 0.1), "desc": "-10 HP  |  +10 Max Armor",                   "index": 30, "weight": 6, "rarity": "uncommon", "chars": ["vector"], "min_level": 2},
	{"name": "Overclocked Reflex",  "category": "Individuality", "color": Color(0.9, 0.9, 0.2), "desc": "Core Speed +%20 / Armor Gain -%15",          "index": 54, "weight": 6, "rarity": "uncommon", "chars": ["vector"], "min_level": 2},
	# Lv2: Armor ekonomisi
	{"name": "Last Stand",          "category": "Utility",       "color": Color(1.0, 0.6, 0.0), "desc": "Low HP → bonus Core Speed\n& Armor Gain efficiency", "index": 38, "weight": 5, "rarity": "rare", "chars": ["vector"], "min_level": 3},
	{"name": "Pain Converter",      "category": "Individuality", "color": Color(0.8, 0.2, 0.3), "desc": "HP <50%  →  Armor Gain +50%",                "index": 31, "weight": 5, "rarity": "rare",     "chars": ["vector"], "min_level": 3},
	{"name": "Scar Tissue",         "category": "Individuality", "color": Color(0.6, 0.1, 0.1), "desc": "-10 Max HP  |  +5 Armor Cap  |  +1 Armor Regen/s",  "index": 33, "weight": 5, "rarity": "rare",     "chars": ["vector"], "min_level": 3},
	{"name": "Blood Circuit",       "category": "Individuality", "color": Color(0.8, 0.1, 0.1), "desc": "HP <= %70: Core Speed scales up to +%50",    "index": 51, "weight": 5, "rarity": "rare",     "chars": ["vector"], "min_level": 3},
	{"name": "Kinetic Nervous System","category":"Individuality", "color": Color(0.2, 0.9, 0.6), "desc": "Momentum cap +10\n(20 → 30)", "index": 55, "weight": 4, "rarity": "rare", "chars": ["vector"], "min_level": 3},
	# Lv3: Risk / Ödül
	{"name": "Tempered Core",       "category": "Identity",      "color": Color(0.9, 0.7, 0.2), "desc": "Armor active → +3 dmg",                      "index": 47, "weight": 5, "rarity": "rare",     "chars": ["vector"], "min_level": 4},
	{"name": "Glass Engine",        "category": "Individuality", "color": Color(0.5, 0.8, 0.9), "desc": "HP <50%: Armor Gain +50% | HP >70%: Armor Gain -30%",   "index": 53, "weight": 4, "rarity": "rare",     "chars": ["vector"], "min_level": 4},
	{"name": "Fortified Core System","category":"Individuality",  "color": Color(0.4, 0.6, 0.8), "desc": "Armor Cap +15 / Momentum gain -%20",          "index": 50, "weight": 4, "rarity": "rare",     "chars": ["vector"], "min_level": 4, "requires": [35]},
	{"name": "Adrenal Armor System", "category":"Individuality",  "color": Color(0.9, 0.3, 0.5), "desc": "Low HP: Armor +%30 | High HP: Core Speed +%10", "index": 59, "weight": 4, "rarity": "rare",  "chars": ["vector"], "min_level": 4},
	# Lv4: Build specialization
	{"name": "Bloodbound Core",     "category": "Identity",      "color": Color(0.7, 0.0, 0.1), "desc": "Missing HP → bonus dmg",                     "index": 46, "weight": 4,  "rarity": "epic",     "chars": ["vector"], "min_level": 4},
	{"name": "Adrenal Surge",       "category": "Individuality", "color": Color(1.0, 0.4, 0.1), "desc": "HP <30%  →  Momentum Engine x2",             "index": 32, "weight": 3, "rarity": "epic",     "chars": ["vector"], "min_level": 5, "requires": [35]},
	# Lv5: Run breaker
	{"name": "Emergency Protocol",  "category": "Individuality", "color": Color(1.0, 0.9, 0.0), "desc": "On pickup: -15 HP\n+75% Armor Gain (10s)",      "index": 34, "weight": 2,   "rarity": "legendary","chars": ["vector"], "min_level": 5},
	{"name": "Risk Engine",         "category": "Individuality", "color": Color(0.8, 0.1, 0.3), "desc": "Damage taken → Momentum stacks / Armor Gain -%30", "index": 60, "weight": 3, "rarity": "epic", "chars": ["vector"], "min_level": 5, "requires": [35]},
	{"name": "Fractured Frame",     "category": "Individuality", "color": Color(0.9, 0.4, 0.1), "desc": "Core Damage ×1.4 / Max HP -15",               "index": 52, "weight": 2, "rarity": "epic",     "chars": ["vector"], "min_level": 5},
	{"name": "Pressure Valve",      "category": "Utility",       "color": Color(0.3, 0.8, 0.7), "desc": "Every 5 Momentum stacks:\ngain +1 Armor",     "index": 104, "weight": 6, "rarity": "uncommon", "chars": ["vector"], "min_level": 2, "requires": [35]},
	# ↑ desc: dinamik gösterim lang.gd _dynamic_desc(104) ile sağlanıyor (pressure_valve_threshold: Lv1=5, Lv2=4, Lv3=3)
	{"name": "Iron Blood",          "category": "Individuality", "color": Color(0.6, 0.2, 0.2), "desc": "On pickup (once):\n+1 Armor Cap per 10 Max HP",   "index": 105, "weight": 4, "rarity": "rare",     "chars": ["vector"], "min_level": 3},
	{"name": "Momentum Cascade",   "category": "Utility",       "color": Color(0.0, 0.85, 1.0), "desc": "12+ Momentum stacks:\nArmor Gain ×1.5",        "index": 108, "weight": 6, "rarity": "uncommon", "chars": ["vector"], "min_level": 2, "requires": [35]},
	{"name": "Steel Rhythm",       "category": "Individuality", "color": Color(0.5, 0.65, 0.85),"desc": "Each hit while Armor = Cap:\n+1 Momentum stack (fills up to 50% max)", "index": 109, "weight": 5, "rarity": "uncommon", "chars": ["vector"], "min_level": 2, "requires": [35]},
	{"name": "Bulwark Surge",      "category": "Utility",       "color": Color(0.4, 0.7, 0.55), "desc": "Armor ≥ %75 Cap:\nCore Speed +%15",             "index": 110, "weight": 5, "rarity": "rare",     "chars": ["vector"], "min_level": 3},
	{"name": "Severance Protocol", "category": "Individuality", "color": Color(0.9, 0.2, 0.15), "desc": "HP drops below 40%:\nArmor Cap +10 (once)",      "index": 111, "weight": 4, "rarity": "rare",     "chars": ["vector"], "min_level": 3},
	{"name": "Inertia Plating",    "category": "Individuality", "color": Color(0.35, 0.5, 0.75),"desc": "Max Armor +5 per 5 Momentum\n(on pickup, once)", "index": 112, "weight": 4, "rarity": "rare",     "chars": ["vector"], "min_level": 4, "requires": [35]},
	{"name": "Overclock Threshold","category": "Individuality", "color": Color(1.0, 0.75, 0.1), "desc": "20 Momentum stacks:\nCore Damage ×1.3 permanently", "index": 113, "weight": 3, "rarity": "epic",  "chars": ["vector"], "min_level": 5, "requires": [35]},
	# ── Vector — Utility (yeni) ───────────────────────────────────────────────
	{"name": "Armor Rush",        "category": "Utility",       "color": Color(0.3, 0.8, 0.6),  "desc": "Momentum ≥ 13:\nArmor gain +1 (cancels below threshold)", "index": 164, "weight": 8,  "rarity": "common",    "chars": ["vector"], "min_level": 0, "requires": [35]},
	{"name": "Combat Rhythm",     "category": "Utility",       "color": Color(0.4, 0.7, 0.9),  "desc": "6 consecutive hits:\nCore returns instantly",               "index": 165, "weight": 7,  "rarity": "uncommon",  "chars": ["vector"], "min_level": 1},
	{"name": "Shield Bash",       "category": "Utility",       "color": Color(0.5, 0.6, 0.8),  "desc": "Core return speed\nscales with Armor",                     "index": 166, "weight": 7,  "rarity": "uncommon",  "chars": ["vector"], "min_level": 1},
	{"name": "Siege Protocol",    "category": "Utility",       "color": Color(0.4, 0.4, 0.5),  "desc": "Siege Core: each wall bounce\ngains +1 dmg. (Extra damage resets on hit)", "index": 167, "weight": 5,  "rarity": "rare",      "chars": ["vector"], "min_level": 2, "requires": [45]},
	{"name": "Bulwark Echo",      "category": "Utility",       "color": Color(0.4, 0.5, 0.7),  "desc": "Bulwark Core hit: after 4s\ngain 1 more Armor", "index": 168, "weight": 5, "rarity": "rare",   "chars": ["vector"], "min_level": 2, "requires": [44]},
	{"name": "Momentum Transfer", "category": "Individuality", "color": Color(0.0, 0.8, 0.9),  "desc": "First time Armor hits 0:\nall Momentum → Armor ×2 (once per run)", "index": 169, "weight": 6,  "rarity": "uncommon",  "chars": ["vector"], "min_level": 1, "requires": [35]},
	{"name": "Kinetic Surge",     "category": "Utility",       "color": Color(0.0, 0.9, 1.0),  "desc": "15+ Momentum:\nCore launches at min. 700 speed",            "index": 171, "weight": 4,  "rarity": "rare",      "chars": ["vector"], "min_level": 3, "requires": [35]},
	{"name": "Armor Conduit",     "category": "Utility",       "color": Color(0.5, 0.7, 0.8),  "desc": "Armor = Cap:\nAll core damage ×1.25",                       "index": 172, "weight": 5,  "rarity": "rare",      "chars": ["vector"], "min_level": 2},
	# ── Vector — Connected Cores (iç yörünge, fırlatılmaz) ───────────────────
	{"name": "Iron Aura Core",      "category": "Identity",      "color": Color(0.5, 0.65, 0.9),  "desc": "Every 2s: deal 1 + Armor×5%\ndamage to enemies within 60px",       "index": 178, "weight": 5, "rarity": "rare",      "chars": ["vector"], "min_level": 2},
	{"name": "Momentum Field Core", "category": "Identity",      "color": Color(0.0, 0.85, 1.0),  "desc": "Momentum Engine's passive\ngeneration +1 per tick",             "index": 179, "weight": 5, "rarity": "rare",      "chars": ["vector"], "min_level": 2, "requires": [35]},
	{"name": "Regen Pulse Core",    "category": "Identity",      "color": Color(0.4, 0.7, 0.55),  "desc": "Every 15s: restore 1 Armor",                                    "index": 180, "weight": 6, "rarity": "uncommon",  "chars": ["vector"], "min_level": 1},
	{"name": "Fortress Core",       "category": "Identity",      "color": Color(0.4, 0.5, 0.75),  "desc": "Armor 75%+ full:\nenemies within 90px slow 25%",                "index": 181, "weight": 5, "rarity": "rare",      "chars": ["vector"], "min_level": 2},
	{"name": "Bloodwall Core",      "category": "Identity",      "color": Color(0.7, 0.1, 0.1),   "desc": "Below 50% HP:\nrestore 1 HP every 9s",                          "index": 182, "weight": 5, "rarity": "rare",      "chars": ["vector"], "min_level": 3},
	{"name": "Overcharge Core",     "category": "Identity",      "color": Color(0.0, 0.7, 1.0),   "desc": "15+ Momentum: every 4s\ndeal 2 dmg pulse within 60px",          "index": 183, "weight": 4, "rarity": "rare",      "chars": ["vector"], "min_level": 3, "requires": [35]},
	{"name": "Anchor Pulse Core",   "category": "Identity",      "color": Color(0.35, 0.5, 0.75), "desc": "Stationary for 5s: gain\n1 Armor every 1s",                     "index": 184, "weight": 5, "rarity": "uncommon",  "chars": ["vector"], "min_level": 1},
	# ── Vector — Calamity ─────────────────────────────────────────────────────
	{"name": "Shockwave",         "category": "Calamity",      "color": Color(0.5, 0.5, 0.9),  "desc": "AoE damage equal to Armor/2 to all enemies in the Yard",           "index": 174, "weight": 2,  "rarity": "epic",      "chars": ["vector"], "min_level": 3},
	{"name": "Full Breach",       "category": "Calamity",      "color": Color(0.9, 0.2, 0.1),  "desc": "Armor resets, 8s:\nCore Damage ×2.5",                   "index": 175, "weight": 2,  "rarity": "legendary", "chars": ["vector"], "min_level": 4},
	{"name": "Momentum Burst",    "category": "Calamity",      "color": Color(0.0, 0.8, 1.0),  "desc": "Spend all Momentum:\n+5% Core Speed per stack (10s)",            "index": 176, "weight": 2,  "rarity": "legendary", "chars": ["vector"], "min_level": 4, "requires": [35]},
	{"name": "Rampart Collapse",  "category": "Calamity",      "color": Color(0.2, 0.85, 1.0),  "desc": "Deals AoE damage equal to Armor Cap\nat the targeted point. Armor resets",       "index": 177, "weight": 2,  "rarity": "legendary", "chars": ["vector"], "min_level": 5},
	{"name": "WormHole",          "category": "Calamity",      "color": Color(0.4, 0.0, 0.8),  "desc": "Opens a wormhole around Vector\nApproaching enemies vanish into the void (Boss immune)", "index": 198, "weight": 2, "rarity": "legendary", "chars": ["vector"], "min_level": 4},
	{"name": "Siege Rain",        "category": "Calamity",      "color": Color(0.4, 0.4, 0.5),  "desc": "7s: a Siege Core falls on the\ntarget area every 0.5s",     "index": 199, "weight": 2,  "rarity": "legendary", "chars": ["vector"], "min_level": 4},
	# ── Leila (Elemental) ─────────────────────────────────────────────────────
	{"name": "Electric Core",       "category": "Identity",      "color": Color(0.2, 0.5, 1.0), "desc": "Core gains electricity",                    "index": 1,  "weight": 10, "rarity": "common", "chars": ["leila"], "min_level": 0},
	{"name": "Cryo Core",           "category": "Identity",      "color": Color(0.5, 0.8, 1.0), "desc": "Slows subject by 25%",                      "index": 15, "weight": 10, "rarity": "common", "chars": ["leila"], "min_level": 0},
	{"name": "Hydro Core",          "category": "Identity",      "color": Color(0.0, 0.5, 1.0), "desc": "Applies wet, single hit",                   "index": 17, "weight": 10, "rarity": "common", "chars": ["leila"], "min_level": 0},
	{"name": "Pyro Core",           "category": "Identity",      "color": Color(1.0, 0.3, 0.0), "desc": "Applies burn to subject",                   "index": 18, "weight": 10, "rarity": "common", "chars": ["leila"], "min_level": 0},
	{"name": "Electric Amp",        "category": "Utility",       "color": Color(0.2, 0.5, 1.0), "desc": "Electric Core +2 damage",                   "index": 13,  "weight": 10, "rarity": "common",   "chars": ["leila"], "min_level": 0},
	{"name": "Cryo Amp",            "category": "Utility",       "color": Color(0.5, 0.8, 1.0), "desc": "Cryo Core +2 damage",                       "index": 99,  "weight": 10, "rarity": "common",   "chars": ["leila"], "min_level": 0},
	{"name": "Hydro Amp",           "category": "Utility",       "color": Color(0.0, 0.5, 1.0), "desc": "Hydro Core +2 damage",                      "index": 100, "weight": 10, "rarity": "common",   "chars": ["leila"], "min_level": 0},
	{"name": "Pyro Amp",            "category": "Utility",       "color": Color(1.0, 0.3, 0.0), "desc": "Pyro Core +2 damage",                       "index": 101, "weight": 10, "rarity": "common",   "chars": ["leila"], "min_level": 0},
	{"name": "Conduction",         "category": "Utility",       "color": Color(0.3, 0.5, 1.0), "desc": "Electric reaction range +30%",               "index": 66,  "weight": 8,  "rarity": "uncommon", "chars": ["leila"], "min_level": 0},
	{"name": "Hydro Pressure",     "category": "Utility",       "color": Color(0.1, 0.5, 0.9), "desc": "Wet uygulayan core'lar %25 hızlı\nFırlatılan: hız / Connected: orbit dönüşü",  "index": 67,  "weight": 8,  "rarity": "uncommon", "chars": ["leila"], "min_level": 0, "requires_any": [17, 62, 65, 185]},
	{"name": "Arc Amplifier",      "category": "Utility",       "color": Color(0.2, 0.4, 1.0), "desc": "Arc Core +1 düşmana daha yayar",              "index": 68,  "weight": 8,  "rarity": "uncommon", "chars": ["leila"], "min_level": 0, "requires": [63]},
	{"name": "Static Charge",      "category": "Utility",       "color": Color(0.4, 0.6, 1.0), "desc": "Electrified enemies transfer damage\nto each other", "index": 69, "weight": 6, "rarity": "uncommon", "chars": ["leila"], "min_level": 0},
	{"name": "Supercooling",       "category": "Utility",       "color": Color(0.5, 0.8, 1.0), "desc": "Cryo Slow +%15",                 "index": 71,  "weight": 8,  "rarity": "uncommon", "chars": ["leila"], "min_level": 0},
	{"name": "Thermal Vision",     "category": "Utility",       "color": Color(1.0, 0.5, 0.1), "desc": "Burn tick hasarı +%20",            "index": 73,  "weight": 6,  "rarity": "uncommon", "chars": ["leila"], "min_level": 1},
	{"name": "Mystic Flow",        "category": "Individuality", "color": Color(0.5, 0.7, 1.0), "desc": "Each unique element applied\n→ +1% Move Speed (max 20%)", "index": 76, "weight": 6, "rarity": "uncommon", "chars": ["leila"], "min_level": 1},
	{"name": "Elemental Memory",   "category": "Individuality", "color": Color(0.7, 0.7, 1.0), "desc": "Reaksiyon geçiren düşmana\nsonraki debuff 2× uzun sürer", "index": 86, "weight": 4, "rarity": "uncommon", "chars": ["leila"], "min_level": 0},
	{"name": "Resonant Soul",      "category": "Individuality", "color": Color(0.8, 0.6, 1.0), "desc": "Each Reaction → restore 2 HP",                "index": 85,  "weight": 5,  "rarity": "uncommon", "chars": ["leila"], "min_level": 0},
	# Lv1: İlk özel core'lar + reaksiyon temeli
	{"name": "Plasma Core",        "category": "Identity",      "color": Color(0.4, 0.6, 1.0), "desc": "Bounces to Electrified enemies",             "index": 61, "weight": 8,  "rarity": "uncommon",  "chars": ["leila"], "min_level": 1},
	{"name": "Arc Core",           "category": "Identity",      "color": Color(0.3, 0.5, 1.0), "desc": "Electrified hedefe çarptığında\ndebuff 2 yakın düşmana yayılır",               "index": 63, "weight": 8,  "rarity": "uncommon",  "chars": ["leila"], "min_level": 1},
	{"name": "Arcane Mind",        "category": "Utility",       "color": Color(0.7, 0.5, 1.0), "desc": "First applied element lasts 100% longer",     "index": 80, "weight": 5,  "rarity": "rare",      "chars": ["leila"], "min_level": 1},
	{"name": "Frozen Time",        "category": "Utility",       "color": Color(0.6, 0.85, 1.0),"desc": "Freeze duration +30%",                       "index": 82, "weight": 5,  "rarity": "rare",      "chars": ["leila"], "min_level": 1},
	{"name": "Overheat",           "category": "Utility",       "color": Color(1.0, 0.4, 0.0), "desc": "33 Burn tick sonra\n150px'e 15 hasar patlaması",                "index": 83, "weight": 4,  "rarity": "rare",      "chars": ["leila"], "min_level": 1},
	# Lv2: Orta seviye core'lar + sinerjiler
	{"name": "Steam Core",         "category": "Identity",      "color": Color(0.7, 0.9, 1.0), "desc": "Çarptığı noktada buhar bulutu bırakır\nYakındaki düşmanlara Wet uygular",         "index": 62, "weight": 8,  "rarity": "uncommon",  "chars": ["leila"], "min_level": 2},
	{"name": "Echo Core",          "category": "Identity",      "color": Color(0.6, 0.8, 1.0), "desc": "Copies element from Debuffed enemy on hit.\nApplies it on return.", "index": 64, "weight": 6, "rarity": "uncommon", "chars": ["leila"], "min_level": 2},
	{"name": "Elemental Harmony",  "category": "Utility",       "color": Color(0.8, 0.8, 1.0), "desc": "Per unique active element:\n+5% Core Speed",      "index": 84, "weight": 4, "rarity": "rare",   "chars": ["leila"], "min_level": 2},
	{"name": "Resonance Engine",   "category": "Utility",       "color": Color(0.6, 0.4, 1.0), "desc": "Reaksiyon → +1 Momentum\n+%2 Core Speed (kalıcı, birikir)", "index": 81, "weight": 5, "rarity": "rare", "chars": ["leila"], "min_level": 2},
	{"name": "Pyroblast",          "category": "Utility",       "color": Color(1.0, 0.4, 0.0), "desc": "Burn explosions gain Area\nbased on Burn Stacks",       "index": 102, "weight": 3, "rarity": "rare",  "chars": ["leila"], "min_level": 2},
	# Lv3: Rare core'lar + Calamity giriş
	{"name": "Prism Core",         "category": "Identity",      "color": Color(0.5, 0.7, 1.0), "desc": "Orbit'te kalır, yakındaki düşmanlara\nrastgele element uygular",           "index": 65, "weight": 5, "rarity": "rare",     "chars": ["leila"], "min_level": 2},
	{"name": "Scatter Core",       "category": "Identity",      "color": Color(0.5, 0.8, 0.7), "desc": "On hit → splits into 3 small\nrandom Elemental Cores", "index": 77, "weight": 6, "rarity": "rare", "chars": ["leila"], "min_level": 3},
	{"name": "Catalyst Core",      "category": "Identity",      "color": Color(0.8, 0.6, 1.0), "desc": "Extends duration of existing\nstatus effects on hit",   "index": 78, "weight": 6, "rarity": "rare", "chars": ["leila"], "min_level": 3},
	{"name": "Monsoon",            "category": "Calamity",      "color": Color(0.1, 0.5, 1.0), "desc": "All enemies in the Yard\ngain Wet",           "index": 95, "weight": 3,  "rarity": "epic",      "chars": ["leila"], "min_level": 3},
	{"name": "EMP Pulse",          "category": "Calamity",      "color": Color(0.2, 0.4, 1.0), "desc": "All Electrified enemies\nin the Yard take 15 dmg","index": 96, "weight": 3,  "rarity": "epic",      "chars": ["leila"], "min_level": 3},
	# Lv4: Epic tier
	{"name": "Voltaic Core",       "category": "Identity",      "color": Color(0.2, 0.4, 1.0), "desc": "Electrified hedefe çarptığında\nhasar zinciri (3 düşmana kadar)", "index": 87, "weight": 4, "rarity": "epic", "chars": ["leila"], "min_level": 4},
	{"name": "Thermal Expansion",  "category": "Utility",       "color": Color(0.7, 0.9, 1.0), "desc": "Steam explosion area grows",                        "index": 89,  "weight": 3, "rarity": "epic",  "chars": ["leila"], "min_level": 4},
	{"name": "Mana Overflow",      "category": "Utility",       "color": Color(0.6, 0.4, 1.0), "desc": "Using Calamity empowers\nall Cores briefly",   "index": 90, "weight": 3,  "rarity": "epic",      "chars": ["leila"], "min_level": 4},
	# Lv5: Legendary endgame
	{"name": "Perfect Catalyst",   "category": "Utility",       "color": Color(0.9, 0.7, 1.0), "desc": "Reaction → reapply last used element",        "index": 91, "weight": 3,  "rarity": "epic",      "chars": ["leila"], "min_level": 5},
	# ── Leila Calamity ────────────────────────────────────────────────────────
	{"name": "Blizzard",           "category": "Calamity",      "color": Color(0.6, 0.9, 1.0), "desc": "Islak tüm düşmanları\nanında dondurur",        "index": 94, "weight": 2,  "rarity": "legendary", "chars": ["leila"], "min_level": 4},
	{"name": "Volcanic Rift",      "category": "Calamity",      "color": Color(1.0, 0.3, 0.0), "desc": "Leaves lava trail on ground",                 "index": 97, "weight": 2,  "rarity": "legendary", "chars": ["leila"], "min_level": 4},
	{"name": "Thunderstorm",       "category": "Calamity",      "color": Color(0.3, 0.5, 1.0), "desc": "Random lightning strikes for 5s",             "index": 98, "weight": 2,  "rarity": "legendary", "chars": ["leila"], "min_level": 5},
	# ── Leila Connected Cores (iç yörünge) ───────────────────────────────────
	{"name": "Mist Core",             "category": "Identity",      "color": Color(0.3, 0.6, 1.0),  "desc": "Her 4s: 70px içinde 1 düşmana\nWet uygular",                    "index": 185, "weight": 5, "rarity": "uncommon",  "chars": ["leila"], "min_level": 1},
	{"name": "Frost Aura Core",       "category": "Identity",      "color": Color(0.5, 0.85, 1.0), "desc": "50px içine giren düşmanlar\notomatik Slow alır",                 "index": 186, "weight": 5, "rarity": "rare",      "chars": ["leila"], "min_level": 2},
	{"name": "Static Aura Core",      "category": "Identity",      "color": Color(0.9, 0.9, 0.2),  "desc": "60px içine giren düşmanlar\nElectrified olur (3s CD/düşman)",    "index": 187, "weight": 5, "rarity": "rare",      "chars": ["leila"], "min_level": 2},
	{"name": "Catalyst Pulse Core",   "category": "Identity",      "color": Color(0.7, 0.4, 1.0),  "desc": "Her 3s: 120px'teki debufflı\ndüşmanların süresi +1s uzar",        "index": 188, "weight": 4, "rarity": "rare",      "chars": ["leila"], "min_level": 2},
	{"name": "Echo Resonance Core",   "category": "Identity",      "color": Color(0.4, 0.7, 1.0),  "desc": "Her 5s: 1s boyunca 80px'e\nson uyguladığın elementi yayar",       "index": 189, "weight": 4, "rarity": "epic",      "chars": ["leila"], "min_level": 3},
	{"name": "Volatile Aura Core",    "category": "Identity",      "color": Color(0.95, 0.4, 0.9), "desc": "Reaksiyon tetiklince:\n80px'e 2 hasar pulse",                     "index": 190, "weight": 4, "rarity": "epic",      "chars": ["leila"], "min_level": 3},
	{"name": "Elemental Shield Core", "category": "Identity",      "color": Color(0.3, 0.9, 0.6),  "desc": "Son uyguladığın element:\no elementin hasarına %20 direnç",        "index": 191, "weight": 4, "rarity": "rare",      "chars": ["leila"], "min_level": 2},
	# Individuality
	{"name": "Wet Armor",       "category": "Individuality", "color": Color(0.1, 0.5, 0.9),  "desc": "Islak düşman varken\n%10 az hasar alırsın",                    "index": 200, "weight": 8,  "rarity": "uncommon",  "chars": ["leila"], "min_level": 0},
	{"name": "Burn Frenzy",     "category": "Individuality", "color": Color(1.0, 0.4, 0.1),  "desc": "Her yanan düşman için\nburn tick hasarı +1 (maks +7)",             "index": 201, "weight": 8,  "rarity": "uncommon",  "chars": ["leila"], "min_level": 1},
	{"name": "Steam Surge",     "category": "Individuality", "color": Color(0.7, 0.9, 1.0),  "desc": "Steam reaksiyonu:\n3s boyunca +15% hareket hızı",              "index": 202, "weight": 8,  "rarity": "uncommon",  "chars": ["leila"], "min_level": 1},
	{"name": "Shock Reflex",    "category": "Individuality", "color": Color(0.4, 0.6, 1.0),  "desc": "Electrocute reaksiyonu:\n3s için +8% hasar kaçınma",            "index": 203, "weight": 7,  "rarity": "uncommon",  "chars": ["leila"], "min_level": 2},
	{"name": "Frost Barrier",   "category": "Individuality", "color": Color(0.6, 0.9, 1.0),  "desc": "Freeze reaksiyonu: +5 HP kalkan\n(birikir, maks 20, 4s)",                    "index": 204, "weight": 6,  "rarity": "rare",      "chars": ["leila"], "min_level": 2},
	{"name": "Primal Instinct", "category": "Individuality", "color": Color(0.9, 0.7, 1.0),  "desc": "Bir dalgada 3 farklı reaksiyon:\n5s için +10% hasar",           "index": 205, "weight": 5,  "rarity": "rare",      "chars": ["leila"], "min_level": 3},
	{"name": "Melt Spiral",     "category": "Individuality", "color": Color(1.0, 0.5, 0.2),  "desc": "Melt reaksiyonu:\ndüşmanın konumunda 2s alev bırakır (1/s)",  "index": 206, "weight": 5,  "rarity": "rare",      "chars": ["leila"], "min_level": 3},
	{"name": "Void Resonance",  "category": "Individuality", "color": Color(0.7, 0.3, 1.0),  "desc": "Dalgada 4 farklı reaksiyon:\nsonraki Calamity slot tüketmez",  "index": 207, "weight": 2,  "rarity": "epic",      "chars": ["leila"], "min_level": 5},
	# Calamity
	{"name": "Wildfire",        "category": "Calamity",      "color": Color(1.0, 0.3, 0.0),  "desc": "Tüm Yanan düşmanlar patlar\n(10 hasar, 2 yakına yayılır)",     "index": 209, "weight": 3,  "rarity": "epic",      "chars": ["leila"], "min_level": 4},
	# Utility
	{"name": "Cryo Burst",      "category": "Utility",       "color": Color(0.6, 0.85, 1.0), "desc": "Yavaşlatılmış düşmana\nsonraki vuruş +8 bonus hasar",          "index": 210, "weight": 5,  "rarity": "rare",      "chars": ["leila"], "min_level": 2},
	{"name": "Arc Overload",    "category": "Utility",       "color": Color(0.3, 0.5, 1.0),  "desc": "Electrocute: 180px içinde\n1 ek düşmana 5 hasar zinciri",                "index": 211, "weight": 4,  "rarity": "rare",      "chars": ["leila"], "min_level": 3},
	# ── Cyclone (Manipülasyon) ────────────────────────────────────────────────
	# Identity — Core kartları
	{"name": "Glitch Core",          "category": "Identity",      "color": Color(0.8, 0.0, 0.8),  "desc": "Disorients subject for 3s",                                "index": 16,  "weight": 10, "rarity": "common",    "chars": ["cyclone"], "min_level": 0},
	{"name": "Echo Core",            "category": "Identity",      "color": Color(0.5, 0.5, 1.0),  "desc": "Copies the nearest powered-up core",                       "index": 19,  "weight": 1,  "rarity": "epic",      "chars": ["cyclone"], "min_level": 3},
	{"name": "Data Leech Core",      "category": "Identity",      "color": Color(0.6, 0.0, 0.2),  "desc": "+2 Integrity on hit",                                      "index": 22,  "weight": 10, "rarity": "common",    "chars": ["cyclone"], "min_level": 0},
	{"name": "Virus Core",       "category": "Identity",      "color": Color(0.1, 0.75, 0.3),  "desc": "Hit → 1 Antivirus stack\n(1 dmg/s, 3s, stackable)",       "index": 160, "weight": 9,  "rarity": "common",    "chars": ["cyclone"], "min_level": 0},
	{"name": "Decay Core",           "category": "Identity",      "color": Color(0.5, 0.3, 0.0),  "desc": "Hit → 1 Decay stack (max 3)\n5% slow/stack; death: 2 dmg/stack","index": 161, "weight": 8,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1},
	{"name": "Static Core",          "category": "Identity",      "color": Color(0.8, 0.8, 0.2),  "desc": "Hit → slow 40% for 0.5s\nGlitched target: 1s instead",     "index": 162, "weight": 8,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1},
	{"name": "Ricochet Core",        "category": "Identity",      "color": Color(0.45, 0.1, 0.9),  "desc": "Duvar sekmesi → +%5 hız (maks +%30)\nHer 10 hız = +1 hasar; düşmana çarpınca sıfır", "index": 163, "weight": 8,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1},
	{"name": "Phantom Circuit Core", "category": "Identity",      "color": Color(0.3, 0.8, 0.9),  "desc": "Bu fırlatışta ilk isabet: 0.5s sersemletir\nPlayer'a dönene kadar tekrar tetiklenmez", "index": 159, "weight": 6,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2},
	# Utility — Lv0
	{"name": "Data Exploit",         "category": "Utility",       "color": Color(0.7, 0.1, 0.5),  "desc": "Glitch'li hedef +1 bonus hasar\n(taban +3)",                "index": 115, "weight": 10, "rarity": "common",    "chars": ["cyclone"], "min_level": 0},
	{"name": "Extended Glitch",      "category": "Utility",       "color": Color(0.75, 0.0, 0.7), "desc": "Glitch süresi +1 Saniye\n(3s taban)",                       "index": 119, "weight": 9,  "rarity": "common",    "chars": ["cyclone"], "min_level": 0},
	{"name": "Angular Precision",    "category": "Utility",       "color": Color(0.45, 0.2, 0.8), "desc": "Her uçuşun ilk vuruşu: +%5 hasar\n(taban +%15)",           "index": 131, "weight": 8,  "rarity": "common",    "chars": ["cyclone"], "min_level": 0},
	{"name": "Signal Jam",           "category": "Utility",       "color": Color(0.6, 0.0, 0.6),  "desc": "Glitch'li düşman hızı: +%5\n(taban +%15)",                 "index": 120, "weight": 9,  "rarity": "common",    "chars": ["cyclone"], "min_level": 0},
	# Utility — Lv1
	{"name": "Bounce Mastery",       "category": "Utility",       "color": Color(0.45, 0.1, 0.9), "desc": "Ricochet Strike bonusu: +1\n(taban 4 → 6)",                "index": 133, "weight": 6,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1, "requires": [114]},
	{"name": "Backstab Protocol",    "category": "Utility",       "color": Color(0.15, 0.55, 0.35),"desc": "Kuzey duvar sekmesi: sonraki vuruş\n+%25 daha fazla (taban ×1.5)",  "index": 158, "weight": 6,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1},
	{"name": "Stack Overflow",       "category": "Utility",       "color": Color(0.1, 0.8, 0.35),  "desc": "Antivirus stack cap +1\n(taban 3 → 4)",                    "index": 148, "weight": 7,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1, "requires": [160]},
	{"name": "Memory Leak",          "category": "Utility",       "color": Color(0.05, 0.65, 0.3), "desc": "Antivirus süresi +1 saniye\n(taban 5s → 6s)",              "index": 150, "weight": 7,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1, "requires": [160]},
	{"name": "Cascade Delete",       "category": "Utility",       "color": Color(0.1, 0.7, 0.45),  "desc": "Virus isabeti en yakın düşmana yayılır\nLv1: 75px/1, Lv2: 100px/1, Lv3: 125px/2 düşman", "index": 152, "weight": 6,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1, "requires": [160]},
	# Utility — Lv2
	{"name": "Pinball Protocol",     "category": "Utility",       "color": Color(0.4, 0.1, 0.95), "desc": "Gereken sekme -1 (pierce kazanmak için)\nLv1: 5, Lv2: 4, Lv3: 3 sekme", "index": 134, "weight": 5,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2, "requires": [163]},
	{"name": "Stealth Pass",         "category": "Utility",       "color": Color(0.25, 0.7, 0.85),"desc": "Phantom Circuit Core: sersemlenen\ndüşman sayısı +1 (taban 1)",  "index": 139, "weight": 5,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 2, "requires": [159]},
	{"name": "Ghost Protocol",       "category": "Utility",       "color": Color(0.2, 0.75, 0.9), "desc": "Phantom Circuit Core sersemletme süresi\nLv1: 0.75s, Lv2: 1.0s, Lv3: 1.5s (taban 0.5s)", "index": 140, "weight": 4,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2, "requires": [159]},
	{"name": "Corruption Protocol",  "category": "Utility",       "color": Color(0.0, 0.6, 0.3),  "desc": "Virus'lü hedef +%5 fazla hasar\nLv1: %15, Lv2: %20, Lv3: %25",  "index": 151, "weight": 5,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2, "requires": [160]},
	# Individuality — Lv1
	{"name": "Ricochet Strike",      "category": "Individuality", "color": Color(0.5, 0.2, 0.9),  "desc": "Each wall bounce in flight:\nnext hit +4 dmg",             "index": 114, "weight": 8,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1, "requires": [163]},
	{"name": "Rogue's Instinct",     "category": "Individuality", "color": Color(0.6, 0.15, 0.4), "desc": "Enemy purified:\n+1 Integrity",                            "index": 145, "weight": 7,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1},
	{"name": "Data Siphon",          "category": "Individuality", "color": Color(0.6, 0.0, 0.35), "desc": "Data Leech heals +1 extra\nwhen target has Decay stacks",        "index": 121, "weight": 7,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1, "requires": [22, 161]},
	{"name": "Viral Load",           "category": "Individuality", "color": Color(0.15, 0.7, 0.4),  "desc": "Glitched target receives\n2× Antivirus stacks",            "index": 149, "weight": 7,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1, "requires": [160]},
	# Individuality — Lv2
	{"name": "Shadow Strike",        "category": "Individuality", "color": Color(0.3, 0.0, 0.5),  "desc": "Sağ/sol duvar sekmesi sonrası\nilk vuruş: ×1.5 hasar",                "index": 116, "weight": 5,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2},
	{"name": "System Overload",      "category": "Individuality", "color": Color(0.85, 0.1, 0.7), "desc": "5+ Glitched enemies alive:\nall your dmg +20%",             "index": 126, "weight": 5,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2},
	{"name": "Kinetic Rogue",        "category": "Individuality", "color": Color(0.45, 0.15, 0.9),"desc": "Tek fırlatışta 5 sekme: tüm Ricochet\nCore'lara +1 kalıcı hasar (dönünce sıfırlanır)", "index": 136, "weight": 4,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2, "requires": [163]},
	{"name": "Phase Shift",          "category": "Individuality", "color": Color(0.3, 0.8, 0.9),  "desc": "Stunned enemy hit:\n×1.5 damage",                          "index": 141, "weight": 4,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2, "requires": [159]},
	{"name": "Shadow Dance",         "category": "Individuality", "color": Color(0.35, 0.05, 0.6),"desc": "7 wall bounces in same flight:\nCore Speed +3% permanently", "index": 146, "weight": 4,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2},
	# Individuality — Lv3
	{"name": "Circuit Breaker",      "category": "Individuality", "color": Color(0.25, 0.75, 0.95),"desc": "Every 25th hit: all enemies\nin the Yard Glitched for 3s", "index": 143, "weight": 3,  "rarity": "epic",      "chars": ["cyclone"], "min_level": 3},
	{"name": "Zero Day",             "category": "Individuality", "color": Color(0.0, 0.85, 0.4),  "desc": "Glitch'li düşmana Virus uygulanınca\nmevcut stack ×2 olur",   "index": 154, "weight": 3,  "rarity": "epic",      "chars": ["cyclone"], "min_level": 3, "requires": [160]},
	{"name": "Kernel Panic",         "category": "Individuality", "color": Color(0.05, 0.9, 0.35), "desc": "Each Antivirus tick:\n5% chance to Glitch target",         "index": 155, "weight": 3,  "rarity": "epic",      "chars": ["cyclone"], "min_level": 3, "requires": [160]},
	# Calamity
	{"name": "Data Storm",           "category": "Calamity",      "color": Color(0.7, 0.0, 0.8),  "desc": "All Glitched enemies\nin the Yard take 10 dmg",             "index": 129, "weight": 2,  "rarity": "legendary", "chars": ["cyclone"], "min_level": 3},
	{"name": "Backdoor",             "category": "Calamity",      "color": Color(0.6, 0.0, 0.7),  "desc": "All enemies in the Yard\nGlitched for 3s",                  "index": 130, "weight": 2,  "rarity": "legendary", "chars": ["cyclone"], "min_level": 4},
	{"name": "Bounce Barrage",       "category": "Calamity",      "color": Color(0.35, 0.0, 0.9),  "desc": "Core Speed ×3 for 5s",                                   "index": 138, "weight": 2,  "rarity": "legendary", "chars": ["cyclone"], "min_level": 4},
	{"name": "Mirror Image",         "category": "Calamity",      "color": Color(0.2, 0.65, 0.9),  "desc": "Spawn 2 phantom cores\nfor 25s",                          "index": 144, "weight": 2,  "rarity": "legendary", "chars": ["cyclone"], "min_level": 4},
	{"name": "Systemic Failure",     "category": "Calamity",      "color": Color(0.0, 0.7, 0.35),  "desc": "All enemies in the Yard\nget 2× Antivirus stacks",        "index": 156, "weight": 2,  "rarity": "legendary", "chars": ["cyclone"], "min_level": 4},
	# ── Cyclone Connected Cores (iç yörünge) ─────────────────────────────────
	{"name": "Glitch Pulse Core",    "category": "Identity",      "color": Color(0.8, 0.0, 0.8),   "desc": "Her 4s: 80px içinde 1 düşmana\nGlitch uygular",                 "index": 192, "weight": 5, "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1},
	{"name": "Shadow Core",          "category": "Identity",      "color": Color(0.2, 0.05, 0.4),  "desc": "Dash sonrası 3s:\n50px çevresine 1 hasar/s",      "index": 193, "weight": 4, "rarity": "rare",      "chars": ["cyclone"], "min_level": 2},
	{"name": "Data Drain Core",      "category": "Identity",      "color": Color(0.6, 0.0, 0.25),  "desc": "Glitch'li düşman 60px içindeyse\nher 1s: +1 HP",                 "index": 194, "weight": 5, "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1},
	{"name": "Virus Beacon Core",    "category": "Identity",      "color": Color(0.1, 0.75, 0.3),  "desc": "Antivirus'lü düşman 80px'te ölürse\n3s: 100px'e 1 stack yayar", "index": 195, "weight": 4, "rarity": "rare",      "chars": ["cyclone"], "min_level": 2},
	{"name": "Rogue's Eye Core",     "category": "Identity",      "color": Color(0.9, 0.6, 0.1),   "desc": "Her 7s: en yakın düşmanı işaretle\n(3s, %10 fazla hasar alır)",  "index": 196, "weight": 4, "rarity": "rare",      "chars": ["cyclone"], "min_level": 2},
	{"name": "Circuit Overload Core","category": "Identity",      "color": Color(0.25, 0.75, 0.95),"desc": "Circuit Breaker tetiklenince\n3s: 90px çevresine sürekli Glitch",  "index": 197, "weight": 3, "rarity": "epic",      "chars": ["cyclone"], "min_level": 3},
	# Identity — yeni Core'lar
	{"name": "Tracer Core",    "category": "Identity",      "color": Color(0.7, 0.2, 1.0),  "desc": "Vuruşta 1s takip izi bırakır\nİzden geçen düşman 0.5s yavaşlar",  "index": 212, "weight": 8,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1},
	{"name": "Spike Core",     "category": "Identity",      "color": Color(0.5, 0.15, 0.0), "desc": "İsabet: hedefte 3 Decay stack varsa\nanında Decay patlaması tetikler", "index": 213, "weight": 6,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2},
	{"name": "Leech Nova Core","category": "Identity",      "color": Color(0.6, 0.0, 0.3),  "desc": "Öldürünce: +2 HP\n80px çevresine 1s Glitch",                        "index": 214, "weight": 4,  "rarity": "epic",      "chars": ["cyclone"], "min_level": 3},
	# Calamity — Rare/Epic
	{"name": "Glitch Bomb",    "category": "Calamity",      "color": Color(0.75, 0.0, 0.85),"desc": "Seçilen 120px alana 4s Glitch uygular",                              "index": 215, "weight": 2,  "rarity": "legendary", "chars": ["cyclone"], "min_level": 3},
	{"name": "System Crash",   "category": "Calamity",      "color": Color(0.8, 0.1, 0.6),  "desc": "Tüm Glitch'li düşmanlar\nmevcut HP'nin %%30'unu kaybeder",          "index": 216, "weight": 4,  "rarity": "epic",      "chars": ["cyclone"], "min_level": 3},
	{"name": "Virus Rain", "category": "Calamity",      "color": Color(0.1, 0.85, 0.4),  "desc": "3s boyunca her 0.5s:\ntüm düşmanlara 1 Antivirus stack",           "index": 217, "weight": 2,  "rarity": "legendary", "chars": ["cyclone"], "min_level": 3},
	{"name": "Decay Field",    "category": "Calamity",      "color": Color(0.45, 0.2, 0.0),  "desc": "5s: seçilen 100px alana aura\ngiren düşmanlar her 1s'de 1 Decay alır","index": 218, "weight": 4,  "rarity": "epic",      "chars": ["cyclone"], "min_level": 3},
	# Individuality
	{"name": "Decay Harvest",       "category": "Individuality", "color": Color(0.5, 0.25, 0.0), "desc": "Decay patlaması tetiklenince:\n+2 HP kazan",                    "index": 219, "weight": 7,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1, "requires": [161]},
	{"name": "Ghost Step",          "category": "Individuality", "color": Color(0.3, 0.8, 0.9),  "desc": "Dash sonrası 1.5s hasar bağışıklığı\n(5s bekleme süresi)",     "index": 220, "weight": 5,  "rarity": "rare",      "chars": ["cyclone"], "min_level": 2},
	{"name": "Overclock Protocol",  "category": "Individuality", "color": Color(0.25, 0.9, 0.95),"desc": "Circuit Breaker sayacı\n2× hızlı dolar",                       "index": 221, "weight": 3,  "rarity": "epic",      "chars": ["cyclone"], "min_level": 4, "requires": [143]},
	# Utility
	{"name": "Decay Amp",   "category": "Utility", "color": Color(0.55, 0.25, 0.0), "desc": "Decay patlaması hasarı (stack başına)\nLv1: 3, Lv2: 5, Lv3: 7 (taban 2)",  "index": 222, "weight": 7,  "rarity": "uncommon",  "chars": ["cyclone"], "min_level": 1},
	{"name": "Chain Extension", "category": "Utility", "color": Color(0.7, 0.6, 0.3), "desc": "Zincir 5 halka uzar\n(hareket alanı genişler)",                         "index": 224, "weight": 6,  "rarity": "uncommon",  "chars": [],           "min_level": 0},
	# ── Herkese açık ─────────────────────────────────────────────────────────
	{"name": "Core Mastery",        "category": "Utility",       "color": Color(0.2, 0.8, 0.2), "desc": "+1 damage to all cores",                    "index": 11, "weight": 10, "rarity": "common", "chars": [], "min_level": 0},
	{"name": "Lightning",           "category": "Calamity",      "color": Color(1.0, 1.0, 0.0), "desc": "Lightning strikes selected point",          "index": 7,  "weight": 3,  "rarity": "epic",   "chars": ["leila"], "min_level": 2},
	{"name": "Flame Zone",          "category": "Calamity",      "color": Color(1.0, 0.3, 0.0), "desc": "Continuous damage in selected area",        "index": 8,  "weight": 3,  "rarity": "epic",   "chars": ["leila"], "min_level": 2},
]
	# ── TEST MODE — false yapınca normal ağırlıklara döner ──────────────────
	const TEST_ELEMENTAL: bool = false
	if TEST_ELEMENTAL:
		var _focus = ["Electric Core", "Cryo Core", "Hydro Core", "Pyro Core",
					  "Electric Amp", "Cryo Amp", "Hydro Amp", "Pyro Amp",
					  "Elemental Memory"]
		for u in upgrades:
			u["min_level"] = 0
			if u.get("name", "") in _focus:
				u["weight"] = 99
			elif u.get("category") == "Calamity":
				u["weight"] = 50
			elif "leila" in u.get("chars", []):
				u["weight"] = 1
	# ─────────────────────────────────────────────────────────────────────────

	_all_upgrades = upgrades.duplicate()

func _get_card_art_path(card: Dictionary, char_id: String) -> String:
	var category: String = card.get("category", "")
	var card_name: String = card.get("name", "")
	var chars: Array = card.get("chars", [])
	var file_name := card_name.to_lower().replace(" ", "_") + "_art.png"
	var cat_folder: String = ({"Identity": "identityCards", "Utility": "utilityCards",
		"Individuality": "individualityCards", "Calamity": "calamityCards"} as Dictionary).get(category, "")
	if cat_folder == "":
		return ""
	# Shared kart: chars boş veya birden fazla karakter
	if chars.size() != 1:
		var shared_path := "res://assets/upgradeCardsArt/Shared/%s/%s" % [cat_folder, file_name]
		return shared_path
	var char_folder: String = ({"vector": "Vector", "leila": "Leila", "cyclone": "Cyclone"} as Dictionary).get(char_id, "")
	if char_folder == "":
		return ""
	var path := "res://assets/upgradeCardsArt/%s/%s/%s" % [char_folder, cat_folder, file_name]
	return path

func show_upgrade_menu() -> void:
	upgrading = true
	# Void Resonance: her dalga başında reaksiyon sayacı sıfırla
	var _vr_p := get_node_or_null("Player")
	if _vr_p:
		_vr_p._wave_reaction_types.clear()
		# Void Resonance ücretsiz Calamity hazırsa slot tüketmeme flag'i zaten set
	_build_all_upgrades()
	var char_id: String = get_node("Player").character_type
	var char_level: int = GameData.get_level(char_id)
	upgrades = upgrades.filter(func(u): return u["chars"].is_empty() or char_id in u["chars"])
	upgrades = upgrades.filter(func(u): return u.get("min_level", 0) <= char_level)
	upgrades = upgrades.filter(func(u):
		if u["category"] == "Individuality":
			return not (u["name"] in _seen_individualities)
		return true
	)
	upgrades = upgrades.filter(func(u):
		if u["category"] == "Utility":
			return _utility_levels.get(u["name"], 0) < 3
		return true
	)
	upgrades = upgrades.filter(func(u):
		var req: Array = u.get("requires", [])
		for r in req:
			if r not in _owned_indices:
				return false
		return true
	)
	upgrades = upgrades.filter(func(u):
		var req_any: Array = u.get("requires_any", [])
		if req_any.is_empty():
			return true
		for r in req_any:
			if r in _owned_indices:
				return true
		return false
	)
	# ── Identity limit filtresi ───────────────────────────────────────────────
	var _fp := get_node("Player")
	upgrades = upgrades.filter(func(u):
		if u.get("category", "") != "Identity":
			return true
		if u.get("index", -1) in _CONNECTED_CORE_INDICES:
			return _fp.connected_core_count < 3
		else:
			return _fp.special_core_count < 5
	)
	upgrades = _pick_rarity_weighted_cards(upgrades, level, 3)
	
	var canvas = CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	
	# ── Blur background: game scene shown blurred ─────────────────────────
	var blur_bg_rect = ColorRect.new()
	blur_bg_rect.size = Vector2(1920, 1080)
	blur_bg_rect.position = Vector2(0, 0)
	blur_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var blur_mat = ShaderMaterial.new()
	blur_mat.shader = preload("res://blur_bg.gdshader")
	blur_bg_rect.material = blur_mat
	canvas.add_child(blur_bg_rect)

	var panel = ColorRect.new()
	panel.color = Color(0, 0, 0, 0.72)
	panel.size = Vector2(1920, 1080)
	panel.position = Vector2(0, 0)
	canvas.add_child(panel)
	
	var title = Label.new()
	title.text = Lang.t("ui_level_up")
	title.position = Vector2(860, 150)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_font_override("font", _font_bold)
	title.modulate = Color(1, 0.8, 0, 0.0)
	canvas.add_child(title)
	var title_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	title_tw.tween_property(title, "modulate:a", 1.0, 0.38)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var card_width = 280
	var card_height = 400
	var start_x = 520
	
	var selected = _weighted_pick(upgrades, 3)
	for i in range(selected.size()):
		var upgrade = selected[i]
		var tx = start_x + i * (card_width + 40)
		var ty = 300
		var rarity: String = upgrade.get("rarity", "common")

		# ── Kart PNG çerçevesi ───────────────────────────────────────────────
		var rarity_prefix: String = ({"common": "001_common", "uncommon": "002_uncommon",
			"rare": "003_rare", "epic": "004_epic", "legendary": "005_legendary"} as Dictionary).get(rarity, "001_common")
		var char_folder: String = ({"vector": "vectorUpgradeCards", "leila": "leilaUpgradeCards",
			"cyclone": "cycloneUpgradeCards"} as Dictionary).get(char_id, "vectorUpgradeCards")
		var char_suffix: String = ({"vector": "VectorCard", "leila": "LeilaCard",
			"cyclone": "CycloneCard"} as Dictionary).get(char_id, "VectorCard")
		# Cyclone uncommon dosyası farklı isimde
		var card_filename: String
		if char_id == "cyclone" and rarity == "uncommon":
			card_filename = "002_uncommonCyclone.png"
		else:
			card_filename = "%s%s.png" % [rarity_prefix, char_suffix]
		var card_tex: Texture2D = load("res://assets/upgradeCardsLabel/%s/%s" % [char_folder, card_filename])
		var card_sprite := TextureRect.new()
		card_sprite.texture = card_tex
		card_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card_sprite.size = Vector2(card_width, card_height)
		card_sprite.position = Vector2(tx, ty)
		# Kart art görseli (card_sprite'dan önce eklenir, altında kalır)
		var art_bg2: Control = null
		var art_rect2: TextureRect = null
		var _art_path2 := _get_card_art_path(upgrade, char_id)
		if _art_path2 != "" and ResourceLoader.exists(_art_path2):
			art_bg2 = TextureRect.new()
			(art_bg2 as TextureRect).texture = load("res://assets/upgradeCardsArt/cardArtBackground.png")
			(art_bg2 as TextureRect).stretch_mode = TextureRect.STRETCH_TILE
			art_bg2.size = Vector2(card_width - 48, 185)
			art_bg2.position = Vector2(tx + 24, ty + 55)
			canvas.add_child(art_bg2)
			var art_tex2: Texture2D = load(_art_path2)
			art_rect2 = TextureRect.new()
			art_rect2.texture = art_tex2
			art_rect2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art_rect2.size = Vector2(card_width - 48, 185)
			art_rect2.position = Vector2(tx + 24, ty + 55)
			art_rect2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(art_rect2)

		canvas.add_child(card_sprite)

		# ── Kategori etiketi (kart üst mavi bandı) ───────────────────────────
		# PNG 162×241 → oyun 280×400 (scale=1.660, yatay margin=5.5)
		# Bant: X 48→106 (merkez 77), Y 5→11 (merkez 8)
		var cat_label := Label.new()
		cat_label.text = upgrade.get("category", "")
		var _cat_cx: float = 5.5 + 81.0 * 1.660   # ≈ 140 (merkez)
		var _cat_cy: float = 8.0 * 1.660 - 2.0      # ≈ 11 (biraz yukarı)
		var _cat_w: float  = 59.0 * 1.660           # ≈ 98
		var _cat_h: float  = 16.0                   # label yüksekliği genişletildi
		cat_label.size = Vector2(_cat_w, _cat_h)
		cat_label.position = Vector2(tx + _cat_cx - _cat_w * 0.5, ty + _cat_cy - _cat_h * 0.5)
		cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cat_label.add_theme_font_size_override("font_size", 10)
		cat_label.add_theme_font_override("font", _font_bold)
		cat_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		cat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(cat_label)

		# ── Kart ismi ────────────────────────────────────────────────────────
		var name_panel := Panel.new()
		name_panel.size = Vector2(card_width - 52, 44)
		name_panel.position = Vector2(tx + 26, ty + card_height - 116)
		name_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		canvas.add_child(name_panel)

		var name_label = Label.new()
		var _card_display_name: String = upgrade["name"]
		if upgrade["category"] == "Utility":
			var _lv: int = _utility_levels.get(upgrade["name"], 0) + 1
			_card_display_name += "  Lv.%d" % _lv
		name_label.text = _card_display_name
		name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		name_label.clip_contents = true
		var name_font_size: int = 17
		if upgrade["name"].length() > 14:
			name_font_size = 14
		name_label.add_theme_font_size_override("font_size", name_font_size)
		name_label.add_theme_font_override("font", _font_bold)
		name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		name_panel.add_child(name_label)

		# ── Kart açıklaması ──────────────────────────────────────────────────
		# Panel içine Label — Panel sabit width verir, autowrap çalışır
		var desc_panel := Panel.new()
		desc_panel.size = Vector2(card_width - 52, 80)
		desc_panel.position = Vector2(tx + 26, ty + card_height - 88)
		desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var empty_sb := StyleBoxEmpty.new()
		desc_panel.add_theme_stylebox_override("panel", empty_sb)
		canvas.add_child(desc_panel)

		var desc_label = RichTextLabel.new()
		desc_label.bbcode_enabled = true
		desc_label.fit_content = false
		desc_label.scroll_active = false
		var _desc_str: String = Lang.desc(upgrade["index"], upgrade["desc"], get_node("Player"))
		desc_label.text = _desc_str
		desc_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.clip_contents = true
		var _desc_plain_len: int = _desc_str.length()
		var desc_font_size: int = 13
		if _desc_plain_len > 40:
			desc_font_size = 11
		if _desc_plain_len > 60:
			desc_font_size = 10
		desc_label.add_theme_font_size_override("normal_font_size", desc_font_size)
		desc_label.add_theme_font_size_override("bold_font_size", desc_font_size)
		desc_label.add_theme_font_override("normal_font", _font_regular)
		desc_label.add_theme_font_override("bold_font", _font_bold)
		desc_label.add_theme_color_override("default_color", Color(0.85, 0.85, 0.85))
		desc_panel.add_child(desc_label)

		# ── Connected Core badge ─────────────────────────────────────────────
		if upgrade.get("index", -1) in _CONNECTED_CORE_INDICES:
			var badge := Label.new()
			badge.text = Lang.t("ui_connected_core")
			badge.position = Vector2(tx + 26, ty + 20)
			badge.size = Vector2(card_width - 52, 24)
			badge.add_theme_font_size_override("font_size", 11)
			badge.add_theme_font_override("font", _font_bold)
			badge.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(badge)

		# Confirm ve Skip ortada
		var confirm_btn = Button.new()
		confirm_btn.text = Lang.t("upgrade_confirm")
		confirm_btn.size = Vector2(180, 55)
		confirm_btn.position = Vector2(830, 820)
		confirm_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		confirm_btn.add_theme_font_override("font", _font_bold)
		confirm_btn.pressed.connect(_on_confirm.bind(canvas))
		canvas.add_child(confirm_btn)

		var skip_btn = Button.new()
		skip_btn.text = Lang.t("upgrade_skip")
		skip_btn.size = Vector2(180, 55)
		skip_btn.position = Vector2(1030, 820)
		skip_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		skip_btn.add_theme_font_override("font", _font_bold)
		skip_btn.pressed.connect(_on_skip.bind(canvas))
		canvas.add_child(skip_btn)
		
		card_sprite.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var click_area := Button.new()
		click_area.size = Vector2(card_width, card_height)
		click_area.position = Vector2(tx, ty)
		click_area.modulate = Color(1, 1, 1, 0)
		click_area.mouse_entered.connect(func():
			var tween := create_tween()
			tween.tween_property(card_sprite, "scale", Vector2(1.05, 1.05), 0.1)
			tween.parallel().tween_property(card_sprite, "position", Vector2(tx - 7, ty - 7), 0.1)
		)
		click_area.mouse_exited.connect(func():
			var tween := create_tween()
			tween.tween_property(card_sprite, "scale", Vector2(1.0, 1.0), 0.1)
			tween.parallel().tween_property(card_sprite, "position", Vector2(tx, ty), 0.1)
		)
		click_area.pressed.connect(_on_card_selected.bind(upgrade["index"], canvas, card_sprite))
		if upgrade.get("index", -1) in _CONNECTED_CORE_INDICES:
			click_area.tooltip_text = Lang.t("ui_connected_core_tooltip")
		canvas.add_child(click_area)

		# ── Card entry animation: bottom to top, staggered ─────────────────────
		var card_anim_nodes: Array = [card_sprite]
		if art_bg2 != null: card_anim_nodes.append(art_bg2)
		if art_rect2 != null: card_anim_nodes.append(art_rect2)
		card_anim_nodes.append_array([name_label, desc_label, click_area])
		var card_target_ys: Array = []
		for anim_node in card_anim_nodes:
			card_target_ys.append(anim_node.position.y)
			anim_node.position.y += 160.0
		for anim_node in card_anim_nodes:
			if anim_node != click_area:
				anim_node.modulate.a = 0.0

		var slide_tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		slide_tw.tween_interval(i * 0.13)
		slide_tw.tween_property(card_sprite, "position:y", card_target_ys[0], 0.40)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		slide_tw.parallel().tween_property(card_sprite, "modulate:a", 1.0, 0.24)
		for ci in range(1, card_anim_nodes.size()):
			var anim_node: Node = card_anim_nodes[ci]
			slide_tw.parallel().tween_property(anim_node, "position:y", card_target_ys[ci], 0.40)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			if ci < card_anim_nodes.size() - 1:
				slide_tw.parallel().tween_property(anim_node, "modulate:a", 1.0, 0.24)

	# ── Glitch intro: overlaid on all card UI, fades in 0.7s ─────────────
	var glitch_rect = ColorRect.new()
	glitch_rect.size = Vector2(1920, 1080)
	glitch_rect.position = Vector2(0, 0)
	glitch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glitch_mat = ShaderMaterial.new()
	glitch_mat.shader = preload("res://glitch_overlay.gdshader")
	glitch_mat.set_shader_parameter("glitch_strength", 1.0)
	glitch_rect.material = glitch_mat
	canvas.add_child(glitch_rect)
	var glitch_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	glitch_tw.tween_method(
		func(v: float): glitch_mat.set_shader_parameter("glitch_strength", v),
		1.0, 0.0, 0.7
	)
	glitch_tw.tween_callback(glitch_rect.queue_free)

func _activate_gravity(pos: Vector2) -> void:
	_vfx_gravity(pos)
	var duration = 5.0
	var elapsed = 0.0
	while elapsed < duration:
		if upgrading:
			await get_tree().process_frame
			continue
		var subjects = get_tree().get_nodes_in_group("subjects")
		for subject in subjects:
			if subject.global_position.distance_to(pos) < 150:
				var direction = (pos - subject.global_position).normalized()
				subject.global_position += direction * 60 * get_process_delta_time()
		elapsed += get_process_delta_time()
		await get_tree().process_frame
		
func _activate_blizzard() -> void:
	for subject in get_tree().get_nodes_in_group("subjects"):
		if is_instance_valid(subject) and subject.global_position.x >= 385.0:
			if subject.get("is_wet") and subject.is_wet and subject.has_method("apply_frozen"):
				subject.apply_frozen()
	_react_flash_screen(Color(0.7, 0.95, 1.0, 0.5))

func _activate_monsoon() -> void:
	for subject in get_tree().get_nodes_in_group("subjects"):
		if is_instance_valid(subject) and subject.global_position.x >= 385.0 and subject.has_method("apply_wet"):
			subject.apply_wet()
	_react_flash_screen(Color(0.1, 0.4, 1.0, 0.4))
	_play_monsoon_vfx()

func _play_monsoon_vfx() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"): frames.remove_animation("default")
	frames.add_animation("rain")
	frames.set_animation_speed("rain", 8.0)
	frames.set_animation_loop("rain", false)
	for i in range(1, 5):
		var path := "res://assets/VFX/monsoonVFX/rain_drops-%02d.png" % i
		frames.add_frame("rain", load(path))
	var vfx := AnimatedSprite2D.new()
	vfx.sprite_frames = frames
	# Saha alanı: x 385→1920, y 0→1080
	var field_w: float = 1920.0 - 385.0
	var field_h: float = 1080.0
	vfx.position = Vector2(385.0 + field_w * 0.5, field_h * 0.5)
	vfx.z_index = 10
	vfx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(vfx)
	vfx.play("rain")
	vfx.animation_finished.connect(vfx.queue_free)

func _activate_volcanic_rift(pos: Vector2) -> void:
	_react_flash_screen(Color(1.0, 0.3, 0.0, 0.35))
	var elapsed := 0.0
	while elapsed < 4.0:
		var subjects = get_tree().get_nodes_in_group("subjects")
		for subject in subjects:
			if is_instance_valid(subject) and subject.global_position.distance_to(pos) < 180:
				subject.take_damage(2)
				if subject.has_method("apply_burn"):
					subject.apply_burn()
		elapsed += 0.5
		await get_tree().create_timer(0.5).timeout

func _activate_thunderstorm() -> void:
	_react_flash_screen(Color(0.5, 0.5, 1.0, 0.3))
	var elapsed := 0.0
	while elapsed < 5.0:
		var subjects = get_tree().get_nodes_in_group("subjects")
		subjects.shuffle()
		var count := mini(3, subjects.size())
		for i in range(count):
			var s = subjects[i]
			if is_instance_valid(s):
				s.take_damage(5)
				if s.has_method("apply_electrified"):
					s.apply_electrified()
				_vfx_lightning(s.global_position)
		elapsed += 1.0
		await get_tree().create_timer(1.0).timeout

func _activate_emp() -> void:
	for subject in get_tree().get_nodes_in_group("subjects"):
		if is_instance_valid(subject) and subject.global_position.x >= 385.0 and subject.get("is_electrified") and subject.is_electrified:
			subject.take_damage(15)
	_react_flash_screen(Color(0.3, 0.6, 1.0, 0.5))

func _activate_data_storm() -> void:
	for subject in get_tree().get_nodes_in_group("subjects"):
		if is_instance_valid(subject) and subject.global_position.x >= 385.0 and subject.get("is_glitched") and subject.is_glitched:
			subject.take_damage(10)
	_react_flash_screen(Color(0.1, 0.8, 0.3, 0.45))

func _activate_backdoor() -> void:
	for subject in get_tree().get_nodes_in_group("subjects"):
		if is_instance_valid(subject) and subject.global_position.x >= 385.0 and subject.has_method("apply_glitch"):
			subject.apply_glitch(3.0)
	_react_flash_screen(Color(0.6, 0.0, 0.7, 0.4))

func _activate_systemic_failure() -> void:
	var p := get_node_or_null("Player")
	var _cap: int = 3 + (p.stack_overflow_level if (p and p.get("stack_overflow_level")) else 0)
	for subject in get_tree().get_nodes_in_group("subjects"):
		if is_instance_valid(subject) and subject.global_position.x >= 385.0 and subject.has_method("apply_antivirus"):
			subject.apply_antivirus(subject.antivirus_stacks if subject.get("antivirus_stacks") and subject.antivirus_stacks > 0 else _cap)
	_react_flash_screen(Color(0.05, 0.9, 0.35, 0.45))

func _activate_bounce_barrage() -> void:
	var p := get_node_or_null("Player")
	if p == null: return
	p.bounce_barrage_timer = 5.0
	_react_flash_screen(Color(0.35, 0.0, 0.9, 0.4))

var _mirror_image_balls: Array = []

func _activate_mirror_image() -> void:
	var p := get_node_or_null("Player")
	var launcher := get_node_or_null("BallLauncher")
	if p == null or launcher == null: return
	for i in range(2):
		var ball = launcher.ball_scene.instantiate()
		ball.max_damage = 4 + p.ball_mastery
		ball.is_normal_core = true
		ball.global_position = p.global_position
		ball.add_to_group("player_balls")
		add_child(ball)
		ball.get_node("CollisionShape2D").disabled = true
		p.add_to_orbit(ball)
		ball.scale = Vector2(1.0, 1.0)
		_mirror_image_balls.append(ball)
	_react_flash_screen(Color(0.2, 0.65, 0.9, 0.4))
	get_tree().create_timer(25.0).timeout.connect(_clear_mirror_image)

func _clear_mirror_image() -> void:
	var p := get_node_or_null("Player")
	for b in _mirror_image_balls:
		if is_instance_valid(b):
			if p: p.remove_from_orbit(b)
			b.queue_free()
	_mirror_image_balls.clear()

# ── Vector Calamity ───────────────────────────────────────────────────────────
func _activate_shockwave() -> void:
	var dmg: int = max(1, player_armor / 2)
	for subject in get_tree().get_nodes_in_group("subjects"):
		if is_instance_valid(subject) and subject.global_position.x >= 385.0:
			subject.take_damage(dmg, false)
	_react_flash_screen(Color(0.6, 0.6, 1.0, 0.5))
	_vfx_shockwave()

func _vfx_shockwave() -> void:
	var pos: Vector2 = _player_node.global_position if is_instance_valid(_player_node) else get_node("Player").global_position

	# Yard dışına (cadde/tribün tarafına) taşmasın diye kırpma alanı
	# Saha sınırı: x 385→1920, y 0→1080 (diğer alan-efektleriyle aynı sınır)
	var clip := Node2D.new()
	clip.z_index = 1
	add_child(clip)
	var mask := Polygon2D.new()
	mask.color = Color(0, 0, 0, 0)
	mask.polygon = PackedVector2Array([
		Vector2(385.0, 255.0), Vector2(1920.0, 255.0),
		Vector2(1920.0, 1080.0), Vector2(385.0, 1080.0)
	])
	clip.add_child(mask)
	clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY

	var burst := AnimatedSprite2D.new()
	burst.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	burst.position = pos
	burst.scale = Vector2(0.6, 0.6)
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("burst")
	sf.set_animation_speed("burst", 13.0)
	sf.set_animation_loop("burst", false)
	for i in range(9):
		sf.add_frame("burst", load("res://assets/VFX/calamitys/shockwave/frame_%03d.png" % i))
	burst.sprite_frames = sf
	clip.add_child(burst)
	burst.play("burst")
	var burst_tw := create_tween()
	burst_tw.tween_property(burst, "scale", Vector2(7.0, 7.0), 0.7)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	burst.animation_finished.connect(func():
		if is_instance_valid(clip): clip.queue_free()
	)

func _activate_full_breach() -> void:
	var p := get_node_or_null("Player")
	if p == null: return
	player_armor = 0
	_update_armor_ui()
	p.full_breach_mult = 2.5
	p._full_breach_timer = 8.0
	_react_flash_screen(Color(1.0, 0.2, 0.1, 0.5))
	screen_shake_heavy()
	_vfx_full_breach_burst(p.global_position)

# Armor'ın kırılıp güce dönüşme anı: gerçek sprite animasyonu (9 frame)
func _vfx_full_breach_burst(pos: Vector2) -> void:
	var i := 0
	while ResourceLoader.exists("res://assets/VFX/calamitys/fullBreach/frame_%03d.png" % i):
		i += 1
	if i == 0: return
	var burst := AnimatedSprite2D.new()
	burst.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	burst.global_position = pos
	burst.z_index = 6
	burst.scale = Vector2(1.4, 1.4)
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("breach")
	sf.set_animation_speed("breach", 12.0)
	sf.set_animation_loop("breach", false)
	for f in range(i):
		sf.add_frame("breach", load("res://assets/VFX/calamitys/fullBreach/frame_%03d.png" % f))
	burst.sprite_frames = sf
	add_child(burst)
	burst.play("breach")
	burst.animation_finished.connect(func():
		if is_instance_valid(burst): burst.queue_free()
	)

func _activate_momentum_burst() -> void:
	var p := get_node_or_null("Player")
	if p == null: return
	var stacks: int = p.momentum_stacks
	if stacks <= 0: return
	p.momentum_stacks = 0
	p.momentum_burst_bonus = float(stacks) * 0.05
	p._momentum_burst_timer = 10.0
	_react_flash_screen(Color(0.0, 0.9, 1.0, 0.4))

func _activate_rampart_collapse(target_pos: Vector2) -> void:
	var p := get_node_or_null("Player")
	if p == null: return
	player_armor = 0
	_update_armor_ui()
	_fire_rampart_core(p.global_position, target_pos)

# ── Rampart Collapse: 1) Player üzerinde hexagon Armor tek noktada yoğunlaşır
#                      2) Yoğunlaşan Core, seçilen noktaya fırlar ve patlayıp AoE hasar verir ──
func _fire_rampart_core(start_pos: Vector2, target_pos: Vector2) -> void:
	await _vfx_rampart_charge(start_pos)
	var core := _spawn_rampart_projectile(start_pos)
	var travel_tw := create_tween()
	travel_tw.tween_property(core, "global_position", target_pos, 0.22)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await travel_tw.finished
	if is_instance_valid(core):
		core.queue_free()
	var dmg: int = player_armor_cap
	for s in get_tree().get_nodes_in_group("subjects"):
		if is_instance_valid(s) and s.global_position.x >= 385.0 and s.global_position.distance_to(target_pos) <= 130.0:
			s.take_damage(dmg, false)
	_vfx_rampart_impact(target_pos)

# Aşama 1 VFX: karakter görünmeksizin, üzerinde hexagon Armor parçaları bir noktada yoğunlaşır
func _vfx_rampart_charge(pos: Vector2) -> void:
	if not ResourceLoader.exists("res://assets/VFX/calamitys/rampartCollapse/charge/frame_000.png"):
		await get_tree().create_timer(0.15).timeout
		return
	var chg := AnimatedSprite2D.new()
	chg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chg.global_position = pos
	chg.z_index = 6
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("charge")
	sf.set_animation_speed("charge", 14.0)
	sf.set_animation_loop("charge", false)
	var i := 0
	while ResourceLoader.exists("res://assets/VFX/calamitys/rampartCollapse/charge/frame_%03d.png" % i):
		sf.add_frame("charge", load("res://assets/VFX/calamitys/rampartCollapse/charge/frame_%03d.png" % i))
		i += 1
	chg.sprite_frames = sf
	add_child(chg)
	chg.play("charge")
	await chg.animation_finished
	if is_instance_valid(chg): chg.queue_free()

# Aşama 1'in son frame'i, fırlayan Core'un sprite'ı olarak yeniden kullanılıyor
func _spawn_rampart_projectile(pos: Vector2) -> Node2D:
	var proj: Node2D
	var last_frame_path := ""
	var i := 0
	while ResourceLoader.exists("res://assets/VFX/calamitys/rampartCollapse/charge/frame_%03d.png" % i):
		last_frame_path = "res://assets/VFX/calamitys/rampartCollapse/charge/frame_%03d.png" % i
		i += 1
	if last_frame_path != "":
		var spr := Sprite2D.new()
		spr.texture = load(last_frame_path)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		proj = spr
	else:
		var ph := CPUParticles2D.new()
		ph.amount = 1
		ph.lifetime = 1.0
		ph.emitting = true
		ph.color = Color(0.3, 0.9, 1.0)
		proj = ph
	proj.global_position = pos
	proj.z_index = 6
	add_child(proj)
	return proj

# Aşama 2 VFX: Core hedefe çarpıp patlar (tek seferlik hasar anı)
func _vfx_rampart_impact(pos: Vector2) -> void:
	screen_shake_heavy()
	var burst_p := CPUParticles2D.new()
	burst_p.global_position = pos
	burst_p.emitting = false
	burst_p.one_shot = true
	burst_p.explosiveness = 1.0
	burst_p.amount = 26
	burst_p.lifetime = 0.4
	burst_p.initial_velocity_min = 90.0
	burst_p.initial_velocity_max = 240.0
	burst_p.gravity = Vector2(0, 320)
	burst_p.scale_amount_min = 2.5
	burst_p.scale_amount_max = 5.5
	burst_p.color = Color(0.2, 0.85, 1.0)
	add_child(burst_p)
	burst_p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(burst_p.queue_free)
	# Sprite dosyaları eklenince otomatik oynayacak (frame_000..00N.png)
	if ResourceLoader.exists("res://assets/VFX/calamitys/rampartCollapse/impact/frame_000.png"):
		var impact := AnimatedSprite2D.new()
		impact.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		impact.position = pos
		impact.z_index = 6
		var sf := SpriteFrames.new()
		if sf.has_animation("default"): sf.remove_animation("default")
		sf.add_animation("collapse")
		sf.set_animation_speed("collapse", 14.0)
		sf.set_animation_loop("collapse", false)
		var j := 0
		while ResourceLoader.exists("res://assets/VFX/calamitys/rampartCollapse/impact/frame_%03d.png" % j):
			sf.add_frame("collapse", load("res://assets/VFX/calamitys/rampartCollapse/impact/frame_%03d.png" % j))
			j += 1
		impact.sprite_frames = sf
		add_child(impact)
		impact.play("collapse")
		impact.animation_finished.connect(func():
			if is_instance_valid(impact): impact.queue_free())

func _activate_wormhole() -> void:
	var player := get_node_or_null("Player")
	if not player: return
	# Delik pozisyonu: player'ın TAM önünde (o anki bakış/nişan yönü — sağ/sol değil)
	var _face_dir: Vector2 = player.aim_direction if player.get("aim_direction") else Vector2(1, 0)
	if _face_dir == Vector2.ZERO: _face_dir = Vector2(1, 0)
	var worm_pos: Vector2 = player.global_position + _face_dir.normalized() * 120.0
	var duration := 5.0

	var visual: CanvasItem = _vfx_wormhole_open(worm_pos, duration)
	var _consuming: Array = []  # şu an merkeze çekilip küçülen düşmanlar

	# 5 saniye boyunca yaklaşan düşmanları yakalayıp merkeze çekiyor
	var elapsed := 0.0
	while elapsed < duration:
		var _dt := get_process_delta_time()
		elapsed += _dt
		for s in get_tree().get_nodes_in_group("subjects"):
			if not is_instance_valid(s) or s in _consuming: continue
			if s.get("is_boss") and s.is_boss: continue  # Boss etkilenmez
			if s.get("is_dead") and s.is_dead: continue
			if worm_pos.distance_to(s.global_position) <= 70.0:
				_consuming.append(s)
				if s.has_method("set_physics_process"): s.set_physics_process(false)
				if s.has_node("CollisionShape2D"): s.get_node("CollisionShape2D").set_deferred("disabled", true)
				s.set_meta("wormhole_pull_t", 0.0)
				s.set_meta("wormhole_start_pos", s.global_position)
				s.set_meta("wormhole_start_scale", s.scale)
		# Yakalanmış düşmanları döndürerek + küçülterek merkeze çek
		for i in range(_consuming.size() - 1, -1, -1):
			var s2 = _consuming[i]
			if not is_instance_valid(s2):
				_consuming.remove_at(i)
				continue
			var t: float = s2.get_meta("wormhole_pull_t") + _dt
			s2.set_meta("wormhole_pull_t", t)
			var pull_dur := 0.4
			var pt: float = clamp(t / pull_dur, 0.0, 1.0)
			var _start_pos: Vector2 = s2.get_meta("wormhole_start_pos")
			var _start_scale: Vector2 = s2.get_meta("wormhole_start_scale")
			s2.global_position = _start_pos.lerp(worm_pos, pt)
			s2.scale = _start_scale.lerp(Vector2.ZERO, pt)
			s2.rotation += 14.0 * _dt
			if pt >= 1.0:
				var score_val: int = s2.get("score_value") if s2.get("score_value") else 0
				subject_died(score_val / 2, worm_pos)
				s2.queue_free()
				_consuming.remove_at(i)
		await get_tree().process_frame

	# Süre bitiminde hâlâ çekilmekte olan düşman kalırsa donuk kalmasın diye tamamla
	for s2 in _consuming:
		if not is_instance_valid(s2): continue
		var score_val: int = s2.get("score_value") if s2.get("score_value") else 0
		subject_died(score_val / 2, worm_pos)
		s2.queue_free()

	if is_instance_valid(visual):
		visual.queue_free()
	_react_flash_screen(Color(0.4, 0.0, 0.8, 0.3))

# WormHole VFX: gerçek sprite animasyonu (Gravitational Force ile aynı desen) —
# dosyalar assets/VFX/calamitys/wormhole/frame_000..00N.png'ye eklenince otomatik
# oynar, eklenmediyse basit bir mor çemberle (eski görsel) devam eder.
func _vfx_wormhole_open(pos: Vector2, duration: float) -> CanvasItem:
	if not ResourceLoader.exists("res://assets/VFX/calamitys/wormhole/frame_000.png"):
		var fallback := ColorRect.new()
		fallback.color = Color(0.5, 0.0, 1.0, 0.0)
		fallback.size = Vector2(120, 120)
		fallback.position = pos - Vector2(60, 60)
		fallback.z_index = 1
		add_child(fallback)
		var tw_in := fallback.create_tween()
		tw_in.tween_property(fallback, "color:a", 0.7, 0.3)
		return fallback

	var vortex := AnimatedSprite2D.new()
	vortex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vortex.z_index = 1  # düşmanların (z_index 2-3) altında kalsın
	vortex.modulate = Color(1, 1, 1, 0.85)
	vortex.scale = Vector2.ZERO
	vortex.global_position = pos
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("spin")
	sf.set_animation_speed("spin", 10.0)
	sf.set_animation_loop("spin", true)
	var i := 0
	while ResourceLoader.exists("res://assets/VFX/calamitys/wormhole/frame_%03d.png" % i):
		sf.add_frame("spin", load("res://assets/VFX/calamitys/wormhole/frame_%03d.png" % i))
		i += 1
	vortex.sprite_frames = sf
	add_child(vortex)
	vortex.play("spin")

	var _grow_time := 0.6
	var _shrink_time := 0.6
	var scale_tw := create_tween()
	scale_tw.tween_property(vortex, "scale", Vector2(1.6, 1.6), _grow_time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tw.tween_interval(max(duration - _grow_time - _shrink_time, 0.0))
	scale_tw.tween_property(vortex, "scale", Vector2.ZERO, _shrink_time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	return vortex

func _activate_siege_rain(pos: Vector2) -> void:
	# 14s boyunca her 1s'de bir Siege Core düşürür (14 darbe)
	var siege_dmg: int = 8
	var siege_radius: float = 55.0
	for i in range(14):
		# BUG FIX: process_always=false — eskiden varsayılan (true) yüzünden
		# upgrade menüsü açıkken (get_tree().paused) bu sayaç durmadan işlemeye
		# devam ediyordu, menüden çıkınca birikmiş birkaç darbe aynı anda tetikleniyordu.
		await get_tree().create_timer(1.0, false).timeout
		# Seçilen alandaki gerçek bir düşmanı hedefle — pasif kalmasın diye rastgele
		# boş noktaya değil, o an alanda duran bir düşmana (küçük sapmayla) düşer.
		# Alanda düşman yoksa eski davranışa (rastgele nokta) düşer.
		var _targets: Array = []
		for s in get_tree().get_nodes_in_group("subjects"):
			if not is_instance_valid(s): continue
			if s.get("is_dead") and s.is_dead: continue
			if s.global_position.distance_to(pos) <= 170.0:
				_targets.append(s)
		var hit_pos: Vector2
		if _targets.size() > 0:
			var _target = _targets[randi() % _targets.size()]
			hit_pos = _target.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		else:
			hit_pos = pos + Vector2(randf_range(-120, 120), randf_range(-120, 120))
		_spawn_siege_rain_impact(hit_pos, siege_dmg, siege_radius)

func _spawn_siege_rain_impact(pos: Vector2, dmg: int, radius: float) -> void:
	# Düşüş + çarpma tek bir sprite dizisinde (assets/VFX/calamitys/siegeRain/) —
	# ayrı bir "düşen top" sprite'ına gerek yok, animasyonun kendisi zaten yukarıdan
	# küçük başlayıp büyüyerek merkeze inip patlıyor.
	var _fps := 8.0
	var _total_frames := 0
	while ResourceLoader.exists("res://assets/VFX/calamitys/siegeRain/frame_%03d.png" % _total_frames):
		_total_frames += 1

	if _total_frames > 0:
		var burst := AnimatedSprite2D.new()
		burst.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		burst.global_position = pos
		burst.z_index = 4  # düşerken düşmanların (2-3) ÖNÜNDE görünsün
		var sf := SpriteFrames.new()
		if sf.has_animation("default"): sf.remove_animation("default")
		sf.add_animation("fall")
		sf.set_animation_speed("fall", _fps)
		sf.set_animation_loop("fall", false)
		for f in range(_total_frames):
			sf.add_frame("fall", load("res://assets/VFX/calamitys/siegeRain/frame_%03d.png" % f))
		burst.sprite_frames = sf
		add_child(burst)
		burst.play("fall")
		burst.animation_finished.connect(func():
			if not is_instance_valid(burst): return
			# Animasyon bitip son karede (kraterin izi) durunca artık düşmanların
			# (2-3) VE ölü/ceset (0) ARKASINDA görünsün — düşerken önde, izde arkada.
			burst.z_index = -1
			# Son frame'de 3sn kalıp yavaşça kaybol
			var _fade_tw := create_tween()
			_fade_tw.tween_interval(3.0)
			_fade_tw.tween_property(burst, "modulate:a", 0.0, 1.0)
			_fade_tw.tween_callback(func():
				if is_instance_valid(burst): burst.queue_free()
			)
		)

	# İsabet anı: son 2 frame'e (patlama) denk gelen noktada hasar + sarsıntı
	var _impact_delay: float = float(max(_total_frames - 2, 3)) / _fps if _total_frames > 0 else 0.6
	await get_tree().create_timer(_impact_delay, false).timeout

	_screen_shake()
	for s in get_tree().get_nodes_in_group("subjects"):
		if not is_instance_valid(s): continue
		if pos.distance_to(s.global_position) <= radius:
			s.take_damage(dmg, false)

func _activate_glitch_bomb(pos: Vector2) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e): continue
		if e.global_position.distance_to(pos) <= 120.0:
			if e.get("apply_glitch"): e.apply_glitch(4.0)
	_react_flash_screen(Color(0.75, 0.0, 0.85, 0.2))

func _activate_system_crash() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e): continue
		if e.get("is_glitched") and e.is_glitched:
			var loss := int(e.health * 0.3)
			e.take_damage(maxi(loss, 1), false)
	_react_flash_screen(Color(0.8, 0.1, 0.6, 0.25))

func _activate_antivirus_rain() -> void:
	var ticks := 6  # 3s × her 0.5s = 6 tick
	var tick_index := 0
	var _do_tick := func():
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			if e.get("apply_antivirus"): e.apply_antivirus()
	_do_tick.call()
	for i in range(1, ticks):
		await get_tree().create_timer(0.5).timeout
		_do_tick.call()
	_react_flash_screen(Color(0.1, 0.85, 0.4, 0.2))

func _activate_decay_field(pos: Vector2) -> void:
	var field_duration := 5.0
	var field_radius := 100.0
	var zone := ColorRect.new()
	zone.color = Color(0.45, 0.2, 0.0, 0.3)
	zone.size = Vector2(field_radius * 2, field_radius * 2)
	zone.position = pos - Vector2(field_radius, field_radius)
	zone.z_index = 1
	add_child(zone)
	var elapsed := 0.0
	while elapsed < field_duration:
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0
		if not is_instance_valid(zone): break
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e): continue
			if e.global_position.distance_to(pos) <= field_radius:
				if e.get("apply_decay"): e.apply_decay()
	if is_instance_valid(zone): zone.queue_free()


func _activate_wildfire() -> void:
	# Tüm Yanan düşmanlar patlar: 10 hasar + 2 yakın düşmana yangın yayar
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e.get("is_burning") and e.is_burning:
			e.take_damage(10, false)
			var spread_count := 0
			for other in enemies:
				if other == e or spread_count >= 2:
					break
				if other.global_position.distance_to(e.global_position) <= 120.0:
					other.apply_burn()
					spread_count += 1
	_react_flash_screen(Color(1.0, 0.3, 0.0, 0.3))

func _react_flash_screen(color: Color) -> void:
	var flash := ColorRect.new()
	flash.color = color
	flash.position = Vector2(385, 255)
	flash.size = Vector2(1920 - 385, 1080 - 255)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 10
	add_child(flash)
	var tw = create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.4)
	tw.tween_callback(flash.queue_free)

func _input(event: InputEvent) -> void:
	# Calamity seçimi artık sağ paneldeki hücrelere tıklanarak yapılıyor
	# (bkz. _on_calamity_cell_clicked). Hedef gerektirmeyen Calamity'ler tıklanınca
	# anında ateşlenir; hedef gerektirenler "nişan" moduna girer (sarı highlight) —
	# basılı tutup sürükleyip mouse'u BIRAKINCA (drag-to-target) veya E tuşuna
	# basınca, mevcut mouse pozisyonunda onaylanıp ateşlenir.
	if calamity_aiming and not calamity_slots.is_empty():
		var mouse_pos = get_viewport().get_mouse_position()
		var _confirm := false
		if event is InputEventKey and event.keycode == KEY_E and event.pressed:
			_confirm = true
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# Nişanı açan tıklamanın kendi bırakışı (hücrenin üzerinde) sayılmaz —
			# sadece hücreden sürükleyip sahada bırakınca ateşlenir.
			var _armed_cell: Panel = _calamity_cells[calamity_index] if calamity_index < _calamity_cells.size() else null
			var _over_cell: bool = _armed_cell != null and Rect2(_armed_cell.global_position, _armed_cell.size).has_point(mouse_pos)
			if not _over_cell:
				_confirm = true
		if _confirm:
			_consume_calamity(calamity_index, mouse_pos)

	# Tab → Tactical Mode aç/kapat
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed and not event.echo:
		if not get_tree().paused:
			_toggle_rts_mode()

	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if calamity_aiming:
			calamity_aiming = false
			update_ui()
		elif not upgrading:
			_show_pause_menu()
			
func _toggle_rts_mode() -> void:
	_rts_mode = not _rts_mode
	Engine.time_scale = 0.5 if _rts_mode else 1.0
	var player := get_node_or_null("Player")
	if player:
		player.rts_mode = _rts_mode
	if _rts_mode:
		_show_rts_overlay()
	else:
		_hide_rts_overlay()

func _show_rts_overlay() -> void:
	if _rts_overlay != null:
		return
	_rts_overlay = CanvasLayer.new()
	_rts_overlay.layer = 20
	add_child(_rts_overlay)

	# Kenarlık — 4 ColorRect (üst / alt / sol / sağ)
	var border_color := Color(1.0, 0.75, 0.0, 0.72)   # amber/altın
	var thickness    := 4
	for side in 4:
		var bar := ColorRect.new()
		bar.color = border_color
		match side:
			0: bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);   bar.custom_minimum_size = Vector2(0, thickness)
			1: bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); bar.custom_minimum_size = Vector2(0, thickness); bar.offset_top = -thickness; bar.offset_bottom = 0
			2: bar.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE);   bar.custom_minimum_size = Vector2(thickness, 0)
			3: bar.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE);  bar.custom_minimum_size = Vector2(thickness, 0); bar.offset_left = -thickness; bar.offset_right = 0
		_rts_overlay.add_child(bar)

	# Etiket — sol üst köşe
	var lbl := Label.new()
	lbl.text              = Lang.t("ui_tactical_mode")
	lbl.add_theme_color_override("font_color",        Color(1.0, 0.82, 0.0, 1.0))
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_font_size_override("font_size", 18)
	if _font_bold:
		lbl.add_theme_font_override("font", _font_bold)
	lbl.position = Vector2(16, 8)
	_rts_overlay.add_child(lbl)

func _hide_rts_overlay() -> void:
	if _rts_overlay != null:
		_rts_overlay.queue_free()
		_rts_overlay = null

func _show_pause_menu() -> void:
	get_tree().paused = true
	
	var canvas = CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.name = "PauseMenu"
	add_child(canvas)
	
	var panel = ColorRect.new()
	panel.color = Color(0, 0, 0, 0.85)
	panel.size = Vector2(1920, 1080)
	canvas.add_child(panel)
	
	var title = Label.new()
	title.text = Lang.t("pause_title")
	title.position = Vector2(880, 300)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_font_override("font", _font_bold)
	title.modulate = Color(1, 0.8, 0)
	canvas.add_child(title)

	var resume_btn = Button.new()
	resume_btn.text = Lang.t("pause_resume")
	resume_btn.size = Vector2(200, 55)
	resume_btn.position = Vector2(860, 450)
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.add_theme_font_override("font", _font_bold)
	resume_btn.pressed.connect(_on_resume.bind(canvas))
	canvas.add_child(resume_btn)

	var menu_btn = Button.new()
	menu_btn.text = Lang.t("pause_menu")
	menu_btn.size = Vector2(200, 55)
	menu_btn.position = Vector2(860, 530)
	menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_btn.add_theme_font_override("font", _font_bold)
	menu_btn.pressed.connect(_on_main_menu.bind(canvas))
	canvas.add_child(menu_btn)

	var settings_btn = Button.new()
	settings_btn.text = Lang.t("ui_settings")
	settings_btn.size = Vector2(200, 55)
	settings_btn.position = Vector2(860, 530)
	settings_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_btn.add_theme_font_override("font", _font_bold)
	settings_btn.pressed.connect(_show_pause_settings.bind(canvas))
	canvas.add_child(settings_btn)

	menu_btn.position = Vector2(860, 610)

	var quit_btn = Button.new()
	quit_btn.text = Lang.t("pause_quit")
	quit_btn.size = Vector2(200, 55)
	quit_btn.position = Vector2(860, 690)
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.add_theme_font_override("font", _font_bold)
	quit_btn.pressed.connect(_on_quit_game)
	canvas.add_child(quit_btn)

func _show_pause_settings(pause_canvas: CanvasLayer) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")

	var overlay := CanvasLayer.new()
	overlay.layer = 120
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.92)
	bg.size  = Vector2(1920, 1080)
	overlay.add_child(bg)

	var title := Label.new()
	title.text = Lang.t("set_title")
	title.position = Vector2(880, 280)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_font_override("font", _font_bold)
	title.modulate = Color(1, 0.8, 0)
	overlay.add_child(title)

	var buses := [
		["Ana Ses",  "Master"],
		["Müzik",    "Music"],
		["Efektler", "SFX"],
	]
	for i in buses.size():
		var bus_name: String = buses[i][1]
		var bus_idx  := AudioServer.get_bus_index(bus_name)
		var cur_vol  := db_to_linear(AudioServer.get_bus_volume_db(bus_idx)) if bus_idx >= 0 else 1.0

		var lbl := Label.new()
		lbl.text = buses[i][0]
		lbl.position = Vector2(720, 380 + i * 90)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_font_override("font", _font_bold)
		lbl.modulate = Color(0.82, 0.92, 1, 0.9)
		overlay.add_child(lbl)

		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step      = 0.01
		slider.value     = cur_vol
		slider.size      = Vector2(400, 30)
		slider.position  = Vector2(720, 410 + i * 90)
		slider.process_mode = Node.PROCESS_MODE_ALWAYS
		overlay.add_child(slider)

		var val_lbl := Label.new()
		val_lbl.text = "%d%%" % int(cur_vol * 100)
		val_lbl.position = Vector2(1135, 410 + i * 90)
		val_lbl.add_theme_font_size_override("font_size", 16)
		val_lbl.add_theme_font_override("font", _font_bold)
		val_lbl.modulate = Color(0, 0.95, 1, 1)
		overlay.add_child(val_lbl)

		var lbl_ref := val_lbl
		slider.value_changed.connect(func(v: float):
			lbl_ref.text = "%d%%" % int(v * 100)
			var idx := AudioServer.get_bus_index(bus_name)
			if idx >= 0:
				AudioServer.set_bus_volume_db(idx, linear_to_db(v))
			cfg.set_value("audio", bus_name.to_lower(), v)
			cfg.save("user://settings.cfg")
		)

	var back_btn := Button.new()
	back_btn.text = Lang.t("ui_back")
	back_btn.size = Vector2(200, 55)
	back_btn.position = Vector2(860, 700)
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.add_theme_font_override("font", _font_bold)
	back_btn.pressed.connect(func(): overlay.queue_free())
	overlay.add_child(back_btn)

func _on_resume(canvas: CanvasLayer) -> void:
	canvas.queue_free()
	get_tree().paused = false

func _on_main_menu(canvas: CanvasLayer) -> void:
	canvas.queue_free()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_quit_game() -> void:
	get_tree().quit()

func _activate_lightning(pos: Vector2) -> void:
	var subjects = get_tree().get_nodes_in_group("subjects")
	for subject in subjects:
		if subject.global_position.distance_to(pos) < 100:
			subject.take_damage(3)
			if subject.has_method("apply_electrified"):
				subject.apply_electrified()
	_vfx_lightning(pos)

func _activate_flame(pos: Vector2) -> void:
	_vfx_flame(pos)
	var flame_timer = get_tree().create_timer(0.5)
	var hits = 0
	while hits < 6:
		var subjects = get_tree().get_nodes_in_group("subjects")
		for subject in subjects:
			if subject.global_position.distance_to(pos) < 120:
				subject.take_damage(1)
				if subject.has_method("apply_burn") and subject.get("is_burning") == false:
					subject.apply_burn()
		hits += 1
		await flame_timer.timeout
		flame_timer = get_tree().create_timer(0.5)

# ── VFX: Lightning ────────────────────────────────────────────────────────────
func _vfx_lightning(pos: Vector2) -> void:
	# Beyaz flash
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.45)
	flash.size  = Vector2(1920, 1080)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 10
	add_child(flash)
	var ftw := create_tween()
	ftw.tween_property(flash, "modulate:a", 0.0, 0.12)
	ftw.tween_callback(flash.queue_free)

	# Gökten gelen zigzag şimşek çizgisi
	for _bolt in range(3):
		var bolt := Line2D.new()
		bolt.width           = randf_range(2.0, 4.0)
		bolt.default_color   = Color(0.85, 0.95, 1.0, 1.0)
		bolt.z_index         = 9
		var top := Vector2(pos.x + randf_range(-30, 30), 240.0)
		var pts  := [top]
		var cur  := top
		while cur.y < pos.y:
			cur = Vector2(
				cur.x + randf_range(-28, 28),
				cur.y + randf_range(18, 40)
			)
			pts.append(cur)
		pts.append(pos)
		for p in pts:
			bolt.add_point(p)
		add_child(bolt)
		var btw := create_tween()
		btw.tween_interval(randf_range(0.0, 0.06))
		btw.tween_property(bolt, "modulate:a", 0.0, randf_range(0.10, 0.20))
		btw.tween_callback(bolt.queue_free)

	# Çarpma noktasında halka
	for ring_i in range(3):
		var ring := Node2D.new()
		ring.global_position = pos
		ring.z_index = 9
		add_child(ring)
		var r_start := randf_range(8.0, 20.0)
		var r_end   := r_start + randf_range(60.0, 100.0)
		var rtw := create_tween()
		rtw.tween_interval(ring_i * 0.05)
		rtw.tween_method(
			func(r: float):
				if is_instance_valid(ring):
					ring.queue_redraw()
					ring.set_meta("r", r),
			r_start, r_end, 0.35
		)
		rtw.tween_callback(ring.queue_free)
		ring.draw.connect(func():
			if ring.has_meta("r"):
				var rr: float = ring.get_meta("r")
				ring.draw_arc(Vector2.ZERO, rr, 0, TAU, 32,
					Color(0.7, 0.9, 1.0, 1.0 - (rr - r_start) / (r_end - r_start)), 2.0)
		)

# ── VFX: Flame Zone ───────────────────────────────────────────────────────────
func _vfx_flame(pos: Vector2) -> void:
	var duration := 3.0   # görsel süresi
	var radius   := 120.0

	# Zemin halkası
	var ground := Node2D.new()
	ground.global_position = pos
	ground.z_index = 3
	add_child(ground)
	ground.draw.connect(func():
		ground.draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(1.0, 0.25, 0.0, 0.55), 3.0)
		ground.draw_arc(Vector2.ZERO, radius * 0.6, 0, TAU, 32, Color(1.0, 0.55, 0.0, 0.35), 2.0)
	)
	ground.queue_redraw()
	var gtw := create_tween()
	gtw.tween_interval(duration)
	gtw.tween_property(ground, "modulate:a", 0.0, 0.4)
	gtw.tween_callback(ground.queue_free)

	# Ateş parçacıkları
	var particles := CPUParticles2D.new()
	particles.global_position  = pos
	particles.z_index           = 4
	particles.amount            = 60
	particles.lifetime          = 0.9
	particles.explosiveness     = 0.0
	particles.emission_shape    = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = radius * 0.8
	particles.direction         = Vector2(0, -1)
	particles.spread            = 35.0
	particles.gravity           = Vector2(0, -80)
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min  = 3.0
	particles.scale_amount_max  = 7.0
	particles.color             = Color(1.0, 0.45, 0.0, 0.9)
	particles.color_ramp        = _make_flame_gradient()
	add_child(particles)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(particles):
		particles.emitting = false
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(particles):
			particles.queue_free()

func _make_flame_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors = [Color(1.0, 0.9, 0.2, 1.0), Color(1.0, 0.3, 0.0, 0.8), Color(0.2, 0.2, 0.2, 0.0)]
	g.offsets = [0.0, 0.5, 1.0]
	return g

# ── VFX: Gravitational Force ──────────────────────────────────────────────────
func _vfx_gravity(pos: Vector2) -> void:
	var duration := 5.0

	# Dönen spiral parçacıklar
	var particles := CPUParticles2D.new()
	particles.global_position       = pos
	particles.z_index                = 1
	particles.amount                 = 80
	particles.lifetime               = 1.2
	particles.explosiveness          = 0.0
	particles.emission_shape         = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 160.0
	particles.direction              = Vector2(0, 0)
	particles.spread                 = 180.0
	particles.gravity                = Vector2(0, 0)
	particles.initial_velocity_min   = 60.0
	particles.initial_velocity_max   = 140.0
	particles.angular_velocity_min   = 180.0
	particles.angular_velocity_max   = 360.0
	particles.scale_amount_min       = 2.0
	particles.scale_amount_max       = 5.0
	particles.color                  = Color(0.65, 0.1, 1.0, 0.9)
	particles.color_ramp             = _make_gravity_gradient()
	add_child(particles)

	# Merkez vorteks — gerçek sprite animasyonu
	var vortex := AnimatedSprite2D.new()
	vortex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vortex.z_index = 1
	vortex.modulate = Color(1, 1, 1, 0.65)
	vortex.scale = Vector2.ZERO
	vortex.global_position = pos
	var vsf := SpriteFrames.new()
	if vsf.has_animation("default"): vsf.remove_animation("default")
	vsf.add_animation("spin")
	vsf.set_animation_speed("spin", 10.0)
	vsf.set_animation_loop("spin", true)
	for i in range(8):
		vsf.add_frame("spin", load("res://assets/VFX/calamitys/gravitationalForce/frame_%03d.png" % i))
	vortex.sprite_frames = vsf
	add_child(vortex)
	vortex.play("spin")

	# Ortadan büyüyüp süre bitmeden kenardan küçülen scale animasyonu
	var _target_scale := Vector2(2.0, 2.0)
	var _grow_time := 1.0
	var _shrink_time := 1.0
	var scale_tw := create_tween()
	scale_tw.tween_property(vortex, "scale", _target_scale, _grow_time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tw.tween_interval(max(duration - _grow_time - _shrink_time, 0.0))
	scale_tw.tween_property(vortex, "scale", Vector2.ZERO, _shrink_time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(duration).timeout
	if is_instance_valid(scale_tw):
		scale_tw.kill()
	if is_instance_valid(vortex):
		vortex.queue_free()
	if is_instance_valid(particles):
		particles.emitting = false
		await get_tree().create_timer(1.2).timeout
		if is_instance_valid(particles):
			particles.queue_free()

func _make_gravity_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors  = [Color(0.9, 0.5, 1.0, 1.0), Color(0.5, 0.0, 1.0, 0.6), Color(0.1, 0.0, 0.3, 0.0)]
	g.offsets = [0.0, 0.5, 1.0]
	return g

func _spawn_subject() -> void:
	# Level bazlı ağırlıklı havuz — yeni tipler kademeli olarak eklenir
	var pool: Array = []

	# 1-3: Sadece Subject
	for i in 5: pool.append("subject")

	# 4-7: + FranticSubject
	if level >= 4:
		for i in 3: pool.append("frantic")

	# 8-11: + ArmedSubject
	if level >= 8:
		for i in 2: pool.append("armed")

	# 12-15: + HeavySubject
	if level >= 12:
		for i in 2: pool.append("heavy")

	# 16-19: + CyberShooter
	if level >= 16:
		pool.append("cyber_shooter")

	# 20-22: + CyberRifle
	if level >= 20:
		pool.append("cyber_rifle")

	# 23+: + CyberShotgun
	if level >= 23:
		pool.append("cyber_shotgun")

	var subject
	match pool[randi() % pool.size()]:
		"subject":       subject = subject_scene.instantiate()
		"frantic":       subject = frantic_subject_scene.instantiate()
		"armed":         subject = armored_subject_scene.instantiate()
		"heavy":         subject = heavy_subject_scene.instantiate()
		"cyber_shooter": subject = cyber_shooter_scene.instantiate()
		"cyber_rifle":   subject = cyber_rifle_scene.instantiate()
		"cyber_shotgun": subject = cyber_shotgun_scene.instantiate()
		_:               subject = subject_scene.instantiate()

	var rand_x = randf_range(430, 1580)
	subject.position = Vector2(rand_x, -50)
	add_child(subject)

func _draw() -> void:
	var player := _player_node
	if player == null: return
	var auto_on: bool  = player.auto_mode
	var lmb_held: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not auto_on and not lmb_held: return
	var start: Vector2 = player.global_position + Vector2(20, -24)
	var mouse: Vector2 = get_global_mouse_position()
	var dir: Vector2   = (mouse - start).normalized()
	if dir == Vector2.ZERO: return
	var pts := _calc_traj(start, dir, 900.0, 3)
	var alpha := 0.65
	for i in pts.size() - 1:
		var a := maxf(alpha - i * 0.18, 0.12)
		_draw_dashed_line(pts[i], pts[i + 1], Color(0.0, 0.9, 1.0, a), 1.5)

func _calc_traj(start: Vector2, dir: Vector2, max_len: float, bounces: int) -> Array:
	var pts := [start]
	var pos  := start
	var d    := dir.normalized()
	const XMIN := 409.0; const XMAX := 1580.0
	const YMIN := 260.0; const YMAX := 1040.0
	var remaining := max_len
	for _b in bounces:
		var t_vals: Array[float] = []
		if d.x > 0.0001:  t_vals.append((XMAX - pos.x) / d.x)
		elif d.x < -0.0001: t_vals.append((XMIN - pos.x) / d.x)
		if d.y > 0.0001:  t_vals.append((YMAX - pos.y) / d.y)
		elif d.y < -0.0001: t_vals.append((YMIN - pos.y) / d.y)
		if t_vals.is_empty(): break
		var t: float = t_vals.min()
		if t <= 0.01 or t > remaining:
			pts.append(pos + d * remaining)
			remaining = 0.0
			break
		var hit := pos + d * t
		pts.append(hit)
		remaining -= t
		if absf(hit.x - XMIN) < 2.0 or absf(hit.x - XMAX) < 2.0: d.x = -d.x
		if absf(hit.y - YMIN) < 2.0 or absf(hit.y - YMAX) < 2.0: d.y = -d.y
		pos = hit
		if remaining <= 0.0: break
	if remaining > 0.0:
		pts.append(pos + d * remaining)
	return pts

func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var total := from.distance_to(to)
	if total < 1.0: return
	var dir   := (to - from) / total
	var dash  := 9.0
	var gap   := 5.0
	var p     := 0.0
	while p < total:
		var e := minf(p + dash, total)
		draw_line(from + dir * p, from + dir * e, color, width)
		p += dash + gap

func _process(delta: float) -> void:
	_update_core_panel()   # her frame güncelle — deferred add_child'ı yakala
	_update_low_hp_vignette()

	var p := _player_node

	# ── Sol üst HUD: Momentum bar (sadece Vector, Momentum Engine alındıktan sonra) ──
	if p and p.get("character_type") == "vector" and p.get("has_momentum_engine") and p.has_momentum_engine:
		$UI/MomentumBar.visible = true
		$UI/MomentumBar/Fill.max_value = p.momentum_max
		$UI/MomentumBar/Fill.value = p.momentum_stacks
		$UI/MomentumBar/Label.text = str(p.momentum_stacks) + "/" + str(p.momentum_max)
	else:
		$UI/MomentumBar.visible = false

	# Yörünge çizgisi: aktifken her frame, bırakılınca bir kez daha (çizgiyi sil)
	var _lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if p and (p.auto_mode or _lmb or _lmb_clear_pending):
		queue_redraw()
	_lmb_clear_pending = _lmb

	# ── Elemental Harmony: aktif unique element → Core Speed bonusu ──────────
	if p and p.get("has_elemental_harmony_util") and p.has_elemental_harmony_util:
		var _eh_elems := {}
		for _body in get_tree().get_nodes_in_group("subjects"):
			if _body.get("is_wet") and _body.is_wet: _eh_elems["wet"] = true
			if _body.get("is_burning") and _body.is_burning: _eh_elems["burn"] = true
			if _body.get("is_slowed") and _body.is_slowed: _eh_elems["cryo"] = true
			if _body.get("is_electrified") and _body.is_electrified: _eh_elems["elec"] = true
			if _body.get("is_frozen") and _body.is_frozen: _eh_elems["frozen"] = true
		p.elemental_harmony_bonus = _eh_elems.size() * 0.05

	# ── Last Stand Lv2-3: eksik HP → pasif armor kazanımı ─────────────────────
	if p and p.has_last_stand and p.last_stand_armor_mult > 0.0:
		var _missing := float(player_max_hp - player_hp)
		if _missing > 0.0:
			_armor_regen_acc += delta * (_missing * p.last_stand_armor_mult)
			var _ls_regen := int(_armor_regen_acc)
			if _ls_regen > 0:
				_armor_regen_acc -= float(_ls_regen)
				gain_armor(_ls_regen)

	# ── Armor regen ───────────────────────────────────────────────────────────
	if player_armor_regen_rate > 0.0 and player_armor < player_armor_cap:
		_armor_regen_acc += delta
		var regen_amount := int(_armor_regen_acc * player_armor_regen_rate)
		if regen_amount > 0:
			_armor_regen_acc = 0.0
			gain_armor(regen_amount)

	# ── Severance Protocol: HP < %40 → Armor Cap +10 (bir kez) ───────────────
	if p and p.get("has_severance_protocol") and p.has_severance_protocol:
		if not p.get("_severance_triggered") and float(player_hp) / float(max(player_max_hp, 1)) < 0.4:
			p._severance_triggered = true
			player_armor_cap += 10
			player_max_armor = max(player_max_armor, player_armor_cap)
			_update_armor_ui()

	# ── Overclock Threshold: 20 momentum stacks → Core Dmg ×1.3 (bir kez) ───
	if p and p.get("has_overclock_threshold") and p.has_overclock_threshold:
		if not p.get("_overclock_triggered") and p.momentum_stacks >= 20:
			p._overclock_triggered = true
			p.damage_mult *= 1.3

	# ── Armor gain boost timer ─────────────────────────────────────────────────
	if _armor_gain_boost_timer > 0.0:
		_armor_gain_boost_timer -= delta
		if _armor_gain_boost_timer <= 0.0:
			_armor_gain_boost = 1.0
			_armor_gain_boost_timer = 0.0

	if upgrading:
		return
	# Boss ölüm kontrolü her frame çalışır — spawn_interval beklenmez
	if _smiler_node != null:
		if not is_instance_valid(_smiler_node) or _smiler_node.is_dead:
			_smiler_node = null
			GameData.unlock_character("leila")
			GameData.add_xp(GameData.selected_character, 30)
			_show_run_end_screen()
	if _cyber404_node != null:
		if not is_instance_valid(_cyber404_node) or _cyber404_node.is_dead:
			_cyber404_node = null
			GameData.unlock_character("cyclone")
			GameData.add_xp(GameData.selected_character, 30)
			_show_run_end_screen()
	if _nyx_node != null:
		if not is_instance_valid(_nyx_node) or _nyx_node.is_dead:
			_nyx_node = null
			GameData.add_xp(GameData.selected_character, 30)
			_show_run_end_screen()

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		var nyx_alive: bool     = is_instance_valid(_nyx_node)      and not _nyx_node.is_dead
		var smiler_alive: bool  = is_instance_valid(_smiler_node)  and not _smiler_node.is_dead
		var cyber_alive: bool   = is_instance_valid(_cyber404_node) and not _cyber404_node.is_dead
		if nyx_alive or smiler_alive or cyber_alive:
			# Boss modunda: 3 düşman, aralık sabit
			for _si in 3:
				_spawn_subject()
		else:
			# Boss yokken daha yoğun spawn
			_spawn_subject()
			_spawn_subject()
	
	if calamity_aiming and not calamity_slots.is_empty():
		var mouse_pos = get_viewport().get_mouse_position()
		$UI/CalamityCircle.visible = true
		$UI/CalamityCircle.position = mouse_pos
		var calamity = calamity_slots[calamity_index]
		if calamity == "⚡":
			$UI/CalamityCircle.color = Color(1, 1, 0, 0.2)
			$UI/CalamityCircle.radius = 67
		elif calamity == "🔥":
			$UI/CalamityCircle.color = Color(1, 0.3, 0, 0.2)
			$UI/CalamityCircle.radius = 80
		elif calamity == "🌀":
			$UI/CalamityCircle.color = Color(0.5, 0.0, 1.0, 0.2)
			$UI/CalamityCircle.radius = 100
		elif calamity == "🌧️":  # Siege Rain — gerçek sapma alanı (±120px köşegeni) kadar
			$UI/CalamityCircle.color = Color(0.4, 0.4, 0.5, 0.2)
			$UI/CalamityCircle.radius = 170
		elif calamity == "🔥💥":  # Wildfire — hedef yok, tüm Yanan düşmanlar
			$UI/CalamityCircle.visible = false
		elif calamity == "🕳️":  # WormHole — mouse'a değil, karakterin tam önüne sabit açılır
			var _wp := _player_node
			if _wp:
				var _fd: Vector2 = _wp.aim_direction if _wp.get("aim_direction") else Vector2(1, 0)
				if _fd == Vector2.ZERO: _fd = Vector2(1, 0)
				$UI/CalamityCircle.position = _wp.global_position + _fd.normalized() * 120.0
			$UI/CalamityCircle.color = Color(0.5, 0.0, 1.0, 0.2)
			$UI/CalamityCircle.radius = 70
		elif calamity == "💣":  # Glitch Bomb
			$UI/CalamityCircle.color = Color(0.75, 0.0, 0.85, 0.2)
			$UI/CalamityCircle.radius = 120
		elif calamity == "💻💥":  # System Crash — hedef yok
			$UI/CalamityCircle.visible = false
		elif calamity == "🦠":  # Virus Rain — hedef yok
			$UI/CalamityCircle.visible = false
		elif calamity == "☠️":  # Decay Field
			$UI/CalamityCircle.color = Color(0.45, 0.2, 0.0, 0.2)
			$UI/CalamityCircle.radius = 100
		elif calamity == "🏚️":  # Rampart Collapse
			$UI/CalamityCircle.color = Color(0.2, 0.85, 1.0, 0.2)
			$UI/CalamityCircle.radius = 130
		$UI/CalamityCircle.queue_redraw()
	else:
		$UI/CalamityCircle.visible = false
		
	if not get_tree().paused:
		elapsed_time += delta
		var minutes = int(elapsed_time / 60)
		var seconds = int(elapsed_time) % 60
		$UI/LabelTime.text = "⏱  %02d:%02d" % [minutes, seconds]
		_check_survival_milestones(minutes)
	# Boss spawn — 10. dakikada bu bölümün boss'u gelir
	if not _boss_spawned and elapsed_time >= BOSS_SPAWN_TIME:
		_boss_spawned = true
		_boss_check_index += 1
		_spawn_section_boss()

func _on_upgrade_selected(index: int, canvas: CanvasLayer) -> void:
	canvas.queue_free()
	upgrading = false
	get_tree().paused = false
	level += 1
	GameData.record_upgrade_taken()
	if calamity_slots.size() >= max_calamity_slots:
		GameData.record_calamity_filled()

	# ── Kart takibi ───────────────────────────────────────────────────────────
	if index not in _owned_indices:
		_owned_indices.append(index)
	if _UPGRADE_META.has(index):
		var _meta: Dictionary = _UPGRADE_META[index]
		var _cat: String  = _meta["category"]
		var _uname: String = _meta["name"]
		if _cat == "Individuality" and not (_uname in _seen_individualities):
			_seen_individualities.append(_uname)
		elif _cat == "Utility":
			_utility_levels[_uname] = _utility_levels.get(_uname, 0) + 1
			_apply_utility_level(index, _utility_levels[_uname])

	# ── Identity kart: core sayacını artır ────────────────────────────────────
	var _p := get_node("Player")
	var _this_upgrade: Dictionary = {}
	for _u in upgrades:
		if _u.get("index", -1) == index:
			_this_upgrade = _u
			break
	if _this_upgrade.get("category", "") == "Identity":
		if index in _CONNECTED_CORE_INDICES:
			_p.connected_core_count += 1
		else:
			_p.special_core_count += 1
	update_ui()

	# Core upgrade — limit artık upgrade ekranında filtreleniyor, discard yok

	if index == 0:
		$BallLauncher.queue_upgrade_ball("split")
	elif index == 1:
		$BallLauncher.queue_upgrade_ball("electric")
	elif index == 2:
		$BallLauncher.queue_upgrade_ball("pierce")
	elif index == 224:
		var p = get_node("Player")
		p.chain_length += 5 * 14.0
	elif index == 4:
		var player = get_node("Player")
		player.SPEED += 50
	elif index == 5:
		# Orbit +1 — Launcher fires an extra ball toward player
		$BallLauncher.queue_upgrade_ball("")
	elif index == 6:
		# "Next One" — currently a no-op in orbit system (kept for future)
		pass
	elif index == 7:
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("⚡")
			update_ui()
	elif index == 8:
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🔥")
			update_ui()
	elif index == 9:
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🌀")
			update_ui()
	elif index == 11:
	# Ball Mastery - +1 to all balls
		var balls_dmg = get_node("Player")
		balls_dmg.ball_mastery += 1
	elif index == 12:
		var balls_dmg = get_node("Player")
		balls_dmg.pierce_bonus += 2
	elif index == 13:  # Electric Amp
		get_node("Player").electric_bonus += 2
	elif index == 99:  # Cryo Amp
		get_node("Player").cryo_bonus += 2
	elif index == 100:  # Hydro Amp
		get_node("Player").hydro_bonus += 2
	elif index == 101:  # Pyro Amp
		get_node("Player").pyro_bonus += 2
	elif index == 14:
		var balls_dmg = get_node("Player")
		balls_dmg.split_bonus += 2
	elif index == 15:
		$BallLauncher.queue_upgrade_ball("cryo")
	elif index == 16:
		$BallLauncher.queue_upgrade_ball("glitch")
	elif index == 17:
		$BallLauncher.queue_upgrade_ball("water")
	elif index == 18:
		$BallLauncher.queue_upgrade_ball("fire")
	elif index == 19:
		$BallLauncher.queue_upgrade_ball("mimic")
	elif index == 20:
		player_hp = min(player_hp + 10, player_max_hp)
	elif index == 21:
		player_max_hp += 5
		player_hp = min(player_hp + 5, player_max_hp)
	elif index == 22:
		$BallLauncher.queue_upgrade_ball("leech")
	elif index == 23:
		ally_chip_duration += 5.0
	# ── Vector Armor — Individuality ─────────────────────────────────────────
	elif index == 30:  # Blood for Steel
		player_max_hp = max(1, player_max_hp - 10)
		player_hp = min(player_hp, player_max_hp)
		player_max_armor += 10
		player_armor_cap += 10
		_update_armor_ui()
	elif index == 31:  # Pain Converter
		var p := get_node("Player")
		p.has_pain_converter = true
	elif index == 32:  # Adrenal Surge
		var p := get_node("Player")
		p.has_adrenal_surge = true
	elif index == 33:  # Scar Tissue
		player_max_hp = max(1, player_max_hp - 10)
		player_hp = min(player_hp, player_max_hp)
		player_armor_cap += 5
		player_max_armor = max(player_max_armor, player_armor_cap)
		player_armor_regen_rate += 1.0
		_update_armor_ui()
	elif index == 34:  # Emergency Protocol
		player_hp = max(1, player_hp - 15)
		update_ui()
		_armor_gain_boost = 1.75
		_armor_gain_boost_timer = 10.0
		_spawn_emergency_vfx()
	# ── Vector Armor — Utility ───────────────────────────────────────────────
	elif index == 35:  # Momentum Engine
		var p := get_node("Player")
		p.has_momentum_engine = true
	elif index == 36:  # Impact Feedback
		var p := get_node("Player")
		p.has_impact_feedback = true
	elif index == 37:  # Chain Density
		var p := get_node("Player")
		p.has_chain_density = true
	elif index == 38:  # Last Stand
		var p := get_node("Player")
		p.has_last_stand = true
	# ── Vector — Identity yeni core'lar ──────────────────────────────────────
	elif index == 40:
		$BallLauncher.queue_upgrade_ball("armor")
		get_node("Player").has_armor_core = true
	elif index == 41:
		$BallLauncher.queue_upgrade_ball("anchor")
	elif index == 42:
		$BallLauncher.queue_upgrade_ball("crusher")
	elif index == 43:
		$BallLauncher.queue_upgrade_ball("kinetic")
	elif index == 44:
		$BallLauncher.queue_upgrade_ball("bulwark")
	elif index == 45:
		$BallLauncher.queue_upgrade_ball("siege")
	elif index == 46:
		$BallLauncher.queue_upgrade_ball("bloodbound")
	elif index == 47:
		$BallLauncher.queue_upgrade_ball("tempered")
	# ── Vector — Yeni Individuality kartlar ──────────────────────────────────
	elif index == 48:  # Reinforced Frame
		player_armor_cap += 20
		player_max_armor = max(player_max_armor, player_armor_cap)
		get_node("Player").orbit_speed_mult *= 0.9
	elif index == 49:  # Iron Constitution
		get_node("Player").armor_gain_mult *= 1.25
	elif index == 50:  # Fortified Core System
		player_armor_cap += 15
		player_max_armor = max(player_max_armor, player_armor_cap)
		get_node("Player").momentum_gen_interval *= 1.25
	elif index == 51:  # Blood Circuit
		get_node("Player").has_blood_circuit = true
	elif index == 52:  # Fractured Frame
		player_max_hp = max(1, player_max_hp - 15)
		player_hp = mini(player_hp, player_max_hp)
		get_node("Player").damage_mult *= 1.4
		update_ui()
	elif index == 53:  # Glass Engine
		get_node("Player").has_glass_engine = true
	elif index == 54:  # Overclocked Reflex
		get_node("Player").orbit_speed_mult *= 1.2
		get_node("Player").armor_gain_mult  *= 0.85
	elif index == 55:  # Kinetic Nervous System
		get_node("Player").momentum_max += 10
	elif index == 56:  # Hyper Recovery Loop
		get_node("Player").return_speed_mult     = 1.5
	elif index == 57:  # Magnetic Weight
		get_node("Player").knockback_force_mult = 2.0
		get_node("Player").orbit_speed_mult    *= 0.9
	elif index == 58:  # Battlefield Anchor
		get_node("Player").slow_duration_mult = 2.0
		get_node("Player").SPEED             = int(get_node("Player").SPEED * 0.9)
	elif index == 59:  # Adrenal Armor System
		get_node("Player").has_adrenal_armor = true
	elif index == 60:  # Risk Engine
		get_node("Player").has_risk_engine   = true
		get_node("Player").armor_gain_mult  *= 0.7
		get_node("Player").armor_gain_mult  *= 0.7
	elif index == 104:  # Pressure Valve
		get_node("Player").has_pressure_valve = true
	elif index == 105:  # Iron Blood
		player_armor_cap += int(player_max_hp / 10)
		player_max_armor = max(player_max_armor, player_armor_cap)
		_update_armor_ui()
	elif index == 108:  # Momentum Cascade
		get_node("Player").has_momentum_cascade = true
	elif index == 109:  # Steel Rhythm
		get_node("Player").has_steel_rhythm = true
	elif index == 110:  # Bulwark Surge
		get_node("Player").has_bulwark_surge = true
	elif index == 111:  # Severance Protocol
		get_node("Player").has_severance_protocol = true
	elif index == 112:  # Inertia Plating
		var p := get_node("Player")
		var bonus: int = int(p.momentum_stacks / 5) * 5
		player_armor_cap += bonus
		player_max_armor = max(player_max_armor, player_armor_cap)
		_update_armor_ui()
	elif index == 113:  # Overclock Threshold
		get_node("Player").has_overclock_threshold = true
	# ── Vector — Utility (yeni) ───────────────────────────────────────────────
	elif index == 164: get_node("Player").has_armor_rush        = true
	elif index == 165: get_node("Player").has_combat_rhythm     = true
	elif index == 166: get_node("Player").has_shield_bash       = true
	elif index == 167: get_node("Player").has_siege_protocol    = true
	elif index == 168: get_node("Player").has_bulwark_echo      = true
	elif index == 169: get_node("Player").has_momentum_transfer = true
	elif index == 170: get_node("Player").has_tactical_reload   = true
	elif index == 171: get_node("Player").has_kinetic_surge     = true
	elif index == 172: get_node("Player").has_armor_conduit     = true
	# ── Vector — Connected Cores ─────────────────────────────────────────────
	elif index == 178: $BallLauncher.queue_upgrade_ball("iron_aura_core")
	elif index == 179:
		$BallLauncher.queue_upgrade_ball("momentum_field_core")
		get_node("Player").has_momentum_field_core = true
	elif index == 180: $BallLauncher.queue_upgrade_ball("regen_pulse_core")
	elif index == 181: $BallLauncher.queue_upgrade_ball("fortress_core")
	elif index == 182: $BallLauncher.queue_upgrade_ball("bloodwall_core")
	elif index == 183: $BallLauncher.queue_upgrade_ball("overcharge_core")
	elif index == 184: $BallLauncher.queue_upgrade_ball("anchor_pulse_core")
	# ── Leila Connected Cores ─────────────────────────────────────────────────
	elif index == 185: $BallLauncher.queue_upgrade_ball("mist_core")
	elif index == 186: $BallLauncher.queue_upgrade_ball("frost_aura_core")
	elif index == 187: $BallLauncher.queue_upgrade_ball("static_aura_core")
	elif index == 188: $BallLauncher.queue_upgrade_ball("catalyst_pulse_core")
	elif index == 189: $BallLauncher.queue_upgrade_ball("echo_resonance_core")
	elif index == 190: $BallLauncher.queue_upgrade_ball("volatile_aura_core")
	elif index == 191: $BallLauncher.queue_upgrade_ball("elemental_shield_core")
	# ── Cyclone Connected Cores ───────────────────────────────────────────────
	elif index == 192: $BallLauncher.queue_upgrade_ball("glitch_pulse_core")
	elif index == 193: $BallLauncher.queue_upgrade_ball("shadow_core")
	elif index == 194: $BallLauncher.queue_upgrade_ball("data_drain_core")
	elif index == 195: $BallLauncher.queue_upgrade_ball("virus_beacon_core")
	elif index == 196: $BallLauncher.queue_upgrade_ball("rogues_eye_core")
	elif index == 197: $BallLauncher.queue_upgrade_ball("circuit_overload_core")
	# ── Vector — Calamity ─────────────────────────────────────────────────────
	elif index == 174:  # Shockwave
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("💥")
	elif index == 175:  # Full Breach
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🔓")
	elif index == 176:  # Momentum Burst
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("💨")
	elif index == 177:  # Rampart Collapse
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🏚️")
	elif index == 198:  # WormHole
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🕳️")
	elif index == 199:  # Siege Rain
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🌧️")

	# ── Leila — Identity Cores ───────────────────────────────────────────────
	elif index == 61:  # Plasma Core
		$BallLauncher.queue_upgrade_ball("plasma")
	elif index == 62:  # Steam Core
		$BallLauncher.queue_upgrade_ball("steam")
	elif index == 63:  # Arc Core
		$BallLauncher.queue_upgrade_ball("arc")
	elif index == 64:  # Echo Core (Leila)
		$BallLauncher.queue_upgrade_ball("echo")
	elif index == 65:  # Prism Core
		$BallLauncher.queue_upgrade_ball("orbit")
	elif index == 77:  # Scatter Core
		$BallLauncher.queue_upgrade_ball("scatter")
	elif index == 78:  # Catalyst Core
		$BallLauncher.queue_upgrade_ball("catalyst")
	elif index == 79:  # Elemental Mastery (Identity)
		get_node("Player").debuff_duration_mult *= 1.3
	elif index == 87:  # Voltaic Core
		$BallLauncher.queue_upgrade_ball("voltaic")

	# ── Leila — Utility ─────────────────────────────────────────────────────
	elif index == 66:  # Conduction
		get_node("Player").electric_reaction_range_mult *= 1.3
	elif index == 67:  # Hydro Pressure
		get_node("Player").has_hydro_pressure = true
	elif index == 68:  # Arc Amplifier
		get_node("Player").arc_chain_targets += 1
	elif index == 69:  # Static Charge
		get_node("Player").has_static_charge = true
	elif index == 70:  # Cryostasis
		get_node("Player").freeze_duration_mult *= 1.1
	elif index == 71:  # Supercooling
		get_node("Player").cryo_slow_mult *= 1.15
	elif index == 73:  # Thermal Vision
		get_node("Player").burn_damage_mult *= 1.2
	elif index == 80:  # Arcane Mind
		get_node("Player").first_debuff_duration_mult *= 2.0
	elif index == 81:  # Resonance Engine
		get_node("Player").reaction_core_speed_bonus += 0.02
	elif index == 82:  # Frozen Time
		get_node("Player").freeze_duration_mult *= 1.3
	elif index == 83:  # Overheat
		get_node("Player").has_overheat = true
	elif index == 84:  # Elemental Harmony (Utility)
		get_node("Player").has_elemental_harmony_util = true
	elif index == 89:  # Thermal Expansion
		get_node("Player").has_thermal_expansion = true
	elif index == 90:  # Mana Overflow
		get_node("Player").has_mana_overflow = true
	elif index == 91:  # Perfect Catalyst
		get_node("Player").has_perfect_catalyst = true
	elif index == 102:  # Pyroblast
		get_node("Player").has_pyroblast = true

	# ── Leila — Individuality ────────────────────────────────────────────────
	elif index == 75:  # Arcane Focus
		get_node("Player").first_debuff_duration_mult *= 1.5
		_seen_individualities.append("Arcane Focus")
	elif index == 76:  # Mystic Flow
		get_node("Player").mystic_flow_stacks = 0
		get_node("Player").move_speed_bonus_pct = 0.0
		_seen_individualities.append("Mystic Flow")
	elif index == 85:  # Resonant Soul
		get_node("Player").reaction_heal_amount += 2
		_seen_individualities.append("Resonant Soul")
	elif index == 86:  # Elemental Memory
		get_node("Player").has_elemental_memory = true
		_seen_individualities.append("Elemental Memory")
	elif index == 200:  # Wet Armor
		get_node("Player").has_wet_armor = true
	elif index == 201:  # Burn Frenzy
		get_node("Player").has_burn_frenzy = true
	elif index == 202:  # Steam Surge
		get_node("Player").has_steam_surge = true
	elif index == 203:  # Shock Reflex
		get_node("Player").has_shock_reflex = true
	elif index == 204:  # Frost Barrier
		get_node("Player").has_frost_barrier = true
	elif index == 205:  # Primal Instinct
		get_node("Player").has_primal_instinct = true
	elif index == 206:  # Melt Spiral
		get_node("Player").has_melt_spiral = true
	elif index == 207:  # Void Resonance
		get_node("Player").has_void_resonance = true
	elif index == 210:  # Cryo Burst
		get_node("Player").has_cryo_burst = true
	elif index == 211:  # Arc Overload
		get_node("Player").has_arc_overload = true
	# ── Cyclone — yeni kartlar ────────────────────────────────────────────────
	elif index == 212:  # Tracer Core
		get_node("Player").has_tracer_core = true
		$BallLauncher.queue_upgrade_ball("tracer_core")
	elif index == 213:  # Spike Core
		$BallLauncher.queue_upgrade_ball("spike_core")
	elif index == 214:  # Leech Nova Core
		get_node("Player").has_leech_nova_core = true
		$BallLauncher.queue_upgrade_ball("leech_nova_core")
	elif index == 215:  # Glitch Bomb
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("💣")
			update_ui()
	elif index == 216:  # System Crash
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("💻💥")
			update_ui()
	elif index == 217:  # Virus Rain
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🦠")
			update_ui()
	elif index == 218:  # Decay Field
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("☠️")
			update_ui()
	elif index == 219:  # Decay Harvest
		get_node("Player").has_decay_harvest = true
	elif index == 220:  # Ghost Step
		get_node("Player").has_ghost_step = true
	elif index == 221:  # Overclock Protocol
		get_node("Player").has_overclock_protocol = true
	elif index == 222:  # Decay Amp
		pass  # level bazlı bonus _apply_utility_level'da uygulanıyor

	# ── Cyclone — Rogue ──────────────────────────────────────────────────────
	elif index >= 114 and index <= 146:
		var p := get_node("Player")
		match index:
			114: p.has_ricochet_strike    = true
			115: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			116: p.has_shadow_strike       = true
			119: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			120: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			121: p.has_data_siphon         = true
			126: p.has_system_overload     = true
			129: if calamity_slots.size() < max_calamity_slots: calamity_slots.append("💾")
			130: if calamity_slots.size() < max_calamity_slots: calamity_slots.append("👾")
			131: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			133: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			134: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			136: p.has_kinetic_rogue       = true
			138: if calamity_slots.size() < max_calamity_slots: calamity_slots.append("🎱")
			139: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			140: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			141: p.has_phase_shift         = true
			143: p.has_circuit_breaker     = true
			144: if calamity_slots.size() < max_calamity_slots: calamity_slots.append("🪞")
			145: p.has_rogues_instinct     = true
			146: p.has_shadow_dance        = true
			148: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			149: p.has_viral_load          = true
			150: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			151: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			152: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			154: p.has_zero_day            = true
			155: p.has_kernel_panic        = true
			156:
				if calamity_slots.size() < max_calamity_slots:
					calamity_slots.append("🧪")
			158: pass  # level bazlı bonus _apply_utility_level'da uygulanıyor
			# Yeni Identity Core'lar
			159: $BallLauncher.queue_upgrade_ball("phantom_circuit")
			160: $BallLauncher.queue_upgrade_ball("antivirus_core")
			161: $BallLauncher.queue_upgrade_ball("decay")
			162: $BallLauncher.queue_upgrade_ball("static_core")
			163: $BallLauncher.queue_upgrade_ball("ricochet_core")

	# ── Leila — Calamity ─────────────────────────────────────────────────────
	elif index == 94:  # Blizzard
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("❄️")
			update_ui()
	elif index == 95:  # Monsoon
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🌊")
			update_ui()
	elif index == 96:  # EMP Pulse
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🔋")
			update_ui()
	elif index == 97:  # Volcanic Rift
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🌋")
			update_ui()
	elif index == 98:  # Thunderstorm
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("⛈️")
			update_ui()
	elif index == 209:  # Wildfire
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🔥💥")
			update_ui()

	update_ui()
	$BallLauncher.queue_redraw()
	
func _pick_rarity_weighted_cards(pool: Array, current_level: int, count: int) -> Array:
	# Rarity olasılık tablosu: [common, uncommon, rare, epic, legendary]
	var weights: Array
	if current_level <= 5:
		weights = [55, 30, 12, 3, 0]
	elif current_level <= 12:
		weights = [35, 35, 22, 7, 1]
	else:
		weights = [15, 30, 32, 18, 5]

	var rarity_names := ["common", "uncommon", "rare", "epic", "legendary"]
	var result: Array = []
	var used_names: Array = []

	for _i in range(count):
		# Rarity çek
		var roll: int = randi() % 100
		var chosen_rarity: String = "common"
		var cumulative: int = 0
		for ri in range(rarity_names.size()):
			cumulative += weights[ri]
			if roll < cumulative:
				chosen_rarity = rarity_names[ri]
				break

		# O rarity'den uygun kartları filtrele
		var candidates := pool.filter(func(u):
			return u["rarity"] == chosen_rarity and not (u["name"] in used_names)
		)
		# O rarity'de kart yoksa bir üst/alt rarity'de ara
		if candidates.is_empty():
			candidates = pool.filter(func(u): return not (u["name"] in used_names))

		if candidates.is_empty():
			break

		# Weight'e göre ağırlıklı seçim
		var total_w: int = 0
		for c in candidates:
			total_w += c.get("weight", 1)
		var pick: int = randi() % total_w
		var cumw: int = 0
		for c in candidates:
			cumw += c.get("weight", 1)
			if pick < cumw:
				result.append(c)
				used_names.append(c["name"])
				break

	return result

func _apply_utility_level(index: int, level: int) -> void:
	var p := get_node("Player")
	match index:
		11:  # Core Mastery — her seviye +1 ball_mastery (kümülatif, no-op here, handled in elif)
			pass
		13:  # Electric Amp — her seviye +2 electric_bonus (no-op, handled in elif)
			pass
		14:  # Split Amp — her seviye +2 split_bonus (no-op, handled in elif)
			pass
		35:  # Momentum Engine
			match level:
				1: p.momentum_speed_bonus = 0.03; p.momentum_max = 20; p.momentum_gen_interval = 4.0
				2: p.momentum_speed_bonus = 0.05; p.momentum_max = 20; p.momentum_gen_interval = 4.0
				3: p.momentum_speed_bonus = 0.07; p.momentum_max = 30; p.momentum_gen_interval = 3.0
		36:  # Impact Feedback
			match level:
				1: p.impact_feedback_threshold = 10
				2: p.impact_feedback_threshold = 7
				3: p.impact_feedback_threshold = 5
		37:  # Chain Density
			match level:
				1: p.chain_density_bonus_per_hit = 1
				2: p.chain_density_bonus_per_hit = 2
				3: p.chain_density_bonus_per_hit = 3
		38:  # Last Stand
			match level:
				1: p.last_stand_hp_mult = 0.005; p.last_stand_armor_mult = 0.0
				2: p.last_stand_hp_mult = 0.008; p.last_stand_armor_mult = 0.003
				3: p.last_stand_hp_mult = 0.012; p.last_stand_armor_mult = 0.005
		104:  # Pressure Valve
			match level:
				1: p.pressure_valve_threshold = 5
				2: p.pressure_valve_threshold = 4
				3: p.pressure_valve_threshold = 3
		108:  # Momentum Cascade
			match level:
				1: p.momentum_cascade_threshold = 12
				2: p.momentum_cascade_threshold = 10
				3: p.momentum_cascade_threshold = 8
		110:  # Bulwark Surge
			match level:
				1: p.bulwark_surge_threshold = 0.75; p.bulwark_surge_mult = 1.15
				2: p.bulwark_surge_threshold = 0.75; p.bulwark_surge_mult = 1.20
				3: p.bulwark_surge_threshold = 0.60; p.bulwark_surge_mult = 1.30
		164:  # Armor Rush
			match level:
				1: p.armor_rush_threshold = 13
				2: p.armor_rush_threshold = 11
				3: p.armor_rush_threshold = 9
		165:  # Combat Rhythm
			match level:
				1: p.combat_rhythm_threshold = 6
				2: p.combat_rhythm_threshold = 5
				3: p.combat_rhythm_threshold = 4
		166:  # Shield Bash
			match level:
				1: p.shield_bash_mult = 1.25
				2: p.shield_bash_mult = 1.5
				3: p.shield_bash_mult = 2.0
		167:  # Siege Protocol
			match level:
				1: p.siege_protocol_bonus = 1
				2: p.siege_protocol_bonus = 2
				3: p.siege_protocol_bonus = 3
		168:  # Bulwark Echo
			match level:
				1: p.bulwark_echo_delay = 4.0; p.bulwark_echo_amount = 1
				2: p.bulwark_echo_delay = 3.0; p.bulwark_echo_amount = 1
				3: p.bulwark_echo_delay = 2.0; p.bulwark_echo_amount = 2
		171:  # Kinetic Surge
			match level:
				1: p.kinetic_surge_threshold = 15; p.kinetic_surge_speed = 700.0
				2: p.kinetic_surge_threshold = 15; p.kinetic_surge_speed = 750.0
				3: p.kinetic_surge_threshold = 12; p.kinetic_surge_speed = 750.0
		172:  # Armor Conduit
			match level:
				1: p.armor_conduit_mult = 1.25
				2: p.armor_conduit_mult = 1.5
				3: p.armor_conduit_mult = 2.0
		119:  # Extended Glitch
			p.extended_glitch_bonus = level
		115:  # Data Exploit
			p.data_exploit_level = level
		131:  # Angular Precision
			p.angular_precision_level = level
		120:  # Signal Jam
			p.signal_jam_level = level
		133:  # Bounce Mastery
			p.bounce_mastery_level = level
		158:  # Backstab Protocol
			p.backstab_protocol_level = level
		148:  # Stack Overflow
			p.stack_overflow_level = level
		150:  # Memory Leak
			p.memory_leak_level = level
		152:  # Cascade Delete
			p.cascade_delete_level = level
		134:  # Pinball Protocol
			p.pinball_protocol_level = level
		139:  # Stealth Pass
			p.stealth_pass_level = level
		140:  # Ghost Protocol
			p.ghost_protocol_level = level
		151:  # Corruption Protocol
			p.corruption_protocol_level = level
		222:  # Decay Amp
			p.decay_amp_level = level

func show_dialog(text: String, pos: Vector2) -> void:
	var label = Label.new()
	label.text = text
	label.position = pos + Vector2(-100, -60)
	label.add_theme_font_override("font", _font_regular)
	label.add_theme_color_override("font_color", Color(1, 1, 0))
	add_child(label)
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(label):
		label.queue_free()
