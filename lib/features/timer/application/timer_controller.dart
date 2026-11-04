import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/clock.dart';
import '../../../services/timer_notifications.dart';
import '../data/timer_repository.dart';
import '../domain/timer_format.dart';
import '../domain/timer_state.dart';
import '../domain/timer_status.dart';

class TimerController extends ChangeNotifier {
  TimerController({
    required this.repository,
    this.clock = systemClock,
    this.notifications = const NoopTimerNotifications(),
    TimerState? initialState,
  }) : _state = initialState ?? TimerState.initial();

  final TimerRepository repository;
  final Clock clock;
  final TimerNotifications notifications;

  TimerState _state;
  Timer? _ticker;
  bool _disposed = false;

  TimerState get state => _state;

  String get display => formatRemaining(_state.remaining);

  Future<void> initialize() async {
    final saved = await repository.load();
    if (saved == null) {
      return;
    }
    _state = _restore(saved);
    if (_state.isRunning && _state.endsAt == null) {
      _state = _state.copyWith(status: TimerStatus.paused, clearEndsAt: true);
    }
    if (_state.isRunning) {
      _startTicker();
      await notifications.schedule(endsAt: _state.endsAt!, phase: _state.phase);
    } else {
      await notifications.cancel();
    }
    await _persist();
    _notify();
  }

  Future<void> primaryAction() {
    switch (_state.status) {
      case TimerStatus.idle:
        return _start();
      case TimerStatus.running:
        return _pause();
      case TimerStatus.paused:
        return _resume();
      case TimerStatus.finished:
        return _startNextPhase();
    }
  }

  Future<void> reset() async {
    if (!_state.canReset) {
      return;
    }
    _cancelTicker();
    await notifications.cancel();
    _state = _state.copyWith(
      status: TimerStatus.paused,
      remaining: _state.phase.duration,
      clearEndsAt: true,
    );
    await _persist();
    _notify();
  }

  Future<void> sync() async {
    if (!_state.isRunning || _state.endsAt == null) {
      return;
    }
    final remaining = _state.endsAt!.difference(clock());
    if (remaining <= Duration.zero) {
      await _finish();
      return;
    }
    _state = _state.copyWith(remaining: remaining);
    _notify();
  }

  TimerState _restore(TimerState saved) {
    if (!saved.isRunning || saved.endsAt == null) {
      return saved;
    }
    final remaining = saved.endsAt!.difference(clock());
    if (remaining <= Duration.zero) {
      return saved.copyWith(
        status: TimerStatus.finished,
        remaining: Duration.zero,
        clearEndsAt: true,
      );
    }
    return saved.copyWith(remaining: remaining);
  }

  Future<void> _start() async {
    final duration = _state.phase.duration;
    final now = clock();
    final endsAt = now.add(duration);
    final firstStart = !_state.hasSeenHint;
    _state = _state.copyWith(
      status: TimerStatus.running,
      remaining: duration,
      endsAt: endsAt,
      hasSeenHint: true,
    );
    _startTicker();
    if (firstStart) {
      await notifications.requestPermission();
    }
    await notifications.schedule(endsAt: endsAt, phase: _state.phase);
    await _persist();
    _notify();
  }

  Future<void> _pause() async {
    final endsAt = _state.endsAt;
    final remaining = endsAt == null
        ? _state.remaining
        : endsAt.difference(clock());
    if (remaining <= Duration.zero) {
      await _finish();
      return;
    }
    _cancelTicker();
    await notifications.cancel();
    _state = _state.copyWith(
      status: TimerStatus.paused,
      remaining: remaining,
      clearEndsAt: true,
    );
    await _persist();
    _notify();
  }

  Future<void> _resume() async {
    final now = clock();
    final endsAt = now.add(_state.remaining);
    _state = _state.copyWith(status: TimerStatus.running, endsAt: endsAt);
    _startTicker();
    await notifications.schedule(endsAt: endsAt, phase: _state.phase);
    await _persist();
    _notify();
  }

  Future<void> _startNextPhase() async {
    final next = _state.phase.next;
    final now = clock();
    final endsAt = now.add(next.duration);
    _state = _state.copyWith(
      phase: next,
      status: TimerStatus.running,
      remaining: next.duration,
      endsAt: endsAt,
      hasSeenHint: true,
    );
    _startTicker();
    await notifications.schedule(endsAt: endsAt, phase: next);
    await _persist();
    _notify();
  }

  Future<void> _finish() async {
    if (_state.isFinished) {
      return;
    }
    _cancelTicker();
    await notifications.cancel();
    _state = _state.copyWith(
      status: TimerStatus.finished,
      remaining: Duration.zero,
      clearEndsAt: true,
    );
    await _persist();
    _notify();
  }

  void _startTicker() {
    _cancelTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(sync());
    });
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _persist() async {
    try {
      await repository.save(_state);
    } on Object {
      return;
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTicker();
    super.dispose();
  }
}
