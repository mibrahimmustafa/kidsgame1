import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Local, offline, COPPA-friendly save data. No accounts, no analytics.
class GameSave {
  GameSave._(this._prefs, Map<String, dynamic> data) : _data = data;

  final SharedPreferences? _prefs;
  Map<String, dynamic> _data;
  static const _key = 'speedy_stars_save_v1';

  /// Number of starter tracks unlocked immediately for new players (Tracks 1, 2, and 3).
  static const int defaultUnlockedCount = 3;

  static Future<GameSave> load() async {
    SharedPreferences? prefs;
    Map<String, dynamic> data = {};
    try {
      prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        data = (jsonDecode(raw) as Map<String, dynamic>).cast<String, dynamic>();
      }
    } catch (_) {
      // In-memory fallback if storage is inaccessible
      data = {};
    }
    // Fill defaults for a brand new player.
    data['coins'] ??= 60;
    data['selectedCar'] ??= CarSpec.defaultCar.id;
    data['ownedCars'] ??= <String>[CarSpec.defaultCar.id];
    data['stars'] ??= <String, dynamic>{}; // levelIndex (as String) -> best stars
    data['music'] ??= true;
    data['sfx'] ??= true;
    data['haptics'] ??= true;

    // Track completed levels explicitly
    data['completedLevels'] ??= <int>[];
    final starsMap = (data['stars'] as Map).cast<String, dynamic>();
    final completedList = (data['completedLevels'] as List)
        .map((e) => (e as num).toInt())
        .toList();
    // Auto-migrate completed levels from any existing star records
    for (final key in starsMap.keys) {
      final idx = int.tryParse(key);
      if (idx != null &&
          (starsMap[key] as num? ?? 0) > 0 &&
          !completedList.contains(idx)) {
        completedList.add(idx);
      }
    }
    data['completedLevels'] = completedList;

    // Ensure at least the starter tracks (indexes 0, 1, 2) are unlocked
    final baseUnlocked = math.max(
      defaultUnlockedCount - 1,
      math.min(
        LevelSpec.levels.length - 1,
        (defaultUnlockedCount + completedList.length) - 1,
      ),
    );
    data['levelUnlocked'] = math.max(
      baseUnlocked,
      (data['levelUnlocked'] as num?)?.toInt() ?? (defaultUnlockedCount - 1),
    );

    final save = GameSave._(prefs, data);
    await save._persist();
    return save;
  }

  Map<String, dynamic> get _starsMap =>
      (_data['stars'] as Map).cast<String, dynamic>();

  // ---- progress ----
  int get coins => (_data['coins'] as num).toInt();
  set coins(int v) {
    _data['coins'] = v;
    _persist();
  }

  String get selectedCarId => _data['selectedCar'] as String;
  set selectedCarId(String id) {
    _data['selectedCar'] = id;
    _persist();
  }

  List<String> get ownedCars => (_data['ownedCars'] as List).cast<String>();

  bool isCarOwned(String id) => ownedCars.contains(id);

  void buyCar(CarSpec car) {
    if (isCarOwned(car.id) || coins < car.price) return;
    coins -= car.price;
    ownedCars.add(car.id);
    selectedCarId = car.id;
    _persist();
  }

  /// Explicit set of completed level indices.
  Set<int> get completedLevels =>
      ((_data['completedLevels'] as List?) ?? const <dynamic>[])
          .map((e) => (e as num).toInt())
          .toSet();

  bool isLevelCompleted(int index) => completedLevels.contains(index);

  int get maxUnlockedLevel {
    final fromCompletions = math.min(
      LevelSpec.levels.length - 1,
      (defaultUnlockedCount + completedLevels.length) - 1,
    );
    final saved = (_data['levelUnlocked'] as num?)?.toInt() ?? 0;
    return math.max(fromCompletions, saved);
  }

  bool isLevelUnlocked(int index) => index <= maxUnlockedLevel;

  int starsFor(int levelIndex) =>
      (_starsMap['$levelIndex'] as num?)?.toInt() ?? 0;

  /// Records the run result.
  /// Returns `true` if this run unlocked a brand-new race!
  bool recordRun(RunResult result, int starsEarned) {
    if (!result.finished) return false;
    final li = result.levelIndex;
    if (li < 0) {
      coins += result.earnedCoins;
      _persist();
      return false;
    }
    final prevUnlocked = maxUnlockedLevel;
    final wasCompleted = isLevelCompleted(li);

    coins += result.earnedCoins;

    // First-time completion awards completion state + 50 bonus coins!
    if (starsEarned >= 1 && !wasCompleted) {
      final currentCompleted = completedLevels.toList()..add(li);
      _data['completedLevels'] = currentCompleted;
      coins += 50;
    }

    if (starsEarned > starsFor(li)) {
      _starsMap['$li'] = starsEarned;
    }

    final newUnlocked = maxUnlockedLevel;
    _data['levelUnlocked'] = newUnlocked;
    _persist();

    return newUnlocked > prevUnlocked;
  }

  // ---- settings ----
  bool get musicOn => _data['music'] == true;
  bool get sfxOn => _data['sfx'] == true;
  bool get hapticsOn => _data['haptics'] == true;

  void setMusic(bool v) {
    _data['music'] = v;
    _persist();
  }

  void setSfx(bool v) {
    _data['sfx'] = v;
    _persist();
  }

  void setHaptics(bool v) {
    _data['haptics'] = v;
    _persist();
  }

  void resetAll() {
    _data = {
      'coins': 60,
      'selectedCar': CarSpec.defaultCar.id,
      'ownedCars': <String>[CarSpec.defaultCar.id],
      'levelUnlocked': defaultUnlockedCount - 1,
      'completedLevels': <int>[],
      'stars': <int, int>{},
      'music': _data['music'],
      'sfx': _data['sfx'],
      'haptics': _data['haptics'],
    };
    _persist();
  }

  Future<void> _persist() async {
    try {
      await _prefs?.setString(_key, jsonEncode(_encode(_data)));
    } catch (_) {
      // Save failures must never crash a kids' game.
    }
  }

  static dynamic _encode(dynamic v) {
    if (v is Map) {
      return v.map((k, val) => MapEntry('$k', _encode(val)));
    }
    if (v is List) return v.map(_encode).toList();
    return v;
  }

  int get totalStars => List<int>.generate(
        LevelSpec.levels.length,
        starsFor,
      ).reduce((a, b) => a + b);
}
