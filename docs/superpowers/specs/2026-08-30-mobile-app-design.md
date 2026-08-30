# e-Vaskania mobile app — design spec

Date: 2026-08-30

## Overview

`e-Vaskania` currently exists as a static, browser-only mockup (`e-Vaskania.dc.html` +
the Broadsheet design-system assets) built via Claude's design tool. It renders two
playful "yiayia ritual" flows — Ξεμάτιασμα (evil-eye removal) and Ο Καφές (coffee-cup
reading) — but the outcome of each is simply randomized; nothing looks at the uploaded
photo.

This spec covers turning that mockup into a real, installable mobile app with actual
image validation:

- **Ξεμάτιασμα** must reject a photo that isn't a single human face.
- **Ο Καφές** must reject a photo that isn't a coffee cup.

## Architecture & tech stack

- **Flutter (Dart)**, one codebase targeting iOS and Android.
- **No backend.** All logic, including image analysis, runs on-device. Photos never
  leave the phone.
- **Detection packages** (the `google_mlkit_*` Flutter plugin family — official-quality
  wrappers around Google's on-device ML Kit SDKs):
  - `google_mlkit_face_detection` for the Ξεμάτιασμα check.
  - `google_mlkit_image_labeling` for the Ο Καφές check — **not** the ML Kit Object
    Detection API, whose on-device classifier only sorts into 5 broad buckets (Fashion
    good / Food / Home good / Place / Plant) and isn't cup-specific. Image Labeling is
    a general ImageNet-family classifier that returns labels like "Cup," "Coffee cup,"
    "Mug," "Drinkware" with confidence scores, which is what the coarse check needs.
- **`image_picker`** (official Flutter package) for camera + gallery photo selection.

**Known trade-offs, accepted for v1:**
- Bundling on-device ML models adds meaningful app size (tens of MB).
- Android face detection requires Google Play Services (present on effectively all
  real Android devices; not on Play-Services-less forks — not designed around).
- The checks are deliberately coarse ("is there a face," "is there a cup-shaped
  object"), not a verification of ritual-specific detail (e.g. the coffee check can't
  confirm the cup is empty or that grounds are visible on the walls — no pretrained
  model exists for that; doing so would require a server call to a vision-capable AI
  model, which was explicitly ruled out for this app).

## Project structure

- Keep the existing web mockup files (`e-Vaskania.dc.html`, `_ds/`, `support.js`,
  `image-slot.js`) at the repo root as the design reference — they are not deleted or
  modified.
- New Flutter project lives in `app/`.
- This spec lives in `docs/superpowers/specs/`; the implementation plan will too.

## Design system port (Broadsheet → Flutter)

Port the Broadsheet tokens (colors, Source Serif 4 type scale, spacing, radii,
shadows) from `_ds/broadsheet-.../styles.css` into:
- A Flutter `ThemeData` (colors, text theme).
- An `AppTokens` class of constants for anything `ThemeData` doesn't model directly
  (the accent tonal ramps, spacing scale), referenced the way the CSS referenced
  `var(--color-accent)` etc.
- Source Serif 4 bundled as a local font asset (via `google_fonts` package or vendored
  `.ttf` files) rather than the web version's Google Fonts CSS `@import`, so it works
  offline immediately.

**Explicitly not ported:** the CMYK print-plate hover effect (`print-plates.js`). It's
a mouse-pointer-driven effect that doesn't translate to touch, and isn't used on the
two ritual screens anyway (only foundations/deck pages).

**Reusable widgets:** `AppCard`, `PrimaryButton`, `SecondaryButton`, `GhostIconButton`,
and an `ImageSlot` widget (placeholder + pick button + preview + "Replace" action).
`ImageSlot` intentionally does **not** port the web version's pan/zoom/reframe
cropping — pick → preview → replace only, keeping v1 scope tight.

## Screens & navigation

A single enum-based app state (no routing library needed — this is a single-screen-
at-a-time flow, not a deep navigation stack), directly porting the mockup's states
plus new rejection states:

```
home
  → xem-form → xem-loading → xem-removing → xem-result
             → xem-rejected (no face / multiple faces)
  → coffee-form → coffee-loading → coffee-result
                → coffee-rejected (no cup)
```

Screen content, copy, and the randomized-outcome logic (which affliction / which
coffee verdict) for the "success" paths are ported as-is from the existing
`e-Vaskania.dc.html` Component class.

## Detection features

### When the check runs

At submit time (tapping "Ξεκίνα το ξεμάτιασμα" / "Δωσ' μου το φλιτζάνι"), **before**
the loading animation — a bad photo is rejected immediately instead of after making
the user wait through "η γιαγιά συγκεντρώνεται…" for nothing.

### Face check (Ξεμάτιασμα)

Run `FaceDetector.processImage()` on the picked photo. Three outcomes:
- **0 faces** → reject, "no face" message.
- **2+ faces** → reject, "one at a time" message. Grandma ξεματιάζει one person at a
  time, not a group photo.
- **Exactly 1 face**, with bounding box ≥ ~5% of image area (filters out a stray face
  in a background poster) → pass, proceed to `xem-loading`.

### Cup check (Ο Καφές)

Run `ImageLabeler.processImage()`. Pass if any label in
`{Cup, Coffee cup, Mug, Espresso, Teacup, Drinkware, Saucer, Tableware}` scores above
~0.6 confidence. Otherwise reject, "not a cup" message.

### Rejection screens

Reuse the existing screen chrome (back button + title + card), swapped in for the
loading/result states when a check fails. Draft copy (tone/wording adjustable during
implementation, mechanism is locked):

**Ξεμάτιασμα — no face found:**
> Καρτ: "Δεν βλέπω πρόσωπο εδώ"
> "Η γιαγιά χρειάζεται να δει ένα πρόσωπο για να διώξει το μάτι — δοκίμασε μια
> φωτογραφία που να φαίνεται καθαρά κάποιος."
> Button: **Δοκίμασε ξανά** → back to `xem-form`, photo cleared

**Ξεμάτιασμα — multiple faces found:**
> Καρτ: "Ένας-ένας, παρακαλώ"
> "Η γιαγιά ξεματιάζει έναν άνθρωπο τη φορά — ανέβασε φωτογραφία με ένα μόνο
> πρόσωπο."
> Button: **Δοκίμασε ξανά** → back to `xem-form`, photo cleared

**Ο Καφές — no cup found:**
> Καρτ: "Αυτό δεν είναι φλιτζάνι"
> "Η γιαγιά διαβάζει μόνο καφέ — ανέβασε μια φωτογραφία του φλιτζανιού, γυρισμένο,
> με το κατακάθι στα τοιχώματα."
> Button: **Δοκίμασε ξανά** → back to `coffee-form`, photo cleared

## Out of scope (v1)

- No backend / server-side vision AI (ruled out explicitly; static/on-device only).
- No history or persistence of past readings — each session is ephemeral, matching
  the current mockup.
- No image crop/reframe/pan in `ImageSlot`.
- No verification that the coffee cup is specifically *empty* or that grounds are
  specifically *visible* — only that a cup-like object is present. Noted as a
  possible future upgrade path requiring a server-side vision AI call.

## Testing strategy

- Widget tests for the state machine (all screen transitions, including the new
  rejected states) and for the design-token widgets.
- The ML detection logic itself isn't realistically unit-testable (it depends on the
  on-device model's actual behavior), so it's structured behind a small interface
  (`FaceChecker`, `CupChecker`) and verified manually on-device with a handful of real
  test photos during implementation (a selfie, a group photo, a landscape, an actual
  Greek coffee cup, a random mug, a plain object).

## Dev environment setup

Machine currently has Xcode 26.6 installed; Flutter/Dart and CocoaPods are not yet
installed; an Android SDK directory exists at `~/Library/Android/sdk` but isn't on
`PATH`. First step of the implementation plan: install Flutter SDK, install CocoaPods,
wire up the Android SDK/`adb` on `PATH`, and confirm with `flutter doctor`.

## Milestones

One implementation plan, three checkpoints — each leaves working, runnable software:

- **A — App shell:** Flutter scaffold, Broadsheet theme port, all screens/widgets,
  full navigation with the *same simulated random result* logic as today's mockup (no
  real detection yet).
- **B — Face detection:** wire `image_picker` + `google_mlkit_face_detection` into the
  Ξεμάτιασμα flow; add the 0/1/2+ face branching and rejection screens.
- **C — Cup detection:** wire the same picker pattern + `google_mlkit_image_labeling`
  into the Ο Καφές flow; add the rejection screen.
