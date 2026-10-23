import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_theme.dart';
import 'game/audio.dart';
import 'game/models.dart';
import 'game/race_screen.dart';
import 'game/save.dart';
import 'screens/garage_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/result_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure orientation and immersive mode safely
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } catch (e) {
    debugPrint('SystemChrome init skipped: $e');
  }

  // Load save data safely
  final save = await GameSave.load();
  AudioHub.instance.attachSave(save);

  // Initialize audio in the background — NEVER block runApp
  unawaited(AudioHub.instance.init());

  runApp(SpeedyStarsApp(save: save));
}

class SpeedyStarsApp extends StatelessWidget {
  const SpeedyStarsApp({required this.save, super.key});
  final GameSave save;

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/race':
        final args = settings.arguments! as Map<String, dynamic>;
        return _slide(RacePage(args: args), settings);
      case '/result':
        final result = settings.arguments! as RunResult;
        return _slide(ResultScreen(result: result, save: save), settings);
      default:
        return null;
    }
  }

  static PageRoute<void> _slide(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speedy Stars Racing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/home',
      onGenerateRoute: _onGenerateRoute,
      routes: {
        '/home': (context) => HomeScreen(save: save),
        '/levels': (context) => LevelSelectScreen(save: save),
        '/garage': (context) => GarageScreen(save: save),
      },
    );
  }
}

/// Wrapper so the race route has a named record of where it goes on exit.
class RacePage extends StatelessWidget {
  const RacePage({required this.args, super.key});
  final Map<String, dynamic> args;

  @override
  Widget build(BuildContext context) {
    final level = args['level'] as LevelSpec;
    final car = args['car'] as CarSpec;
    return RaceScreen(level: level, car: car);
  }
}

