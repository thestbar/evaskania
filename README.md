# e-Vaskania

A pocket-sized Greek yiayia app. Two rituals, one photo each:

- **Ξεμάτιασμα** — snap a photo of a person, get ξεματιασμένος/η. Needs exactly **one face**.
- **Ο Καφές** — snap a photo of a coffee cup, get a fortune. Needs **a cup**.

Both checks run **on your phone**, on-device. No server, no upload, no account.

## Run it

```bash
cd app
flutter pub get
flutter run
```

Needs Flutter installed and a simulator/device connected. That's it.

## Build an installable APK (Android)

```bash
cd app
flutter build apk --release
# → app/build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Stack

Flutter · Dart · Google ML Kit (face detection + image labeling, both on-device)

## Docs

- [`docs/superpowers/specs/`](docs/superpowers/specs/) — what this app is and why
- [`docs/superpowers/plans/`](docs/superpowers/plans/) — how it was built, task by task

## Status

Works. Detection is deliberately coarse — it checks "is there a face" / "is there a cup," not ritual-specific detail (e.g. it can't tell if the cup is empty).
