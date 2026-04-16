import 'package:flutter/material.dart';
import '../models/wallpaper_image.dart';
import '../theme/app_colors.dart';
import 'wallpaper_card.dart';

class WallpaperGrid extends StatefulWidget {
  const WallpaperGrid({
    super.key,
    required this.images,
    required this.onTap,
    this.captionBuilder,
    this.onLoadMore,
    this.emptyMessage = 'No wallpapers found',
  });

  final List<WallpaperImage> images;
  final void Function(WallpaperImage) onTap;
  final String? Function(WallpaperImage)? captionBuilder;
  final Future<void> Function()? onLoadMore;
  final String emptyMessage;

  @override
  State<WallpaperGrid> createState() => _WallpaperGridState();
}

class _WallpaperGridState extends State<WallpaperGrid> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    if (widget.onLoadMore != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onScroll() async {
    if (_loadingMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      setState(() => _loadingMore = true);
      await widget.onLoadMore!();
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Center(
        child: Text(
          widget.emptyMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 16 / 9,
            ),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final image = widget.images[index];
              return WallpaperCard(
                image: image,
                caption: widget.captionBuilder?.call(image),
                onTap: () => widget.onTap(image),
              );
            },
          ),
        ),
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
