import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/services/scheduler_service.dart';

void main() {
  late SchedulerService scheduler;

  setUp(() => scheduler = SchedulerService());
  tearDown(() => scheduler.stop());

  test('isRunning is false before start', () {
    expect(scheduler.isRunning, isFalse);
  });

  test('isRunning is true after start', () {
    scheduler.start(
      interval: const Duration(hours: 1),
      onTick: () async {},
    );
    expect(scheduler.isRunning, isTrue);
  });

  test('isRunning is false after stop', () {
    scheduler.start(
      interval: const Duration(hours: 1),
      onTick: () async {},
    );
    scheduler.stop();
    expect(scheduler.isRunning, isFalse);
  });

  test('nextFireAt is null when not running', () {
    expect(scheduler.nextFireAt, isNull);
  });

  test('nextFireAt is in the future when running', () {
    scheduler.start(
      interval: const Duration(hours: 1),
      onTick: () async {},
    );
    expect(scheduler.nextFireAt, isNotNull);
    expect(scheduler.nextFireAt!.isAfter(DateTime.now()), isTrue);
  });

  test('onTick is called when timer fires', () async {
    int ticks = 0;
    scheduler.start(
      interval: const Duration(milliseconds: 25),
      onTick: () async { ticks++; },
    );
    await Future.delayed(const Duration(milliseconds: 150));
    expect(ticks, greaterThanOrEqualTo(4));
  });

  test('reset restarts with new interval', () {
    scheduler.start(
      interval: const Duration(hours: 1),
      onTick: () async {},
    );
    scheduler.reset(const Duration(hours: 2), onTick: () async {});
    expect(scheduler.isRunning, isTrue);
    expect(
      scheduler.nextFireAt!.difference(DateTime.now()).inMinutes,
      greaterThan(60),
    );
  });
}
