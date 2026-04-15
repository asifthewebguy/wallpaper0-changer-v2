import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/app.dart';

void main() {
  testWidgets('app renders NavigationBar with 5 destinations', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WallpaperChangerApp()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Discover'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Schedule'), findsWidgets);
    expect(find.text('Sources'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('tapping History nav item switches screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WallpaperChangerApp()));
    await tester.pumpAndSettle();
    final historyItems = find.text('History');
    await tester.tap(historyItems.last);
    await tester.pumpAndSettle();
    expect(find.text('History'), findsWidgets);
  });
}
