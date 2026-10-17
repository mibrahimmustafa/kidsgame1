import 'package:flutter/material.dart';

import 'models.dart';

/// Cinematic look for each world: sky, grounds, hills, and little
/// delights drawn procedurally (zero bitmaps — infinitely sharp HD).
class TrackTheme {
  const TrackTheme({
    required this.name,
    required this.skyTop,
    required this.skyBottom,
    required this.road,
    required this.roadEdge,
    required this.laneDash,
    required this.groundA,
    required this.groundB,
    required this.hill,
    required this.hillFar,
    required this.shade,
    this.night = false,
    this.rain = false,
    this.embers = false,
    this.stars = false,
    this.rainbowRoad = false,
  });

  final String name;
  final Color skyTop;
  final Color skyBottom;
  final Color road;
  final Color roadEdge;
  final Color laneDash;
  final Color groundA;
  final Color groundB;
  final Color hill;
  final Color hillFar;
  final Color shade;
  final bool night;
  final bool rain;
  final bool embers;
  final bool stars;
  final bool rainbowRoad;

  static TrackTheme themeFor(ThemeKind kind) => switch (kind) {
        ThemeKind.meadow => meadow,
        ThemeKind.beach => beach,
        ThemeKind.snow => snow,
        ThemeKind.desert => desert,
        ThemeKind.nightCity => city,
        ThemeKind.forestRain => forest,
        ThemeKind.volcano => volcano,
        ThemeKind.galaxy => galaxy,
      };

  static const meadow = TrackTheme(
    name: 'Sunny Meadow',
    skyTop: Color(0xFF7ED0F5),
    skyBottom: Color(0xFFD9F3FF),
    road: Color(0xFF3E4650),
    roadEdge: Color(0xFFFFE08A),
    laneDash: Color(0xFFF4F7FB),
    groundA: Color(0xFF6FCB63),
    groundB: Color(0xFF5DB856),
    hill: Color(0xFF4FA45C),
    hillFar: Color(0xFF7BCB86),
    shade: Color(0x24000000),
  );

  static const beach = TrackTheme(
    name: 'Sunny Beach',
    skyTop: Color(0xFF61C3F2),
    skyBottom: Color(0xFFFFF2C7),
    road: Color(0xFFD9B45A),
    roadEdge: Color(0xFFFFF7DF),
    laneDash: Color(0xFFFFFFFF),
    groundA: Color(0xFFFBE08A),
    groundB: Color(0xFFF6D178),
    hill: Color(0xFF67CBDA),
    hillFar: Color(0xFFBDEAF2),
    shade: Color(0x2A000000),
  );

  static const snow = TrackTheme(
    name: 'Snowy Hills',
    skyTop: Color(0xFFA9D8FF),
    skyBottom: Color(0xFFF3FBFF),
    road: Color(0xFF8CA0B4),
    roadEdge: Color(0xFFF0F6FF),
    laneDash: Color(0xFFFFFFFF),
    groundA: Color(0xFFF7FCFF),
    groundB: Color(0xFFE2F0FA),
    hill: Color(0xFFCCE4F5),
    hillFar: Color(0xFFEAF7FF),
    shade: Color(0x1F274458),
  );

  static const desert = TrackTheme(
    name: 'Cookie Desert',
    skyTop: Color(0xFF7CCDF2),
    skyBottom: Color(0xFFFFE1A6),
    road: Color(0xFFB98E52),
    roadEdge: Color(0xFFFFF0CC),
    laneDash: Color(0xFFFFF8E4),
    groundA: Color(0xFFF3CE82),
    groundB: Color(0xFFE5BC6C),
    hill: Color(0xFFC98F52),
    hillFar: Color(0xFFEBC082),
    shade: Color(0x26000000),
  );

  static const city = TrackTheme(
    name: 'Twinkle City',
    skyTop: Color(0xFF232E5C),
    skyBottom: Color(0xFF4F5E9E),
    road: Color(0xFF262C36),
    roadEdge: Color(0xFFFFC94D),
    laneDash: Color(0xFFFFE9A8),
    groundA: Color(0xFF2A3150),
    groundB: Color(0xFF20263C),
    hill: Color(0xFF353D62),
    hillFar: Color(0xFF454F7E),
    night: true,
    stars: true,
    shade: Color(0x33000000),
  );

  static const forest = TrackTheme(
    name: 'Rainy Forest',
    skyTop: Color(0xFFACC9C6),
    skyBottom: Color(0xFFE4F0EA),
    road: Color(0xFF37413B),
    roadEdge: Color(0xFFC8DFCB),
    laneDash: Color(0xFFE7F2E7),
    groundA: Color(0xFF3E6E52),
    groundB: Color(0xFF33604A),
    hill: Color(0xFF2E5B45),
    hillFar: Color(0xFF447A5D),
    rain: true,
    shade: Color(0x30000000),
  );

  static const volcano = TrackTheme(
    name: 'Volcano Valley',
    skyTop: Color(0xFF3B1F2B),
    skyBottom: Color(0xFF8E4033),
    road: Color(0xFF332F33),
    roadEdge: Color(0xFFFF8A50),
    laneDash: Color(0xFFFFC08A),
    groundA: Color(0xFF4A4142),
    groundB: Color(0xFF3B3437),
    hill: Color(0xFF55302F),
    hillFar: Color(0xFF6E3B36),
    embers: true,
    night: true,
    shade: Color(0x40000000),
  );

  static const galaxy = TrackTheme(
    name: 'Galaxy Loop',
    skyTop: Color(0xFF120B33),
    skyBottom: Color(0xFF3A1663),
    road: Color(0xFF1F1A36),
    roadEdge: Color(0xFFFF7BD5),
    laneDash: Color(0xFFFF7BD5),
    groundA: Color(0xFF1B1533),
    groundB: Color(0xFF150F2B),
    hill: Color(0xFF281C4C),
    hillFar: Color(0xFF3A2366),
    night: true,
    stars: true,
    rainbowRoad: true,
    shade: Color(0x38000000),
  );
}
