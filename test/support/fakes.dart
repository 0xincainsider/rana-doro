import 'package:ranadoro/features/timer/data/timer_repository.dart';
import 'package:ranadoro/features/timer/domain/timer_phase.dart';
import 'package:ranadoro/features/timer/domain/timer_state.dart';
import 'package:ranadoro/services/timer_notifications.dart';

class FakeTimerRepository implements TimerRepository {
  FakeTimerRepository({this.saved});

  TimerState? saved;
  int loadCount = 0;
  int saveCount = 0;

  @override
  Future<TimerState?> load() async {
    loadCount++;
    return saved;
  }

  @override
  Future<void> save(TimerState state) async {
    saved = state;
    saveCount++;
  }
}

class FakeClock {
  FakeClock([DateTime? initial]) : now = initial ?? DateTime(2026, 11, 3, 12);

  DateTime now;

  DateTime call() => now;

  void advance(Duration duration) {
    now = now.add(duration);
  }
}

class FakeTimerNotifications implements TimerNotifications {
  FakeTimerNotifications({this.permissionGranted = true});

  bool permissionGranted;
  int permissionRequests = 0;
  int scheduleCount = 0;
  int cancelCount = 0;
  DateTime? lastScheduledEndsAt;
  TimerPhase? lastPhase;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> schedule({
    required DateTime endsAt,
    required TimerPhase phase,
  }) async {
    scheduleCount++;
    lastScheduledEndsAt = endsAt;
    lastPhase = phase;
  }

  @override
  Future<void> cancel() async {
    cancelCount++;
  }
}
