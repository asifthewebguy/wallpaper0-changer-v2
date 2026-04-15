import 'dart:typed_data';
import '../models/wallpaper_image.dart';

abstract interface class WallpaperSource {
  String get id;
  String get displayName;
  bool get requiresApiKey;

  Future<List<WallpaperImage>> browse({String? query, int page = 1});
  Future<WallpaperImage> getRandom();
  Future<Uint8List> download(
    WallpaperImage image, {
    void Function(int received, int total)? onProgress,
  });
}
