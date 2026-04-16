import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';

void main() {
  const image = WallpaperImage(
    id: 'test.jpg',
    sourceId: 'aiwpme',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    downloadUrl: 'https://example.com/full.jpg',
    width: 1920,
    height: 1080,
    format: 'jpg',
  );

  test('fromJson round-trips toJson', () {
    final json = image.toJson();
    final restored = WallpaperImage.fromJson(json);
    expect(restored.id, image.id);
    expect(restored.sourceId, image.sourceId);
    expect(restored.thumbnailUrl, image.thumbnailUrl);
    expect(restored.downloadUrl, image.downloadUrl);
    expect(restored.width, image.width);
    expect(restored.height, image.height);
    expect(restored.format, image.format);
  });

  test('copyWith replaces specified fields', () {
    final copy = image.copyWith(sourceId: 'unsplash', width: 2560);
    expect(copy.sourceId, 'unsplash');
    expect(copy.width, 2560);
    expect(copy.id, image.id);
  });

  group('WallpaperImage.setAt', () {
    test('setAt round-trips through JSON', () {
      final dt = DateTime.utc(2026, 4, 16, 12, 0, 0);
      final image = WallpaperImage(
        id: 'img1',
        sourceId: 'aiwpme',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        downloadUrl: 'https://example.com/full.jpg',
        width: 1920,
        height: 1080,
        format: 'jpg',
        setAt: dt,
      );
      final restored = WallpaperImage.fromJson(image.toJson());
      expect(restored.setAt, dt);
    });

    test('setAt is null when absent from JSON', () {
      final image = WallpaperImage.fromJson({
        'id': 'img1',
        'sourceId': 'aiwpme',
        'thumbnailUrl': 'https://example.com/thumb.jpg',
        'downloadUrl': 'https://example.com/full.jpg',
        'width': 1920,
        'height': 1080,
        'format': 'jpg',
      });
      expect(image.setAt, isNull);
    });

    test('copyWith preserves setAt when not overridden', () {
      final dt = DateTime.utc(2026, 4, 16, 12, 0, 0);
      final image = WallpaperImage(
        id: 'img1',
        sourceId: 'aiwpme',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        downloadUrl: 'https://example.com/full.jpg',
        width: 1920,
        height: 1080,
        format: 'jpg',
        setAt: dt,
      );
      expect(image.copyWith(id: 'img2').setAt, dt);
    });
  });
}
