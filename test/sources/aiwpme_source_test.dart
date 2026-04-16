import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/sources/aiwpme_source.dart';

class MockDio extends Mock implements Dio {}

class _SeededRandom implements Random {
  _SeededRandom(this._value);
  final int _value;
  @override
  int nextInt(int max) => _value % max;
  @override
  bool nextBool() => _value.isOdd;
  @override
  double nextDouble() => 0.0;
}

final _fakeImageData = [
  {
    'id': 'ABC123.png',
    'path': 'https://drive.google.com/uc?export=view&id=xyz',
    'type': 'png',
    'thumbnailUrl': 'https://drive.google.com/thumbnail?id=xyz&sz=w2000',
  },
  {
    'id': 'DEF456.jpg',
    'path': 'https://drive.google.com/uc?export=view&id=abc',
    'type': 'jpg',
    'thumbnailUrl': 'https://drive.google.com/thumbnail?id=abc&sz=w2000',
  },
];

void main() {
  late MockDio mockDio;
  late AiwpmeSource source;

  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    source = AiwpmeSource(dio: mockDio);

    when(() => mockDio.get<List<dynamic>>(
          'https://aiwp.me/api/images-data.json',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).thenAnswer((_) async => Response<List<dynamic>>(
          data: _fakeImageData,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));
  });

  test('browse returns all images when no query', () async {
    final images = await source.browse();
    expect(images.length, 2);
    expect(images.first.id, 'ABC123.png');
    expect(images.first.sourceId, 'aiwpme');
    expect(images.first.format, 'png');
  });

  test('browse filters by query (case-insensitive)', () async {
    final images = await source.browse(query: 'abc');
    expect(images.length, 1);
    expect(images.first.id, 'ABC123.png');
  });

  test('browse caches the image list (only one HTTP call)', () async {
    await source.browse();
    await source.browse();
    verify(() => mockDio.get<List<dynamic>>(
          'https://aiwp.me/api/images-data.json',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        )).called(1);
  });

  test('getRandom picks an image from the catalog (no HTML endpoint call)', () async {
    final seeded = AiwpmeSource(dio: mockDio, random: _SeededRandom(1));
    final image = await seeded.getRandom();
    expect(image.id, 'DEF456.jpg');

    verifyNever(() => mockDio.get<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ));
  });

  test('id and displayName are correct', () {
    expect(source.id, 'aiwpme');
    expect(source.requiresApiKey, isFalse);
  });
}
