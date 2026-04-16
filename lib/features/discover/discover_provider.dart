import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wallpaper_image.dart';
import '../../providers.dart';

final discoverProvider =
    AsyncNotifierProvider<DiscoverNotifier, List<WallpaperImage>>(
  DiscoverNotifier.new,
);

class DiscoverNotifier extends AsyncNotifier<List<WallpaperImage>> {
  int _page = 1;

  @override
  Future<List<WallpaperImage>> build() async {
    _page = 1;
    final activeId = ref.watch(selectedSourceProvider);
    final sources = ref.read(allSourcesProvider);
    final source = sources[activeId] ?? sources['aiwpme']!;
    return source.browse(page: _page);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    _page++;
    final activeId = ref.read(selectedSourceProvider);
    final sources = ref.read(allSourcesProvider);
    final source = sources[activeId] ?? sources['aiwpme']!;
    final more = await source.browse(page: _page);
    state = AsyncValue.data([...current, ...more]);
  }

  Future<void> search(String query) async {
    _page = 1;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final activeId = ref.read(selectedSourceProvider);
      final sources = ref.read(allSourcesProvider);
      final source = sources[activeId] ?? sources['aiwpme']!;
      return source.browse(query: query, page: 1);
    });
  }

  Future<void> setWallpaper(WallpaperImage image) async {
    final activeId = ref.read(selectedSourceProvider);
    final sources = ref.read(allSourcesProvider);
    final source = sources[activeId] ?? sources['aiwpme']!;
    await ref.read(wallpaperServiceProvider).setWallpaper(image, source);
  }

  Future<void> random() async {
    _page = 1;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final activeId = ref.read(selectedSourceProvider);
      final sources = ref.read(allSourcesProvider);
      final source = sources[activeId] ?? sources['aiwpme']!;
      final image = await source.getRandom();
      await ref.read(wallpaperServiceProvider).setWallpaper(image, source);
      return [image];
    });
  }
}
