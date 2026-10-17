import 'package:flutter/material.dart';

/// ------------------------------- Entities ------------------------------- ///

enum EntityKind { trafficCar, coin, star, boostPowerUp, heart, cone, oilSlick }

/// A dynamic object on the road.
class Entity {
  Entity({
    required this.kind,
    required this.x,
    required this.y,
    this.lane = 0,
    this.color,
    this.speedFactor = 0.0,
    this.phase = 0.0,
    this.variant = 0,
  });

  EntityKind kind;
  double x; // road coordinate: -1 .. 1  (-1 = left edge, +1 = right edge)
  double y; // world-space meters ahead of the player; negative = behind
  int lane;
  Color? color; // traffic car livery
  double speedFactor; // fraction of player's cruise speed (traffic only)
  double phase; // animation phase (bobbing coins / wobble traffic)
  int variant; // sprite variant so repeats don't look cloned
  double nudge = 0; // lateral push from the player's HORN (traffic only)

  /// Collision half-extents in road units (football ~ x:[-0.14,0.14]).
  double get halfWidth => switch (kind) {
        EntityKind.trafficCar => 0.155,
        EntityKind.coin => 0.075,
        EntityKind.star => 0.085,
        EntityKind.boostPowerUp => 0.095,
        EntityKind.heart => 0.09,
        EntityKind.cone => 0.095,
        EntityKind.oilSlick => 0.16,
      };

  double get halfHeight => switch (kind) {
        EntityKind.trafficCar => 2.2,
        EntityKind.coin => 0.9,
        EntityKind.star => 1.0,
        EntityKind.boostPowerUp => 1.1,
        EntityKind.heart => 1.05,
        EntityKind.cone => 1.0,
        EntityKind.oilSlick => 0.6,
      };
}

/// ------------------------------- Bodies --------------------------------- ///

/// Chassis shapes the player can own and swap — each one changes the
/// silhouette in both the race painter and the garage preview.
enum BodyStyle {
  classic('classic', 'Classic', 0),
  muscle('muscle', 'Muscle', 180),
  sport('sport', 'Sprint', 320),
  monster('monster', 'Monster Truck', 500);

  const BodyStyle(this.id, this.label, this.price);
  final String id;
  final String label;
  final int price;

  static BodyStyle byId(String id) =>
      values.firstWhere((b) => b.id == id, orElse: () => classic);
}

/// ------------------------------- Mods ------------------------------------ ///

/// Visual bolt-on components. Purely cosmetic — every kid should feel
/// like a champion when they buy one.
class CarMod {
  const CarMod(this.id, this.name, this.emoji, this.price, this.blurb);
  final String id;
  final String name;
  final String emoji;
  final int price;
  final String blurb;

  static CarMod? byIdOrNull(String id) {
    for (final m in mods) {
      if (m.id == id) return m;
    }
    return null;
  }
  static const mods = <CarMod>[
    CarMod('spoiler', 'Grand Wing', '🪽', 120,
        'A championship rear wing with endplates.'),
    CarMod('stripes', 'Hero Stripes', '🏁', 80,
        'Twin racing stripes across hood and roof.'),
    CarMod('neon', 'Neon Underglow', '💡', 150,
        'A friendly glow that lights the tarmac.'),
    CarMod('exhaust', 'Twin Mega Exhaust', '🔥', 140,
        'Double pipes with extra rocket flames.'),
    CarMod('flag', 'Champion Flag', '🚩', 100,
        'A wavy flag to celebrate every win.'),
    CarMod('roundel', 'Race Number 7', '🔢', 90,
        'Pro style racing number on the roof.'),
    CarMod('lightbar', 'Roof Light Bar', '🔦', 130,
        'Four tiny lamps for dark races.'),
    CarMod('antenna', 'Bubble Antenna', '🎈', 60,
        'A happy bobbing antenna ball.'),
  ];

  static CarMod byId(String id) =>
      mods.firstWhere((m) => m.id == id, orElse: () => mods.first);
}

/// ------------------------------- Cars ------------------------------------ ///

/// A selectable kid racer. All specs are fractions in [0,1] tuned so every car
/// is viable — we never sell a "bad" car to a child.
class CarSpec {
  const CarSpec({
    required this.id,
    required this.name,
    required this.bodyColor,
    required this.accentColor,
    required this.price,
    required this.topSpeed, // world units / second at boost-free max
    required this.acceleration,
    required this.handling,
    required this.boostPower,
    required this.description,
  });

  final String id;
  final String name;
  final Color bodyColor;
  final Color accentColor;
  final int price;
  final double topSpeed;
  final double acceleration;
  final double handling;
  final double boostPower;
  final String description;

  static const cars = <CarSpec>[
    CarSpec(
      id: 'speedy',
      name: 'Speedy',
      bodyColor: Color(0xFFEF3B5D),
      accentColor: Color(0xFFFFD166),
      price: 0,
      topSpeed: 62,
      acceleration: 30,
      handling: 2.6,
      boostPower: 1.55,
      description: 'The little hero everyone starts with!',
    ),
    CarSpec(
      id: 'bluey',
      name: 'Bluey',
      bodyColor: Color(0xFF3B82F6),
      accentColor: Color(0xFFE0F2FE),
      price: 120,
      topSpeed: 65,
      acceleration: 32,
      handling: 2.7,
      boostPower: 1.6,
      description: 'Cool, calm and lightning quick.',
    ),
    CarSpec(
      id: 'leafy',
      name: 'Leafy',
      bodyColor: Color(0xFF22C55E),
      accentColor: Color(0xFFF0FDF4),
      price: 200,
      topSpeed: 67,
      acceleration: 34,
      handling: 2.9,
      boostPower: 1.62,
      description: 'Hugs every corner like a leaf in the wind.',
    ),
    CarSpec(
      id: 'bubbles',
      name: 'Bubbles',
      bodyColor: Color(0xFFA855F7),
      accentColor: Color(0xFFF5D0FE),
      price: 320,
      topSpeed: 70,
      acceleration: 35,
      handling: 3.0,
      boostPower: 1.68,
      description: 'So slippery fast, it leaves rainbows!',
    ),
    CarSpec(
      id: 'sunny',
      name: 'Sunny',
      bodyColor: Color(0xFFF97316),
      accentColor: Color(0xFFFFF7ED),
      price: 450,
      topSpeed: 73,
      acceleration: 36,
      handling: 3.1,
      boostPower: 1.72,
      description: 'A pocket rocket powered by smiles.',
    ),
    CarSpec(
      id: 'nightling',
      name: 'Nightling',
      bodyColor: Color(0xFF0F172A),
      accentColor: Color(0xFF38BDF8),
      price: 650,
      topSpeed: 76,
      acceleration: 38,
      handling: 3.25,
      boostPower: 1.8,
      description: 'The legend of the kindergarten track.',
    ),
  ];

  static CarSpec get defaultCar => cars.first;

  static CarSpec byId(String id) =>
      cars.firstWhere((c) => c.id == id, orElse: () => defaultCar);
}

/// ------------------------------ Levels ----------------------------------- ///

enum ThemeKind { meadow, beach, snow, desert, nightCity, forestRain, volcano, galaxy }

/// One race level. Difficulty knobs scale with the index.
class LevelSpec {
  const LevelSpec({
    required this.index,
    required this.name,
    required this.subtitle,
    required this.theme,
    required this.targetDistance,
    required this.cruiseSpeed,
    required this.trafficDensity,
    required this.spawnInterval,
    required this.doubleTraffic,
  });

  final int index;
  final String name;
  final String subtitle;
  final ThemeKind theme;
  final double targetDistance; // metres to finish the race
  final double cruiseSpeed; // base autonomous speed (units/s)
  final double trafficDensity; // how aggressively traffic spawns
  final double spawnInterval; // seconds between collectible spawns
  final bool doubleTraffic; // two cars can share a wave

  Duration get targetTime => Duration(
      seconds: (targetDistance / (cruiseSpeed * 0.92)).ceil().clamp(40, 150));

  /// Kid-friendly Free Drive: a chill endless cruise for ages 5-7.
  static const LevelSpec? noOpSpec = null;
  static const LevelSpec freeDrive = LevelSpec(
    index: -1,
    name: 'Free Drive',
    subtitle: 'Cruise with no rush at all!',
    theme: ThemeKind.meadow,
    targetDistance: 99999,
    cruiseSpeed: 46,
    trafficDensity: 0.5,
    spawnInterval: 0.9,
    doubleTraffic: false,
  );

  LevelSpec get asChill => index < 0
      ? this
      : LevelSpec(
          index: index,
          name: name,
          subtitle: subtitle,
          theme: theme,
          targetDistance: targetDistance,
          cruiseSpeed: cruiseSpeed - 6,
          trafficDensity: trafficDensity * 0.6,
          spawnInterval: spawnInterval + 0.2,
          doubleTraffic: false,
        );

  static const levels = <LevelSpec>[
    LevelSpec(// 0 - tutorial-easy
        index: 0,
        name: 'Sunny Meadow',
        subtitle: 'Say hi to the racing road!',
        theme: ThemeKind.meadow,
        targetDistance: 1000,
        cruiseSpeed: 52,
        trafficDensity: 0.55,
        spawnInterval: 0.9,
        doubleTraffic: false),
    LevelSpec(
        index: 1,
        name: 'Sunny Beach',
        subtitle: 'Watch out for sandy corners!',
        theme: ThemeKind.beach,
        targetDistance: 1150,
        cruiseSpeed: 55,
        trafficDensity: 0.7,
        spawnInterval: 0.8,
        doubleTraffic: false),
    LevelSpec(
        index: 2,
        name: 'Snowy Hills',
        subtitle: 'SlideLimits: gentle on ice!',
        theme: ThemeKind.snow,
        targetDistance: 1300,
        cruiseSpeed: 57,
        trafficDensity: 0.8,
        spawnInterval: 0.75,
        doubleTraffic: true),
    LevelSpec(
        index: 3,
        name: 'Cookie Desert',
        subtitle: 'Sweet speedy dunes ahead!',
        theme: ThemeKind.desert,
        targetDistance: 1450,
        cruiseSpeed: 59,
        trafficDensity: 0.9,
        spawnInterval: 0.7,
        doubleTraffic: true),
    LevelSpec(
        index: 4,
        name: 'Twinkle City',
        subtitle: 'Bright lights, big race!',
        theme: ThemeKind.nightCity,
        targetDistance: 1600,
        cruiseSpeed: 61,
        trafficDensity: 1.0,
        spawnInterval: 0.62,
        doubleTraffic: true),
    LevelSpec(
        index: 5,
        name: 'Rainy Forest',
        subtitle: 'Puddle splashing race!',
        theme: ThemeKind.forestRain,
        targetDistance: 1750,
        cruiseSpeed: 63,
        trafficDensity: 1.12,
        spawnInterval: 0.58,
        doubleTraffic: true),
    LevelSpec(
        index: 6,
        name: 'Volcano Valley',
        subtitle: 'Hot wheels on the run!',
        theme: ThemeKind.volcano,
        targetDistance: 1900,
        cruiseSpeed: 66,
        trafficDensity: 1.25,
        spawnInterval: 0.52,
        doubleTraffic: true),
    LevelSpec(
        index: 7,
        name: 'Galaxy Loop',
        subtitle: 'The star champion race!',
        theme: ThemeKind.galaxy,
        targetDistance: 1950,
        cruiseSpeed: 69,
        trafficDensity: 1.4,
        spawnInterval: 0.46,
        doubleTraffic: true),
  ];
}

/// ------------------------------ Results ---------------------------------- ///

class RunResult {
  const RunResult({
    required this.levelIndex,
    required this.finished,
    required this.distanceTravelled,
    required this.coinsCollected,
    required this.starsCollected,
    required this.heartsLeft,
    required this.elaspsed,
  });

  final int levelIndex;
  final bool finished;
  final double distanceTravelled;
  final int coinsCollected;
  final int starsCollected;
  final int heartsLeft;
  final Duration elaspsed;

  int get earnedCoins => coinsCollected + (finished ? 30 : 0) + heartsLeft * 10;
}
