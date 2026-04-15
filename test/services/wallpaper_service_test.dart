import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/models/exceptions.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/platform/app_notifier.dart';
import 'package:wallpaper_changer/platform/wallpaper_setter.dart';
import 'package:wallpaper_changer/services/cache_manager.dart';
import 'package:wallpaper_changer/services/wallpaper_service.dart';
import 'package:wallpaper_changer/sources/wallpaper_source.dart';

class MockCacheManager extends Mock implements CacheManager {}
class MockWallpaperSetter extends Mock implements WallpaperSetter {}
class MockAppNotifier extends Mock implements AppNotifier {}
class MockWallpaperSource extends Mock implements WallpaperSource {}

class _FakeWallpaperSource extends Fake implements WallpaperSource {}

const _image = WallpaperImage(
  id: 'photo.jpg',
  sourceId: 'aiwpme',
  thumbnailUrl: 'https://example.com/t.jpg',
  downloadUrl: 'https://example.com/f.jpg',
  width: 1920,
  height: 1080,
  format: 'jpg',
);

void main() {
  late MockCacheManager mockCache;
  late MockWallpaperSetter mockSetter;
  late MockAppNotifier mockNotifier;
  late MockWallpaperSource mockSource;
  late WallpaperService service;

  setUpAll(() {
    registerFallbackValue(_image);
    registerFallbackValue(const WallpaperImage(
      id: '', sourceId: '', thumbnailUrl: '',
      downloadUrl: '', width: 0, height: 0, format: '',
    ));
    registerFallbackValue(_FakeWallpaperSource());
  });

  setUp(() {
    mockCache = MockCacheManager();
    mockSetter = MockWallpaperSetter();
    mockNotifier = MockAppNotifier();
    mockSource = MockWallpaperSource();

    when(() => mockCache.getOrDownload(any(), any(), cacheSizeLimitMb: any(named: 'cacheSizeLimitMb')))
        .thenAnswer((_) async => '/tmp/photo.jpg');
    when(() => mockSetter.set(any())).thenAnswer((_) async {});
    when(() => mockCache.recordHistory(any())).thenAnswer((_) async {});
    when(() => mockNotifier.show(any())).thenAnswer((_) async {});

    service = WallpaperService(
      cacheManager: mockCache,
      wallpaperSetter: mockSetter,
      notifier: mockNotifier,
    );
  });

  test('setWallpaper calls download → set → recordHistory → notify in order',
      () async {
    await service.setWallpaper(_image, mockSource);

    verifyInOrder([
      () => mockCache.getOrDownload(any(), any(), cacheSizeLimitMb: any(named: 'cacheSizeLimitMb')),
      () => mockSetter.set('/tmp/photo.jpg'),
      () => mockCache.recordHistory(_image),
      () => mockNotifier.show('Wallpaper updated'),
    ]);
  });

  test('setWallpaper throws ValidationException for invalid image', () async {
    const bad = WallpaperImage(
      id: '',
      sourceId: 'aiwpme',
      thumbnailUrl: 'https://example.com/t.jpg',
      downloadUrl: 'https://example.com/f.jpg',
      width: 1920,
      height: 1080,
      format: 'jpg',
    );
    await expectLater(
      () => service.setWallpaper(bad, mockSource),
      throwsA(isA<ValidationException>()),
    );
    verifyNever(() => mockCache.getOrDownload(any(), any(), cacheSizeLimitMb: any(named: 'cacheSizeLimitMb')));
  });
}
