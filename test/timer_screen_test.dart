import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranadoro/app.dart';
import 'package:ranadoro/core/theme/app_theme.dart';
import 'package:ranadoro/core/theme/tokens.dart';
import 'package:ranadoro/features/timer/application/timer_controller.dart';
import 'package:ranadoro/features/timer/domain/timer_phase.dart';
import 'package:ranadoro/features/timer/domain/timer_state.dart';
import 'package:ranadoro/features/timer/domain/timer_status.dart';
import 'package:ranadoro/features/timer/presentation/timer_screen.dart';

import 'support/fakes.dart';

void main() {
  TimerController buildController({TimerState? initialState}) {
    final clock = FakeClock();
    return TimerController(
      repository: FakeTimerRepository(),
      clock: clock.call,
      initialState: initialState,
    );
  }

  testWidgets('muestra el estado inicial y la pista de primera apertura', (
    tester,
  ) async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(RanadoroApp(controller: controller));

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('enfoque'), findsOneWidget);
    expect(find.text('rana-doro'), findsOneWidget);
    expect(find.text('toca para empezar'), findsOneWidget);
    expect(find.byKey(TimerKeys.hint), findsOneWidget);
    expect(find.byKey(TimerKeys.reset), findsNothing);
  });

  testWidgets('tocar inicia y volver a tocar pausa', (tester) async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(RanadoroApp(controller: controller));

    await tester.tap(find.byKey(TimerKeys.timer));
    await tester.pump();
    expect(controller.state.status, TimerStatus.running);
    expect(find.byKey(TimerKeys.hint), findsNothing);

    await tester.tap(find.byKey(TimerKeys.timer));
    await tester.pump();
    expect(controller.state.status, TimerStatus.paused);
    expect(find.text('en pausa'), findsOneWidget);
    expect(find.byKey(TimerKeys.reset), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('usa la rana focus mientras corre y la default al pausar', (
    tester,
  ) async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(RanadoroApp(controller: controller));

    await tester.tap(find.byKey(TimerKeys.timer));
    await tester.pump();
    final runningImage =
        tester.widget<Image>(find.byKey(TimerKeys.frog)).image as AssetImage;
    expect(runningImage.assetName, 'assets/images/frog_focus.png');

    await tester.tap(find.byKey(TimerKeys.timer));
    await tester.pump();
    final pausedImage =
        tester.widget<Image>(find.byKey(TimerKeys.frog)).image as AssetImage;
    expect(pausedImage.assetName, 'assets/images/frog_idle.png');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reiniciar vuelve a 25:00 y sigue en pausa', (tester) async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(RanadoroApp(controller: controller));
    await tester.tap(find.byKey(TimerKeys.timer));
    await tester.pump();
    await tester.tap(find.byKey(TimerKeys.timer));
    await tester.pump();

    await tester.tap(find.byKey(TimerKeys.reset));
    await tester.pump();

    expect(controller.state.status, TimerStatus.paused);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('en pausa'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('al terminar ofrece el descanso y arranca al tocar', (
    tester,
  ) async {
    final controller = buildController(
      initialState: const TimerState(
        phase: TimerPhase.focus,
        status: TimerStatus.finished,
        remaining: Duration.zero,
        hasSeenHint: true,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(RanadoroApp(controller: controller));

    expect(find.text('listo'), findsOneWidget);
    expect(find.text('empezar descanso'), findsOneWidget);
    expect(find.byKey(TimerKeys.nextPhase), findsOneWidget);

    await tester.tap(find.byKey(TimerKeys.nextPhase));
    await tester.pump();

    expect(controller.state.phase, TimerPhase.rest);
    expect(controller.state.status, TimerStatus.running);
    expect(find.text('descanso'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    await tester.tap(find.byKey(TimerKeys.timer));
    await tester.pump();
    expect(controller.state.status, TimerStatus.paused);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('el temporizador expone una etiqueta semántica de botón', (
    tester,
  ) async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(RanadoroApp(controller: controller));

    final semantics = tester
        .getSemantics(find.byKey(TimerKeys.timer))
        .getSemanticsData();
    expect(semantics.label, 'Iniciar sesión de enfoque, 25 minutos');
    expect(semantics.flagsCollection.isButton, isTrue);
  });

  testWidgets('soporta texto al 200 % sin desbordar', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: TimerScreen(controller: controller),
            );
          },
        ),
      ),
    );

    expect(find.text('25:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('respeta el tema oscuro del sistema', (tester) async {
    final controller = buildController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: TimerScreen(controller: controller),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(AppColors.of(context), AppColors.dark);
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.dark.paper);
  });
}
