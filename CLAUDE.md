# CLAUDE.md – open-starcore

## Hub-Zugehörigkeit

Dieses Projekt ist Teil des `dev-notes`-Hub-Systems (`~/git_repos/dev-notes`,
`dev-notes/STANDARDS.md` §1–§4) — Session startet dort, Übergabe am Ende dorthin. Die relevanten
Hub-/Projektdateien werden automatisch per `@`-Import geladen, siehe Abschnitt „Automatisch
geladene Dateien" ganz unten.

**Abweichung vom Hub-Standard (bewusst, geerbt von `INA-ePA-und-Patientenportale`, aus dem
dieses Repo ausgegliedert wurde):** `dev-notes/STANDARDS.md` verlangt global englische
Commit-Messages — dieses Repo (wie sein Ursprungsrepo) committet bewusst auf Deutsch, siehe
unten. Nicht ohne Rücksprache angleichen.

## Sprache
Alle Ausgaben, Commit-Messages, Kommentare und Dokumente auf Deutsch.

---

## Worum geht es

Siehe `README.md` für die Kurzfassung. Kern: ein generisches
Dimensionen-Datenmodell (`workgroups` → `dimensions`/`dimension_values` →
`process_steps`/`process_step_values`), nicht an einen bestimmten
Anwendungsfall gebunden. Neue Anwendungsfälle bekommen eine eigene
Workgroup mit eigenen Dimensionen — kein Codeänderung im Viewer/Editor
nötig, siehe `supabase/README.md`, Abschnitt „Erste Workgroup anlegen".

**Interne Bezeichner bewusst nicht umbenannt:** Die Kern-Tabelle heißt
weiterhin `process_steps` (Herkunft: erster Anwendungsfall, eine
Prozesslandkarte) — taucht nirgends in der UI auf, nur in Migrationen/
RLS-Policies/RPCs/Embed-Query-Strings in `viewer-db`/`editor-db`. Sichtbarer
UI-Text spricht generisch von „Einträgen".

---

## Entwicklungsumgebung

Gemeinsame Devbox-Umgebung (OS/Hardware/Migrationsgeschichte): siehe `dev-notes/REPOS.md`
(„Speicherorte") — autoritative Quelle, hier bewusst nicht dupliziert (siehe
`dev-notes/STANDARDS.md` §3, „Single Source of Truth für Infra-Fakten").

- **Projektpfad (Devbox):** `~/git_repos/open-starcore`
- **Versionskontrolle:** Git, Remote auf GitHub (`github.com/oeme-github/open-starcore`)

## Dateien

- `supabase/` — Postgres + PostgREST + GoTrue (Docker Compose),
  Schema-Migrationen, Start-/Stop-Skripte. Siehe `supabase/README.md` für
  alle Details.
- `viewer-db/index.html` — Viewer (nur Darstellung/Filter/Export)
- `editor-db/index.html` — Editor (Einträge, Dimensionen, Mitglieder)
- `shared/auth.js` — gemeinsamer Login (Magic-Link + Passwort-Fallback,
  SSO-Scaffolding für Microsoft Entra ID), von beiden Frontends per
  `<script src="../shared/auth.js">` eingebunden

**Wichtig für lokale Tests:** Viewer/Editor müssen aus dem
Projekt-Wurzelverzeichnis heraus per Webserver bereitgestellt werden (nicht
aus ihrem eigenen Unterordner), da beide `../shared/auth.js` referenzieren.

**Branding pro Deployment:** `APP_TITLE`-Konstante am Anfang von
`viewer-db/index.html`/`editor-db/index.html` (analog zu
`GOTRUE_URL`/`REST_URL`) — jede Instanz setzt hier ihren eigenen
Produktnamen.

## Häufige Befehle
```bash
# Alles starten (idempotent)
./supabase/start.sh

# Stoppen (Daten bleiben erhalten)
./supabase/stop.sh

# Stoppen mit komplettem Reset
./supabase/stop.sh --wipe-data
```

---

## Git-Workflow

- Nie direkt in `main` pushen (Ausnahme: reine Doku-Nachträge ohne
  Code-/Datenänderung — dort ist ein Direkt-Push auf `main` in Ordnung)
- Feature-Branches: `feature/thema`, `fix/thema`
- Ein Commit pro sinnvoller Arbeitseinheit
- Commit-Format: `Bereich: Was und warum`
- Häufig committen und pushen — nicht erst am Ende einer Sitzung
- WIP-Commits bei unfertigem Stand: `WIP: Bereich – kurze Beschreibung was fehlt`
- Vor jedem Branch-Wechsel: `git status` prüfen, nie mit uncommitted Changes wechseln

---

## Allgemeine Regeln

- Keine neuen Dateien ohne expliziten Auftrag
- Änderungen am Datenmodell (Migrationen) immer mit dem Nutzer abstimmen,
  bevor umgesetzt wird — RLS-Policies/Trigger betreffen alle laufenden
  Instanzen, die von diesem Repo aus aktualisiert werden

---

## Automatisch geladene Dateien (via `@`-Import)

- @BACKLOG.md — **zuerst lesen**: letzter Stand, offene Punkte
- @CHANGELOG.md — expliziter Verzicht-Vermerk (dieses Projekt pflegt keins aktiv, siehe Datei)
- @README.md — Projektübersicht, Datenmodell-Kurzfassung
- @~/git_repos/dev-notes/projects/open-starcore.md — Hub-Projektkontext (letzter Stand,
  nächster Schritt, offene Fragen)
- @~/git_repos/dev-notes/STANDARDS.md — verbindlicher, projektübergreifender Arbeitsablauf
  (Hub-Regelwerk; externer Import außerhalb dieses Projekts — Claude Code zeigt beim allerersten
  Laden einen einmaligen Genehmigungsdialog, danach automatisch)

---

## Doku-Check (alle 4 Wochen)
Dedizierte Session zur Synchronisierung der Dokumentation mit dem tatsächlichen Projektstand:
- `CLAUDE.md` — nur noch projektspezifische Fakten hier; deckt sich der Rest noch mit
  `dev-notes/STANDARDS.md`?
- `README.md`/`supabase/README.md` — Features, Konfiguration, Installationsschritte
- `BACKLOG.md` — erledigte Einträge bereinigen, neue Erkenntnisse ergänzen; IDs auf
  `<repo>_<ID>`-Konvention prüfen und ggf. nachziehen (siehe `dev-notes/STANDARDS.md`) — inkl.
  Querverweise in `dev-notes/PROJECTS.md`/`dev-notes/projects/open-starcore.md`

Nächster Doku-Check: **2026-10-03**
