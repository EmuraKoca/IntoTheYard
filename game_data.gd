extends Node

const SAVE_PATH := "user://ity_save.cfg"

var selected_character := "vector"

var unlocked_characters: Array[String] = ["vector"]

func _ready() -> void:
	load_data()

func unlock_character(char_id: String) -> void:
	if char_id not in unlocked_characters:
		unlocked_characters.append(char_id)
		save_data()

func is_unlocked(char_id: String) -> bool:
	return char_id in unlocked_characters

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_characters", unlocked_characters)
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return  # Kayıt yok — varsayılan değerler geçerli
	var saved: Variant = cfg.get_value("progress", "unlocked_characters", ["vector"])
	if saved is Array:
		unlocked_characters = []
		for c in saved:
			if c is String and c not in unlocked_characters:
				unlocked_characters.append(c)
	# Vector her zaman açık olmalı
	if "vector" not in unlocked_characters:
		unlocked_characters.append("vector")
