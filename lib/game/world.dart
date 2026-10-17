import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

/// Pure gameplay simulation — no I/O, no UI. The race screen's ticker
/// advances this every frame; the painter draws whatever state results.
/// All audio emerges from `Event`s the UI layer drains each frame.
class GameWorld {
  GameWorld({required this.level, required this.car}) {
    // Start on the second lane, gently rolling with a thumb-free intro.
    lateral = -0.22;
    targetLateral = -0.22;
  }

  final LevelSpec level;
  final CarSpec car;
  final math.Random _rng = math.Random();

  // ---- tunables ----------------------------------------------------------
  static const double boostSpeedScale = 1.55;
  static const double boostCostPerSecond = 26; // nitro units / second
  static const double coinNitroGain = 14;
  static const int maxHearts = 3;
  static const double invulnerableSeconds = 2.4;
  static const double brakeSpeedScale = 0.42; // cockpit brake pedal
  static const double steerLateralRate = 1.30; // road-widths/second at full lock

  // ---- world state -------------------------------------------------------
  double distance = 0;
  double speedKmh = 0;
  double lateral = -0.22; // -1 (left road edge) .. +1 (right road edge)
  double targetLateral = -0.22;
  bool boosting = false;
  double nitro = 55; // starts half-full: instant boost fun
  int hearts = maxHearts;
  int coinsCollected = 0;
  int starsCollected = 0;
  int bonusPickupsEaten = 0;
  double elapsedSeconds = 0;
  bool finished = false;
  bool crashedOut = false;
  double slipSeconds = 0;
  double bumpSeconds = 0;
  double invulnSeconds = 0;
  double shake = 0;
  double flash = 0;
  double fireworkTimer = 0;

  // ---- cockpit driving state ----
  double steer = 0; // -1 (full left) .. +1 (full right) — rotates the wheel
  bool braking = false;
  bool hornHeld = false;
  double _screechHold = 0;
  double _screechCooldown = 0;

  final List<Entity> entities = <Entity>[];
  final List<Particle> particles = <Particle>[];
  final List<GameEvent> events = <GameEvent>[]; // drained by the UI layer

  double _spawnTimer = 1.8;
  double _honkCooldown = 0;
  double crashCooldown = 0;

  bool get running => !finished && !crashedOut;

  double get progress => (distance / level.targetDistance).clamp(0.0, 1.0);

  /// Current forward velocity (units/second), considering boost, bumps &
  /// the brake pedal (cockpit mode). Braking eases in like a real pedal.
  double _brakeEase = 0;

  double get activeSpeed {
    final base = level.cruiseSpeed *
        (boosting ? boostSpeedScale : 1.0) *
        (bumpSeconds > 0 ? 0.55 : 1.0);
    if (braking) return base * (1.0 - (1.0 - brakeSpeedScale) * _brakeEase);
    return base;
  }

  /// Engine load 0..1.35 for sound pitch (1.0 = cruise).
  double get engineLoad =>
      activeSpeed / level.cruiseSpeed;

  /// Gentle winding-road curvature for the cockpit camera: the road bends
  /// slowly and the car feels a mild centrifugal push. Fully cosmetic for
  /// sky view, physical for cockpit.
  double get roadCurve =>
      math.sin(distance * 0.0021) * 0.55 +
      math.sin(distance * 0.0037 + 1.7) * 0.28;

  static const List<Color> trafficLivery = [
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFFFEE58),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
    Color(0xFF26C6DA),
  ];

  // --------------------------------------------------------------- input
  void setSteerTarget(double lateralTarget) {
    targetLateral = lateralTarget.clamp(-1.0, 1.0);
  }

  /// Cockpit driving: analog steering wheel (-1..+1) that self-centers
  /// and a brake pedal. Applied as a force so fast driving always feels
  /// heavier than slow driving.
  void setSteer(double analog) {
    steer = analog.clamp(-1.0, 1.0);
  }

  void setBrake(bool engaged) {
    braking = engaged;
  }

  /// Blaring the horn startles nearby cars — they swerve out of the way.
  /// A friendly superpower, and it keeps kids honking joyfully.
  void doHonk() {
    events.add(GameEvent.honk);
    for (final e in entities) {
      if (e.kind != EntityKind.trafficCar) continue;
      if (e.y < 1.0 || e.y > 17) continue;
      final gap = e.x - lateral;
      if (gap.abs() < 0.42) {
        e.nudge = (gap.abs() < 0.02 ? 0.5 : gap.sign) * 1.6;
      }
    }
  }

  void toggleBoost(bool enable) {
    if (enable) {
      if (nitro < 8) {
        events.add(GameEvent.boostEnd); // deny with tiny feedback
        return;
      }
      if (!boosting) events.add(GameEvent.boostStart);
      boosting = true;
    } else {
      if (boosting) events.add(GameEvent.boostEnd);
      boosting = false;
    }
  }

  // --------------------------------------------------------------- update
  /// Call once per frame with the elapsed seconds for this tick.
  void update(double dt, {bool simulating = true}) {
    // Visual decay always runs so screens settle even when paused.
    shake = math.max(0, shake - dt * 2.6);
    flash = math.max(0, flash - dt * 2.4);
    _honkCooldown = math.max(0, _honkCooldown - dt);
    _advanceParticles(dt);

    if (!simulating || finished || crashedOut) return;
    if (dt <= 0) return;
    elapsedSeconds += dt;

    // --- motion
    _brakeEase = braking
        ? math.min(1.0, _brakeEase + dt * 6)
        : math.max(0.0, _brakeEase - dt * 4);
    final speed = activeSpeed;
    distance += speed * dt;
    speedKmh = speed * 1.8;
    if (!finished && distance >= level.targetDistance) {
      finished = true;
      events.add(GameEvent.win);
    }

    // --- lateral movement
    if (steer != 0.0) {
      // cockpit driving: wheel force scaled by road speed (real feel)
      final speedFactor = (speed / level.cruiseSpeed).clamp(0.35, 2.0);
      final grip = slipSeconds > 0 ? 0.55 : 1.0;
      lateral += steer * steerLateralRate * speedFactor * grip * dt;
      targetLateral = lateral; // keeps sky painter consistent
    } else {
      targetLateral = lateral; // no sticky auto-center for cockpit
    }
    // centrifugal drift from the winding road (outward push)
    final speedFactor = (speed / level.cruiseSpeed).clamp(0.0, 2.0);
    lateral += -roadCurve * 0.30 * speedFactor * dt;

    // --- tire screech when cornering hot (slipping grip)
    _screechCooldown = math.max(0, _screechCooldown - dt);
    if (steer.abs() > 0.72 && speedFactor > 1.05 && slipSeconds <= 0) {
      _screechHold += dt;
      if (_screechHold > 0.28 && _screechCooldown <= 0) {
        _screechHold = 0;
        _screechCooldown = 1.1;
        if (!braking) events.add(GameEvent.screech);
      }
    } else {
      _screechHold = 0;
    }

    // --- lateral steering with exponential smoothing (frame-rate safe)
    final grip = car.handling * (slipSeconds > 0 ? 0.45 : 1.0);
    final k = 1 - math.exp(-grip * dt * 4.2);
    lateral += (targetLateral - lateral) * k;
    if (slipSeconds > 0) {
      slipSeconds -= dt;
      lateral += math.sin(elapsedSeconds * 6.5) * 0.35 * dt;
    }
    lateral = lateral.clamp(-1.0, 1.0);

    if (bumpSeconds > 0) bumpSeconds -= dt;
    if (invulnSeconds > 0) invulnSeconds -= dt;
    if (crashCooldown > 0) crashCooldown -= dt;

    // --- boost bookkeeping
    if (boosting) {
      nitro = (nitro - boostCostPerSecond * dt).clamp(0.0, 100.0);
      if (nitro <= 0) {
        boosting = false;
        events.add(GameEvent.boostEnd);
      }
    }
    fireworkTimer = (fireworkTimer - dt) % 10;

    // --- entities scroll toward the player
    for (final e in entities) {
      final speedOf =
          e.kind == EntityKind.trafficCar ? speed * e.speedFactor : speed;
      e.y -= speedOf * dt;
      if (e.kind == EntityKind.coin || e.kind == EntityKind.star) {
        e.phase += dt * 4;
        // soft magnetism: coins noodle toward hungry little players
        final gap = (e.x - lateral).abs();
        if (e.y < 9 && e.y > -1 && gap < 0.45) {
          e.x += (lateral - e.x) * 2.4 * dt;
        }
      }
      if (e.kind == EntityKind.trafficCar) {
        e.x += math.sin(e.phase * (0.9 + e.variant * 0.11)) * 0.06 * dt;
        // honk power: startled cars drift away from an angry little horn
        if (e.nudge != 0) {
          e.x += e.nudge * dt;
          e.nudge = e.nudge * (1 - 2.5 * dt).clamp(0.0, 0.999);
          if (e.nudge.abs() < 0.05) e.nudge = 0;
        }
        e.x = e.x.clamp(-1.2, 1.2);
        _honkIfNear(e);
      }
    }

    _collide();
    entities.removeWhere((e) => e.y < -12);
    _spawn(dt);
  }

  // ------------------------------------------------------------ collisions
  void _collide() {
    const playerHalfW = 0.15;
    const playerHalfH = 1.9;
    for (final e in entities) {
      final hitW = e.halfWidth + playerHalfW;
      final hitH = e.halfHeight + playerHalfH;
      final dz = (e.y - 0).abs();
      final dx = (e.x - lateral).abs();
      if (dz > hitH || dx > hitW) continue;

      switch (e.kind) {
        case EntityKind.coin:
          coinsCollected++;
          nitro = math.min(100, nitro + coinNitroGain);
          events.add(GameEvent.coin);
          _burst(e.x, e.y, 6, const Color(0xFFFFD54F));
          e.y = -99; // collect
        case EntityKind.star:
          starsCollected++;
          nitro = 100;
          events.add(GameEvent.star);
          _burst(e.x, e.y, 9, const Color(0xFFFFE082));
          e.y = -99;
        case EntityKind.heart:
          if (hearts < maxHearts) {
            hearts++;
            events.add(GameEvent.heart);
          }
          _burst(e.x, e.y, 8, const Color(0xFFFF8FA3));
          e.y = -99;
        case EntityKind.boostPowerUp:
          nitro = 100;
          bonusPickupsEaten++;
          events.add(GameEvent.boostUp);
          _burst(e.x, e.y, 9, const Color(0xFF80DEEA));
          e.y = -99;
        case EntityKind.cone:
          if (bumpSeconds <= 0) {
            bumpSeconds = 0.7;
            shake = math.max(shake, 0.5);
            events.add(GameEvent.bounce);
            _burst(e.x, e.y, 8, const Color(0xFFFF7043));
          }
          e.y = -99;
        case EntityKind.oilSlick:
          if (slipSeconds <= 0) {
            slipSeconds = 1.3;
            events.add(GameEvent.splash);
            _burst(e.x, e.y, 6, const Color(0xFF4A6572));
          }
        case EntityKind.trafficCar:
          if (invulnSeconds > 0 || crashCooldown > 0) continue;
          hearts--;
          events.add(GameEvent.boom);
          invulnSeconds = invulnerableSeconds;
          crashCooldown = invulnerableSeconds + 0.1;
          bumpSeconds = 1.0;
          shake = 1.2;
          flash = 0.8;
          _burst(lateral, 0, 12, const Color(0xFFCFD8DC));
          if (hearts <= 0) {
            crashedOut = true;
            events.add(GameEvent.oops);
          }
      }
    }
  }

  void _honkIfNear(Entity e) {
    if (_honkCooldown > 0) return;
    if (e.y < 3.2 && e.y > 1.0 && (e.x - lateral).abs() < 0.28) {
      _honkCooldown = 1.8 + _rng.nextDouble();
      events.add(GameEvent.honk);
    }
  }

  // ---------------------------------------------------------------- fx
  void _burst(double x, double y, int count, Color color) {
    for (var i = 0; i < count; i++) {
      particles.add(Particle(
        x + (_rng.nextDouble() - 0.5) * 0.1,
        y + (_rng.nextDouble() - 0.5) * 0.6,
        (_rng.nextDouble() - 0.5) * 2.2,
        (2 + _rng.nextDouble() * 3) * (1),
        0.45 + _rng.nextDouble() * 0.3,
        color,
      ));
    }
  }

  void _advanceParticles(double dt) {
    if (particles.isEmpty) return;
    for (final p in particles) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy -= 4 * dt;
    }
    particles.removeWhere((p) => p.life <= 0);
  }

  // -------------------------------------------------------------- spawning
  void _spawn(double dt) {
    _spawnTimer -= dt;
    if (_spawnTimer > 0) return;
    final densityRamp = (elapsedSeconds / 40).clamp(0.0, 1.0);
    final interval = level.spawnInterval /
        (0.85 + level.trafficDensity * 0.35 * densityRamp);
    _spawnTimer = interval * (0.75 + _rng.nextDouble() * 0.5);

    final roll = _rng.nextDouble();
    if (roll < 0.34) {
      final lane = _pickLane();
      for (var i = 0; i < 5; i++) {
        entities.add(Entity(
          kind: EntityKind.coin,
          x: lane,
          y: _aheadBase() + i * 2.2,
          phase: _rng.nextDouble() * math.pi * 2,
        ));
      }
    } else if (roll < 0.40 && progress > 0.15) {
      entities.add(_pickup(EntityKind.star, 6));
    } else if (roll < 0.46 && progress > 0.15) {
      entities.add(_pickup(EntityKind.boostPowerUp, 6));
    } else if (roll < 0.52 && progress > 0.2) {
      entities.add(_pickup(EntityKind.heart, 6));
    } else if (roll < 0.68) {
      final count = level.doubleTraffic && _rng.nextBool() ? 2 : 1;
      final used = <double>{};
      for (var i = 0; i < count; i++) {
        final lane = _pickLane(exclude: used);
        used.add(lane);
        entities.add(Entity(
          kind: EntityKind.trafficCar,
          x: lane,
          y: _aheadBase() + i * 9 + _rng.nextDouble() * 3,
          color: trafficLivery[_rng.nextInt(trafficLivery.length)],
          speedFactor: (0.40 + _rng.nextDouble() * 0.22).clamp(0.28, 0.62),
          phase: _rng.nextDouble() * math.pi * 2,
          variant: _rng.nextInt(4),
        ));
      }
    } else if (roll < 0.76) {
      final lane = _pickLane();
      entities.add(Entity(
          kind: EntityKind.cone, x: lane + _jitter(0.3), y: _aheadBase()));
      if (_rng.nextBool()) {
        entities.add(Entity(
            kind: EntityKind.cone,
            x: lane + _jitter(0.45),
            y: _aheadBase() + 6));
      }
    } else if (roll < 0.82 && level.index >= 1) {
      entities.add(_pickup(EntityKind.oilSlick, 2));
    }
  }

  Entity _pickup(EntityKind kind, double extra) => Entity(
        kind: kind,
        x: _pickLane(),
        y: _aheadBase() + extra,
        phase: _rng.nextDouble() * math.pi * 2,
      );

  double _aheadBase() => 22 + _rng.nextDouble() * 3;

  double _jitter(double amount) => (_rng.nextDouble() - 0.5) * amount;

  /// Picks a random lane; avoids lanes in [exclude] when possible.
  double _pickLane({Set<double>? exclude}) {
    const lanes = <double>[-0.66, -0.22, 0.22, 0.66];
    final pool = lanes.where((lane) {
      if (exclude == null) return true;
      return !exclude.any((other) => (other - lane).abs() < 0.2);
    }).toList();
    if (pool.isEmpty) return lanes[_rng.nextInt(lanes.length)];
    return pool[_rng.nextInt(pool.length)];
  }

  // ------------------------------------------------------------- results
  int get earnedStars {
    if (!finished) return 0;
    // Generous, kid-friendly star rubric: 1★ finish, +1★ few hits, +1★ stars.
    var stars = 1;
    if (hearts >= 2) stars++;
    if (hearts >= maxHearts || starsCollected >= 12) stars++;
    return stars.clamp(1, 3);
  }

  RunResult buildResult() => RunResult(
        levelIndex: finished ? level.index : -1,
        finished: finished,
        distanceTravelled: distance,
        coinsCollected: coinsCollected,
        starsCollected: starsCollected,
        heartsLeft: finished ? hearts : 0,
        elaspsed: Duration(seconds: elapsedSeconds.round()),
      );
}

/// Drains into SFX calls.
class GameEvent {
  const GameEvent._(this.reason);
  final String reason;

  static const win = GameEvent._('win');
  static const coin = GameEvent._('coin');
  static const star = GameEvent._('star');
  static const heart = GameEvent._('heart');
  static const boostUp = GameEvent._('boostUp');
  static const bounce = GameEvent._('bounce');
  static const splash = GameEvent._('splash');
  static const boom = GameEvent._('crash');
  static const oops = GameEvent._('gameover');
  static const honk = GameEvent._('honk');
  static const boostStart = GameEvent._('boostStart');
  static const boostEnd = GameEvent._('boostEnd');
  static const screech = GameEvent._('screech');
}

class Particle {
  Particle(this.x, this.y, this.vx, this.vy, this.life, this.color);
  double x, y, vx, vy, life;
  Color color;
}
