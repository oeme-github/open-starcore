# Backlog – open-starcore

## Letzter Stand

**Zuletzt abgeschlossen:** Ausgliederung aus `INA-ePA-und-Patientenportale` (PR #57 dort, per
`git filter-repo` mit voller Historie, 2026-08-15/2026-09-04 gemergt). Zwei Instanzen produktiv
auf `inabox.lan`: die ursprüngliche AK-Patientenportale-Instanz (Branding „Patientenpfad") und
eine zweite, unabhängige Instanz für `euviaio`-Ausfallszenarien (Branding „Euviaio
Ausfallszenarien", eigene Ports/`COMPOSE_PROJECT_NAME`). Reboot-Test mit beiden Instanzen
gleichzeitig erfolgreich.

### Abgeschlossen in dieser Session
- Repo geklont, Onboarding ins Hub-System (`dev-notes`)
- open-starcore_F01 geklärt (Instanz-Ports bleiben in diesem Repo statt in `dev-notes/PORTS.md`,
  siehe Abschnitt „Instanzen auf inabox.lan" oben); veralteter Quellverweis in
  `dev-notes/ops/server-landschaft.md` korrigiert
- open-starcore_D01 bestätigt: bleibt vorerst Heimnetz-only, kein Umsetzungsbedarf heute
- Dritte Instanz „Kommunikationswege" auf `inabox.lan` aufgesetzt und mit Erstdaten aus Excel
  befüllt (17 Use-Cases), siehe Abschnitt „Instanzen auf inabox.lan" unten
- open-starcore_D02 erledigt (`@`-Import-Muster in CLAUDE.md)
- Initiator-Dimension bei Kommunikationswege ergänzt
- PR #3 (dynamische Viewer-Filter pro Dimension, `ist_filterbar` + generischer Such-Fix)
  geplant, umgesetzt, lokal verifiziert, gemergt und auf `euviaio-ausfallszenarien` +
  `kommunikationswege` ausgerollt (Migration `20260904090000` eingespielt, Code aktualisiert,
  Branding-Diffs sauber neu angewendet). `~/app` dabei bewusst ausgelassen, siehe
  open-starcore_D03

---

## Entwicklung & Infrastruktur

| ID | Aufgabe | Priorität | Status |
|----|---------|-----------|--------|
| open-starcore_D01 | Kein HTTPS/Reverse-Proxy vor den `inabox.lan`-Instanzen — für reinen Heimnetz-Zugriff aktuell akzeptabel, vor Fernzugriff/AG-Freigabe zu klären | Mittel | 📋 Offen (2026-09-04 bestätigt: bleibt vorerst Heimnetz-only, kein konkreter Anlass für Fernzugriff) |
| open-starcore_D02 | CLAUDE.md nutzt noch nicht das aktuelle `@`-Import-Muster für `dev-notes/STANDARDS.md` (Muster geerbt von `INA-ePA-und-Patientenportale`, vordatiert die Konvention) — bei Gelegenheit auf aktuelles Template angleichen | Niedrig | ✅ Erledigt (2026-09-04) — Abschnitt „Automatisch geladene Dateien (via `@`-Import)" ergänzt (`BACKLOG.md`/`CHANGELOG.md`/`README.md`/`dev-notes/projects/open-starcore.md`/`dev-notes/STANDARDS.md`), analog zu `handbuch-wiki`/`ird-projektplan`; redundante Prosa in „Hub-Zugehörigkeit" entfernt |
| open-starcore_D03 | `~/app` (AK-Patientenportale-Checkout auf `inabox`) wurde bei der Ausgliederung nie auf `open-starcore` umgestellt — Remote zeigt noch auf `INA-ePA-und-Patientenportale`, eingefroren bei Commit `c6078a5` (vor PR #57), keine `APP_TITLE`-Konstante. Bekommt dadurch keine post-Split-Verbesserungen (z.B. PR #3, dynamische Viewer-Filter) ab — eigene Migration nötig (Remote umstellen, Datenstand/Migrationshistorie abgleichen), kein einfacher `git pull` | Mittel | 📋 Offen (2026-09-04 entdeckt beim Rollout-Versuch von PR #3) |

---

## Instanzen auf `inabox.lan`

Betriebs-Port-Registry für die beiden produktiven Instanzen (Host: VM `inabox`, Debian 13,
Proxmox, Heimnetz des Nutzers, `192.168.1.102`/`inabox.lan`). Ports kollidieren nur
untereinander, nicht mit anderen Projekten auf anderen Hosts — deshalb hier statt in
`dev-notes/PORTS.md` erfasst (siehe Entscheidung zu F01 unten).

| Instanz | Branding (`APP_TITLE`) | `DB_PORT` | `REST_PORT` | `AUTH_PORT` | `MAILPIT_PORT` | `STATIC_PORT` |
|---|---|---|---|---|---|---|
| AK-Patientenportale | „Patientenpfad" | 5435 | 8001 | 9999 | 8026 | 8095 |
| euviaio-Ausfallszenarien | „Euviaio Ausfallszenarien" | 5436 | 8002 | 9998 | 8027 | 8096 |
| Kommunikationswege (Arbeitstitel) | „Kommunikationswege" | 5437 | 8003 | 9997 | 8028 | 8097 |

(Defaults aus `supabase/README.md`, Abschnitt „Ports"; jede weitere Instanz zählt die Ports um
+1 hoch über `.env`.)

### Kommunikationswege (angelegt 2026-09-04)

Neuer Anwendungsfall: Kommunikationswege zwischen Patienten/Mitarbeitenden/externen Profis
(Krankenhaus-Kontext), Erstdaten aus `Use-Cases_Kommunikation_kommentiert.xlsx` (17 Use-Cases,
10 Kategorien). Checkout `~/kommunikationswege` auf `inabox`, Workgroup-Key
`kommunikationswege`, Admin-Login `admin@kommunikationswege.local` (Passwort in KeePass des
Nutzers).

**Dimensionen:** `phase` (vor/während/nach Aufenthalt, Navigationsachse — Nutzerentscheidung:
zeitliche Trennung statt/zusätzlich zur Akteurs-Paarung), `kommunikationsweg` (Patient↔Mitarbeitende
/ Mitarbeitende↔Mitarbeitende / Mitarbeitende↔Externe Profis — die urspr. angefragte 3er-Einteilung,
jetzt zweite Achse statt Tab-Leiste), `kategorie` (die 10 Excel-Kategorien), `use_case_id`,
`beteiligte`, `beschreibung` (alle drei text, 1:1 aus Excel), `kanal_praeferiert`/`kanal_alternativ`
(aus den beiden Kanal-Spalten; Tippfehler „Portalle" zu „Portale" normalisiert).

**Phase/Kommunikationsweg sind ein Erstvorschlag des Modells, kein Excel-Feld** — im Editor prüfen,
besonders Use-Case 4.1 (Beteiligte: „Krankenhaus-Kliniksystem → Patient/Nachsorger", als
Patient↔Mitarbeitende vorklassifiziert, Nachsorger-Anteil eigentlich extern) und 5.1 (Beteiligte:
„Patient/Zuweiser ↔ Krankenhaus", Zuweiser-Anteil eigentlich Mitarbeitende↔Extern).

**Nachtrag 2026-09-04:** Initiator-Dimension ergänzt (Kommentar von Anna-Antonia Pape an Spalte
„Beteiligte", s.o.) — neue Dimension `initiator` (text, Reihenfolge 6, direkt nach „Beteiligte"),
noch ohne Werte (wie bei den bestehenden Use-Cases üblich, erst bei Bedarf befüllen). Die beiden
leeren „Lücken sind vorhanden"-Punkte aus der Excel wurden dagegen verworfen — der Nutzer hat
stattdessen selbst drei neue Dimensionen `ist`/`soll`/`gap` (Ist-Zustand/Soll-Zustand/Lücke
Ist-Soll) angelegt und exemplarisch bei Use-Case 1.1 befüllt; weitere Use-Cases folgen bei
Bedarf direkt im Editor.

## Offene Fragen / Entscheidungen

| ID | Frage | Status |
|----|-------|--------|
| open-starcore_F01 | Sollen Ports einzelner Instanzen in `dev-notes/PORTS.md` erfasst werden? | ✅ Geklärt (2026-09-04): Nein. `dev-notes/ops/server-landschaft.md` führt `inabox` bereits explizit als „außerhalb des Modells" (kein euviaio-Verbund, keine Dev→Staging-Port-Formel wie bei `netcup`/`stagingbox`) — die dortigen PORTS.md-Staging-Abschnitte passen nur zu diesem Verbund-Muster. Instanz-Ports stattdessen oben in diesem Repo dokumentiert; veralteter Quellverweis in `server-landschaft.md` (zeigte noch auf `INA-ePA-und-Patientenportale`) auf `open-starcore` korrigiert. |

---

## Zurückgestellt

*(keine)*

---

## Abgelehnte Features

*(keine)*
