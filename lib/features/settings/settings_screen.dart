import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_form_field.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _cacheController = TextEditingController();
  final _localFolderController = TextEditingController();
  final _unsplashKey = GlobalKey();
  final _wallhavenKey = GlobalKey();
  final _localFolderKey = GlobalKey();

  @override
  void dispose() {
    _cacheController.dispose();
    _localFolderController.dispose();
    super.dispose();
  }

  AppSettings _current() =>
      ref.read(settingsProvider).valueOrNull ?? const AppSettings();

  Future<void> _saveWith(AppSettings updated) async {
    await ref.read(settingsProvider.notifier).save(updated);
  }

  Future<void> _pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    _localFolderController.text = path;
    await _saveWith(_current().copyWith(localFolderPath: path));
  }

  void _handleScrollTarget(String? target) {
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalKey? key;
      switch (target) {
        case 'unsplash':
          key = _unsplashKey;
          break;
        case 'wallhaven':
          key = _wallhavenKey;
          break;
        case 'local':
          key = _localFolderKey;
          break;
      }
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
        );
      }
      ref.read(settingsScrollTargetProvider.notifier).state = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    ref.listen<String?>(settingsScrollTargetProvider, (_, next) {
      _handleScrollTarget(next);
    });

    return settingsAsync.when(
      data: (settings) {
        if (_cacheController.text != settings.cacheSizeLimitMb.toString()) {
          _cacheController.text = settings.cacheSizeLimitMb.toString();
        }
        if (_localFolderController.text !=
            (settings.localFolderPath ?? '')) {
          _localFolderController.text = settings.localFolderPath ?? '';
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader('API Keys'),
            GlassFormField(
              key: _unsplashKey,
              label: 'Unsplash API Key',
              initialValue: settings.unsplashApiKey ?? '',
              obscureText: true,
              onBlur: (text) => _saveWith(
                _current().copyWith(
                    unsplashApiKey: text.isEmpty ? null : text),
              ),
            ),
            const SizedBox(height: 16),
            GlassFormField(
              key: _wallhavenKey,
              label: 'Wallhaven API Key',
              initialValue: settings.wallhavenApiKey ?? '',
              obscureText: true,
              onBlur: (text) => _saveWith(
                _current().copyWith(
                    wallhavenApiKey: text.isEmpty ? null : text),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Local Folder'),
            Row(
              key: _localFolderKey,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'Folder path',
                    controller: _localFolderController,
                    onBlur: (text) => _saveWith(
                      _current().copyWith(
                          localFolderPath: text.isEmpty ? null : text),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _pickFolder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  child: const Text('Browse...'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Cache'),
            GlassFormField(
              label: 'Cache size limit (MB)',
              controller: _cacheController,
              keyboardType: TextInputType.number,
              onBlur: (text) async {
                final parsed = int.tryParse(text);
                if (parsed == null || parsed < 50) {
                  _cacheController.text =
                      _current().cacheSizeLimitMb.toString();
                  return;
                }
                await _saveWith(
                    _current().copyWith(cacheSizeLimitMb: parsed));
              },
            ),
            if (Platform.isLinux) ...[
              const SizedBox(height: 24),
              const _SectionHeader('Linux'),
              GlassFormField(
                label: 'Custom wallpaper command (optional)',
                initialValue: settings.linuxWallpaperCommand ?? '',
                helperText: 'e.g., feh --bg-scale',
                onBlur: (text) => _saveWith(
                  _current().copyWith(
                      linuxWallpaperCommand: text.isEmpty ? null : text),
                ),
              ),
            ],
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
