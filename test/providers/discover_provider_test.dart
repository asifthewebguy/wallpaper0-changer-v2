import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/features/discover/discover_provider.dart';
import 'package:wallpaper_changer/models/app_settings.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/providers.dart';
import 'package:wallpaper_changer/sources/wallpaper_source.dart';

class MockWallpaperSource extends Mock implements WallpaperSource {}

const _image = WallpaperImage(
  id: 'img1',
  sourceId: 'aiwpme',
  thumbnailUrl: 'https://example.com/t.jpg',
  downloadUrl: 'https://example.com/f.jpg',
  width: 1920,
  height: 1080,
  format: 'jpg',
);

void main() {
  late MockWallpaperSource mockSource;

  setUpAll(() {
    registerFallbackValue(_image);
  });

  setUp(() {
    mockSource = MockWallpaperSource();
    when(() => mockSource.browse(
          query: any(named: 'query'),
          page: any(named: 'page'),
        )).thenAnswer((_) async => [_image]);
    when(() => mockSource.id).thenReturn('aiwpme');
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        appSettingsProvider.overrideWith(
          (ref) async => const AppSettings(activeSourceIds: ['aiwpme']),
        ),
        allSourcesProvider.overrideWithValue({'aiwpme': mockSource}),
      ]);

  test('build loads images from active source', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final images = await container.read(discoverProvider.future);
    expect(images.length, 1);
    expect(images.first.id, 'img1');
  });

  test('search calls browse with query', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(discoverProvider.future);
    await container.read(discoverProvider.notifier).search('forest');
    verify(() => mockSource.browse(query: 'forest', page: any(named: 'page')))
        .called(1);
  });
}
