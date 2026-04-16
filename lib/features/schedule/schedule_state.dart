import 'package:flutter/foundation.dart';

@immutable
class ScheduleState {
  final bool isEnabled;
  final int intervalMinutes;
  final DateTime? nextFireAt;

  const ScheduleState({
    required this.isEnabled,
    required this.intervalMinutes,
    this.nextFireAt,
  });
}
