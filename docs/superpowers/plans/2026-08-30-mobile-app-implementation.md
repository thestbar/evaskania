# e-Vaskania mobile app Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the static `e-Vaskania.dc.html` web mockup into a real, installable Flutter app (iOS + Android) with on-device face detection gating Ξεμάτιασμα and on-device cup detection gating Ο Καφές.

**Architecture:** A single Flutter project (`app/`) with no backend. An enum-based `AppScreen` state machine (`AppStateController`, a `ChangeNotifier`) drives which screen renders, directly porting the mockup's flow. Detection is isolated behind two small checker classes (`FaceChecker`, `CupChecker`) that wrap Google ML Kit plugins behind a testable seam.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2 (already installed via Homebrew). Packages: `image_picker` (camera/gallery), `google_mlkit_face_detection` + `google_mlkit_image_labeling` + `google_mlkit_commons` (on-device ML), `intl` (Greek date/time formatting). Source Serif 4 bundled as local variable-font assets (no `google_fonts` package — that fetches over network at runtime, which would break the "works offline immediately" requirement).

**Spec:** `docs/superpowers/specs/2026-08-30-mobile-app-design.md`

## Global Constraints

- No backend. All logic, including image analysis, runs on-device — verified in the spec's architecture section.
- Face check: pass only if **exactly 1** face is detected with bounding-box area ≥ 5% of the image area. 0 faces → "no face" rejection. 2+ faces → "one at a time" rejection.
- Cup check: pass if any ML Kit Image Labeling result in `{Cup, Coffee cup, Mug, Espresso, Teacup, Drinkware, Saucer, Tableware}` (case-insensitive) scores ≥ 0.6 confidence.
- Use `google_mlkit_image_labeling` for the cup check, **not** `google_mlkit_object_detection` (its on-device classifier only sorts into 5 broad buckets, not cup-specific — decided and justified in the spec).
- Detection runs at submit time, before the loading animation, so a bad photo is rejected immediately.
- Ephemeral state only — no persistence/history (explicit spec out-of-scope item).
- `ImageSlot` is pick → preview → replace only — no crop/pan/reframe (explicit spec out-of-scope item).
- Keep the existing web mockup files at the repo root untouched; the Flutter project lives entirely under `app/`.
- Every screen's Greek copy is ported verbatim from `e-Vaskania.dc.html` (or, for the two new rejection screens, verbatim from the spec's drafted copy) — do not rephrase during implementation.
- Elaborate CSS keyframe animations from the mockup (confetti pop, bounce, pulsing loading icon, CMYK print-plate hover) are **not** ported — screens render statically. This is a deliberate v1 simplification (not in the original spec's out-of-scope list, but consistent with it); flag to the user if richer motion is wanted later.

---

## Task A1: Flutter project scaffold + dev environment finalization

**Files:**
- Create: `app/` (entire Flutter project via `flutter create`)
- Modify: `app/pubspec.yaml`
- Create: `app/assets/fonts/SourceSerif4-Variable.ttf`
- Create: `app/assets/fonts/SourceSerif4-Italic-Variable.ttf`

**Interfaces:** None yet — this task produces the project shell every later task builds inside.

- [ ] **Step 1: Finish the Android toolchain**

The SDK at `~/Library/Android/sdk` already has platform-tools, build-tools, platforms, and an accepted `android-sdk-license` file — it's only missing `cmdline-tools` (confirmed by inspecting the directory during planning). Fetch it via Homebrew's cask (which downloads and caches it) and copy just the `cmdline-tools/latest` folder into the existing SDK root, so nothing is duplicated:

```bash
brew install --cask android-commandlinetools
mkdir -p ~/Library/Android/sdk/cmdline-tools
cp -R /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest \
      ~/Library/Android/sdk/cmdline-tools/latest
```

Add the SDK tools to `PATH` for future shells (append to `~/.zshrc`, since the shell is zsh):

```bash
cat >> ~/.zshrc << 'EOF'

# Android SDK (added for e-Vaskania Flutter build)
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
EOF
source ~/.zshrc
```

Point Flutter at the SDK and accept any outstanding licenses:

```bash
flutter config --android-sdk "$HOME/Library/Android/sdk"
yes | flutter doctor --android-licenses
```

- [ ] **Step 2: Finish the iOS toolchain**

```bash
brew install cocoapods
```

(The iOS Simulator runtime warning from `flutter doctor` — "iOS 26.5 Simulator not installed" — requires opening Xcode's GUI to download under Settings > Components; leave a note for the user to do this manually since it can't be scripted headlessly. It only blocks running on a simulator, not `flutter build ios --no-codesign` compile checks.)

- [ ] **Step 3: Verify the toolchain**

```bash
flutter doctor
```

Expected: `[✓] Flutter`, `[✓] Chrome`. Android and Xcode sections may still show the iOS Simulator note above, but the `cmdline-tools missing` and `Android license status unknown` lines from before must be gone.

- [ ] **Step 4: Scaffold the Flutter project**

```bash
cd /Users/thestbar/Projects/evaskania
flutter create --org gr.evaskania --project-name evaskania app
```

- [ ] **Step 5: Add dependencies**

Edit `app/pubspec.yaml` — replace the `dependencies:` and `dev_dependencies:` sections (keep everything else `flutter create` generated) with:

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.2.3
  google_mlkit_commons: ^0.13.0
  google_mlkit_face_detection: ^0.15.1
  google_mlkit_image_labeling: ^0.16.1
  intl: ^0.20.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

If `flutter pub get` (next step) fails to resolve one of these, it means a newer major version has since been published — run `flutter pub outdated` and bump that one line's constraint to what it reports, then retry. Don't guess at a version; check.

- [ ] **Step 6: Fetch and bundle the Source Serif 4 variable fonts**

These exact URLs were verified reachable during planning:

```bash
mkdir -p app/assets/fonts
curl -sSL -o app/assets/fonts/SourceSerif4-Variable.ttf \
  "https://raw.githubusercontent.com/google/fonts/main/ofl/sourceserif4/SourceSerif4%5Bopsz,wght%5D.ttf"
curl -sSL -o app/assets/fonts/SourceSerif4-Italic-Variable.ttf \
  "https://raw.githubusercontent.com/google/fonts/main/ofl/sourceserif4/SourceSerif4-Italic%5Bopsz,wght%5D.ttf"
file app/assets/fonts/*.ttf
```

Expected: both report as `TrueType Font data`.

Add the font declaration to `app/pubspec.yaml`'s `flutter:` section (alongside the existing `uses-material-design: true` line `flutter create` generated):

```yaml
  fonts:
    - family: Source Serif 4
      fonts:
        - asset: assets/fonts/SourceSerif4-Variable.ttf
        - asset: assets/fonts/SourceSerif4-Italic-Variable.ttf
          style: italic
```

(These are variable fonts covering the whole weight range in one file each — semibold headings are rendered later with `TextStyle(fontVariations: [FontVariation('wght', 600)])`, not via separate font-weight files.)

- [ ] **Step 7: Install packages and verify the default scaffold**

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

Expected: `flutter analyze` reports "No issues found!" and `flutter test` passes the one default counter-app test `flutter create` generated (we haven't touched `lib/main.dart` yet).

- [ ] **Step 8: Commit**

```bash
cd /Users/thestbar/Projects/evaskania
git add app .zshrc 2>/dev/null; git add app
git commit -m "Scaffold Flutter app project with dependencies and bundled fonts"
```

(`.zshrc` lives outside the repo and isn't tracked — only `app/` is committed here.)

---

## Task A2: Design tokens and theme

**Files:**
- Create: `app/lib/theme/app_tokens.dart`
- Create: `app/lib/theme/app_theme.dart`
- Test: `app/test/theme/app_tokens_test.dart`

**Interfaces:**
- Produces: `AppTokens` (static const `Color`s: `colorBg`, `colorSurface`, `colorText`, `colorAccent`, `colorAccent2`, `accent100`, `accent700`, `accent2_100`, `accent2_700`, `accent2_800`; static `Color get colorDivider`; static const `double`s: `space1..space8`, `radiusSm/Md/Lg`), `AppTheme.light()` returning a `ThemeData`.

- [ ] **Step 1: Write the failing test**

Create `app/test/theme/app_tokens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/theme/app_tokens.dart';

void main() {
  test('colors match the Broadsheet design tokens', () {
    expect(AppTokens.colorBg, const Color(0xFFF3F2F2));
    expect(AppTokens.colorText, const Color(0xFF201E1D));
    expect(AppTokens.colorAccent, const Color(0xFF0088B0));
    expect(AppTokens.colorAccent2, const Color(0xFFD6006C));
  });

  test('spacing scale matches the CSS --space-* values', () {
    expect(AppTokens.space1, 5);
    expect(AppTokens.space2, 10);
    expect(AppTokens.space3, 15);
    expect(AppTokens.space4, 20);
    expect(AppTokens.space8, 40);
  });

  test('colorDivider is the text color at 16% opacity', () {
    final divider = AppTokens.colorDivider;
    expect(divider.toARGB32() & 0x00FFFFFF, 0x00201E1D);
    expect((divider.a * 255).round(), 41); // 16% of 255, rounded
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run (from `app/`): `flutter test test/theme/app_tokens_test.dart`
Expected: FAIL — `package:evaskania/theme/app_tokens.dart` doesn't exist.

- [ ] **Step 3: Write `AppTokens`**

Create `app/lib/theme/app_tokens.dart`:

```dart
import 'package:flutter/material.dart';

/// Design tokens ported from the Broadsheet design system used by the
/// original web mockup (`_ds/broadsheet-.../styles.css` at the repo root).
/// Keep both in sync if the mockup's tokens ever change.
class AppTokens {
  AppTokens._();

  // Colors
  static const Color colorBg = Color(0xFFF3F2F2);
  static const Color colorSurface = Color(0xFFEAE9E9);
  static const Color colorText = Color(0xFF201E1D);
  static const Color colorAccent = Color(0xFF0088B0);
  static const Color colorAccent2 = Color(0xFFD6006C);
  static Color get colorDivider => colorText.withValues(alpha: 0.16);

  static const Color accent100 = Color(0xFFE9F8FF);
  static const Color accent700 = Color(0xFF006786);

  static const Color accent2_100 = Color(0xFFFFF1F4);
  static const Color accent2_700 = Color(0xFFAA0B56);
  static const Color accent2_800 = Color(0xFF790E3D);

  // Spacing (space-1..space-8 from the CSS scale, in logical pixels)
  static const double space1 = 5;
  static const double space2 = 10;
  static const double space3 = 15;
  static const double space4 = 20;
  static const double space6 = 30;
  static const double space8 = 40;

  // Radius
  static const double radiusSm = 1;
  static const double radiusMd = 2;
  static const double radiusLg = 4;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/theme/app_tokens_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Write `AppTheme`**

Create `app/lib/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'app_tokens.dart';

const String kHeadingFontFamily = 'Source Serif 4';

/// The semibold weight the CSS's `--font-heading-weight: 600` used —
/// applied via `fontVariations` since Source Serif 4 is bundled as a
/// single variable font, not separate per-weight files.
const List<FontVariation> kHeadingWeight = [FontVariation('wght', 600)];

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: kHeadingFontFamily,
      scaffoldBackgroundColor: AppTokens.colorBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTokens.colorAccent,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppTokens.colorAccent,
        secondary: AppTokens.colorAccent2,
        surface: AppTokens.colorSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.colorSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: BorderSide(color: AppTokens.colorDivider),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppTokens.colorText,
        displayColor: AppTokens.colorText,
        fontFamily: kHeadingFontFamily,
      ),
    );
  }
}
```

- [ ] **Step 6: Manual sanity check**

Run: `flutter analyze` (from `app/`)
Expected: "No issues found!" — `AppTheme` isn't wired into `main.dart` yet (that's Task A8), so there's no widget test for it here; the analyzer pass is this step's verification.

- [ ] **Step 7: Commit**

```bash
git add app/lib/theme app/test/theme
git commit -m "Add Broadsheet design tokens and Flutter theme"
```

---

## Task A3: Reusable widgets — card and buttons

**Files:**
- Create: `app/lib/widgets/app_card.dart`
- Create: `app/lib/widgets/app_buttons.dart`
- Test: `app/test/widgets/app_card_test.dart`
- Test: `app/test/widgets/app_buttons_test.dart`

**Interfaces:**
- Consumes: `AppTokens`, `kHeadingFontFamily`, `kHeadingWeight` (Task A2).
- Produces: `AppCard({children, onTap})`, `CardKicker(text)`, `CardTitle(text, {fontSize = 17})`, `CardBody(text, {italic = false, fontSize = 13})`, `CardMeta(text, {icon})` — all in `app_card.dart`. `PrimaryButton({label, onPressed})`, `SecondaryButton({label, onPressed})`, `GhostIconButton({icon, semanticLabel, onPressed})` — all in `app_buttons.dart`. Every button's `onPressed` is `VoidCallback?` (nullable — passing `null` disables it with Material's built-in disabled styling).

- [ ] **Step 1: Write the failing tests**

Create `app/test/widgets/app_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/widgets/app_card.dart';

void main() {
  testWidgets('AppCard renders its children and responds to tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppCard(
          onTap: () => tapped = true,
          children: const [
            CardKicker('Τελετουργία Ι'),
            CardTitle('Ξεμάτιασμα'),
            CardBody('Περιγραφή'),
            CardMeta('~30 δευτ.', icon: Icons.visibility_outlined),
          ],
        ),
      ),
    ));

    expect(find.text('ΤΕΛΕΤΟΥΡΓΊΑ Ι'), findsOneWidget); // kicker uppercases
    expect(find.text('Ξεμάτιασμα'), findsOneWidget);
    expect(find.text('Περιγραφή'), findsOneWidget);
    expect(find.text('~30 δευτ.'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byType(AppCard));
    expect(tapped, isTrue);
  });

  testWidgets('AppCard without onTap is not tappable', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AppCard(children: [CardTitle('Τίτλος')])),
    ));
    expect(find.byType(InkWell), findsNothing);
  });
}
```

Create `app/test/widgets/app_buttons_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/widgets/app_buttons.dart';

void main() {
  testWidgets('PrimaryButton fires onPressed and disables when null', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PrimaryButton(label: 'Ξεκίνα', onPressed: () => pressed = true),
      ),
    ));
    await tester.tap(find.text('Ξεκίνα'));
    expect(pressed, isTrue);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PrimaryButton(label: 'Ξεκίνα', onPressed: null)),
    ));
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('SecondaryButton fires onPressed', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SecondaryButton(label: 'Άλλον', onPressed: () => pressed = true),
      ),
    ));
    await tester.tap(find.text('Άλλον'));
    expect(pressed, isTrue);
  });

  testWidgets('GhostIconButton exposes its semantic label', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GhostIconButton(
          icon: Icons.arrow_back,
          semanticLabel: 'Πίσω',
          onPressed: () => pressed = true,
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(pressed, isTrue);
    expect(find.bySemanticsLabel('Πίσω'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widgets/app_card_test.dart test/widgets/app_buttons_test.dart`
Expected: FAIL — neither `app_card.dart` nor `app_buttons.dart` exist yet.

- [ ] **Step 3: Write `app_card.dart`**

Create `app/lib/widgets/app_card.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.children, this.onTap});

  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space3),
      decoration: BoxDecoration(
        color: AppTokens.colorSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: content,
    );
  }
}

class CardKicker extends StatelessWidget {
  const CardKicker(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          color: AppTokens.colorAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key, this.fontSize = 17});
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kHeadingFontFamily,
          fontVariations: kHeadingWeight,
          fontSize: fontSize,
          height: 1.2,
          color: AppTokens.colorText,
        ),
      ),
    );
  }
}

class CardBody extends StatelessWidget {
  const CardBody(this.text, {super.key, this.italic = false, this.fontSize = 13});
  final String text;
  final bool italic;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: 0.8,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.4,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            color: AppTokens.colorText,
          ),
        ),
      ),
    );
  }
}

class CardMeta extends StatelessWidget {
  const CardMeta(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 11, color: AppTokens.colorText.withValues(alpha: 0.5));
    if (icon == null) return Text(text, style: style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTokens.colorText.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Text(text, style: style),
      ],
    );
  }
}
```

- [ ] **Step 4: Write `app_buttons.dart`**

Create `app/lib/widgets/app_buttons.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

TextStyle get _buttonTextStyle => const TextStyle(
      fontFamily: kHeadingFontFamily,
      fontVariations: kHeadingWeight,
      fontSize: 14,
    );

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.colorAccent,
          foregroundColor: AppTokens.colorBg,
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
        child: Text(label, style: _buttonTextStyle),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.colorText,
          side: BorderSide(color: AppTokens.colorDivider),
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
        child: Text(label, style: _buttonTextStyle),
      ),
    );
  }
}

class GhostIconButton extends StatelessWidget {
  const GhostIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: AppTokens.colorAccent,
      tooltip: semanticLabel,
      onPressed: onPressed,
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/widgets/app_card_test.dart test/widgets/app_buttons_test.dart`
Expected: PASS (5 tests total).

- [ ] **Step 6: Commit**

```bash
git add app/lib/widgets/app_card.dart app/lib/widgets/app_buttons.dart app/test/widgets/app_card_test.dart app/test/widgets/app_buttons_test.dart
git commit -m "Add AppCard and button widgets"
```

---

## Task A4: `ImageSlot` widget

**Files:**
- Create: `app/lib/widgets/image_slot.dart`
- Test: `app/test/widgets/image_slot_test.dart`

**Interfaces:**
- Consumes: `AppTokens` (Task A2).
- Produces: `typedef ImagePickFn = Future<String?> Function(ImageSource source)`; `defaultPickImage` (the real implementation, using `package:image_picker`); `ImageSlot({placeholder, imagePath, onImagePicked, height = 220, pickImage = defaultPickImage})`. Later tasks (A6, A7) use `ImageSlot` with its default `pickImage`; this task's tests inject a fake to avoid touching the real camera/gallery platform channels.

- [ ] **Step 1: Write the failing test**

Create `app/test/widgets/image_slot_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evaskania/widgets/image_slot.dart';

void main() {
  testWidgets('shows placeholder text when no image is picked', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ImageSlot(
          placeholder: 'Ρίξε τη φωτογραφία εδώ',
          imagePath: null,
          onImagePicked: (_) {},
          pickImage: (source) async => null,
        ),
      ),
    ));
    expect(find.text('Ρίξε τη φωτογραφία εδώ'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows an Image once imagePath is set', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ImageSlot(
          placeholder: 'Ρίξε τη φωτογραφία εδώ',
          imagePath: '/tmp/does-not-exist.jpg',
          onImagePicked: (_) {},
          pickImage: (source) async => null,
        ),
      ),
    ));
    expect(find.text('Ρίξε τη φωτογραφία εδώ'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('tapping opens a source sheet and reports the picked path', (tester) async {
    String? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ImageSlot(
          placeholder: 'Ρίξε τη φωτογραφία εδώ',
          imagePath: null,
          onImagePicked: (path) => picked = path,
          pickImage: (source) async {
            expect(source, ImageSource.gallery);
            return '/tmp/fake-photo.jpg';
          },
        ),
      ),
    ));

    await tester.tap(find.text('Ρίξε τη φωτογραφία εδώ'));
    await tester.pumpAndSettle(); // bottom sheet animates open

    await tester.tap(find.text('Βιβλιοθήκη φωτογραφιών'));
    await tester.pumpAndSettle(); // sheet closes, async pick resolves

    expect(picked, '/tmp/fake-photo.jpg');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/image_slot_test.dart`
Expected: FAIL — `image_slot.dart` doesn't exist.

- [ ] **Step 3: Write `image_slot.dart`**

Create `app/lib/widgets/image_slot.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_tokens.dart';

typedef ImagePickFn = Future<String?> Function(ImageSource source);

Future<String?> defaultPickImage(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
  return file?.path;
}

class ImageSlot extends StatelessWidget {
  const ImageSlot({
    super.key,
    required this.placeholder,
    required this.imagePath,
    required this.onImagePicked,
    this.height = 220,
    this.pickImage = defaultPickImage,
  });

  final String placeholder;
  final String? imagePath;
  final ValueChanged<String> onImagePicked;
  final double height;
  final ImagePickFn pickImage;

  Future<void> _handleTap(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Κάμερα'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Βιβλιοθήκη φωτογραφιών'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final path = await pickImage(source);
    if (path != null) onImagePicked(path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTokens.colorSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: AppTokens.colorDivider),
        ),
        child: imagePath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined,
                      size: 40, color: AppTokens.colorText.withValues(alpha: 0.45)),
                  const SizedBox(height: AppTokens.space2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
                    child: Text(
                      placeholder,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTokens.colorText.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                child: Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: height,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppTokens.colorText.withValues(alpha: 0.45)),
                  ),
                ),
              ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/image_slot_test.dart`
Expected: PASS (3 tests). The second test's `Image.file` on a nonexistent path will log a decode error to the test console (caught by `errorBuilder` at render time, harmless) — that's expected noise, not a failure.

- [ ] **Step 5: Commit**

```bash
git add app/lib/widgets/image_slot.dart app/test/widgets/image_slot_test.dart
git commit -m "Add ImageSlot widget with camera/gallery picker"
```

---

## Task A5: Data models, screen enum, and `AppStateController`

**Files:**
- Create: `app/lib/data/afflictions.dart`
- Create: `app/lib/data/coffee_verdicts.dart`
- Create: `app/lib/state/app_screen.dart`
- Create: `app/lib/state/app_state_controller.dart`
- Test: `app/test/state/app_state_controller_test.dart`

**Interfaces:**
- Produces: `Affliction({name, startPct, note})`, `const List<Affliction> xemAfflictions`; `CoffeeVerdict({symbols, quote})`, `const List<CoffeeVerdict> coffeeVerdicts`; `enum AppScreen {home, xemForm, xemLoading, xemRemoving, xemResult, xemRejected, coffeeForm, coffeeLoading, coffeeResult, coffeeRejected}`; `enum XemRejectionReason {noFace, multipleFaces}`; `AppStateController extends ChangeNotifier` with public fields `screen`, `name`, `xemPhotoPath`, `coffeePhotoPath`, `xemRejectionReason`, `xemFound`, `xemNote`, `xemStartPct`, `xemPct`, `dropsCleared`, `revealedAt`, `coffeeResult`, `String get displayName`, `String get today`, and methods `goHome()`, `goXemForm()`, `goCoffeeForm()`, `setName(String)`, `setXemPhoto(String)`, `setCoffeePhoto(String)`, `Future<void> submitXem()`, `Future<void> submitCoffee()`.
- This task's `submitXem`/`submitCoffee` go straight from form to loading to result — **no detection yet**. Tasks B2 and C2 modify this file to insert the real checks.

- [ ] **Step 1: Write the failing test**

Create `app/test/state/app_state_controller_test.dart`:

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:evaskania/state/app_screen.dart';
import 'package:evaskania/state/app_state_controller.dart';

/// Deterministic stand-in for dart:math's Random so tests always land on
/// the first affliction / coffee verdict in the list.
class FixedRandom implements Random {
  const FixedRandom();
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('el', null);
  });

  testWidgets('goXemForm clears any previous photo and switches screen', (tester) async {
    final controller = AppStateController(random: const FixedRandom());
    controller.setXemPhoto('/tmp/a.jpg');
    controller.goHome();
    controller.goXemForm();
    expect(controller.screen, AppScreen.xemForm);
    expect(controller.xemPhotoPath, isNull);
  });

  testWidgets('submitXem transitions loading -> removing -> result over time', (tester) async {
    final controller = AppStateController(random: const FixedRandom());
    controller.goXemForm();
    controller.setXemPhoto('/tmp/a.jpg');

    unawaited(controller.submitXem());
    expect(controller.screen, AppScreen.xemLoading);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(controller.screen, AppScreen.xemRemoving);
    expect(controller.dropsCleared, 0);

    await tester.pump(const Duration(milliseconds: 1800));
    expect(controller.dropsCleared, 3);
    expect(controller.xemPct, 0);

    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.screen, AppScreen.xemResult);
    expect(controller.revealedAt, isNotEmpty);
  });

  testWidgets('displayName falls back to Κάποιον when name is blank', (tester) async {
    final controller = AppStateController(random: const FixedRandom());
    expect(controller.displayName, 'Κάποιον');
    controller.setName('  Μαρία  ');
    expect(controller.displayName, 'Μαρία');
  });

  testWidgets('submitCoffee transitions loading -> result over time', (tester) async {
    final controller = AppStateController(random: const FixedRandom());
    controller.goCoffeeForm();
    controller.setCoffeePhoto('/tmp/cup.jpg');

    unawaited(controller.submitCoffee());
    expect(controller.screen, AppScreen.coffeeLoading);

    await tester.pump(const Duration(milliseconds: 2200));
    expect(controller.screen, AppScreen.coffeeResult);
    expect(controller.coffeeResult, isNotNull);
  });
}

void unawaited(Future<void> future) {}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/state/app_state_controller_test.dart`
Expected: FAIL — none of `data/afflictions.dart`, `data/coffee_verdicts.dart`, `state/app_screen.dart`, `state/app_state_controller.dart` exist yet.

- [ ] **Step 3: Write the data files**

Create `app/lib/data/afflictions.dart`:

```dart
class Affliction {
  const Affliction({required this.name, required this.startPct, required this.note});
  final String name;
  final int startPct;
  final String note;
}

const List<Affliction> xemAfflictions = [
  Affliction(
    name: 'Ελαφρύ ματάκι από ζήλια',
    startPct: 46,
    note: 'Κάποιος ζήλεψε κάτι μικρό — τα μαλλιά σου, μάλλον.',
  ),
  Affliction(
    name: 'Βαρύ μάτι από σχόλιο',
    startPct: 78,
    note: 'Ένα «τι όμορφο/η» ειπώθηκε χωρίς να χτυπηθεί ξύλο.',
  ),
  Affliction(
    name: 'Ψιλό μάτι από αγάπη',
    startPct: 33,
    note: "Ακόμα κι όσοι σ'αγαπάνε ζηλεύουν λίγο.",
  ),
  Affliction(
    name: 'Μάτι από άγνωστο',
    startPct: 91,
    note: 'Δεν ξέρουμε ποιος, αλλά το ένιωσες.',
  ),
];
```

Create `app/lib/data/coffee_verdicts.dart`:

```dart
class CoffeeVerdict {
  const CoffeeVerdict({required this.symbols, required this.quote});
  final List<String> symbols;
  final String quote;
}

const List<CoffeeVerdict> coffeeVerdicts = [
  CoffeeVerdict(
    symbols: ['Πουλί', 'Κουκκίδες'],
    quote:
        'Ένα πουλί σου φέρνει νέα πριν την Κυριακή, και οι κουκκίδες από κάτω λένε ότι είναι πληρωμένα νέα, όχι κουτσομπολιό.',
  ),
  CoffeeVerdict(
    symbols: ['Φίδι', 'Σταυρός'],
    quote:
        'Υπάρχει ένα φίδι κοντά στα πράγματά σου· όχι επικίνδυνο, απλώς μιλάει πολύ. Ο σταυρός πίσω του λέει ότι καλά έκανες και δεν το άκουσες.',
  ),
  CoffeeVerdict(
    symbols: ['Άγκυρα'],
    quote:
        "Μια άγκυρα τόσο κοντά στο χερούλι θέλει να μείνεις κάπου λίγο παραπάνω απ' όσο σχεδίαζες.",
  ),
  CoffeeVerdict(
    symbols: ['Γάτα', 'Κλειδί'],
    quote:
        'Η γάτα σημαίνει ότι κάποιος κοντινός κρύβει κάτι μικρό. Το κλειδί λέει ότι θα το βρεις χωρίς να ρωτήσεις.',
  ),
  CoffeeVerdict(
    symbols: ['Δέντρο', 'Καρδιά'],
    quote:
        'Ένα δέντρο με μια καρδιά πιασμένη στα κλαδιά του — καλά, αργά νέα για την οικογένεια, τίποτα που βιάζεται.',
  ),
];
```

Create `app/lib/state/app_screen.dart`:

```dart
enum AppScreen {
  home,
  xemForm,
  xemLoading,
  xemRemoving,
  xemResult,
  xemRejected,
  coffeeForm,
  coffeeLoading,
  coffeeResult,
  coffeeRejected,
}

enum XemRejectionReason { noFace, multipleFaces }
```

- [ ] **Step 4: Write `AppStateController`**

Create `app/lib/state/app_state_controller.dart`:

```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/afflictions.dart';
import '../data/coffee_verdicts.dart';
import 'app_screen.dart';

class AppStateController extends ChangeNotifier {
  AppStateController({Random? random}) : _random = random ?? Random();

  final Random _random;
  Timer? _xemTimer;

  AppScreen screen = AppScreen.home;
  String name = '';
  String? xemPhotoPath;
  String? coffeePhotoPath;
  XemRejectionReason? xemRejectionReason;

  String xemFound = '';
  String xemNote = '';
  int xemStartPct = 0;
  int xemPct = 0;
  int dropsCleared = 0;
  String revealedAt = '';
  CoffeeVerdict? coffeeResult;

  String get displayName => name.trim().isEmpty ? 'Κάποιον' : name.trim();

  String get today => DateFormat('d MMM', 'el').format(DateTime.now());

  void goHome() {
    _xemTimer?.cancel();
    screen = AppScreen.home;
    notifyListeners();
  }

  void goXemForm() {
    _xemTimer?.cancel();
    xemPhotoPath = null;
    xemRejectionReason = null;
    screen = AppScreen.xemForm;
    notifyListeners();
  }

  void goCoffeeForm() {
    coffeePhotoPath = null;
    screen = AppScreen.coffeeForm;
    notifyListeners();
  }

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setXemPhoto(String path) {
    xemPhotoPath = path;
    notifyListeners();
  }

  void setCoffeePhoto(String path) {
    coffeePhotoPath = path;
    notifyListeners();
  }

  Future<void> submitXem() async {
    if (xemPhotoPath == null) return;
    screen = AppScreen.xemLoading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));
    final affliction = xemAfflictions[_random.nextInt(xemAfflictions.length)];
    _startRemoval(affliction);
  }

  void _startRemoval(Affliction affliction) {
    xemFound = affliction.name;
    xemNote = affliction.note;
    xemStartPct = affliction.startPct;
    xemPct = affliction.startPct;
    dropsCleared = 0;
    screen = AppScreen.xemRemoving;
    notifyListeners();

    final total = affliction.startPct;
    const totalDurationMs = 1800;
    final t0 = DateTime.now();
    _xemTimer?.cancel();
    _xemTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      final elapsedMs = DateTime.now().difference(t0).inMilliseconds;
      final frac = (elapsedMs / totalDurationMs).clamp(0.0, 1.0);
      xemPct = (total * (1 - frac)).round();
      dropsCleared = frac >= 0.999 ? 3 : (frac * 3).floor();
      notifyListeners();
      if (frac >= 1.0) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          revealedAt = _formatNow();
          screen = AppScreen.xemResult;
          notifyListeners();
        });
      }
    });
  }

  Future<void> submitCoffee() async {
    if (coffeePhotoPath == null) return;
    screen = AppScreen.coffeeLoading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 2200));
    coffeeResult = coffeeVerdicts[_random.nextInt(coffeeVerdicts.length)];
    revealedAt = _formatNow();
    screen = AppScreen.coffeeResult;
    notifyListeners();
  }

  String _formatNow() => DateFormat('h:mm a', 'el').format(DateTime.now());

  @override
  void dispose() {
    _xemTimer?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/state/app_state_controller_test.dart`
Expected: PASS (4 tests). This runs inside `testWidgets`'s fake-async zone, so `tester.pump(duration)` advances the controller's `Future.delayed`/`Timer.periodic` calls deterministically — no real wall-clock waiting.

- [ ] **Step 6: Commit**

```bash
git add app/lib/data app/lib/state app/test/state
git commit -m "Add ritual data, screen enum, and AppStateController"
```

---

## Task A6: Ξεμάτιασμα screens (form, loading, removing, result)

**Files:**
- Create: `app/lib/screens/xem_form_screen.dart`
- Create: `app/lib/screens/xem_loading_screen.dart`
- Create: `app/lib/screens/xem_removing_screen.dart`
- Create: `app/lib/screens/xem_result_screen.dart`
- Test: `app/test/screens/xem_screens_test.dart`

**Interfaces:**
- Consumes: `AppTokens`, `kHeadingFontFamily` (A2); `AppCard`/`CardKicker`/`CardTitle`/`CardBody`/`CardMeta` (A3); `PrimaryButton`/`SecondaryButton`/`GhostIconButton` (A3); `ImageSlot` (A4); `AppStateController` and its fields/methods (A5).
- Produces: `XemFormScreen({controller})`, `XemLoadingScreen()`, `XemRemovingScreen({controller})`, `XemResultScreen({controller})` — all taking the controller as a plain constructor parameter and reading its current field values at build time (the parent, wired in Task A8, is responsible for rebuilding on `notifyListeners()`).

- [ ] **Step 1: Write the failing test**

Create `app/test/screens/xem_screens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/screens/xem_form_screen.dart';
import 'package:evaskania/screens/xem_loading_screen.dart';
import 'package:evaskania/screens/xem_removing_screen.dart';
import 'package:evaskania/screens/xem_result_screen.dart';
import 'package:evaskania/state/app_state_controller.dart';

void main() {
  testWidgets('XemFormScreen shows fields and a disabled button with no photo', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(MaterialApp(home: XemFormScreen(controller: controller)));
    expect(find.text('Ξεμάτιασμα'), findsOneWidget);
    expect(find.text('Όνομα'), findsOneWidget);
    expect(find.text('Ρίξε τη φωτογραφία εδώ'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('XemFormScreen enables submit once a photo path is set', (tester) async {
    final controller = AppStateController()..setXemPhoto('/tmp/a.jpg');
    await tester.pumpWidget(MaterialApp(home: XemFormScreen(controller: controller)));
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('XemFormScreen name field updates the controller', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(MaterialApp(home: XemFormScreen(controller: controller)));
    await tester.enterText(find.byType(TextField), 'Μαρία');
    expect(controller.name, 'Μαρία');
  });

  testWidgets('XemLoadingScreen shows the waiting copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: XemLoadingScreen()));
    expect(find.text('Η γιαγιά συγκεντρώνεται…'), findsOneWidget);
  });

  testWidgets('XemRemovingScreen shows the affliction and percentage', (tester) async {
    // Sets controller fields directly rather than driving them through
    // submitXem()/a timer — this screen only reads current state, and this
    // keeps the test decoupled from Tasks B2/C2's later changes to submitXem
    // (which start awaiting a real detection check before this point).
    final controller = AppStateController()
      ..xemFound = 'Ελαφρύ ματάκι από ζήλια'
      ..xemNote = 'Κάποιος ζήλεψε κάτι μικρό — τα μαλλιά σου, μάλλον.'
      ..xemPct = 23;

    await tester.pumpWidget(MaterialApp(home: XemRemovingScreen(controller: controller)));
    expect(find.text('Βρέθηκε'), findsOneWidget);
    expect(find.text('Ελαφρύ ματάκι από ζήλια'), findsOneWidget);
    expect(find.textContaining('%'), findsWidgets);
  });

  testWidgets('XemResultScreen shows the display name and a retry button', (tester) async {
    // Same rationale as above: set state directly instead of calling
    // submitXem(), so this test stays valid after Tasks B2/C2.
    final controller = AppStateController()
      ..setName('Μαρία')
      ..xemFound = 'Βαρύ μάτι από σχόλιο'
      ..xemStartPct = 78
      ..revealedAt = '11:26 μ.μ.';

    await tester.pumpWidget(MaterialApp(home: XemResultScreen(controller: controller)));
    expect(find.textContaining('Μαρία, είσαι καθαρός/ή πια!'), findsOneWidget);
    expect(find.text('Ξεμάτιασε άλλον'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/xem_screens_test.dart`
Expected: FAIL — none of the four screen files exist yet.

- [ ] **Step 3: Write the screens**

Create `app/lib/screens/xem_form_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/image_slot.dart';

class XemFormScreen extends StatefulWidget {
  const XemFormScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  State<XemFormScreen> createState() => _XemFormScreenState();
}

class _XemFormScreenState extends State<XemFormScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.controller.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(
                icon: Icons.arrow_back,
                semanticLabel: 'Πίσω',
                onPressed: controller.goHome,
              ),
              const SizedBox(width: AppTokens.space2),
              const Text('Ξεμάτιασμα',
                  style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          const Text('Όνομα', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'π.χ. Μαρία'),
            onChanged: controller.setName,
          ),
          const SizedBox(height: AppTokens.space4),
          const Text('Φωτογραφία', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          ImageSlot(
            placeholder: 'Ρίξε τη φωτογραφία εδώ',
            imagePath: controller.xemPhotoPath,
            onImagePicked: controller.setXemPhoto,
            height: 220,
          ),
          const SizedBox(height: AppTokens.space6),
          PrimaryButton(
            label: 'Ξεκίνα το ξεμάτιασμα',
            onPressed: controller.xemPhotoPath == null ? null : controller.submitXem,
          ),
        ],
      ),
    );
  }
}
```

Create `app/lib/screens/xem_loading_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

class XemLoadingScreen extends StatelessWidget {
  const XemLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppTokens.accent100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove_red_eye_outlined, size: 40, color: AppTokens.accent700),
          ),
          const SizedBox(height: AppTokens.space4),
          const Text('Η γιαγιά συγκεντρώνεται…',
              style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 15)),
          const SizedBox(height: 6),
          Text('τρεις σταγόνες λάδι στο νερό',
              style: TextStyle(fontSize: 12, color: AppTokens.colorText.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}
```

Create `app/lib/screens/xem_removing_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_card.dart';

class XemRemovingScreen extends StatelessWidget {
  const XemRemovingScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ξεμάτιασμα',
              style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
          const SizedBox(height: AppTokens.space3),
          AppCard(
            children: [
              const CardKicker('Βρέθηκε'),
              CardTitle(controller.xemFound, fontSize: 22),
              CardBody(controller.xemNote),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Text(
                      '${controller.xemPct}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: kHeadingFontFamily,
                        fontSize: 52,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.accent700,
                      ),
                    ),
                    Text(
                      'δείκτης βασκανίας — φεύγει',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.6,
                        color: AppTokens.colorText.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final cleared = controller.dropsCleared > i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: AnimatedOpacity(
                      opacity: cleared ? 0.15 : 1,
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedScale(
                        scale: cleared ? 0.4 : 1,
                        duration: const Duration(milliseconds: 500),
                        child: Transform.rotate(
                          angle: 0.785398, // 45deg — matches the CSS drop shape
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppTokens.accent700,
                              borderRadius: BorderRadius.circular(10)
                                  .copyWith(bottomLeft: const Radius.circular(2)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

Create `app/lib/screens/xem_result_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';

class XemResultScreen extends StatelessWidget {
  const XemResultScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(
                icon: Icons.arrow_back,
                semanticLabel: 'Αρχική',
                onPressed: controller.goHome,
              ),
              const SizedBox(width: AppTokens.space2),
              const Text('Έγινε', style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          AppCard(
            children: [
              const CardKicker('Ξεματιάστηκε'),
              CardTitle('${controller.displayName}, είσαι καθαρός/ή πια!', fontSize: 24),
              CardBody('Το «${controller.xemFound}» έφυγε μαζί με τις σταγόνες. '
                  'Αν ξανανιώσεις παράξενα, ξανάρθε.'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${controller.xemStartPct}%',
                    style: TextStyle(
                      fontFamily: kHeadingFontFamily,
                      fontSize: 15,
                      decoration: TextDecoration.lineThrough,
                      color: AppTokens.colorText.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '0%',
                    style: TextStyle(
                      fontFamily: kHeadingFontFamily,
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.accent700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('τωρινός δείκτης',
                      style: TextStyle(fontSize: 11, color: AppTokens.colorText.withValues(alpha: 0.55))),
                ],
              ),
              const SizedBox(height: 4),
              CardMeta('Για ${controller.displayName} · ξεματιάστηκε στις ${controller.revealedAt}'),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          SecondaryButton(label: 'Ξεμάτιασε άλλον', onPressed: controller.goXemForm),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/xem_screens_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/xem_form_screen.dart app/lib/screens/xem_loading_screen.dart app/lib/screens/xem_removing_screen.dart app/lib/screens/xem_result_screen.dart app/test/screens/xem_screens_test.dart
git commit -m "Add Ξεμάτιασμα form, loading, removing, and result screens"
```

---

## Task A7: Ο Καφές screens (form, loading, result)

**Files:**
- Create: `app/lib/screens/coffee_form_screen.dart`
- Create: `app/lib/screens/coffee_loading_screen.dart`
- Create: `app/lib/screens/coffee_result_screen.dart`
- Test: `app/test/screens/coffee_screens_test.dart`

**Interfaces:**
- Consumes: same widget/token/controller interfaces as Task A6.
- Produces: `CoffeeFormScreen({controller})`, `CoffeeLoadingScreen()`, `CoffeeResultScreen({controller})`.

- [ ] **Step 1: Write the failing test**

Create `app/test/screens/coffee_screens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/screens/coffee_form_screen.dart';
import 'package:evaskania/screens/coffee_loading_screen.dart';
import 'package:evaskania/screens/coffee_result_screen.dart';
import 'package:evaskania/data/coffee_verdicts.dart';
import 'package:evaskania/state/app_state_controller.dart';

void main() {
  testWidgets('CoffeeFormScreen shows the photo slot and a disabled button with no photo', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(MaterialApp(home: CoffeeFormScreen(controller: controller)));
    expect(find.text('Ο Καφές'), findsOneWidget);
    expect(find.text('Ανέβασε το γυρισμένο φλιτζάνι'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('CoffeeFormScreen enables submit once a photo path is set', (tester) async {
    final controller = AppStateController()..setCoffeePhoto('/tmp/cup.jpg');
    await tester.pumpWidget(MaterialApp(home: CoffeeFormScreen(controller: controller)));
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('CoffeeLoadingScreen shows the waiting copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CoffeeLoadingScreen()));
    expect(find.text('Η γιαγιά διαβάζει…'), findsOneWidget);
  });

  testWidgets('CoffeeResultScreen shows the verdict symbols and quote', (tester) async {
    // Sets coffeeResult directly rather than driving it through
    // submitCoffee() — this screen only reads current state, and this keeps
    // the test decoupled from Task C2's later change to submitCoffee (which
    // starts awaiting a real detection check before this point).
    const verdict = CoffeeVerdict(symbols: ['Πουλί', 'Κουκκίδες'], quote: 'Δοκιμαστικό απόσπασμα.');
    final controller = AppStateController()
      ..coffeeResult = verdict
      ..revealedAt = '11:26 μ.μ.';

    await tester.pumpWidget(MaterialApp(home: CoffeeResultScreen(controller: controller)));
    for (final symbol in verdict.symbols) {
      expect(find.text(symbol), findsOneWidget);
    }
    expect(find.textContaining(verdict.quote), findsOneWidget);
    expect(find.text('Διάβασε άλλο φλιτζάνι'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/coffee_screens_test.dart`
Expected: FAIL — none of the three screen files exist yet.

- [ ] **Step 3: Write the screens**

Create `app/lib/screens/coffee_form_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/image_slot.dart';

class CoffeeFormScreen extends StatelessWidget {
  const CoffeeFormScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(
                icon: Icons.arrow_back,
                semanticLabel: 'Πίσω',
                onPressed: controller.goHome,
              ),
              const SizedBox(width: AppTokens.space2),
              const Text('Ο Καφές', style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          const Text('Φλιτζάνι', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 5),
          ImageSlot(
            placeholder: 'Ανέβασε το γυρισμένο φλιτζάνι',
            imagePath: controller.coffeePhotoPath,
            onImagePicked: controller.setCoffeePhoto,
            height: 260,
          ),
          const SizedBox(height: AppTokens.space6),
          PrimaryButton(
            label: "Δωσ' μου το φλιτζάνι",
            onPressed: controller.coffeePhotoPath == null ? null : controller.submitCoffee,
          ),
        ],
      ),
    );
  }
}
```

Create `app/lib/screens/coffee_loading_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

class CoffeeLoadingScreen extends StatelessWidget {
  const CoffeeLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppTokens.accent2_100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.coffee_outlined, size: 34, color: AppTokens.accent2_700),
          ),
          const SizedBox(height: AppTokens.space4),
          const Text('Η γιαγιά διαβάζει…',
              style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 15)),
          const SizedBox(height: 6),
          Text('γύρνα το, μη βιάζεσαι',
              style: TextStyle(fontSize: 12, color: AppTokens.colorText.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}
```

Create `app/lib/screens/coffee_result_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';

class CoffeeResultScreen extends StatelessWidget {
  const CoffeeResultScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.coffeeResult!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(
                icon: Icons.arrow_back,
                semanticLabel: 'Αρχική',
                onPressed: controller.goHome,
              ),
              const SizedBox(width: AppTokens.space2),
              const Text('Η ανάγνωση', style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          AppCard(
            children: [
              const CardKicker('Σύμβολα στο φλιτζάνι'),
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final symbol in result.symbols)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTokens.accent2_100,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                      child: Text(symbol,
                          style: const TextStyle(fontSize: 11, color: AppTokens.accent2_800)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              CardBody('"${result.quote}"', italic: true, fontSize: 16),
              CardMeta('— η Γιαγιά, ${controller.revealedAt}'),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          SecondaryButton(label: 'Διάβασε άλλο φλιτζάνι', onPressed: controller.goCoffeeForm),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/screens/coffee_screens_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add app/lib/screens/coffee_form_screen.dart app/lib/screens/coffee_loading_screen.dart app/lib/screens/coffee_result_screen.dart app/test/screens/coffee_screens_test.dart
git commit -m "Add Ο Καφές form, loading, and result screens"
```

---

## Task A8: Home screen, `AppShell` navigation, and `main.dart` wiring

This is the milestone-A checkpoint: after this task, the app runs end-to-end with the
mockup's exact original behavior (randomized outcomes, no real detection yet).

**Files:**
- Create: `app/lib/screens/home_screen.dart`
- Create: `app/lib/screens/app_shell.dart`
- Modify: `app/lib/screens/xem_form_screen.dart` (add a `pickImage` parameter, forwarded to its `ImageSlot`, so tests can inject a fake picker)
- Modify: `app/lib/screens/coffee_form_screen.dart` (same change)
- Modify: `app/lib/main.dart` (replace the `flutter create` counter-app boilerplate)
- Delete: `app/test/widget_test.dart` (the default counter-app test — it references widgets `main.dart` no longer has)
- Test: `app/test/screens/app_shell_test.dart`

**Interfaces:**
- Consumes: everything from A2–A7.
- Produces: `HomeScreen({controller})`; `AppShell({controller, pickImage = defaultPickImage})` — the root widget that watches `controller` and switches screens; `EVaskaniaApp({controller})` in `main.dart`. `AppScreen.xemRejected`/`AppScreen.coffeeRejected` render a small internal `_RejectedFallback` widget for now (real screens land in Tasks B2 and C2, which replace those two switch arms and then delete `_RejectedFallback`) — these two states are unreachable in this task since `AppStateController.submitXem`/`submitCoffee` never set them yet, so this is dead code today, not a functional gap.

- [ ] **Step 1: Write the failing test**

Create `app/test/screens/app_shell_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evaskania/screens/app_shell.dart';
import 'package:evaskania/state/app_state_controller.dart';

Future<String?> _fakePick(ImageSource source) async => '/tmp/fake.jpg';

void main() {
  testWidgets('home shows the masthead and both ritual cards', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
    expect(find.text('Ξεμάτιασμα'), findsOneWidget);
    expect(find.text('Ο Καφές'), findsOneWidget);
  });

  testWidgets('full Ξεμάτιασμα flow: home -> form -> pick -> submit -> result -> home',
      (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );

    await tester.tap(find.text('Ξεμάτιασμα'));
    await tester.pumpAndSettle();
    expect(find.text('Ρίξε τη φωτογραφία εδώ'), findsOneWidget);

    await tester.tap(find.text('Ρίξε τη φωτογραφία εδώ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Βιβλιοθήκη φωτογραφιών'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ξεκίνα το ξεμάτιασμα'));
    await tester.pump();
    expect(find.text('Η γιαγιά συγκεντρώνεται…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Βρέθηκε'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ξεμάτιασε άλλον'), findsOneWidget);

    await tester.tap(find.byTooltip('Αρχική'));
    await tester.pumpAndSettle();
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
  });

  testWidgets('full Ο Καφές flow: home -> form -> pick -> submit -> result -> home',
      (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );

    await tester.tap(find.text('Ο Καφές'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ανέβασε το γυρισμένο φλιτζάνι'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Βιβλιοθήκη φωτογραφιών'));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Δωσ' μου το φλιτζάνι"));
    await tester.pump();
    expect(find.text('Η γιαγιά διαβάζει…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    expect(find.text('Διάβασε άλλο φλιτζάνι'), findsOneWidget);

    await tester.tap(find.byTooltip('Αρχική'));
    await tester.pumpAndSettle();
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/screens/app_shell_test.dart`
Expected: FAIL — `home_screen.dart` and `app_shell.dart` don't exist yet, and `XemFormScreen`/`CoffeeFormScreen` don't yet accept `pickImage`.

- [ ] **Step 3: Write `HomeScreen`**

Create `app/lib/screens/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: AppTokens.colorText),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.only(top: AppTokens.space2),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTokens.colorText))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ΤΕΎΧΟΣ ΤΣΈΠΗΣ',
                    style: TextStyle(
                        fontSize: 10, letterSpacing: 1.4, color: AppTokens.colorText.withValues(alpha: 0.6))),
                Text(controller.today,
                    style: TextStyle(fontSize: 10, color: AppTokens.colorText.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          const Text('e-ΒΑΣΚΑΝΙΑ',
              style: TextStyle(
                  fontFamily: kHeadingFontFamily, fontSize: 40, height: 0.95, color: AppTokens.colorText)),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Δύο τελετουργίες τσέπης: διώξε το μάτι, διάβασε τον καφέ. '
            'Για πλάκα, με τους φίλους σου.',
            style: TextStyle(fontSize: 14, height: 1.5, color: AppTokens.colorText.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: AppTokens.space4),
          AppCard(
            onTap: controller.goXemForm,
            children: const [
              CardKicker('Τελετουργία Ι'),
              CardTitle('Ξεμάτιασμα'),
              CardBody('Φωτογραφία, όνομα, και σε ξεματιάζουμε επιτόπου — τρεις '
                  'σταγόνες λάδι το επισφραγίζουν.'),
              CardMeta('~30 δευτ.', icon: Icons.visibility_outlined),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          AppCard(
            onTap: controller.goCoffeeForm,
            children: const [
              CardKicker('Τελετουργία ΙΙ'),
              CardTitle('Ο Καφές'),
              CardBody('Γύρνα το φλιτζάνι, ανέβασε το κατακάθι, άσε τη γιαγιά '
                  'να διαβάσει την εβδομάδα σου.'),
              CardMeta('~20 δευτ.', icon: Icons.coffee_outlined),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            'Η προσευχή δεν λέγεται πάνω από τρεις φορές στη ζωή μας — μετά '
            'χάνει τη δύναμή της.',
            style: TextStyle(
                fontSize: 11, fontStyle: FontStyle.italic, color: AppTokens.colorText.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Add `pickImage` to the two form screens**

In `app/lib/screens/xem_form_screen.dart`, add the import `import '../widgets/image_slot.dart';` (for `ImagePickFn`/`defaultPickImage`), add a field to both the widget and its state, and pass it through to `ImageSlot`:

```dart
class XemFormScreen extends StatefulWidget {
  const XemFormScreen({super.key, required this.controller, this.pickImage = defaultPickImage});
  final AppStateController controller;
  final ImagePickFn pickImage;

  @override
  State<XemFormScreen> createState() => _XemFormScreenState();
}
```

And in `_XemFormScreenState.build`, change the `ImageSlot(...)` call to add `pickImage: widget.pickImage,` as one more named argument.

Apply the equivalent change to `app/lib/screens/coffee_form_screen.dart` (it's a `StatelessWidget`, so just add the field to the class and pass `pickImage: pickImage,` into its `ImageSlot`):

```dart
class CoffeeFormScreen extends StatelessWidget {
  const CoffeeFormScreen({super.key, required this.controller, this.pickImage = defaultPickImage});
  final AppStateController controller;
  final ImagePickFn pickImage;
  // ...ImageSlot(..., pickImage: pickImage,) inside build()
}
```

(Both need `import '../widgets/image_slot.dart';` if not already present — it already is, since both screens use `ImageSlot`.)

- [ ] **Step 5: Write `AppShell`**

Create `app/lib/screens/app_shell.dart`:

```dart
import 'package:flutter/material.dart';
import '../state/app_screen.dart';
import '../state/app_state_controller.dart';
import '../widgets/app_buttons.dart';
import '../widgets/image_slot.dart';
import 'coffee_form_screen.dart';
import 'coffee_loading_screen.dart';
import 'coffee_result_screen.dart';
import 'home_screen.dart';
import 'xem_form_screen.dart';
import 'xem_loading_screen.dart';
import 'xem_removing_screen.dart';
import 'xem_result_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.controller, this.pickImage = defaultPickImage});

  final AppStateController controller;
  final ImagePickFn pickImage;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: switch (controller.screen) {
              AppScreen.home => HomeScreen(controller: controller),
              AppScreen.xemForm => XemFormScreen(controller: controller, pickImage: pickImage),
              AppScreen.xemLoading => const XemLoadingScreen(),
              AppScreen.xemRemoving => XemRemovingScreen(controller: controller),
              AppScreen.xemResult => XemResultScreen(controller: controller),
              AppScreen.xemRejected || AppScreen.coffeeRejected =>
                _RejectedFallback(controller: controller),
              AppScreen.coffeeForm => CoffeeFormScreen(controller: controller, pickImage: pickImage),
              AppScreen.coffeeLoading => const CoffeeLoadingScreen(),
              AppScreen.coffeeResult => CoffeeResultScreen(controller: controller),
            },
          ),
        );
      },
    );
  }
}

/// Temporary stand-in for [AppScreen.xemRejected] / [AppScreen.coffeeRejected].
/// Both states are unreachable until Tasks B2 and C2 wire the real detection
/// checks into [AppStateController]; those tasks replace this switch arm
/// with the real `XemRejectedScreen` / `CoffeeRejectedScreen` and delete
/// this class once both are in place.
class _RejectedFallback extends StatelessWidget {
  const _RejectedFallback({required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SecondaryButton(label: 'Αρχική', onPressed: controller.goHome),
    );
  }
}
```

- [ ] **Step 6: Wire `main.dart`**

Replace the contents of `app/lib/main.dart` (generated by `flutter create`) with:

```dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/app_shell.dart';
import 'state/app_state_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('el', null);
  runApp(EVaskaniaApp(controller: AppStateController()));
}

class EVaskaniaApp extends StatelessWidget {
  const EVaskaniaApp({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'e-Vaskania',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AppShell(controller: controller),
    );
  }
}
```

Delete the stale default test, which references the counter-app widgets `main.dart` no longer has:

```bash
rm app/test/widget_test.dart
```

- [ ] **Step 7: Run test to verify it passes**

Run (from `app/`): `flutter test`
Expected: PASS — every test file from A1 through A8 passes (the deleted `widget_test.dart` is gone, so its stale failure is moot).

- [ ] **Step 8: Full static + build check**

```bash
flutter analyze
flutter build apk --debug
flutter build ios --no-codesign --simulator
```

Expected: `flutter analyze` reports no issues; both builds succeed (these compile-check the whole app without needing a running emulator/simulator — actually launching it is a manual step, noted below).

- [ ] **Step 9: Manual smoke test (not automatable from here)**

Ask the user to run `flutter run` from `app/` with a simulator or physical device connected, and confirm the home screen shows both cards, tapping through each ritual reaches a randomized result, and the back arrows return home. This is the milestone-A "does it actually feel like the mockup" check that no widget test substitutes for.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "Wire home screen, AppShell navigation, and main.dart (milestone A complete)"
```

---

## Task B1: `FaceChecker`

**Files:**
- Create: `app/lib/detection/face_checker.dart`
- Test: `app/test/detection/face_checker_test.dart`

**Interfaces:**
- Produces: `enum FaceCheckResult {ok, noFace, multipleFaces}`; `abstract class FaceDetectionSource {Future<List<Rect>> detectFaceBoxes(String imagePath)}`; `MlKitFaceDetectionSource implements FaceDetectionSource` (the real one, wrapping `google_mlkit_face_detection`); `abstract class ImageSizeReader {Future<Size> readSize(String imagePath)}`; `UiImageSizeReader implements ImageSizeReader` (the real one, via `dart:ui`'s `instantiateImageCodec`); `FaceChecker({FaceDetectionSource? detectionSource, ImageSizeReader? sizeReader, double minAreaFraction = 0.05})` with `Future<FaceCheckResult> check(String imagePath)` and `void dispose()`.
- The real ML Kit detector and the real image decoder both use platform/engine calls that don't work in `flutter test`'s headless environment — this task's tests inject fakes for both seams. Task B2 uses the real `FaceChecker()` (no args, defaulting to the real implementations) inside `AppStateController`.

- [ ] **Step 1: Write the failing test**

Create `app/test/detection/face_checker_test.dart`:

```dart
import 'package:flutter/material.dart' show Rect, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/detection/face_checker.dart';

class _FakeDetectionSource implements FaceDetectionSource {
  _FakeDetectionSource(this.boxes);
  final List<Rect> boxes;
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async => boxes;
}

class _FakeSizeReader implements ImageSizeReader {
  _FakeSizeReader(this.size);
  final Size size;
  @override
  Future<Size> readSize(String imagePath) async => size;
}

void main() {
  const imageSize = Size(1000, 1000); // 1,000,000 px^2 area

  test('no faces -> noFace', () async {
    final checker = FaceChecker(
      detectionSource: _FakeDetectionSource(const []),
      sizeReader: _FakeSizeReader(imageSize),
    );
    expect(await checker.check('/tmp/a.jpg'), FaceCheckResult.noFace);
  });

  test('exactly one significant face -> ok', () async {
    final checker = FaceChecker(
      detectionSource: _FakeDetectionSource([const Rect.fromLTWH(0, 0, 400, 400)]), // 16% of area
      sizeReader: _FakeSizeReader(imageSize),
    );
    expect(await checker.check('/tmp/a.jpg'), FaceCheckResult.ok);
  });

  test('two significant faces -> multipleFaces', () async {
    final checker = FaceChecker(
      detectionSource: _FakeDetectionSource([
        const Rect.fromLTWH(0, 0, 400, 400),
        const Rect.fromLTWH(500, 500, 400, 400),
      ]),
      sizeReader: _FakeSizeReader(imageSize),
    );
    expect(await checker.check('/tmp/a.jpg'), FaceCheckResult.multipleFaces);
  });

  test('a tiny background face below the area threshold is ignored', () async {
    final checker = FaceChecker(
      detectionSource: _FakeDetectionSource([
        const Rect.fromLTWH(0, 0, 400, 400), // 16% — the real subject
        const Rect.fromLTWH(900, 900, 50, 50), // 0.25% — a stray poster face
      ]),
      sizeReader: _FakeSizeReader(imageSize),
    );
    expect(await checker.check('/tmp/a.jpg'), FaceCheckResult.ok);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/detection/face_checker_test.dart`
Expected: FAIL — `face_checker.dart` doesn't exist.

- [ ] **Step 3: Write `FaceChecker`**

Create `app/lib/detection/face_checker.dart`:

```dart
import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum FaceCheckResult { ok, noFace, multipleFaces }

/// Seam over ML Kit's face detector so tests can inject a fake — platform
/// channels (which the real detector uses) don't work in `flutter test`'s
/// headless environment.
abstract class FaceDetectionSource {
  Future<List<Rect>> detectFaceBoxes(String imagePath);
}

class MlKitFaceDetectionSource implements FaceDetectionSource {
  final FaceDetector _detector = FaceDetector(options: FaceDetectorOptions());

  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _detector.processImage(inputImage);
    return faces.map((f) => f.boundingBox).toList();
  }

  void dispose() => _detector.close();
}

/// Seam over reading an image file's pixel dimensions, for the same
/// testability reason as [FaceDetectionSource].
abstract class ImageSizeReader {
  Future<Size> readSize(String imagePath);
}

class UiImageSizeReader implements ImageSizeReader {
  @override
  Future<Size> readSize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    frame.image.dispose();
    return size;
  }
}

/// Ξεμάτιασμα's face check: pass only if exactly one face fills at least
/// [minAreaFraction] of the photo — filters out a stray face in the
/// background (a poster, someone walking by) without requiring the photo
/// be a tight headshot.
class FaceChecker {
  FaceChecker({
    FaceDetectionSource? detectionSource,
    ImageSizeReader? sizeReader,
    this.minAreaFraction = 0.05,
  })  : _detectionSource = detectionSource ?? MlKitFaceDetectionSource(),
        _sizeReader = sizeReader ?? UiImageSizeReader();

  final FaceDetectionSource _detectionSource;
  final ImageSizeReader _sizeReader;
  final double minAreaFraction;

  Future<FaceCheckResult> check(String imagePath) async {
    final boxes = await _detectionSource.detectFaceBoxes(imagePath);
    final imageSize = await _sizeReader.readSize(imagePath);
    final imageArea = imageSize.width * imageSize.height;

    final significant = boxes.where((box) {
      if (imageArea <= 0) return true;
      final boxArea = box.width * box.height;
      return (boxArea / imageArea) >= minAreaFraction;
    }).toList();

    if (significant.isEmpty) return FaceCheckResult.noFace;
    if (significant.length > 1) return FaceCheckResult.multipleFaces;
    return FaceCheckResult.ok;
  }

  void dispose() {
    final source = _detectionSource;
    if (source is MlKitFaceDetectionSource) source.dispose();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/detection/face_checker_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add app/lib/detection/face_checker.dart app/test/detection/face_checker_test.dart
git commit -m "Add FaceChecker with a fakeable detection/size-reading seam"
```

---

## Task B2: Wire `FaceChecker` into the Ξεμάτιασμα flow

**Files:**
- Modify: `app/lib/state/app_state_controller.dart` (inject `FaceChecker`, branch `submitXem` on its result)
- Modify: `app/test/state/app_state_controller_test.dart` (existing `submitXem` tests need a stubbed-`ok` `FaceChecker` injected so they keep exercising the success path; add new tests for both rejection reasons)
- Create: `app/lib/screens/xem_rejected_screen.dart`
- Test: `app/test/screens/xem_rejected_screen_test.dart`
- Modify: `app/lib/screens/app_shell.dart` (route `AppScreen.xemRejected` to the new screen; `AppScreen.coffeeRejected` keeps using `_RejectedFallback` until Task C2)
- Modify: `app/test/screens/app_shell_test.dart` (its Ξεμάτιασμα end-to-end test drives `submitXem` by tapping through the UI — it now needs a fake `FaceChecker` injected so it doesn't hit the real ML Kit platform channel)

**Interfaces:**
- Consumes: `FaceChecker`, `FaceCheckResult` (B1).
- Produces: `AppStateController({random, FaceChecker? faceChecker})` — new optional constructor parameter, defaulting to a real `FaceChecker()`. `XemRejectedScreen({controller})`.

- [ ] **Step 1: Write the failing tests**

Replace the full contents of `app/test/state/app_state_controller_test.dart` with:

```dart
import 'dart:math';
import 'package:flutter/material.dart' show Rect, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:evaskania/detection/face_checker.dart';
import 'package:evaskania/state/app_screen.dart';
import 'package:evaskania/state/app_state_controller.dart';

/// Deterministic stand-in for dart:math's Random so tests always land on
/// the first affliction / coffee verdict in the list.
class FixedRandom implements Random {
  const FixedRandom();
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

class _OneFace implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async =>
      [const Rect.fromLTWH(0, 0, 400, 400)];
}

class _NoFace implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async => const [];
}

class _TwoFaces implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async => [
        const Rect.fromLTWH(0, 0, 400, 400),
        const Rect.fromLTWH(500, 500, 400, 400),
      ];
}

class _FixedSize implements ImageSizeReader {
  @override
  Future<Size> readSize(String imagePath) async => const Size(1000, 1000);
}

FaceChecker _faceCheckerWith(FaceDetectionSource source) =>
    FaceChecker(detectionSource: source, sizeReader: _FixedSize());

void unawaited(Future<void> future) {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('el', null);
  });

  testWidgets('goXemForm clears any previous photo and rejection, and switches screen',
      (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_OneFace()));
    controller.setXemPhoto('/tmp/a.jpg');
    controller.goHome();
    controller.goXemForm();
    expect(controller.screen, AppScreen.xemForm);
    expect(controller.xemPhotoPath, isNull);
    expect(controller.xemRejectionReason, isNull);
  });

  testWidgets('submitXem transitions loading -> removing -> result when a face is found',
      (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_OneFace()));
    controller.goXemForm();
    controller.setXemPhoto('/tmp/a.jpg');

    unawaited(controller.submitXem());
    expect(controller.screen, AppScreen.xemLoading);

    await tester.pump(); // the face check itself resolves on a microtask
    expect(controller.screen, AppScreen.xemLoading); // still in the 1500ms simulated wait

    await tester.pump(const Duration(milliseconds: 1500));
    expect(controller.screen, AppScreen.xemRemoving);
    expect(controller.dropsCleared, 0);

    await tester.pump(const Duration(milliseconds: 1800));
    expect(controller.dropsCleared, 3);
    expect(controller.xemPct, 0);

    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.screen, AppScreen.xemResult);
    expect(controller.revealedAt, isNotEmpty);
  });

  testWidgets('submitXem rejects with noFace when the checker finds no face', (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_NoFace()));
    controller.setXemPhoto('/tmp/a.jpg');
    unawaited(controller.submitXem());
    await tester.pump();
    expect(controller.screen, AppScreen.xemRejected);
    expect(controller.xemRejectionReason, XemRejectionReason.noFace);
  });

  testWidgets('submitXem rejects with multipleFaces when the checker finds two', (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_TwoFaces()));
    controller.setXemPhoto('/tmp/a.jpg');
    unawaited(controller.submitXem());
    await tester.pump();
    expect(controller.screen, AppScreen.xemRejected);
    expect(controller.xemRejectionReason, XemRejectionReason.multipleFaces);
  });

  testWidgets('displayName falls back to Κάποιον when name is blank', (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_OneFace()));
    expect(controller.displayName, 'Κάποιον');
    controller.setName('  Μαρία  ');
    expect(controller.displayName, 'Μαρία');
  });

  testWidgets('submitCoffee transitions loading -> result over time', (tester) async {
    final controller =
        AppStateController(random: const FixedRandom(), faceChecker: _faceCheckerWith(_OneFace()));
    controller.goCoffeeForm();
    controller.setCoffeePhoto('/tmp/cup.jpg');

    unawaited(controller.submitCoffee());
    expect(controller.screen, AppScreen.coffeeLoading);

    await tester.pump(const Duration(milliseconds: 2200));
    expect(controller.screen, AppScreen.coffeeResult);
    expect(controller.coffeeResult, isNotNull);
  });
}
```

Create `app/test/screens/xem_rejected_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/screens/xem_rejected_screen.dart';
import 'package:evaskania/state/app_screen.dart';
import 'package:evaskania/state/app_state_controller.dart';

void main() {
  testWidgets('shows the no-face message when rejected for no face', (tester) async {
    final controller = AppStateController()..xemRejectionReason = XemRejectionReason.noFace;
    await tester.pumpWidget(MaterialApp(home: XemRejectedScreen(controller: controller)));
    expect(find.text('Δεν βλέπω πρόσωπο εδώ'), findsOneWidget);
  });

  testWidgets('shows the multiple-faces message when rejected for multiple faces', (tester) async {
    final controller = AppStateController()..xemRejectionReason = XemRejectionReason.multipleFaces;
    await tester.pumpWidget(MaterialApp(home: XemRejectedScreen(controller: controller)));
    expect(find.text('Ένας-ένας, παρακαλώ'), findsOneWidget);
  });

  testWidgets('retry button returns to the xem form', (tester) async {
    final controller = AppStateController()..xemRejectionReason = XemRejectionReason.noFace;
    await tester.pumpWidget(MaterialApp(home: XemRejectedScreen(controller: controller)));
    await tester.tap(find.text('Δοκίμασε ξανά'));
    expect(controller.screen, AppScreen.xemForm);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/state/app_state_controller_test.dart test/screens/xem_rejected_screen_test.dart`
Expected: FAIL — `app_state_controller.dart` doesn't yet accept `faceChecker` or branch on it, and `xem_rejected_screen.dart` doesn't exist.

- [ ] **Step 3: Modify `AppStateController`**

Replace the full contents of `app/lib/state/app_state_controller.dart` with:

```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/afflictions.dart';
import '../data/coffee_verdicts.dart';
import '../detection/face_checker.dart';
import 'app_screen.dart';

class AppStateController extends ChangeNotifier {
  AppStateController({Random? random, FaceChecker? faceChecker})
      : _random = random ?? Random(),
        _faceChecker = faceChecker ?? FaceChecker();

  final Random _random;
  final FaceChecker _faceChecker;
  Timer? _xemTimer;

  AppScreen screen = AppScreen.home;
  String name = '';
  String? xemPhotoPath;
  String? coffeePhotoPath;
  XemRejectionReason? xemRejectionReason;

  String xemFound = '';
  String xemNote = '';
  int xemStartPct = 0;
  int xemPct = 0;
  int dropsCleared = 0;
  String revealedAt = '';
  CoffeeVerdict? coffeeResult;

  String get displayName => name.trim().isEmpty ? 'Κάποιον' : name.trim();

  String get today => DateFormat('d MMM', 'el').format(DateTime.now());

  void goHome() {
    _xemTimer?.cancel();
    screen = AppScreen.home;
    notifyListeners();
  }

  void goXemForm() {
    _xemTimer?.cancel();
    xemPhotoPath = null;
    xemRejectionReason = null;
    screen = AppScreen.xemForm;
    notifyListeners();
  }

  void goCoffeeForm() {
    coffeePhotoPath = null;
    screen = AppScreen.coffeeForm;
    notifyListeners();
  }

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setXemPhoto(String path) {
    xemPhotoPath = path;
    notifyListeners();
  }

  void setCoffeePhoto(String path) {
    coffeePhotoPath = path;
    notifyListeners();
  }

  Future<void> submitXem() async {
    if (xemPhotoPath == null) return;
    screen = AppScreen.xemLoading;
    notifyListeners();

    final result = await _faceChecker.check(xemPhotoPath!);
    if (result != FaceCheckResult.ok) {
      xemRejectionReason = result == FaceCheckResult.noFace
          ? XemRejectionReason.noFace
          : XemRejectionReason.multipleFaces;
      screen = AppScreen.xemRejected;
      notifyListeners();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    final affliction = xemAfflictions[_random.nextInt(xemAfflictions.length)];
    _startRemoval(affliction);
  }

  void _startRemoval(Affliction affliction) {
    xemFound = affliction.name;
    xemNote = affliction.note;
    xemStartPct = affliction.startPct;
    xemPct = affliction.startPct;
    dropsCleared = 0;
    screen = AppScreen.xemRemoving;
    notifyListeners();

    final total = affliction.startPct;
    const totalDurationMs = 1800;
    final t0 = DateTime.now();
    _xemTimer?.cancel();
    _xemTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      final elapsedMs = DateTime.now().difference(t0).inMilliseconds;
      final frac = (elapsedMs / totalDurationMs).clamp(0.0, 1.0);
      xemPct = (total * (1 - frac)).round();
      dropsCleared = frac >= 0.999 ? 3 : (frac * 3).floor();
      notifyListeners();
      if (frac >= 1.0) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          revealedAt = _formatNow();
          screen = AppScreen.xemResult;
          notifyListeners();
        });
      }
    });
  }

  Future<void> submitCoffee() async {
    if (coffeePhotoPath == null) return;
    screen = AppScreen.coffeeLoading;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 2200));
    coffeeResult = coffeeVerdicts[_random.nextInt(coffeeVerdicts.length)];
    revealedAt = _formatNow();
    screen = AppScreen.coffeeResult;
    notifyListeners();
  }

  String _formatNow() => DateFormat('h:mm a', 'el').format(DateTime.now());

  @override
  void dispose() {
    _xemTimer?.cancel();
    super.dispose();
  }
}
```

(`goXemForm` already set `xemRejectionReason = null` in Task A5's version, so a retry after rejection doesn't carry a stale reason into a fresh attempt — nothing new there, just confirming it's still present.)

- [ ] **Step 4: Write `XemRejectedScreen`**

Create `app/lib/screens/xem_rejected_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../state/app_screen.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';

class XemRejectedScreen extends StatelessWidget {
  const XemRejectedScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    final isMultiple = controller.xemRejectionReason == XemRejectionReason.multipleFaces;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(icon: Icons.arrow_back, semanticLabel: 'Πίσω', onPressed: controller.goHome),
              const SizedBox(width: AppTokens.space2),
              const Text('Ξεμάτιασμα', style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          AppCard(
            children: [
              CardTitle(
                isMultiple ? 'Ένας-ένας, παρακαλώ' : 'Δεν βλέπω πρόσωπο εδώ',
                fontSize: 20,
              ),
              CardBody(
                isMultiple
                    ? 'Η γιαγιά ξεματιάζει έναν άνθρωπο τη φορά — ανέβασε φωτογραφία με '
                        'ένα μόνο πρόσωπο.'
                    : 'Η γιαγιά χρειάζεται να δει ένα πρόσωπο για να διώξει το μάτι — '
                        'δοκίμασε μια φωτογραφία που να φαίνεται καθαρά κάποιος.',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          PrimaryButton(label: 'Δοκίμασε ξανά', onPressed: controller.goXemForm),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Modify `AppShell`**

In `app/lib/screens/app_shell.dart`, add `import 'xem_rejected_screen.dart';` and split the combined switch arm:

```dart
              AppScreen.xemRejected => XemRejectedScreen(controller: controller),
              AppScreen.coffeeRejected => _RejectedFallback(controller: controller),
```

(replacing the old single `AppScreen.xemRejected || AppScreen.coffeeRejected => _RejectedFallback(controller: controller),` line). `_RejectedFallback` stays for now — Task C2 replaces the `coffeeRejected` arm and then deletes `_RejectedFallback` entirely.

- [ ] **Step 6: Modify `app_shell_test.dart`**

Its Ξεμάτιασμα flow test taps through to `submitXem`, which now awaits a real `FaceChecker` by default — inject a fake so it doesn't hit the ML Kit platform channel. Replace the full contents of `app/test/screens/app_shell_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evaskania/detection/face_checker.dart';
import 'package:evaskania/screens/app_shell.dart';
import 'package:evaskania/state/app_state_controller.dart';

Future<String?> _fakePick(ImageSource source) async => '/tmp/fake.jpg';

class _OneFace implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async =>
      [const Rect.fromLTWH(0, 0, 400, 400)];
}

class _FixedSize implements ImageSizeReader {
  @override
  Future<Size> readSize(String imagePath) async => const Size(1000, 1000);
}

FaceChecker _okFaceChecker() => FaceChecker(detectionSource: _OneFace(), sizeReader: _FixedSize());

void main() {
  testWidgets('home shows the masthead and both ritual cards', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
    expect(find.text('Ξεμάτιασμα'), findsOneWidget);
    expect(find.text('Ο Καφές'), findsOneWidget);
  });

  testWidgets('full Ξεμάτιασμα flow: home -> form -> pick -> submit -> result -> home',
      (tester) async {
    final controller = AppStateController(faceChecker: _okFaceChecker());
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );

    await tester.tap(find.text('Ξεμάτιασμα'));
    await tester.pumpAndSettle();
    expect(find.text('Ρίξε τη φωτογραφία εδώ'), findsOneWidget);

    await tester.tap(find.text('Ρίξε τη φωτογραφία εδώ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Βιβλιοθήκη φωτογραφιών'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ξεκίνα το ξεμάτιασμα'));
    await tester.pump();
    expect(find.text('Η γιαγιά συγκεντρώνεται…'), findsOneWidget);

    await tester.pump(); // the face check itself resolves on a microtask
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Βρέθηκε'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ξεμάτιασε άλλον'), findsOneWidget);

    await tester.tap(find.byTooltip('Αρχική'));
    await tester.pumpAndSettle();
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
  });

  testWidgets('full Ο Καφές flow: home -> form -> pick -> submit -> result -> home',
      (tester) async {
    final controller = AppStateController(faceChecker: _okFaceChecker());
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );

    await tester.tap(find.text('Ο Καφές'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ανέβασε το γυρισμένο φλιτζάνι'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Βιβλιοθήκη φωτογραφιών'));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Δωσ' μου το φλιτζάνι"));
    await tester.pump();
    expect(find.text('Η γιαγιά διαβάζει…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    expect(find.text('Διάβασε άλλο φλιτζάνι'), findsOneWidget);

    await tester.tap(find.byTooltip('Αρχική'));
    await tester.pumpAndSettle();
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
  });
}
```

(`Rect` and `Size` both come from `material.dart`'s re-export of `dart:ui`, same as in the `face_checker_test.dart` pattern from Task B1. The coffee flow test doesn't need a `cupChecker` override yet — `submitCoffee` doesn't call any checker until Task C2.)

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test`
Expected: PASS — every test in the suite, including the modified controller tests, the new rejected-screen tests, and the re-fitted `app_shell_test.dart`.

- [ ] **Step 8: Static check**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 9: Commit**

```bash
git add app/lib/state/app_state_controller.dart app/test/state/app_state_controller_test.dart app/lib/screens/xem_rejected_screen.dart app/test/screens/xem_rejected_screen_test.dart app/lib/screens/app_shell.dart app/test/screens/app_shell_test.dart
git commit -m "Wire FaceChecker into Ξεμάτιασμα submit flow with rejection screen"
```

---

## Task B3: Manual on-device verification of the face check

Real ML Kit face detection only runs on an actual iOS/Android device or simulator — it
cannot be exercised by `flutter test`. This task is a manual checklist, not automated
code; nothing here is committed unless a real bug is found and fixed (in which case,
fix it, add a regression test to `face_checker_test.dart` or
`app_state_controller_test.dart` per the patterns in B1/B2, and commit that fix
separately with its own message).

**Files:** none created — verification only. (If a bug surfaces: modify whichever of
`app/lib/detection/face_checker.dart` or `app/lib/state/app_state_controller.dart` is
at fault, per the bug.)

- [ ] **Step 1: Run the app on a real device or simulator**

```bash
cd app
flutter run
```

- [ ] **Step 2: Verify each case manually, using real or sample photos**

| # | Photo | Expected outcome |
|---|-------|-------------------|
| 1 | A clear selfie / single portrait | Proceeds to the loading animation, then a removal result |
| 2 | A group photo with 2+ people clearly visible | "Ένας-ένας, παρακαλώ" rejection |
| 3 | A landscape or object with no people (a room, a pet, a street) | "Δεν βλέπω πρόσωπο εδώ" rejection |
| 4 | A photo with one clear subject and a tiny, distant face in the background (e.g. someone walking by far away, or a face on a poster) | Proceeds normally — the background face should fall under the 5%-of-frame threshold and be ignored |

- [ ] **Step 3: Note the outcome**

If all four behave as expected, this task is done — no commit needed. If any case
misbehaves (e.g. the 5% area threshold feels wrong in practice — too strict or too
lenient), adjust `FaceChecker`'s `minAreaFraction` default in
`app/lib/detection/face_checker.dart`, re-run this checklist, and commit that
adjustment with a message explaining what was observed and changed.

---

## Task C1: `CupChecker`

**Files:**
- Create: `app/lib/detection/cup_checker.dart`
- Test: `app/test/detection/cup_checker_test.dart`

**Interfaces:**
- Produces: `enum CupCheckResult {ok, notACup}`; `abstract class ImageLabelSource {Future<List<MapEntry<String, double>>> labelImage(String imagePath)}`; `MlKitImageLabelSource implements ImageLabelSource` (the real one, wrapping `google_mlkit_image_labeling`); `CupChecker({ImageLabelSource? labelSource, double minConfidence = 0.6})` with `Future<CupCheckResult> check(String imagePath)` and `void dispose()`.

- [ ] **Step 1: Write the failing test**

Create `app/test/detection/cup_checker_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/detection/cup_checker.dart';

class _FakeLabelSource implements ImageLabelSource {
  _FakeLabelSource(this.labels);
  final List<MapEntry<String, double>> labels;
  @override
  Future<List<MapEntry<String, double>>> labelImage(String imagePath) async => labels;
}

void main() {
  test('a confident Cup label -> ok', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const [MapEntry('Cup', 0.92)]));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.ok);
  });

  test('a confident label in a different case (MUG) -> ok', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const [MapEntry('MUG', 0.75)]));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.ok);
  });

  test('no cup-like labels -> notACup', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const [MapEntry('Dog', 0.98)]));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.notACup);
  });

  test('a cup label below the confidence threshold -> notACup', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const [MapEntry('Cup', 0.4)]));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.notACup);
  });

  test('no labels at all -> notACup', () async {
    final checker = CupChecker(labelSource: _FakeLabelSource(const []));
    expect(await checker.check('/tmp/a.jpg'), CupCheckResult.notACup);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/detection/cup_checker_test.dart`
Expected: FAIL — `cup_checker.dart` doesn't exist.

- [ ] **Step 3: Write `CupChecker`**

Create `app/lib/detection/cup_checker.dart`:

```dart
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

enum CupCheckResult { ok, notACup }

/// Seam over ML Kit's image labeler so tests can inject a fake — platform
/// channels (which the real labeler uses) don't work in `flutter test`'s
/// headless environment.
abstract class ImageLabelSource {
  Future<List<MapEntry<String, double>>> labelImage(String imagePath);
}

class MlKitImageLabelSource implements ImageLabelSource {
  final ImageLabeler _labeler =
      ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.6));

  @override
  Future<List<MapEntry<String, double>>> labelImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final labels = await _labeler.processImage(inputImage);
    return labels.map((l) => MapEntry(l.label, l.confidence)).toList();
  }

  void dispose() => _labeler.close();
}

/// Ο Καφές's cup check: pass if the on-device image classifier returns any
/// cup/mug-family label at or above [minConfidence]. This is deliberately
/// coarse (see the spec's "Known trade-offs") — it can't tell an empty cup
/// with visible grounds from a full one, only that a cup-shaped object is
/// in the photo.
class CupChecker {
  CupChecker({ImageLabelSource? labelSource, this.minConfidence = 0.6})
      : _labelSource = labelSource ?? MlKitImageLabelSource();

  final ImageLabelSource _labelSource;
  final double minConfidence;

  static const Set<String> _cupLabels = {
    'cup',
    'coffee cup',
    'mug',
    'espresso',
    'teacup',
    'drinkware',
    'saucer',
    'tableware',
  };

  Future<CupCheckResult> check(String imagePath) async {
    final labels = await _labelSource.labelImage(imagePath);
    final hasCup = labels.any(
      (entry) => _cupLabels.contains(entry.key.toLowerCase()) && entry.value >= minConfidence,
    );
    return hasCup ? CupCheckResult.ok : CupCheckResult.notACup;
  }

  void dispose() {
    final source = _labelSource;
    if (source is MlKitImageLabelSource) source.dispose();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/detection/cup_checker_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add app/lib/detection/cup_checker.dart app/test/detection/cup_checker_test.dart
git commit -m "Add CupChecker using ML Kit image labeling"
```

---

## Task C2: Wire `CupChecker` into the Ο Καφές flow

**Files:**
- Modify: `app/lib/state/app_state_controller.dart` (inject `CupChecker`, branch `submitCoffee` on its result)
- Modify: `app/test/state/app_state_controller_test.dart` (existing `submitCoffee` test needs a stubbed-`ok` `CupChecker`; add a new rejection test)
- Create: `app/lib/screens/coffee_rejected_screen.dart`
- Test: `app/test/screens/coffee_rejected_screen_test.dart`
- Modify: `app/lib/screens/app_shell.dart` (route `AppScreen.coffeeRejected` to the new screen; delete `_RejectedFallback`, now fully unused)
- Modify: `app/test/screens/app_shell_test.dart` (its Ο Καφές end-to-end test drives `submitCoffee` by tapping through the UI — it now needs a fake `CupChecker` injected too, alongside the `FaceChecker` fake Task B2 already added)

**Interfaces:**
- Consumes: `CupChecker`, `CupCheckResult` (C1).
- Produces: `AppStateController({random, faceChecker, CupChecker? cupChecker})` — new optional constructor parameter, defaulting to a real `CupChecker()`. `CoffeeRejectedScreen({controller})`.

- [ ] **Step 1: Write the failing tests**

Replace the full contents of `app/test/state/app_state_controller_test.dart` with:

```dart
import 'dart:math';
import 'package:flutter/material.dart' show Rect, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:evaskania/detection/cup_checker.dart';
import 'package:evaskania/detection/face_checker.dart';
import 'package:evaskania/state/app_screen.dart';
import 'package:evaskania/state/app_state_controller.dart';

/// Deterministic stand-in for dart:math's Random so tests always land on
/// the first affliction / coffee verdict in the list.
class FixedRandom implements Random {
  const FixedRandom();
  @override
  int nextInt(int max) => 0;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

class _OneFace implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async =>
      [const Rect.fromLTWH(0, 0, 400, 400)];
}

class _NoFace implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async => const [];
}

class _TwoFaces implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async => [
        const Rect.fromLTWH(0, 0, 400, 400),
        const Rect.fromLTWH(500, 500, 400, 400),
      ];
}

class _FixedSize implements ImageSizeReader {
  @override
  Future<Size> readSize(String imagePath) async => const Size(1000, 1000);
}

class _CupLabel implements ImageLabelSource {
  @override
  Future<List<MapEntry<String, double>>> labelImage(String imagePath) async =>
      [const MapEntry('Cup', 0.9)];
}

class _NoCupLabel implements ImageLabelSource {
  @override
  Future<List<MapEntry<String, double>>> labelImage(String imagePath) async =>
      [const MapEntry('Dog', 0.9)];
}

FaceChecker _faceCheckerWith(FaceDetectionSource source) =>
    FaceChecker(detectionSource: source, sizeReader: _FixedSize());

CupChecker _cupCheckerWith(ImageLabelSource source) => CupChecker(labelSource: source);

void unawaited(Future<void> future) {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('el', null);
  });

  AppStateController buildController({
    FaceDetectionSource? faceSource,
    ImageLabelSource? cupSource,
  }) {
    return AppStateController(
      random: const FixedRandom(),
      faceChecker: _faceCheckerWith(faceSource ?? _OneFace()),
      cupChecker: _cupCheckerWith(cupSource ?? _CupLabel()),
    );
  }

  testWidgets('goXemForm clears any previous photo and rejection, and switches screen',
      (tester) async {
    final controller = buildController();
    controller.setXemPhoto('/tmp/a.jpg');
    controller.goHome();
    controller.goXemForm();
    expect(controller.screen, AppScreen.xemForm);
    expect(controller.xemPhotoPath, isNull);
    expect(controller.xemRejectionReason, isNull);
  });

  testWidgets('submitXem transitions loading -> removing -> result when a face is found',
      (tester) async {
    final controller = buildController();
    controller.goXemForm();
    controller.setXemPhoto('/tmp/a.jpg');

    unawaited(controller.submitXem());
    expect(controller.screen, AppScreen.xemLoading);

    await tester.pump(); // the face check itself resolves on a microtask
    expect(controller.screen, AppScreen.xemLoading); // still in the 1500ms simulated wait

    await tester.pump(const Duration(milliseconds: 1500));
    expect(controller.screen, AppScreen.xemRemoving);
    expect(controller.dropsCleared, 0);

    await tester.pump(const Duration(milliseconds: 1800));
    expect(controller.dropsCleared, 3);
    expect(controller.xemPct, 0);

    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.screen, AppScreen.xemResult);
    expect(controller.revealedAt, isNotEmpty);
  });

  testWidgets('submitXem rejects with noFace when the checker finds no face', (tester) async {
    final controller = buildController(faceSource: _NoFace());
    controller.setXemPhoto('/tmp/a.jpg');
    unawaited(controller.submitXem());
    await tester.pump();
    expect(controller.screen, AppScreen.xemRejected);
    expect(controller.xemRejectionReason, XemRejectionReason.noFace);
  });

  testWidgets('submitXem rejects with multipleFaces when the checker finds two', (tester) async {
    final controller = buildController(faceSource: _TwoFaces());
    controller.setXemPhoto('/tmp/a.jpg');
    unawaited(controller.submitXem());
    await tester.pump();
    expect(controller.screen, AppScreen.xemRejected);
    expect(controller.xemRejectionReason, XemRejectionReason.multipleFaces);
  });

  testWidgets('displayName falls back to Κάποιον when name is blank', (tester) async {
    final controller = buildController();
    expect(controller.displayName, 'Κάποιον');
    controller.setName('  Μαρία  ');
    expect(controller.displayName, 'Μαρία');
  });

  testWidgets('submitCoffee transitions loading -> result when a cup is found', (tester) async {
    final controller = buildController();
    controller.goCoffeeForm();
    controller.setCoffeePhoto('/tmp/cup.jpg');

    unawaited(controller.submitCoffee());
    expect(controller.screen, AppScreen.coffeeLoading);

    await tester.pump(); // the cup check itself resolves on a microtask
    await tester.pump(const Duration(milliseconds: 2200));
    expect(controller.screen, AppScreen.coffeeResult);
    expect(controller.coffeeResult, isNotNull);
  });

  testWidgets('submitCoffee rejects when no cup is found', (tester) async {
    final controller = buildController(cupSource: _NoCupLabel());
    controller.setCoffeePhoto('/tmp/cup.jpg');
    unawaited(controller.submitCoffee());
    await tester.pump();
    expect(controller.screen, AppScreen.coffeeRejected);
  });
}
```

Create `app/test/screens/coffee_rejected_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evaskania/screens/coffee_rejected_screen.dart';
import 'package:evaskania/state/app_screen.dart';
import 'package:evaskania/state/app_state_controller.dart';

void main() {
  testWidgets('shows the not-a-cup message', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(MaterialApp(home: CoffeeRejectedScreen(controller: controller)));
    expect(find.text('Αυτό δεν είναι φλιτζάνι'), findsOneWidget);
  });

  testWidgets('retry button returns to the coffee form', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(MaterialApp(home: CoffeeRejectedScreen(controller: controller)));
    await tester.tap(find.text('Δοκίμασε ξανά'));
    expect(controller.screen, AppScreen.coffeeForm);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/state/app_state_controller_test.dart test/screens/coffee_rejected_screen_test.dart`
Expected: FAIL — `app_state_controller.dart` doesn't yet accept `cupChecker` or branch on it, and `coffee_rejected_screen.dart` doesn't exist.

- [ ] **Step 3: Modify `AppStateController`**

Replace the full contents of `app/lib/state/app_state_controller.dart` with:

```dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../data/afflictions.dart';
import '../data/coffee_verdicts.dart';
import '../detection/cup_checker.dart';
import '../detection/face_checker.dart';
import 'app_screen.dart';

class AppStateController extends ChangeNotifier {
  AppStateController({Random? random, FaceChecker? faceChecker, CupChecker? cupChecker})
      : _random = random ?? Random(),
        _faceChecker = faceChecker ?? FaceChecker(),
        _cupChecker = cupChecker ?? CupChecker();

  final Random _random;
  final FaceChecker _faceChecker;
  final CupChecker _cupChecker;
  Timer? _xemTimer;

  AppScreen screen = AppScreen.home;
  String name = '';
  String? xemPhotoPath;
  String? coffeePhotoPath;
  XemRejectionReason? xemRejectionReason;

  String xemFound = '';
  String xemNote = '';
  int xemStartPct = 0;
  int xemPct = 0;
  int dropsCleared = 0;
  String revealedAt = '';
  CoffeeVerdict? coffeeResult;

  String get displayName => name.trim().isEmpty ? 'Κάποιον' : name.trim();

  String get today => DateFormat('d MMM', 'el').format(DateTime.now());

  void goHome() {
    _xemTimer?.cancel();
    screen = AppScreen.home;
    notifyListeners();
  }

  void goXemForm() {
    _xemTimer?.cancel();
    xemPhotoPath = null;
    xemRejectionReason = null;
    screen = AppScreen.xemForm;
    notifyListeners();
  }

  void goCoffeeForm() {
    coffeePhotoPath = null;
    screen = AppScreen.coffeeForm;
    notifyListeners();
  }

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setXemPhoto(String path) {
    xemPhotoPath = path;
    notifyListeners();
  }

  void setCoffeePhoto(String path) {
    coffeePhotoPath = path;
    notifyListeners();
  }

  Future<void> submitXem() async {
    if (xemPhotoPath == null) return;
    screen = AppScreen.xemLoading;
    notifyListeners();

    final result = await _faceChecker.check(xemPhotoPath!);
    if (result != FaceCheckResult.ok) {
      xemRejectionReason = result == FaceCheckResult.noFace
          ? XemRejectionReason.noFace
          : XemRejectionReason.multipleFaces;
      screen = AppScreen.xemRejected;
      notifyListeners();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    final affliction = xemAfflictions[_random.nextInt(xemAfflictions.length)];
    _startRemoval(affliction);
  }

  void _startRemoval(Affliction affliction) {
    xemFound = affliction.name;
    xemNote = affliction.note;
    xemStartPct = affliction.startPct;
    xemPct = affliction.startPct;
    dropsCleared = 0;
    screen = AppScreen.xemRemoving;
    notifyListeners();

    final total = affliction.startPct;
    const totalDurationMs = 1800;
    final t0 = DateTime.now();
    _xemTimer?.cancel();
    _xemTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      final elapsedMs = DateTime.now().difference(t0).inMilliseconds;
      final frac = (elapsedMs / totalDurationMs).clamp(0.0, 1.0);
      xemPct = (total * (1 - frac)).round();
      dropsCleared = frac >= 0.999 ? 3 : (frac * 3).floor();
      notifyListeners();
      if (frac >= 1.0) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          revealedAt = _formatNow();
          screen = AppScreen.xemResult;
          notifyListeners();
        });
      }
    });
  }

  Future<void> submitCoffee() async {
    if (coffeePhotoPath == null) return;
    screen = AppScreen.coffeeLoading;
    notifyListeners();

    final result = await _cupChecker.check(coffeePhotoPath!);
    if (result != CupCheckResult.ok) {
      screen = AppScreen.coffeeRejected;
      notifyListeners();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 2200));
    coffeeResult = coffeeVerdicts[_random.nextInt(coffeeVerdicts.length)];
    revealedAt = _formatNow();
    screen = AppScreen.coffeeResult;
    notifyListeners();
  }

  String _formatNow() => DateFormat('h:mm a', 'el').format(DateTime.now());

  @override
  void dispose() {
    _xemTimer?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 4: Write `CoffeeRejectedScreen`**

Create `app/lib/screens/coffee_rejected_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../state/app_state_controller.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';

class CoffeeRejectedScreen extends StatelessWidget {
  const CoffeeRejectedScreen({super.key, required this.controller});
  final AppStateController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GhostIconButton(icon: Icons.arrow_back, semanticLabel: 'Πίσω', onPressed: controller.goHome),
              const SizedBox(width: AppTokens.space2),
              const Text('Ο Καφές', style: TextStyle(fontFamily: kHeadingFontFamily, fontSize: 20)),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          const AppCard(
            children: [
              CardTitle('Αυτό δεν είναι φλιτζάνι', fontSize: 20),
              CardBody(
                'Η γιαγιά διαβάζει μόνο καφέ — ανέβασε μια φωτογραφία του φλιτζανιού, '
                'γυρισμένο, με το κατακάθι στα τοιχώματα.',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          PrimaryButton(label: 'Δοκίμασε ξανά', onPressed: controller.goCoffeeForm),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Modify `AppShell` and delete `_RejectedFallback`**

Replace the full contents of `app/lib/screens/app_shell.dart` with:

```dart
import 'package:flutter/material.dart';
import '../state/app_screen.dart';
import '../state/app_state_controller.dart';
import '../widgets/image_slot.dart';
import 'coffee_form_screen.dart';
import 'coffee_loading_screen.dart';
import 'coffee_rejected_screen.dart';
import 'coffee_result_screen.dart';
import 'home_screen.dart';
import 'xem_form_screen.dart';
import 'xem_loading_screen.dart';
import 'xem_rejected_screen.dart';
import 'xem_removing_screen.dart';
import 'xem_result_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.controller, this.pickImage = defaultPickImage});

  final AppStateController controller;
  final ImagePickFn pickImage;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: switch (controller.screen) {
              AppScreen.home => HomeScreen(controller: controller),
              AppScreen.xemForm => XemFormScreen(controller: controller, pickImage: pickImage),
              AppScreen.xemLoading => const XemLoadingScreen(),
              AppScreen.xemRemoving => XemRemovingScreen(controller: controller),
              AppScreen.xemResult => XemResultScreen(controller: controller),
              AppScreen.xemRejected => XemRejectedScreen(controller: controller),
              AppScreen.coffeeForm => CoffeeFormScreen(controller: controller, pickImage: pickImage),
              AppScreen.coffeeLoading => const CoffeeLoadingScreen(),
              AppScreen.coffeeResult => CoffeeResultScreen(controller: controller),
              AppScreen.coffeeRejected => CoffeeRejectedScreen(controller: controller),
            },
          ),
        );
      },
    );
  }
}
```

(`_RejectedFallback` and the now-unused `app_buttons.dart` import are gone — every `AppScreen` case has its real screen.)

- [ ] **Step 6: Modify `app_shell_test.dart`**

Its Ο Καφές flow test taps through to `submitCoffee`, which now awaits a real `CupChecker` by default — inject a fake, alongside the `FaceChecker` fake Task B2 already added. Replace the full contents of `app/test/screens/app_shell_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evaskania/detection/cup_checker.dart';
import 'package:evaskania/detection/face_checker.dart';
import 'package:evaskania/screens/app_shell.dart';
import 'package:evaskania/state/app_state_controller.dart';

Future<String?> _fakePick(ImageSource source) async => '/tmp/fake.jpg';

class _OneFace implements FaceDetectionSource {
  @override
  Future<List<Rect>> detectFaceBoxes(String imagePath) async =>
      [const Rect.fromLTWH(0, 0, 400, 400)];
}

class _FixedSize implements ImageSizeReader {
  @override
  Future<Size> readSize(String imagePath) async => const Size(1000, 1000);
}

class _CupLabel implements ImageLabelSource {
  @override
  Future<List<MapEntry<String, double>>> labelImage(String imagePath) async =>
      [const MapEntry('Cup', 0.9)];
}

FaceChecker _okFaceChecker() => FaceChecker(detectionSource: _OneFace(), sizeReader: _FixedSize());
CupChecker _okCupChecker() => CupChecker(labelSource: _CupLabel());

void main() {
  testWidgets('home shows the masthead and both ritual cards', (tester) async {
    final controller = AppStateController();
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
    expect(find.text('Ξεμάτιασμα'), findsOneWidget);
    expect(find.text('Ο Καφές'), findsOneWidget);
  });

  testWidgets('full Ξεμάτιασμα flow: home -> form -> pick -> submit -> result -> home',
      (tester) async {
    final controller = AppStateController(faceChecker: _okFaceChecker());
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );

    await tester.tap(find.text('Ξεμάτιασμα'));
    await tester.pumpAndSettle();
    expect(find.text('Ρίξε τη φωτογραφία εδώ'), findsOneWidget);

    await tester.tap(find.text('Ρίξε τη φωτογραφία εδώ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Βιβλιοθήκη φωτογραφιών'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ξεκίνα το ξεμάτιασμα'));
    await tester.pump();
    expect(find.text('Η γιαγιά συγκεντρώνεται…'), findsOneWidget);

    await tester.pump(); // the face check itself resolves on a microtask
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Βρέθηκε'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ξεμάτιασε άλλον'), findsOneWidget);

    await tester.tap(find.byTooltip('Αρχική'));
    await tester.pumpAndSettle();
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
  });

  testWidgets('full Ο Καφές flow: home -> form -> pick -> submit -> result -> home',
      (tester) async {
    final controller = AppStateController(cupChecker: _okCupChecker());
    await tester.pumpWidget(
      MaterialApp(home: AppShell(controller: controller, pickImage: _fakePick)),
    );

    await tester.tap(find.text('Ο Καφές'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ανέβασε το γυρισμένο φλιτζάνι'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Βιβλιοθήκη φωτογραφιών'));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Δωσ' μου το φλιτζάνι"));
    await tester.pump();
    expect(find.text('Η γιαγιά διαβάζει…'), findsOneWidget);

    await tester.pump(); // the cup check itself resolves on a microtask
    await tester.pump(const Duration(milliseconds: 2200));
    expect(find.text('Διάβασε άλλο φλιτζάνι'), findsOneWidget);

    await tester.tap(find.byTooltip('Αρχική'));
    await tester.pumpAndSettle();
    expect(find.text('e-ΒΑΣΚΑΝΙΑ'), findsOneWidget);
  });
}
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test`
Expected: PASS — the entire suite, including the modified controller tests, the new coffee-rejected screen tests, and the re-fitted `app_shell_test.dart`.

- [ ] **Step 8: Full static + build check**

```bash
cd app
flutter analyze
flutter build apk --debug
flutter build ios --no-codesign --simulator
```

Expected: no analyzer issues, both builds succeed.

- [ ] **Step 9: Commit**

```bash
git add app/lib/state/app_state_controller.dart app/test/state/app_state_controller_test.dart app/lib/screens/coffee_rejected_screen.dart app/test/screens/coffee_rejected_screen_test.dart app/lib/screens/app_shell.dart app/test/screens/app_shell_test.dart
git commit -m "Wire CupChecker into Ο Καφές submit flow with rejection screen (milestone C complete)"
```

---

## Task C3: Manual on-device verification of the cup check

Same rationale as Task B3 — real ML Kit image labeling only runs on an actual
iOS/Android device or simulator. Manual checklist, not automated code; only commit if
a real bug surfaces (fix it, add a regression test to `cup_checker_test.dart` or
`app_state_controller_test.dart`, commit that separately).

**Files:** none created — verification only.

- [ ] **Step 1: Run the app on a real device or simulator**

```bash
cd app
flutter run
```

- [ ] **Step 2: Verify each case manually, using real or sample photos**

| # | Photo | Expected outcome |
|---|-------|-------------------|
| 1 | An actual Greek/Turkish coffee cup (empty, grounds visible or not) | Proceeds to the loading animation, then a coffee reading |
| 2 | Any other mug or cup (a regular coffee mug, a teacup) | Proceeds normally too — this is the accepted coarseness from the spec (a cup is a cup; it can't tell it's specifically Greek coffee) |
| 3 | A landscape, a pet, a random household object with no cup | "Αυτό δεν είναι φλιτζάνι" rejection |
| 4 | A photo of a full cup of coffee (not emptied/read yet) | Proceeds normally — this is the known, spec-accepted limitation (no "is it empty" check without a server-side vision AI call); confirm this behaves as expected, not as a bug |

- [ ] **Step 3: Note the outcome**

If all four behave as expected (including #4's known coarseness), this task — and the
whole plan — is done. If case #3 keeps false-accepting some particular object your
testing turns up, adjust `CupChecker`'s `_cupLabels` set or `minConfidence` default in
`app/lib/detection/cup_checker.dart`, re-run this checklist, and commit that
adjustment with a message explaining what was observed and changed.

---

## Post-plan note

Once all three milestones are done, the app matches the spec's full scope: a native
Flutter app, no backend, with real on-device face detection gating Ξεμάτιασμα and real
on-device cup detection gating Ο Καφές. Anything beyond this (history/persistence,
image cropping, the stricter "empty cup with visible grounds" check) is explicitly out
of scope per the spec and would need its own brainstorming → spec → plan cycle if
wanted later.
