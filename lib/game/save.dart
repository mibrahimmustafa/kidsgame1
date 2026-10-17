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
    // Stars are keyed as STRINGS ('0', '1', …) — JSON round-trips turn
    // int keys into strings, and a mixed-key map is what crashed on web.
    data['coins'] ??= 60;
    data['selectedCar'] ??= CarSpec.defaultCar.id;
    data['ownedCars'] ??= <String>[CarSpec.defaultCar.id];
    data['levelUnlocked'] ??= 0;
    // Stars keyed as STRINGS ('0', '1', …) — JSON round-trips turn int
    // keys into strings and a mixed-key map crashes dart2js on web.
    data['stars'] ??= <String, int>{};
    data['music'] ??= true;
    data['sfx'] ??= true;
    data['haptics'] ??= true;
    // Normalize: force every stars key/value back to String->int in case
    // an older save stored int keys or string values.
    if (data['stars'] is Map) {
      data['stars'] = (data['stars'] as Map)
          .map((k, v) => MapEntry('$k', (v as num?)?.toInt() ?? 0));
    }
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

  // ---- body styles ----
  String get bodyId => _data['body'] as String? ?? 'classic';
  set bodyId(String id) {
    _data['body'] = id;
    _persist();
  }

  List<String> get ownedBodies =>
      (_data['ownedBodies'] as List?)?.cast<String>() ?? <String>['classic'];

  bool ownsBody(String id) =>
      ownedBodies.contains(id) || id == 'classic';

  void buyBody(BodyStyle body) {
    if (ownsBody(body.id) || coins < body.price) return;
    coins -= body.price;
    final list = ownedBodies;
    list.add(body.id);
    _data['ownedBodies'] = list;
    bodyId = body.id;
    _persist();
  }

  // ---- mods (bolt-on components) ----
  List<String> get ownedMods =>
      (_data['ownedMods'] as List?)?.cast<String>() ?? <String>[];

  List<String> get equippedMods =>
      (_data['equippedMods'] as List?)?.cast<String>() ?? <String>[];

  bool ownsMod(String id) => ownedMods.contains(id);

  bool isModEquipped(String id) => equippedMods.contains(id);

  void buyMod(CarMod mod) {
    if (ownedMods.contains(mod.id) || coins < mod.price) return;
    coins -= mod.price;
    final owned = ownedMods..add(mod.id);
    _data['ownedMods'] = owned;
    final equipped = equippedMods..add(mod.id);
    _data['equippedMods'] = equipped;
    _persist();
  }

  void toggleMod(String id) {
    if (!ownedMods.contains(id)) return;
    final list = equippedMods;
    if (!list.remove(id)) list.add(id);
    _data['equippedMods'] = list;
    _persist();
  }

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

  /// Cockpit (first-person) driving camera. Defaults ON — it's the
  /// signature experience; sky view is the accessibility fallback.
  bool get cockpitView => _data['cockpit'] is bool ? _data['cockpit'] : true;

  void setCockpitView(bool v) {
    _data['cockpit'] = v;
    _persist();
  }

  void resetAll() {
    _data = {
      'coins': 60,
      'selectedCar': CarSpec.defaultCar.id,
      'ownedCars': <String>[CarSpec.defaultCar.id],
      'ownedBodies': <String>['classic'],
      'body': 'classic',
      'ownedMods': <String>[],
      'equippedMods': <String>[],
      'levelUnlocked': 0,
      'stars': <String, int>{},
      'music': _data['music'],
      'sfx': _data['sfx'],
      'haptics': _data['haptics'],
      'cockpit': _data['cockpit'],
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
