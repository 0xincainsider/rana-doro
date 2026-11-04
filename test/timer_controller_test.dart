import 'package:flutter_test/flutter_test.dart';
import 'package:ranadoro/features/timer/application/timer_controller.dart';
import 'package:ranadoro/features/timer/domain/timer_format.dart';
import 'package:ranadoro/features/timer/domain/timer_phase.dart';
import 'package:ranadoro/features/timer/domain/timer_state.dart';
import 'package:ranadoro/features/timer/domain/timer_status.dart';

import 'support/fakes.dart';

void main() {
  late FakeTimerRepository repository;
  late FakeClock clock;
  late FakeTimerNotifications notifications;
  late TimerController controller;

  setUp(() {
    repository = FakeTimerRepository();
    clock = FakeClock();
    notifications = FakeTimerNotifications();
    controller = TimerController(
      repository: repository,
      clock: clock.call,
      notifications: notifications,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('arranca en enfoque de 25:00 sin pista vista', () {
    expect(controller.state.phase, TimerPhase.focus);
    expect(controller.state.status, TimerStatus.idle);
    expect(controller.display, '25:00');
    expect(controller.state.hasSeenHint, isFalse);
  });

  test(
    'iniciar guarda el estado, marca la pista y fija el vencimiento',
    () async {
      await controller.primaryAction();

      expect(controller.state.status, TimerStatus.running);
      expect(controller.state.hasSeenHint, isTrue);
      expect(
        controller.state.endsAt,
        clock.now.add(const Duration(minutes: 25)),
      );
      expect(repository.saved?.status, TimerStatus.running);
      expect(notifications.permissionRequests, 1);
      expect(notifications.scheduleCount, 1);
      expect(
        notifications.lastScheduledEndsAt,
        clock.now.add(const Duration(minutes: 25)),
      );
      expect(notifications.lastPhase, TimerPhase.focus);
    },
  );

  test('pedir permiso denegado no bloquea el timer', () async {
    notifications.permissionGranted = false;

    await controller.primaryAction();

    expect(controller.state.status, TimerStatus.running);
    expect(notifications.scheduleCount, 1);
  });

  test('no vuelve a pedir permiso al reanudar', () async {
    await controller.primaryAction();
    await controller.primaryAction();

    await controller.primaryAction();

    expect(notifications.permissionRequests, 1);
    expect(notifications.scheduleCount, 2);
  });

  test('pausar congela y reanudar continúa desde el mismo valor', () async {
    await controller.primaryAction();
    clock.advance(const Duration(seconds: 2));
    await controller.primaryAction();

    expect(controller.state.status, TimerStatus.paused);
    expect(controller.display, '24:58');

    clock.advance(const Duration(seconds: 30));
    await controller.primaryAction();
    expect(controller.state.status, TimerStatus.running);
    expect(controller.display, '24:58');
    expect(notifications.cancelCount, greaterThanOrEqualTo(1));
    expect(notifications.scheduleCount, 2);

    clock.advance(const Duration(seconds: 1));
    await controller.sync();
    expect(controller.display, '24:57');
  });

  test(
    'reiniciar solo funciona en pausa y vuelve a la duración completa',
    () async {
      await controller.primaryAction();
      clock.advance(const Duration(seconds: 10));
      await controller.primaryAction();
      expect(controller.display, '24:50');

      await controller.reset();

      expect(controller.state.status, TimerStatus.paused);
      expect(controller.display, '25:00');
      expect(repository.saved?.remaining, const Duration(minutes: 25));
    },
  );

  test('reiniciar no hace nada durante la cuenta activa', () async {
    await controller.primaryAction();
    clock.advance(const Duration(seconds: 5));

    await controller.reset();

    expect(controller.state.status, TimerStatus.running);
    expect(repository.saved?.status, TimerStatus.running);
  });

  test('terminar enfoque deja listo el descanso sin iniciarlo', () async {
    await controller.primaryAction();
    clock.advance(const Duration(minutes: 25));
    await controller.sync();

    expect(controller.state.status, TimerStatus.finished);
    expect(controller.state.phase, TimerPhase.focus);
    expect(controller.display, '00:00');

    await controller.primaryAction();

    expect(controller.state.phase, TimerPhase.rest);
    expect(controller.state.status, TimerStatus.running);
    expect(controller.display, '05:00');
  });

  test(
    'terminar cancela el aviso y la siguiente fase programa descanso',
    () async {
      await controller.primaryAction();
      clock.advance(const Duration(minutes: 25));

      await controller.sync();
      await controller.primaryAction();

      expect(notifications.cancelCount, greaterThanOrEqualTo(1));
      expect(notifications.lastPhase, TimerPhase.rest);
      expect(
        notifications.lastScheduledEndsAt,
        clock.now.add(const Duration(minutes: 5)),
      );
    },
  );

  test('terminar descanso ofrece el siguiente enfoque', () async {
    await controller.primaryAction();
    clock.advance(const Duration(minutes: 25));
    await controller.sync();
    await controller.primaryAction();

    clock.advance(const Duration(minutes: 5));
    await controller.sync();

    expect(controller.state.phase, TimerPhase.rest);
    expect(controller.state.status, TimerStatus.finished);

    await controller.primaryAction();

    expect(controller.state.phase, TimerPhase.focus);
    expect(controller.state.status, TimerStatus.running);
    expect(controller.display, '25:00');
  });

  test('el fin se procesa una sola vez y no hay valores negativos', () async {
    await controller.primaryAction();
    clock.advance(const Duration(minutes: 30));
    await controller.sync();
    final saveCount = repository.saveCount;

    await controller.sync();
    await controller.sync();

    expect(controller.state.status, TimerStatus.finished);
    expect(controller.state.remaining, Duration.zero);
    expect(repository.saveCount, saveCount);
  });

  test('restaurar una cuenta en curso reprograma el aviso', () async {
    repository.saved = TimerState(
      phase: TimerPhase.focus,
      status: TimerStatus.running,
      remaining: const Duration(minutes: 10),
      endsAt: clock.now.add(const Duration(minutes: 10)),
      hasSeenHint: true,
    );

    await controller.initialize();

    expect(notifications.scheduleCount, 1);
    expect(
      notifications.lastScheduledEndsAt,
      clock.now.add(const Duration(minutes: 10)),
    );
  });

  test('restaurar una pausa cancela el aviso pendiente', () async {
    repository.saved = const TimerState(
      phase: TimerPhase.rest,
      status: TimerStatus.paused,
      remaining: Duration(minutes: 3),
      hasSeenHint: true,
    );

    await controller.initialize();

    expect(notifications.cancelCount, 1);
  });

  test('restaura una cuenta en curso con reloj de pared', () async {
    repository.saved = TimerState(
      phase: TimerPhase.focus,
      status: TimerStatus.running,
      remaining: const Duration(minutes: 10),
      endsAt: clock.now.add(const Duration(minutes: 10)),
      hasSeenHint: true,
    );

    await controller.initialize();

    expect(controller.state.status, TimerStatus.running);
    expect(controller.display, '10:00');

    clock.advance(const Duration(minutes: 2));
    await controller.sync();

    expect(controller.display, '08:00');
  });

  test('restaura una sesión vencida como terminada', () async {
    repository.saved = TimerState(
      phase: TimerPhase.focus,
      status: TimerStatus.running,
      remaining: const Duration(minutes: 10),
      endsAt: clock.now.subtract(const Duration(minutes: 1)),
      hasSeenHint: true,
    );

    await controller.initialize();

    expect(controller.state.status, TimerStatus.finished);
    expect(controller.display, '00:00');
  });

  test('restaura una pausa con la fase y el tiempo guardados', () async {
    repository.saved = TimerState(
      phase: TimerPhase.rest,
      status: TimerStatus.paused,
      remaining: const Duration(minutes: 3, seconds: 10),
      hasSeenHint: true,
    );

    await controller.initialize();

    expect(controller.state.phase, TimerPhase.rest);
    expect(controller.state.status, TimerStatus.paused);
    expect(controller.display, '03:10');
  });

  test('serializa y deserializa el estado', () {
    const state = TimerState(
      phase: TimerPhase.rest,
      status: TimerStatus.paused,
      remaining: Duration(minutes: 3, seconds: 10),
      hasSeenHint: true,
    );

    final restored = TimerState.fromJson(state.toJson());

    expect(restored.phase, TimerPhase.rest);
    expect(restored.status, TimerStatus.paused);
    expect(restored.remaining, const Duration(minutes: 3, seconds: 10));
    expect(restored.hasSeenHint, isTrue);
    expect(restored.endsAt, isNull);
  });

  test('formatea el tiempo y su versión accesible', () {
    expect(formatRemaining(const Duration(minutes: 25)), '25:00');
    expect(formatRemaining(const Duration(minutes: 9, seconds: 59)), '09:59');
    expect(formatRemaining(const Duration(milliseconds: 1499400)), '25:00');
    expect(formatRemaining(Duration.zero), '00:00');

    expect(formatRemainingWords(const Duration(minutes: 25)), '25 minutos');
    expect(
      formatRemainingWords(const Duration(minutes: 1, seconds: 1)),
      '1 minuto 1 segundo',
    );
    expect(formatRemainingWords(const Duration(seconds: 30)), '30 segundos');
  });
}
