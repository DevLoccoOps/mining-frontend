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

## License & credits

Built for MineTrack by InnovAI Technologies. Font: Inter (SIL Open Font
License). CanvasKit is part of the Flutter engine (BSD-style license).