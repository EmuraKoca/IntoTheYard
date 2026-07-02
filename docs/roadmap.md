# IntoTheYard — Roadmap (2026-07-02)

Playtester (2026-07-02) ve Content Agent (2026-07-02) çıktıları ile mevcut bilinen
eksikler birleştirilerek oluşturulmuştur. MoSCoW öncelik + Epic gruplarına göre
3 sprint'lik plan.

---

## Backlog (MoSCoW Önceliklendirilmiş)

### Must Have (Yapılmadan yayına çıkılamaz)

| # | Görev | Epic |
|---|-------|------|
| M1 | Elemental Memory logic implement et (sadece flag var, duration logic yok) | Kart Sistemi |
| M2 | Volatile Mixture çift tetik riski test et + gerekirse guard ekle | Kart Balans |
| M3 | Living Storm + Static Charge sonsuz döngü riskini test et + kır | Kart Balans |
| M4 | Calamity Lightning & Flame tam test (hasar + durum efekti doğrulama) | Kart Balans |
| M5 | Leila reaksiyon zinciri tam test (Perfect Catalyst, Volatile Mixture, Catalyst Mind combo) | Kart Balans |
| M6 | v0.0.9.9f güncelleme notu yaz (Steam VFX, Vector kartları, balans değişiklikleri) | Dokümantasyon |
| M7 | Freeze VFX scale/pozisyon oyunda test et, karaktere göre ayarla | VFX / Görsel |
| M8 | Steam VFX scale/pozisyon tüm 7 düşman için test et | VFX / Görsel |

### Should Have (Bu sprint veya bir sonraki)

| # | Görev | Epic |
|---|-------|------|
| S1 | Pain Converter + Glass Engine + Adrenal Armor System 2.73× combo üst sınır kararı (cap veya nerf) | Kart Balans |
| S2 | Electrocute VFX sprite üret + implement et | VFX / Görsel |
| S3 | Melt VFX sprite üret + implement et | VFX / Görsel |
| S4 | Overheat VFX sprite üret + implement et | VFX / Görsel |
| S5 | Cyclone kart sayısını say, eksik varsa tamamla | Kart Sistemi |
| S6 | Fusion Zone kaldırılmasını güncelleme notlarına ekle (kayıt eksiği) | Dokümantasyon |
| S7 | Leila kart sinerjileri tam entegrasyon testi (reaksiyon zinciri, Volatile Mixture, Catalyst Mind, Perfect Catalyst) | Kart Balans |

### Could Have (Zaman kalırsa)

| # | Görev | Epic |
|---|-------|------|
| C1 | Overheat sayacı (_overheat_counter) per-enemy reset kontrolü | Kart Balans |
| C2 | Cards Unlocked ekranı unlock_bg.png bağlantısı (tekstür eksik) | UI / Görsel |
| C3 | Vector kart sayısı 37 → hedef sayı belirleme ve denge | Kart Sistemi |
| C4 | Yeni Vector kartları (Momentum Cascade vb.) oyun içi test | Kart Balans |
| C5 | Ally chance production değeri doğrulama (%3 mi yoksa test modu mu?) | Düşman Sistemi |

### Won't Have (Bu versiyon dışında)

| # | Görev | Not |
|---|-------|-----|
| W1 | Yeni karakter / karakter dengesi | v0.1.x'e ertelendi |
| W2 | Yeni düşman tipi | v0.1.x'e ertelendi |
| W3 | Multiplayer / co-op | Scope dışı |

---

## Epic Grupları

### Epic 1 — Kart Balans & Test
M2, M3, M4, M5, S1, S7, C1, C4

### Epic 2 — Kart Sistemi (Implement)
M1, S5, C3

### Epic 3 — VFX / Görsel
M7, M8, S2, S3, S4, C2

### Epic 4 — Dokümantasyon & Sürüm Notları
M6, S6

### Epic 5 — Düşman & Oyun Sistemi
C5

---

## Sprint Planı

### Sprint 1 — Stabilizasyon & Kritik Bugfix (2026-07-02 → 2026-07-09)

**Hedef:** Var olan içeriği oynabilir ve test edilebilir hale getir. Hiçbir kırık
mechanic kalmasın.

| Görev | Epic | Öncelik |
|-------|------|---------|
| M1 — Elemental Memory logic | Kart Sistemi | Must |
| M2 — Volatile Mixture çift tetik guard | Kart Balans | Must |
| M3 — Living Storm + Static Charge loop | Kart Balans | Must |
| M4 — Calamity Lightning/Flame test | Kart Balans | Must |
| M5 — Leila reaksiyon zinciri tam test | Kart Balans | Must |
| M7 — Freeze VFX scale/pos ayarı | VFX | Must |
| M8 — Steam VFX scale/pos tüm düşmanlar | VFX | Must |
| M6 — v0.0.9.9f güncelleme notu | Dokümantasyon | Must |

**Çıktı:** v0.0.9.9f kararlı build, tüm Must testler yeşil.

---

### Sprint 2 — İçerik Tamamlama & Görsel (2026-07-09 → 2026-07-16)

**Hedef:** Eksik VFX'leri kapat, kart dengesini son hale getir, Cyclone'u tamamla.

| Görev | Epic | Öncelik |
|-------|------|---------|
| S1 — Pain Converter combo cap kararı | Kart Balans | Should |
| S2 — Electrocute VFX | VFX | Should |
| S3 — Melt VFX | VFX | Should |
| S4 — Overheat VFX | VFX | Should |
| S5 — Cyclone kart sayısı tamamla | Kart Sistemi | Should |
| S6 — Fusion Zone kaldırma notu | Dokümantasyon | Should |
| S7 — Leila entegrasyon testi (tam) | Kart Balans | Should |
| C1 — Overheat sayacı per-enemy reset | Kart Balans | Could |
| C4 — Yeni Vector kartları oyun içi test | Kart Balans | Could |

**Çıktı:** v0.0.9.9g — tüm element VFX'ler mevcut, Cyclone tamamlanmış.

---

### Sprint 3 — Cilalama & v0.1 Hazırlık (2026-07-16 → 2026-07-23)

**Hedef:** Teknik borçları temizle, v0.1 için zemin hazırla, UI iyileştirmeleri.

| Görev | Epic | Öncelik |
|-------|------|---------|
| C2 — Cards Unlocked unlock_bg.png bağlantısı | UI | Could |
| C3 — Vector kart hedef sayısı & denge | Kart Sistemi | Could |
| C5 — Ally chance production kontrolü | Düşman Sistemi | Could |
| — Tam regresyon testi (tüm karakterler) | QA | — |
| — v0.1 scope belirleme toplantısı | Planlama | — |

**Çıktı:** v0.0.9.9h / v0.1-RC1, yayına hazır candidate.

---

## Notlar

- Commit mesajları Türkçe, format: `kısa özet + (gerekirse) madde listesi`
- Her sprint sonu güncelleme notları.txt güncellenecek
- VFX sprite'lar dışarıdan temin ediliyorsa Sprint 2 VFX görevleri kayabilir
- Cyclone kart havuzu sayımı yapılmadan Sprint 2 S5 başlatılamaz

---

_Son güncelleme: 2026-07-02 — PO Agent (claude-sonnet-4-6)_
