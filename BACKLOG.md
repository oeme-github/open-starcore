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

---

## Entwicklung & Infrastruktur

| ID | Aufgabe | Priorität | Status |
|----|---------|-----------|--------|
| open-starcore_D01 | Kein HTTPS/Reverse-Proxy vor den `inabox.lan`-Instanzen — für reinen Heimnetz-Zugriff aktuell akzeptabel, vor Fernzugriff/AG-Freigabe zu klären | Mittel | 📋 Offen |
| open-starcore_D02 | CLAUDE.md nutzt noch nicht das aktuelle `@`-Import-Muster für `dev-notes/STANDARDS.md` (Muster geerbt von `INA-ePA-und-Patientenportale`, vordatiert die Konvention) — bei Gelegenheit auf aktuelles Template angleichen | Niedrig | 📋 Offen |

---

## Offene Fragen / Entscheidungen

| ID | Frage | Status |
|----|-------|--------|
| open-starcore_F01 | Sollen Ports einzelner Instanzen (z. B. euviaio-starcore: `DB_PORT=5436`/`REST_PORT=8002`/`AUTH_PORT=9998`/`MAILPIT_PORT=8027`/`STATIC_PORT=8096`) in `dev-notes/PORTS.md` erfasst werden? Diese Registry ist bisher explizit auf Devbox-lokale Konflikte (`docker-compose`/Dev-Server auf derselben Maschine) begrenzt — die Instanzen laufen aber auf dem separaten Host `inabox.lan`. Klären, ob PORTS.md erweitert wird oder eine instanzbezogene Registry an anderer Stelle (z. B. in diesem Repo oder bei `inabox.lan`s Betriebsdoku) sinnvoller ist. | 📋 Offen |

---

## Zurückgestellt

*(keine)*

---

## Abgelehnte Features

*(keine)*
