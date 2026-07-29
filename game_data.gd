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

# ── Chip sistemi ─────────────────────────────────────────────────────────────
var chips: int = 0

# Kalıcı kill / fire sayaçları
var enemy_kills: Dictionary = {
	"subject": 0, "armored_subject": 0, "frantic_subject": 0,
	"heavy_subject": 0, "cyber_shotgun": 0, "cyber_shooter": 0,
	"cyber_rifle": 0, "boss": 0
}
var core_fires: Dictionary = {}

# Tamamlanan milestone'lar (tekrar ödül vermesin)
var completed_milestones: Array = []

# Milestone tanımları
const ENEMY_MILESTONES: Array = [10, 100, 1000]
const ENEMY_MILESTONE_CHIPS: Array = [5, 20, 75]
const BOSS_MILESTONES: Array = [5, 10, 25, 50, 100]
const BOSS_MILESTONE_CHIPS: Array = [15, 30, 60, 100, 200]
const CORE_MILESTONES: Array = [100, 1000, 10000]
const CORE_MILESTONE_CHIPS: Array = [10, 40, 150]

func record_kill(enemy_type: String) -> int:
	if enemy_type not in enemy_kills:
		enemy_kills[enemy_type] = 0
	enemy_kills[enemy_type] += 1
	var earned := 0
	var milestones := BOSS_MILESTONES if enemy_type == "boss" else ENEMY_MILESTONES
	var rewards   := BOSS_MILESTONE_CHIPS if enemy_type == "boss" else ENEMY_MILESTONE_CHIPS
	for i in range(milestones.size()):
		var key := "kill_%s_%d" % [enemy_type, milestones[i]]
		if enemy_kills[enemy_type] >= milestones[i] and key not in completed_milestones:
			completed_milestones.append(key)
			chips += rewards[i]
			earned += rewards[i]
	if earned > 0:
		save_data()
	return earned

func record_core_fire(core_type: String) -> int:
	if core_type not in core_fires:
		core_fires[core_type] = 0
	core_fires[core_type] += 1
	var earned := 0
	for i in range(CORE_MILESTONES.size()):
		var key := "core_%s_%d" % [core_type, CORE_MILESTONES[i]]
		if core_fires[core_type] >= CORE_MILESTONES[i] and key not in completed_milestones:
			completed_milestones.append(key)
			chips += CORE_MILESTONE_CHIPS[i]
			earned += CORE_MILESTONE_CHIPS[i]
	if earned > 0:
		save_data()
	return earned

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
	cfg.set_value("chips", "total", chips)
	cfg.set_value("chips", "completed_milestones", completed_milestones)
	for k in enemy_kills:
		cfg.set_value("kills", k, enemy_kills[k])
	for k in core_fires:
		cfg.set_value("cores", k, core_fires[k])
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
	chips = cfg.get_value("chips", "total", 0)
	var ms: Variant = cfg.get_value("chips", "completed_milestones", [])
	if ms is Array:
		completed_milestones = ms
	for k in enemy_kills:
		enemy_kills[k] = cfg.get_value("kills", k, 0)
	var core_keys: Variant = cfg.get_section_keys("cores") if cfg.has_section("cores") else []
	if core_keys is Array:
		for k in core_keys:
			core_fires[k] = cfg.get_value("cores", k, 0)
