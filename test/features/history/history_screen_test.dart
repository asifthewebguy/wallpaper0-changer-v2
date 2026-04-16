import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/features/history/history_provider.dart';
import 'package:wallpaper_changer/features/history/history_screen.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/widgets/wallpaper_card.dart';

class FakeHistoryNotifier extends HistoryNotifier {
  final List<WallpaperImage> _data;
  FakeHistoryNotifier(this._data);

  @override
  Future<List<WallpaperImage>> build() async => _data;
}

WallpaperImage _img(String id, {DateTime? setAt}) => WallpaperImage(
      id: id,
      sourceId: 'aiwpme',
      thumbnailUrl: 'https://example.com/$id.jpg',
      downloadUrl: 'https://example.com/${id}f.jpg',
      width: 1920,
      height: 1080,
      format: 'jpg',
      setAt: setAt,
    );

void main() {
  group('HistoryScreen', () {
    testWidgets('shows empty message when history is empty', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          historyProvider.overrideWith(() => FakeHistoryNotifier([])),
        ],
        child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
      ));
      await tester.pump();

      expect(find.text('No wallpapers set yet'), findsOneWidget);
      expect(find.byType(WallpaperCard), findsNothing);
    });

    testWidgets('renders WallpaperCards for each history entry', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          historyProvider.overrideWith(
              () => FakeHistoryNotifier([_img('a'), _img('b')])),
        ],
        child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
      ));
      await tester.pump();

      expect(find.byType(WallpaperCard), findsNWidgets(2));
    });

    testWidgets('shows timestamp caption for images with setAt', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          historyProvider.overrideWith(
              () => FakeHistoryNotifier([_img('a', setAt: yesterday)])),
        ],
        child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
      ));
      await tester.pump();

      expect(find.text('yesterday'), findsOneWidget);
    });
  });
}
