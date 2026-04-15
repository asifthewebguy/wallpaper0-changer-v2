import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/models/exceptions.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/services/validation_service.dart';

const _valid = WallpaperImage(
  id: 'abc',
  sourceId: 'aiwpme',
  thumbnailUrl: 'https://example.com/thumb.jpg',
  downloadUrl: 'https://example.com/full.jpg',
  width: 1920,
  height: 1080,
  format: 'jpg',
);

void main() {
  group('validateImage', () {
    test('passes for a valid remote image', () {
      expect(() => ValidationService.validateImage(_valid), returnsNormally);
    });

    test('throws ValidationException when id is empty', () {
      expect(
        () => ValidationService.validateImage(_valid.copyWith(id: '')),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws ValidationException when thumbnailUrl is not https', () {
      expect(
        () => ValidationService.validateImage(
          _valid.copyWith(thumbnailUrl: 'http://example.com/t.jpg'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('passes for a local-source image (file path download URL)', () {
      const local = WallpaperImage(
        id: 'local_photo.jpg',
        sourceId: 'local',
        thumbnailUrl: '/home/user/wallpapers/photo.jpg',
        downloadUrl: '/home/user/wallpapers/photo.jpg',
        width: 0,
        height: 0,
        format: 'jpg',
      );
      expect(() => ValidationService.validateImage(local), returnsNormally);
    });

    test('throws for local-source image with traversal in thumbnailUrl', () {
      const bad = WallpaperImage(
        id: 'local_x.jpg',
        sourceId: 'local',
        thumbnailUrl: '/home/user/../etc/shadow',
        downloadUrl: '/home/user/wallpapers/photo.jpg',
        width: 0,
        height: 0,
        format: 'jpg',
      );
      expect(
        () => ValidationService.validateImage(bad),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('validateLocalPath', () {
    test('passes for absolute unix path', () {
      expect(
        () => ValidationService.validateLocalPath('/home/user/photo.jpg'),
        returnsNormally,
      );
    });

    test('passes for absolute windows path', () {
      expect(
        () => ValidationService.validateLocalPath(r'C:\Users\user\photo.jpg'),
        returnsNormally,
      );
    });

    test('throws for path with traversal', () {
      expect(
        () => ValidationService.validateLocalPath('/home/user/../etc/passwd'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws for relative path', () {
      expect(
        () => ValidationService.validateLocalPath('relative/path.jpg'),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
