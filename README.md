# Mira VPN — Android app

Flutter client for the Mira VPN WireGuard service. Talks to the `mira-vpn-backend`
to register / sign in users, provision WireGuard peers, and bring up a tunnel on
Android via `wireguard_flutter_plus`.

Phase 1 target: single server (Finland), three tabs (Home / Premium / Me),
email + password auth, AdMob on the free tier, Google Play Billing on Pro.

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

Run against a local backend (emulator loopback to host):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
# or: ./run_dev.sh   (defaults API_BASE_URL; override: API_BASE_URL=http://host:8080 ./run_dev.sh)
```

Run against a deployed backend:

```bash
flutter run --dart-define=API_BASE_URL=https://api.mira-vpn.example
```

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

## License

See [LICENSE](./LICENSE).
