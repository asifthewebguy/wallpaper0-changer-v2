import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/app.dart';
import 'package:wallpaper_changer/features/discover/discover_provider.dart';
import 'package:wallpaper_changer/features/history/history_provider.dart';
import 'package:wallpaper_changer/features/schedule/schedule_provider.dart';
import 'package:wallpaper_changer/features/schedule/schedule_state.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/providers.dart';
import 'package:wallpaper_changer/sources/wallpaper_source.dart';
import 'package:mocktail/mocktail.dart';

class MockWallpaperSource extends Mock implements WallpaperSource {}

class FakeDiscoverNotifier extends DiscoverNotifier {
  @override
  Future<List<WallpaperImage>> build() async => [];
  @override
  Future<void> search(String query) async {}
  @override
  Future<void> loadMore() async {}
}

class FakeHistoryNotifier extends HistoryNotifier {
  @override
  Future<List<WallpaperImage>> build() async => [];
}

class FakeScheduleNotifier extends ScheduleNotifier {
  @override
  Future<ScheduleState> build() async =>
      const ScheduleState(isEnabled: false, intervalMinutes: 30);
}

List<Override> _overrides() {
  final src = MockWallpaperSource();
  when(() => src.id).thenReturn('aiwpme');
  when(() => src.displayName).thenReturn('AI Wallpapers');
  return [
    discoverProvider.overrideWith(() => FakeDiscoverNotifier()),
    historyProvider.overrideWith(() => FakeHistoryNotifier()),
    scheduleProvider.overrideWith(() => FakeScheduleNotifier()),
    allSourcesProvider.overrideWithValue({'aiwpme': src}),
    selectedSourceProvider.overrideWith((ref) => 'aiwpme'),
  ];
}

void main() {
  testWidgets('app renders NavigationBar with 5 destinations', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(),
      child: const WallpaperChangerApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Discover'), findsWidgets);  // nav label
    expect(find.text('History'), findsWidgets);
    expect(find.text('Schedule'), findsWidgets);
    expect(find.text('Sources'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('tapping History nav item switches screen', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: _overrides(),
      child: const WallpaperChangerApp(),
    ));
    await tester.pumpAndSettle();
    // Tap History nav destination
    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();
    // Now on History screen — shows empty state
    expect(find.text('No wallpapers set yet'), findsOneWidget);
    expect(find.text('Discover'), findsWidgets); // nav label still present
  });

  testWidgets('writing to currentPageIndexProvider switches screen',
      (tester) async {
    final container = ProviderContainer(overrides: _overrides());
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const WallpaperChangerApp(),
    ));
    await tester.pumpAndSettle();
    container.read(currentPageIndexProvider.notifier).state = 1;
    await tester.pumpAndSettle();
    expect(find.text('No wallpapers set yet'), findsOneWidget);
  });
}
