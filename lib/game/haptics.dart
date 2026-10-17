import 'package:flutter/services.dart';

import 'save.dart';

/// Central haptics gate — every buzz in the game goes through [Buzz] so
/// the "Vibration feedback" parent setting is honored everywhere.
///
/// Note: web and desktop browsers cannot physically vibrate; haptics are
/// real only on Android (and iOS) device builds.
abstract final class Buzz {
  static GameSave? _save;

  /// Call once after the save game loads (see main.dart).
  static void attach(GameSave save) => _save = save;

  static void selection() {
    if (_save?.hapticsOn ?? true) HapticFeedback.selectionClick();
  }

  static void light() {
    if (_save?.hapticsOn ?? true) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_save?.hapticsOn ?? true) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_save?.hapticsOn ?? true) HapticFeedback.heavyImpact();
  }
}
