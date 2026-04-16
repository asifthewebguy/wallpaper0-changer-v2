import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/widgets/wallpaper_card.dart';
import 'package:wallpaper_changer/widgets/wallpaper_grid.dart';

WallpaperImage _img(String id) => WallpaperImage(
      id: id,
      sourceId: 'aiwpme',
      thumbnailUrl: 'https://example.com/$id.jpg',
      downloadUrl: 'https://example.com/${id}f.jpg',
      width: 1920,
      height: 1080,
      format: 'jpg',
    );

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('WallpaperGrid', () {
    testWidgets('renders one WallpaperCard per image', (tester) async {
      final images = [_img('a'), _img('b'), _img('c')];
      await tester.pumpWidget(_wrap(WallpaperGrid(
        images: images,
        onTap: (_) {},
      )));
      expect(find.byType(WallpaperCard), findsNWidgets(3));
    });

    testWidgets('shows empty message when list is empty', (tester) async {
      await tester.pumpWidget(_wrap(WallpaperGrid(
        images: const [],
        onTap: (_) {},
        emptyMessage: 'Nothing here',
      )));
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byType(WallpaperCard), findsNothing);
    });

    testWidgets('fires onTap with correct image', (tester) async {
      final images = [_img('x'), _img('y')];
      WallpaperImage? tappedImage;
      await tester.pumpWidget(_wrap(WallpaperGrid(
        images: images,
        onTap: (img) => tappedImage = img,
      )));
      await tester.tap(find.byType(WallpaperCard).first);
      expect(tappedImage?.id, 'x');
    });

    testWidgets('passes caption from captionBuilder to WallpaperCard',
        (tester) async {
      final images = [_img('a')];
      await tester.pumpWidget(_wrap(WallpaperGrid(
        images: images,
        onTap: (_) {},
        captionBuilder: (_) => 'yesterday',
      )));
      expect(find.text('yesterday'), findsOneWidget);
    });
  });
}
