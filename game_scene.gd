extends Node2D

var _font_bold    = preload("res://assets/orbitronfont/Orbitron-Bold.ttf")
var _font_regular = preload("res://assets/orbitronfont/Orbitron-Regular.ttf")

var level = 1
var player_hp = 50
var player_max_hp = 50
var subject_scene = preload("res://subject.tscn")
var upgrading = false
var heavy_subject_scene = preload("res://heavy_subject.tscn")
var armed_subject_scene = preload("res://armed_subject.tscn")
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
var ally_chip_duration: float = 15.0  # Upgradeable via card (index 23)

# ── RTS / Tactical Mode ───────────────────────────────────────────────────────
var _rts_mode:    bool        = false
var _rts_overlay: CanvasLayer = null

# ── Veri Barı ─────────────────────────────────────────────────────────────────
var _data_current:    float      = 0.0
var _data_max:        float      = 40.0
var _data_bar_canvas: CanvasLayer = null
var _data_bar_fill:   ColorRect   = null
var _data_bar_label:  Label       = null
var _data_particle_canvas: CanvasLayer = null
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
	crate.play_intro(Vector2(1240, 570))

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
	tw.tween_property(b, "position", Vector2(1240, 400), 0.75)\
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
	for i in range(8):
		tween.tween_property(camera, "offset", Vector2(randf_range(-15, 15), randf_range(-15, 15)), 0.05)
	tween.tween_property(camera, "offset", original_pos, 0.05)

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
	title.text = "RUN TAMAMLANDI"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_font_override("font", _font_bold)
	title.modulate = Color(0.2, 1.0, 0.6)
	title.position = Vector2(660, 200)
	canvas.add_child(title)

	var stats_text := "⏱  %02d:%02d\n\n💀  Düşman: %d\n\n🤝  Kurtarılan: %d" % [
		minutes, seconds, total_subjects_killed, get_tree().get_nodes_in_group("allies").size()
	]
	var stats := Label.new()
	stats.text = stats_text
	stats.add_theme_font_size_override("font_size", 28)
	stats.add_theme_font_override("font", _font_bold)
	stats.modulate = Color(0.85, 0.85, 0.9)
	stats.position = Vector2(760, 340)
	canvas.add_child(stats)

	var btn := Button.new()
	btn.text = "ANA MENÜYE DÖN"
	btn.add_theme_font_size_override("font_size", 26)
	btn.position = Vector2(760, 620)
	btn.size     = Vector2(400, 60)
	canvas.add_child(btn)
	btn.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://main_menu.tscn")
	)

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
	section_label.text = "// AVAILABLE UPGRADES //"
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
	nyx.play_entry(Vector2(1240, 380))

func _spawn_smiler() -> void:
	var smiler = load("res://s_miler_79.gd").new()
	smiler.name = "SMiler79"
	_smiler_node = smiler
	add_child(smiler)
	smiler.landed.connect(_on_smiler_landed)
	smiler.play_entry(Vector2(1240, 500))

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
		Vector2(820, 1260),   # giriş — güney (ekran altı)
		Vector2(820, 750),    # kuzey sonu
		Vector2(725, 750)     # sandalye
	)

func _ready() -> void:
	update_ui()
	$UI/BtnPause.pressed.connect(_show_pause_menu)
	$UI/FusionEnergyBar.max_value = 50
	$UI/FusionEnergyBar.value = 0
	$UI/IntegrityBar.max_value = player_max_hp
	$UI/IntegrityBar.value = player_hp
	$UI/IntegrityBar/LabelIntegrity.text = str(player_hp) + " / " + str(player_max_hp)
			# Fusion Zone hidden at start
	var fusion_zone = get_tree().get_first_node_in_group("fusion_zone")
	if fusion_zone:
		fusion_zone.visible = false
		fusion_zone.set_physics_process(false)
	
	_setup_data_bar()
	_setup_auto_toggle()
	_setup_neon_sign()
	get_tree().paused = true
	_show_hasmen_selection()
	


func update_ui() -> void:
	$UI/LabelLevel.text = "◈  LEVEL " + str(level)
	$UI/IntegrityBar.max_value = player_max_hp
	$UI/IntegrityBar.value = player_hp
	$UI/LabelBalls.text = "⬤  BALLS   " + str(get_node("Player").orbit_balls.size()) + " / " + str(get_node("Player").MAX_ORBIT)
	$UI/IntegrityBar.max_value = player_max_hp
	$UI/IntegrityBar.value = player_hp
	$UI/IntegrityBar/LabelIntegrity.text = "♥  " + str(player_hp) + " / " + str(player_max_hp)

	# Aktif upgrade'ler
	var upgrade_text = "— UPGRADES —\n"
	if get_node("Player").SPEED > 300:
		upgrade_text += "▸ Speed Up\n"
	if get_node("Player").chain_length > 220:
		upgrade_text += "▸ Chain Up\n"
	if get_node("Player").has_next_one:
		upgrade_text += "▸ Next One\n"
	if upgrade_text == "— UPGRADES —\n":
		upgrade_text += "  none"
	$UI/LabelUpgrades.text = upgrade_text

	# Catch slot indicator (legacy — hidden or repurposed)
	var catch_lbl = get_node_or_null("UI/LabelCatch")
	if catch_lbl:
		catch_lbl.visible = false

	# Calamity slots
	var calamity_text = "— CALAMITY —\n"
	if calamity_slots.is_empty():
		calamity_text += "◻  ◻  ◻"
	else:
		for i in range(calamity_slots.size()):
			if i == calamity_index:
				calamity_text += "◉ " + calamity_slots[i] + "  "
			else:
				calamity_text += "◎ " + calamity_slots[i] + "  "
		for _j in range(max_calamity_slots - calamity_slots.size()):
			calamity_text += "◻  "
	$UI/LabelCalamity.text = calamity_text
	_update_processor_btn()

func subject_died(xp_reward: int = 1, death_pos: Vector2 = Vector2.ZERO) -> void:
	subjects_killed += 1
	total_subjects_killed += 1
	GameData.add_xp(GameData.selected_character, xp_reward)
	update_ui()
	# Level sayacı boss kontrolü için devam ediyor
	if subjects_killed >= kills_to_level:
		subjects_killed = 0
		kills_to_level = int(kills_to_level * 1.3)
		spawn_interval = max(spawn_interval - 0.1, min_spawn_interval)
	# Veri parçacıkları: hasar miktarına göre 3-7 parçacık
	var particle_count := clampi(xp_reward + 2, 3, 7)
	_spawn_data_particles(death_pos, float(xp_reward) * 10.0, particle_count)

func _setup_neon_sign() -> void:
	var sign: Node2D = load("res://neon_sign.gd").new()
	# Oyun alanı ortası, üst duvara monte: x=1240, y=248 (duvarın hemen altı)
	# Tribün sağ duvarına monte, cadde şeridinde dikey tabela
	sign.position = Vector2(930, 120)
	add_child(sign)

func _setup_auto_toggle() -> void:
	var btn := Button.new()
	btn.name = "BtnAutoMode"
	btn.text = "AUTO  OFF"
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
			btn.text = "AUTO  ON"
			btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.45))
			player._fire_all_balls()
		else:
			btn.text = "AUTO  OFF"
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
	_data_bar_label.text = "UPGRADE READY"
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
	var canvas_tf: Transform2D = get_viewport().get_canvas_transform()
	var screen_pos: Vector2    = canvas_tf * world_pos
	var bar_target: Vector2    = _DATA_BAR_POS + Vector2(_DATA_BAR_W * 0.5, _DATA_BAR_H * 0.5) + Vector2(0, 7)
	var chars := ["0","1","▓","▒","░","#","@","$","%","&","■","▲"]
	var per_particle := amount / float(count)

	for i in count:
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
			_data_current += per_particle
			_update_data_bar()
			if _data_current >= _data_max:
				_data_current = 0.0
				_data_max     = _data_max * 1.35
				get_tree().paused = true
				show_upgrade_menu()
			lbl.queue_free()
		)

func subject_rescued() -> void:
	GameData.add_xp(GameData.selected_character, 2)

func player_damaged(amount: int = 1) -> void:
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
	header.text     = "// EXPERIMENT SESSION CONCLUDED //"
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
		["DATA HARVESTED",       _format_data(data_collected) + " units", Color(0.0, 1.0, 0.55)],
		["SESSION TIME",         "%02d:%02d" % [minutes, seconds],         Color(0.0, 0.9, 1.0)],
		["THREATS NEUTRALIZED",  str(total_subjects_killed),                 Color(0.0, 0.9, 1.0)],
		["EXPERIMENT LEVEL",     str(level),                               Color(0.0, 0.9, 1.0)],
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
	var retry_btn = Button.new()
	retry_btn.text         = "RETRY SESSION"
	retry_btn.position     = Vector2(200, 760)
	retry_btn.size         = Vector2(240, 55)
	retry_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	retry_btn.add_theme_font_override("font", _font_bold)
	retry_btn.pressed.connect(_on_restart)
	canvas.add_child(retry_btn)

	var menu_btn = Button.new()
	menu_btn.text         = "MAIN MENU"
	menu_btn.position     = Vector2(480, 760)
	menu_btn.size         = Vector2(240, 55)
	menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_btn.add_theme_font_override("font", _font_bold)
	menu_btn.pressed.connect(_on_main_menu.bind(canvas))
	canvas.add_child(menu_btn)

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# ── Veri Sistemi ─────────────────────────────────────────────────────────────

func add_data(amount: int) -> void:
	data_collected += amount
	var lbl = get_node_or_null("UI/LabelData")
	if lbl:
		lbl.text = _format_data(data_collected) + " units"

func _format_data(n: int) -> String:
	if n >= 1_000_000:
		return "%.2f M" % (n / 1_000_000.0)
	elif n >= 1_000:
		return "%.1f K" % (n / 1_000.0)
	return str(n)

func _get_hasmen_quote() -> String:
	if data_collected < 500:
		return "Pathetic. My patience has limits, unlike your failure rate."
	elif data_collected < 2_000:
		return "Barely enough. The Personal-ITY chip deserves better test subjects."
	elif data_collected < 8_000:
		return "Mediocre results. But the behavioral patterns are... noted."
	elif data_collected < 25_000:
		return "Not bad. The next chip update draws closer. Keep going."
	else:
		return "Exceptional. You may yet prove worthy of my investment."

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

func show_upgrade_menu() -> void:
	upgrading = true

	# weight: seçilme ağırlığı — düşük = nadir
	# rarity: "common" | "rare" | "epic"
	var char_id: String = get_node("Player").character_type
	var upgrades = [
	# ── Vector (Kinetik) ──────────────────────────────────────────────────────
	{"name": "Split Ball",          "category": "Utility",       "color": Color(0.2, 0.8, 0.2), "desc": "Ball splits into 3",                        "index": 0,  "weight": 10, "rarity": "common", "chars": ["vector"]},
	{"name": "Pierce Ball",         "category": "Utility",       "color": Color(1.0, 0.8, 0.0), "desc": "Ball pierces through",                      "index": 2,  "weight": 10, "rarity": "common", "chars": ["vector"]},
	{"name": "Split Amp",           "category": "Utility",       "color": Color(1.0, 0.2, 0.2), "desc": "Split ball +2 damage",                      "index": 14, "weight": 10, "rarity": "common", "chars": ["vector"]},
	# ── Leila (Elemental) ─────────────────────────────────────────────────────
	{"name": "Electric Ball",       "category": "Utility",       "color": Color(0.2, 0.5, 1.0), "desc": "Ball gains electricity",                    "index": 1,  "weight": 10, "rarity": "common", "chars": ["leila"]},
	{"name": "Cryo Ball",           "category": "Utility",       "color": Color(0.5, 0.8, 1.0), "desc": "Slows subject by 25%",                      "index": 15, "weight": 10, "rarity": "common", "chars": ["leila"]},
	{"name": "Water Ball",          "category": "Utility",       "color": Color(0.0, 0.5, 1.0), "desc": "Applies wet, single hit",                   "index": 17, "weight": 10, "rarity": "common", "chars": ["leila"]},
	{"name": "Fire Ball",           "category": "Utility",       "color": Color(1.0, 0.3, 0.0), "desc": "Applies burn to subject",                   "index": 18, "weight": 10, "rarity": "common", "chars": ["leila"]},
	{"name": "Thunder Amp",         "category": "Utility",       "color": Color(0.2, 0.5, 1.0), "desc": "Electric ball +2 damage",                   "index": 13, "weight": 10, "rarity": "common", "chars": ["leila"]},
	# ── Cyclone (Manipülasyon) ────────────────────────────────────────────────
	{"name": "Glitch Ball",         "category": "Utility",       "color": Color(0.8, 0.0, 0.8), "desc": "Disorients subject for 3s",                 "index": 16, "weight": 10, "rarity": "common", "chars": ["cyclone"]},
	{"name": "Mimic Ball",          "category": "Utility",       "color": Color(0.5, 0.5, 1.0), "desc": "Copies the nearest powered-up ball",        "index": 19, "weight": 1,  "rarity": "epic",   "chars": ["cyclone"]},
	{"name": "Data Leech Ball",     "category": "Utility",       "color": Color(0.6, 0.0, 0.2), "desc": "+2 Integrity on hit",                       "index": 22, "weight": 10, "rarity": "common", "chars": ["cyclone"]},
	# ── Herkese açık ─────────────────────────────────────────────────────────
	{"name": "Ball Mastery",        "category": "Utility",       "color": Color(0.2, 0.8, 0.2), "desc": "+1 damage to all balls",                    "index": 11, "weight": 10, "rarity": "common", "chars": []},
	{"name": "Speed Upgrade",       "category": "Individuality", "color": Color(0.6, 0.2, 0.8), "desc": "Movement speed increases",                  "index": 4,  "weight": 10, "rarity": "common", "chars": []},
	{"name": "Lightning",           "category": "Calamity",      "color": Color(1.0, 1.0, 0.0), "desc": "Lightning strikes selected point",          "index": 7,  "weight": 8,  "rarity": "common", "chars": []},
	{"name": "Flame Zone",          "category": "Calamity",      "color": Color(1.0, 0.3, 0.0), "desc": "Continuous damage in selected area",        "index": 8,  "weight": 8,  "rarity": "common", "chars": []},
	{"name": "Gravitational Force", "category": "Calamity",      "color": Color(0.5, 0.0, 1.0), "desc": "Pulls subjects for 5s",                     "index": 9,  "weight": 8,  "rarity": "common", "chars": []},
	{"name": "Medkit",              "category": "Individuality", "color": Color(0.9, 0.1, 0.1), "desc": "+10 HP restored",                           "index": 20, "weight": 10, "rarity": "common", "chars": []},
	{"name": "Max Health Up",       "category": "Individuality", "color": Color(0.8, 0.2, 0.2), "desc": "Maximum HP +5",                             "index": 21, "weight": 10, "rarity": "common", "chars": []},
]
	upgrades = upgrades.filter(func(u): return u["chars"].is_empty() or char_id in u["chars"])
	
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
	title.text = "LEVEL UP!"
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
		canvas.add_child(card_sprite)

		# ── Kart ismi ────────────────────────────────────────────────────────
		var name_label = Label.new()
		name_label.text = upgrade["name"]
		name_label.size = Vector2(card_width - 30, 40)
		name_label.position = Vector2(tx + 15, ty + card_height - 110)
		name_label.add_theme_font_size_override("font_size", 17)
		name_label.add_theme_font_override("font", _font_bold)
		name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		canvas.add_child(name_label)

		# ── Kart açıklaması ──────────────────────────────────────────────────
		var desc_label = Label.new()
		desc_label.text = upgrade["desc"]
		desc_label.size = Vector2(card_width - 30, 60)
		desc_label.position = Vector2(tx + 15, ty + card_height - 72)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_font_override("font", _font_regular)
		desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		canvas.add_child(desc_label)
		
		# Confirm ve Skip ortada
		var confirm_btn = Button.new()
		confirm_btn.text = "Confirm"
		confirm_btn.size = Vector2(180, 55)
		confirm_btn.position = Vector2(830, 820)
		confirm_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		confirm_btn.add_theme_font_override("font", _font_bold)
		confirm_btn.pressed.connect(_on_confirm.bind(canvas))
		canvas.add_child(confirm_btn)

		var skip_btn = Button.new()
		skip_btn.text = "Skip"
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
		canvas.add_child(click_area)

		# ── Card entry animation: bottom to top, staggered ─────────────────────
		var card_anim_nodes: Array = [card_sprite, name_label, desc_label, click_area]
		var card_target_ys: Array = []
		for anim_node in card_anim_nodes:
			card_target_ys.append(anim_node.position.y)
			anim_node.position.y += 160.0
		for anim_node in [card_sprite, name_label, desc_label]:
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
		var subjects = get_tree().get_nodes_in_group("subjects")
		for subject in subjects:
			if subject.global_position.distance_to(pos) < 150:
				var direction = (pos - subject.global_position).normalized()
				subject.global_position += direction * 60 * get_process_delta_time()
		elapsed += get_process_delta_time()
		await get_tree().process_frame
		
func _activate_arise() -> void:
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		if not ball.moving:
			ball.scale = Vector2(1, 1)
			ball.z_index = 2
			ball.get_node("CollisionShape2D").disabled = false
			ball.damage = 1
			ball.speed = 400.0
			ball.moving = true
			var player = get_node("Player")
			ball.move_direction = (player.global_position - ball.global_position).normalized()

func _input(event: InputEvent) -> void:
	# C key - cycle through Calamity slots
	if event is InputEventKey and event.keycode == KEY_C and event.pressed:
		if not calamity_slots.is_empty():
			calamity_index = (calamity_index + 1) % calamity_slots.size()
			update_ui()
			
	
	# Right click held - show area of effect
	# E key - fire Calamity
	if event is InputEventKey and event.keycode == KEY_E:
		if event.pressed and not calamity_slots.is_empty():
			calamity_aiming = true
		elif not event.pressed and calamity_aiming:
			calamity_aiming = false
			var mouse_pos = get_viewport().get_mouse_position()
			var calamity = calamity_slots[calamity_index]
			if calamity == "⚡":
				_activate_lightning(mouse_pos)
			elif calamity == "🔥":
				_activate_flame(mouse_pos)
			elif calamity == "🌀":
				_activate_gravity(mouse_pos)
			elif calamity == "🔮":
				_activate_arise()
			calamity_slots.remove_at(calamity_index)
			calamity_index = clamp(calamity_index, 0, max(calamity_slots.size() - 1, 0))
			update_ui()
	
	# Tab → Tactical Mode aç/kapat
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed and not event.echo:
		if not get_tree().paused:
			_toggle_rts_mode()

	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if not upgrading:
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
	lbl.text              = "◈  TACTICAL MODE  //  ×0.5"
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
	title.text = "PAUSED"
	title.position = Vector2(880, 300)
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_font_override("font", _font_bold)
	title.modulate = Color(1, 0.8, 0)
	canvas.add_child(title)

	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	resume_btn.size = Vector2(200, 55)
	resume_btn.position = Vector2(860, 450)
	resume_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_btn.add_theme_font_override("font", _font_bold)
	resume_btn.pressed.connect(_on_resume.bind(canvas))
	canvas.add_child(resume_btn)

	var menu_btn = Button.new()
	menu_btn.text = "Main Menu"
	menu_btn.size = Vector2(200, 55)
	menu_btn.position = Vector2(860, 530)
	menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_btn.add_theme_font_override("font", _font_bold)
	menu_btn.pressed.connect(_on_main_menu.bind(canvas))
	canvas.add_child(menu_btn)

	var quit_btn = Button.new()
	quit_btn.text = "Quit"
	quit_btn.size = Vector2(200, 55)
	quit_btn.position = Vector2(860, 610)
	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_btn.add_theme_font_override("font", _font_bold)
	quit_btn.pressed.connect(_on_quit_game)
	canvas.add_child(quit_btn)

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
	particles.z_index                = 4
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

	# Merkez vorteks halkası — büyüyüp küçülüyor
	var vortex := Node2D.new()
	vortex.global_position = pos
	vortex.z_index = 5
	add_child(vortex)
	var vr := 0.0
	var vtw := create_tween().set_loops()
	vtw.tween_method(func(r: float):
		vr = r
		if is_instance_valid(vortex): vortex.queue_redraw(),
		8.0, 55.0, 0.6)
	vtw.tween_method(func(r: float):
		vr = r
		if is_instance_valid(vortex): vortex.queue_redraw(),
		55.0, 8.0, 0.6)
	vortex.draw.connect(func():
		vortex.draw_arc(Vector2.ZERO, vr, 0, TAU, 48, Color(0.8, 0.2, 1.0, 0.7), 3.0)
		vortex.draw_arc(Vector2.ZERO, vr * 0.5, 0, TAU, 32, Color(0.5, 0.0, 1.0, 0.5), 2.0)
	)

	await get_tree().create_timer(duration).timeout
	vtw.kill()
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
		"armed":         subject = armed_subject_scene.instantiate()
		"heavy":         subject = heavy_subject_scene.instantiate()
		"cyber_shooter": subject = cyber_shooter_scene.instantiate()
		"cyber_rifle":   subject = cyber_rifle_scene.instantiate()
		"cyber_shotgun": subject = cyber_shotgun_scene.instantiate()
		_:               subject = subject_scene.instantiate()

	var rand_x = randf_range(950, 1820)
	subject.position = Vector2(rand_x, -50)
	add_child(subject)

func _draw() -> void:
	var player := get_node_or_null("Player")
	if player == null: return
	var auto_on: bool  = player.auto_mode
	var lmb_held: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if not auto_on and not lmb_held: return
	var start: Vector2 = player.global_position
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
	const XMIN := 910.0; const XMAX := 1580.0
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

func _process(_delta: float) -> void:
	queue_redraw()
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

	spawn_timer += _delta
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
		elif calamity == "🔮":
			$UI/CalamityCircle.color = Color(0.8, 0.8, 1.0, 0.2)
			$UI/CalamityCircle.radius = 200
		$UI/CalamityCircle.queue_redraw()
	else:
		$UI/CalamityCircle.visible = false
		
	if not get_tree().paused:
		elapsed_time += _delta
		var minutes = int(elapsed_time / 60)
		var seconds = int(elapsed_time) % 60
		$UI/LabelTime.text = "⏱  %02d:%02d" % [minutes, seconds]
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
	
	if index == 0:
		$BallLauncher.queue_upgrade_ball("split")
	elif index == 1:
		$BallLauncher.queue_upgrade_ball("electric")
	elif index == 2:
		$BallLauncher.queue_upgrade_ball("pierce")
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
	elif index == 10:
		if calamity_slots.size() < max_calamity_slots:
			calamity_slots.append("🔮")
			update_ui()
	elif index == 11:
	# Ball Mastery - +1 to all balls
		var balls_dmg = get_node("Player")
		balls_dmg.ball_mastery += 1
	elif index == 12:
		var balls_dmg = get_node("Player")
		balls_dmg.pierce_bonus += 2
	elif index == 13:
		var balls_dmg = get_node("Player")
		balls_dmg.electric_bonus += 2
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
		# Chip Boost — extend ally chip duration for all future allies
		ally_chip_duration += 5.0

	update_ui()
	$BallLauncher.queue_redraw()
	
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
