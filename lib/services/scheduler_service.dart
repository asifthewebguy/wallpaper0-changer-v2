import 'dart:async';

class SchedulerService {
  Timer? _timer;
  DateTime? _startedAt;
  Duration? _interval;

  void start({
    required Duration interval,
    required Future<void> Function() onTick,
  }) {
    stop();
    _interval = interval;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(interval, (_) => onTick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _startedAt = null;
    _interval = null;
  }

  void reset(Duration newInterval, {required Future<void> Function() onTick}) {
    stop();
    start(interval: newInterval, onTick: onTick);
  }

  bool get isRunning => _timer?.isActive ?? false;

  DateTime? get nextFireAt {
    if (_startedAt == null || _interval == null) return null;
    final elapsed = DateTime.now().difference(_startedAt!);
    final ticksDone = elapsed.inMicroseconds ~/ _interval!.inMicroseconds;
    return _startedAt!.add(_interval! * (ticksDone + 1));
  }
}
