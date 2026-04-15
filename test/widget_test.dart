import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/app.dart';

void main() {
  testWidgets('app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WallpaperChangerApp()));
    await tester.pumpAndSettle();
    expect(find.text('Discover'), findsWidgets);
  });
}
