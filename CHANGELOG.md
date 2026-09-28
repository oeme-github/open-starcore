# Changelog – open-starcore

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/). Einzige dauerhafte Historie
erledigter Backlog-Punkte (siehe `dev-notes/STANDARDS.md` §3) — `BACKLOG.md` enthält nur noch
offene Punkte. Gepflegt laufend während der Arbeit, nicht erst am Session-Ende. Details zu
einzelnen Änderungen stehen zusätzlich in den (bewusst ausführlichen) Commit-Messages.

---

## [2026-09-28] — Backlog-Aufräumen, Patientenpfad-Instanz umgestellt (D03)

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
