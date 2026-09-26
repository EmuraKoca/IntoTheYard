extends Node
# Global SFX yöneticisi (autoload "Sfx"). Kullanım: Sfx.play("hover")
# Tüm Button'lara otomatik hover/click sesi bağlar. Butona özel ses için:
#   btn.set_meta("sfx_click", "confirmClick")   # başka ses
#   btn.set_meta("sfx_click", "")               # click sesi yok
#   btn.set_meta("sfx_hover", "")               # hover sesi yok

const DIR := "res://assets/sfx/ui/"
const VOLUME := {"hover": -8.0}
const POOL_SIZE := 8

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)
	get_tree().node_added.connect(_on_node_added)

func play(sound: String) -> void:
	if sound == "":
		return
	if not _cache.has(sound):
		var path := DIR + sound + ".ogg"
		_cache[sound] = load(path) if ResourceLoader.exists(path) else null
	var stream: AudioStream = _cache[sound]
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"   # SFX bus'ı ana menüde çalışırken oluşturulur
	p.stream = stream
	p.volume_db = VOLUME.get(sound, 0.0)
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
