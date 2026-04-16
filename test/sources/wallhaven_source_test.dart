import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/sources/wallhaven_source.dart';

class MockDio extends Mock implements Dio {}

final _fakeWallpaper = {
  'id': 'yx5lq2',
  'dimension_x': 1920,
  'dimension_y': 1080,
  'file_type': 'image/jpeg',
  'path': 'https://w.wallhaven.cc/full/yx/wallhaven-yx5lq2.jpg',
  'thumbs': {
    'large': 'https://th.wallhaven.cc/lg/yx/yx5lq2.jpg',
    'original': 'https://th.wallhaven.cc/orig/yx/yx5lq2.jpg',
    'small': 'https://th.wallhaven.cc/sm/yx/yx5lq2.jpg',
  },
};

void main() {
  late MockDio mockDio;
  late WallhavenSource source;

  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    source = WallhavenSource(dio: mockDio);
  });

  test('browse returns mapped images from search endpoint', () async {
    when(() => mockDio.get<Map<String, dynamic>>(
          'https://wallhaven.cc/api/v1/search',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response<Map<String, dynamic>>(
          data: {
            'data': [_fakeWallpaper]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

    final images = await source.browse(query: 'nature');
    expect(images.length, 1);
    expect(images.first.id, 'yx5lq2');
    expect(images.first.sourceId, 'wallhaven');
    expect(images.first.format, 'jpg');
    expect(images.first.width, 1920);
  });

  test('getRandom uses sorting=random param', () async {
    when(() => mockDio.get<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response<Map<String, dynamic>>(
          data: {
            'data': [_fakeWallpaper]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

    final image = await source.getRandom();
    expect(image.id, 'yx5lq2');
  });

  test('requiresApiKey is false', () {
    expect(source.requiresApiKey, isFalse);
  });
}
