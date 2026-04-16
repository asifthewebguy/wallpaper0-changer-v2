import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../sources/wallpaper_source.dart';

final sourcesProvider =
    AsyncNotifierProvider<SourcesNotifier, List<WallpaperSource>>(
  SourcesNotifier.new,
);

class SourcesNotifier extends AsyncNotifier<List<WallpaperSource>> {
  @override
  Future<List<WallpaperSource>> build() async {
    final settings = await ref.watch(appSettingsProvider.future);
    final all = ref.read(allSourcesProvider);
    return settings.activeSourceIds
        .where(all.containsKey)
        .map((id) => all[id]!)
        .toList();
  }

  Future<void> setActiveIds(List<String> sourceIds) async {
    final settings = await ref.read(appSettingsProvider.future);
    await ref.read(configServiceProvider).save(
          settings.copyWith(activeSourceIds: sourceIds),
        );
    ref.invalidateSelf();
  }
}
