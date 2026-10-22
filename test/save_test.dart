import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedy_stars/game/models.dart';
import 'package:speedy_stars/game/save.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('GameSave loads with friendly defaults', () async {
    final save = await GameSave.load();
    expect(save.coins, 60);
    expect(save.selectedCarId, CarSpec.defaultCar.id);
    expect(save.isCarOwned(CarSpec.defaultCar.id), isTrue);
    expect(save.isLevelUnlocked(0), isTrue);
    expect(save.isLevelUnlocked(1), isTrue);
    expect(save.isLevelUnlocked(2), isTrue);
    expect(save.isLevelUnlocked(3), isFalse);
    expect(save.maxUnlockedLevel, 2);
    expect(save.musicOn, isTrue);
  });

  test('GameState: buying a car debits coins and selects it', () async {
    final save = await GameSave.load();
    final car = CarSpec.byId('leafy');
    save.coins = 1000;
    final before = save.coins;
    save.buyCar(car);
    expect(save.isCarOwned(car.id), isTrue);
    expect(save.selectedCarId, car.id);
    expect(save.coins, before - car.price);
  });

  test('Finishing a level unlocks the next one and awards stars', () async {
    final save = await GameSave.load();
    expect(save.isLevelCompleted(0), isFalse);
    expect(save.isLevelUnlocked(3), isFalse);
    final unlockedNew = save.recordRun(
      const RunResult(
        levelIndex: 0,
        finished: true,
        distanceTravelled: 1000,
        coinsCollected: 12,
        starsCollected: 4,
        heartsLeft: 2,
        elaspsed: Duration(seconds: 26),
      ),
      2,
    );
    expect(unlockedNew, isTrue);
    expect(save.isLevelCompleted(0), isTrue);
    expect(save.isLevelUnlocked(3), isTrue);
    expect(save.maxUnlockedLevel, 3);
    expect(save.starsFor(0), 2);
    expect(save.coins >= (12 + 30 + 20 + 50) - 1, isTrue);
  });

  test('LevelSpec packs every world uniquely', () {
    final themes = LevelSpec.levels.map((l) => l.theme).toSet();
    expect(themes.length, LevelSpec.levels.length);
    for (final level in LevelSpec.levels) {
      expect(level.cruiseSpeed, greaterThan(0));
      expect(level.spawnInterval, greaterThan(0));
    }
  });

  test('GameWorld saves progress across reloads', () async {
    final save = await GameSave.load();
    save.coins = 777;
    final reloaded = await GameSave.load();
    expect(reloaded.coins, 777);
  });
}
