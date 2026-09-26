# IntoTheYard — SFX İhtiyaç Listesi (2026-09-25)

Öncelik: **P1** = oyun hissi için şart, **P2** = önemli, **P3** = cila.
Mevcut sesler: top isabeti (3), karakter silah ateşi (3), intro yağmur/gök gürültüsü, 3 müzik.
Aşağıdakilerin hiçbirinin sesi henüz yok. Arama anahtar kelimeleri (freesound / Kenney / OpenGameArt) parantez içinde.

---
## 1. MENÜ / UI

| #   | Olay                                                    | Öncelik | Arama                   |
| --- | ------------------------------------------------------- | ------- | ----------------------- |
| 1   | Buton hover (ana menü, pause, karakter seçimi, ayarlar) | P1      | ui hover, blip          |
| 2   | Buton tıklama / onay                                    | P1      | ui click, confirm       |
| 3   | Geri / iptal butonu                                     | P2      | ui back, cancel         |
| 4   | Çıkış butonu (pembe)                                    | P3      | power down              |
| 5   | Yeni Oyun onay penceresi açılışı (Evet/Hayır)           | P3      | ui warning              |
| 6   | Ayarlar sürgüsü kaydırma (tık tık)                      | P3      | slider tick             |
| 7   | Karakter seçimi: karakter değiştirme (sol/sağ)          | P2      | ui swipe, select        |
| 8   | Karakter seçimi: onay (Confirm)                         | P2      | ui start, confirm heavy |
| 9   | Chip COLLECT (milestone ödülü)                          | P2      | coin collect, reward    |
| 10  | Chip mağazası: satın alma / yetersiz bakiye             | P2      | purchase, error buzz    |
| 11  | Başarım / milestone tamamlandı                          | P2      | achievement unlock      |
| 12  | Credits ekranı açılışı                                  | P3      | ui open                 |

## 2. PAUSE / GENEL AKIŞ

| # | Olay | Öncelik | Arama |
|---|---|---|---|
| 13 | Oyunu duraklat (pause aç) | P2 | pause in |
| 14 | Devam et (pause kapat) | P2 | pause out |
| 15 | Run başlangıcı (sahaya giriş) | P2 | game start, whoosh |
| 16 | Game Over / ölüm ekranı | P1 | game over, defeat |
| 17 | Zafer / run bitişi (varsa) | P3 | victory jingle |

## 3. KART SEÇİM EKRANI (level-up)

| # | Olay | Öncelik | Arama |
|---|---|---|---|
| 18 | Level-up anı (menü açılırken) | P1 | level up, power up |
| 19 | Kartların ekrana gelişi (3 kart) | P2 | card deal, whoosh |
| 20 | Kart üzerinde gezinme (hover, büyüme animasyonu) | P1 | card hover, tick |
| 21 | Kart seçme (tıklama) | P1 | card select, confirm |
| 22 | Nadirlik sesleri: rare / epic / legendary kart geldiğinde farklı parıltı | P2 | rare item, sparkle, legendary |
| 23 | Keyword sözlüğü paneli (glossary) açılışı | P3 | tooltip |
| 24 | Kart alındıktan sonra menü kapanışı | P2 | menu close |
| 25 | Core kartı seçilince (yeni top eklendi) | P2 | equip, power up |
| 26 | Medkit / Max Health Up alınınca | P2 | heal, health pickup |

## 4. CALAMITY SİSTEMİ (genel)

| # | Olay | Öncelik | Arama |
|---|---|---|---|
| 27 | Calamity slotuna kart eklendi | P1 | item pickup, charge |
| 28 | Slot hover | P3 | ui hover |
| 29 | Slot tıklama / nişan modu açılış (hedefli Calamity) | P1 | target lock, aim |
| 30 | Nişan iptali (Escape) | P3 | cancel |
| 31 | Calamity ateşleme / tetikleme (genel onay sesi) | P1 | activate, trigger |
| 32 | Slot dolu, kart alınamadı | P3 | error, denied |
| 33 | Süreli buff bitişi (Full Breach, Momentum Burst, Bounce Barrage) | P2 | power down |
| 34 | **The Yard Engine**: makine yerden yükselir | P1 | machine rise, mechanical start |
| 35 | Yard Engine: elektrik çizgileri ateşlenir (bolt) | P1 | electric zap, arc |
| 36 | Yard Engine: makine yere gömülür | P2 | machine retract |

## 5. CALAMITY — VECTOR (7)

| # | Kart | Ses ihtiyacı | Arama |
|---|---|---|---|
| 37 | Gravitational Force | Vorteks açılış + 5sn süren düşük uğultu (loop) + kapanış | gravity well, black hole hum |
| 38 | Shockwave | Geniş şok dalgası patlaması | shockwave, explosion boom |
| 39 | Full Breach | Armor kırılma + güç yükselişi; 8sn aktifken hafif enerji loop'u (opsiyonel) | armor break, power surge |
| 40 | Momentum Burst | Hızlanma / elektriklenme (silah üzerinde kıvılcım loop'u, 10sn) | speed boost, electric crackle |
| 41 | Rampart Collapse | Şarj toplanması → fırlatma → çarpma patlaması (3 aşama) | charge up, projectile launch, impact explosion |
| 42 | WormHole | Portal açılış + emme (düşmanlar çekilirken) + kapanış | portal open, suction, warp |
| 43 | Siege Rain | 14 kez meteor düşüşü (kısa varyasyonlar, 3-4 farklı) + çarpma | meteor fall, impact, rumble |

## 6. CALAMITY — LEILA (8)

| # | Kart | Ses ihtiyacı | Arama |
|---|---|---|---|
| 44 | Lightning | Şimşek çakması + gök gürültüsü | lightning strike |
| 45 | Flame Zone | Alev alanı açılış + 3sn yanma loop'u | fire ignite, flame burst |
| 46 | Freezing Cold | Hortum girişi + süpürme rüzgarı (loop) + donma | blizzard wind, ice freeze |
| 47 | Monsoon | Yağmur başlangıcı (tüm saha) | rain, downpour |
| 48 | EMP Pulse | EMP patlaması + her isabet alan düşmanda şimşek | emp pulse, electric discharge |
| 49 | Volcanic Rift | Yer yarılması + lav erüpsiyonu (4sn) | volcano eruption, lava |
| 50 | Thunderstorm | 5sn boyunca her saniye 2 şimşek (kısa varyasyonlar) | thunder crack |
| 51 | Wildfire | Yanan düşmanlar patlar (küçük patlamalar, çoklu) | fire explosion, ignite |

## 7. CALAMITY — CYCLONE (8)

| # | Kart | Ses ihtiyacı | Arama |
|---|---|---|---|
| 52 | Data Storm | Glitchli düşmanlarda dijital bozulma patlaması (her düşmanda) | glitch burst, digital corruption |
| 53 | Backdoor | Sisteme sızma + herkes Glitch | hack, system breach |
| 54 | Bounce Barrage | Silah elektriklenmesi + 5sn hız loop'u | electric charge, overdrive |
| 55 | Mirror Image | 2 bonus core belirişi (kopyalanma) | clone, mirror shimmer |
| 56 | Systemic Failure | Herkese max Virus (yeşil) | virus infect, toxic |
| 57 | Glitch Field | Glitch alanı açılış + 3sn loop | glitch field, static hum |
| 58 | System Crash | Glitchli düşmanlardan makineye akış + çöküş | system crash, error |
| 59 | Decay Field | Çürüme alanı 5sn loop + Decay patlaması (ölümde) | decay, rot, corrosion |

## 8. TOP (CORE) SESLERİ

Mevcut: silah ateşi (3 karakter), isabet (classic/elemental/heavy).

| # | Olay | Öncelik | Arama |
|---|---|---|---|
| 60 | Duvar sekmesi (arena duvarı) | P1 | ball bounce wall |
| 61 | Top dönüşü / yakalama (oyuncuya geri gelme) | P2 | catch, return whoosh |
| 62 | Kritik vuruş | P2 | critical hit |
| 63 | Pierce Core: düşmandan geçme | P3 | pierce, slice |
| 64 | Armor Core / Bulwark: Armor kazanımı | P2 | shield gain, armor up |
| 65 | Crusher Core: zırh kırma | P2 | armor break, shatter |
| 66 | Anchor Core: yavaşlatma vuruşu | P3 | heavy thud |
| 67 | Kinetic / Siege: ağır vuruş | P3 | heavy impact |
| 68 | Electric / Plasma / Arc / Voltaic: elektrik zinciri sıçrama | P2 | electric arc, zap chain |
| 69 | Steam Core: buhar bulutu | P3 | steam hiss |
| 70 | Cryo / Frost: buz vuruşu | P2 | ice hit |
| 71 | Pyro: yanma vuruşu | P2 | fire hit |
| 72 | Scatter Core: 3 parçaya bölünme | P2 | split, shatter |
| 73 | Echo Core: element kopyalama | P3 | echo, copy |
| 74 | Connected Core dart saldırısı (yörüngedeki core düşmana atılır) | P2 | dart, quick strike |
| 75 | Phantom Circuit / Ricochet: özel sekme | P3 | ricochet |
| 76 | Yeni core kuyruğa eklendi / launcher'a yüklendi | P3 | reload, click |
| 77 | Launcher hazır/boş | P3 | empty click |

## 9. DURUM EFEKTLERİ (düşmana uygulanınca)

| # | Efekt | Öncelik | Arama |
|---|---|---|---|
| 78 | Burning uygulandı (+ yanma tik'leri) | P2 | ignite, fire crackle |
| 79 | Wet uygulandı | P3 | water splash |
| 80 | Electrified uygulandı | P2 | electric shock |
| 81 | Slowed uygulandı | P3 | slow down |
| 82 | Frozen uygulandı (donma) | P1 | freeze, ice crack |
| 83 | Frozen bitişi / kırılma | P2 | ice shatter |
| 84 | Glitched uygulandı | P2 | glitch short |
| 85 | Virus tik'i (yeşil hasar) | P3 | toxic tick |
| 86 | Decay stack | P3 | decay |
| 87 | Mark (Rogue's Eye işareti) | P3 | target mark |

## 10. ELEMENT REAKSİYONLARI (Leila)

| # | Reaksiyon | Öncelik | Arama |
|---|---|---|---|
| 88 | Electrocute (Electric+Wet) | P1 | electrocute, zap |
| 89 | Steam (Burning+Wet) | P1 | steam explosion |
| 90 | Cryostatic (Cryo+Wet/Electric) | P2 | ice burst |
| 91 | Shatter (Electric+Frozen) | P1 | glass shatter |
| 92 | Melt (Burning+Slowed) | P2 | melt, sizzle |
| 93 | Overheat (yanan düşman sayacı dolunca patlama) | P1 | overheat explosion |
| 94 | Overcharge (Volatile/Overcharge Core pulse) | P3 | energy pulse |

## 11. DÜŞMANLAR

Düşman tipleri: subject, armed_subject, frantic_subject, heavy_subject, cyber_shotgun, cyber_shooter, cyber_rifle. Boss: Cyber-404, S-Miler-79, Nyx-09.

| # | Olay | Öncelik | Arama |
|---|---|---|---|
| 95 | Düşman spawn (sahaya giriş) | P3 | enemy spawn |
| 96 | Düşman vuruş alma (temel) | P2 | hit flesh, body hit |
| 97 | Düşman ölümü — normal (temel ölüm) | P1 | enemy death, body fall |
| 98 | Düşman ölümü — brutal (Decay ölümü) | P2 | gore, splat |
| 99 | Düşman ölümü — yanarak | P2 | burn death |
| 100 | Düşman ölümü — donarak | P2 | ice death |
| 101 | Düşman ölümü — elektrikle | P2 | electric death |
| 102 | Heavy subject: zırhlı vuruş (metalik) | P2 | metal clang |
| 103 | Cyber shooter / rifle / shotgun: ateş | P1 | laser shot, rifle, shotgun |
| 104 | Düşman mermisi oyuncuya çarpar | P2 | bullet hit |
| 105 | Frantic subject: koşuş / saldırı | P3 | swing, hit |
| 106 | Melee düşman oyuncuya vurur | P1 | punch, melee hit |
| 107 | Glitchli düşman dövüşü (düşmana vuruş) | P3 | glitch hit |
| 108 | Ceset solup yok olması | P3 | fade out |
| 109 | WormHole ile yutulan düşman | P2 | warp, vanish |

## 12. BOSS

| # | Olay | Öncelik | Arama |
|---|---|---|---|
| 110 | Boss girişi / sahne müziği geçişi (bossSceneTheme zaten var, kodda bağlı değil) | P1 | boss intro, warning siren |
| 111 | Cyber-404: özel saldırı sesleri (armor, ateş) | P2 | robot, laser |
| 112 | S-Miler-79: saldırı sesleri | P2 | boss attack |
| 113 | Nyx-09: saldırı + bolt çakması (`_bolt_flash`) | P2 | electric boss |
| 114 | Boss hasar alma | P2 | boss hit |
| 115 | Boss ölümü | P1 | boss death, big explosion |

## 13. OYUNCU

| # | Olay | Öncelik | Arama |
|---|---|---|---|
| 116 | Hasar alma (beyaz flaş anı) | P1 | player hurt |
| 117 | Armor hasar emer | P2 | shield hit |
| 118 | Armor tamamen sıfırlandı (Momentum Transfer tetikleme) | P2 | armor break big |
| 119 | Armor kazanımı (Regen Pulse, Anchor Pulse vb.) | P3 | shield recharge |
| 120 | HP iyileşme (Bloodwall, Data Leech, Medkit) | P2 | heal |
| 121 | Düşük can uyarısı (kalp atışı loop'u, HP ≤ %30) | P1 | heartbeat |
| 122 | Ölüm | P1 | player death |
| 123 | Dash | P2 | dash whoosh |
| 124 | Yürüme adımları (opsiyonel) | P3 | footsteps |
| 125 | Momentum stack kazanımı / kaybı (Vector) | P3 | tick |
| 126 | Vector: Full Breach hasar çarpanı aktifken isabet | P3 | powered hit |
| 127 | Shock Reflex kaçınma / Frost Barrier kalkan | P3 | shield, dodge |
| 128 | Auto-mod aç/kapa | P3 | toggle |

## 14. ORTAM / AMBIYANS

| # | Olay | Öncelik | Arama |
|---|---|---|---|
| 129 | Avlu (Yard) ortam sesi: uzak kalabalık, şehir uğultusu | P2 | ambience, city crowd |
| 130 | Tribün / cadde ambiyansı | P3 | stadium crowd |
| 131 | Menü ortam sesi (opsiyonel) | P3 | menu ambience |
| 132 | Intro sahnesi ek sesleri (rainThunder zaten var) | P3 | — |

---
## Özet
- **Toplam ~132 olay**. P1 (şart): yaklaşık 30, P2: ~55, P3: kalanı.
- **Önce şunlar**: UI hover/click, kart hover/select, level-up, düşman ölümü, oyuncu hasarı, duvar sekmesi, Yard Engine, Frozen, 3 reaksiyon patlaması (Steam/Shatter/Overheat), Game Over.
- Calamity başına ihtiyaç: 22 kart × ortalama 1-3 ses.
- **Loop gereken sesler**: Gravitational Force, Flame Zone, Freezing Cold, Glitch Field, Decay Field, Bounce Barrage/Momentum Burst kıvılcımı, düşük can kalp atışı, Yard ambiyansı.
- **Aynı sesten farklı varyasyon iste** (2-4 adet): duvar sekmesi, düşman ölümü, isabet, meteor düşüşü — tekrar hissi azalır.
- Ses formatı: `.ogg` (oyunda mevcut olanlar gibi).
- Lisans: CC0 tercih, CC BY seçersen credits ekranına (`main_menu.gd::_on_credits` içindeki `lines` listesi) eklenmeli.
