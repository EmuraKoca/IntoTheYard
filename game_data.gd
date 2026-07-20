extends Node

const SAVE_PATH := "user://ity_save.cfg"

var selected_character := "vector"
var unlocked_characters: Array[String] = ["vector", "cyclone"]

# Kümülatif XP eşikleri — level 2,3,4,5,6 için gereken toplam XP
const XP_THRESHOLDS: Array[int] = [0, 2100, 5250, 9600, 15000, 22000]

const UNLOCKS: Dictionary = {
	"vector":  {1: "Piercing Ball",  3: "Heavy Ball",   5: "Crusher Fusion"},
	"leila":   {1: "Cryo Ball",      3: "Plasma Ball",  5: "Storm Fusion"},
	"cyclone": {1: "Mimic Ball",     3: "Glitch Ball",  5: "Ghost Fusion"},
}

var char_xp: Dictionary = {"vector": 0, "leila": 0, "cyclone": 0}

var show_intro: bool = false
var rescued_total: int = 0

func _ready() -> void:
	load_data()

# ── Karakter unlock ───────────────────────────────────────────────────────────
func unlock_character(char_id: String) -> void:
	if char_id not in unlocked_characters:
		unlocked_characters.append(char_id)
		save_data()

func is_unlocked(char_id: String) -> bool:
	return char_id in unlocked_characters

# ── XP ───────────────────────────────────────────────────────────────────────
func add_xp(char_id: String, amount: int) -> void:
	if char_id not in char_xp:
		char_xp[char_id] = 0
	char_xp[char_id] += amount
	save_data()

func get_xp(char_id: String) -> int:
	return char_xp.get(char_id, 0)

func get_level(char_id: String) -> int:
	var xp := get_xp(char_id)
	var lv  := 0
	for i in range(1, XP_THRESHOLDS.size()):
		if xp >= XP_THRESHOLDS[i]:
			lv = i
		else:
			break
	return min(lv, XP_THRESHOLDS.size() - 1)

func xp_in_current_level(char_id: String) -> int:
	var lv  := get_level(char_id)
	var xp  := get_xp(char_id)
	var base: int = XP_THRESHOLDS[lv]
	return xp - base

func xp_needed_for_level(char_id: String) -> int:
	var lv := get_level(char_id)
	if lv >= XP_THRESHOLDS.size() - 1:
		return 1  # Max level — bar dolu göster
	var base: int     = XP_THRESHOLDS[lv]
	var next_int: int = XP_THRESHOLDS[lv + 1]
	return next_int - base

func get_unlock_for_level(char_id: String, lv: int) -> String:
	if char_id not in UNLOCKS:
		return ""
	var table: Dictionary = UNLOCKS[char_id]
	return table.get(lv, "")

# ── Save / Load ───────────────────────────────────────────────────────────────
func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_characters", unlocked_characters)
	cfg.set_value("progress", "char_xp_vector",      char_xp.get("vector",  0))
	cfg.set_value("progress", "char_xp_leila",       char_xp.get("leila",   0))
	cfg.set_value("progress", "char_xp_cyclone",     char_xp.get("cyclone", 0))
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var saved: Variant = cfg.get_value("progress", "unlocked_characters", ["vector"])
	if saved is Array:
		unlocked_characters = []
		for c in saved:
			if c is String and c not in unlocked_characters:
				unlocked_characters.append(c)
	if "vector" not in unlocked_characters:
		unlocked_characters.append("vector")
	if "cyclone" not in unlocked_characters:
		unlocked_characters.append("cyclone")
	char_xp["vector"]  = cfg.get_value("progress", "char_xp_vector",  0)
	char_xp["leila"]   = cfg.get_value("progress", "char_xp_leila",   0)
	char_xp["cyclone"] = cfg.get_value("progress", "char_xp_cyclone", 0)
