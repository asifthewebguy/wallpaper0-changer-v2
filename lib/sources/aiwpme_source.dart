import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/exceptions.dart';
import '../models/wallpaper_image.dart';
import 'wallpaper_source.dart';

class AiwpmeSource implements WallpaperSource {
  static const _base = 'https://aiwp.me';
  static const _pageSize = 40;

  final Dio _dio;
  final Random _random;
  List<WallpaperImage>? _cache;

  AiwpmeSource({Dio? dio, Random? random})
      : _dio = dio ?? Dio(),
        _random = random ?? Random();

  @override
  String get id => 'aiwpme';

  @override
  String get displayName => 'AI Wallpapers (aiwp.me)';

  @override
  bool get requiresApiKey => false;

  Future<List<WallpaperImage>> _fetchAll() async {
    if (_cache != null) return _cache!;
    final response = await _dio.get<List<dynamic>>(
      '$_base/api/images-data.json',
    );
    _cache = response.data!.map((e) {
      final m = e as Map<String, dynamic>;
      final type = (m['type'] as String).toLowerCase();
      return WallpaperImage(
        id: m['id'] as String,
        sourceId: id,
        thumbnailUrl: m['thumbnailUrl'] as String,
        downloadUrl: m['path'] as String,
        width: 0,
        height: 0,
        format: type == 'jpeg' ? 'jpg' : type,
      );
    }).toList();
    return _cache!;
  }

  @override
  Future<List<WallpaperImage>> browse({String? query, int page = 1}) async {
    var all = await _fetchAll();
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      all = all.where((img) => img.id.toLowerCase().contains(q)).toList();
    }
    final start = (page - 1) * _pageSize;
    if (start >= all.length) return [];
    return all.sublist(start, (start + _pageSize).clamp(0, all.length));
  }

  @override
  Future<WallpaperImage> getRandom() async {
    final all = await _fetchAll();
    if (all.isEmpty) throw const DownloadException('aiwp.me catalog is empty');
    return all[_random.nextInt(all.length)];
  }

  @override
  Future<Uint8List> download(
    WallpaperImage image, {
    void Function(int received, int total)? onProgress,
  }) async {
    final response = await _dio.get<List<int>>(
      image.downloadUrl,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onProgress,
    );
    return Uint8List.fromList(response.data!);
  }
}
