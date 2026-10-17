# 🏎️ Speedy Stars — Kids Car Racing (Android · Flutter)

A family-safe arcade racing game for **ages 7+**, written in Flutter.
**Zero external art or audio assets** — every pixel is drawn procedurally
with `CustomPainter`, and every sound is synthesized by a build tool.
No ads. No analytics. No network permissions.

---

## ✨ The signature experience: real driving (Cockpit mode)

Since v1.1 the race happens from **inside the car** — a first-person
cockpit with a working steering wheel, brake pedal, analog speedometer,
winding roads and engine audio whose pitch tracks your actual speed
(`lib/game/cockpit.dart`). A dazzling sky-camera is one tap away in
settings for accessibility (toggle “Real cockpit camera”).

**Controls**

| Action | Touch | Keyboard |
|---|---|---|
| Steer | drag left ↔ right | ← / → or A / D |
| Brake | hold pedal (bottom-left) | ↓ or S |
| Nitro | lightning button (boost) | ↑ |
| Horn (startles traffic into swerving!) | tap the wheel hub | Space |
| Pause | ⏸ chip | — |

**Feel-good driving tech**: speed-scaled steering, mild centrifugal push
in bends, tire screech when cornering hot, FOV speed-lines, engine drone
looping with dynamic pitch (`audio/engine_loop.wav`).

## Architecture

```
lib/
├── main.dart                     # app bootstrap, routing (landscape, off-store-clean)
├── core/app_theme.dart           # design system + procedural car-preview painter
├── core/app_icon.dart            # launcher icon artwork (procedural, reused everywhere)
├── game/
│   ├── models.dart               # CarSpec, LevelSpec, BodyStyle, CarMod, Entity
│   ├── save.dart                 # offline save (SharedPreferences, JSON blob)
│   ├── audio.dart                # SFX pool + music + dynamic engine loop
│   ├── haptics.dart              # single-gate vibration (Buzz) honoring the settings toggle
│   ├── world.dart                # pure simulation: physics, spawn, collisions, events
│   ├── cockpit.dart              # pseudo-3D first-person cockpit renderer
│   ├── painter.dart              # top-down ("sky camera") HD vector renderer
│   ├── theme.dart                # 8 cinematic palettes (meadow → galaxy)
│   └── race_screen.dart          # game loop (Ticker), input, HUD, brake/horn, pause
└── screens/
    ├── home_screen.dart          # cinematic dark title screen (starfield, glass showcase)
    ├── garage_screen.dart        # dark showroom: CARS / BODIES / MODS — everything free
    ├── level_select_screen.dart, result_screen.dart
    └── settings_dialog.dart      # parent-gated grown-up settings
tool/generate_audio.dart          # synthesizes all .wav audio from pure math
assets/audio/                     # 13 generated WAVs (SFX + engine + 2 music loops)
assets/icon/                      # rendered launcher icon + adaptive foreground
test/                             # save / world / garage widget tests
```

**Engine**: no game-ship dependency. A ~700-line simulation (`world.dart`)
+ painter separation keeps 60 fps trivially and makes gameplay fully
unit-testable. `pumpAndSettle` intentionally never settles on animated
screens — tests use fixed `pump(Duration)` steps.

## Design pillars (age 7+)

- **Zero fail-frustration** — traffic bumps cost hearts, but cones only
  bounce you and oil is a giggle, not a punishment.
- **Free customization** — cars, body shapes and bolt-on mods cost
  nothing; kids can always express themselves (coins are pure score
  that feeds nitro).
- **Unlock next race on finish** — finishing *is* the win; stars are
  bragging rights, not progress blockers.
- **Parent zone behind hold-gate** (3 s press) for settings/reset.
- **Instant audio settings** — toggling music/SFX/dynamics applies
  the moment you flip the switch.
- **COPPA-clean** — offline, no permissions, no third-party anything.

## Feature list (v1.2)

Feature|Status
---|---
Eight themed worlds (Meadow→Beach→Snow→Desert→Night City→Rain Forest→Volcano→Galaxy)|✅
Cockpit driving mode (wheel, pedal, horn, speedometer)|✅
Sky camera fallback (accessibility toggle)|✅
Six cars + 4 body shapes + 8 bolt-on mods — all free to swap|✅
Tesla-style EV "Classic" body: glass canopy, LED signature, aero turbine wheels|✅
Cinematic dark identity: home starfield, glass garage showroom, glass level grid|✅
Procedural launcher icon + Android adaptive icons + web favicons|✅
Mods render live on the hood & top-down view|✅
Nitro boost with speed-lines & flames|✅
Collectibles: coins, stars, hearts, boost caps|✅
Traffic AI + horn swerves + proximity honks|✅
Kid-safe obstacles: cones, oil slicks|✅
Star ratings + level unlocking|✅
Free Drive endless mode|✅
Offline save (coins, cars, bodies, mods, stars)|✅
Generated SFX + engine loop + 2 music loops|✅
Haptic feedback (single gate — `lib/game/haptics.dart`)|✅
Parent settings + 3 s hold-to-reset|✅
Save/simulation/garage tests|✅

## Run

```bash
flutter pub get
dart run tool/generate_audio.dart   # only needed if you edit tool/
flutter test                        # all green
flutter run -d <device>             # or: flutter run -d chrome
flutter build apk --release         # requires Android SDK / Android Studio
```

> WhatsApp-style health check: the settings dialog persists instantly
> (SharedPreferences); toggling music stops or resumes the current menu/
> race track at once; every buzz in the game is gated by the single
> “Vibration feedback” switch (`Buzz.*` in `lib/game/haptics.dart` — it
> even test-buzzes when you re-enable the switch) — on web browsers
> silent (no desktop vibration hardware), on Android devices fully
> functional.

## Art pipeline (all procedural)

- `test/icon_shot.dart`, `test/screen_shot.dart`, `test/cockpit_shot.dart`
  render headless PNGs (one `toImage` per flutter_tester process, gated by
  dart-defines) into `build/icon/` and `build/screens/`.
- `flutter_launcher_icons` consumes `assets/icon/` for Android adaptive
  icons; the same art is resized into `web/favicon.png` and
  `web/icons/Icon-*.png` so the PWA icon matches the store icon.

## Version history

- **v1.1** — cockpit mode, engine audio, free customization.
- **v1.2** — cinematic dark identity (home, garage, race grid), Tesla-style
  EV "Classic" body, procedural launcher icons, haptics single-gate.
  Roadmap next: achievements & sticker challenges, two-player same-screen,
  AR/ES localization.
