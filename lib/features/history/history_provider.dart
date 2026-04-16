import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wallpaper_image.dart';
import '../../providers.dart';

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<WallpaperImage>>(
  HistoryNotifier.new,
);

class HistoryNotifier extends AsyncNotifier<List<WallpaperImage>> {
  @override
  Future<List<WallpaperImage>> build() {
    return ref.read(cacheManagerProvider).getHistory();
  }

  Future<void> clear() async {
    await ref.read(cacheManagerProvider).clearCache();
    state = const AsyncValue.data([]);
  }
}
