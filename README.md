# Mira VPN — Android app

Flutter client for the Mira VPN WireGuard service. Talks to the `mira-vpn-backend`
to register / sign in users, provision WireGuard peers, and bring up a tunnel on
Android via `wireguard_flutter_plus`.

The app loads **VPN regions** from `GET /wireguard/locations` (server list and
display names come from the backend registry). How those servers are defined
(JSON, env vars, WireGuard host requirements) is documented in the backend repo:
[`mira-vpn-backend/docs/wireguard-locations.md`](../mira-vpn-backend/docs/wireguard-locations.md).

Phase 1 target: three tabs (Home / Premium / Me), email + password auth, AdMob
on the free tier, Google Play Billing on Pro, multi-region server selection when
the API exposes more than one location.

## Requirements

- Flutter stable (tested on 3.24.5)
- Android SDK with an emulator or a physical device (WireGuard needs a real device
  to actually bring up a tunnel)
- Min Android SDK: 24 (WireGuard requirement). Target SDK: 35.

## Getting started

```bash
flutter pub get
flutter analyze
flutter test
```

Run against your current backend:

```bash
flutter run --dart-define=API_BASE_URL=http://95.217.206.233:18080
# or: ./run_dev.sh   (defaults API_BASE_URL; override: API_BASE_URL=http://host:18080 ./run_dev.sh)
```

Run against a deployed backend:

```bash
flutter run --dart-define=API_BASE_URL=https://api.mira-vpn.example
```

### Web preview (UI only)

Flutter web **debug** builds are slow to load (large script, unoptimized). On desktop
browsers the default **CanvasKit** renderer also downloads a heavy WASM bundle. For a
lighter first load while checking layout:

```bash
chmod +x run_web.sh   # once
./run_web.sh
# faster runtime (slower compile): MODE=release ./run_web.sh
```

Then open the URL printed in the terminal (e.g. `http://localhost:7357`). VPN
features are not supported on web; this is for UI/navigation only.

## Layout

```
lib/
  main.dart
  app.dart              (later steps)
  core/
    config/             env / flavor
    theme/              design tokens + reusable widgets
    routing/            go_router
    api/                dio client + DTOs
    storage/            secure storage wrappers
    vpn/                wireguard_flutter_plus wrapper
    ads/                google_mobile_ads wrapper
    billing/            in_app_purchase wrapper
  features/
    home/               connect screen
    auth/               sign in / sign up
    premium/            upgrade screen
    me/                 account screen
    splash/             bootstrap
test/
android/
```

## Android identifiers

- `applicationId` / namespace: `com.mira.mira_vpn_app` (locked — this is the Play
  Console app id for the lifetime of the app)

## Billing (Step 13)

- Product ids wired in app:
  - `mira_vpn_pro_monthly`
  - `mira_vpn_pro_annual`
- The app sends purchase tokens to backend `POST /billing/verify`, then refreshes
  `GET /auth/me` so `isPro` updates immediately.
- If `/billing/verify` is not deployed yet, purchase verification will fail with a
  clear in-app message.

## Release prep (Step 14)

- Configure icon/splash generation:
  - `flutter_launcher_icons`
  - `flutter_native_splash`
- Add image assets before generation:
  - `assets/icons/app_icon.png`
  - `assets/icons/splash_logo.png`
- Generate assets:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

- Release signing:
  - Place keystore outside git.
  - Create `android/key.properties` (already gitignored) with:
    - `storeFile=...`
    - `storePassword=...`
    - `keyAlias=...`
    - `keyPassword=...`
- Build release bundle:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.mira-vpn.example
```

- Publish a public privacy policy URL before Play submission (required by Play and AdMob).

## CI (Step 15)

- GitHub Actions workflow at `.github/workflows/flutter.yml` runs:
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`
- Enable branch protection in GitHub settings and require this workflow on `main`.

## License

See [LICENSE](./LICENSE).
