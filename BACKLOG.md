# Backlog – open-starcore

## Letzter Stand

**Zuletzt abgeschlossen:** Backlog-Aufräumen (2026-09-28) — erledigte Punkte ins `CHANGELOG.md`
verschoben (einzige dauerhafte Historie, siehe `dev-notes/STANDARDS.md` §3),
`open-starcore_F02` → `open-starcore_D05` umbenannt. open-starcore_D03 erledigt: Patientenpfad-Instanz
läuft vollständig aus `~/open-starcore` (Details `CHANGELOG.md`). Kommunikationswege-Frontend (8097)
nach Reboot-Ausfall mit eigener Static-Unit reboot-fest gemacht, Folgepunkt open-starcore_D06.

---

## Entwicklung & Infrastruktur

| ID | Aufgabe | Priorität | Status |
|----|---------|-----------|--------|
| open-starcore_D01 | Kein HTTPS/Reverse-Proxy vor den `inabox.lan`-Instanzen — für reinen Heimnetz-Zugriff aktuell akzeptabel, vor Fernzugriff/AG-Freigabe zu klären | Mittel | 📋 Offen (2026-09-04 bestätigt: bleibt vorerst Heimnetz-only, kein konkreter Anlass für Fernzugriff) |
| open-starcore_D04 | Anwenderdoku für Editor-Konzepte fehlt (Unterschied Navigationsachse/Filterbar/Gruppen-Filter, wann welches Feld sinnvoll ist) — bisher nur in Commit-Messages/BACKLOG erklärt, nicht für die Arbeitsgruppe selbst aufbereitet | Niedrig | 📋 Offen (2026-09-04, beim Nutzer-Feedback zu PR #3/#4 aufgefallen) |
| open-starcore_D05 | Institutionelles SSO (Microsoft Entra ID) aktivieren — braucht eine App-Registrierung im Entra-ID-Tenant der Organisation (Client-ID/-Secret, Redirect-URI). Scaffolding liegt bereits vor, aber deaktiviert: `GOTRUE_EXTERNAL_AZURE_*` in `supabase/docker-compose.yml` (aus `SSO_AZURE_*` in `.env`), `signInWithAzure()` + Schalter `ssoAzureEnabled` in `shared/auth.js`, Aktivierungsschritte in `supabase/README.md`. Aus `INA-ePA-und-Patientenportale` T10 übernommen (2026-09-28, ursprünglich als `open-starcore_F02` vergeben) | Niedrig | ⏭ Wartet auf externe App-Registrierung |
| open-starcore_D07 | Nutzerwunsch (2026-09-28): „Es wäre schön, wenn wir ein Mouse-Over-Text für bestimmte Dimensionen hätten." Analyse: Schema hat bisher kein Beschreibungsfeld an `dimensions`/`dimension_values`. Vorschlag: optionale Textspalte (Migration, mit Nutzer abzustimmen) + Eingabefeld in der Dimensionen-Verwaltung des Editors + `title`-Attribut im Viewer (Filterzeilen-Label, Detail-Label, Chips/Tabs/Badges). Leer = kein Tooltip, dadurch nur „bestimmte" Dimensionen betroffen. Entschieden (Nutzer, 2026-09-28): beides (Dimension und Werte), Spaltenname `erlaeuterung`. Rollout auf alle drei `inabox`-Instanzen per `psql` | Mittel | 🔧 In Arbeit (Branch `feature/D07-erlaeuterung-tooltips`) |
| open-starcore_D06 | Beim Aufsetzen einer weiteren Instanz wird die Static-Unit leicht vergessen: `start.sh` startet das Frontend nur per `nohup`, das übersteht keinen Reboot (Backend schon, via Docker-Restart-Policy). Live passiert bei Kommunikationswege (Frontend nach `inabox`-Reboot 2026-09-27 einen Tag lang tot). `supabase/README.md` hat im Abschnitt „Dauerhaftes Deployment" bereits eine Unit-Vorlage, aber „Mehrfachbetrieb auf einem Host" erwähnt nicht, dass jede Instanz eine **eigene** Unit (eigener Name, `STATIC_PORT`, `WorkingDirectory`) braucht — dort ergänzen; optional `start.sh` am Ende warnen lassen, wenn keine passende Unit existiert | Niedrig | 📋 Offen (2026-09-28) |

---

## Instanzen auf `inabox.lan`

Betriebs-Port-Registry für die produktiven Instanzen (Host: VM `inabox`, Debian 13,
Proxmox, Heimnetz des Nutzers, `192.168.1.102`/`inabox.lan`). Ports kollidieren nur
untereinander, nicht mit anderen Projekten auf anderen Hosts — deshalb hier statt in
`dev-notes/PORTS.md` erfasst (siehe Entscheidung zu open-starcore_F01 in `CHANGELOG.md`).

| Instanz | Checkout (`~deploy/…`) | Compose-Projekt | Static-Unit | Branding (`APP_TITLE`) | `DB_PORT` | `REST_PORT` | `AUTH_PORT` | `MAILPIT_PORT` | `STATIC_PORT` |
|---|---|---|---|---|---|---|---|---|---|
| AK-Patientenportale | `open-starcore` | `supabase` | `prozesslandkarte-static.service` | „Patientenpfad" | 5435 | 8001 | 9999 | 8026 | 8095 |
| euviaio-Ausfallszenarien | `euviaio-ausfallszenarien` | `euviaio-starcore` | `euviaio-starcore-static.service` | „Euviaio Ausfallszenarien" | 5436 | 8002 | 9998 | 8027 | 8096 |
| Kommunikationswege (Arbeitstitel) | `kommunikationswege` | `kommunikationswege` | `kommunikationswege-static.service` (seit 2026-09-28) | „Kommunikationswege" | 5437 | 8003 | 9997 | 8028 | 8097 |

**Adressen** (alle Klartext-HTTP, nur im Heimnetz):

| Instanz | Viewer | Editor | Mailpit |
|---|---|---|---|
| AK-Patientenportale | http://inabox.lan:8095/viewer-db/ | http://inabox.lan:8095/editor-db/ | http://inabox.lan:8026/ |
| euviaio-Ausfallszenarien | http://inabox.lan:8096/viewer-db/ | http://inabox.lan:8096/editor-db/ | http://inabox.lan:8027/ |
| Kommunikationswege | http://inabox.lan:8097/viewer-db/ | http://inabox.lan:8097/editor-db/ | http://inabox.lan:8028/ |

Backend-Container starten nach Reboot über Dockers Restart-Policy (`unless-stopped`), keine
eigene systemd-Unit; Frontends über die jeweilige Static-Unit (`python3 -m http.server`,
`WorkingDirectory` = Checkout). `APP_TITLE` ist in jedem Checkout eine lokale, uncommittete
Änderung an `viewer-db/index.html`/`editor-db/index.html` — beim Aktualisieren per
`git stash`/`git pull`/`git stash pop` erhalten. Bestehende DBs bekommen neue Migrationen nicht
über `start.sh` (spielt nur bei leerer DB ein), sondern einzeln per
`docker exec -i <db-container> psql … < migrations/<datei>.sql` plus `NOTIFY pgrst, 'reload schema'`.

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

*(keine — open-starcore_F01 geklärt, siehe `CHANGELOG.md` 2026-09-04)*

---

## Zurückgestellt

*(keine)*

---

## Abgelehnte Features

*(keine)*
