import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/models/exceptions.dart';
import 'package:wallpaper_changer/sources/unsplash_source.dart';

class MockDio extends Mock implements Dio {}

final _fakePhoto = {
  'id': 'photo-abc',
  'width': 5000,
  'height': 3333,
  'urls': {
    'thumb': 'https://images.unsplash.com/photo-abc?w=200',
    'full': 'https://images.unsplash.com/photo-abc',
  },
};

void main() {
  late MockDio mockDio;
  late UnsplashSource source;

  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    source = UnsplashSource(apiKey: 'test-key', dio: mockDio);
  });

  test('browse with query hits /search/photos', () async {
    when(() => mockDio.get<Map<String, dynamic>>(
          'https://api.unsplash.com/search/photos',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response<Map<String, dynamic>>(
          data: {
            'results': [_fakePhoto]
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

    final images = await source.browse(query: 'nature');
    expect(images.length, 1);
    expect(images.first.id, 'photo-abc');
    expect(images.first.sourceId, 'unsplash');
    expect(images.first.width, 5000);
  });

  test('browse without query hits /photos', () async {
    when(() => mockDio.get<List<dynamic>>(
          'https://api.unsplash.com/photos',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response<List<dynamic>>(
          data: [_fakePhoto],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

    final images = await source.browse();
    expect(images.length, 1);
    expect(images.first.id, 'photo-abc');
  });

  test('throws MissingApiKeyException when no key set', () async {
    final noKey = UnsplashSource(apiKey: null, dio: mockDio);
    await expectLater(
      () => noKey.browse(),
      throwsA(isA<MissingApiKeyException>()),
    );
  });

  test('requiresApiKey is true', () {
    expect(source.requiresApiKey, isTrue);
  });
}
