import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/wallpaper_grid.dart';
import '../../widgets/wallpaper_preview_dialog.dart';
import 'history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final days = DateTime.now().difference(dt).inDays.abs();
    if (days == 0) return 'today';
    if (days == 1) return 'yesterday';
    return '$days days ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    return historyState.when(
      data: (images) => WallpaperGrid(
        images: images,
        emptyMessage: 'No wallpapers set yet',
        captionBuilder: (image) => _timeAgo(image.setAt),
        onTap: (image) => showDialog(
          context: context,
          builder: (_) => WallpaperPreviewDialog(image: image),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          e.toString(),
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
