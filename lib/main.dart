import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // A kids' game ships portrait, distraction-free, no network.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final save = await GameSave.load();
  AudioHub.instance.attachSave(save);
  await AudioHub.instance.init();

  runApp(SpeedyStarsApp(save: save));
}

class SpeedyStarsApp extends StatelessWidget {
  const SpeedyStarsApp({required this.save, super.key});
  final GameSave save;

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/race':
        final args = settings.arguments! as Map<String, dynamic>;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => RacePage(args: args),
        );
      case '/result':
        final result = settings.arguments! as RunResult;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ResultScreen(result: result, save: save),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speedy Stars Racing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFFB9E4FF),
      ),
      initialRoute: '/home',
      onGenerateRoute: _onGenerateRoute,
      routes: {
        '/home': (context) => HomeScreen(save: save),
        '/levels': (context) => LevelSelectScreen(save: save),
        '/garage': (context) => GarageScreen(
              save: save,
              initialTab: ModalRoute.of(context)?.settings.arguments is String
                  ? ModalRoute.of(context)?.settings.arguments as String
                  : 'cars',
            ),
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
    final bodyId = args['body'] as String?;
    final mods = (args['mods'] as List?)?.cast<String>() ?? const <String>[];
    return RaceScreen(
      level: level,
      car: car,
      bodyStyle:
          bodyId == null ? BodyStyle.classic : BodyStyle.byId(bodyId),
      mods: mods,
      cockpit: args['cockpit'] as bool? ?? true,
    );
  }
}
