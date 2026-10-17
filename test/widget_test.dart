import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speedy_stars/game/save.dart';
import 'package:speedy_stars/main.dart';

void main() {
  testWidgets('App boots and shows the home screen', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final save = await GameSave.load();
    // pump() rather than pumpAndSettle: the garage previews bounce in a
    // never-ending loop on purpose (it's a kids' game).
    await tester.pumpWidget(SpeedyStarsApp(save: save));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('RACES'), findsOneWidget);
    expect(find.text('GARAGE'), findsOneWidget);
    expect(find.text('FREE DRIVE'), findsOneWidget);
  });
}
