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

# Reaksiyon sayaçları
var reaction_counts: Dictionary = {"steam": 0, "overheat": 0, "electrocute": 0, "frozen": 0}

# Karaktere özel kill
var char_kills: Dictionary = {"vector": 0, "leila": 0, "cyclone": 0}

# Upgrade / run istatistikleri
var total_upgrades_taken: int = 0
var calamity_filled_count: int = 0
var survival_5min: int = 0
var survival_10min: int = 0
var survival_20min: int = 0
var run_3element_count: int = 0

# Tamamlanan milestone'lar — collect edilmemiş olanlar burada bekler
var completed_milestones: Array = []
# Collect edilmiş milestone'lar — bir daha gösterilmez
var claimed_milestones: Array = []

# Milestone tanımları
const ENEMY_MILESTONES: Array = [10, 100, 1000]
const ENEMY_MILESTONE_CHIPS: Array = [5, 20, 75]
const BOSS_MILESTONES: Array = [5, 10, 25, 50, 100]
const BOSS_MILESTONE_CHIPS: Array = [15, 30, 60, 100, 200]
const CORE_MILESTONES: Array = [100, 1000, 10000]
const CORE_MILESTONE_CHIPS: Array = [10, 40, 150]
const REACTION_MILESTONES: Array = [100, 500, 2000]
const REACTION_MILESTONE_CHIPS: Array = [15, 50, 150]
const CHAR_KILL_MILESTONES: Array = [100, 500, 2000]
const CHAR_KILL_MILESTONE_CHIPS: Array = [20, 60, 150]
const UPGRADE_MILESTONES: Array = [10, 50, 200]
const UPGRADE_MILESTONE_CHIPS: Array = [10, 30, 100]
const CALAMITY_MILESTONES: Array = [1, 5, 20]
const CALAMITY_MILESTONE_CHIPS: Array = [25, 60, 150]
const SURVIVAL_5MIN_MILESTONES: Array = [1, 5, 20]
const SURVIVAL_5MIN_CHIPS: Array = [20, 50, 100]
const SURVIVAL_10MIN_MILESTONES: Array = [1, 5, 10]
const SURVIVAL_10MIN_CHIPS: Array = [40, 80, 150]
const SURVIVAL_20MIN_MILESTONES: Array = [1, 3]
const SURVIVAL_20MIN_CHIPS: Array = [100, 250]
const RUN3ELEM_MILESTONES: Array = [1, 10, 50]
const RUN3ELEM_MILESTONE_CHIPS: Array = [15, 40, 100]

# ── Chip Mağazası ────────────────────────────────────────────────────────────
# purchased_upgrades[char_id][item_id] = stack sayısı
var purchased_upgrades: Dictionary = {
	"vector": {}, "leila": {}, "cyclone": {}
}

# chars: [] = tüm karakterler, ["vector"] = sadece Vector vb.
const SHOP_ITEMS: Array = [
	{"id": "hp_up",        "name": "Güçlendirilmiş Biyometri", "desc": "Başlangıç HP +10",            "base_cost": 50,  "cost_inc": 10, "max_stack": 3, "chars": [],           "color": Color(0.2, 1.0, 0.5)},
	{"id": "core_up",      "name": "Ekstra Orbit Slotu",        "desc": "Başlangıçta +1 Normal Core",  "base_cost": 60,  "cost_inc": 10, "max_stack": 3, "chars": [],           "color": Color(1.0, 0.8, 0.0)},
	{"id": "speed_up",     "name": "Overclock Protokolü",       "desc": "Core hızı +%5",               "base_cost": 60,  "cost_inc": 10, "max_stack": 3, "chars": [],           "color": Color(0.0, 1.0, 1.0)},
	{"id": "xp_up",        "name": "Veri Emici",                "desc": "Düşmanlar +%10 XP verir",    "base_cost": 70,  "cost_inc": 10, "max_stack": 3, "chars": [],           "color": Color(0.8, 0.4, 1.0)},
	{"id": "cal_slot",     "name": "Ek Calamity Yuvası",        "desc": "Maksimum Calamity Slotu +1",  "base_cost": 80,  "cost_inc": 15, "max_stack": 2, "chars": [],           "color": Color(1.0, 0.4, 0.0)},
	{"id": "cal_start",    "name": "Hızlı Başlangıç",           "desc": "Run başında +1 rastgele Calamity", "base_cost": 90, "cost_inc": 15, "max_stack": 2, "chars": [],      "color": Color(1.0, 0.6, 0.0)},
	{"id": "armor_up",     "name": "Titanyum Tabaka",           "desc": "Başlangıç Armor +5",          "base_cost": 40,  "cost_inc": 10, "max_stack": 3, "chars": ["vector"],   "color": Color(0.5, 0.8, 1.0)},
	{"id": "leila_unlock", "name": "Leila — Erişim Kodu",       "desc": "Leila karakterini aç",        "base_cost": 150, "cost_inc": 0,  "max_stack": 1, "chars": ["vector","cyclone"], "color": Color(1.0, 0.18, 0.47)},
]

func get_stack(item_id: String, char_id: String = "") -> int:
	var cid := char_id if char_id != "" else selected_character
	if cid not in purchased_upgrades: return 0
	return purchased_upgrades[cid].get(item_id, 0)

func get_item_cost(item: Dictionary, char_id: String = "") -> int:
	return item["base_cost"] + get_stack(item["id"], char_id) * item["cost_inc"]

func can_buy(item: Dictionary, char_id: String = "") -> bool:
	var cid := char_id if char_id != "" else selected_character
	var allowed: Array = item.get("chars", [])
	if allowed.size() > 0 and cid not in allowed: return false
	if get_stack(item["id"], cid) >= item["max_stack"]: return false
	return chips >= get_item_cost(item, cid)

func buy_item(item_id: String) -> bool:
	var item: Dictionary = {}
	for s in SHOP_ITEMS:
		if s["id"] == item_id: item = s; break
	if item.is_empty(): return false
	var cid := selected_character
	if not can_buy(item, cid): return false
	var cost := get_item_cost(item, cid)
	chips -= cost
	if cid not in purchased_upgrades: purchased_upgrades[cid] = {}
	purchased_upgrades[cid][item_id] = purchased_upgrades[cid].get(item_id, 0) + 1
	if item_id == "leila_unlock":
		unlock_character("leila")
	save_data()
	return true

func get_shop_hp_bonus() -> int:
	return get_stack("hp_up") * 10

func get_shop_armor_bonus() -> int:
	return get_stack("armor_up") * 5

func get_shop_core_bonus() -> int:
	return get_stack("core_up")

func get_shop_speed_mult() -> float:
	return 1.0 + get_stack("speed_up") * 0.05

func get_shop_xp_mult() -> float:
	return 1.0 + get_stack("xp_up") * 0.1

func get_shop_calamity_slot_bonus() -> int:
	return get_stack("cal_slot")

func get_shop_start_calamity_count() -> int:
	return get_stack("cal_start")

func record_kill(enemy_type: String) -> void:
	if enemy_type not in enemy_kills:
		enemy_kills[enemy_type] = 0
	enemy_kills[enemy_type] += 1
	var milestones := BOSS_MILESTONES if enemy_type == "boss" else ENEMY_MILESTONES
	var new_unlock := false
	for i in range(milestones.size()):
		var key := "kill_%s_%d" % [enemy_type, milestones[i]]
		if enemy_kills[enemy_type] >= milestones[i] and key not in completed_milestones and key not in claimed_milestones:
			completed_milestones.append(key)
			new_unlock = true
	if new_unlock:
		save_data()

func record_char_kill(char_id: String) -> void:
	if char_id not in char_kills: char_kills[char_id] = 0
	char_kills[char_id] += 1
	_check_generic("charkill_%s" % char_id, char_kills[char_id], CHAR_KILL_MILESTONES)

func record_reaction(rtype: String) -> void:
	if rtype not in reaction_counts: reaction_counts[rtype] = 0
	reaction_counts[rtype] += 1
	_check_generic("react_%s" % rtype, reaction_counts[rtype], REACTION_MILESTONES)

func record_upgrade_taken() -> void:
	total_upgrades_taken += 1
	_check_generic("upgrade_total", total_upgrades_taken, UPGRADE_MILESTONES)

func record_calamity_filled() -> void:
	calamity_filled_count += 1
	_check_generic("calamity_filled", calamity_filled_count, CALAMITY_MILESTONES)

func record_survival(minutes: int) -> void:
	match minutes:
		5:
			survival_5min += 1
			_check_generic("survival_5min", survival_5min, SURVIVAL_5MIN_MILESTONES)
		10:
			survival_10min += 1
			_check_generic("survival_10min", survival_10min, SURVIVAL_10MIN_MILESTONES)
		20:
			survival_20min += 1
			_check_generic("survival_20min", survival_20min, SURVIVAL_20MIN_MILESTONES)

func record_run_3element() -> void:
	run_3element_count += 1
	_check_generic("run_3element", run_3element_count, RUN3ELEM_MILESTONES)

func _check_generic(prefix: String, value: int, thresholds: Array) -> void:
	var changed := false
	for t in thresholds:
		var key := "%s_%d" % [prefix, t]
		if value >= t and key not in completed_milestones and key not in claimed_milestones:
			completed_milestones.append(key)
			changed = true
	if changed: save_data()

func record_core_fire(core_type: String) -> void:
	if core_type not in core_fires:
		core_fires[core_type] = 0
	core_fires[core_type] += 1
	var new_unlock := false
	for i in range(CORE_MILESTONES.size()):
		var key := "core_%s_%d" % [core_type, CORE_MILESTONES[i]]
		if core_fires[core_type] >= CORE_MILESTONES[i] and key not in completed_milestones and key not in claimed_milestones:
			completed_milestones.append(key)
			new_unlock = true
	if new_unlock:
		save_data()

func claim_milestone(key: String) -> int:
	if key not in completed_milestones: return 0
	var reward := _get_milestone_reward(key)
	completed_milestones.erase(key)
	claimed_milestones.append(key)
	chips += reward
	save_data()
	return reward

func _get_milestone_reward(key: String) -> int:
	var parts := key.split("_")
	var threshold := int(parts[parts.size() - 1])
	if key.begins_with("kill_boss_"):
		var idx := BOSS_MILESTONES.find(threshold)
		return BOSS_MILESTONE_CHIPS[idx] if idx >= 0 else 0
	elif key.begins_with("kill_"):
		var idx := ENEMY_MILESTONES.find(threshold)
		return ENEMY_MILESTONE_CHIPS[idx] if idx >= 0 else 0
	elif key.begins_with("core_"):
		var idx := CORE_MILESTONES.find(threshold)
		return CORE_MILESTONE_CHIPS[idx] if idx >= 0 else 0
	elif key.begins_with("react_"):
		var idx := REACTION_MILESTONES.find(threshold)
		return REACTION_MILESTONE_CHIPS[idx] if idx >= 0 else 0
	elif key.begins_with("charkill_"):
		var idx := CHAR_KILL_MILESTONES.find(threshold)
		return CHAR_KILL_MILESTONE_CHIPS[idx] if idx >= 0 else 0
	elif key.begins_with("upgrade_total_"):
		var idx := UPGRADE_MILESTONES.find(threshold)
		return UPGRADE_MILESTONE_CHIPS[idx] if idx >= 0 else 0
	elif key.begins_with("calamity_filled_"):
		var idx := CALAMITY_MILESTONES.find(threshold)
		return CALAMITY_MILESTONE_CHIPS[idx] if idx >= 0 else 0
	elif key.begins_with("survival_5min_"):
		var idx := SURVIVAL_5MIN_MILESTONES.find(threshold)
		return SURVIVAL_5MIN_CHIPS[idx] if idx >= 0 else 0
	elif key.begins_with("survival_10min_"):
		var idx := SURVIVAL_10MIN_MILESTONES.find(threshold)
		return SURVIVAL_10MIN_CHIPS[idx] if idx >= 0 else 0
	elif key.begins_with("survival_20min_"):
		var idx := SURVIVAL_20MIN_MILESTONES.find(threshold)
		return SURVIVAL_20MIN_CHIPS[idx] if idx >= 0 else 0
	elif key.begins_with("run_3element_"):
		var idx := RUN3ELEM_MILESTONES.find(threshold)
		return RUN3ELEM_MILESTONE_CHIPS[idx] if idx >= 0 else 0
	return 0

func has_unclaimed_milestones() -> bool:
	return completed_milestones.size() > 0

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
	cfg.set_value("chips", "claimed_milestones",   claimed_milestones)
	for cid in purchased_upgrades:
		for iid in purchased_upgrades[cid]:
			cfg.set_value("shop_%s" % cid, iid, purchased_upgrades[cid][iid])
	for k in enemy_kills:
		cfg.set_value("kills", k, enemy_kills[k])
	for k in core_fires:
		cfg.set_value("cores", k, core_fires[k])
	for k in reaction_counts:
		cfg.set_value("reactions", k, reaction_counts[k])
	for k in char_kills:
		cfg.set_value("char_kills", k, char_kills[k])
	cfg.set_value("stats", "total_upgrades_taken", total_upgrades_taken)
	cfg.set_value("stats", "calamity_filled_count", calamity_filled_count)
	cfg.set_value("stats", "survival_5min",  survival_5min)
	cfg.set_value("stats", "survival_10min", survival_10min)
	cfg.set_value("stats", "survival_20min", survival_20min)
	cfg.set_value("stats", "run_3element_count", run_3element_count)
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
	var cm: Variant = cfg.get_value("chips", "claimed_milestones", [])
	if cm is Array:
		claimed_milestones = cm
	for cid in ["vector", "leila", "cyclone"]:
		purchased_upgrades[cid] = {}
		if cfg.has_section("shop_%s" % cid):
			for iid in cfg.get_section_keys("shop_%s" % cid):
				purchased_upgrades[cid][iid] = cfg.get_value("shop_%s" % cid, iid, 0)
	for k in enemy_kills:
		enemy_kills[k] = cfg.get_value("kills", k, 0)
	var core_keys: Variant = cfg.get_section_keys("cores") if cfg.has_section("cores") else []
	if core_keys is Array:
		for k in core_keys:
			core_fires[k] = cfg.get_value("cores", k, 0)
	for k in reaction_counts:
		reaction_counts[k] = cfg.get_value("reactions", k, 0)
	for k in char_kills:
		char_kills[k] = cfg.get_value("char_kills", k, 0)
	total_upgrades_taken  = cfg.get_value("stats", "total_upgrades_taken",  0)
	calamity_filled_count = cfg.get_value("stats", "calamity_filled_count", 0)
	survival_5min         = cfg.get_value("stats", "survival_5min",         0)
	survival_10min        = cfg.get_value("stats", "survival_10min",        0)
	survival_20min        = cfg.get_value("stats", "survival_20min",        0)
	run_3element_count    = cfg.get_value("stats", "run_3element_count",    0)
