import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/features/history/history_provider.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/providers.dart';
import 'package:wallpaper_changer/services/cache_manager.dart';

void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('history_prov_test_');
  });
  tearDown(() async => tmpDir.delete(recursive: true));

  test('build returns history from CacheManager', () async {
    final cache = CacheManager(getAppDir: () async => tmpDir);
    const image = WallpaperImage(
      id: 'hist1',
      sourceId: 'aiwpme',
      thumbnailUrl: 'https://example.com/t.jpg',
      downloadUrl: 'https://example.com/f.jpg',
      width: 1920,
      height: 1080,
      format: 'jpg',
    );
    await cache.recordHistory(image);

    final container = ProviderContainer(overrides: [
      cacheManagerProvider.overrideWithValue(cache),
    ]);
    addTearDown(container.dispose);

    final history = await container.read(historyProvider.future);
    expect(history.length, 1);
    expect(history.first.id, 'hist1');
  });
}
