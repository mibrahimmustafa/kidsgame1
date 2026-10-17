# 🏎️ Speedy Stars — Kids Car Racing (Android · Flutter)

A family-safe arcade racing game for **ages 7+**, written in Flutter.
**Zero external art or audio assets** — every pixel is drawn procedurally
with `CustomPainter`, and every sound is synthesized by a build tool.
No ads. No analytics. No network permissions.

---

## Architecture

```
lib/
├── main.dart                     # app bootstrap, routing (landscape, off-store-clean)
├── core/app_theme.dart           # design system + procedural car-preview painter
├── game/
│   ├── models.dart               # CarSpec, LevelSpec, RunResult, Entity
│   ├── save.dart                 # offline save (SharedPreferences, JSON blob)
│   ├── audio.dart                # SFX pool + looping music, fully failure-safe
│   ├── world.dart                # pure simulation: physics, spawning, collisions, events
│   ├── theme.dart                # 8 cinematic palettes (meadow → galaxy)
│   ├── painter.dart              # HD vector renderer (no textures anywhere)
│   └── race_screen.dart          # game loop (Ticker), input, HUD, boost, pause
└── screens/
    ├── home_screen.dart, garage_screen.dart, level_select_screen.dart
    ├── result_screen.dart, settings_dialog.dart   # parent-gated grown-up settings
tool/generate_audio.dart          # synthesizes all .wav audio from pure math
assets/audio/                     # 11 generated WAVs (SFX + 2 music loops)
```

**Engine**: no Flame dependency. A ~700-line simulation (`world.dart`) +
painter separation keeps 60 fps trivially and makes gameplay fully
unit-testable (see `test/world_test.dart`).

## Design pillars (age 7+)

- **Zero fail-frustration** — traffic bumps cost hearts, but cones only
  bounce you and oil is a giggle not a punishment.
- **Short runs** — every level is roughly 25–45 min of replayable haven;
  sessions land nicely in a kid's attention span.
- **Unlock next race on finish** — finishing *is* the win; 3 stars are
  bragging rights, not progress blockers.
- **Parent zone behind hold-gate** (3 s press) for settings/reset.
- **COPPA-clean** — offline, no permissions, no third-party anything.

## Feature list (v1.0)

Feature|Status
---|---
Eight themed worlds (Meadow→Beach→Snow→Desert→Night City→Rain Forest→Volcano→Galaxy)|✅
Six cars with stats & garage economy|✅
Nitro boost with speed-lines & flames|✅
Collectibles: coins, stars, hearts, boost caps|✅
Traffic AI + proximity honks|✅
Kid-safe obstacles: cones, oil slicks|✅
Star ratings + level unlocking|✅
Free Drive endless mode|✅
Offline save (coins, cars, stars, unlocked levels)|✅
Generated SFX + 2 music loops|✅
Haptic feedback (toggleable)|✅
Parent settings + 3 s hold-to-reset|✅
Full unit tests for save + simulation|✅

## Run

```bash
flutter pub get
dart run tool/generate_audio.dart   # only needed if you edit tool/
flutter run                         # or: flutter run -d <device>
flutter test                        # 12 green tests
flutter build apk --release         # requires Android SDK / Android Studio
```

## Roadmap (v1.1)

1. Launcher icons + store screenshots (procedural too).
2. Achievements & daily sticker challenges.
3. Two-player split-screen (Bluetooth-free, same screen).
4. Localization (AR/ESafter EN).
5. Optional cloud-free "report card" for grown-ups per session.
