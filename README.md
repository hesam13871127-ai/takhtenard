# تخته نرد — Takhteh Nard (Traditional Iranian Backgammon)

A complete, **production-ready, fully offline** mobile backgammon game implementing the
**traditional Iranian rules** of تخته نرد — built with Flutter for Android and iOS.

![Flutter](https://img.shields.io/badge/Flutter-3.24%2B-02569B) ![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2) ![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green) ![Offline](https://img.shields.io/badge/Offline-100%25-no%20internet)

---

## ✨ Features

### Authentic traditional Iranian rules
- **Traditional opening**: each player rolls one die; the higher roll starts and then rolls **both dice fresh** (ties re-roll automatically).
- **Doubles** grant **four moves**.
- **Hitting blots** sends them to the bar; entering from the bar into the opponent's home board is mandatory before any other move.
- **Bear-off** only with all 15 checkers in the home board; exact or higher-die-from-the-highest-lower-point.
- **Mandatory maximum dice usage** — if only one die can be played, the **higher** must be used whenever possible.
- **خال‌سوزی rule (no hit-and-run at home)**: a checker that hits inside the player's own home board is frozen for the rest of the turn — *unless* the dice would otherwise be wasted, in which case khal-soozi priority allows the escape.
- **Scoring**: normal win = 1 point, **مارس (gammon/mars)** = 2 points (backgammon-type wins also count as mars, per tradition). No doubling cube.
- Turn passes automatically (with animation + sound) when no moves remain.

### Gameplay
- Play **vs AI** with three difficulties:
  - **Easy** — randomized play with occasional weak moves, ~0.8–1.5 s think time.
  - **Medium** — values hits, primes and safety, ~0.6–1.2 s.
  - **Hard** — strong positional search with pip awareness, ~0.4–0.9 s, computed in a **background isolate** so the UI never freezes.
- **Local two-player** hot-seat mode with a clear turn indicator and optional automatic board flip for black.
- Movable checkers are highlighted after rolling; **tap-to-select, tap-to-move, or drag & drop**; illegal moves are structurally impossible (no dialogs, no invalid states).
- **Undo the last move** of your turn.
- Pip count, borne-off count and running match score per player.
- **Auto-save**: leave mid-game and continue exactly where you were.

### Presentation
- Premium **Persian luxury aesthetic**: walnut & gold palette, Vazirmatn font, full **RTL** Persian UI.
- Painted wooden board with three selectable themes (Classic walnut, Emerald night, Royal ruby), glossy 3D-style checkers and dice.
- Animated splash screen, home menu with difficulty selector, full illustrated rules screen, settings (sound, default difficulty, board theme, flip-for-black), and a golden celebration result screen (normal win / مارس).
- Nine bundled sound effects (dice roll, move, hit, re-enter, bear-off, turn change, win/lose, click).
- Responsive portrait-first layout (landscape supported), safe-area aware, 60 FPS target.

### Privacy
- **No internet permission in release builds** — verified automatically in CI (`aapt dump permissions` fails the build if `INTERNET` ever appears).
- No ads, no analytics, no tracking, no Firebase, no network calls — everything is bundled.

---

## 🏗 Architecture

Clean Architecture with a pure-Dart, UI-independent, fully unit-tested domain layer:

```
lib/
├── main.dart                     # Bootstrap: prefs → container → app
├── app.dart                      # MaterialApp (fa locale, RTL, dark luxury theme)
├── core/
│   ├── audio/                    # SoundController (audioplayers, one player per effect)
│   ├── constants/                # App constants
│   ├── localization/             # All Persian strings (AppStrings)
│   ├── theme/                    # Palette, ThemeData, board themes
│   └── utils/                    # Persian digit conversion
├── features/
│   ├── game/
│   │   ├── domain/               # PURE DART — no Flutter imports
│   │   │   ├── engine/           # TakhtehGame (state machine), rules, move search
│   │   │   ├── ai/               # AiEngine (easy/medium/hard), evaluation, shot risk
│   │   │   └── models/           # Position, DiceRoll, SingleMove, GameConfig, GameResult
│   │   ├── application/          # GameController (Riverpod Notifier) + GameSaver
│   │   └── presentation/         # GameScreen, BoardView, painters, checkers, dice
│   ├── home/  rules/  settings/  splash/  result/
└── shared/widgets/               # AppBackground, LuxuryButton
```

Key design decisions:
- **`TakhtehGame`** is the single source of truth for rules; it exposes an immutable-ish, snapshot-undoable state machine and a cached legal-move search (`MoveSearch`) that encodes the Iranian mandatory-usage and khal-soozi rules.
- **`GameController`** (Riverpod `Notifier`) orchestrates dice animations, human input, AI turns (via `Isolate.run`), banners, sounds and persistence — every async continuation is epoch-guarded, so restarting a game can never leak or race.
- The presentation layer consumes `GameUiState` and animates **stable checker identities** across moves (`AnimatedPositioned` + hop key), giving smooth, correct motion even when a hit and a move interleave.

---

## 🚀 Getting started

Requirements: Flutter **3.24+** (Dart 3.5+).

```bash
flutter pub get
flutter run             # on a connected device / emulator
```

### Tests

```bash
flutter test            # 6 domain test suites: rules, search, position, AI, khal-soozi
flutter analyze         # zero warnings
```

### CI

The included GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push/PR:
`flutter analyze` → `flutter test` → release APK + AAB build → **offline-permission audit** → iOS simulator build. Artifacts (APK/AAB) are attached to each run.

---

## 📦 Building for release

### Android (APK / AAB)

```bash
flutter build apk --release        # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release  # build/app/outputs/bundle/release/app-release.aab
```

**Store signing** — the project ships with debug signing so the release build installs
out of the box. Before publishing:

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore ~/takhtenard.jks -keyalg RSA -keysize 2048 \
           -validity 10000 -alias takhtenard
   ```
2. Copy it to `android/app/takhtenard.jks` (it is git-ignored) and create
   `android/key.properties`:
   ```properties
   storePassword=<your store password>
   keyPassword=<your key password>
   keyAlias=takhtenard
   storeFile=takhtenard.jks
   ```
3. In `android/app/build.gradle`, replace the debug signing config with:
   ```groovy
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }
   // ... inside android { buildTypes { release { ... } } }:
   signingConfigs {
       release {
           keyAlias keystoreProperties['keyAlias']
           keyPassword keystoreProperties['keyPassword']
           storeFile file(keystoreProperties['storeFile'])
           storePassword keystoreProperties['storePassword']
       }
   }
   // then: signingConfig signingConfigs.release
   ```
4. Rebuild with `flutter build appbundle --release` and upload the AAB to Google Play.

### iOS (IPA)

```bash
flutter build ipa --release        # requires a signing team in Xcode
```

Or open `ios/Runner.xcworkspace` in Xcode, select your team under
**Runner → Signing & Capabilities**, then **Product → Archive**.
For a quick unsigned check: `flutter build ios --release --no-codesign`.

App Store notes: the bundle id is `com.takhtenard.game` (change to your own before
submitting), the display name is «تخته نرد», and the app icon set is included.
The minimum deployment target is iOS 13.

---

## 📖 رهنمای فارسی (Quick guide in Persian)

**تخته نرد** — بازی کامل و آفلاین تخته نرد ایرانی برای اندروید و iOS.

- **بازی با هوش مصنوعی** در سه سطح «آسان»، «متوسط» و «سخت» — سطح سخت در نخستهٔ جداگانه فکر می‌کند و بازی هرگز کند نمی‌شود.
- **بازی دونفره** روی یک گوشی (نوبت هر بازیکن با نشانگر طلایی مشخص می‌شود و تخته می‌تواند خودکار برای سیاه بچرخد).
- **قوانین سنتی ایرانی**: تاس آغازین (عدد بزرگ‌تر شروع می‌کند و هر دو تاس را دوباره می‌اندازد)، جفت تاس چهار حرکت، خوردن مهره و ورود از مانع، جمع کردن مهره‌ها فقط با کامل شدن خانه، اجرای اجباری بیشترین تعداد تاس، و قانون **خال‌سوزی** (مهرهٔ خورنده در خانهٔ خودی تا پایان نوبت قفل می‌شود مگر آنکه تاس هدر رود).
- **امتیازدهی سنتی**: برد ساده ۱ امتیاز، مارس ۲ امتیاز.
- مهره‌های قابل حرکت بعد از انداختن تاس **طلکی می‌شوند**؛ با لمس یا کشیدن و رها کردن حرکت کنید. حرکت غیرمجاز عملاً ممکن نیست.
- **واگرد آخرین حرکت**، شمارش پیپ، امتیاز کل مسابقه، ذخیرهٔ خودکار بازی نیمه‌تمام، و تنظیمات صدا، سختی پیش‌فرض، تم تخته (گردویی، زمرد شب، یاقوت سلطنتی) و چرخش تخته.
- صدای تاس، حرکت، خوردن مهره، جمع کردن، تعویض نوبت، برد و باخت — همه به‌صورت باندل‌شده و آفلاین. بدون تبلیغ، بدون ردیابی، بدون اینترنت.

برای ساخت نسخهٔ اندروید: `flutter build apk --release`
و برای iOS: `flutter build ipa --release`

---

## 📄 License

The Vazirmatn font is bundled under the SIL Open Font License 1.1
(see `assets/fonts/OFL.txt`). All game code and assets in this repository are
provided for the project owner's use.
