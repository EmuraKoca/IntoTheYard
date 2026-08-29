extends Node

# ── Aktif dil ────────────────────────────────────────────────────────────────
var locale: String = "en"   # "en" veya "tr"

const _TR := {
	# ── Ana Menü ─────────────────────────────────────────────────────────────
	"mm_new_game":   "▶  YENİ OYUN",
	"mm_load_game":  "▶  KAYDI YÜKLE",
	"mm_settings":   "⚙  AYARLAR",
	"mm_quit":       "■  ÇIKIŞ",
	"mm_subtitle":   "[ ITY CORP. — GÜVENLİ TERMİNAL v2.1 ]",
	"mm_version":    "v0.0.9.5  //  ALFA YAPIM  //  ITY CORP. 2099",

	# ── Settings ─────────────────────────────────────────────────────────────
	"set_title":           "⚙  AYARLAR",
	"set_tab_controls":    "KONTROLLER",
	"set_tab_audio":       "SES",
	"set_tab_display":     "EKRAN",
	"set_tab_language":    "DİL",
	"set_close":           "✕  KAPAT",
	"set_ctrl_header_action": "EYLEM",
	"set_ctrl_header_key":    "TUŞ / GİRDİ",
	"set_ctrl_movement":   "HAREKET",
	"set_ctrl_aim":        "NIŞAN",
	"set_ctrl_launch":     "CORE FIRLATMA",
	"set_ctrl_rts":        "RTS MODU GEÇIŞI",
	"set_ctrl_pause":      "DURDUR / MENÜ",
	"set_ctrl_debug":      "HATA AYIKLAMA (GEL.)",
	"set_ctrl_interact":   "ETKİLEŞİM (GEL.)",
	"set_ctrl_note":       "* Kontroller şu an değiştirilemez — ileride özelleştirme eklenecek.",
	"set_audio_master":    "ANA SES",
	"set_audio_music":     "MÜZİK SESİ",
	"set_audio_sfx":       "SES EFEKTLERİ",
	"set_display_fs":      "TAM EKRAN",
	"set_display_note":    "* Çözünürlük ayarı ileriki güncellemede eklenecek.",
	"set_lang_title":      "DİL SEÇİMİ",
	"set_lang_note":       "* Kart isimleri ve türleri her zaman İngilizce kalır.",

	# ── Oyun İçi UI ──────────────────────────────────────────────────────────
	"ui_level":            "◈  SEVİYE ",
	"ui_upgrades_header":  "— GELİŞTİRMELER —",
	"ui_upgrades_none":    "  yok",
	"ui_upgrades_speed":   "▸ Hız Artışı",
	"ui_upgrades_chain":   "▸ Zincir Artışı",
	"ui_upgrades_next":    "▸ Sonraki",
	"ui_calamity_header":  "— FELAKET —",
	"ui_cores_header":     "— CORE'LAR —",
	"ui_data_units":       " birim",
	"ui_avail_upgrades":   "// MEVCUT GELİŞTİRMELER //",

	# ── Duraklama Menüsü ─────────────────────────────────────────────────────
	"pause_title":    "DURAKLATILDI",
	"pause_resume":   "Devam Et",
	"pause_menu":     "Ana Menü",
	"pause_quit":     "Çıkış",

	# ── Upgrade Menüsü ───────────────────────────────────────────────────────
	"upgrade_confirm": "Onayla",
	"upgrade_skip":    "Geç",

	# ── Oyun Bitti ───────────────────────────────────────────────────────────
	"go_header":       "// DENEY OTURUMU SONA ERDİ //",
	"go_data":         "TOPLANAN VERİ",
	"go_time":         "OTURUM SÜRESİ",
	"go_threats":      "NÖTR. EDİLEN TEHDİTLER",
	"go_level":        "DENEY SEVİYESİ",
	"go_units":        " birim",
	"go_restart":      "TEKRAR DENE",
	"go_menu":         "ANA MENÜ",
	"go_continue":     "DEVAM ET",
	"go_hint":         "[ Devam et — Victor seni izliyor ]",
	"unlock_continue": "AL VE DEVAM ET",
	"unlock_hint":     "Yeni kartlar sonraki runlarda görünecek.",

	# ── Oyun İçi — Ek ────────────────────────────────────────────────────────
	"ui_balls":            "⬤  TOPLAR   ",
	"ui_release_core":     "CORE BIRAK",
	"ui_cancel":           "İptal",
	"ui_auto_on":          "OTO  AÇIK",
	"ui_auto_off":         "OTO  KAPALI",
	"ui_upgrade_ready":    "GELİŞTİRME HAZIR",
	"ui_level_up":         "SEVİYE ATLADI!",
	"ui_connected_core":   "◈ Bağlantılı Core",
	"ui_connected_core_tooltip": "Bu core fırlatılamaz — sürekli oyuncunun etrafında döner.",
	"ui_tactical_mode":    "◈  TAKTİK MOD  //  ×0.5",
	"ui_settings":         "Ayarlar",
	"ui_back":             "Geri",

	# ── Karakter Seçim ────────────────────────────────────────────────────────
	"cs_name":             "İsim: ",
	"cs_passive":          "Pasif: ",
	"cs_locked":           "Bu karakter henüz kilitli.",

	# ── Yeni Oyun Onayı ───────────────────────────────────────────────────────
	"ng_title":   "! YENİ OYUN",
	"ng_warn":    "Mevcut kayıt kalıcı olarak silinecek.\nDevam etmek istiyor musun?",
	"ng_yes":     "EVET — SİL VE BAŞLA",
	"ng_no":      "HAYIR — GERİ DÖN",
	"cs_next_unlock": "\nSonraki: ",
	"cs_balls":        "Toplar: ",

	# ── Hasmen Alıntıları ─────────────────────────────────────────────────────
	"quote_0": "Sefil. Sabrımın sınırları var, başarısızlık oranının aksine.",
	"quote_1": "Zar zor yeterli. Personal-ITY çipi daha iyi denekler hak ediyor.",
	"quote_2": "Ortalama sonuçlar. Ama davranış kalıpları... not edildi.",
	"quote_3": "Fena değil. Bir sonraki çip güncellemesi yaklaşıyor. Devam et.",
	"quote_4": "İstisnai. Belki de yatırımıma değeceksin.",

	# ── Run Tamamlama ─────────────────────────────────────────────────────────
	"run_end_title":   "RUN TAMAMLANDI",
	"run_end_time":    "⏱  %02d:%02d",
	"run_end_enemies": "💀  Düşman: %d",
	"run_end_allies":  "🤝  Kurtarılan: %d",
	"run_end_btn":     "ANA MENÜYE DÖN",
}

const _EN := {
	# ── Ana Menü ─────────────────────────────────────────────────────────────
	"mm_new_game":   "▶  NEW GAME",
	"mm_load_game":  "▶  LOAD GAME",
	"mm_settings":   "⚙  SETTINGS",
	"mm_quit":       "■  QUIT",
	"mm_subtitle":   "[ ITY CORP. — SECURE TERMINAL v2.1 ]",
	"mm_version":    "v0.0.9.5  //  ALPHA BUILD  //  ITY CORP. 2099",

	# ── Settings ─────────────────────────────────────────────────────────────
	"set_title":           "⚙  SETTINGS",
	"set_tab_controls":    "CONTROLS",
	"set_tab_audio":       "AUDIO",
	"set_tab_display":     "DISPLAY",
	"set_tab_language":    "LANGUAGE",
	"set_close":           "✕  CLOSE",
	"set_ctrl_header_action": "ACTION",
	"set_ctrl_header_key":    "KEY / INPUT",
	"set_ctrl_movement":   "MOVEMENT",
	"set_ctrl_aim":        "AIM",
	"set_ctrl_launch":     "LAUNCH CORE",
	"set_ctrl_rts":        "RTS MODE TOGGLE",
	"set_ctrl_pause":      "PAUSE / MENU",
	"set_ctrl_debug":      "DEBUG (DEV)",
	"set_ctrl_interact":   "INTERACT (DEV)",
	"set_ctrl_note":       "* Controls cannot be remapped yet — customization coming soon.",
	"set_audio_master":    "MASTER VOLUME",
	"set_audio_music":     "MUSIC VOLUME",
	"set_audio_sfx":       "SFX VOLUME",
	"set_display_fs":      "FULLSCREEN",
	"set_display_note":    "* Resolution settings coming in a future update.",
	"set_lang_title":      "LANGUAGE",
	"set_lang_note":       "* Card names and types always remain in English.",

	# ── Oyun İçi UI ──────────────────────────────────────────────────────────
	"ui_level":            "◈  LEVEL ",
	"ui_upgrades_header":  "— UPGRADES —",
	"ui_upgrades_none":    "  none",
	"ui_upgrades_speed":   "▸ Speed Up",
	"ui_upgrades_chain":   "▸ Chain Up",
	"ui_upgrades_next":    "▸ Next One",
	"ui_calamity_header":  "— CALAMITY —",
	"ui_cores_header":     "— CORES —",
	"ui_data_units":       " units",
	"ui_avail_upgrades":   "// AVAILABLE UPGRADES //",

	# ── Duraklama Menüsü ─────────────────────────────────────────────────────
	"pause_title":    "PAUSED",
	"pause_resume":   "Resume",
	"pause_menu":     "Main Menu",
	"pause_quit":     "Quit",

	# ── Upgrade Menüsü ───────────────────────────────────────────────────────
	"upgrade_confirm": "Confirm",
	"upgrade_skip":    "Skip",

	# ── Oyun Bitti ───────────────────────────────────────────────────────────
	"go_header":       "// EXPERIMENT SESSION CONCLUDED //",
	"go_data":         "DATA HARVESTED",
	"go_time":         "SESSION TIME",
	"go_threats":      "THREATS NEUTRALIZED",
	"go_level":        "EXPERIMENT LEVEL",
	"go_units":        " units",
	"go_restart":      "RESTART",
	"go_menu":         "MAIN MENU",
	"go_continue":     "CONTINUE",
	"go_hint":         "[ Keep going — Victor is watching ]",
	"unlock_continue": "TAKE AND CONTINUE",
	"unlock_hint":     "New cards will appear in future runs.",

	# ── Oyun İçi — Ek ────────────────────────────────────────────────────────
	"ui_balls":            "⬤  BALLS   ",
	"ui_release_core":     "RELEASE A CORE",
	"ui_cancel":           "Cancel",
	"ui_auto_on":          "AUTO  ON",
	"ui_auto_off":         "AUTO  OFF",
	"ui_upgrade_ready":    "UPGRADE READY",
	"ui_level_up":         "LEVEL UP!",
	"ui_connected_core":   "◈ Connected Core",
	"ui_connected_core_tooltip": "This core cannot be launched — it orbits the player permanently.",
	"ui_tactical_mode":    "◈  TACTICAL MODE  //  ×0.5",
	"ui_settings":         "Settings",
	"ui_back":             "Back",

	# ── Karakter Seçim ────────────────────────────────────────────────────────
	"cs_name":             "Name: ",
	"cs_passive":          "Passive: ",
	"cs_locked":           "This character is not yet unlocked.",

	# ── Yeni Oyun Onayı ───────────────────────────────────────────────────────
	"ng_title":   "! NEW GAME",
	"ng_warn":    "Your existing save will be permanently deleted.\nAre you sure you want to continue?",
	"ng_yes":     "YES — DELETE & START",
	"ng_no":      "NO — GO BACK",
	"cs_next_unlock": "\nNext: ",
	"cs_balls":        "Balls: ",

	# ── Hasmen Alıntıları ─────────────────────────────────────────────────────
	"quote_0": "Pathetic. My patience has limits, unlike your failure rate.",
	"quote_1": "Barely enough. The Personal-ITY chip deserves better test subjects.",
	"quote_2": "Mediocre results. But the behavioral patterns are... noted.",
	"quote_3": "Not bad. The next chip update draws closer. Keep going.",
	"quote_4": "Exceptional. You may yet prove worthy of my investment.",

	# ── Run Tamamlama ─────────────────────────────────────────────────────────
	"run_end_title":   "RUN COMPLETE",
	"run_end_time":    "⏱  %02d:%02d",
	"run_end_enemies": "💀  Enemies: %d",
	"run_end_allies":  "🤝  Rescued: %d",
	"run_end_btn":     "RETURN TO MENU",
}

func t(key: String) -> String:
	var dict := _TR if locale == "tr" else _EN
	if dict.has(key):
		return dict[key]
	if _EN.has(key):
		return _EN[key]
	return "[%s]" % key

# ── Kart açıklamaları (index → TR metin) ─────────────────────────────────────
const _DESC_TR: Dictionary = {
	# ── Vector — Identity ────────────────────────────────────────────────────
	0:  "Core 3'e bölünür",
	# 2, 40, 41, 42, 43, 44, 45: _dynamic_desc() içinde (ball_mastery'ye göre canlı hasar gösterir)
	46: "Eksik HP → bonus hasar",
	47: "Zırh aktifken → +3 hasar",
	# ── Vector — Utility ─────────────────────────────────────────────────────
	35: "İsabet → +1 Stack\n+3% Core Hızı/stack\n(maks 20 stack)",
	36: "Her 10 isabette:\n+1 Zırh Kazanımı (maks 10)",
	37: "Uçuşta yeni düşmana çarparsan:\nhasar artar, dönünce sıfırlanır",
	38: "Düşük HP → Core Hız bonusu\n& Zırh Kazanım verimliliği",
	# ── Vector — Individuality ────────────────────────────────────────────────
	4:  "Hareket hızı artar",
	20: "+10 HP iyileştirilir",
	21: "Maksimum HP +5",
	30: "-10 HP  |  +10 Maks Zırh",
	31: "HP <%50  →  Zırh Kazanımı +%50",
	32: "HP <%30  →  Momentum Engine x2",
	33: "-10 HP  |  +5 Zırh Kapasitesi  |  +1 Zırh Yenilenme/sn",
	34: "Alındığında: -15 HP\n+%75 Zırh Kazanımı (10sn)",
	48: "+20 Maks Zırh / Core Hızı -%10",
	49: "Zırh kazanım verimi +%25",
	50: "Zırh Kapasitesi +15 / Momentum Kazanımı -%20",
	51: "HP ≤%70: Core Hızı +%0→%50 arasında artar",
	52: "Core Hasarı ×1.4 / Maks HP -15",
	53: "HP <%50: Zırh Kazanımı +%50 | HP >%70: Zırh Kazanımı -%30",
	54: "Core Hızı +%20 / Zırh Kazanımı -%15",
	55: "Momentum dönüşte sıfırlanmaz / Maks Zırh -10",
	56: "Core dönüş hızı ×1.5",
	57: "Geri tepme ×2 / Core Hızı -%10",
	58: "Düşman yavaşlama süresi ×2 / Oyuncu Hızı -%10",
	59: "Düşük HP: Zırh +%40 | Yüksek HP: Core Hızı +%10",
	60: "Alınan hasar → Momentum stack / Zırh Kazanımı -%30",
	105: "Alındığında (tek seferlik):\nHer 10 Maks HP için +1 Armor Cap",
	109: "Armor Cap doluyken her isabet:\n+1 Momentum stack (maks %50'ye kadar doldurur)",
	111: "HP %40'ın altına düşünce:\n+10 Armor Cap (tek seferlik)",
	112: "Her 5 Momentum için +5 Max Armor\n(alındığında, tek seferlik)",
	113: "20 Momentum stack'ine ulaşınca:\nCore Hasarı ×1.3 (kalıcı)",
	174: "Mevcut Armor/2 kadar Avlu'daki tüm düşmanlara AoE hasar",
	175: "Armor sıfırlanır, 8s:\nCore Hasarı ×2.5",
	176: "Tüm Momentum'u harca:\nstack başına +%5 Core Hızı (10sn)",
	177: "En yakın düşmana Armor Cap kadar hasar\nArmor sıfırlanır",
	169: "Armor ilk kez sıfırlanınca:\ntüm Momentum → Armor ×2 (run başına 1 kez)",
	178: "Her 2s: 60px'deki düşmanlara\n1 + Armor×%5 hasar",
	179: "Momentum Engine'in pasif\nüretimine +1 ekler (tick başına)",
	181: "Armor %75+ doluyken:\n90px içindeki düşmanlar %25 yavaşlar",
	182: "HP %50 altındayken:\nher 9s'de 1 HP yeniler",
	183: "Momentum 15+: her 4s\n60px'e 2 hasar pulse",
	# ── Leila — Identity ─────────────────────────────────────────────────────
	1:  "Core elektrik kazanır",
	15: "Düşmanı %25 yavaşlatır",
	17: "Düşmana ıslak etkisi uygular",
	18: "Düşmana yanma etkisi uygular",
	# ── Leila — Utility ──────────────────────────────────────────────────────
	13: "Elektrik core +2 hasar",
	# ── Cyclone — Identity ───────────────────────────────────────────────────
	16: "Düşmanı 3sn şaşırtır",
	19: "Yakındaki güçlü core'u kopyalar",
	22: "İsabette +2 Can",
	# ── Herkese açık — Utility & Calamity ────────────────────────────────────
	11: "Tüm core'lara +1 hasar",
	7:  "Seçilen noktaya yıldırım çarpar",
	8:  "Seçilen alanda sürekli hasar",
	9:  "Düşmanları 5sn çeker",
}


# ── Dinamik kart açıklamaları (runtime'da değişen sayılar) ───────────────────
# Sadece başka kartlarla değeri değişebilen kartlar burada match'lenir.
# BBCode kullanılır — [b]..[/b] ile güncel değer kalın gösterilir.
func _dynamic_desc(index: int, player: Node) -> String:
	var _bm: int = player.get("ball_mastery") if player.get("ball_mastery") != null else 0
	match index:
		2:  # Pierce Core
			var _dmg: int = 5 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nPierces through unarmored enemies." % _dmg
			return "[b]%d[/b] hasar.\nZırhı olmayan düşmanı deşip geçer" % _dmg
		40:  # Armor Core
			var amt: int = player.get("armor_gain_per_hit") if player.get("armor_gain_per_hit") != null else 1
			var _dmg: int = 4 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nHit enemy → gain [b]%d[/b] Armor" % [_dmg, amt]
			return "[b]%d[/b] hasar.\nDüşmana vuruş → [b]%d[/b] Armor kazandırır" % [_dmg, amt]
		41:  # Anchor Core
			var _mult: float = player.get("slow_duration_mult") if player.get("slow_duration_mult") != null else 1.0
			var _dur: int = int(3.0 * _mult)
			var _dmg: int = 8 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nHit enemy → slows 60%% for [b]%d[/b]s" % [_dmg, _dur]
			return "[b]%d[/b] hasar.\nİsabet → düşman [b]%d[/b] Saniye boyunca %%60 yavaşlar" % [_dmg, _dur]
		42:  # Crusher Core
			var _dmg: int = 9 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nHit → instantly breaks enemy Armor" % _dmg
			return "[b]%d[/b] hasar.\nİsabet → düşmanın Zırhını anında kırar" % _dmg
		45:  # Siege Core
			var _dmg: int = 15 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nHighest damage core" % _dmg
			return "[b]%d[/b] hasar.\nEn yüksek hasarlı core" % _dmg
		43:  # Kinetic Core
			var _dmg: int = 7 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nEach wall bounce → +dmg" % _dmg
			return "[b]%d[/b] hasar.\nHer duvar sekmesi → +hasar" % _dmg
		44:  # Bulwark Core
			var _dmg: int = 3 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nHit → +2 Armor" % _dmg
			return "[b]%d[/b] hasar.\nİsabet → +2 Armor" % _dmg
		46:  # Bloodbound Core
			var _dmg: int = 8 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nEvery 5 missing HP → +1 bonus dmg" % _dmg
			return "[b]%d[/b] hasar.\nHer 5 eksik can için +1 bonus hasar" % _dmg
		47:  # Tempered Core
			var _dmg: int = 9 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nArmor active → +3 dmg" % _dmg
			return "[b]%d[/b] hasar.\nZırh aktifken → +3 hasar" % _dmg
		180:  # Regen Pulse Core
			var _agm: float = player.get("armor_gain_mult") if player.get("armor_gain_mult") != null else 1.0
			var _amt: int = int(1 * _agm)
			if locale == "en":
				return "Every 15s: restore [b]%d[/b] Armor" % _amt
			return "Her 15s: [b]%d[/b] Armor yeniler" % _amt
		35:  # Momentum Engine
			var _msb: float = player.get("momentum_speed_bonus") if player.get("momentum_speed_bonus") != null else 0.03
			var _mmax: int = player.get("momentum_max") if player.get("momentum_max") != null else 20
			var _mgi: float = player.get("momentum_gen_interval") if player.get("momentum_gen_interval") != null else 4.0
			var _msb_pct: int = int(round(_msb * 100.0))
			var _is_lv1: bool = _msb_pct <= 3
			if locale == "en":
				var _r_en: String = ""
				if _is_lv1:
					_r_en = "Unlocks the Momentum system.\n"
				_r_en += "While walking, every [b]%.0f[/b]s: +1 Stack\n+[b]%d[/b]%% Core Speed per stack (max [b]%d[/b])" % [_mgi, _msb_pct, _mmax]
				return _r_en
			var _r_tr: String = ""
			if _is_lv1:
				_r_tr = "Momentum Mekaniğini açar.\n"
			_r_tr += "Yürürken her [b]%.0f[/b]s: +1 Stack\n+[b]%d[/b]%% Core Hızı/stack (maks [b]%d[/b])" % [_mgi, _msb_pct, _mmax]
			return _r_tr
		37:  # Chain Density
			var _cdb: int = player.get("chain_density_bonus_per_hit") if player.get("chain_density_bonus_per_hit") != null else 1
			if locale == "en":
				return "New enemy hit mid-flight:\n+[b]%d[/b]x cumulative dmg, resets on return" % _cdb
			return "Uçuşta yeni düşmana çarparsan:\n+[b]%d[/b]x kümülatif hasar, dönünce sıfırlanır" % _cdb
		36:  # Impact Feedback
			var _ift: int = player.get("impact_feedback_threshold") if player.get("impact_feedback_threshold") != null else 10
			if locale == "en":
				return "Every [b]%d[/b] hits:\nArmor Core gain permanently +1 (max 10)" % _ift
			return "Her [b]%d[/b] isabette:\nArmor Core kazanımı kalıcı +1 artar (maks 10)" % _ift
		38:  # Last Stand
			var _lshm: float = player.get("last_stand_hp_mult") if player.get("last_stand_hp_mult") != null else 0.005
			var _lsam: float = player.get("last_stand_armor_mult") if player.get("last_stand_armor_mult") != null else 0.0
			var _pct: float = _lshm * 100.0
			if locale == "en":
				var _r_en: String = "Missing HP → Core Speed bonus\n(+[b]%.1f[/b]%% per missing HP)" % _pct
				if _lsam > 0.0:
					_r_en += "\nMissing HP → passive Armor regen"
				return _r_en
			var _r_tr: String = "Eksik HP → Core Hızı bonusu\n(+[b]%.1f[/b]%% / eksik HP)" % _pct
			if _lsam > 0.0:
				_r_tr += "\nEksik HP → pasif Zırh kazanımı"
			return _r_tr
		104:  # Pressure Valve
			var _pvt: int = player.get("pressure_valve_threshold") if player.get("pressure_valve_threshold") != null else 5
			if locale == "en":
				return "Every [b]%d[/b] Momentum stacks:\ngain +1 Armor" % _pvt
			return "Her [b]%d[/b] Momentum stack'inde:\n+1 Armor kazan" % _pvt
		108:  # Momentum Cascade
			var _mct: int = player.get("momentum_cascade_threshold") if player.get("momentum_cascade_threshold") != null else 12
			if locale == "en":
				return "[b]%d[/b]+ Momentum stacks:\nArmor Gain ×1.5" % _mct
			return "[b]%d[/b]+ Momentum stack:\nZırh Kazanımı ×1.5" % _mct
		110:  # Bulwark Surge
			var _bst: int = int(round((player.get("bulwark_surge_threshold") if player.get("bulwark_surge_threshold") != null else 0.75) * 100.0))
			var _bsm: float = player.get("bulwark_surge_mult") if player.get("bulwark_surge_mult") != null else 1.15
			var _bsp: int = int(round((_bsm - 1.0) * 100.0))
			if locale == "en":
				return "Armor ≥ [b]%d[/b]%% Cap:\nCore Speed +[b]%d[/b]%%" % [_bst, _bsp]
			return "Armor ≥ %[b]%d[/b] Cap:\nCore Hızı +%[b]%d[/b]" % [_bst, _bsp]
		164:  # Armor Rush
			var _art: int = player.get("armor_rush_threshold") if player.get("armor_rush_threshold") != null else 13
			if locale == "en":
				return "Momentum ≥ [b]%d[/b]:\nArmor gain +1 (cancels below threshold)" % _art
			return "Momentum ≥ [b]%d[/b]:\nArmor kazanımı +1 (eşik altına düşünce iptal olur)" % _art
		165:  # Combat Rhythm
			var _crt: int = player.get("combat_rhythm_threshold") if player.get("combat_rhythm_threshold") != null else 6
			if locale == "en":
				return "[b]%d[/b] consecutive hits:\nCore returns instantly" % _crt
			return "[b]%d[/b] ardışık isabet:\nCore anında geri döner" % _crt
		166:  # Shield Bash
			var _sbm: float = player.get("shield_bash_mult") if player.get("shield_bash_mult") != null else 1.25
			if locale == "en":
				return "Core return speed:\n+Armor ×[b]%.2f[/b]" % _sbm
			return "Core dönüş hızı:\n+Armor ×[b]%.2f[/b]" % _sbm
		167:  # Siege Protocol
			var _spb: int = player.get("siege_protocol_bonus") if player.get("siege_protocol_bonus") != null else 1
			if locale == "en":
				return "Siege Core: each wall bounce\ngains +[b]%d[/b] dmg. (Extra damage resets on hit)" % _spb
			return "Siege Core: her duvar sekmesinde\n+[b]%d[/b] hasar kazanır. (Kazanılan ekstra hasar isabette sıfırlanır)" % _spb
		168:  # Bulwark Echo
			var _bed: float = player.get("bulwark_echo_delay") if player.get("bulwark_echo_delay") != null else 4.0
			var _bea: int = player.get("bulwark_echo_amount") if player.get("bulwark_echo_amount") != null else 1
			if locale == "en":
				return "Bulwark Core hit: after [b]%.0f[/b]s\ngain [b]%d[/b] more Armor" % [_bed, _bea]
			return "Bulwark Core isabeti: [b]%.0f[/b]s sonra\n[b]%d[/b] Armor daha kazanırsın" % [_bed, _bea]
		171:  # Kinetic Surge
			var _kst: int = player.get("kinetic_surge_threshold") if player.get("kinetic_surge_threshold") != null else 15
			var _kss: float = player.get("kinetic_surge_speed") if player.get("kinetic_surge_speed") != null else 700.0
			if locale == "en":
				return "[b]%d[/b]+ Momentum:\nCore launches at min. [b]%.0f[/b] speed" % [_kst, _kss]
			return "[b]%d[/b]+ Momentum:\nCore en az [b]%.0f[/b] hızla fırlar" % [_kst, _kss]
		172:  # Armor Conduit
			var _acm: float = player.get("armor_conduit_mult") if player.get("armor_conduit_mult") != null else 1.25
			if locale == "en":
				return "Armor = Cap:\nAll core damage ×[b]%.2f[/b]" % _acm
			return "Armor = Cap:\nTüm core hasarı ×[b]%.2f[/b]" % _acm
		184:  # Anchor Pulse Core
			var _agm2: float = player.get("armor_gain_mult") if player.get("armor_gain_mult") != null else 1.0
			var _amt2: int = int(1 * _agm2)
			if locale == "en":
				return "Stationary for 5s: gain\n[b]%d[/b] Armor every 1s" % _amt2
			return "5s hareketsiz: her 1s\n[b]%d[/b] Armor kazanır" % _amt2
	return ""

func desc(index: int, fallback: String, player: Node = null) -> String:
	if player:
		var _d: String = _dynamic_desc(index, player)
		if _d != "":
			return _d
	if locale == "en":
		return fallback
	return _DESC_TR.get(index, fallback)
