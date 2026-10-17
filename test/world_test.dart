import 'package:flutter_test/flutter_test.dart';
import 'package:speedy_stars/game/models.dart';
import 'package:speedy_stars/game/world.dart';

void main() {
  test('Steering clamps to the road band', () {
    final world = GameWorld(level: LevelSpec.levels.first, car: CarSpec.cars.first);
    world.setSteerTarget(5.0);
    world.update(0.016, simulating: true);
    expect(world.lateral, lessThanOrEqualTo(1.0));
    expect(world.lateral, greaterThanOrEqualTo(-1.0));
  });

  test('Boost only spends nitro when enabled and available', () {
    final world = GameWorld(level: LevelSpec.levels.first, car: CarSpec.cars.first);
    world.nitro = 0;
    world.toggleBoost(true);
    expect(world.boosting, isFalse, reason: 'no nitro — boost denied');
    world.nitro = 100;
    world.toggleBoost(true);
    expect(world.boosting, isTrue);
    world.update(2, simulating: true);
    expect(world.nitro, lessThan(60), reason: '2s of boost drains ~52');
  });

  test('Boost speeds the car up by the boost scale', () {
    final world = GameWorld(level: LevelSpec.levels.first, car: CarSpec.cars.first);
    final base = world.activeSpeed;
    world.nitro = 100;
    world.toggleBoost(true);
    expect(world.activeSpeed, base * GameWorld.boostSpeedScale);
  });

  test('Traffic spawns ahead and scrolls toward the player', () {
    final world = GameWorld(level: LevelSpec.levels.first, car: CarSpec.cars.first);
    var spawned = 0;
    for (var i = 0; i < 900; i++) {
      world.update(0.1, simulating: true);
      for (final e in world.entities) {
        if (e.kind == EntityKind.trafficCar) {
          expect(e.speedFactor, inInclusiveRange(0.25, 0.7));
          spawned++;
        }
      }
    }
    expect(spawned, greaterThan(0));
  });

  test('Collecting coins increments the counter', () {
    final world = GameWorld(level: LevelSpec.levels.first, car: CarSpec.cars.first);
    world.entities.add(Entity(
      kind: EntityKind.coin,
      x: world.lateral,
      y: 0.1,
    ));
    world.update(0.016, simulating: true);
    expect(world.coinsCollected, 1);
  });

  test('Cars in the shop are always playable (never pay-to-lose)', () {
    for (final car in CarSpec.cars) {
      expect(car.topSpeed, greaterThanOrEqualTo(CarSpec.defaultCar.topSpeed));
      expect(car.handling, greaterThanOrEqualTo(CarSpec.defaultCar.handling));
      expect(car.boostPower, greaterThanOrEqualTo(CarSpec.defaultCar.boostPower));
    }
  });
}
