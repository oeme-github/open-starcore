# Changelog – open-starcore

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/). Einzige dauerhafte Historie
erledigter Backlog-Punkte (siehe `dev-notes/STANDARDS.md` §3) — `BACKLOG.md` enthält nur noch
offene Punkte. Gepflegt laufend während der Arbeit, nicht erst am Session-Ende. Details zu
einzelnen Änderungen stehen zusätzlich in den (bewusst ausführlichen) Commit-Messages.

---

## [2026-09-28] — Viewer: Filter einklappbar, Einleitungstext im Header (D08)

### Added
- Viewer (PR #8): Filterzeilen per Knopf „Filter" ein-/ausklappbar; Suche und Karten/Matrix
  bleiben sichtbar, eingeklappt zeigt ein Zähler die aktiven Filter. Zustand pro Browser
  (`localStorage`). Nutzerwunsch.
- open-starcore_D08 (PR #9): optionaler Einleitungstext im Viewer-Header nach Vorbild der
  ursprünglichen Prozesskarte — Einzeiler (auch im Druck) plus aufklappbarer Kasten mit eigener
  Überschrift, Text mit Absätzen und `**fett**`, alles escaped. Migration
  `20260928100000_add_workgroup_einleitung.sql` (`workgroups.einleitung_kurz/_titel/_text`);
  Pflege im Editor unter „Einstellungen" (admin) ausschließlich über die security-definer-RPC
  `set_workgroup_einleitung` — `workgroups` behält bewusst keine Schreib-Policy.
- Editor (PR #10): Kurzanleitung zum Einleitungstext als eigene Kachel unter dem
  Einstellungen-Formular (Felder, erlaubte Formatierung, HTML-Tags erscheinen als Text,
  Beispiel). Ausgerollt auf alle drei Instanzen (`78bc33b`).
- Rollout auf alle drei `inabox`-Instanzen (`10d1dfd`): Migration zuerst, dann Code; je Instanz
  Titel, Ports, neue Spalten, REST und RPC-Ablehnung ohne Login geprüft.

---

## [2026-09-28] — Mouse-Over-Erläuterung (D07), Editor-Hilfeseite (D04)

### Added
- open-starcore_D07 (PR #5): optionale Erläuterung (`erlaeuterung`) an Dimensionen und
  Dimension-Werten, Migration `20260928090000_add_erlaeuterung.sql`. Der Editor pflegt sie im
  Dimensionsformular und pro Wertzeile. Der Viewer zeigt sie als Mouse-Over an Beschriftungen,
  Tabs, Chips, Badges und in der Matrix; Beschriftungen mit Erläuterung sind gepunktet
  unterstrichen. Kurz-Key-Badges fallen ohne Erläuterung auf das volle Label zurück.
  Nutzerwunsch: „Mouse-Over-Text für bestimmte Dimensionen".
- open-starcore_D04 (PR #7, ersetzt das versehentlich in den D07-Branch gemergte #6):
  Anwender-Anleitung `editor-db/hilfe.html` (eine Seite, druckbar), im Editor über „Hilfe"
  verlinkt — Rollen, Einträge, Mitglieder, Wirkung der Dimensionsfelder im Viewer, FAQ.
- Rollout auf alle drei `inabox`-Instanzen: Migration zuerst per `psql`, danach Code per
  `git stash`/`pull`/`stash pop`; Titel, Ports, Hilfeseite und neue Spalte je Instanz geprüft.
- open-starcore_D06: `supabase/README.md`, Abschnitt „Mehrfachbetrieb": jede Instanz braucht
  eine eigene Static-Unit (Dateiname, `WorkingDirectory`, Port), weil das per `nohup` aus
  `start.sh` gestartete Frontend keinen Reboot übersteht. Anlass: Kommunikationswege-Ausfall.

---

## [2026-09-28] — Backlog-Aufräumen, Patientenpfad-Instanz umgestellt (D03)

### Fixed
- Kommunikationswege-Frontend (Port 8097) war seit dem `inabox`-Reboot am 2026-09-27 nicht
  erreichbar: es lief nur per `nohup` aus `start.sh`, ohne systemd-Unit — das Backend kam über
  Dockers Restart-Policy zurück, das Frontend nicht. Neue Unit `kommunikationswege-static.service`
  (analog `prozesslandkarte-static.service`, `WorkingDirectory=/home/deploy/kommunikationswege`),
  aktiviert und verifiziert.

### Changed
- open-starcore_D03: AK-Patientenportale-Instanz („Patientenpfad") auf `inabox` vollständig auf
  `open-starcore` umgestellt. Ist-Stand war eine seit 2026-08-15 halb umgezogene Instanz:
  Frontend (8095, `prozesslandkarte-static.service`) und `supabase-db-1` liefen schon aus
  `~/open-starcore` (Stand `eac8242`), `rest`/`auth`/`mailpit` noch aus `~/app` (alter
  INA-Checkout, `c6078a5`). Statt eines dritten Klons ist `~/open-starcore` jetzt der einzige
  Checkout: auf `main` gebracht (PR #3/#4, `APP_TITLE` per Stash erhalten), Migration
  `20260904090000` per `psql` eingespielt, `.env` aus `~/app` übernommen (Werte identisch),
  `rest`/`auth`/`mailpit` aus `~/open-starcore/supabase` neu erzeugt (Volume `supabase_db-data`
  unverändert, 25 Einträge). `~/app` → `~/app.ina-alt` als Rückfallebene. Vorher DB-Sicherung
  `~/backups/patientenpfad_20260928_145127_vor-D03.sql.gz`.
  Auffälligkeit: beim `git pull` in `~/open-starcore` verschwand die untracked
  `supabase/.env` (Ursache ungeklärt, Inhalt vorher als `.env.bak` gesichert).
- `BACKLOG.md` auf offene Punkte verschlankt, erledigte Einträge (Session 2026-09-04,
  open-starcore_D02, open-starcore_F01) hierher verschoben. Dieses Changelog wird ab jetzt aktiv
  gepflegt (vorher: expliziter Verzicht-Vermerk, Historie nur in `BACKLOG.md`).
- `open-starcore_F02` in `open-starcore_D05` umbenannt — das Präfix `F` steht in diesem Repo für
  die Tabelle „Offene Fragen", der Punkt (Entra-ID-SSO aktivieren) ist aber eine Aufgabe.

### Added
- `open-starcore_D05` (vormals `open-starcore_F02`): Institutionelles SSO über Microsoft Entra ID
  aktivieren, aus `INA-ePA-und-Patientenportale` T10 übernommen. Wartet auf App-Registrierung im
  Tenant der Organisation.

---

## [2026-09-04] — Hub-Onboarding, Kommunikationswege-Instanz, dynamische Viewer-Filter

### Added
- Onboarding ins Hub-System (`dev-notes`): Repo auf der Devbox geklont, `BACKLOG.md`/
  `CHANGELOG.md` angelegt, `CLAUDE.md` um Hub-Zugehörigkeit ergänzt.
- Dritte Instanz „Kommunikationswege" auf `inabox.lan` aufgesetzt und mit Erstdaten aus Excel
  befüllt (17 Use-Cases), Initiator-Dimension nachträglich ergänzt (Details: `BACKLOG.md`,
  Abschnitt „Instanzen auf `inabox.lan`").
- PR #3: dynamische Viewer-Filter pro Dimension (`ist_filterbar`, Migration `20260904090000`)
  plus genereller Fix der Freitextsuche. Ausgerollt auf `euviaio-ausfallszenarien` und
  `kommunikationswege` (Migration eingespielt, Code aktualisiert, Branding-Diffs sauber neu
  angewendet). `~/app` bewusst ausgelassen, siehe open-starcore_D03.
- `supabase/README.md`: Filterbar-Feld ergänzt, Unterschied Navigationsachse/Filterbar erklärt.

### Changed
- open-starcore_D02: `CLAUDE.md` auf das aktuelle `@`-Import-Muster umgestellt (Abschnitt
  „Automatisch geladene Dateien (via `@`-Import)" für `BACKLOG.md`/`CHANGELOG.md`/`README.md`/
  `dev-notes/projects/open-starcore.md`/`dev-notes/STANDARDS.md`, analog zu `handbuch-wiki`/
  `ird-projektplan`); redundante Prosa in „Hub-Zugehörigkeit" entfernt.

### Fixed
- PR #4 (Nachbesserung aus Nutzer-Praxistest von PR #3): Matrix-Ansicht berücksichtigte
  Toolbar-Filter/Phase-Tab bisher gar nicht (nur Freitextsuche) — gefilterte Einträge werden jetzt
  auch dort gedimmt. Editor: eine Navigationsachse auf einer `text`-Dimension ließ diese komplett
  aus dem Viewer verschwinden — gleiche Typ-Sperre wie bei Filterbar ergänzt. Ausgerollt auf
  `euviaio-ausfallszenarien` und `kommunikationswege` (reiner Code, keine Migration).

### Decided
- open-starcore_F01 (Instanz-Ports in `dev-notes/PORTS.md` erfassen?): Nein.
  `dev-notes/ops/server-landschaft.md` führt `inabox` bereits als „außerhalb des Modells" (kein
  euviaio-Verbund, keine Dev→Staging-Port-Formel) — die PORTS.md-Staging-Abschnitte passen nur zu
  diesem Verbund-Muster. Instanz-Ports stattdessen in `BACKLOG.md` („Instanzen auf `inabox.lan`")
  dokumentiert; veralteter Quellverweis in `server-landschaft.md` auf `open-starcore` korrigiert.
- open-starcore_D01 (HTTPS/Reverse-Proxy) bestätigt als bewusst zurückgestellt: bleibt
  Heimnetz-only, kein konkreter Anlass für Fernzugriff.

---

## [2026-08-15] — Ausgliederung

### Added
- Ausgliederung aus `INA-ePA-und-Patientenportale` (PR #57 dort, per `git filter-repo` mit voller
  Historie). Zwei Instanzen produktiv auf `inabox.lan`: AK-Patientenportale (Branding
  „Patientenpfad") und `euviaio`-Ausfallszenarien (Branding „Euviaio Ausfallszenarien", eigene
  Ports/`COMPOSE_PROJECT_NAME`). Reboot-Test mit beiden Instanzen gleichzeitig erfolgreich.
