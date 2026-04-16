import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wallpaper_image.dart';
import '../../providers.dart';

final discoverProvider =
    AsyncNotifierProvider<DiscoverNotifier, List<WallpaperImage>>(
  DiscoverNotifier.new,
);

class DiscoverNotifier extends AsyncNotifier<List<WallpaperImage>> {
  @override
  Future<List<WallpaperImage>> build() async {
    final settings = await ref.watch(appSettingsProvider.future);
    final sources = ref.read(allSourcesProvider);
    final activeId = settings.activeSourceIds.firstOrNull ?? 'aiwpme';
    final source = sources[activeId] ?? sources['aiwpme']!;
    return source.browse();
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final settings = await ref.read(appSettingsProvider.future);
      final sources = ref.read(allSourcesProvider);
      final activeId = settings.activeSourceIds.firstOrNull ?? 'aiwpme';
      final source = sources[activeId] ?? sources['aiwpme']!;
      return source.browse(query: query);
    });
  }

  Future<void> setWallpaper(WallpaperImage image) async {
    final settings = await ref.read(appSettingsProvider.future);
    final sources = ref.read(allSourcesProvider);
    final activeId = settings.activeSourceIds.firstOrNull ?? 'aiwpme';
    final source = sources[activeId] ?? sources['aiwpme']!;
    await ref.read(wallpaperServiceProvider).setWallpaper(image, source);
  }

  Future<void> random() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final settings = await ref.read(appSettingsProvider.future);
      final sources = ref.read(allSourcesProvider);
      final activeId = settings.activeSourceIds.firstOrNull ?? 'aiwpme';
      final source = sources[activeId] ?? sources['aiwpme']!;
      final image = await source.getRandom();
      await ref.read(wallpaperServiceProvider).setWallpaper(image, source);
      return [image];
    });
  }
}
