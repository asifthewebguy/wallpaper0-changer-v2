import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/app.dart';

void main() {
  testWidgets('app renders NavigationBar with 5 destinations', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WallpaperChangerApp()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Discover Screen'), findsOneWidget); // body content
    expect(find.text('Discover'), findsWidgets);  // nav label
    expect(find.text('History'), findsWidgets);
    expect(find.text('Schedule'), findsWidgets);
    expect(find.text('Sources'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('tapping History nav item switches screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WallpaperChangerApp()));
    await tester.pumpAndSettle();
    // Initially on Discover
    expect(find.text('Discover Screen'), findsOneWidget);
    // Tap History nav destination
    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();
    // Now on History screen
    expect(find.text('History Screen'), findsOneWidget);
    expect(find.text('Discover Screen'), findsNothing);
  });
}
