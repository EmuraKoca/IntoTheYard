## iso_effect.gd
## Sadece görsel izometrik açı — collision, UI ve mekanik dokunulmaz.
## Kapatmak için: enabled = false  (veya Godot editöründen Inspector'dan)
extends Node

@export var enabled: bool = true

## Hades benzeri ~30-45° izometrik görünüm parametreleri
## Y ekseni sıkıştırma: 0.5 = tam izometrik, 0.65 = hafif, 1.0 = normal
@export var y_scale: float  = 0.60
## Yatay kaydırma (eğim): 0.0 = sadece sıkıştır, 0.15-0.25 = Hades hissi
@export var shear_x: float  = 0.18

func _ready() -> void:
	# Camera2D process_priority = 0 (varsayılan), biz ondan sonra çalışalım
	process_priority = 100

func _process(_delta: float) -> void:
	if not enabled:
		return
	var vp := get_viewport()
	var t  := vp.canvas_transform
	# Camera2D'nin yerleştirdiği origin (kamera takibi) korunur,
	# yalnızca Y bazisi dönüştürülür → izometrik eğim + sıkıştırma
	vp.canvas_transform = Transform2D(
		t.x,                             # X bazis değişmez
		t.x * shear_x + t.y * y_scale,  # Y bazis: eğim + sıkıştırma
		t.origin                         # kamera pozisyonu korunur
	)
