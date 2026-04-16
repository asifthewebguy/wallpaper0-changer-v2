import 'dart:io';
import 'dart:typed_data';
import '../models/exceptions.dart';
import '../models/wallpaper_image.dart';
import 'wallpaper_source.dart';

class LocalFolderSource implements WallpaperSource {
  static const _pageSize = 40;
  static const _supportedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  final String? folderPath;

  LocalFolderSource({this.folderPath});

  @override
  String get id => 'local';

  @override
  String get displayName => 'Local Folder';

  @override
  bool get requiresApiKey => false;

  void _assertFolder() {
    if (folderPath == null || folderPath!.isEmpty) {
      throw const ValidationException('Local folder path is not configured');
    }
  }

  Future<List<WallpaperImage>> _scanFolder() async {
    _assertFolder();
    final dir = Directory(folderPath!);
    if (!await dir.exists()) {
      throw ValidationException('Local folder not found: $folderPath');
    }

    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.path.split(Platform.pathSeparator).last;
      final dotIdx = name.lastIndexOf('.');
      if (dotIdx < 0) continue;
      final ext = name.substring(dotIdx).toLowerCase();
      if (_supportedExtensions.contains(ext)) files.add(entity);
    }

    return files.map((file) {
      final name = file.path.split(Platform.pathSeparator).last;
      final dotIdx = name.lastIndexOf('.');
      final ext = name.substring(dotIdx + 1).toLowerCase();
      final format = ext == 'jpeg' ? 'jpg' : ext;
      return WallpaperImage(
        id: 'local_$name',
        sourceId: id,
        thumbnailUrl: file.path,
        downloadUrl: file.path,
        width: 0,
        height: 0,
        format: format,
      );
    }).toList();
  }

  @override
  Future<List<WallpaperImage>> browse({String? query, int page = 1}) async {
    var files = await _scanFolder();
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      files = files.where((img) => img.id.toLowerCase().contains(q)).toList();
    }
    final start = (page - 1) * _pageSize;
    if (start >= files.length) return [];
    return files.sublist(start, (start + _pageSize).clamp(0, files.length));
  }

  @override
  Future<WallpaperImage> getRandom() async {
    final files = await _scanFolder();
    if (files.isEmpty) {
      throw const DownloadException('No images found in local folder');
    }
    files.shuffle();
    return files.first;
  }

  @override
  Future<Uint8List> download(
    WallpaperImage image, {
    void Function(int received, int total)? onProgress,
  }) async {
    final bytes = await File(image.downloadUrl).readAsBytes();
    onProgress?.call(bytes.length, bytes.length);
    return bytes;
  }
}
