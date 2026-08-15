#!/usr/bin/env bash
# Startet den kompletten lokalen Stack mit einem Aufruf:
# Postgres + PostgREST + GoTrue + Mailpit (Docker) sowie den statischen
# Webserver für viewer-db/editor-db. Idempotent — kann beliebig oft erneut
# aufgerufen werden, ohne bestehende Daten zu verändern:
# - Docker-Services: `docker compose up -d` startet nur, was nicht schon läuft
# - Schema-Migration läuft nur beim allerersten Start (leeres DB-Volume)
#
# Legt KEINE Workgroup/Testnutzer an — das Schema ist bewusst leer nach dem
# Erststart. `workgroups` hat keine Schreib-Policy über PostgREST (siehe
# README.md), die erste Workgroup + der erste admin-Nutzer müssen daher
# einmalig per direktem DB-Zugriff angelegt werden (siehe README.md,
# Abschnitt "Erste Workgroup anlegen").
#
# Verwendung: ./start.sh (aus beliebigem Verzeichnis aufrufbar)
set -euo pipefail

SUPABASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SUPABASE_DIR")"
STATIC_PORT="${STATIC_PORT:-8095}"

cd "$SUPABASE_DIR"

# ── .env sicherstellen ──────────────────────────────────────────────
if [ ! -f .env ]; then
  echo "==> supabase/.env fehlt, erzeuge neue lokale Secrets ..."
  cat > .env <<EOF
POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=')
AUTHENTICATOR_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=')
AUTH_ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=')
JWT_SECRET=$(openssl rand -hex 32)
SITE_URL=http://localhost:3000
EOF
fi

# shellcheck disable=SC1091
source .env
DB_PORT="${DB_PORT:-5435}"
REST_PORT="${REST_PORT:-8001}"
AUTH_PORT="${AUTH_PORT:-9999}"
MAILPIT_PORT="${MAILPIT_PORT:-8026}"

# ── Docker-Stack ─────────────────────────────────────────────────────
echo "==> Postgres + Mailpit starten ..."
docker compose up -d db mailpit

echo "==> Warte auf Postgres ..."
until docker compose exec -T db pg_isready -U postgres >/dev/null 2>&1; do sleep 1; done

echo "==> GoTrue (Auth) starten ..."
docker compose up -d auth

echo "==> Warte auf GoTrue ..."
until curl -s -o /dev/null "http://localhost:${AUTH_PORT}/settings"; do sleep 1; done

echo "==> post-auth-init.sql einspielen (Rollen-Default/-Trigger, idempotent) ..."
docker compose exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < post-auth-init.sql > /dev/null

echo "==> PostgREST starten ..."
docker compose up -d rest

# ── Schema-Migration nur beim allerersten Start ──────────────────────
# Alle Dateien in migrations/ (sortiert) einspielen.
FRESH="$(docker compose exec -T db psql -U postgres -d postgres -tAc "select to_regclass('public.workgroups')" | tr -d '[:space:]')"
if [ -z "$FRESH" ]; then
  echo "==> Erststart erkannt: Schema-Migrationen einspielen ..."
  for f in $(ls migrations/*.sql | sort); do
    echo "  -- $f"
    docker compose exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < "$f"
  done
  docker compose exec -T db psql -U postgres -d postgres -c "NOTIFY pgrst, 'reload schema';" > /dev/null
else
  echo "==> Schema existiert bereits (kein Erststart) — Migration übersprungen."
fi

# ── Statischer Webserver für viewer-db/editor-db ────────────────────
if ! curl -s -o /dev/null "http://localhost:${STATIC_PORT}/"; then
  echo "==> Statischen Webserver für viewer-db/editor-db starten (Port ${STATIC_PORT}) ..."
  (cd "$REPO_ROOT" && nohup python3 -m http.server "$STATIC_PORT" > /tmp/starcore-http.log 2>&1 &)
  sleep 1
else
  echo "==> Statischer Webserver läuft bereits auf Port ${STATIC_PORT}."
fi

cat <<EOF

Fertig! Stack läuft:

  Viewer:   http://localhost:${STATIC_PORT}/viewer-db/
  Editor:   http://localhost:${STATIC_PORT}/editor-db/
  Mailpit:  http://localhost:${MAILPIT_PORT}  (Bestätigungscodes für Magic-Link)

Noch keine Workgroup/kein Nutzer angelegt — siehe README.md, Abschnitt
"Erste Workgroup anlegen", für den einmaligen manuellen Einrichtungsschritt.

Stack stoppen: ./stop.sh (Daten bleiben erhalten)
Kompletter Reset: ./stop.sh --wipe-data (löscht das DB-Volume, nächster
start.sh macht einen Erststart)
EOF
