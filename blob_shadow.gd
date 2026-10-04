extends Polygon2D

# Canlılar için ayak gölgesi (oval). Sahibinin AnimatedSprite2D'sinin ilk karesinin gerçek alfa
# sınırlarından ayak hizası ve genişlik hesaplanır → her düşman/boss kendi boyutuna göre gölge alır.
# Sahibin çocuğu olduğu için onunla birlikte hareket eder ve ölçeklenir (boss 2.43× ise gölge de öyle).
# Kullanım: BlobShadow.attach(self, sprite)  — sprite_frames henüz kurulmamışsa bir kare beklenir.

const Z := 1                 # düşmanların (2-3) altında, cesetlerin (0) üstünde
const COLOR := Color(0.0, 0.0, 0.0, 0.36)
const WIDTH_FACTOR := 0.40   # gövde genişliği × bu = gölge yarıçapı (rx)
const ASPECT := 0.38         # ry / rx (izometrik düz oval)

static var _cache: Dictionary = {}   # "script|sprite_scale" → [center_x, feet_y, rx]

var _owner: Node2D
var _sprite: AnimatedSprite2D
var _width_mult := 1.0   # boss gibi büyük gövdeler için gölgeyi genişletir
var _up := 0.0           # gölgeyi sahip-yerel px kadar YUKARI (gövdenin arkasına) kaydırır

static func attach(owner: Node2D, sprite: AnimatedSprite2D, width_mult: float = 1.0, up: float = 0.0) -> void:
	if owner == null or sprite == null:
		return
	var sh = load("res://blob_shadow.gd").new()   # kendini preload etmek döngüsel referans verir
	sh._owner = owner
	sh._sprite = sprite
	sh._width_mult = width_mult
	sh._up = up
	sh.z_as_relative = false
	sh.z_index = Z
	sh.color = COLOR
	sh.name = "BlobShadow"
	owner.add_child(sh)

func _ready() -> void:
	visible = false
	await get_tree().process_frame   # sahibin _ready'si (sprite_frames kurulumu) bitsin
	if not is_instance_valid(_sprite) or _sprite.sprite_frames == null:
		queue_free()
		return
	var key := "%s|%s" % [str(_owner.get_script().resource_path), str(_sprite.scale.x)]
	var p: Array
	if _cache.has(key):
		p = _cache[key]
	else:
		p = _measure()
		_cache[key] = p
	if p.is_empty():
		queue_free()
		return
	var rx: float = float(p[2]) * _width_mult
	var ry: float = rx * ASPECT
	var pts := PackedVector2Array()
	for i in 24:
		var a := float(i) / 24.0 * TAU
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	polygon = pts
	position = Vector2(p[0], p[1] - ry * 0.35 - _up)   # gölge ayakların hemen altına/üstüne biner
	visible = true

func _measure() -> Array:
	var names := _sprite.sprite_frames.get_animation_names()
	if names.is_empty() or _sprite.sprite_frames.get_frame_count(names[0]) == 0:
		return []
	var tex: Texture2D = _sprite.sprite_frames.get_frame_texture(names[0], 0)
	if tex == null:
		return []
	var img: Image = tex.get_image()
	if img == null:
		return []
	var r: Rect2i = img.get_used_rect()
	if r.size.x <= 0:
		return []
	var sc: Vector2 = _sprite.scale
	var tw: float = float(tex.get_width())
	var th: float = float(tex.get_height())
	var cx: float = (float(r.position.x) + float(r.size.x) * 0.5 - tw * 0.5) * sc.x + _sprite.position.x
	var fy: float = (float(r.position.y + r.size.y) - th * 0.5) * sc.y + _sprite.position.y
	var rx: float = maxf(float(r.size.x) * sc.x * WIDTH_FACTOR, 8.0)
	return [cx, fy, rx]

func _process(_delta: float) -> void:
	# Sahip ölünce gölge de kaybolur (ceset gölgesiz kalır)
	if not is_instance_valid(_owner) or _owner.get("is_dead"):
		queue_free()
