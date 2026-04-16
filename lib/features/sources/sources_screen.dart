import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../providers.dart';
import '../../sources/wallpaper_source.dart';
import '../../theme/app_colors.dart';
import 'sources_provider.dart';

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  IconData _iconFor(String sourceId) {
    switch (sourceId) {
      case 'aiwpme':
        return Icons.auto_awesome_outlined;
      case 'unsplash':
      case 'wallhaven':
        return Icons.cloud_outlined;
      case 'local':
        return Icons.folder_outlined;
      default:
        return Icons.image_outlined;
    }
  }

  String? _disabledReason(WallpaperSource source, AppSettings settings) {
    if (source.id == 'unsplash' &&
        (settings.unsplashApiKey == null ||
            settings.unsplashApiKey!.isEmpty)) {
      return 'API key required';
    }
    if (source.id == 'wallhaven' &&
        (settings.wallhavenApiKey == null ||
            settings.wallhavenApiKey!.isEmpty)) {
      return 'API key required';
    }
    if (source.id == 'local' &&
        (settings.localFolderPath == null ||
            settings.localFolderPath!.isEmpty)) {
      return 'Folder not set';
    }
    return null;
  }

  String _scrollTargetFor(String sourceId) {
    if (sourceId == 'unsplash') return 'unsplash';
    if (sourceId == 'wallhaven') return 'wallhaven';
    return 'local';
  }

  void _navigateToSettings(WidgetRef ref, String target) {
    ref.read(currentPageIndexProvider.notifier).state = 4;
    ref.read(settingsScrollTargetProvider.notifier).state = target;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesMap = ref.watch(allSourcesProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final sources = sourcesMap.values.toList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                'Active Sources',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...sources.map((source) {
              final disabledReason = _disabledReason(source, settings);
              final isActive = settings.activeSourceIds.contains(source.id);
              final canToggle = disabledReason == null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(_iconFor(source.id),
                          color: AppColors.textSecondary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.displayName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (disabledReason != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  disabledReason,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!canToggle)
                        TextButton(
                          onPressed: () => _navigateToSettings(
                              ref, _scrollTargetFor(source.id)),
                          child: const Text(
                            'Configure →',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      Switch(
                        value: isActive,
                        activeColor: AppColors.primary,
                        onChanged: !canToggle
                            ? null
                            : (v) async {
                                final current =
                                    List<String>.from(settings.activeSourceIds);
                                if (v) {
                                  if (!current.contains(source.id)) {
                                    current.add(source.id);
                                  }
                                } else {
                                  current.remove(source.id);
                                }
                                await ref
                                    .read(sourcesProvider.notifier)
                                    .setActiveIds(current);
                              },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}
