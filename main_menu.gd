extends Node2D

func _ready() -> void:
	$BtnNewGame.pressed.connect(_on_new_game)
	$BtnLoadGame.pressed.connect(_on_load_game)
	$BtnQuit.pressed.connect(_on_quit)

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://character_select.tscn")

func _on_load_game() -> void:
	pass  # Load Game henüz eklenmedi

func _on_quit() -> void:
	get_tree().quit()
