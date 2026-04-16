import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_form_field.dart';
import 'schedule_provider.dart';

const _presetIntervals = [5, 10, 15, 30, 60, 120];

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _customMode = false;
  int _customInterval = 30;
  bool _setNowLoading = false;
  String? _setNowError;

  String _formatCountdown(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int _currentInterval(int stateInterval) {
    if (_customMode) return _customInterval;
    return stateInterval;
  }

  Future<void> _onToggle(bool enable, int interval) async {
    final notifier = ref.read(scheduleProvider.notifier);
    if (enable) {
      await notifier.enable(interval);
    } else {
      await notifier.disable();
    }
  }

  Future<void> _onIntervalChanged(int? value, bool isEnabled) async {
    setState(() {
      if (value == null) {
        _customMode = true;
      } else {
        _customMode = false;
        _customInterval = value;
      }
    });
    if (isEnabled) {
      final interval = value ?? _customInterval;
      final notifier = ref.read(scheduleProvider.notifier);
      await notifier.disable();
      await notifier.enable(interval);
    }
  }

  Future<void> _onSetNow() async {
    setState(() {
      _setNowLoading = true;
      _setNowError = null;
    });
    try {
      final settings = await ref.read(appSettingsProvider.future);
      final sources = ref.read(allSourcesProvider);
      final activeId = settings.activeSourceIds.firstOrNull ?? 'aiwpme';
      final source = sources[activeId] ?? sources['aiwpme']!;
      final image = await source.getRandom();
      await ref.read(wallpaperServiceProvider).setWallpaper(image, source);
      if (mounted) setState(() => _setNowLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _setNowLoading = false;
          _setNowError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider);

    return scheduleState.when(
      data: (state) {
        final displayedInterval = _currentInterval(state.intervalMinutes);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GlassCard(
                title: 'Automatic wallpaper rotation',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: state.isEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (v) => _onToggle(v, displayedInterval),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.isEnabled
                                ? 'Rotating every $displayedInterval minutes'
                                : 'Disabled',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<int?>(
                      value: _customMode
                          ? null
                          : (_presetIntervals.contains(state.intervalMinutes)
                              ? state.intervalMinutes
                              : null),
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary),
                      isExpanded: true,
                      items: [
                        ..._presetIntervals.map(
                          (m) => DropdownMenuItem<int?>(
                            value: m,
                            child: Text('$m minutes'),
                          ),
                        ),
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Custom...'),
                        ),
                      ],
                      onChanged: (v) => _onIntervalChanged(v, state.isEnabled),
                    ),
                    if (_customMode) ...[
                      const SizedBox(height: 12),
                      GlassFormField(
                        label: 'Custom interval (minutes)',
                        initialValue: _customInterval.toString(),
                        keyboardType: TextInputType.number,
                        onBlur: (text) async {
                          final parsed = int.tryParse(text);
                          if (parsed == null || parsed < 1) return;
                          setState(() => _customInterval = parsed);
                          if (state.isEnabled) {
                            final n = ref.read(scheduleProvider.notifier);
                            await n.disable();
                            await n.enable(parsed);
                          }
                        },
                      ),
                    ],
                    if (state.isEnabled) ...[
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, _) {
                          final countdownAsync =
                              ref.watch(scheduleCountdownProvider);
                          return countdownAsync.when(
                            data: (remaining) => Text(
                              'Next change in ${_formatCountdown(remaining)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _GlassCard(
                title: 'Manual',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_setNowLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        onPressed: _onSetNow,
                        child: const Text('Set Random Wallpaper Now'),
                      ),
                    if (_setNowError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _setNowError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
