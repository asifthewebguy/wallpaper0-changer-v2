import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/features/discover/discover_provider.dart';
import 'package:wallpaper_changer/features/discover/discover_screen.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/providers.dart';
import 'package:wallpaper_changer/sources/wallpaper_source.dart';

class MockWallpaperSource extends Mock implements WallpaperSource {}

// A simple fake notifier that starts with empty data
class FakeDiscoverNotifier extends DiscoverNotifier {
  final Future<List<WallpaperImage>> Function() buildFn;

  FakeDiscoverNotifier({required this.buildFn});

  @override
  Future<List<WallpaperImage>> build() => buildFn();

  @override
  Future<void> search(String query) async {}

  @override
  Future<void> loadMore() async {}
}

void main() {
  late MockWallpaperSource mockSource;

  setUp(() {
    mockSource = MockWallpaperSource();
    when(() => mockSource.id).thenReturn('aiwpme');
    when(() => mockSource.displayName).thenReturn('AI Wallpapers');
  });

  Widget buildWidget({Future<List<WallpaperImage>> Function()? buildFn}) {
    final notifier = FakeDiscoverNotifier(
      buildFn: buildFn ?? () async => [],
    );
    return ProviderScope(
      overrides: [
        discoverProvider.overrideWith(() => notifier),
        allSourcesProvider.overrideWithValue({'aiwpme': mockSource}),
        selectedSourceProvider.overrideWith((ref) => 'aiwpme'),
      ],
      child: const MaterialApp(home: Scaffold(body: DiscoverScreen())),
    );
  }

  testWidgets('shows source dropdown', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pump();
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  testWidgets('shows search text field', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('shows loading indicator while fetching', (tester) async {
    // Use a Completer that never completes so no pending timer is left behind.
    final completer = Completer<List<WallpaperImage>>();
    await tester.pumpWidget(buildWidget(buildFn: () => completer.future));
    await tester.pump(); // first frame — still loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Complete to avoid leaking the completer across tests.
    completer.complete([]);
  });
}
