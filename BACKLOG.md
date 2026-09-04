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

---

## Entwicklung & Infrastruktur

| ID | Aufgabe | Priorität | Status |
|----|---------|-----------|--------|
| open-starcore_D01 | Kein HTTPS/Reverse-Proxy vor den `inabox.lan`-Instanzen — für reinen Heimnetz-Zugriff aktuell akzeptabel, vor Fernzugriff/AG-Freigabe zu klären | Mittel | 📋 Offen (2026-09-04 bestätigt: bleibt vorerst Heimnetz-only, kein konkreter Anlass für Fernzugriff) |
| open-starcore_D02 | CLAUDE.md nutzt noch nicht das aktuelle `@`-Import-Muster für `dev-notes/STANDARDS.md` (Muster geerbt von `INA-ePA-und-Patientenportale`, vordatiert die Konvention) — bei Gelegenheit auf aktuelles Template angleichen | Niedrig | 📋 Offen |

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

(Defaults aus `supabase/README.md`, Abschnitt „Ports"; zweite Instanz nutzt jeweils Default+1
über `.env`.)

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
