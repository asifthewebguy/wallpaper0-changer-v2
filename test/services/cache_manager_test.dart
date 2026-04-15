import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/models/cached_image.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/services/cache_manager.dart';
import 'package:wallpaper_changer/sources/wallpaper_source.dart';

class MockWallpaperSource extends Mock implements WallpaperSource {}

const _image = WallpaperImage(
  id: 'test-image.jpg',
  sourceId: 'aiwpme',
  thumbnailUrl: 'https://example.com/thumb.jpg',
  downloadUrl: 'https://example.com/full.jpg',
  width: 1920,
  height: 1080,
  format: 'jpg',
);

void main() {
  late Directory tmpDir;
  late CacheManager cache;
  late MockWallpaperSource mockSource;

  setUpAll(() {
    registerFallbackValue(_image);
  });

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('cache_test_');
    cache = CacheManager(getAppDir: () async => tmpDir);
    mockSource = MockWallpaperSource();
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  test('getOrDownload downloads and returns local path on cache miss', () async {
    final fakeBytes = Uint8List.fromList([1, 2, 3, 4]);
    when(() => mockSource.download(_image))
        .thenAnswer((_) async => fakeBytes);

    final path = await cache.getOrDownload(_image, mockSource);

    expect(path, contains('test-image.jpg'));
    expect(await File(path).exists(), isTrue);
    expect(await File(path).readAsBytes(), fakeBytes);
    verify(() => mockSource.download(_image)).called(1);
  });

  test('getOrDownload returns cached path on cache hit without re-downloading',
      () async {
    final fakeBytes = Uint8List.fromList([1, 2, 3, 4]);
    when(() => mockSource.download(_image))
        .thenAnswer((_) async => fakeBytes);

    final path1 = await cache.getOrDownload(_image, mockSource);
    final path2 = await cache.getOrDownload(_image, mockSource);

    expect(path1, path2);
    verify(() => mockSource.download(_image)).called(1); // only once
  });

  test('recordHistory then getHistory returns newest-first', () async {
    const image2 = WallpaperImage(
      id: 'second.jpg',
      sourceId: 'aiwpme',
      thumbnailUrl: 'https://example.com/t2.jpg',
      downloadUrl: 'https://example.com/f2.jpg',
      width: 1920,
      height: 1080,
      format: 'jpg',
    );
    await cache.recordHistory(_image);
    await cache.recordHistory(image2);
    final history = await cache.getHistory();
    expect(history.first.id, image2.id);
    expect(history.last.id, _image.id);
  });

  test('clearCache removes all files and metadata', () async {
    final fakeBytes = Uint8List.fromList([1, 2, 3]);
    when(() => mockSource.download(_image))
        .thenAnswer((_) async => fakeBytes);

    final path = await cache.getOrDownload(_image, mockSource);
    expect(await File(path).exists(), isTrue);

    await cache.clearCache();
    expect(await File(path).exists(), isFalse);
  });

  test('evictToLimit removes oldest entries when over limit', () async {
    // Write two fake cached entries manually
    final cacheDir = Directory('${tmpDir.path}/wallpaper_changer/cache');
    await cacheDir.create(recursive: true);

    final file1 = File('${cacheDir.path}/old.jpg');
    final file2 = File('${cacheDir.path}/new.jpg');
    await file1.writeAsBytes(Uint8List(600 * 1024)); // 600KB
    await file2.writeAsBytes(Uint8List(600 * 1024)); // 600KB

    final now = DateTime.now();
    await cache.writeMetaForTest([
      CachedImage(
        wallpaperImageId: 'old',
        localPath: file1.path,
        downloadedAt: now.subtract(const Duration(hours: 2)),
        fileSizeBytes: 600 * 1024,
      ),
      CachedImage(
        wallpaperImageId: 'new',
        localPath: file2.path,
        downloadedAt: now,
        fileSizeBytes: 600 * 1024,
      ),
    ]);

    // Evict to 700KB limit — total (1200KB) exceeds limit, oldest (600KB) evicted first,
    // leaving 600KB which fits under 700KB, so newest file is kept.
    await cache.evictToLimit(700 * 1024);

    expect(await file1.exists(), isFalse); // old evicted
    expect(await file2.exists(), isTrue);  // new kept
  });
}
