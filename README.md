# open-starcore

Selbst gehostete, mandantenfähige Engine für Kataloge, deren Einträge sich
entlang frei definierbarer Dimensionen klassifizieren lassen — statt eines
festen Tabellenschemas pro Anwendungsfall gibt es genau drei generische
Bausteine: **Einträge**, **Dimensionen** (Kategorien/Achsen) und
**Dimension-Werte** (Auswahllisten pro Dimension). Jede Arbeitsgruppe
(„Workgroup") definiert ihre eigenen Dimensionen, ohne Codeänderung.

Namensgeber ist das „Star Schema" — der Fachbegriff für genau dieses
Muster: eine zentrale Fakten-Tabelle (hier: `process_steps`, siehe unten)
umgeben von Dimensions-Tabellen.

## Was das ist

- Backend: Postgres + PostgREST + GoTrue (Auth), selbst gehostet per Docker
  Compose — ein entbündelter Ersatz für Supabase, keine SaaS-Abhängigkeit.
- Zwei schlanke Web-Frontends ohne Build-Schritt: `viewer-db/` (Lesen,
  Filtern, Matrix-Ansicht, Export) und `editor-db/` (Pflege von Einträgen,
  Dimensionen und Mitgliedschaften).
- Row-Level-Security pro Workgroup, Rollen `viewer`/`editor`/`admin`,
  Magic-Link-Login mit Einladungs-Gate, vollständiges Änderungsprotokoll.

## Herkunft

Ursprünglich als Teil eines Projekts zur interaktiven Prozesslandkarte
entstanden (Akteur × Prozess → Datenobjekt), aber von Anfang an bewusst
generisch gebaut. In dieses eigenständige Repo ausgegliedert, um es für
andere Anwendungsfälle nutzbar zu machen, deren Daten sich ebenfalls als
„Einträge mit klassifizierenden Dimensionen" modellieren lassen (z.B.
Ausfallszenarien-Kataloge, Anforderungslisten, Risikoregister).

## Loslegen

Siehe `supabase/README.md` — enthält alles: Voraussetzungen, Start/Stop,
erste Workgroup anlegen, Deployment-Hinweise (auch für mehrere Instanzen
auf einem Host).

```bash
./supabase/start.sh
```

## Struktur

- `supabase/` — Schema-Migrationen, Docker Compose, Start-/Stop-Skripte
- `viewer-db/` — Viewer (nur Lesen)
- `editor-db/` — Editor (Einträge, Dimensionen, Mitglieder verwalten)
- `shared/` — gemeinsamer Login (`auth.js`), von beiden Frontends eingebunden

## Lizenz

EUPL 1.2, siehe `LICENSE`.
