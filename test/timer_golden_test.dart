import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranadoro/app.dart';
import 'package:ranadoro/features/timer/application/timer_controller.dart';
import 'package:ranadoro/features/timer/domain/timer_phase.dart';
import 'package:ranadoro/features/timer/domain/timer_state.dart';
import 'package:ranadoro/features/timer/domain/timer_status.dart';
import 'package:ranadoro/features/timer/presentation/timer_screen.dart';

import 'support/fakes.dart';

void main() {
  setUpAll(() async {
    final caveat = FontLoader('Caveat')
      ..addFont(rootBundle.load('assets/fonts/Caveat-wght.ttf'));
    await caveat.load();
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-opsz-wght.ttf'));
    await inter.load();
  });

  testWidgets('golden de la pantalla con rana focus', (tester) async {
    tester.view.physicalSize = const Size(473, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TimerController(
      repository: FakeTimerRepository(),
      clock: FakeClock().call,
      initialState: TimerState(
        phase: TimerPhase.focus,
        status: TimerStatus.running,
        remaining: const Duration(minutes: 25),
        endsAt: DateTime(2026, 11, 3, 12, 25),
        hasSeenHint: true,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(RanadoroApp(controller: controller));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/frog_focus.png'),
        tester.element(find.byType(TimerScreen)),
      );
    });
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(TimerScreen),
      matchesGoldenFile('goldens/timer_focus.png'),
    );
  });

  testWidgets('golden de la pantalla inicial', (tester) async {
    tester.view.physicalSize = const Size(473, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TimerController(
      repository: FakeTimerRepository(),
      clock: FakeClock().call,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(RanadoroApp(controller: controller));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/frog_idle.png'),
        tester.element(find.byType(TimerScreen)),
      );
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TimerScreen),
      matchesGoldenFile('goldens/timer_idle.png'),
    );
  });
}
