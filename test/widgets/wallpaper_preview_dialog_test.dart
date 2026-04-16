import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/features/discover/discover_provider.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/widgets/wallpaper_preview_dialog.dart';

class MockDiscoverNotifier extends AsyncNotifier<List<WallpaperImage>>
    with Mock
    implements DiscoverNotifier {
  @override
  Future<List<WallpaperImage>> build() async => [];
}

WallpaperImage _image() => const WallpaperImage(
      id: 'img1',
      sourceId: 'aiwpme',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      downloadUrl: 'https://example.com/full.jpg',
      width: 1920,
      height: 1080,
      format: 'jpg',
    );

Widget _wrap(WallpaperImage image, MockDiscoverNotifier notifier) {
  return ProviderScope(
    overrides: [
      discoverProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => WallpaperPreviewDialog(image: image),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const WallpaperImage(
      id: 'fallback',
      sourceId: 'aiwpme',
      thumbnailUrl: 'https://example.com/t.jpg',
      downloadUrl: 'https://example.com/f.jpg',
      width: 1920,
      height: 1080,
      format: 'jpg',
    ));
  });

  group('WallpaperPreviewDialog', () {
    testWidgets('shows Set as Wallpaper button', (tester) async {
      final notifier = MockDiscoverNotifier();
      when(() => notifier.setWallpaper(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(_image(), notifier));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Set as Wallpaper'), findsOneWidget);
    });

    testWidgets('calls setWallpaper and closes on success', (tester) async {
      final notifier = MockDiscoverNotifier();
      when(() => notifier.setWallpaper(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(_image(), notifier));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set as Wallpaper'));
      await tester.pumpAndSettle();

      verify(() => notifier.setWallpaper(any())).called(1);
      expect(find.text('Set as Wallpaper'), findsNothing); // dialog closed
    });

    testWidgets('shows error text when setWallpaper throws', (tester) async {
      final notifier = MockDiscoverNotifier();
      when(() => notifier.setWallpaper(any()))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(_wrap(_image(), notifier));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set as Wallpaper'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Network error'), findsOneWidget);
      expect(find.text('Set as Wallpaper'), findsOneWidget); // button re-enabled
    });
  });
}
