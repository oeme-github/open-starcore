# Lokaler Stack: Postgres + PostgREST + GoTrue

Entbündelter Ersatz für Supabase: nur die drei tatsächlich benötigten
Bausteine (mandantenfähiges Dimensionen-Datenmodell + Auth + REST-API),
selbst gehostet per Docker Compose. Kein Supabase Studio, kein Kong, keine
Realtime-/Storage-Dienste.

## Voraussetzungen auf dem Host

- Docker + Docker Compose Plugin (`docker compose ...`, nicht das alte
  eigenständige `docker-compose`-Binary)
- Python 3 (nur für `python3 -m http.server`, den statischen Webserver für
  `viewer-db`/`editor-db` — kein Build-Schritt, keine Abhängigkeiten)

## TL;DR: alles mit einem Aufruf starten

```bash
./supabase/start.sh
```

Idempotent — legt beim allerersten Aufruf `.env` (neue Secrets) und das
Schema an und startet den statischen Webserver für Viewer/Editor; bei jedem
weiteren Aufruf werden nur fehlende Teile ergänzt, nichts wird
überschrieben. Details zu den einzelnen Schritten (falls manuell/einzeln
gebraucht) siehe unten. Direkt nach dem allerersten Start ist die Instanz
leer — siehe „Erste Workgroup anlegen" unten für den einmaligen
Einrichtungsschritt.

Stoppen mit `./supabase/stop.sh` (Daten bleiben erhalten — Container werden
entfernt, aber nicht das DB-Volume). Für einen kompletten Reset:
`./supabase/stop.sh --wipe-data` (löscht auch die Daten; der nächste
`start.sh`-Aufruf spielt das Schema dann wieder frisch ein).

## Einmalig einrichten (manuell, falls nicht über start.sh)

```bash
cd supabase
cp .env.example .env
# Werte in .env füllen, z.B.:
openssl rand -hex 32       # → JWT_SECRET
openssl rand -base64 24    # → POSTGRES_PASSWORD / AUTHENTICATOR_PASSWORD / AUTH_ADMIN_PASSWORD
```

## Starten (Reihenfolge beachten)

GoTrue muss seine eigenen `auth.*`-Tabellen/Funktionen anlegen, **bevor**
unsere Migration läuft (die per Fremdschlüssel auf `auth.users` verweist):

```bash
docker compose up -d db mailpit   # Postgres + Mailfänger für Magic-Link/Bestätigungsmails
docker compose up -d auth          # GoTrue: legt auth.users, auth.uid() etc. an
docker compose up -d rest          # PostgREST
```

Direkt danach einmalig `post-auth-init.sql` einspielen (setzt den Default
`role = 'authenticated'` für neue Nutzer – fehlt hier, weil wir nicht das
volle supabase/postgres-Image nutzen, siehe Datei-Kommentar):

```bash
docker compose exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 \
  < post-auth-init.sql
```

Danach die Schema-Migrationen einspielen (alle Dateien in `migrations/`,
sortiert):

```bash
for f in $(ls migrations/*.sql | sort); do
  docker compose exec -T db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < "$f"
done

# PostgREST danach den Schema-Cache neu laden lassen:
docker compose exec -T db psql -U postgres -d postgres -c "NOTIFY pgrst, 'reload schema';"
```

## Erste Workgroup anlegen

Das Schema ist nach dem Erststart leer — kein Beispieldatensatz, keine
Test-Zugänge. `workgroups` hat bewusst keine Schreib-Policy über PostgREST
(siehe „Wichtige technische Erkenntnisse" unten), daher ist die erste
Workgroup + der erste `admin`-Nutzer ein einmaliger manueller Schritt:

```bash
# 1) Workgroup anlegen (Key frei wählbar, url-/code-freundlich, z.B. "mein-projekt")
docker compose exec -T db psql -U postgres -d postgres -c "
  insert into workgroups (key, name) values ('mein-projekt', 'Mein Projekt');
"

# 2) Einladung eintragen - ohne diesen Schritt blockt gate_new_user_signup()
#    jede Registrierung (siehe "Einladungs-gesteuerte Selbstregistrierung"
#    unten) auch für den allerersten Nutzer
docker compose exec -T db psql -U postgres -d postgres -c "
  insert into pending_invites (workgroup_id, email, rolle)
  select id, 'admin@beispiel.local', 'admin' from workgroups where key='mein-projekt';
"

# 3) Nutzer registrieren (löst Bestätigungsmail an Mailpit aus)
curl -X POST http://localhost:9999/signup -H "Content-Type: application/json" \
  -d '{"email":"admin@beispiel.local","password":"ein-sicheres-passwort"}'

# 4) Bestätigungscode aus Mailpit holen (http://localhost:8026) und verifizieren
curl -X POST http://localhost:9999/verify -H "Content-Type: application/json" \
  -d '{"type":"signup","email":"admin@beispiel.local","token":"<code aus Mailpit>"}'
```

Die Mitgliedschaft als `admin` entsteht danach automatisch (Trigger
`provision_membership_from_invite`, verbraucht die Einladung aus Schritt 2)
— kein weiterer manueller Schritt nötig.

Danach im Editor (`editor-db/index.html`) unter „Dimensionen" die ersten
Dimensionen (z.B. Kategorien/Klassifikationen für die eigenen Einträge)
anlegen und weitere Mitglieder unter „Mitglieder" einladen (siehe unten).

## Viewer-Prototyp gegen die Datenbank

`../viewer-db/index.html` — Viewer, lädt Daten live per PostgREST aus der
Datenbank. Start (beliebiger statischer Webserver genügt, kein
Build-Schritt). **Wichtig:** vom Projekt-Wurzelverzeichnis aus starten,
nicht aus `viewer-db/` selbst — `viewer-db` und `editor-db` binden beide
`../shared/auth.js` ein, das liegt außerhalb ihres jeweiligen Ordners:

```bash
# im Projekt-Wurzelverzeichnis:
python3 -m http.server 8095
# im Browser: http://localhost:8095/viewer-db/
```

Der Viewer braucht eine echte Anmeldung (GoTrue) UND eine Mitgliedschaft
(`memberships`-Zeile) in einer Workgroup, sonst blendet RLS alle Daten aus
— siehe „Erste Workgroup anlegen" oben. `GOTRUE_URL`/`REST_URL`/`APP_TITLE`
sind oben in `viewer-db/index.html` als Konstanten hinterlegt (Default: die
Ports aus diesem Stack) – bei abweichenden Ports oder für einen eigenen
Produktnamen dort anpassen.

Tabs/Filter/Kartenfelder/Matrix-Achsen werden vollständig dynamisch aus
`dimensions`/`dimension_values` abgeleitet, nicht hart codiert — eine neue
Workgroup mit eigenen Dimensionen benötigt keine Codeänderung im Viewer.

## Editor-Prototyp gegen die Datenbank

`../editor-db/index.html` — Formularfelder werden pro Dimension generisch
erzeugt (`single_select`/`multi_select`/`text`), neue Werte lassen sich
inline ergänzen. Speichern schreibt direkt per PostgREST, abgesichert durch
RLS (nur Rolle `editor`/`admin` darf schreiben).

```bash
# im Projekt-Wurzelverzeichnis, siehe Hinweis oben:
python3 -m http.server 8095
# im Browser: http://localhost:8095/editor-db/
```

## Dimensionen-Verwaltung im Editor

Im Editor (`editor-db/index.html`) zwischen „Einträge" und „Dimensionen"
umschalten (Sidebar-Tabs). Dort lassen sich neue Dimensionen anlegen
(Key/Label/Typ/Reihenfolge/Farbe/Navigationsachse/Filterbar) sowie
bestehende bearbeiten/löschen, und die Werte einer Dimension pflegen
(bearbeiten/löschen, nicht nur ergänzen wie im Eintrags-Formular).
Dimensionen anlegen/ändern/löschen erfordert laut Schema die Rolle
`admin`, nicht nur `editor` (`"Admins verwalten Dimensionen"`-Policy) — mit
`editor` bleibt nur die Werte-Pflege innerhalb bestehender Dimensionen
möglich.

**Navigationsachse vs. Filterbar:** Nur die *erste* `single_select`-
Dimension mit Navigationsachse (`sectionDim`) sektioniert den Viewer
(eigene Tab-Leiste + betitelte Abschnitte in der Kartenansicht). Weitere
Navigationsachsen wirken nur noch wie Filter (Tab-Leiste/Toggle-Chips),
bekommen aber zusätzlich automatisch ein Badge auf jeder Karte. Filterbar
(`ist_filterbar`, unabhängig von Navigationsachse) erzeugt denselben
Filter, ohne Seite zu sektionieren oder ein Karten-Badge zu ergänzen — die
richtige Wahl für zusätzliche Filter, die die Kartendarstellung nicht
verändern sollen. Beide Felder sind nur für `single_select`/`multi_select`
vorgesehen und im Editor bei `typ=text` ausgeblendet (eine
Text-Dimension mit gesetztem Navigationsachse- oder Filterbar-Flag würde
sonst ohne jede UI-Rückmeldung aus dem Viewer verschwinden, siehe
`detailDims` in `viewer-db/index.html`).

## Mitglieder-Verwaltung im Editor

Im Editor zwischen „Einträge"/„Dimensionen"/„Mitglieder" umschalten.
Erfordert wie die Dimensionen-Verwaltung die Rolle `admin`
(`"Admins verwalten Mitgliedschaften"`-Policy) — mit `editor`/`viewer` zeigt
der Tab nur einen Hinweistext, keine Liste.

Existiert bereits ein Konto unter der eingegebenen E-Mail-Adresse, wird
sofort eine echte Mitgliedschaft angelegt. Existiert noch keins, legt der
Editor automatisch eine Einladung an (siehe „Einladungs-gesteuerte
Selbstregistrierung" unten), statt nur eine Fehlermeldung zu zeigen — die
Person kann sich danach selbst per Magic-Link registrieren. Dahinter
stecken zwei `security definer`-RPCs (Migration
`20260719100000_add_member_lookup_functions.sql`), weil `auth.users` selbst
über PostgREST nicht erreichbar ist (`PGRST_DB_SCHEMA=public`):

- `lookup_user_by_email(p_email, p_workgroup_id)` — löst eine E-Mail-Adresse
  zur `user_id` auf (`null`, falls kein Account existiert)
- `list_workgroup_members(p_workgroup_id)` — Mitgliederliste inkl. E-Mail

Beide prüfen den `admin`-Status selbst (RLS greift bei `security definer`
nicht), liefern sonst HTTP 403. Nach dem Einspielen einer neuen
Funktions-Migration nicht vergessen: `NOTIFY pgrst, 'reload schema';`
(PostgREST cacht Funktionssignaturen wie Tabellenschemata).

Client-seitiger Selbstschutz (kein DB-Constraint): Die letzte `admin`-Rolle
einer Workgroup lässt sich weder herabstufen noch entfernen, um
versehentliches Selbst-Aussperren zu verhindern.

## Einladungs-gesteuerte Selbstregistrierung

`shared/auth.js` erlaubt Erstregistrierung per Magic-Link (`create_user:true`
gegenüber GoTrue) — abgesichert durch eine Einladungsliste, nicht
unkontrolliert offen für beliebige E-Mail-Adressen.

**Ablauf:**
1. Ein `admin` trägt in der Mitglieder-Verwaltung eine E-Mail-Adresse +
   Rolle ein. Existiert noch kein Konto, entsteht eine Zeile in
   `pending_invites` (Badge „eingeladen" in der Liste) — es wird **keine**
   Mail verschickt, der admin muss die Person selbst informieren.
2. Die Person registriert sich eigenständig über den Login-Bildschirm
   (Magic-Link). GoTrue prüft beim Anlegen der `auth.users`-Zeile per
   Trigger `gate_new_user_signup` (Migration
   `20260719120000_add_invite_gated_signup.sql`), ob eine passende
   Einladung existiert — sonst schlägt die Registrierung fehl (HTTP 500
   „Database error saving new user"; GoTrue reicht den eigenen
   Trigger-Fehlertext nicht durch, `shared/auth.js` zeigt stattdessen eine
   eigene, verständliche Meldung).
3. Nach erfolgreicher Registrierung legt der Trigger
   `provision_membership_from_invite` automatisch die vorgesehene
   `memberships`-Zeile an und löscht die verbrauchte Einladung — der admin
   muss nichts weiter tun. Die App refresht Listen nicht automatisch — die
   Mitgliederliste zeigt den aktuellen Stand erst nach erneutem Laden.

**Bekannter GoTrue-Stolperstein:** Bei `create_user:true` erzeugt GoTrue für
eine noch unbekannte E-Mail-Adresse einen `signup`-Token, für eine bereits
bestehende Adresse dagegen einen `magiclink`-Token — welcher Fall vorliegt,
weiß das Frontend vorher nicht (`/otp` antwortet bewusst immer `{}`,
Anti-Enumeration). `verifyMagicLinkCode()` versucht deshalb zuerst
`type:'magiclink'`, bei Fehlschlag automatisch `type:'signup'`.

## Änderungsprotokoll

`process_step_audit` (interner Name aus dem ursprünglichen Anwendungsfall
— siehe `init_schema.sql` — die UI zeigt generisch „Einträge"/„Verlauf")
wird per Trigger auf `process_steps` UND `process_step_values` aktiv
befüllt (die fachlichen Inhalte eines Eintrags liegen im generischen
Datenmodell nicht in `process_steps` selbst), beide `security definer`, da
die Tabelle bewusst keine Schreib-Policy hat.

Abfragbar nur über die API (`GET /process_step_audit?process_step_id=eq.<id>`),
RLS erlaubt Lesen ab Rolle `viewer` in der jeweiligen Workgroup. Im Editor
als „Verlauf"-Abschnitt pro Eintrag sichtbar.

**Rauschunterdrückung bei Massenimporten:** Ein Skript, das viele Zeilen in
kurzer Zeit ändert (z.B. ein Migrations-/Import-Lauf), kann sich per
`set local app.skip_audit='on'` innerhalb seiner eigenen Transaktion von der
Protokollierung ausnehmen — ein normaler `psql`-Zugriff ohne diese Einstellung
wird ganz regulär protokolliert (mit `changed_by = null`, da ohne
PostgREST-JWT kein `auth.uid()` verfügbar ist).

**Wichtig bei künftigen Migrationen an `process_step_audit`:**
`process_step_id` hat bewusst **keinen** Fremdschlüssel auf `process_steps`
— ein Audit-Log darf nicht verschwinden, wenn die protokollierte Zeile
gelöscht wird. `workgroup_id` ist denormalisiert direkt in der Tabelle
mitgeführt (nicht per Join ermittelt), sonst würden RLS-Leserechte und der
Cascade-Trigger nach einer Löschung ins Leere laufen.

## Gemeinsamer Login

`../shared/auth.js` wird von `viewer-db` und `editor-db` gemeinsam per
`<script src="../shared/auth.js">` eingebunden — daher der Hinweis oben,
beide Prototypen über einen Server im Projekt-Wurzelverzeichnis zu starten.
Login-Reihenfolge: Magic-Link zuerst (E-Mail → GoTrue `/otp` → 6-stelliger
Code aus der Mail/Mailpit → `/verify`), Passwort als eingeklappter Fallback.

## Institutionelles SSO — Microsoft Entra ID

GoTrue unterstützt Entra ID als externen OAuth-Provider bereits fertig
(`GOTRUE_EXTERNAL_AZURE_*` in `docker-compose.yml`, `SSO_AZURE_*` in
`.env.example`) — der Redirect-Flow (`/authorize?provider=azure` → Microsoft-
Login → zurück mit `#access_token` im URL-Hash) ist in `shared/auth.js`
(`signInWithAzure()`) verdrahtet und nutzt denselben Hash-Consuming-Pfad wie
der Magic-Link-Bonusweg.

**Braucht eine echte App-Registrierung** im Entra-ID-Tenant der eigenen
Organisation (Client-ID/-Secret, erlaubte Redirect-URIs) — ohne das bleibt
SSO im Login-Bildschirm ausgeblendet (`ssoAzureEnabled: false` in
`viewer-db/index.html` und `editor-db/index.html`).

**Um SSO scharf zu schalten**, sobald eine App-Registrierung existiert:
1. In Entra ID: App-Registrierung anlegen, Redirect-URI auf die GoTrue-URL
   setzen (z.B. `http://localhost:9999/callback` lokal), Client-Secret
   erzeugen.
2. `supabase/.env`: `SSO_AZURE_ENABLED=true` sowie Client-ID/-Secret/
   Tenant-URL/Redirect-URI eintragen, Stack neu starten (`docker compose up
   -d auth`).
3. In `viewer-db/index.html` und `editor-db/index.html`: `ssoAzureEnabled:
   true` in `initLoginScreen(...)` setzen.

## Ports

| Dienst | Env-Var | Default |
|---|---|---|
| db (Postgres) | `DB_PORT` | 5435 |
| auth (GoTrue) | `AUTH_PORT` | 9999 |
| rest (PostgREST) | `REST_PORT` | 8001 (intern immer 3000) |
| mailpit (Web-UI) | `MAILPIT_PORT` | 8026 |
| statischer Webserver | `STATIC_PORT` (an `start.sh` übergeben) | 8095 |

Alle Ports sind über `.env` (bzw. Umgebungsvariablen für `STATIC_PORT`)
überschreibbar — nötig, sobald mehrere Instanzen auf demselben Host laufen
sollen (siehe „Dauerhaftes Deployment" unten, Abschnitt Mehrfachbetrieb).

## Wichtige technische Erkenntnisse

- **`auth.uid()`/`auth.role()`/`auth.email()`/`auth.jwt()` kommen von GoTrue
  selbst** (Migration `00_init_auth_schema`), nicht vom supabase/postgres-
  Image. Nicht selbst vordefinieren – GoTrue verbindet sich als eigene Rolle
  (`supabase_auth_admin`, angelegt in `init-db/01-auth-schema.sh`) und legt
  sie beim ersten Start selbst an. Eigene Vordefinition führt zu
  `must be owner of function uid`.
- **`supabase_auth_admin` braucht `search_path = auth, public`**, sonst legt
  GoTrue seine (unqualifizierten) Typen/Tabellen in `public` statt `auth` an
  – spätere GoTrue-Migrationen, die explizit `auth.factor_type`
  referenzieren, brechen dann mit „type does not exist".
- **`PGRST_DB_USE_LEGACY_GUCS` muss `false` sein** (PostgREST-Default seit
  v10+): GoTrues `auth.uid()` liest `request.jwt.claim.sub`, nicht die alte
  JSON-GUC `request.jwt.claims`.
- Rollen `anon`/`authenticated`/`service_role`/`authenticator` sind nicht
  Teil von Postgres/PostgREST/GoTrue – die legt `init-db/00-roles.sh`
  einmalig beim ersten Start des DB-Volumes an (inkl. Default-Privileges für
  künftige Tabellen aus der Migration).
- `workgroups` hat in der Migration bewusst nur eine `select`-Policy, keine
  Schreib-Policy – neue Arbeitsgruppen anlegen ist nur per
  `service_role`/direktem DB-Zugriff möglich, nicht über PostgREST mit einer
  Nutzerrolle (siehe „Erste Workgroup anlegen" oben).
- `docker-entrypoint-initdb.d`-Skripte laufen nur beim allerersten Start
  eines leeren `db-data`-Volumes. Nach Änderungen an `init-db/*.sh` während
  der Entwicklung: `docker compose down -v` (Volume löschen) und neu
  hochfahren.
- **`GOTRUE_JWT_DEFAULT_GROUP_NAME` ist in dieser GoTrue-Version ein reines
  No-op** (Deprecation-Hinweis im Log, aber ohne Wirkung). Im vollen
  supabase/postgres-Image bekommen neue Nutzer ihre Rolle stattdessen über
  einen Spalten-Default `auth.users.role = 'authenticated'`. Ohne diesen
  Default (unser Fall) liefert GoTrue JWTs mit `role:""`, und PostgREST kann
  nicht per `SET ROLE` wechseln → `post-auth-init.sql` setzt den Default
  nach. **Ein reiner Spalten-Default reicht aber nicht**: GoTrue schreibt
  bei jedem Signup explizit `role=''` (nicht NULL, nicht weggelassen) – ein
  Default greift nur, wenn die Spalte in der INSERT-Anweisung fehlt.
  Deshalb zusätzlich ein Trigger auf `auth.users`, der leere Rollen
  korrigiert. **Ein `before insert`-Trigger allein reicht dafür nicht**:
  GoTrue überschreibt den Nutzer offenbar noch mindestens einmal per
  `UPDATE` im selben Signup/Verify-Ablauf, mit einem in Go noch leeren
  Rollen-Feld — ein reiner Insert-Trigger sieht dieses spätere Update
  nicht. Endgültiger Fix: Trigger auf `before insert or update` erweitert.

## Dauerhaftes Deployment (z.B. eigene VM/Container statt Laptop)

Docker-Compose-Services haben `restart: unless-stopped` und starten damit
nach einem Reboot automatisch wieder, sofern der Docker-Dienst selbst beim
Boot startet (`systemctl enable docker`, bei einer frischen Docker-CE-
Installation über das offizielle APT-Repo bereits der Fall). Der statische
Webserver für `viewer-db`/`editor-db` (`python3 -m http.server` in
`start.sh`) ist dagegen ein reiner Vordergrund-Prozess und übersteht ohne
Weiteres **keinen** Neustart. Für einen dauerhaften Host stattdessen eine
systemd-Unit einrichten, z.B.:

```ini
# /etc/systemd/system/starcore-static.service
[Unit]
Description=Statischer Webserver fuer viewer-db/editor-db
After=network.target docker.service

[Service]
Type=simple
User=<dein-deploy-user>
WorkingDirectory=/pfad/zum/repo
ExecStart=/usr/bin/python3 -m http.server 8095
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now starcore-static.service
```

`viewer-db/index.html`, `editor-db/index.html` und `shared/auth.js` leiten
`GOTRUE_URL`/`REST_URL`/den Mailpit-Hinweislink zur Laufzeit aus
`location.hostname` ab (nicht fest `localhost`) — funktioniert dadurch
unverändert, ob der Stack lokal auf `localhost` oder auf einem entfernten
Host im Netz läuft, ohne Codeänderung.

**Kein HTTPS/Reverse-Proxy vor den Diensten** — alle Ports laufen als
Klartext-HTTP. Für reinen Zugriff im vertrauenswürdigen Heimnetz akzeptabel,
für Fernzugriff oder produktiven Betrieb nachzuziehen (z.B. Caddy/nginx als
TLS-Terminierung davor).

**Mehrfachbetrieb auf einem Host:** Mehrere Instanzen (z.B. für
unterschiedliche Projekte/Anwendungsfälle) können denselben Host teilen,
solange jede einen eigenen Checkout mit eigener `.env` (eigene
`DB_PORT`/`AUTH_PORT`/`REST_PORT`/`MAILPIT_PORT`/`STATIC_PORT`) hat. Docker
Compose benennt Volumes standardmäßig nach dem Verzeichnisnamen, der die
`docker-compose.yml` enthält (hier: `supabase`) — ohne explizites
`COMPOSE_PROJECT_NAME` würden zwei Checkouts mit demselben Ordnernamen
`supabase/` versehentlich dieselben Docker-Volumes/Netzwerke teilen. Für
jede weitere Instanz auf demselben Host `COMPOSE_PROJECT_NAME` explizit
setzen (z.B. in der jeweiligen `.env` oder vor jedem `docker
compose`/`start.sh`-Aufruf exportieren).

## Smoke-Test (durchgeführt, nicht dauerhaft im Stack)

Signup → Mailpit-Bestätigungsmail → `/verify` → JWT mit `role: authenticated`
→ PostgREST: anonym leer, `authenticated` ohne Membership leer, `viewer`
liest, `editor` schreibt (`POST /process_steps` → 201). Testdaten wieder
gelöscht.
