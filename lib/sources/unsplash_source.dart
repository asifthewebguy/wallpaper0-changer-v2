import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/exceptions.dart';
import '../models/wallpaper_image.dart';
import 'wallpaper_source.dart';

class UnsplashSource implements WallpaperSource {
  static const _base = 'https://api.unsplash.com';
  static const _pageSize = 40;

  final String? _apiKey;
  final Dio _dio;

  UnsplashSource({required String? apiKey, Dio? dio})
      : _apiKey = apiKey,
        _dio = dio ?? Dio();

  @override
  String get id => 'unsplash';

  @override
  String get displayName => 'Unsplash';

  @override
  bool get requiresApiKey => true;

  void _assertKey() {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw const MissingApiKeyException('Unsplash');
    }
  }

  Options get _auth =>
      Options(headers: {'Authorization': 'Client-ID $_apiKey'});

  WallpaperImage _fromJson(Map<String, dynamic> json) {
    final urls = json['urls'] as Map<String, dynamic>;
    return WallpaperImage(
      id: json['id'] as String,
      sourceId: id,
      thumbnailUrl: urls['thumb'] as String,
      downloadUrl: urls['full'] as String,
      width: (json['width'] as int?) ?? 0,
      height: (json['height'] as int?) ?? 0,
      format: 'jpg',
    );
  }

  @override
  Future<List<WallpaperImage>> browse({String? query, int page = 1}) async {
    _assertKey();
    if (query != null && query.isNotEmpty) {
      final r = await _dio.get<Map<String, dynamic>>(
        '$_base/search/photos',
        queryParameters: {'query': query, 'page': page, 'per_page': _pageSize},
        options: _auth,
      );
      return (r.data!['results'] as List<dynamic>)
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final r = await _dio.get<List<dynamic>>(
        '$_base/photos',
        queryParameters: {'page': page, 'per_page': _pageSize},
        options: _auth,
      );
      return r.data!
          .map((e) => _fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  @override
  Future<WallpaperImage> getRandom() async {
    _assertKey();
    final r = await _dio.get<Map<String, dynamic>>(
      '$_base/photos/random',
      options: _auth,
    );
    return _fromJson(r.data!);
  }

  @override
  Future<Uint8List> download(
    WallpaperImage image, {
    void Function(int received, int total)? onProgress,
  }) async {
    final r = await _dio.get<List<int>>(
      image.downloadUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Authorization': 'Client-ID $_apiKey'},
      ),
      onReceiveProgress: onProgress,
    );
    return Uint8List.fromList(r.data!);
  }
}
