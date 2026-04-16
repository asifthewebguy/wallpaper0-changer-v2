import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/discover/discover_provider.dart';
import '../models/wallpaper_image.dart';
import '../theme/app_colors.dart';

class WallpaperPreviewDialog extends ConsumerStatefulWidget {
  const WallpaperPreviewDialog({super.key, required this.image});

  final WallpaperImage image;

  @override
  ConsumerState<WallpaperPreviewDialog> createState() =>
      _WallpaperPreviewDialogState();
}

class _WallpaperPreviewDialogState
    extends ConsumerState<WallpaperPreviewDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _setWallpaper() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(discoverProvider.notifier).setWallpaper(widget.image);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.image.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.image.id,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.image.sourceId,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 12),
                ),
              ),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _setWallpaper,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Set as Wallpaper'),
              ),
          ],
        ),
      ),
    );
  }
}

