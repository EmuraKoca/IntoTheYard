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
	"go_hint":         "[ Devam et — Victor seni izliyor ]",

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
	"go_hint":         "[ Keep going — Victor is watching ]",

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
