extends Node2D

var anchor_pos: Vector2 = Vector2.ZERO
var target: Node2D = null

const LINK_SPACING: float = 16.0
const MAX_LINKS: int = 40

var _links: Array = []
var _textures: Dictionary = {}

const _DIR_NAMES: Array = ["east", "south-east", "south", "south-west",
							"west", "north-west", "north", "north-east"]

func _ready() -> void:
	top_level = true
	z_index = 10
	z_as_relative = false
	for d in _DIR_NAMES:
		_textures[d] = load("res://assets/chain/chainLink/%s.png" % d)
	# Başlangıçta tek halka
	_add_link()

func _add_link() -> void:
	if _links.size() >= MAX_LINKS:
		return
	var lnk := Sprite2D.new()
	lnk.z_index = 10
	lnk.z_as_relative = false
	lnk.scale = Vector2(0.45, 0.45)
	lnk.modulate = Color(0.55, 0.55, 0.6, 1.0)
	lnk.visible = false
	add_child(lnk)
	_links.append(lnk)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target) or not target.get("is_slowed") or not target.is_slowed:
		queue_free()
		return

	var enemy_pos: Vector2 = target.global_position
	var diff: Vector2 = enemy_pos - anchor_pos
	var dist: float = diff.length()
	var needed: int = max(1, int(dist / LINK_SPACING))
	needed = min(needed, MAX_LINKS)

	# Gerektiği kadar halka ekle
	while _links.size() < needed:
		_add_link()

	var dir_vec: Vector2 = diff.normalized() if dist > 0.1 else Vector2.RIGHT
	var dir_name: String = _angle_to_dir(dir_vec.angle())

	# Halkalar anchor'dan düşmana doğru eşit aralıklı
	for i in range(_links.size()):
		if i < needed:
			var t: float = float(i) / float(max(needed - 1, 1))
			_links[i].global_position = anchor_pos.lerp(enemy_pos, t)
			_links[i].texture = _textures[dir_name]
			_links[i].visible = true
		else:
			_links[i].visible = false

func _angle_to_dir(angle: float) -> String:
	var deg: float = fmod(rad_to_deg(angle) + 360.0, 360.0)
	var sector: int = int((deg + 22.5) / 45.0) % 8
	return _DIR_NAMES[sector]
