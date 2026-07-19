# MineTrack — Underground Personnel Tracking (Flutter Web)

MineTrack is a personnel-tracking dashboard for underground mining operations.
It tracks workers, BLE tags, gateways, alerts, and live locations on an
underground mine map. This is the **Flutter web** implementation; it mirrors the
behaviour and layout of the original React reference app that lives alongside it
in the repository root.

The app is designed to run **fully offline** — CanvasKit, the UI font (Inter),
and fallback fonts are all bundled locally so the app loads with zero network
dependencies.

---

## Table of contents

1. [Features](#features)
2. [Tech stack](#tech-stack)
3. [Prerequisites](#prerequisites)
4. [Project structure](#project-structure)
5. [Install dependencies](#install-dependencies)
6. [Run locally](#run-locally)
7. [Build for production](#build-for-production)
8. [Offline loading (how it works)](#offline-loading-how-it-works)
9. [Deploy](#deploy)
10. [Configuration reference](#configuration-reference)
11. [App architecture](#app-architecture)
12. [Pages reference](#pages-reference)
13. [Theming](#theming)
14. [Data](#data)
15. [Troubleshooting](#troubleshooting)

---

## Features

- **Dashboard** — KPI cards, live underground mine map, recent events feed,
  tabbed personnel/gateway tables, and chart grid (battery health, worker
  distribution, signal strength, personnel underground).
- **Live Tracking** — full-screen command centre with map layers (default,
  heatmap, gas overlay), worker selection drawer, live stats overlay, and
  per-worker detail panel.
- **Personnel** — searchable personnel table with filters, pagination, and a
  multi-step register-worker dialog.
- **BLE Devices** — MikroTik BLE tag inventory with status filters and actions.
- **Alerts** — incident management with severity/type filters and assign/close
  workflows.
- **Reports** — exportable daily/shift/attendance reports with charts and a
  daily summary table.
- **Admin** — user management, mine configuration, notification rules, data
  management, API integrations, departments, and audit logs.
- **Settings** — dark mode, language, alert thresholds (sliders), and
  notification toggles.
- **Responsive layout** — sidebar collapses, top bar hides chips by breakpoint,
  grids reflow, live-tracking stacks on narrow screens.
- **Light & dark themes.**
- **Offline-capable** — no CDN calls at runtime.

---

## Tech stack

| Layer       | Choice                                             |
|-------------|----------------------------------------------------|
| Framework   | Flutter 3.41.x (stable channel)                    |
| Language    | Dart ^3.11.0                                       |
| Renderer    | CanvasKit (default for web)                        |
| State       | `provider` ^6.1.2 (`ChangeNotifier`)               |
| Charts      | `fl_chart` ^0.69.2                                 |
| i18n dates  | `intl` ^0.19.0 (`en_ZA` locale)                    |
| Icons       | Material Icons + `cupertino_icons` ^1.0.8          |
| Font        | Inter (bundled, registered via `pubspec.yaml`)     |

---

## Prerequisites

Install the **Flutter SDK** (stable channel). This project was built and tested
with:

```
Flutter 3.41.2 (stable)
Dart 3.11.0
```

Verify your toolchain:

```bash
flutter --version          # must be 3.41.x or newer
flutter doctor             # check web/desktop/mobile toolchains
dart --version
```

For **web** (the primary target) you only need Flutter + a browser. No Android
Studio or Xcode is required to build/run the web app.

Optional, for deployment:
- A static file server (`python3 -m http.server`, `npx serve`, nginx, Caddy…)
- Docker (if containerising)

---

## Project structure

```
flutter_app/
├── lib/
│   ├── main.dart                 # Entry point → MineTrackAppRoot (Provider)
│   ├── app.dart                  # MaterialApp + shell (Sidebar + TopBar + page)
│   ├── core/
│   │   ├── app_state.dart        # ChangeNotifier: auth, theme, sidebar, page
│   │   └── page_type.dart        # PageKey enum + nav sections
│   ├── data/
│   │   └── mock_data.dart        # Workers, gateways, alerts, events, devices…
│   ├── models/                   # Worker, Gateway, AlertItem, etc.
│   ├── theme/
│   │   └── app_theme.dart        # AppTheme.light/dark, AppColors, SurfaceTokens
│   ├── pages/                    # One file per screen
│   │   ├── login_page.dart
│   │   ├── dashboard_page.dart
│   │   ├── live_tracking_page.dart
│   │   ├── personnel_page.dart
│   │   ├── ble_devices_page.dart
│   │   ├── alerts_page.dart
│   │   ├── reports_page.dart
│   │   ├── admin_page.dart
│   │   └── settings_page.dart
│   ├── widgets/                  # Reusable UI: sidebar, top_bar, kpi_card,
│   │                             # charts, mine_map, badge, worker_tooltip…
│   └── utils/
├── web/                          # Web assets (copied into build/web at build)
│   ├── index.html                # Offline interceptor + service-worker cleanup
│   ├── canvaskit/                # (empty in source; build fills build/web/canvaskit)
│   ├── fonts/                    # Bundled Noto fallback fonts
│   ├── icons/  favicon.png  manifest.json
├── fonts/                        # Inter font (source assets, declared in pubspec)
│   ├── Inter-Regular.ttf
│   ├── Inter-Medium.ttf
│   ├── Inter-SemiBold.ttf
│   └── Inter-Bold.ttf
├── pubspec.yaml                  # Dependencies + Inter font registration
├── analysis_options.yaml
├── android/  ios/  macos/  linux/  windows/   # Platform runners
└── build/                        # (gitignored) build output
```

---

## Install dependencies

From the `flutter_app/` directory:

```bash
flutter pub get
```

This downloads `provider`, `fl_chart`, `intl`, `cupertino_icons` and registers
the bundled Inter font declared in `pubspec.yaml`.

> If you ever add or change fonts in `pubspec.yaml`, re-run `flutter pub get`.

---

## Run locally

### Option A — Flutter dev server (hot reload)

```bash
cd flutter_app
flutter run -d chrome           # opens Chrome, hot reload enabled
# or, pinned to a port:
flutter run -d web-server --web-port=8080
```

Then open http://localhost:8080 (the `web-server` device prints the URL).

The app opens on the **login screen**. The login is mocked — click **Sign In**
with any (or empty) credentials to enter the dashboard.

### Option B — Serve a production build locally (recommended for testing offline)

This is the most realistic way to verify the app, because it uses the exact
artefacts that will be deployed:

```bash
cd flutter_app
flutter build web --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --release

# serve the build output
cd build/web
python3 -m http.server 8080
```

Open http://localhost:8080.

> **Important:** always include `--dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/`
> for builds you intend to deploy or test offline. It tells the Flutter loader
> to look for CanvasKit at the local `/canvaskit/` path instead of the gstatic
> CDN. See [Offline loading](#offline-loading-how-it-works).

### Other platforms (optional)

```bash
flutter run -d macos      # macOS desktop
flutter run -d windows    # Windows desktop
flutter run -d ios        # iOS simulator (requires Xcode)
flutter run -d android    # Android emulator/device (requires Android Studio)
```

The UI is optimised for web/desktop widths. Mobile runners work but the layout
is tuned for wide screens.

---

## Build for production

### Web (primary target)

```bash
cd flutter_app
flutter build web \
  --release \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/
```

Output is written to `flutter_app/build/web/`. That single directory is the
complete deployable artefact — it contains:

- `index.html` (with the offline interceptor script)
- `main.dart.js` (compiled app)
- `flutter.js`, `flutter_bootstrap.js`
- `canvaskit/` (CanvasKit engine: `canvaskit.js`, `canvaskit.wasm`, …)
- `assets/fonts/` (Inter + Material Icons)
- `fonts/` (Noto fallback fonts)
- `icons/`, `favicon.png`, `manifest.json`

You can copy `build/web/` to any static host.

#### Serving from a sub-path

If the app is served from a sub-path (e.g. `https://example.com/minetrack/`),
set the base href at build time:

```bash
flutter build web --release \
  --base-href=/minetrack/ \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=/minetrack/canvaskit/
```

The `FLUTTER_WEB_CANVASKIT_URL` must include the same sub-path so the offline
CanvasKit redirect resolves correctly.

#### Tree-shaking

By default Flutter tree-shakes icon fonts to reduce size. If you see missing
icons, rebuild with `--no-tree-shake-icons`:

```bash
flutter build web --release --no-tree-shake-icons \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/
```

---

## Offline loading (how it works)

The app loads with **zero network calls** by design. Three mechanisms work
together:

1. **Local CanvasKit** — `--dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/`
   makes the Flutter loader import CanvasKit from `/canvaskit/` (files written
   to `build/web/canvaskit/` by the build). No gstatic fetch.

2. **Bundled Inter font** — Inter is declared in `pubspec.yaml` and bundled in
   `build/web/assets/fonts/`. CanvasKit registers it as the main UI font, so
   all text renders without any font fetch. (This is the fix for the
   "clickable but invisible text" issue — the theme sets `fontFamily: 'Inter'`,
   so the font *must* be registered.)

3. **`web/index.html` interceptor** — an inline script (copied into the built
   `index.html`) does three things:
   - **Service-worker cleanup:** unregisters old Flutter service workers and
     clears stale CacheStorage on first load, then reloads once. This prevents
     stale cached code after a redeploy. (A `sessionStorage` flag prevents a
     reload loop.)
   - **Fetch interceptor (backup):** redirects any stray
     `gstatic.com/flutter-canvaskit/*` fetch to `/canvaskit/<file>`.
   - **Loader patch:** wraps `_flutter.loader.load` to force
     `canvasKitBaseUrl='/canvaskit/'` and `fontFallbackBaseUrl='/fonts/'`, and
     disables Flutter's service worker so it never re-registers.

> Symbol/emoji fallback fonts (Noto Sans Symbols) are bundled in `web/fonts/`
> for best-effort offline symbol rendering. Regular text always renders via
> the bundled Inter font.

### Verifying offline works

After building:

```bash
cd flutter_app/build/web
python3 -m http.server 8080
```

In another terminal, confirm every critical asset returns 200 from **localhost**
(not a CDN):

```bash
curl -o /dev/null -w "%{http_code}\n" http://localhost:8080/index.html
curl -o /dev/null -w "%{http_code}\n" http://localhost:8080/main.dart.js
curl -o /dev/null -w "%{http_code}\n" http://localhost:8080/canvaskit/canvaskit.js
curl -o /dev/null -w "%{http_code}\n" http://localhost:8080/canvaskit/canvaskit.wasm
curl -o /dev/null -w "%{http_code}\n" http://localhost:8080/assets/fonts/Inter-Regular.ttf
```

All should print `200`. Then open the URL with the browser's network set to
"Offline" (DevTools → Network → Offline) and reload — the app should still
load and render text.

---

## Deploy

`flutter_app/build/web/` is a static site. Any static host works.

### nginx

Copy `build/web/` to your web root, e.g. `/var/www/minetrack/`:

```bash
flutter build web --release \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/
sudo cp -r build/web/* /var/www/minetrack/
```

nginx server block:

```nginx
server {
    listen 80;
    server_name minetrack.example.com;
    root /var/www/minetrack;
    index index.html;

    # SPA fallback
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Never cache index.html / bootstrap (so new deploys are picked up)
    location = /index.html {
        add_header Cache-Control "no-cache";
    }
    location ~ ^/(flutter_bootstrap\.js|flutter\.js|main\.dart\.js)$ {
        add_header Cache-Control "no-cache";
    }

    # Long-cache immutable static assets
    location ~* \.(wasm|js\.symbols|ttf|otf|png|json|ico)$ {
        add_header Cache-Control "public, max-age=31536000, immutable";
    }
}
```

### Any static server (quick)

```bash
cd flutter_app/build/web
npx serve -l 8080 .
# or
python3 -m http.server 8080
```

### Docker

Create a `Dockerfile` next to `build/web/` (or use a multi-stage build):

```dockerfile
# Build stage
FROM ghcr.io/cirruslabs/flutter:3.41.2 AS build
WORKDIR /app
COPY . .
RUN flutter pub get && \
    flutter build web --release \
      --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/

# Serve stage
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Build and run:

```bash
docker build -t minetrack .
docker run -p 8080:80 minetrack
```

### GitHub Pages

```bash
flutter build web --release \
  --base-href=/minetrack/ \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=/minetrack/canvaskit/
# publish the contents of build/web/ to the gh-pages branch
```

---

## Configuration reference

| Setting / flag                                | Purpose                                              | Default                          |
|-----------------------------------------------|------------------------------------------------------|----------------------------------|
| `--release`                                   | Optimised production build                            | (dev build without it)           |
| `--dart-define=FLUTTER_WEB_CANVASKIT_URL=…`   | Where the loader fetches CanvasKit                   | gstatic CDN (online)             |
| `--base-href=…`                               | Base path when served from a sub-path                | `/`                              |
| `--no-tree-shake-icons`                       | Keep full icon fonts (if icons go missing)           | tree-shaking on                  |
| `--wasm`                                      | Experimental Wasm build                              | off (dry-run warning only)       |

> There is no `.env` or runtime config file. All configuration is compile-time
> via `dart-define` and `--base-href`.

---

## App architecture

### State management

A single `AppState` `ChangeNotifier` (in `lib/core/app_state.dart`) is provided
to the widget tree via `MultiProvider` in `main.dart`:

```dart
void main() {
  initializeDateFormatting();
  Intl.defaultLocale = 'en_ZA';
  runApp(const MineTrackAppRoot());
}
```

`AppState` exposes:
- `isLoggedIn` / `login()` / `logout()`
- `currentPage` (a `PageKey`) / `setPage(PageKey)`
- `darkMode` / `toggleDarkMode()` / `setDarkMode(bool)`
- `collapsed` (sidebar) / `toggleCollapsed()`

Widgets read state with `context.watch<AppState>()` and mutate with
`context.read<AppState>()`.

### Shell

`lib/app.dart` builds the shell:

```
MaterialApp
  └─ (login? LoginPage : _Shell)
      └─ Row
          ├─ Sidebar          (fixed width 240 / collapsed 64)
          └─ Expanded → Column
              ├─ TopBar       (h:56, responsive chips)
              └─ Expanded → page(currentPage)
```

The `Expanded` around the page gives every page a bounded height, so pages can
use `SingleChildScrollView` for vertical scrolling and `Expanded`/`LayoutBuilder`
for responsive grids without overflow.

### Layout conventions

- **Responsive grids** are built as manual `Row` of `Expanded` cards (not
  `GridView` with `childAspectRatio`, which clips content). A helper pattern
  pads the final incomplete row with empty `Expanded(SizedBox())` so last-row
  cards keep the same width as cards above.
- **Scrollable pages** (reports, admin, settings) wrap their `Column` in a
  `SingleChildScrollView`.
- **Fixed-height rows** (e.g. dashboard map + events) use `SizedBox(height: H)`
  with `crossAxisAlignment: stretch` so both children share the bounded height.
- **Top bar / control bars** use `LayoutBuilder` to hide non-essential chips by
  breakpoint and `Flexible(ConstrainedBox(maxWidth: …))` for search fields so
  they shrink instead of overflowing.

---

## Pages reference

| Page            | File                              | Notes                                            |
|-----------------|-----------------------------------|--------------------------------------------------|
| Login           | `pages/login_page.dart`           | Animated tunnel background, mocked auth          |
| Dashboard       | `pages/dashboard_page.dart`       | KPIs, mine map, events, tables, charts           |
| Live Tracking   | `pages/live_tracking_page.dart`   | Full-height map + worker drawer, layer toggles   |
| Personnel       | `pages/personnel_page.dart`       | Table + filters + register dialog                |
| BLE Devices     | `pages/ble_devices_page.dart`     | Tag inventory + status filters                   |
| Alerts          | `pages/alerts_page.dart`          | Incident cards, severity/type filters            |
| Reports         | `pages/reports_page.dart`         | Charts + daily summary table                     |
| Admin           | `pages/admin_page.dart`           | Section cards + audit logs                       |
| Settings        | `pages/settings_page.dart`        | Theme, thresholds, notifications                 |
| Placeholders    | `widgets/placeholder_page.dart`   | Gateways, Mine Zones, Analytics, Shifts, Visitors, Audit Logs, System Health |

---

## Theming

Themes are defined in `lib/theme/app_theme.dart`:

- `AppTheme.light()` and `AppTheme.dark()` produce `ThemeData` with the `Inter`
  font family and a shared text theme.
- `AppColors` holds the brand and semantic colour constants.
- `SurfaceTokens` (via `tokensOf(context)`) gives pages a compact set of
  contextual colours (`card`, `bg`, `fg`, `muted`, `border`, `mutedBg`,
  `isDark`) derived from the current `ThemeData`.

Dark mode is toggled at runtime via `AppState.toggleDarkMode()` (top-bar
button); `MaterialApp` switches `themeMode` accordingly.

---

## Data

All data is **mocked** and lives in `lib/data/mock_data.dart`:

- `workers` — 11 underground workers with zone, BLE tag, battery, signal, status
- `gateways` — 10 KNOT gateways with signal, power, UPS, temperature, online
- `alerts` — 9 alert items with severity, status, assignment
- `recentEvents` — feed of timestamped events
- `bleDevices` — 28 BLE tags
- `auditLogs` — admin audit log entries
- `navSections` — sidebar navigation grouping
- chart datasets (`batteryPie`, `workerDist`, `signalTrend`, …)

There is no backend. To wire up a real API, replace the `mock_data.dart`
constants with repository calls and feed results into `AppState` (or dedicated
`ChangeNotifier`s).

---

## Troubleshooting

**Text is invisible / glyphs don't render**
Inter must be bundled and registered. Confirm `pubspec.yaml` has the `fonts:`
block declaring `family: Inter` and that `fonts/Inter-*.ttf` exist, then
`flutter pub get` and rebuild. In the built output, verify
`build/web/assets/fonts/Inter-Regular.ttf` exists and
`build/web/assets/FontManifest.json` lists `Inter`.

**404s for `fonts.gstatic.com/...` offline**
These are symbol/emoji fallback requests. They are non-fatal — regular text
renders via bundled Inter. To silence them entirely, keep the bundled Noto
fallback fonts in `web/fonts/` (already included) and ensure
`fontFallbackBaseUrl='/fonts/'` in `index.html`'s loader patch.

**404 for `/canvaskit/canvaskit.js`**
You built without `--dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/`, or the
`canvaskit/` folder is missing from the deployed `build/web/`. Rebuild with the
dart-define and deploy the whole `build/web/` directory.

**Stale content after a redeploy**
The `index.html` interceptor busts old service workers on first load and reloads
once. If you still see stale assets, hard-reload (Cmd/Ctrl+Shift+R) and check
that your static host sets `Cache-Control: no-cache` on `index.html` and the
bootstrap JS files (see the nginx config above).

**Blank page on a sub-path**
Set `--base-href=/your-sub-path/` **and** adjust
`FLUTTER_WEB_CANVASKIT_URL` to include the same sub-path.

**`flutter analyze` warnings**
The codebase has ~69 info-level deprecation warnings (`withOpacity`,
`MaterialStateProperty`, `background`). These are pre-existing and harmless;
there are **0 errors**.

**Icons missing**
Rebuild with `--no-tree-shake-icons`.

---

# Backend Architecture — MineTrack Full System

## System Overview

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Frontend** | Flutter Web (SDK ^3.11) | Live tracking dashboard, personnel management, reports |
| **MQTT Broker** | RabbitMQ with EMQX plugin / Railway managed | Receives BLE detection events from KNOT devices |
| **Ingestion Module** | Spring Boot 3.2 + Apache Camel | Consumes MQTT, processes BLE detections, computes positions |
| **Tracking Module** | Spring Boot 3.2 + PostgreSQL | Worker positions, movement history, zone management, SSE streaming |
| **Alert Module** | Spring Boot 3.2 + PostgreSQL | Alert lifecycle, geofence violations, SOS triggers |
| **Admin Module** | Spring Boot 3.2 + Keycloak | User management, BLE devices, reports, OAuth2 JWT validation |
| **Simulator** | Spring Boot 3.2 + Paho MQTT | Simulates KNOT BLE detections and gateway health for demos |
| **Identity** | Keycloak (Docker) | OAuth2 / OIDC with PKCE, realm roles, user management |
| **Hosting** | Railway.app | Single Docker container + PostgreSQL + RabbitMQ + Keycloak |

### Architecture Diagram

```
┌─────────────────┐     MQTT              ┌──────────────────┐
│ MikroTik KNOT   │ ───────────────────>  │  Ingestion       │
│ (BLE scanner +  │                       │  Module          │
│  BEAM mesh)     │                       │  (Camel + MQTT)  │
└─────────────────┘                       └───────┬──────────┘
                                                  │ Direct calls
                                    ┌─────────────▼─────────────┐
                                    │        Tracking Module     │
                                    │  (positions + SSE stream)  │
                                    └─────────────┬─────────────┘
                                                  │
                                    ┌─────────────▼─────────────┐
                                    │         Alert Module       │
                                    │  (alerts + geofence)       │
                                    └─────────────┬─────────────┘
                                                  │
                                   HTTP + SSE     │     JWT      ┌──────────┐
                                ┌─────────────────▼─────────────▼┐         │
                                │     Flutter Web Dashboard       │<--------│ Keycloak│
                                └────────────────────────────────┘         └─────────┘

                                  PostgreSQL (Railway)
                                  RabbitMQ/MQTT (Railway)
                                  KNOT Simulator (Docker, demo only)
```

---

## Modules (Separation of Concerns)

Each module is a separate Maven package within a single Spring Boot application, deployed as one Docker container on Railway.

### 1. Ingestion Module

**Why separate**: Decouples high-throughput MQTT data collection from business logic. Uses Apache Camel for complex routing patterns.

| Responsibility | Detail |
|---------------|--------|
| MQTT consumer | Subscribes to `minetrack/ble/detections` and `minetrack/gateways/{id}/status` |
| BLE parsing | Extracts MAC, RSSI, battery level, tag ID from KNOT JSON events |
| Nearest gateway | Aggregates RSSI across multiple KNOTs detecting same tag, selects strongest |
| Gateway health | Processes CPU, temperature, UPS, battery health telemetry from KNOTs |
| Deduplication | Ignores duplicate detections within 10-second time window |

### 2. Tracking Module (Core — Demo Star)

**Why separate**: High-frequency position updates need optimized read/write paths. SSE streaming and geofence logic are independent from alert handling.

| Responsibility | REST Endpoint | Detail |
|---------------|---------------|--------|
| Worker positions | `GET /api/workers/current` | All workers with live location, zone, signal, battery |
| Worker detail | `GET /api/workers/{id}` | Full worker profile with last 50 movements |
| Position history | `GET /api/workers/history?workerId=&from=&to=` | Historical movement data for reports |
| Gateway status | `GET /api/gateways/status` | KNOT health dashboard with uptime, temp, battery |
| Zone list | `GET /api/zones` | Mine zones with boundaries and restrictions |
| SSE stream | `GET /api/stream/positions` | Real-time position pushes to Flutter map |
| Worker register | `POST /api/workers/register` | Add new worker with BLE tag assignment |

### 3. Alert Module

**Why separate**: Alerts have independent lifecycle (open → in-progress → closed), assignment tracking, severity escalation. Different data models from tracking.

| Responsibility | REST Endpoint | Detail |
|---------------|---------------|--------|
| Alert list | `GET /api/alerts?severity=&status=&type=` | Filterable alert feed with pagination |
| Alert detail | `GET /api/alerts/{id}` | Full alert info with assignment history |
| Assign alert | `POST /api/alerts/{id}/assign` | Assign to user/team |
| Close alert | `POST /api/alerts/{id}/close` | Resolve alert with notes |
| Alert stats | `GET /api/alerts/stats` | KPI counts: critical, warnings, open, resolved |
| Geofence events | In-process trigger | Listening for zone boundary violations from Tracking |
| SSE alerts | Part of stream | Pushes new critical alerts to Flutter in real-time |

### 4. Admin Module

**Why separate**: Centralizes user management, Keycloak integration, device inventory, and report aggregation. Single auth boundary for all Flutter backend calls.

| Responsibility | REST Endpoint | Detail |
|---------------|---------------|--------|
| JWT validation | Spring Security filter | OAuth2 Resource Server — validates all Flutter tokens |
| User management | `GET/POST /api/users` | Create, list users synced with Keycloak roles |
| BLE devices | `GET/POST /api/ble-devices` | Tag inventory, assign/deactivate tags |
| Reports | `GET /api/reports/{type}` | Daily personnel, shift report, attendance, battery health |
| Audit log | `GET /api/audit-log` | System activity history |
| Mine config | `GET/PUT /api/config/mine` | Zones, departments, shifts, notification thresholds |

### 5. KNOT Device Simulator (Demo Only)

**Why separate**: Demo must work reliably even without physical hardware. Simulates full KNOT behavior so the end-to-end pipeline is demonstrable.

| Responsibility | Detail |
|---------------|--------|
| BLE detection simulation | Publishes realistic events with changing RSSI, battery, timestamps |
| Worker movement | Positions shift over time to make map appear alive |
| Gateway health | Cycles through normal/warning/critical states per KNOT |
| Demo scenarios | Normal shift, emergency drill, geofence breach triggered on demand |

---

## Data Models

| Entity | Module | Key Fields | Purpose |
|--------|--------|-----------|---------|
| **WorkerPosition** | Tracking | workerId, name, zone, bleTag, battery, signalDbm, status, x/y, lastSeen | Current live worker state |
| **MovementHistory** | Tracking | workerId, zone, x/y, timestamp | Historical movement for reports |
| **Alert** | Alert | severity, type, message, location, assignedTo, status, timestamp | Alert lifecycle management |
| **GatewayHealth** | Tracking | gatewayId, location, signalDbm, powerSource, ups, temperature, batteryHealth, online | KNOT device monitoring |
| **BleDevice** | Admin | tagId, battery, firmwareVersion, status, assignedWorker, lastDetected | BLE tag inventory |
| **Zone** | Tracking | id, name, department, minX/minY/maxX/maxY, isRestricted | Mine zone definitions + geofence boundaries |

---

## Communication Patterns

| Channel | Direction | Protocol | Purpose |
|---------|-----------|----------|---------|
| KNOT → Backend | Device → Ingestion | MQTT on RabbitMQ | BLE detections + gateway health |
| Ingestion → Tracking | Same container | Direct method call | Processed detection events |
| Tracking → Alert | Same container | Direct method call | Geofence violations, emergency triggers |
| Backend → Flutter | Server → Client | REST HTTP + SSE | Data fetches + real-time position pushes |
| Flutter → Backend | Client → Server | REST HTTP + JWT | Authenticated API calls |
| Flutter ↔ Keycloak | App ↔ Identity | OAuth2 / OIDC PKCE | Login, token issuance, role validation |

---

## MQTT Topic Structure

| Topic | Direction | Content |
|-------|-----------|---------|
| `minetrack/ble/detections` | KNOT → Backend | `{type, gateway, timestamp, ble_mac, rssi, battery_level, tag_id}` |
| `minetrack/gateways/{id}/status` | KNOT → Backend | `{cpu, temperature, batteryHealth, online, lastComm}` |
| `minetrack/commands/{id}` | Backend → KNOT | Control commands (future) |

---

## Keycloak Configuration

| Setting | Value |
|---------|-------|
| Realm | `minetrack` |
| Flutter client | `minetrack-web` — OpenID Connect, Authorization Code + PKCE |
| Service clients | `tracking-svc`, `alert-svc`, `admin-svc` — confidential |
| Demo client | `knot-simulator` — public |

### Roles (Realm Roles)

| Role | Access Level |
|------|-------------|
| `SURFACE_ADMIN` | Full admin: users, config, reports, all pages |
| `SAFETY_OFFICER` | View alerts, assign incidents, view tracking and reports |
| `MINE_SUPERVISOR` | Live tracking, personnel, reports, BLE devices |
| `OPERATOR` | Dashboard read-only, live tracking map |

---

## Railway Deployment

### Infrastructure
| Resource | Specification |
|----------|--------------|
| PostgreSQL | Managed, 1GB storage |
| RabbitMQ | With EMQX MQTT plugin enabled |
| Keycloak | Docker image, 1GB RAM, H2 storage for demo |

### Application (Single Docker Container)
| Module | Memory | Port |
|--------|--------|------|
| Ingestion (Camel + MQTT) | 256MB | Embedded — shares app port |
| Tracking (REST + SSE) | 512MB | 8080 |
| Alert | 256MB | Embedded — shares app port |
| Admin (Auth + Reports) | 512MB | Embedded — shares app port |
| KNOT Simulator | 256MB | Embedded — shares app port |

### Dockerfile
```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

### Environment Variables
| Variable | Example Value | Purpose |
|----------|--------------|---------|
| `DATABASE_URL` | `postgresql://user:pass@host:5432/minetrack` | PostgreSQL connection |
| `RABBITMQ_URL` | `amqp://user:pass@host:5672` | RabbitMQ connection |
| `MQTT_BROKER_URL` | `mqtt://host:1883` | MQTT broker for Camel routes |
| `KEYCLOCK_URL` | `https://minetrack-keycloak.railway.app` | Keycloak server URL |
| `KEYCLOCK_REALM` | `minetrack` | Keycloak realm name |

---

## Flutter Changes Required

| Area | Current State | Required Change |
|------|-------------|-----------------|
| **Auth** | Mock login (any input works) | Keycloak PKCE flow + token storage |
| **Data** | Static `mock_data.dart` | Repository pattern with HTTP calls to backend |
| **Live updates** | None (static mock data) | SSE listener for real-time position pushes |
| **State** | Single `AppState` ChangeNotifier | Per-page state with API sync + SSE stream |
| **API client** | None | HTTP client with JWT bearer token interceptor |

### Page-by-Page API Mapping

| Flutter Page | Backend API(s) Called |
|-------------|----------------------|
| Login | Keycloak PKCE redirect + token exchange |
| Dashboard | `GET /api/workers/current`, `/api/gateways/status`, `/api/alerts/stats`, SSE stream |
| Live Tracking | `GET /api/workers/current`, `/api/workers/{id}`, SSE positions, `/api/zones` |
| Personnel | `GET/POST /api/workers`, search/filter via query params |
| BLE Devices | `GET /api/ble-devices?status=`, `/api/ble-devices/assign` |
| Alerts | `GET /api/alerts?filter=`, `/api/alerts/{id}/assign`, `/api/alerts/{id}/close` |
| Reports | `GET /api/reports/{type}` — daily, shift, battery, attendance, etc. |
| Admin | `GET/POST /api/users`, `/api/config/mine`, `/api/audit-log` |
| Settings | `PUT /api/config/thresholds` — battery/signal thresholds, notification toggles |

---

## 13-Day Implementation Schedule

### Phase 1: Foundation (Days 1–3, Jul 19–21)

| Day | Task | Owner |
|-----|------|-------|
| **1** | Railway project setup: provision PostgreSQL + RabbitMQ | Dev A |
| **1** | Keycloak Docker deployment: realm, clients, roles, test users | Dev A |
| **2** | Tracking module: entity classes + JPA repositories (WorkerPosition, MovementHistory, Zone, GatewayHealth) | Dev B |
| **2** | Admin module: BleDevice entity + REST controllers for devices, users, config | Dev B |
| **3** | Alert module: Alert entity + CRUD REST API + seed data | Dev C |
| **3** | Security: Spring Security OAuth2 Resource Server in all modules, Keycloak JWT validation filter | Dev A + B |

### Phase 2: Data Pipeline (Days 4–6, Jul 22–24)

| Day | Task | Owner |
|-----|------|-------|
| **4** | KNOT Simulator: MQTT publishers for BLE detections + gateway health + worker movement | Dev A |
| **4** | Ingestion module: Apache Camel MQTT routes, BLE event parser, RSSI nearest-gateway logic | Dev A |
| **5** | Tracking module: REST endpoints (`/current`, `/history`, `/gateways/status`) + position upsert | Dev B |
| **5** | Tracking module: SSE endpoint for real-time position stream to Flutter | Dev B |
| **6** | Alert module: geofence violation trigger + assign/close endpoints + SSE alert push | Dev C |
| **6** | Alert module: `/api/alerts/stats` KPI aggregation + `/api/alerts/types` definitions | Dev C |

### Phase 3: Flutter Integration (Days 7–10, Jul 25–28)

| Day | Task | Owner |
|-----|------|-------|
| **7** | Flutter: Keycloak PKCE login flow + `flutter_secure_storage` for tokens + auth interceptor | Dev B |
| **7** | Flutter: Replace `mock_data.dart` with repository pattern (HTTP + JSON serialization) | Dev B or C |
| **8** | Flutter: SSE listener — connect to `/api/stream/positions`, update map live | Dev B |
| **8–9** | Flutter: Wire all 9 pages to backend APIs (Dashboard, Live Tracking, Personnel, BLE Devices, Alerts) | Dev C |
| **9–10** | Flutter: Admin page, Settings page (thresholds), Reports page, search/filter from API | Dev C |

### Phase 4: Polish & Demo (Days 11–13, Jul 29–31)

| Day | Task | Owner |
|-----|------|-------|
| **11** | Full end-to-end test: KNOT Simulator → MQTT → Backend → Flutter. Fix all broken flows | All |
| **11** | Simulator: demo scenarios (normal shift, emergency drill, geofence breach) | Dev A |
| **12** | SSE stability + map performance with live updates, HTTP polling fallback if SSE drops | Dev B |
| **12** | Reports module: aggregation endpoints (daily, shift, battery, attendance) | Dev C |
| **13** | Final demo dry run (2+ hours), fix remaining issues, deploy to Railway for live demo | All |

---

## 15-Minute Demo Script

| Time | Section | What You Show |
|------|---------|--------------|
| 0:30 | **Login** | Keycloak PKCE login screen — real OAuth2 flow, not mock |
| 1:30 | **Dashboard** | Live KPI cards updating in real-time. Switch Personnel/Gateway tabs |
| 5:30 | **Live Tracking Map** | Workers moving underground in real-time. Hover tooltips with BLE tag/battery/signal. Layer switching (normal/heatmap/gas). Click worker for detailed panel |
| 7:30 | **Geofence Breach** | Trigger simulator event: worker enters restricted gas zone. Alert appears instantly on Dashboard and map flashes red |
| 9:30 | **Alert Workflow** | Assign alert to safety officer. Mark as in-progress. Close with resolution notes |
| 10:30 | **Personnel + BLE** | Register new worker with BLE tag. Show device inventory, filter by status, reassign tag |
| 11:30 | **Reports** | Generate Daily Personnel Report, Battery Health breakdown, Gateway Uptime chart |
| 12:30 | **Gateway Health** | Show KNOT device panel — temperature, battery, uptime, signal strength for all 10 gateways |
| 13:30 | **SOS Emergency** | Trigger SOS from simulator. Critical alert with blinking indicator. Map highlights emergency worker |
| 15:00 | **Summary** | Full stack recap: KNOT BLE detection → MQTT → Spring Boot/Camel → PostgreSQL → SSE → Flutter web on Railway |

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Railway MQTT support limited | Ingestion can't receive KNOT data | Use RabbitMQ with EMQX Docker image which includes native MQTT support |
| Keycloak consumes too much memory on Railway | OOM kills, service crashes | Allocate 1GB minimum, use H2 in-memory storage for demo |
| SSE connections unstable on Railway | Flutter stops receiving position updates | Implement HTTP polling fallback (30s interval) that activates automatically if SSE drops |
| Physical KNOT BLE scanning unreliable for demo | Map shows stale or no worker positions | KNOT Simulator always active as primary source; physical tags are bonus, not requirement |
| Too many modules for 13 days | Delays and integration failures | Modular monolith: single Docker container, direct method calls. Clean code separation, simple deployment |
| Keycloak setup complexity on Railway | Auth delays block all other work | Provision Keycloak on Day 1, create test users immediately. Use `quay.io/keycloak/keycloak` Docker image |

---

## Quick Start (Local Development)

### Prerequisites
- Flutter SDK ^3.11, Dart SDK
- Java 21+, Maven 3.9+
- Docker + Docker Compose

### Infrastructure (Day 1)
```bash
# Start PostgreSQL, RabbitMQ with MQTT, Keycloak
docker compose up -d

# Wait for services, then run backend
cd backend/
mvn clean package -DskipTests
java -jar target/mminetrack.jar

# Run Flutter app
cd flutter_app/
flutter pub get
flutter run -d chrome
```

Built for MineTrack by InnovAI Technologies. Font: Inter (SIL Open Font
License). CanvasKit is part of the Flutter engine (BSD-style license).