extends Node2D

var _font_bold    = preload("res://assets/orbitronfont/Orbitron-Bold.ttf")
var _font_regular = preload("res://assets/orbitronfont/Orbitron-Regular.ttf")

var level = 1
var player_hp = 50
var player_max_hp = 50
var zombie_scene = preload("res://zombie.tscn")
var upgrading = false
var armored_zombie_scene = preload("res://armored_zombie.tscn")
var cyber_zombie_scene = preload("res://cyber_zombie.tscn")
var fast_zombie_scene = preload("res://fast_zombie.tscn")
var next_ball_upgrade = ""
var calamity_slots = []
var max_calamity_slots = 3
var calamity_index = 0
var calamity_aiming = false
var zombies_killed = 0
var kills_to_level = 3
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
var boss = null
var boss_defeated = false
var boss_warning = null
var data_collected: int = 0
var total_zombies_killed: int = 0

func _show_boss_warning() -> void:
	boss_warning = ColorRect.new()
	boss_warning.name = "BossWarning"
	boss_warning.size = Vector2(150, 150)
	boss_warning.color = Color(0.4, 0.2, 0.0)
	boss_warning.position = Vector2(280, -200)
	add_child(boss_warning)
	
	# Yukarıdan düşsün
	var tween = create_tween()
	tween.tween_property(boss_warning, "position", Vector2(280, 550), 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	
	await get_tree().create_timer(1.0).timeout
	_screen_shake()
	
	# 3 level bekle sonra aç
	await get_tree().create_timer(15.0).timeout
	_open_crate()

func _open_crate() -> void:
	if boss_warning == null:
		return
	
	# Sandık açılıyor - renk değişimi
	var tween = create_tween()
	tween.tween_property(boss_warning, "color", Color(0.1, 0.1, 0.1), 0.5)
	tween.parallel().tween_property(boss_warning, "scale", Vector2(1.3, 1.3), 0.5)
	
	await get_tree().create_timer(1.0).timeout
	
	# Işıklar açılıyor - mavi parıltı
	var tween2 = create_tween()
	tween2.tween_property(boss_warning, "color", Color(0.0, 0.5, 1.0), 0.5)
	
	await get_tree().create_timer(1.0).timeout
	
	# Sahaya atla
	boss_warning.queue_free()
	boss_warning = null
	_spawn_boss()

func _spawn_boss() -> void:
	var b = cyber_404_scene.instantiate()
	b.position = Vector2(350, 550)
	b.scale = Vector2(3.0, 3.0)
	add_child(b)
	boss = b
	
	# Atlama sırasında collision kapat
	b.get_node("CollisionShape2D").disabled = true
	
	var tween = create_tween()
	tween.tween_property(b, "position", Vector2(1240, 400), 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(b, "scale", Vector2(1.8, 1.8), 1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(1.0).timeout
	_screen_shake()
	
	# İndi, collision'ı geri aç
	if is_instance_valid(b):
		b.get_node("CollisionShape2D").disabled = false
		b._landing_wave()
	
func _screen_shake() -> void:
	var camera = get_node("Camera2D")
	var original_pos = camera.offset
	var tween = create_tween()
	for i in range(8):
		tween.tween_property(camera, "offset", Vector2(randf_range(-15, 15), randf_range(-15, 15)), 0.05)
	tween.tween_property(camera, "offset", original_pos, 0.05)

func show_boss_bar(boss_node: Node2D) -> void:
	boss = boss_node
	boss_bar_canvas = CanvasLayer.new()
	boss_bar_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(boss_bar_canvas)
	
	var name_label = Label.new()
	name_label.name = "BossName"
	name_label.text = "CYBER 404"
	name_label.position = Vector2(760, 20)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_font_override("font", _font_bold)
	name_label.modulate = Color(1, 0.3, 0.3)
	boss_bar_canvas.add_child(name_label)
	
	# Zırh barı
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
	
	# Can barı
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
	health_bar.visible = false  # Başta gizli
	boss_bar_canvas.add_child(health_bar)

func update_boss_bar(armor: int, health: int, max_armor: int, max_health: int) -> void:
	if boss_bar_canvas == null:
		return
	var armor_bar = boss_bar_canvas.get_node("ArmorBar")
	var health_bar = boss_bar_canvas.get_node("HealthBar")
	
	armor_bar.size.x = 400 * (float(armor) / float(max_armor))
	
	if armor <= 0:
		armor_bar.visible = false
		health_bar.visible = true
		health_bar.size.x = 400 * (float(health) / float(max_health))

func hide_boss_bar() -> void:
	boss_defeated = true
	if boss_bar_canvas:
		boss_bar_canvas.queue_free()
		boss_bar_canvas = null
	boss = null

func _on_card_selected(index: int, _canvas: CanvasLayer, bg: ColorRect) -> void:
	selected_upgrade_index = index
	if selected_card_bg:
		selected_card_bg.color = Color(0.1, 0.1, 0.15)
	selected_card_bg = bg
	bg.color = Color(0.3, 0.3, 0.5)

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

	# ── MR. HASMEN — karakter görseli (sağ alan) ─────────────────────────
	var hasmen_img = TextureRect.new()
	hasmen_img.texture = load("res://assets/mrHasmen.png")
	hasmen_img.size = Vector2(580, 900)
	hasmen_img.position = Vector2(1310, 160)
	hasmen_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hasmen_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hasmen_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hasmen_img)

	# İsim etiketi — görselin üstünde, ortada
	var hasmen_label = Label.new()
	hasmen_label.text = "MR. HASMEN"
	hasmen_label.size = Vector2(580, 40)
	hasmen_label.position = Vector2(1310, 108)
	hasmen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hasmen_label.add_theme_font_size_override("font_size", 26)
	hasmen_label.add_theme_font_override("font", _font_bold)
	hasmen_label.add_theme_color_override("font_color", Color(1, 0.18, 0.58, 1))
	canvas.add_child(hasmen_label)

	# ── DİKEY AYRAÇ (kart alanı | Hasmen alanı) ──────────────────────────
	var divider = ColorRect.new()
	divider.color = Color(0, 0.72, 0.82, 0.32)
	divider.size = Vector2(2, 960)
	divider.position = Vector2(797, 60)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(divider)

	# ── KONUŞMA BALONU — gövde ────────────────────────────────────────────
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

	# Kuyruk — dış (cyan border, Mr. Hasmen'a doğru işaret eder)
	var tail_outer = ColorRect.new()
	tail_outer.color = Color(0, 0.92, 1, 1)
	tail_outer.size = Vector2(22, 22)
	tail_outer.position = Vector2(1270, 151)
	tail_outer.rotation_degrees = 45.0
	tail_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tail_outer)

	# Kuyruk — iç (koyu dolgu, border etkisi yaratır)
	var tail_inner = ColorRect.new()
	tail_inner.color = Color(0.05, 0.05, 0.14, 0.97)
	tail_inner.size = Vector2(16, 16)
	tail_inner.position = Vector2(1274, 155)
	tail_inner.rotation_degrees = 45.0
	tail_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tail_inner)

	# Konuşma metni (İngilizce)
	var dialog = Label.new()
	dialog.text = "Hey Vec, let me make you look good!\nPick one of these and benefit from\nthe gifts of technology !!!!!"
	dialog.size = Vector2(426, 180)
	dialog.position = Vector2(836, 78)
	dialog.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialog.add_theme_font_size_override("font_size", 18)
	dialog.add_theme_font_override("font", _font_regular)
	dialog.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 1.0))
	canvas.add_child(dialog)

	# ── KART BÖLÜMÜ BAŞLIĞI ───────────────────────────────────────────────
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
	desc1.text = "Sahaya paraşütle 'ITY RE-Processor cihazı' indirilir."
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
		
		# İniş animasyonu
		var start_y = -150
		var end_pos = processor_sprite.position
		processor_sprite.position.y = start_y
		
		var tween = create_tween()
		tween.tween_property(processor_sprite, "position:y", end_pos.y, 2.0)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _ready() -> void:
	update_ui()
	$UI/BtnPause.pressed.connect(_show_pause_menu)
	$UI/FusionEnergyBar.max_value = 50
	$UI/FusionEnergyBar.value = 0
	$UI/IntegrityBar.max_value = player_max_hp
	$UI/IntegrityBar.value = player_hp
	$UI/IntegrityBar/LabelIntegrity.text = str(player_hp) + " / " + str(player_max_hp)
			# Fusion Zone başlangıçta gizli
	var fusion_zone = get_tree().get_first_node_in_group("fusion_zone")
	if fusion_zone:
		fusion_zone.visible = false
		fusion_zone.set_physics_process(false)
	
	get_tree().paused = true
	_show_hasmen_selection()
	


func update_ui() -> void:
	$UI/LabelLevel.text = "◈  LEVEL " + str(level)
	$UI/IntegrityBar.max_value = player_max_hp
	$UI/IntegrityBar.value = player_hp
	$UI/LabelBalls.text = "⬤  BALLS   " + str($BallLauncher.balls_fired) + " / " + str($BallLauncher.total_balls)
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

	# Catch slot göstergesi
	var player = get_node("Player")
	$UI/LabelCatch.text = "✋  CATCH   " + str(player.held_balls.size()) + " / " + str(player.max_held_balls)

	# Calamity slotları
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

func zombie_died() -> void:
	zombies_killed += 1
	total_zombies_killed += 1
	update_ui()
	if zombies_killed >= kills_to_level:
		zombies_killed = 0
		kills_to_level = int(kills_to_level * 1.5)
		spawn_interval = max(spawn_interval - 0.2, min_spawn_interval)
		get_tree().paused = true
		show_upgrade_menu()

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

	# ── Hasmen görseli (sağ taraf) ────────────────────────────
	var hasmen_img = TextureRect.new()
	hasmen_img.texture      = load("res://assets/mrHasmen.png")
	hasmen_img.size         = Vector2(500, 900)
	hasmen_img.position     = Vector2(1380, 180)
	hasmen_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hasmen_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	canvas.add_child(hasmen_img)

	# Neon pembe dikey ayraç
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

	# ── Başlık ────────────────────────────────────────────────
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

	# Rapor satırları: [başlık, değer, renk]
	var minutes = int(elapsed_time / 60)
	var seconds = int(elapsed_time) % 60
	var rows = [
		["DATA HARVESTED",       _format_data(data_collected) + " units", Color(0.0, 1.0, 0.55)],
		["SESSION TIME",         "%02d:%02d" % [minutes, seconds],         Color(0.0, 0.9, 1.0)],
		["THREATS NEUTRALIZED",  str(total_zombies_killed),                 Color(0.0, 0.9, 1.0)],
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

	# ── Hasmen alıntısı ───────────────────────────────────────
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
	var tribune = get_node_or_null("Tribune")
	if tribune and tribune.has_method("update_data"):
		tribune.update_data(data_collected)

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

func show_upgrade_menu() -> void:
	upgrading = true
	
	var upgrades = [
	{"name": "Mimic Ball", "category": "Utility", "color": Color(0.5, 0.5, 1.0), "desc": "Güçlendirilmiş topu kopyalar", "index": 19},
	{"name": "Split Ball", "category": "Utility", "color": Color(0.2, 0.8, 0.2), "desc": "Top 3'e ayrılır", "index": 0},
	{"name": "Electric Ball", "category": "Utility", "color": Color(0.2, 0.5, 1.0), "desc": "Top elektrik kazanır", "index": 1},
	{"name": "Pierce Ball", "category": "Utility", "color": Color(1.0, 0.8, 0.0), "desc": "Top deşip geçer", "index": 2},
	{"name": "Cryo Ball", "category": "Utility", "color": Color(0.5, 0.8, 1.0), "desc": "Zombiyi %25 yavaşlatır", "index": 15},
	{"name": "Glitch Ball", "category": "Utility", "color": Color(0.8, 0.0, 0.8), "desc": "Zombiyi 3sn şaşırtır", "index": 16},
	{"name": "Water Ball", "category": "Utility", "color": Color(0.0, 0.5, 1.0), "desc": "Düşmanı ıslatır, tek vurumluk", "index": 17},
	{"name": "Fire Ball", "category": "Utility", "color": Color(1.0, 0.3, 0.0), "desc": "Düşmana yanma efekti uygular", "index": 18},
	{"name": "Speed Upgrade", "category": "Individuality", "color": Color(0.6, 0.2, 0.8), "desc": "Hareket hızı artar", "index": 4},
	{"name": "Catch +1", "category": "Connectivity", "color": Color(1.0, 0.5, 0.0), "desc": "Aynı anda 2 top tutarsın", "index": 5},
	{"name": "Next One", "category": "Connectivity", "color": Color(1.0, 0.5, 0.0), "desc": "Topları istediğin sırayla at", "index": 6},
	{"name": "Lightning", "category": "Calamity", "color": Color(1.0, 1.0, 0.0), "desc": "Seçilen noktaya yıldırım düşer", "index": 7},
	{"name": "Flame Zone", "category": "Calamity", "color": Color(1.0, 0.3, 0.0), "desc": "Seçilen bölgeye sürekli hasar", "index": 8},
	{"name": "Gravitational Force", "category": "Calamity", "color": Color(0.5, 0.0, 1.0), "desc": "Zombileri 5 sn çeker", "index": 9},
	{"name": "Arise", "category": "Calamity", "color": Color(0.8, 0.8, 1.0), "desc": "Düşmüş toplar harekete geçer", "index": 10},
	{"name": "Ball Mastery", "category": "Utility", "color": Color(0.2, 0.8, 0.2), "desc": "Tüm toplara +1 hasar", "index": 11},
	{"name": "Pierce Sharpness", "category": "Utility", "color": Color(1.0, 0.8, 0.0), "desc": "Pierce topuna +2 hasar", "index": 12},
	{"name": "Thunder Amp", "category": "Utility", "color": Color(0.2, 0.5, 1.0), "desc": "Electric topuna +2 hasar", "index": 13},
	{"name": "Split Amp", "category": "Utility", "color": Color(1.0, 0.2, 0.2), "desc": "Split topuna +2 hasar", "index": 14},
	{"name": "Medkit", "category": "Individuality", "color": Color(0.9, 0.1, 0.1), "desc": "+10 Can yenilersin", "index": 20},
	{"name": "Max Health Up", "category": "Individuality", "color": Color(0.8, 0.2, 0.2), "desc": "Maksimum can +5 artar", "index": 21},
	{"name": "Data Leech Ball", "category": "Utility", "color": Color(0.6, 0.0, 0.2), "desc": "Düşmana vurduğunda +2 Integrity", "index": 22, "rarity": "rare"},
]
	
	var canvas = CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	
	# ── Blur arka planı: oyun sahnesi bulanık gösterilir ─────────────────────
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
	
	upgrades.shuffle()
	var selected = upgrades.slice(0, 3)
	for i in range(selected.size()):
		var upgrade = selected[i]
		var tx = start_x + i * (card_width + 40)
		var ty = 300
		
		var bg = ColorRect.new()
		bg.size = Vector2(card_width, card_height)
		bg.color = Color(0.1, 0.1, 0.15)
		bg.position = Vector2(tx, ty)
		canvas.add_child(bg)
		
		var cat_strip = ColorRect.new()
		cat_strip.size = Vector2(card_width, 40)
		cat_strip.color = upgrade["color"]
		cat_strip.position = Vector2(tx, ty)
		canvas.add_child(cat_strip)
		
		var cat_label = Label.new()
		cat_label.text = upgrade["category"]
		cat_label.position = Vector2(tx + 10, ty + 8)
		cat_label.add_theme_font_size_override("font_size", 18)
		cat_label.add_theme_font_override("font", _font_bold)
		canvas.add_child(cat_label)

		var name_label = Label.new()
		name_label.text = upgrade["name"]
		name_label.position = Vector2(tx + 10, ty + card_height - 90)
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_font_override("font", _font_bold)
		canvas.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = upgrade["desc"]
		desc_label.position = Vector2(tx + 10, ty + card_height - 60)
		desc_label.add_theme_font_size_override("font_size", 16)
		desc_label.add_theme_font_override("font", _font_regular)
		desc_label.modulate = Color(0.8, 0.8, 0.8)
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
		
		bg.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var click_area = Button.new()
		click_area.size = Vector2(card_width, card_height)
		click_area.position = Vector2(tx, ty)
		click_area.modulate = Color(1, 1, 1, 0)
		click_area.mouse_entered.connect(func():
			if selected_card_bg != bg:
				bg.color = Color(0.2, 0.2, 0.3)
			# Kartı büyüt
			var tween = create_tween()
			tween.tween_property(bg, "scale", Vector2(1.05, 1.05), 0.1)
			tween.parallel().tween_property(bg, "position", Vector2(tx - 7, ty - 7), 0.1)
		)
		click_area.mouse_exited.connect(func():
			if selected_card_bg != bg:
				bg.color = Color(0.1, 0.1, 0.15)
			# Kartı küçült
			var tween = create_tween()
			tween.tween_property(bg, "scale", Vector2(1.0, 1.0), 0.1)
			tween.parallel().tween_property(bg, "position", Vector2(tx, ty), 0.1)
		)
		click_area.pressed.connect(_on_card_selected.bind(upgrade["index"], canvas, bg))
		canvas.add_child(click_area)

		# ── Kart giriş animasyonu: aşağıdan yukarıya, gecikimli (stagger) ───────
		var card_anim_nodes = [bg, cat_strip, cat_label, name_label, desc_label, click_area]
		var card_target_ys: Array = []
		for anim_node in card_anim_nodes:
			card_target_ys.append(anim_node.position.y)
			anim_node.position.y += 160.0
		# Sadece görsel elemanlar başlangıçta şeffaf (click_area zaten görünmez)
		for anim_node in [bg, cat_strip, cat_label, name_label, desc_label]:
			anim_node.modulate.a = 0.0

		var slide_tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		slide_tw.tween_interval(i * 0.13)
		# bg ilk adım — sonraki tüm adımlar buna paralel bağlanır
		slide_tw.tween_property(bg, "position:y", card_target_ys[0], 0.40)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		slide_tw.parallel().tween_property(bg, "modulate:a", 1.0, 0.24)
		for ci in range(1, card_anim_nodes.size()):
			var anim_node = card_anim_nodes[ci]
			slide_tw.parallel().tween_property(anim_node, "position:y", card_target_ys[ci], 0.40)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			# click_area (son eleman) için alpha tween yok — görünmez kalmalı
			if ci < card_anim_nodes.size() - 1:
				slide_tw.parallel().tween_property(anim_node, "modulate:a", 1.0, 0.24)

	# ── Glitch intro: tüm kart UI'ının üstüne bindirilir, 0.7s'de solar ────
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
	var duration = 5.0
	var elapsed = 0.0
	while elapsed < duration:
		var zombies = get_tree().get_nodes_in_group("zombies")
		for zombie in zombies:
			if zombie.global_position.distance_to(pos) < 150:
				var direction = (pos - zombie.global_position).normalized()
				zombie.global_position += direction * 60 * get_process_delta_time()
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
	# C tuşu - Calamity slotları arasında geçiş
	if event is InputEventKey and event.keycode == KEY_C and event.pressed:
		if not calamity_slots.is_empty():
			calamity_index = (calamity_index + 1) % calamity_slots.size()
			update_ui()
			
	
	# Sağ tık basılı - etki alanını göster
	# E tuşu - Calamity ateşle
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
	
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if not upgrading:
			_show_pause_menu()
			
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
	# Yakındaki zombilere hasar ver
	var zombies = get_tree().get_nodes_in_group("zombies")
	for zombie in zombies:
		if zombie.global_position.distance_to(pos) < 100:
			zombie.take_damage(3)

func _activate_flame(pos: Vector2) -> void:
	# Alanda sürekli hasar
	var flame_timer = get_tree().create_timer(0.5)
	var hits = 0
	while hits < 6:
		var zombies = get_tree().get_nodes_in_group("zombies")
		for zombie in zombies:
			if zombie.global_position.distance_to(pos) < 120:
				zombie.take_damage(1)
		hits += 1
		await flame_timer.timeout
		flame_timer = get_tree().create_timer(0.5)

func _spawn_zombie() -> void:
		
	var zombie
	var rand = randf()
	
	if level <= 2:
		zombie = zombie_scene.instantiate()
	elif level <= 4:
		if rand < 0.7:
			zombie = zombie_scene.instantiate()
		else:
			zombie = fast_zombie_scene.instantiate()
	elif level <= 6:
		if rand < 0.5:
			zombie = zombie_scene.instantiate()
		elif rand < 0.8:
			zombie = fast_zombie_scene.instantiate()
		else:
			zombie = cyber_zombie_scene.instantiate()
	else:
		var rand2 = randf()
		if rand2 < 0.2:
			zombie = zombie_scene.instantiate()
		elif rand2 < 0.4:
			zombie = fast_zombie_scene.instantiate()
		elif rand2 < 0.55:
			zombie = cyber_zombie_scene.instantiate()
		elif rand2 < 0.7:
			zombie = armored_zombie_scene.instantiate()
		elif rand2 < 0.85:
			zombie = cyber_shooter_scene.instantiate()
		elif rand2 < 0.92:
			zombie = cyber_shotgun_scene.instantiate()
		else:
			zombie = cyber_rifle_scene.instantiate()
		
	
	var rand_x = randf_range(50, 1600)
	zombie.position = Vector2(rand_x, -50)
	add_child(zombie)

func _process(_delta: float) -> void:
	
	if upgrading:
		return
	spawn_timer += _delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_zombie()
	
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
	# Boss öncesi uyarı
	if level >= 13 and boss == null and not boss_defeated:
		if not has_node("BossWarning"):
			_show_boss_warning()

func _on_upgrade_selected(index: int, canvas: CanvasLayer) -> void:
	canvas.queue_free()
	upgrading = false
	get_tree().paused = false
	level += 1
	
	if index == 0:
		next_ball_upgrade = "split"
	elif index == 1:
		next_ball_upgrade = "electric"
	elif index == 2:
		next_ball_upgrade = "pierce"
	elif index == 4:
		var player = get_node("Player")
		player.SPEED += 50
	elif index == 5:
		var player = get_node("Player")
		player.max_held_balls += 1
	elif index == 6:
		var player = get_node("Player")
		player.has_next_one = true
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
	# Ball Mastery - tüm toplara +1
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
		next_ball_upgrade = "cryo"
	elif index == 16:
		next_ball_upgrade = "glitch"
	elif index == 17:
		next_ball_upgrade = "water"
	elif index == 18:
		next_ball_upgrade = "fire"
	elif index == 19:
		var player = get_node("Player")
		player.has_mimic = true
	elif index == 20:
		player_hp = min(player_hp + 10, player_max_hp)
	elif index == 21:
		player_max_hp += 5
		player_hp = min(player_hp + 5, player_max_hp)
	elif index == 22:
		next_ball_upgrade = "leech"
	
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
