import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
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

  @override
  void dispose() {
    _cacheController.dispose();
    super.dispose();
  }

  AppSettings _current() =>
      ref.read(settingsProvider).valueOrNull ?? const AppSettings();

  Future<void> _saveWith(AppSettings updated) async {
    await ref.read(settingsProvider.notifier).save(updated);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (_cacheController.text != settings.cacheSizeLimitMb.toString()) {
          _cacheController.text = settings.cacheSizeLimitMb.toString();
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader('API Keys'),
            GlassFormField(
              key: const Key('unsplash_key_field'),
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
              key: const Key('wallhaven_key_field'),
              label: 'Wallhaven API Key',
              initialValue: settings.wallhavenApiKey ?? '',
              obscureText: true,
              onBlur: (text) => _saveWith(
                _current().copyWith(
                    wallhavenApiKey: text.isEmpty ? null : text),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Cache'),
            GlassFormField(
              label: 'Cache size limit (MB)',
              initialValue: settings.cacheSizeLimitMb.toString(),
              keyboardType: TextInputType.number,
              controller: _cacheController,
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
