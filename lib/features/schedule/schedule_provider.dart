import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import 'schedule_state.dart';

final scheduleProvider =
    AsyncNotifierProvider<ScheduleNotifier, ScheduleState>(
  ScheduleNotifier.new,
);

/// Stream that ticks every second and yields remaining time until next fire.
final scheduleCountdownProvider = StreamProvider<Duration>((ref) async* {
  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
    final state = ref.read(scheduleProvider).valueOrNull;
    if (state == null || !state.isEnabled || state.nextFireAt == null) {
      yield Duration.zero;
    } else {
      final remaining = state.nextFireAt!.difference(DateTime.now());
      yield remaining.isNegative ? Duration.zero : remaining;
    }
  }
});

class ScheduleNotifier extends AsyncNotifier<ScheduleState> {
  @override
  Future<ScheduleState> build() async {
    final settings = await ref.watch(appSettingsProvider.future);
    return ScheduleState(
      isEnabled: false,
      intervalMinutes: settings.schedulerIntervalMinutes,
    );
  }

  Future<void> enable(int intervalMinutes) async {
    final scheduler = ref.read(schedulerServiceProvider);
    scheduler.start(
      interval: Duration(minutes: intervalMinutes),
      onTick: () async {
        try {
          final settings = await ref.read(appSettingsProvider.future);
          final sources = ref.read(allSourcesProvider);
          final activeId = settings.activeSourceIds.firstOrNull ?? 'aiwpme';
          final source = sources[activeId] ?? sources['aiwpme']!;
          final image = await source.getRandom();
          await ref.read(wallpaperServiceProvider).setWallpaper(image, source);
        } catch (_) {
          // Scheduler tick errors are silent — app continues running.
        }
      },
    );
    state = AsyncValue.data(ScheduleState(
      isEnabled: true,
      intervalMinutes: intervalMinutes,
      nextFireAt: scheduler.nextFireAt,
    ));
    final settings = await ref.read(appSettingsProvider.future);
    await ref.read(configServiceProvider).save(
          settings.copyWith(schedulerIntervalMinutes: intervalMinutes),
        );
  }

  Future<void> disable() async {
    ref.read(schedulerServiceProvider).stop();
    final current = state.valueOrNull;
    state = AsyncValue.data(ScheduleState(
      isEnabled: false,
      intervalMinutes: current?.intervalMinutes ?? 30,
    ));
  }
}
