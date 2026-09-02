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

## Testing

```bash
cd app
flutter test                                                                  # unit + widget tests

# real ML Kit, on a device/emulator — run BOTH, they catch different bugs:
flutter test integration_test/detection_regression_test.dart -d <device>            # debug
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/detection_regression_test.dart -d <device> --profile    # minified, like release
```

The unit tests fake out ML Kit (platform channels don't work in `flutter
test`'s headless mode), so they can't catch platform-level regressions —
that's what the integration tests are for. Two real bugs made every photo
get rejected on a real phone, and each needed a different one of the two
runs above to catch:

- ML Kit's face detector reliably missed faces cropped tight to the frame
  edges (the **debug** run catches this) — fixed in
  `app/lib/detection/face_checker.dart`.
- The **release/minified** build crashed inside Google Play Services' ML
  Kit glue — the plugin's own ProGuard rules don't cover it (only the
  **profile** run, which is minified the same way release is, catches
  this) — fixed in `app/android/app/proguard-rules.pro`.

## Docs

- [`docs/superpowers/specs/`](docs/superpowers/specs/) — what this app is and why
- [`docs/superpowers/plans/`](docs/superpowers/plans/) — how it was built, task by task

## Status

Works. Detection is deliberately coarse — it checks "is there a face" / "is there a cup," not ritual-specific detail (e.g. it can't tell if the cup is empty).
