extends Node
# Global SFX yöneticisi (autoload "Sfx"). Kullanım: Sfx.play("hover")
# Tüm Button'lara otomatik hover/click sesi bağlar. Butona özel ses için:
#   btn.set_meta("sfx_click", "confirmClick")   # başka ses
#   btn.set_meta("sfx_click", "")               # click sesi yok
#   btn.set_meta("sfx_hover", "")               # hover sesi yok
#
# İki ayrı bus: "SFX" (UI — hover/click, hiçbir zaman susturulmaz) ve "GameplaySFX"
# (calamity/ölüm gibi oyun-içi tek seferlik sesler, `play_path()`) — "GameplaySFX"
# "SFX"e "send" ediliyor, yani ayarlardaki SFX sürgüsünü hâlâ takip ediyor ama level-up/
# iskarta ekranı gibi duraklama menülerinde `set_gameplay_muted(true)` ile ayrıca
# susturulabiliyor, UI tıklama sesleri bundan etkilenmiyor.

const DIR := "res://assets/sfx/ui/"
const VOLUME := {"hover": -8.0}
const POOL_SIZE := 8

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _gameplay_bus_linked: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_gameplay_bus()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)
	get_tree().node_added.connect(_on_node_added)

func _ensure_gameplay_bus() -> void:
	if AudioServer.get_bus_index("GameplaySFX") >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(idx, "GameplaySFX")
	# "SFX" bus'ı henüz yoksa (ana menüden geçilmediyse) Master'a gönder, SFX oluşunca
	# bir sonraki play_path çağrısında zaten doğru bus'a yönleniyor olacak — bus send'i
	# burada sabitlemiyoruz, her _route_gameplay_bus() çağrısında güncel tutuluyor.
	AudioServer.set_bus_send(idx, "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master")

func play(sound: String) -> void:
	if sound == "":
		return
	if not _cache.has(sound):
		var path := DIR + sound + ".ogg"
		_cache[sound] = load(path) if ResourceLoader.exists(path) else null
	_play_stream(_cache[sound], VOLUME.get(sound, 0.0), 1.0, "SFX")

# UI klasörü dışındaki tam yoldan tek seferlik ses (örn. "res://assets/sfx/characters/death.ogg")
# pitch_scale < 1.0 sesi yavaşlatıp fiziksel olarak uzatır (dosyaya dokunmadan) — kısa kalan
# seslerde (örn. Gravitational Force) kullanılabilir. "GameplaySFX" bus'ında çalar —
# level-up/iskarta ekranında `set_gameplay_muted(true)` ile susturulabilir.
func play_path(path: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	if not _gameplay_bus_linked:
		_route_gameplay_bus()
	_play_stream(_cache[path], volume_db, pitch_scale, "GameplaySFX")

# Bir sesi henüz ÇALMADAN önbelleğe yükler — ilk kez `play_path()` ile çağrılan bir ses
# `load()`'u o anda senkron yapar, bu da tam bir frame'e kilitlenmesi gereken bir tetikleme
# (örn. Boss Crate'in kırılma sesi) için küçük bir hitch'e/gecikmeye sebep olabilir. Zamanı
# kritik olmayan bir noktada (örn. birkaç saniye önceden) bunu çağırmak o riski ortadan kaldırır.
func preload_sound(path: String) -> void:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null

# BUG FIX (2026-09-29): eskiden play_path() HER çağrıda set_bus_send() ile "GameplaySFX"
# bus'ının hedefini yeniden ayarlıyordu — Godot bunu bus'ı yeniden bağlama gibi işleyip
# o an o bus'ta çalmakta olan başka bir sesi (örn. Thunderstorm'un fon sesi, ilk Lightning
# çarpması aynı bus'a başka bir play_path() çağrısı yapınca) kesiyordu. Artık sadece "SFX"
# bus'ı bulunup gerçekten bağlanana kadar (genelde ana menüde bir kez) çağrılıyor, ondan
# sonra hiç dokunulmuyor.
func _route_gameplay_bus() -> void:
	var idx := AudioServer.get_bus_index("GameplaySFX")
	if idx >= 0 and AudioServer.get_bus_index("SFX") >= 0:
		AudioServer.set_bus_send(idx, "SFX")
		_gameplay_bus_linked = true

# Level-up/iskarta gibi duraklama menüleri açılınca/kapanınca çağrılır — sadece oyun-içi
# tek seferlik sesleri (calamity, ölüm) susturur, UI hover/click sesleri etkilenmez.
func set_gameplay_muted(muted: bool) -> void:
	var idx := AudioServer.get_bus_index("GameplaySFX")
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)

func _play_stream(stream: AudioStream, volume_db: float, pitch_scale: float = 1.0, bus: String = "SFX") -> void:
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Master"
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.play()

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.mouse_entered.connect(_on_hover.bind(node))
		node.pressed.connect(_on_pressed.bind(node))

func _on_hover(b: BaseButton) -> void:
	if b.disabled:
		return
	play(b.get_meta("sfx_hover", "hover"))

func _on_pressed(b: BaseButton) -> void:
	if b.has_meta("sfx_click"):
		play(b.get_meta("sfx_click"))
		return
	play("backQuitCancel" if _is_back_color(b) else "menuClick")

# Pembe (Quit/Geri) ve kırmızı (Kapat) butonlar = geri/iptal sesi
func _is_back_color(b: BaseButton) -> bool:
	if not b.has_theme_color_override("font_color"):
		return false
	var c: Color = b.get_theme_color("font_color")
	return (absf(c.r - 1.0) < 0.05 and absf(c.g - 0.18) < 0.05 and absf(c.b - 0.58) < 0.05) \
		or (absf(c.r - 0.8) < 0.05 and absf(c.g - 0.2) < 0.05 and absf(c.b - 0.2) < 0.05)
