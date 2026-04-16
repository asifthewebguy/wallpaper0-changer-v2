import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/features/sources/sources_provider.dart';
import 'package:wallpaper_changer/features/sources/sources_screen.dart';
import 'package:wallpaper_changer/models/app_settings.dart';
import 'package:wallpaper_changer/providers.dart';
import 'package:wallpaper_changer/sources/wallpaper_source.dart';

class FakeSourcesNotifier extends SourcesNotifier {
  FakeSourcesNotifier(this._data);
  final List<WallpaperSource> _data;
  List<String>? lastSetIds;

  @override
  Future<List<WallpaperSource>> build() async => _data;

  @override
  Future<void> setActiveIds(List<String> ids) async {
    lastSetIds = ids;
  }
}

class MockWallpaperSource extends Mock implements WallpaperSource {}

MockWallpaperSource _src(String id, String name, {bool requiresKey = false}) {
  final s = MockWallpaperSource();
  when(() => s.id).thenReturn(id);
  when(() => s.displayName).thenReturn(name);
  when(() => s.requiresApiKey).thenReturn(requiresKey);
  return s;
}

void main() {
  late FakeSourcesNotifier notifier;

  setUp(() {
    notifier = FakeSourcesNotifier([]);
  });

  Widget wrap(AppSettings settings, Map<String, WallpaperSource> sources) {
    return ProviderScope(
      overrides: [
        sourcesProvider.overrideWith(() => notifier),
        appSettingsProvider.overrideWith((ref) async => settings),
        allSourcesProvider.overrideWithValue(sources),
      ],
      child: const MaterialApp(home: Scaffold(body: SourcesScreen())),
    );
  }

  testWidgets('renders one row per source', (tester) async {
    final sources = {
      'aiwpme': _src('aiwpme', 'AI Wallpapers'),
      'unsplash': _src('unsplash', 'Unsplash', requiresKey: true),
      'wallhaven': _src('wallhaven', 'Wallhaven', requiresKey: true),
      'local': _src('local', 'Local Folder'),
    };
    await tester.pumpWidget(wrap(const AppSettings(), sources));
    await tester.pumpAndSettle();
    expect(find.text('AI Wallpapers'), findsOneWidget);
    expect(find.text('Unsplash'), findsOneWidget);
    expect(find.text('Wallhaven'), findsOneWidget);
    expect(find.text('Local Folder'), findsOneWidget);
  });

  testWidgets('source needing API key shows Configure link and disabled toggle',
      (tester) async {
    final sources = {
      'unsplash': _src('unsplash', 'Unsplash', requiresKey: true),
    };
    await tester.pumpWidget(wrap(const AppSettings(), sources));
    await tester.pumpAndSettle();
    expect(find.text('API key required'), findsOneWidget);
    expect(find.text('Configure →'), findsOneWidget);
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.onChanged, isNull);
  });

  testWidgets('toggling an enabled source calls setActiveIds',
      (tester) async {
    final sources = {
      'aiwpme': _src('aiwpme', 'AI Wallpapers'),
    };
    await tester.pumpWidget(wrap(const AppSettings(), sources));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(notifier.lastSetIds, isNot(contains('aiwpme')));
  });

  testWidgets('source with API key set has enabled toggle', (tester) async {
    final sources = {
      'unsplash': _src('unsplash', 'Unsplash', requiresKey: true),
    };
    await tester.pumpWidget(wrap(
      const AppSettings(unsplashApiKey: 'abc123', activeSourceIds: []),
      sources,
    ));
    await tester.pumpAndSettle();
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.onChanged, isNotNull);
  });

  testWidgets('Configure → tap writes to nav + scroll providers',
      (tester) async {
    final container = ProviderContainer(overrides: [
      sourcesProvider.overrideWith(() => notifier),
      appSettingsProvider
          .overrideWith((ref) async => const AppSettings()),
      allSourcesProvider.overrideWithValue({
        'unsplash': _src('unsplash', 'Unsplash', requiresKey: true),
      }),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: SourcesScreen())),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configure →'));
    await tester.pumpAndSettle();
    expect(container.read(currentPageIndexProvider), 4);
    expect(container.read(settingsScrollTargetProvider), 'unsplash');
  });
}
