extends CharacterBody2D

var armor = 90
var health = 45
var max_armor = 90
var max_health = 45
var is_dead = false
var is_frozen = false
var is_slowed = false
var is_glitched = false
var is_wet = false
var is_burning = false
var is_stunned = false
var original_speed = 120.0
var speed = 120.0
var keep_distance = 500.0
var chain_anchor = Vector2(995, 560)   # yeni (genişletilmiş) oyun alanının merkezi (x:360-1630)
var chain_length = 450.0
var ring_timer = 0.0
var missile_timer = 0.0
var shockwave_timer = 0.0
var random_weapon_timer = 0.0
var is_electrified = false

var bullet_scene = preload("res://bullet.tscn")
var missile_scene = preload("res://missile.tscn")

func _ready() -> void:
	z_index = 3
	add_to_group("subjects")
	scale = Vector2(0.1, 0.1)
	_setup_sprite()
	_setup_armor_look()
	_start_theme()
	await get_tree().process_frame
	var game = get_parent()
	if game.has_method("show_boss_bar"):
		game.show_boss_bar(self)

const THEME_PATH := "res://assets/sfx/bosses/cyber404/cyber404inthefield.ogg"
var _theme_player: AudioStreamPlayer = null

# Boss kutudan çıktığı an (_ready, add_child ile tetiklenir) başlar, ölene kadar döngüde çalar.
func _start_theme() -> void:
	if not ResourceLoader.exists(THEME_PATH):
		return
	var stream: AudioStream = load(THEME_PATH)
	if "loop" in stream:
		stream.loop = true
	_theme_player = AudioStreamPlayer.new()
	_theme_player.stream = stream
	_theme_player.bus = "GameplaySFX" if AudioServer.get_bus_index("GameplaySFX") >= 0 else "Master"
	_theme_player.volume_db = linear_to_db(0.455)  # 0.65 × 0.7 (önce %35, sonra üstüne %30 kısıldı)
	add_child(_theme_player)
	_theme_player.play()

func _stop_theme() -> void:
	if not is_instance_valid(_theme_player):
		return
	var tw := create_tween()
	tw.tween_property(_theme_player, "volume_db", -40.0, 1.5)
	tw.tween_callback(_theme_player.stop)

func _setup_sprite() -> void:
	var sprite: AnimatedSprite2D = $Boss404Sprite
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	# Walk animasyonu (tek tek frame'ler — kullanıcı bu klasörde düzenliyor)
	var walk_base := "res://assets/enemys/cyber404/animations/animation-3e031936/south/"
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 8.0)
	frames.set_animation_loop("walk", true)
	var wi := 0
	while ResourceLoader.exists(walk_base + "frame_%03d.png" % wi):
		frames.add_frame("walk", load(walk_base + "frame_%03d.png" % wi))
		wi += 1

	# Death animasyonu (tek tek frame'ler)
	var death_base := "res://assets/enemys/cyber404/animations/death/"
	frames.add_animation("death")
	frames.set_animation_speed("death", 5.0)
	frames.set_animation_loop("death", false)
	for i in range(9):
		var t: Texture2D = load(death_base + "frame_%03d.png" % i)
		frames.add_frame("death", t)

	# Halka saldırısı: kare 0-2 hazırlık, 3-24 ateş (RING_WINDUP_FRAMES)
	var ring_base := "res://assets/enemys/cyber404/animations/ringAttack/"
	frames.add_animation("ringAttack")
	frames.set_animation_speed("ringAttack", RING_FPS)
	frames.set_animation_loop("ringAttack", false)
	var ring_i := 0
	while ResourceLoader.exists(ring_base + "frame_%03d.png" % ring_i):
		frames.add_frame("ringAttack", load(ring_base + "frame_%03d.png" % ring_i))
		ring_i += 1

	# Füze fırlatma: 4 kare (0 hazır, 1 şarj, 2 parlama = fırlatma anı, 3 toparlanma)
	var lm_base := "res://assets/enemys/cyber404/animations/launchMissile/"
	frames.add_animation("launchMissile")
	frames.set_animation_speed("launchMissile", MISSILE_ANIM_FPS)
	frames.set_animation_loop("launchMissile", false)
	var lm_i := 0
	while ResourceLoader.exists(lm_base + "frame_%03d.png" % lm_i):
		frames.add_frame("launchMissile", load(lm_base + "frame_%03d.png" % lm_i))
		lm_i += 1

	# Rastgele atış: 7 kare (0 namlu kıvılcımı, 1 büyük parlama = ateş anı, 2-3 toparlanma, 4-6 ikinci tur)
	var rs_base := "res://assets/enemys/cyber404/animations/randomShot/"
	frames.add_animation("randomShot")
	frames.set_animation_speed("randomShot", RANDOM_SHOT_FPS)
	frames.set_animation_loop("randomShot", false)
	var rs_i := 0
	while ResourceLoader.exists(rs_base + "frame_%03d.png" % rs_i):
		frames.add_frame("randomShot", load(rs_base + "frame_%03d.png" % rs_i))
		rs_i += 1

	# Shockwave (13 kare): 0-2 hazırlık, 3-11 elektrik döngüsü, 12 toparlanma
	var sw_base := "res://assets/enemys/cyber404/animations/shockwave/"
	var sw_tex: Array = []
	var sw_i := 0
	while ResourceLoader.exists(sw_base + "frame_%03d.png" % sw_i):
		sw_tex.append(load(sw_base + "frame_%03d.png" % sw_i))
		sw_i += 1
	if sw_tex.size() >= 3:
		var wind_end: int = mini(SHOCK_WIND_FRAMES, sw_tex.size() - 1)
		var loop_end: int = maxi(wind_end + 1, sw_tex.size() - 1)   # son kare toparlanma
		frames.add_animation("shockwaveWind")
		frames.set_animation_speed("shockwaveWind", SHOCK_WIND_FPS)
		frames.set_animation_loop("shockwaveWind", false)
		for k in range(0, wind_end):
			frames.add_frame("shockwaveWind", sw_tex[k])
		frames.add_animation("shockwaveLoop")
		frames.set_animation_speed("shockwaveLoop", 14.0)
		frames.set_animation_loop("shockwaveLoop", true)
		for k in range(wind_end, loop_end):
			frames.add_frame("shockwaveLoop", sw_tex[k])
		frames.add_animation("shockwaveEnd")
		frames.set_animation_speed("shockwaveEnd", 8.0)
		frames.set_animation_loop("shockwaveEnd", false)
		for k in range(loop_end, sw_tex.size()):
			frames.add_frame("shockwaveEnd", sw_tex[k])

	# Sersemlemiş (zırh kırılınca, 37 kare): süre = ARMOR_STUN_TIME, döngülü
	var st_base := "res://assets/enemys/cyber404/animations/stunned/"
	var st_n := 0
	frames.add_animation("stunned")
	frames.set_animation_loop("stunned", true)
	while ResourceLoader.exists(st_base + "frame_%03d.png" % st_n):
		frames.add_frame("stunned", load(st_base + "frame_%03d.png" % st_n))
		st_n += 1
	frames.set_animation_speed("stunned", maxf(float(st_n), 1.0) / ARMOR_STUN_TIME)

	sprite.sprite_frames  = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale          = Vector2(0.7, 0.7)
	sprite.play("walk")

func _physics_process(delta: float) -> void:
	if is_frozen or is_stunned or is_dead:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > keep_distance:
		var diff = player.global_position - global_position
		if abs(diff.x) > abs(diff.y):
			velocity = Vector2(sign(diff.x) * speed, 0)
		else:
			velocity = Vector2(0, sign(diff.y) * speed)
	elif dist < keep_distance - 50:
		var diff = global_position - player.global_position
		if abs(diff.x) > abs(diff.y):
			velocity = Vector2(sign(diff.x) * speed, 0)
		else:
			velocity = Vector2(0, sign(diff.y) * speed)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Chain constraint
	var dist_to_anchor = global_position.distance_to(chain_anchor)
	if dist_to_anchor > chain_length:
		var dir_to_anchor = (chain_anchor - global_position).normalized()
		global_position = chain_anchor - dir_to_anchor * chain_length

	ring_timer += delta
	missile_timer += delta
	shockwave_timer += delta
	random_weapon_timer += delta

	# Saldırılar çakışmaz: aynı anda tek saldırı. Birden fazlası hazırsa öncelik sırası
	# shockwave > füze > ring > rastgele atış; hazır olup bekleyen saldırının sayacı sıfırlanmaz,
	# boss serbest kalınca (+ATTACK_GAP) sıradaki başlar.
	if _attacking:
		return
	if shockwave_timer >= 30.0 and armor > 0:
		shockwave_timer = 0.0
		_run_attack(_shockwave)
	elif missile_timer >= 15.0:
		missile_timer = 0.0
		_run_attack(_launch_missile.bind(player))
	elif ring_timer >= 9.0:
		ring_timer = 0.0
		_run_attack(_ring_attack.bind(player))
	elif random_weapon_timer >= _random_next:
		random_weapon_timer = 0.0
		_random_next = randf_range(4.0, 8.0)
		_run_attack(_random_weapon.bind(player))

const ATTACK_GAP := 0.6   # bir saldırı bitince sonrakine kadar bekleme (animasyon toparlanması)
var _attacking := false
var _random_next := randf_range(4.0, 8.0)

func _run_attack(fn: Callable) -> void:
	_attacking = true
	await fn.call()
	await get_tree().create_timer(ATTACK_GAP, false).timeout
	_attacking = false

const SFX_DIR := "res://assets/sfx/bosses/cyber404/"
const SFX_MACHINEGUN := SFX_DIR + "machineGun.ogg"   # ring attack + sıralı smg serisi
const SFX_SHOTGUN    := SFX_DIR + "shotgun.ogg"      # 7'li saçma
const SFX_SINGLESHOT := SFX_DIR + "singleShot.ogg"   # tek smg
const SFX_STUNNED      := SFX_DIR + "stunned.ogg"             # zırh kırıldığı an (0.87sn)
const ELEC_EARLY := 0.6   # stunnedElectrified, sersemleme bitmeden bu kadar önce kısılmaya başlar (büyük = daha erken biter)
const SFX_STUNNED_ELEC := SFX_DIR + "stunnedElectrified.ogg"  # hemen ardından, sersemleme bitene kadar (3.94sn, fade ile kesilir)

const RING_FPS := 14.0
# ring animasyonu: 25 kare @14fps, 3 kare hazırlık sonrası ses başlar → ateş kısmı ≈1.57sn; ses ~1.5sn (kuyruk dahil)
const RING_SFX_PITCH := 0.95
const RING_WINDUP_FRAMES := 3

# Her yana mermi (8 yön × 3'lü saçma × 5 dalga) — ringAttack animasyonu eşliğinde.
func _ring_attack(_player: Node2D) -> void:
	var my_id := _attack_id
	var spr: AnimatedSprite2D = $Boss404Sprite
	if spr.sprite_frames.has_animation("ringAttack"):
		spr.play("ringAttack")
		spr.animation_finished.connect(func():
			if not is_dead:
				spr.play("walk"), CONNECT_ONE_SHOT)
		await get_tree().create_timer(RING_WINDUP_FRAMES / RING_FPS, false).timeout
	if is_dead or my_id != _attack_id: return
	_gun_snd = Sfx.play_path_dedicated(SFX_MACHINEGUN, 0.0, RING_SFX_PITCH)   # animasyonun ateş kısmıyla (~1.57sn) bitsin
	for burst in range(5):
		if is_dead or my_id != _attack_id: return
		for i in range(8):
			var angle = i * TAU / 8
			var base_dir = Vector2(cos(angle), sin(angle))
			for j in range(3):
				var bullet = bullet_scene.instantiate()
				bullet.global_position = global_position
				bullet.bullet_type = "shotgun"
				var spread = deg_to_rad(-10 + j * 10)
				get_parent().add_child(bullet)
				bullet.launch(base_dir.rotated(spread))
		await get_tree().create_timer(0.3, false).timeout

const MISSILE_ANIM_FPS := 8.0
const MISSILE_FIRE_FRAME := 2   # parlama karesi — füze tam bu anda çıkar

func _launch_missile(player: Node2D) -> void:
	var my_id := _attack_id
	var spr: AnimatedSprite2D = $Boss404Sprite
	if spr.sprite_frames.has_animation("launchMissile"):
		spr.play("launchMissile")
		spr.animation_finished.connect(func():
			if not is_dead:
				spr.play("walk"), CONNECT_ONE_SHOT)
		await get_tree().create_timer(MISSILE_FIRE_FRAME / MISSILE_ANIM_FPS, false).timeout
		if is_dead or my_id != _attack_id or not is_instance_valid(player):
			return
	var missile = missile_scene.instantiate()
	missile.global_position = global_position
	missile.target = player
	get_parent().add_child(missile)

const RANDOM_SHOT_FPS := 12.0
const RANDOM_SHOT_FIRE_FRAME := 1   # büyük parlama karesi — mermiler tam bu anda çıkar
const SERIES_SHOT_INTERVAL := 0.15  # sıralı smg serisi: mermi aralığı = animasyonun bir tur süresi
const SHOCK_WIND_FRAMES := 3
const SHOCK_WIND_FPS := 8.0

# Animasyon yoksa (dosya eksikse) sessizce yürüme karesinde donar.
func _play_if_exists(anim: String) -> bool:
	var spr: AnimatedSprite2D = $Boss404Sprite
	if spr.sprite_frames.has_animation(anim) and spr.sprite_frames.get_frame_count(anim) > 0:
		spr.play(anim)
		return true
	return false

func _to_walk() -> void:
	if is_dead: return
	var spr: AnimatedSprite2D = $Boss404Sprite
	spr.play("walk")

# Shockwave: hazırlık → elektrik döngüsü (3 dalga bu sırada) → toparlanma. Dalga zamanlaması aynı (1.5sn arayla).
func _shockwave() -> void:
	var my_id := _attack_id
	is_stunned = true
	var has_anim := _play_if_exists("shockwaveWind")
	if not has_anim:
		$Boss404Sprite.pause()
	else:
		await get_tree().create_timer(float(SHOCK_WIND_FRAMES) / SHOCK_WIND_FPS, false).timeout
		if is_dead or my_id != _attack_id: return
		_play_if_exists("shockwaveLoop")
	var wait_left := 1.5 - (float(SHOCK_WIND_FRAMES) / SHOCK_WIND_FPS if has_anim else 0.0)
	for i in range(3):
		await get_tree().create_timer(wait_left, false).timeout
		wait_left = 1.5
		if is_dead or my_id != _attack_id:
			return
		var game = get_parent()
		if game.has_method("boss_shockwave"):
			game.boss_shockwave(global_position, 300.0 + i * 150.0)
	if has_anim and _play_if_exists("shockwaveEnd"):
		await get_tree().create_timer(0.3, false).timeout
		if is_dead or my_id != _attack_id: return
	is_stunned = false
	_to_walk()

func _random_weapon(player: Node2D) -> void:
	var my_id := _attack_id
	var spr: AnimatedSprite2D = $Boss404Sprite
	var has_anim: bool = spr.sprite_frames.has_animation("randomShot")
	var choice := randi() % 3
	if choice == 2:
		await _random_series(player, spr, has_anim)
		return
	if has_anim:
		spr.speed_scale = 1.0
		spr.play("randomShot")
		spr.animation_finished.connect(func():
			if not is_dead:
				spr.play("walk"), CONNECT_ONE_SHOT)
		await get_tree().create_timer(RANDOM_SHOT_FIRE_FRAME / RANDOM_SHOT_FPS, false).timeout
	if is_dead or my_id != _attack_id or not is_instance_valid(player):
		return
	if choice == 0:
		Sfx.play_path(SFX_SINGLESHOT)
		_fire_from_hands(player, "smg", [0.0])
	else:
		Sfx.play_path(SFX_SHOTGUN)
		_fire_from_hands(player, "shotgun", [-12.0, 0.0, 12.0])

# randomShot karesindeki iki silahın namlu noktaları (252×252 karede sol ≈(94,133), sağ ≈(160,133);
# merkez 126,126). Dünya konumu sprite'ın gerçek ölçeğinden hesaplanır (boss ölçeği değişirse uyar).
const MUZZLE_OFFSETS := [Vector2(-32.0, 7.0), Vector2(34.0, 7.0)]

func _muzzle_positions() -> Array:
	var spr: AnimatedSprite2D = $Boss404Sprite
	var out := []
	for o in MUZZLE_OFFSETS:
		out.append(spr.global_position + o * spr.global_scale)
	return out

# Her iki eldeki silahtan, oyuncuya doğru; spread_degs her elden çıkan mermilerin açı sapmaları (huni).
func _fire_from_hands(player: Node2D, btype: String, spread_degs: Array) -> void:
	for m in _muzzle_positions():
		var dir: Vector2 = (player.global_position - m).normalized()
		for deg in spread_degs:
			var bullet = bullet_scene.instantiate()
			bullet.global_position = m
			bullet.bullet_type = btype
			get_parent().add_child(bullet)
			bullet.launch(dir.rotated(deg_to_rad(deg)))

# 5'li sıralı smg: randomShot animasyonu her mermide baştan oynar (bir tur = SERIES_SHOT_INTERVAL),
# machineGun sesi seri bitince kısa bir fade ile susar (ses 1.5sn, seri 0.75sn).
func _random_series(player: Node2D, spr: AnimatedSprite2D, has_anim: bool) -> void:
	var my_id := _attack_id
	var frame_count: int = spr.sprite_frames.get_frame_count("randomShot") if has_anim else 1
	var fire_t: float = SERIES_SHOT_INTERVAL * float(RANDOM_SHOT_FIRE_FRAME) / float(maxi(frame_count, 1))
	var snd := Sfx.play_path_dedicated(SFX_MACHINEGUN)
	_gun_snd = snd
	for i in range(5):
		if is_dead or my_id != _attack_id or not is_instance_valid(player):
			break
		if has_anim:
			spr.speed_scale = (float(frame_count) / RANDOM_SHOT_FPS) / SERIES_SHOT_INTERVAL
			spr.play("randomShot")
		await get_tree().create_timer(fire_t, false).timeout
		if is_dead or my_id != _attack_id or not is_instance_valid(player):
			break
		_fire_from_hands(player, "smg", [0.0])
		await get_tree().create_timer(SERIES_SHOT_INTERVAL - fire_t, false).timeout
	if is_instance_valid(snd):
		var tw := snd.create_tween()
		tw.tween_property(snd, "volume_db", -40.0, 0.12)
		tw.tween_callback(snd.stop)
	if my_id != _attack_id:
		return   # zırh kırılması araya girdi — animasyon/hız sıfırlamasını _armor_break halletti
	if has_anim:
		spr.speed_scale = 1.0
		if not is_dead:
			spr.play("walk")

func take_damage(amount, from_ally: bool = false, kill_cause: String = "normal", physical: bool = false) -> void:
	if physical: _physical_flash()
	if armor > 0:
		armor -= amount
		if armor <= 0:
			armor = 0
			_armor_break()
	else:
		health -= amount
		if health <= 0:
			die()
	var game = get_parent()
	if game.has_method("update_boss_bar"):
		game.update_boss_bar(armor, health, max_armor, max_health)

# ── Zırh görünümü ───────────────────────────────────────────────────────────────
# Zırh varken sprite hafif çelik-mavi/parlak (metalik), zırh kırılınca solgun gri tonlara geçer
# + parçalar dökülür. Sprite'ın kendi shader'ı: kökün modulate'ini kullanan vuruş flaşıyla çakışmaz.
const ARMOR_SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
uniform float saturation : hint_range(0.0, 1.5) = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(vec3(l), c.rgb, saturation) * tint.rgb;
	COLOR = c;
}
"""
const ARMOR_ON_TINT   := Color(0.58, 0.64, 0.74)   # zırhlı: koyu, metal kaplı hissi (soğuk çelik)
const ARMOR_STUN_TIME := 3.0   # zırh kırılınca sersemleme süresi (durum kutusu da bunu kullanır)
const ARMOR_ON_SAT    := 0.65
const ARMOR_OFF_TINT  := Color(1.0, 1.0, 1.0)       # zırh kırık: sprite'ın orijinal rengi
const ARMOR_OFF_SAT   := 1.0
var _armor_mat: ShaderMaterial

func _setup_armor_look() -> void:
	var sh := Shader.new()
	sh.code = ARMOR_SHADER
	_armor_mat = ShaderMaterial.new()
	_armor_mat.shader = sh
	var spr: AnimatedSprite2D = $Boss404Sprite
	spr.material = _armor_mat
	_set_armor_look(armor > 0)

func _set_armor_look(armored: bool) -> void:
	if _armor_mat == null: return
	_armor_mat.set_shader_parameter("tint", ARMOR_ON_TINT if armored else ARMOR_OFF_TINT)
	_armor_mat.set_shader_parameter("saturation", ARMOR_ON_SAT if armored else ARMOR_OFF_SAT)

# Zırh kırılınca devam eden TÜM saldırılar iptal olur: her saldırı başında kimliğini (_attack_id) alır,
# her await'ten sonra kontrol eder; burada kimlik değişince yeni mermi/füze/dalga çıkmaz. Taramalı sesi kesilir.
var _attack_id := 0
var _gun_snd: AudioStreamPlayer = null

func _interrupt_attacks() -> void:
	_attack_id += 1
	if is_instance_valid(_gun_snd):
		var g := _gun_snd
		_gun_snd = null
		var tw := g.create_tween()
		tw.tween_property(g, "volume_db", -40.0, 0.06)
		tw.tween_callback(g.stop)
	$Boss404Sprite.speed_scale = 1.0

func _armor_break() -> void:
	_interrupt_attacks()
	is_stunned = true
	if not _play_if_exists("stunned"):
		$Boss404Sprite.pause()
	_armor_break_fx()
	var gm = get_parent()
	if gm and gm.has_method("show_boss_status"):
		gm.show_boss_status("stun", "res://assets/elemIndicators/stun.png", ARMOR_STUN_TIME,
			Lang.t("boss_stun_title"), Lang.t("boss_stun_desc"))
	# Sesler: kırılma anı "stunned", hemen ardından arızalı kısım "stunnedElectrified" (sersemleme bitene kadar)
	Sfx.play_path_dedicated(SFX_STUNNED)
	var t_first: float = (load(SFX_STUNNED) as AudioStream).get_length() if ResourceLoader.exists(SFX_STUNNED) else 0.0
	await get_tree().create_timer(minf(t_first, ARMOR_STUN_TIME), false).timeout
	var loop_snd: AudioStreamPlayer = null
	if not is_dead and is_stunned:
		loop_snd = Sfx.play_path_dedicated(SFX_STUNNED_ELEC)
	# Arızalı ses sersemlemenin bitişinden ELEC_EARLY sn ÖNCE fade ile kapanmaya başlar
	await get_tree().create_timer(maxf(ARMOR_STUN_TIME - t_first - ELEC_EARLY, 0.0), false).timeout
	if is_instance_valid(loop_snd):
		var ftw := loop_snd.create_tween()
		ftw.tween_property(loop_snd, "volume_db", -40.0, ELEC_EARLY * 0.8)
		ftw.tween_callback(loop_snd.stop)
	await get_tree().create_timer(ELEC_EARLY, false).timeout
	if is_dead: return
	is_stunned = false
	_to_walk()

# Zırh kırılma efekti: beyaz parlama → soluk gri tona geçiş + dökülen metal parçaları.
func _armor_break_fx() -> void:
	if _armor_mat != null:
		_armor_mat.set_shader_parameter("tint", Color(2.2, 2.2, 2.4))
		_armor_mat.set_shader_parameter("saturation", 0.8)
		var tw := create_tween()
		tw.tween_method(func(t: float):
			_armor_mat.set_shader_parameter("tint", Color(2.2, 2.2, 2.4).lerp(ARMOR_OFF_TINT, t))
			_armor_mat.set_shader_parameter("saturation", lerpf(0.8, ARMOR_OFF_SAT, t)),
			0.0, 1.0, 0.45)
	_spawn_armor_debris()
	var game = get_parent()
	if game and game.has_method("_screen_shake_strong"):
		game._screen_shake_strong()   # ±8px, ~0.4sn azalan genlik (eskisi ±3px'ti, fark edilmiyordu)
	elif game and game.has_method("screen_shake_heavy"):
		game.screen_shake_heavy()

func _spawn_armor_debris() -> void:
	var game = get_parent()
	if game == null: return
	var p := CPUParticles2D.new()
	p.global_position = global_position   # kök ölçeğini miras almasın diye boss'un değil sahnenin çocuğu
	p.z_index = 4
	p.one_shot = true
	p.emitting = false
	p.amount = 34
	p.lifetime = 1.3
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 150.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 280.0
	p.gravity = Vector2(0, 520)
	p.angular_velocity_min = -300.0
	p.angular_velocity_max = 300.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 60.0
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.75, 0.78, 0.85, 1.0), Color(0.42, 0.44, 0.48, 1.0), Color(0.25, 0.26, 0.28, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	p.color_ramp = grad
	game.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

func die() -> void:
	is_dead = true
	set_physics_process(false)
	_stop_theme()
	$CollisionShape2D.set_deferred("disabled", true)
	var game = get_parent()
	if game.has_method("subject_died"):
		game.subject_died()
	if game.has_method("hide_boss_bar"):
		game.hide_boss_bar()
	_play_death()

func _play_death() -> void:
	var sprite: AnimatedSprite2D = $Boss404Sprite
	sprite.play("death")
	# Animasyon bitince son frame'de 1.5s bekle, sonra yok ol
	await sprite.animation_finished
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(self):
		queue_free()

func apply_slow(amount, duration: float = 3.0) -> void:
	if is_slowed:
		return
	is_slowed = true
	original_speed = speed
	speed = speed * (1.0 - amount)
	await get_tree().create_timer(duration).timeout
	speed = original_speed
	is_slowed = false

func apply_frozen() -> void:
	# Boss is immune to freeze
	return

func apply_wet() -> void:
	is_wet = true
	await get_tree().create_timer(5.0).timeout
	is_wet = false

func apply_glitch() -> void:
	# Boss is immune to glitch
	return

func apply_electrified() -> void:
	if is_electrified:
		return
	is_electrified = true
	var game := get_parent()
	if game.has_method("update_boss_element"):
		game.update_boss_element("electrified")
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(self):
		is_electrified = false
		if game.has_method("clear_boss_element"):
			game.clear_boss_element()

func apply_burn() -> void:
	if is_burning:
		return
	is_burning = true
	for i in range(3):
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self) and health > 0:
			health -= 2
			if health <= 0:
				die()
				return
	is_burning = false

func _physical_flash() -> void:
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	await get_tree().create_timer(0.08, false).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1, 1)
