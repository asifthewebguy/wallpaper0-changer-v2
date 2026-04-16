import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/widgets/wallpaper_card.dart';

WallpaperImage _image() => const WallpaperImage(
      id: 'img1',
      sourceId: 'aiwpme',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      downloadUrl: 'https://example.com/full.jpg',
      width: 1920,
      height: 1080,
      format: 'jpg',
    );

void main() {
  group('WallpaperCard', () {
    testWidgets('renders without caption', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: WallpaperCard(image: _image(), onTap: () {}),
            ),
          ),
        ),
      );
      expect(find.byType(WallpaperCard), findsOneWidget);
    });

    testWidgets('shows caption when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 160,
              child: WallpaperCard(
                image: _image(),
                onTap: () {},
                caption: '2 days ago',
              ),
            ),
          ),
        ),
      );
      expect(find.text('2 days ago'), findsOneWidget);
    });

    testWidgets('does not show caption when null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: WallpaperCard(image: _image(), onTap: () {}),
            ),
          ),
        ),
      );
      // No caption should appear when caption is null
      final textWidgets = find.descendant(
        of: find.byType(WallpaperCard),
        matching: find.byType(Text),
      );
      expect(textWidgets, findsNothing);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 150,
              child: WallpaperCard(
                image: _image(),
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(WallpaperCard));
      expect(tapped, isTrue);
    });
  });
}
