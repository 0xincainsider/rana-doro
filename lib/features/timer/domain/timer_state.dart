import 'package:flutter/foundation.dart';

import 'timer_phase.dart';
import 'timer_status.dart';

@immutable
class TimerState {
  const TimerState({
    required this.phase,
    required this.status,
    required this.remaining,
    this.endsAt,
    this.hasSeenHint = false,
  });

  factory TimerState.initial() {
    return TimerState(
      phase: TimerPhase.focus,
      status: TimerStatus.idle,
      remaining: TimerPhase.focus.duration,
    );
  }

  factory TimerState.fromJson(Map<String, Object?> json) {
    final phase = _enumByName(
      TimerPhase.values,
      json['phase'],
      TimerPhase.focus,
    );
    var status = _enumByName(
      TimerStatus.values,
      json['status'],
      TimerStatus.idle,
    );
    var remaining = Duration(milliseconds: _positiveInt(json['remainingMs']));
    final endsAtMs = json['endsAtEpochMs'];
    final endsAt = endsAtMs is int
        ? DateTime.fromMillisecondsSinceEpoch(endsAtMs)
        : null;

    if (status == TimerStatus.running && endsAt == null) {
      status = TimerStatus.paused;
    }
    if (status == TimerStatus.paused && remaining <= Duration.zero) {
      status = TimerStatus.finished;
      remaining = Duration.zero;
    }
    if (remaining < Duration.zero) {
      remaining = Duration.zero;
    }

    return TimerState(
      phase: phase,
      status: status,
      remaining: remaining,
      endsAt: endsAt,
      hasSeenHint: json['hasSeenHint'] == true,
    );
  }

  final TimerPhase phase;
  final TimerStatus status;
  final Duration remaining;
  final DateTime? endsAt;
  final bool hasSeenHint;

  bool get isRunning => status == TimerStatus.running;
  bool get isFinished => status == TimerStatus.finished;
  bool get canReset => status == TimerStatus.paused;

  TimerState copyWith({
    TimerPhase? phase,
    TimerStatus? status,
    Duration? remaining,
    DateTime? endsAt,
    bool? hasSeenHint,
    bool clearEndsAt = false,
  }) {
    return TimerState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      remaining: remaining ?? this.remaining,
      endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
      hasSeenHint: hasSeenHint ?? this.hasSeenHint,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': 1,
      'phase': phase.name,
      'status': status.name,
      'remainingMs': remaining.inMilliseconds,
      'endsAtEpochMs': endsAt?.millisecondsSinceEpoch,
      'hasSeenHint': hasSeenHint,
    };
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }

  static int _positiveInt(Object? value) {
    if (value is int && value > 0) {
      return value;
    }
    return 0;
  }
}
