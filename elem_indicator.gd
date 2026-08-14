extends Node2D

var current_element: String = ""

var _sprite: Sprite2D = null

const _TEXTURES: Dictionary = {
	"burn":        "res://assets/elemIndicators/burn.png",
	"frozen":      "res://assets/elemIndicators/frozen.png",
	"wet":         "res://assets/elemIndicators/wet.png",
	"glitch":      "res://assets/elemIndicators/glitch.png",
	"electrified": "res://assets/elemIndicators/electrified.png",
	"slow":        "res://assets/elemIndicators/slow.png",
	"virus":       "res://assets/elemIndicators/virus.png",
	"decay":       "res://assets/elemIndicators/decay.png",
}

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.visible = false
	add_child(_sprite)

func set_element(elem: String) -> void:
	if current_element == elem:
		return
	current_element = elem
	if _TEXTURES.has(elem):
		_sprite.texture = load(_TEXTURES[elem])
		_sprite.visible = true
		visible = true
	else:
		_sprite.visible = false

func clear_element() -> void:
	current_element = ""
	_sprite.visible = false
	visible = false
