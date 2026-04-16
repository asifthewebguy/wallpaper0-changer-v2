import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/wallpaper_grid.dart';
import '../../widgets/wallpaper_preview_dialog.dart';
import 'discover_provider.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(discoverProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(allSourcesProvider);
    final selectedSourceId = ref.watch(selectedSourceProvider);
    final discoverState = ref.watch(discoverProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              DropdownButton<String>(
                value: selectedSourceId,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                items: sources.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value.displayName),
                        ))
                    .toList(),
                onChanged: (id) {
                  if (id != null) {
                    ref.read(selectedSourceProvider.notifier).state = id;
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: discoverState.when(
            data: (images) => WallpaperGrid(
              images: images,
              onTap: (image) => showDialog(
                context: context,
                builder: (_) => WallpaperPreviewDialog(image: image),
              ),
              onLoadMore:
                  ref.read(discoverProvider.notifier).loadMore,
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
