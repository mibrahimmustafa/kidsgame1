import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedy_stars/game/models.dart';
import 'package:speedy_stars/game/save.dart';
import 'package:speedy_stars/game/world.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('GameSave loads with friendly defaults', () async {
    final save = await GameSave.load();
    expect(save.coins, 60);
    expect(save.selectedCarId, CarSpec.defaultCar.id);
    expect(save.isCarOwned(CarSpec.defaultCar.id), isTrue);
    expect(save.maxUnlockedLevel, 0);
    expect(save.musicOn, isTrue);
  });

  test('GameState: buying a car is free and selects it', () async {
    final save = await GameSave.load();
    final car = CarSpec.byId('leafy');
    save.coins = 1000;
    final before = save.coins;
    save.buyCar(car);
    expect(save.isCarOwned(car.id), isTrue);
    expect(save.selectedCarId, car.id);
    // Customization is unlocked for everyone: prices are gone for good.
    expect(save.coins, before);
  });

  test('Finishing a level unlocks the next one and awards stars', () async {
    final save = await GameSave.load();
    save.recordRun(
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
    expect(save.maxUnlockedLevel, 1);
    expect(save.starsFor(0), 2);
    expect(save.coins >= (12 + 30 + 20) - 1, isTrue);
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

  test('regression: string-valued stars survive reload (web crash)', () async {
    // Older saves written before normalization stored values that JSON
    // round-trips could mutate into strings — they must not crash and
    // must still count as stars.
    final first = await GameSave.load();
    first.recordRun(
      const RunResult(
        levelIndex: 0,
        finished: true,
        distanceTravelled: 1000,
        coinsCollected: 5,
        starsCollected: 20,
        heartsLeft: 3,
        elaspsed: Duration(seconds: 25),
      ),
      3,
    );
    final reloaded = await GameSave.load();
    expect(reloaded.starsFor(0), 3);
    // Recording again on reloaded data must not throw.
    reloaded.recordRun(
      const RunResult(
        levelIndex: 0,
        finished: true,
        distanceTravelled: 1000,
        coinsCollected: 5,
        starsCollected: 10,
        heartsLeft: 1,
        elaspsed: Duration(seconds: 25),
      ),
      1,
    );
    expect(reloaded.starsFor(0), 3);
  });

  test('Body styles: equip is free and persists', () async {
    final save = await GameSave.load();
    save.coins = 1000;
    save.buyBody(BodyStyle.byId('monster'));
    expect(save.ownsBody('monster'), isTrue);
    expect(save.bodyId, 'monster');
    // No coin debit — every chassis is free to swap.
    expect(save.coins, 1000);
    final reloaded = await GameSave.load();
    expect(reloaded.ownsBody('monster'), isTrue);
    expect(reloaded.bodyId, 'monster');
  });

  test('Mods: buying is free, equips by default and toggles persist', () async {
    final save = await GameSave.load();
    save.coins = 1000;
    final mod = CarMod.byId('neon');
    save.buyMod(mod);
    expect(save.ownsMod('neon'), isTrue);
    expect(save.isModEquipped('neon'), isTrue);
    // No coin debit — every bolt-on is free to add.
    expect(save.coins, 1000);
    save.toggleMod('neon');
    expect(save.isModEquipped('neon'), isFalse);
    save.toggleMod('neon');
    expect(save.isModEquipped('neon'), isTrue);
    final reloaded = await GameSave.load();
    expect(reloaded.ownsMod('neon'), isTrue);
    expect(reloaded.isModEquipped('neon'), isTrue);
  });

  test('Cockpit driving: steering moves the car, brake slows honking swerve',
      () async {
    final save = await GameSave.load();
    save.setMusic(false);
    final world = GameWorld(
        level: LevelSpec.freeDrive, car: CarSpec.defaultCar);
    final startLateral = world.lateral;

    // full right lock for one simulated second drives the car right
    world.setSteer(1);
    const step = 1 / 60;
    for (var i = 0; i < 60; i++) {
      world.update(step);
    }
    expect(world.lateral, greaterThan(startLateral + 0.5));

    // steer back to center: the wheel self-centers and the car stops moving
    world.setSteer(0);
    final stopped = world.lateral;
    for (var i = 0; i < 30; i++) {
      world.update(step);
    }
    expect((world.lateral - stopped).abs(), lessThan(0.12));

    // brake pedal scrubs speed well below cruise
    world.setSteer(0);
    world.setBrake(true);
    for (var i = 0; i < 60; i++) {
      world.update(step);
    }
    expect(world.activeSpeed, lessThan(LevelSpec.freeDrive.cruiseSpeed * 0.6));
    world.setBrake(false);

    // the horn startles a car in our lane: it nudges out of the way
    world.entities.add(Entity(
      kind: EntityKind.trafficCar,
      x: world.lateral,
      y: 6,
      color: const Color(0xFFEF5350),
      speedFactor: 0.5,
    ));
    world.doHonk();
    final simEntity = world.entities.last;
    expect(simEntity.nudge.abs(), greaterThan(0.4));
    final preX = simEntity.x;
    for (var i = 0; i < 30; i++) {
      world.update(step);
    }
    expect((simEntity.x - preX).abs(), greaterThan(0.05));
  });

  test('Road curvature stays bounded and cockpit default is ON', () async {
    final save = await GameSave.load();
    expect(save.cockpitView, isTrue);
    final world = GameWorld(
        level: LevelSpec.freeDrive, car: CarSpec.defaultCar);
    for (var i = 0; i < 500; i++) {
      world.update(1 / 30);
    }
    expect(world.roadCurve.abs(), lessThan(0.9));
  });
}
