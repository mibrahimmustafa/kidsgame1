import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Local, offline, COPPA-friendly save data. No accounts, no analytics.
class GameSave {
  GameSave._(this._prefs, Map<String, dynamic> data) : _data = data;

  final SharedPreferences _prefs;
  Map<String, dynamic> _data;
  static const _key = 'speedy_stars_save_v1';

  static Future<GameSave> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    Map<String, dynamic> data;
    try {
      data = raw == null ? {} : (jsonDecode(raw) as Map<String, dynamic>).cast<String, dynamic>();
    } catch (_) {
      data = {};
    }
    // Fill defaults for a brand new player.
    data['coins'] ??= 60;
    data['selectedCar'] ??= CarSpec.defaultCar.id;
    data['ownedCars'] ??= <String>[CarSpec.defaultCar.id];
    data['levelUnlocked'] ??= 0;
    data['stars'] ??= <int, int>{}; // levelIndex -> best stars (via keys below)
    data['music'] ??= true;
    data['sfx'] ??= true;
    data['haptics'] ??= true;
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

  List<String> get ownedCars =>
      (_data['ownedCars'] as List).cast<String>();

  bool isCarOwned(String id) => ownedCars.contains(id);

  void buyCar(CarSpec car) {
    if (isCarOwned(car.id) || coins < car.price) return;
    coins -= car.price;
    ownedCars.add(car.id);
    selectedCarId = car.id;
    _persist();
  }

  int get maxUnlockedLevel => (_data['levelUnlocked'] as num).toInt();
  bool isLevelUnlocked(int index) => index <= maxUnlockedLevel;

  int starsFor(int levelIndex) => (_starsMap['$levelIndex'] as num?)?.toInt() ?? 0;

  void recordRun(RunResult result, int starsEarned) {
    if (!result.finished) return;
    coins += result.earnedCoins;
    final li = result.levelIndex;
    if (li == maxUnlockedLevel && starsEarned >= 1 && li + 1 < LevelSpec.levels.length) {
      _data['levelUnlocked'] = li + 1;
    }
    if (starsEarned > starsFor(li)) _starsMap['$li'] = starsEarned;
    _persist();
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
      'levelUnlocked': 0,
      'music': _data['music'],
      'sfx': _data['sfx'],
      'haptics': _data['haptics'],
    };
    _persist();
  }

  Future<void> _persist() async {
    try {
      await _prefs.setString(_key, jsonEncode(_encode(_data)));
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

  int get totalStars =>
      List<int>.generate(LevelSpec.levels.length, starsFor).reduce((a, b) => a + b);
}
