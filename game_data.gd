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

# ── Chip Mağazası ────────────────────────────────────────────────────────────
var purchased_upgrades: Array = []

const SHOP_ITEMS: Array = [
	{"id": "hp_up",       "name": "Güçlendirilmiş Biyometri", "desc": "Başlangıç HP +10",          "cost": 50,  "color": Color(0.2, 1.0, 0.5)},
	{"id": "armor_up",    "name": "Titanyum Tabaka",           "desc": "Başlangıç Armor +5",         "cost": 40,  "color": Color(0.5, 0.8, 1.0)},
	{"id": "core_up",     "name": "Ekstra Orbit Slotu",        "desc": "Başlangıçta +1 Core",        "cost": 75,  "color": Color(1.0, 0.8, 0.0)},
	{"id": "speed_up",    "name": "Overclock Protokolü",       "desc": "Core hızı +%5",              "cost": 60,  "color": Color(0.0, 1.0, 1.0)},
	{"id": "xp_up",       "name": "Veri Emici",                "desc": "Düşmanlar +%10 XP verir",   "cost": 80,  "color": Color(0.8, 0.4, 1.0)},
	{"id": "leila_unlock","name": "Leila — Erişim Kodu",       "desc": "Leila karakterini aç",       "cost": 150, "color": Color(1.0, 0.18, 0.47)},
]

func is_purchased(item_id: String) -> bool:
	return item_id in purchased_upgrades

func buy_item(item_id: String) -> bool:
	if is_purchased(item_id): return false
	var item: Dictionary = {}
	for s in SHOP_ITEMS:
		if s["id"] == item_id:
			item = s
			break
	if item.is_empty(): return false
	if chips < item["cost"]: return false
	chips -= item["cost"]
	purchased_upgrades.append(item_id)
	if item_id == "leila_unlock":
		unlock_character("leila")
	save_data()
	return true

func get_shop_hp_bonus() -> int:
	return 10 if is_purchased("hp_up") else 0

func get_shop_armor_bonus() -> int:
	return 5 if is_purchased("armor_up") else 0

func get_shop_core_bonus() -> int:
	return 1 if is_purchased("core_up") else 0

func get_shop_speed_mult() -> float:
	return 1.05 if is_purchased("speed_up") else 1.0

func get_shop_xp_mult() -> float:
	return 1.1 if is_purchased("xp_up") else 1.0

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
	cfg.set_value("chips", "purchased_upgrades", purchased_upgrades)
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
	var pu: Variant = cfg.get_value("chips", "purchased_upgrades", [])
	if pu is Array:
		purchased_upgrades = pu
	for k in enemy_kills:
		enemy_kills[k] = cfg.get_value("kills", k, 0)
	var core_keys: Variant = cfg.get_section_keys("cores") if cfg.has_section("cores") else []
	if core_keys is Array:
		for k in core_keys:
			core_fires[k] = cfg.get_value("cores", k, 0)
