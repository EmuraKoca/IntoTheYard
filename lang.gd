extends Node

# ── Aktif dil ────────────────────────────────────────────────────────────────
var locale: String = "en"   # "en" veya "tr"

# ── Durum efekti sözlüğü (kart açıklamalarında bold geçen keyword'ler için) ───
# Gwent tarzı: kart üzerine gelince, açıklamada geçen keyword'lerin anlamı yan
# panelde gösterilir. Yeni bir keyword açıklamaya eklenince buraya da eklenmeli.
const STATUS_KEYWORDS := ["Electrified", "Wet", "Burning", "Slowed", "Frozen", "Momentum", "Glitched", "Virus", "Decay", "Mark"]

# "Connected Core" keyword açıklamada geçmez, rozet üzerinden ayrıca ekleniyor
# (bkz. game_scene.gd::_show_card_glossary çağrısı, _CONNECTED_CORE_INDICES kontrolü).
const _STATUS_GLOSSARY_EN := {
	"Electrified": "Enemy is marked for 5s. Triggers electric-based combos and reactions (chain damage, spread effects, etc.) from other cards.",
	"Wet":         "Enemy is marked as wet. Combines with Fire (→ Steam) or Electric (stronger shock) for elemental reactions.",
	"Burning":     "Enemy takes damage over time. Combines with Wet (→ Steam) for a reaction.",
	"Slowed":      "Enemy's movement speed is reduced for a duration.",
	"Frozen":      "Enemy is completely immobilized for a duration.",
	"Connected Core": "Cannot be launched — orbits the player permanently. Dart-strikes any enemy that comes within range for [b]3[/b] damage.",
	"Momentum": "Represents [b]Core Speed[/b] — each stack makes your cores move faster.",
	"Glitched": "Enemy is disoriented for a duration — deals reduced damage while attacking. Triggers glitch-based synergies from other cards.",
	"Virus": "Enemy accumulates stacks that deal damage over time. Stacks and duration can grow with other cards.",
	"Decay": "Enemy accumulates stacks (max 3) that slow it. Each stack lasts [b]3s[/b]. If it dies with stacks, it explodes and damages nearby enemies.",
	"Mark": "Marked enemies take 50% more damage.",
}
const _STATUS_GLOSSARY_TR := {
	"Electrified": "Düşman 5sn işaretlenir. Diğer kartların elektrik tabanlı combo/reaksiyonlarını (zincir hasarı, yayılma efekti vb.) tetikler.",
	"Wet":         "Düşman ıslak olarak işaretlenir. Ateş (→ Buhar) veya Elektrik (daha güçlü şok) ile birleşince elemental reaksiyon oluşturur.",
	"Burning":     "Düşman zamana yayılı hasar alır. Islak (→ Buhar) ile birleşince reaksiyon oluşturur.",
	"Slowed":      "Düşmanın hareket hızı belirli bir süre boyunca düşer.",
	"Frozen":      "Düşman belirli bir süre boyunca tamamen hareketsiz kalır.",
	"Connected Core": "Fırlatılamaz — sürekli oyuncunun etrafında döner. Menziline giren düşmanlara [b]3[/b] hasarlık dart saldırısı yapar.",
	"Momentum": "[b]Core Speed[/b]'i temsil eder — her stack core'ların hareket hızını artırır.",
	"Glitched": "Düşman belirli bir süre boyunca sersemler — saldırırken daha az hasar verir. Diğer kartların glitch tabanlı sinerjilerini tetikler.",
	"Virus": "Düşman zamana yayılı hasar veren stack biriktirir. Diğer kartlarla stack/süre artabilir.",
	"Decay": "Düşman yavaşlatan stack biriktirir (maks 3). Her stack [b]3sn[/b] sürer. Stack'liyken ölürse patlar ve yakındaki düşmanlara hasar verir.",
	"Mark": "İşaretli düşmanlar %50 daha fazla hasar alır.",
}

func status_glossary(keyword: String) -> String:
	if locale == "en":
		return _STATUS_GLOSSARY_EN.get(keyword, "")
	return _STATUS_GLOSSARY_TR.get(keyword, "")

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
	177: "Hedeflenen noktaya Armor Cap\nkadar alan hasarı verir, Armor sıfırlanır",
	198: "Vector'un çevresinde solucan deliği açılır\nYaklaşan düşmanlar sonsuzluğa karışır. (Boss hariç)",
	199: "7sn: hedef alana her 0.5sn'de\nbir Siege Core düşer",
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
	77: "İsabette 3 küçük rastgele\nElemental Core'a ayrılır",
	# ── Leila — Utility ──────────────────────────────────────────────────────
	13: "Electric Core +2 hasar",
	99: "Cryo Core +2 hasar",
	100: "Hydro Core +2 hasar",
	101: "Pyro Core +2 hasar",
	91: "Reaksiyon → son kullanılan elementi\ntekrar uygular",
	94: "Yard'ı bir kar fırtınası kaplar. Yolundaki\n[b]Wet[/b] düşmanlar [b]Frozen[/b] olur,\ndiğerleri [b]Slowed[/b] olur",
	95: "Yard'daki tüm düşmanlar\n[b]Wet[/b] olur",
	96: "Yard'daki tüm [b]Electrified[/b] düşmanlar\n15 hasar alır",
	97: "Alandaki düşmanlara 4sn boyunca her\n0.5sn'de 2 hasar verir ve [b]Burning[/b] uygular",
	98: "5sn boyunca her saniye rastgele 2 düşmana\n5 hasar verir ve [b]Electrified[/b] uygular",
	129: "Avlu'daki tüm [b]Glitched[/b] düşmanlar bozulma\npatlamasıyla 10 hasar alır, Glitch'leri temizlenir",
	130: "Avlu'daki tüm düşmanlar 3sn boyunca\n[b]Glitched[/b] olur",
	138: "5sn boyunca Core Hızı ×3 olur",
	144: "2 bonus core kazandırır.\nAteşlenmezse 25sn sonra kaybolur",
	156: "Avlu'daki tüm düşmanlar maksimum\n[b]Virus[/b] stack'i alır",
	215: "Yerde bir alan bırakır.\nÜstünden geçen düşmanlar\n[b]Glitched[/b] olur",
	216: "Avlu'daki tüm [b]Glitched[/b] düşmanlar\nmevcut HP'sinin %30'unu kaybeder",
	218: "5sn boyunca bir çürüme alanı bırakır.\nİçindeki düşmanlar her saniye 1 [b]Decay[/b] stack alır",
	76: "Uyguladığın her benzersiz element\n→ +%1 Hareket Hızı (maks %4)",
	85: "Her Reaksiyon → 2 HP geri kazandırır",
	86: "Reaksiyon sonrası: düşmanın bir sonraki\ndebuff'ı 2× uzun sürer",
	200: "Sahada [b]Wet[/b] bir düşman varken:\n%10 az hasar alırsın",
	201: "Her [b]Burning[/b] düşman için:\n+1 Burn tick hasarı (maks +7)",
	202: "Steam reaksiyonu: 3sn boyunca\n+%15 hareket hızı",
	203: "Electrocute reaksiyonu: 3sn boyunca\n%8 ihtimalle hasardan kaçınırsın",
	204: "Shatter reaksiyonu: +5 HP kalkan\n(birikir, maks 20, 4sn)",
	205: "Bir sonraki level up'a kadar 3 farklı\nreaksiyon: 5sn için +%10 hasar",
	206: "Melt reaksiyonu: düşmanın konumunda\n2sn boyunca alev bırakır (1 hasar/sn)",
	207: "Bir sonraki level up'a kadar 4 farklı\nreaksiyon: sonraki Calamity slot tüketmez",
	209: "Avlu'daki tüm [b]Burning[/b] düşmanlar patlar:\n10 hasar, yakındaki 2 düşmana [b]Burning[/b] yayar",
	# ── Cyclone — Identity ───────────────────────────────────────────────────
	19: "Yakındaki güçlü core'u kopyalar",
	22: "İsabette +2 Can",
	159: "Her fırlatışta ilk isabet: 0.5sn sersemletir\nCore player'a dönene kadar tekrar tetiklenmez",
	160: "İsabet → 1 [b]Virus[/b] stack",
	161: "İsabet → 1 [b]Decay[/b] stack",
	162: "İsabet → düşmana [b]Slowed[/b] uygular (%40, 0.5sn)\n[b]Glitched[/b] hedef: 1sn sürer",
	163: "Duvar sekmesi → +%5 hız (maks +%30)\nHer 10 hız = +1 hasar. İsabette sıfırlanır",
	192: "Her 4sn: yakındaki bir düşmana\n[b]Glitched[/b] uygular",
	193: "Dash sonrası 3sn: yakındaki\ndüşmanlara 1 hasar/sn verir",
	194: "Yakında [b]Glitched[/b] düşman varsa\nher 1sn: +1 HP kazanır",
	195: "Yakındaki bir [b]Virus[/b]'lü düşman ölürse,\n3sn boyunca yakındaki düşmanlara 1'er stack yayar",
	196: "Yakındaki bir düşmanı [b]Mark[/b] eder",
	197: "Circuit Breaker tetiklenince\n3sn: yakındaki düşmanlara sürekli [b]Glitched[/b] uygular",
	212: "İsabet 1sn'lik takip izi bırakır\nİzden geçen düşman %40 yavaşlar (0.5sn)",
	213: "İsabet: hedefte 3 [b]Decay[/b] stack varsa\nanında Decay patlamasını tetikler",
	214: "Öldürünce: +2 HP kazanır",
	# ── Cyclone — Utility ─────────────────────────────────────────────────────
	115: "[b]Glitched[/b] hedefe +1 bonus hasar\n(taban +3)",
	119: "[b]Glitched[/b] süresi +1sn\n(taban 2sn)",
	131: "Her fırlatışın ilk vuruşu: +%5 hasar\n(taban +%15)",
	120: "[b]Glitched[/b] düşman hızı +%5\n(taban +%15)",
	133: "Ricochet Strike bonusu +1\n(taban 4 → 6)",
	158: "Kuzey duvar sekmesi: sonraki vuruş\n+%25 daha fazla (taban ×1.5)",
	148: "[b]Virus[/b] stack cap'i +1\n(taban 3 → 4)",
	150: "[b]Virus[/b] süresi +1 saniye\n(taban 3sn → 4sn)",
	152: "[b]Virus[/b] isabeti en yakın düşmana yayılır\nLv1: 75px/1, Lv2: 100px/1, Lv3: 125px/2 düşman",
	134: "Gereken sekme -1 (pierce kazanmak için)\nLv1: 5, Lv2: 4, Lv3: 3 sekme",
	139: "Phantom Circuit Core: sersemlenen\ndüşman sayısı +1 (taban 1)",
	140: "Phantom Circuit Core sersemletme süresi\nLv1: 0.75sn, Lv2: 1.0sn, Lv3: 1.5sn (taban 0.5sn)",
	151: "[b]Virus[/b]'lü hedef +%5 fazla hasar alır\nLv1: %15, Lv2: %20, Lv3: %25",
	222: "[b]Decay[/b] patlaması hasarı (stack başına)\nLv1: 3, Lv2: 5, Lv3: 7 (taban 2)",
	# ── Cyclone — Individuality ───────────────────────────────────────────────
	114: "Fırlatıştaki duvar sekmeleri, top dönene kadar\nher vuruşa +4 hasar ekler",
	145: "Öldürünce:\n+1 Can",
	121: "Data Leech +1 ekstra iyileştirir\nhedefte [b]Decay[/b] stack'i varsa",
	149: "[b]Glitched[/b] hedef 2× [b]Virus[/b]\nstack'i alır",
	116: "Sağ/sol duvar sekmesi sonrası\nilk vuruş: ×1.5 hasar",
	126: "Sahada 5+ [b]Glitched[/b] düşman varken:\ntüm hasarın +%20",
	136: "Tek fırlatışta 5 sekme: tüm Ricochet\nCore'lara kalıcı +1 hasar (sekme sayacı dönünce sıfırlanır)",
	141: "Sersemlemiş düşmana vuruş:\n×1.5 hasar",
	146: "Aynı fırlatışta 7 duvar sekmesi:\nkalıcı +%3 Core Speed",
	143: "Her 25. isabette: Avlu'daki tüm\ndüşmanlar 2sn [b]Glitched[/b] olur",
	154: "[b]Glitched[/b] düşmana [b]Virus[/b] uygulanınca\nmevcut stack ×2 olur",
	155: "Her [b]Virus[/b] tick'i:\n%5 ihtimalle hedef [b]Glitched[/b] olur",
	219: "[b]Decay[/b] patlaması tetiklenince:\n+2 HP kazan",
	220: "Dash sonrası 1.5sn hasar bağışıklığı\n(5sn bekleme süresi)",
	221: "Circuit Breaker sayacı\n2× hızlı dolar",
	# ── Herkese açık — Utility & Calamity ────────────────────────────────────
	11: "Tüm core'lara +1 hasar",
	224: "Zincir 5 halka uzar\n(hareket alanı genişler)",
	7:  "Hedeflenen noktaya 13 hasar verir\nve yakındaki düşmanlara [b]Electrified[/b] uygular",
	8:  "Hedeflenen alanda 3sn boyunca her 0.5sn'de\n4 hasar verir ve [b]Burning[/b] uygular",
	9:  "Düşmanları 5 sn boyunca merkeze doğru çeker.",
}


# ── Dinamik kart açıklamaları (runtime'da değişen sayılar) ───────────────────
# Sadece başka kartlarla değeri değişebilen kartlar burada match'lenir.
# BBCode kullanılır — [b]..[/b] ile güncel değer kalın gösterilir.
func _dynamic_desc(index: int, player: Node) -> String:
	var _bm: int = player.get("ball_mastery") if player.get("ball_mastery") != null else 0
	match index:
		66:  # Conduction
			var _crm: float = (player.electric_reaction_range_mult - 1.0) * 100.0 if player.get("electric_reaction_range_mult") != null else 20.0
			if locale == "en":
				return "Electric spread range +[b]%d[/b]%%\n(Plasma / Arc / Voltaic Core)" % int(round(_crm))
			return "Elektrik yayılma menzili +%[b]%d[/b]\n(Plasma / Arc / Voltaic Core)" % int(round(_crm))
		67:  # Hydro Pressure
			var _hpm: float = (player.hydro_pressure_mult - 1.0) * 100.0 if player.get("hydro_pressure_mult") != null else 20.0
			if locale == "en":
				return "Wet-applying cores are [b]%d[/b]%% faster\nLaunched: speed / Connected: orbit speed" % int(round(_hpm))
			return "Wet uygulayan core'lar %[b]%d[/b] hızlı\nFırlatılan: hız / Connected: orbit hızı" % int(round(_hpm))
		68:  # Arc Amplifier
			var _aat: int = player.arc_chain_targets if player.get("arc_chain_targets") != null else 2
			if locale == "en":
				return "Arc Core spreads to [b]%d[/b] more enemies" % (_aat - 1)
			return "Arc Core [b]%d[/b] düşmana daha yayar" % (_aat - 1)
		69:  # Static Charge
			var _scm: float = player.static_charge_mult * 100.0 if player.get("static_charge_mult") != null else 25.0
			if locale == "en":
				return "Electrified enemies transfer [b]%d[/b]%%\ndamage to each other" % int(round(_scm))
			return "Electrified düşmanlar birbirine\nhasarın %[b]%d[/b]'ini aktarır" % int(round(_scm))
		71:  # Supercooling
			var _csm: float = (player.cryo_slow_mult - 1.0) * 100.0 if player.get("cryo_slow_mult") != null else 15.0
			if locale == "en":
				return "Cryo Slow amount +[b]%d[/b]%%" % int(round(_csm))
			return "Cryo yavaşlatma miktarı +%[b]%d[/b]" % int(round(_csm))
		73:  # Thermal Vision
			var _bbd: int = player.burn_bonus_dmg if player.get("burn_bonus_dmg") != null else 1
			var _bft: bool = player.burn_fast_ticks if player.get("burn_fast_ticks") != null else false
			if locale == "en":
				return "[b]Burning[/b] tick damage +[b]%d[/b]" % _bbd + ("\nBurns every [b]1.5s[/b] (4 ticks)" if _bft else "")
			return "[b]Burning[/b] tick hasarı +[b]%d[/b]" % _bbd + ("\nHer [b]1.5sn[/b]'de vurur (4 tick)" if _bft else "")
		80:  # Arcane Mind
			var _fdm: float = player.first_debuff_duration_mult if player.get("first_debuff_duration_mult") != null else 7.0 / 6.0
			var _fds: int = int(round(6.0 * _fdm))
			if locale == "en":
				return "First applied element lasts\n[b]%d[/b]s instead of 6s" % _fds
			return "İlk uygulanan element 6 yerine\n[b]%d[/b] sn sürer" % _fds
		81:  # Resonance Engine
			var _rms: int = player.resonance_max_stacks if player.get("resonance_max_stacks") != null else 3
			if locale == "en":
				return "Reaction → +1 [b]Momentum[/b] stack\n(max [b]%d[/b], 3s each). Each stack: +2%% Core Speed" % _rms
			return "Reaksiyon → +1 [b]Momentum[/b] stack\n(maks [b]%d[/b], her biri 3sn). Her stack: +%%2 Core Speed" % _rms
		82:  # Frozen Time
			var _fzm: float = (player.freeze_duration_mult - 1.0) * 100.0 if player.get("freeze_duration_mult") != null else 25.0
			if locale == "en":
				return "[b]Frozen[/b] duration +[b]%d[/b]%%" % int(round(_fzm))
			return "[b]Frozen[/b] süresi +%[b]%d[/b]" % int(round(_fzm))
		83:  # Overheat
			var _oht: int = player.overheat_threshold if player.get("overheat_threshold") != null else 30
			if locale == "en":
				return "After [b]%d[/b] [b]Burning[/b] ticks:\nexplodes for 15 damage within 150px" % _oht
			return "[b]%d[/b] [b]Burning[/b] tick'i sonra:\n150px içine 15 hasarlık patlama" % _oht
		84:  # Elemental Harmony (Utility)
			var _ehb: float = player.elemental_harmony_util_bonus * 100.0 if player.get("elemental_harmony_util_bonus") != null else 3.0
			if locale == "en":
				return "Per unique active element:\n+[b]%.1f[/b]%% Core Speed" % _ehb
			return "Sahadaki her benzersiz aktif element için:\n+%[b]%.1f[/b] Core Speed" % _ehb
		89:  # Thermal Expansion
			var _ter: int = int(player.thermal_expansion_radius) if player.get("thermal_expansion_radius") != null else 100
			if locale == "en":
				return "Steam reaction radius: [b]%d[/b]px\nAlso applies [b]Wet[/b] to enemies in range" % _ter
			return "Buhar reaksiyonu menzili: [b]%d[/b]px\nAyrıca menzildeki düşmanlara [b]Wet[/b] uygular" % _ter
		90:  # Mana Overflow
			var _mod: float = player.mana_overflow_duration if player.get("mana_overflow_duration") != null else 4.0
			var _mom: float = (player.mana_overflow_mult - 1.0) * 100.0 if player.get("mana_overflow_mult") != null else 30.0
			if locale == "en":
				return "Using a Calamity: +[b]%d[/b]%% Core Speed\nfor [b]%d[/b]s" % [int(round(_mom)), int(_mod)]
			return "Calamity kullanınca: [b]%d[/b]sn boyunca\n+%[b]%d[/b] Core Speed" % [int(_mod), int(round(_mom))]
		102:  # Pyroblast
			var _pbm: int = int(player.pyroblast_mult) if player.get("pyroblast_mult") != null else 4
			if locale == "en":
				return "Overheat's explosion radius grows by\n[b]%d[/b]px per accumulated tick" % _pbm
			return "Overheat'in patlama yarıçapı, biriken\ntick başına [b]%d[/b]px büyür" % _pbm
		210:  # Cryo Burst
			var _cbb: int = player.cryo_burst_bonus if player.get("cryo_burst_bonus") != null else 4
			if locale == "en":
				return "Hits on a [b]Slowed[/b] enemy deal\n+[b]%d[/b] bonus damage" % _cbb
			return "[b]Slowed[/b] düşmana yapılan vuruşlar\n+[b]%d[/b] bonus hasar verir" % _cbb
		211:  # Arc Overload
			var _aot: int = player.arc_overload_targets if player.get("arc_overload_targets") != null else 1
			var _aod: int = player.arc_overload_dmg if player.get("arc_overload_dmg") != null else 4
			if locale == "en":
				return "Electrocute chains to [b]%d[/b] nearby\nenem%s for [b]%d[/b] damage" % [_aot, ("y" if _aot == 1 else "ies"), _aod]
			return "Electrocute yakındaki [b]%d[/b] düşmana\n[b]%d[/b] hasarlık zincir yapar" % [_aot, _aod]
		1:  # Electric Core
			var _dmg1: int = 9 + _bm + (player.get("electric_bonus") if player.get("electric_bonus") != null else 0)
			if locale == "en":
				return "[b]%d[/b] damage.\nApplies [b]Electrified[/b] to enemy" % _dmg1
			return "[b]%d[/b] hasar.\nDüşmana [b]Electrified[/b] uygular" % _dmg1
		64:  # Echo Core
			var _dmg64: int = 5 + _bm
			if locale == "en":
				return "[b]%d[/b] damage. Copies element from\ndebuffed enemy — applies it on return" % _dmg64
			return "[b]%d[/b] hasar. Debufflı düşmandan element\nkopyalar — dönüşte uygular" % _dmg64
		63:  # Arc Core
			var _dmg63: int = 6 + _bm
			var _act: int = 2 + (player.get("arc_chain_targets") if player.get("arc_chain_targets") != null else 1)
			if locale == "en":
				return "[b]%d[/b] damage. Applies [b]Electrified[/b].\nSpreads it to [b]%d[/b] nearby enemies" % [_dmg63, _act]
			return "[b]%d[/b] hasar. [b]Electrified[/b] uygular.\nYakındaki [b]%d[/b] düşmana yayılır" % [_dmg63, _act]
		190:  # Volatile Aura Core
			if locale == "en":
				return "On reaction trigger: deals a\n[b]2[/b] damage pulse to nearby enemies"
			return "Reaksiyon tetiklenince: yakındaki\ndüşmanlara [b]2[/b] hasarlık pulse"
		189:  # Echo Resonance Core
			if locale == "en":
				return "Every 5s: for 1s, spreads the last element\nyou applied ([b]Burning[/b]/[b]Wet[/b]/[b]Electrified[/b]/[b]Slowed[/b])\nto nearby enemies"
			return "Her 5sn: 1sn boyunca son uyguladığın\nelementi ([b]Burning[/b]/[b]Wet[/b]/[b]Electrified[/b]/[b]Slowed[/b])\nyakındaki düşmanlara yayar"
		187:  # Static Aura Core
			if locale == "en":
				return "Enemies that enter range get [b]Electrified[/b]\n(3s cooldown per enemy)"
			return "Menzile giren düşmanlar [b]Electrified[/b] olur\n(düşman başına 3sn CD)"
		186:  # Frost Aura Core
			if locale == "en":
				return "Enemies that enter range automatically\nget [b]Slowed[/b]"
			return "Menzile giren düşmanlar otomatik\nolarak [b]Slowed[/b] olur"
		185:  # Mist Core
			if locale == "en":
				return "Every 4s: applies [b]Wet[/b] to 1 enemy\nwithin range"
			return "Her 4sn: menzildeki 1 düşmana\n[b]Wet[/b] uygular"
		87:  # Voltaic Core
			var _dmg87: int = 8 + _bm
			if locale == "en":
				return "[b]%d[/b] damage. Applies [b]Electrified[/b].\nHitting an Electrified enemy chains damage (up to 3)" % _dmg87
			return "[b]%d[/b] hasar. [b]Electrified[/b] uygular.\nElectrified düşmana çarpınca hasar zincirlenir (3'e kadar)" % _dmg87
		78:  # Catalyst Core
			var _dmg78: int = 5 + _bm
			if locale == "en":
				return "[b]%d[/b] damage. Refreshes the duration of\nexisting [b]Burning[/b]/[b]Electrified[/b]/[b]Wet[/b]/[b]Slowed[/b] on hit" % _dmg78
			return "[b]%d[/b] hasar. İsabet ettiğinde mevcut\n[b]Burning[/b]/[b]Electrified[/b]/[b]Wet[/b]/[b]Slowed[/b] süresini tazeler" % _dmg78
		65:  # Prism Core
			if locale == "en":
				return "Stays in orbit. Every 2s: applies a random\nelement ([b]Burning[/b]/[b]Wet[/b]/[b]Electrified[/b]/[b]Slowed[/b]) to enemies in range"
			return "Orbit'te kalır. Her 2sn: menzildeki\ndüşmanlara rastgele element uygular ([b]Burning[/b]/[b]Wet[/b]/[b]Electrified[/b]/[b]Slowed[/b])"
		62:  # Steam Core
			var _dmg62: int = 5 + _bm
			if locale == "en":
				return "[b]%d[/b] damage. Applies [b]Wet[/b].\nLeaves a steam cloud → nearby enemies get [b]Wet[/b]" % _dmg62
			return "[b]%d[/b] hasar. [b]Wet[/b] uygular.\nBuhar bulutu bırakır → yakındaki düşmanlar [b]Wet[/b] olur" % _dmg62
		61:  # Plasma Core
			var _dmg61: int = 7 + _bm
			if locale == "en":
				return "[b]%d[/b] damage. Applies [b]Electrified[/b].\nDeals half damage to nearby [b]Electrified[/b] enemies" % _dmg61
			return "[b]%d[/b] hasar. [b]Electrified[/b] uygular.\nYakındaki [b]Electrified[/b] düşmanlara yarım hasar sıçratır" % _dmg61
		18:  # Pyro Core
			var _dmg18: int = 6 + _bm + (player.get("pyro_bonus") if player.get("pyro_bonus") != null else 0)
			if locale == "en":
				return "[b]%d[/b] damage.\nApplies [b]Burning[/b] to enemy" % _dmg18
			return "[b]%d[/b] hasar.\nDüşmana [b]Burning[/b] uygular" % _dmg18
		17:  # Hydro Core
			var _dmg17: int = 3 + _bm + (player.get("hydro_bonus") if player.get("hydro_bonus") != null else 0)
			if locale == "en":
				return "[b]%d[/b] damage.\nApplies [b]Wet[/b] to enemy" % _dmg17
			return "[b]%d[/b] hasar.\nDüşmana [b]Wet[/b] uygular" % _dmg17
		15:  # Cryo Core
			var _dmg15: int = 4 + _bm + (player.get("cryo_bonus") if player.get("cryo_bonus") != null else 0)
			if locale == "en":
				return "[b]%d[/b] damage.\nSlows enemy by 25%%. Freezes instead if\nenemy is already [b]Wet[/b]" % _dmg15
			return "[b]%d[/b] hasar.\nDüşmanı %%25 yavaşlatır. Düşman zaten\n[b]Wet[/b]se onun yerine dondurur" % _dmg15
		2:  # Pierce Core
			var _dmg: int = 5 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nPierces through unarmored enemies." % _dmg
			return "[b]%d[/b] hasar.\nZırhı olmayan düşmanı deşip geçer" % _dmg
		16:  # Glitch Core
			var _dmg16: int = 4 + _bm
			if locale == "en":
				return "[b]%d[/b] damage.\nApplies [b]Glitched[/b] to enemy for 2s" % _dmg16
			return "[b]%d[/b] hasar.\nDüşmana 2sn [b]Glitched[/b] uygular" % _dmg16
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
