import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/models/exceptions.dart';
import 'package:wallpaper_changer/sources/local_folder_source.dart';

void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('local_folder_test_');
    // Create fake image files
    await File('${tmpDir.path}/photo.jpg').writeAsBytes([1, 2, 3]);
    await File('${tmpDir.path}/art.png').writeAsBytes([4, 5, 6]);
    await File('${tmpDir.path}/readme.txt').writeAsBytes([7, 8, 9]);
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  test('browse returns only supported image files', () async {
    final source = LocalFolderSource(folderPath: tmpDir.path);
    final images = await source.browse();
    expect(images.length, 2);
    expect(images.map((i) => i.format).toSet(), containsAll(['jpg', 'png']));
  });

  test('browse filters by query (case-insensitive filename match)', () async {
    final source = LocalFolderSource(folderPath: tmpDir.path);
    final images = await source.browse(query: 'photo');
    expect(images.length, 1);
    expect(images.first.format, 'jpg');
  });

  test('getRandom returns one image', () async {
    final source = LocalFolderSource(folderPath: tmpDir.path);
    final image = await source.getRandom();
    expect(['jpg', 'png'], contains(image.format));
  });

  test('download returns the file bytes', () async {
    final source = LocalFolderSource(folderPath: tmpDir.path);
    final images = await source.browse();
    final bytes = await source.download(images.first);
    expect(bytes.length, greaterThan(0));
  });

  test('browse throws ValidationException when folder not configured', () async {
    final source = LocalFolderSource(folderPath: null);
    await expectLater(
      () => source.browse(),
      throwsA(isA<ValidationException>()),
    );
  });

  test('sourceId and requiresApiKey are correct', () {
    final source = LocalFolderSource(folderPath: tmpDir.path);
    expect(source.id, 'local');
    expect(source.requiresApiKey, isFalse);
  });
}
