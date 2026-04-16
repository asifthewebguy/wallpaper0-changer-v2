import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/exceptions.dart';
import '../models/wallpaper_image.dart';
import 'wallpaper_source.dart';

class WallhavenSource implements WallpaperSource {
  static const _base = 'https://wallhaven.cc/api/v1';

  final String? _apiKey;
  final Dio _dio;

  WallhavenSource({String? apiKey, Dio? dio})
      : _apiKey = apiKey,
        _dio = dio ?? Dio();

  @override
  String get id => 'wallhaven';

  @override
  String get displayName => 'Wallhaven';

  @override
  bool get requiresApiKey => false;

  Options? get _auth {
    if (_apiKey == null || _apiKey!.isEmpty) return null;
    return Options(headers: {'X-API-Key': _apiKey});
  }

  WallpaperImage _fromJson(Map<String, dynamic> json) {
    final thumbs = json['thumbs'] as Map<String, dynamic>;
    final fileType = (json['file_type'] as String?) ?? 'image/jpeg';
    final ext = fileType.split('/').last;
    final format = ext == 'jpeg' ? 'jpg' : ext;
    return WallpaperImage(
      id: json['id'] as String,
      sourceId: id,
      thumbnailUrl: thumbs['large'] as String,
      downloadUrl: json['path'] as String,
      width: (json['dimension_x'] as int?) ?? 0,
      height: (json['dimension_y'] as int?) ?? 0,
      format: format,
    );
  }

  @override
  Future<List<WallpaperImage>> browse({String? query, int page = 1}) async {
    final params = <String, dynamic>{
      'purity': '100',
      'atleast': '1920x1080',
      'page': page,
    };
    if (query != null && query.isNotEmpty) params['q'] = query;

    final r = await _dio.get<Map<String, dynamic>>(
      '$_base/search',
      queryParameters: params,
      options: _auth,
    );
    return (r.data!['data'] as List<dynamic>)
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WallpaperImage> getRandom() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '$_base/search',
      queryParameters: {'sorting': 'random', 'purity': '100'},
      options: _auth,
    );
    final data = r.data!['data'] as List<dynamic>;
    if (data.isEmpty) {
      throw const DownloadException('No wallpapers returned by Wallhaven');
    }
    return _fromJson(data.first as Map<String, dynamic>);
  }

  @override
  Future<Uint8List> download(
    WallpaperImage image, {
    void Function(int received, int total)? onProgress,
  }) async {
    final headers = (_apiKey != null && _apiKey!.isNotEmpty)
        ? <String, dynamic>{'X-API-Key': _apiKey}
        : null;
    final r = await _dio.get<List<int>>(
      image.downloadUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: headers,
      ),
      onReceiveProgress: onProgress,
    );
    return Uint8List.fromList(r.data!);
  }
}
