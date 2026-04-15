import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/cached_image.dart';
import '../models/wallpaper_image.dart';
import '../sources/wallpaper_source.dart';

class CacheManager {
  final Future<Directory> Function() _getAppDir;

  CacheManager({Future<Directory> Function()? getAppDir})
      : _getAppDir = getAppDir ?? getApplicationSupportDirectory;

  Future<Directory> _cacheDir() async {
    final base = await _getAppDir();
    final dir = Directory('${base.path}/wallpaper_changer/cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _metaFile() async {
    final base = await _getAppDir();
    final dir = Directory('${base.path}/wallpaper_changer');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/cache.json');
  }

  Future<File> _historyFile() async {
    final base = await _getAppDir();
    final dir = Directory('${base.path}/wallpaper_changer');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/history.json');
  }

  Future<List<CachedImage>> _loadMeta() async {
    final file = await _metaFile();
    if (!await file.exists()) return [];
    try {
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      return list
          .map((e) => CachedImage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveMeta(List<CachedImage> entries) async {
    final file = await _metaFile();
    await file
        .writeAsString(jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  /// Exposed for tests only — writes metadata directly without downloading.
  Future<void> writeMetaForTest(List<CachedImage> entries) => _saveMeta(entries);

  Future<String> getOrDownload(
    WallpaperImage image,
    WallpaperSource source, {
    void Function(int received, int total)? onProgress,
    int cacheSizeLimitMb = 500,
  }) async {
    final meta = await _loadMeta();
    final existing = meta
        .where((e) => e.wallpaperImageId == image.id)
        .firstOrNull;
    if (existing != null && await File(existing.localPath).exists()) {
      return existing.localPath;
    }

    final bytes = await source.download(image, onProgress: onProgress);
    final dir = await _cacheDir();
    final localPath = '${dir.path}/${image.id}.${image.format}';
    await File(localPath).writeAsBytes(bytes);

    final entry = CachedImage(
      wallpaperImageId: image.id,
      localPath: localPath,
      downloadedAt: DateTime.now(),
      fileSizeBytes: bytes.length,
    );
    final updated = [
      ...meta.where((e) => e.wallpaperImageId != image.id),
      entry,
    ];
    await _saveMeta(updated);
    await evictToLimit(cacheSizeLimitMb * 1024 * 1024);
    return localPath;
  }

  Future<void> recordHistory(WallpaperImage image) async {
    final file = await _historyFile();
    List<WallpaperImage> history = [];
    if (await file.exists()) {
      try {
        final list = jsonDecode(await file.readAsString()) as List<dynamic>;
        history = list
            .map((e) => WallpaperImage.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    history.insert(0, image);
    if (history.length > 500) history = history.take(500).toList();
    await file
        .writeAsString(jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  Future<List<WallpaperImage>> getHistory() async {
    final file = await _historyFile();
    if (!await file.exists()) return [];
    try {
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      return list
          .map((e) => WallpaperImage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> evictToLimit(int limitBytes) async {
    var meta = await _loadMeta();
    var total = meta.fold<int>(0, (sum, e) => sum + e.fileSizeBytes);
    if (total <= limitBytes) return;

    meta.sort((a, b) => a.downloadedAt.compareTo(b.downloadedAt));
    while (total > limitBytes && meta.isNotEmpty) {
      final oldest = meta.removeAt(0);
      final f = File(oldest.localPath);
      if (await f.exists()) await f.delete();
      total -= oldest.fileSizeBytes;
    }
    await _saveMeta(meta);
  }

  Future<void> clearCache() async {
    final meta = await _loadMeta();
    for (final entry in meta) {
      final f = File(entry.localPath);
      if (await f.exists()) await f.delete();
    }
    await _saveMeta([]);
  }
}
