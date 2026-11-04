import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/theme/tokens.dart';
import '../application/timer_controller.dart';
import '../domain/timer_format.dart';
import '../domain/timer_phase.dart';
import '../domain/timer_state.dart';
import '../domain/timer_status.dart';

class TimerKeys {
  static const Key timer = Key('timer-tap-target');
  static const Key reset = Key('reset-action');
  static const Key nextPhase = Key('next-phase-action');
  static const Key hint = Key('first-run-hint');
  static const Key frog = Key('frog');
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key, required this.controller});

  final TimerController controller;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final state = widget.controller.state;
            return LayoutBuilder(
              builder: (context, constraints) {
                final timerSize = (constraints.maxWidth * 0.15)
                    .clamp(56.0, 140.0)
                    .toDouble();
                final frogWidth = math.min(
                  (constraints.maxWidth * 0.42).clamp(150.0, 280.0).toDouble(),
                  (constraints.maxHeight * 0.28).clamp(120.0, 280.0).toDouble(),
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const SizedBox(height: 28),
                        Text(
                          _phaseLabel(state),
                          style: caveatStyle(
                            22,
                            color: colors.inkMuted,
                            weight: 500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _TimerTapTarget(
                          controller: widget.controller,
                          state: state,
                          child: Text(
                            widget.controller.display,
                            maxLines: 1,
                            style: timeStyle(timerSize, colors.ink),
                          ),
                        ),
                        _SecondaryAction(
                          state: state,
                          controller: widget.controller,
                          colors: colors,
                        ),
                        const Spacer(),
                        _FrogStage(width: frogWidth, state: state),
                        const SizedBox(height: 18),
                        Text(
                          kAppName,
                          style: caveatStyle(
                            22,
                            color: colors.ink,
                            weight: 600,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TimerTapTarget extends StatelessWidget {
  const _TimerTapTarget({
    required this.controller,
    required this.state,
    required this.child,
  });

  final TimerController controller;
  final TimerState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: TimerKeys.timer,
      button: true,
      label: _semanticLabel(state),
      excludeSemantics: true,
      onTap: () {
        controller.primaryAction();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          controller.primaryAction();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.state,
    required this.controller,
    required this.colors,
  });

  final TimerState state;
  final TimerController controller;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case TimerStatus.paused:
        return _TextAction(
          key: TimerKeys.reset,
          label: kResetLabel,
          onPressed: controller.reset,
        );
      case TimerStatus.finished:
        return _TextAction(
          key: TimerKeys.nextPhase,
          label: state.phase.next == TimerPhase.focus
              ? kStartFocusLabel
              : kStartBreakLabel,
          onPressed: controller.primaryAction,
        );
      case TimerStatus.idle:
        if (state.hasSeenHint) {
          return const SizedBox(height: kMinTouchTarget);
        }
        return SizedBox(
          height: kMinTouchTarget,
          child: Center(
            child: Text(
              kStartHint,
              key: TimerKeys.hint,
              maxLines: 1,
              style: caveatStyle(20, color: colors.inkMuted, weight: 500),
            ),
          ),
        );
      case TimerStatus.running:
        return const SizedBox(height: kMinTouchTarget);
    }
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({super.key, required this.label, required this.onPressed});

  final String label;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: kMinTouchTarget,
      child: TextButton(
        onPressed: () {
          onPressed();
        },
        style: TextButton.styleFrom(
          foregroundColor: colors.ink,
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: caveatStyle(22, color: colors.ink, weight: 600),
          ),
        ),
      ),
    );
  }
}

class _FrogStage extends StatefulWidget {
  const _FrogStage({required this.width, required this.state});

  final double width;
  final TimerState state;

  @override
  State<_FrogStage> createState() => _FrogStageState();
}

class _FrogStageState extends State<_FrogStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _FrogStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  void _syncAnimation() {
    final shouldAnimate =
        widget.state.isRunning && !MediaQuery.of(context).disableAnimations;
    if (shouldAnimate) {
      if (!_breathe.isAnimating) {
        _breathe.repeat(reverse: true);
      }
    } else {
      _breathe.stop();
      _breathe.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final shadowWidth = widget.width * 1.05;
    final shadowHeight = widget.width * 0.09;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final frogAsset = widget.state.isRunning
        ? (isDark
              ? 'assets/images/frog_focus_dark.png'
              : 'assets/images/frog_focus.png')
        : (isDark
              ? 'assets/images/frog_idle_dark.png'
              : 'assets/images/frog_idle.png');

    return SizedBox(
      width: widget.width * 1.2,
      height: widget.width * 1.12,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: shadowWidth,
              height: shadowHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.elliptical(shadowWidth, shadowHeight),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 24,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: widget.width * 0.05,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.018).animate(
                CurvedAnimation(parent: _breathe, curve: Curves.easeInOut),
              ),
              child: Image.asset(
                frogAsset,
                key: TimerKeys.frog,
                width: widget.width,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _phaseLabel(TimerState state) {
  switch (state.status) {
    case TimerStatus.idle:
      return state.phase.label;
    case TimerStatus.running:
      return state.phase.label;
    case TimerStatus.paused:
      return kPausedLabel;
    case TimerStatus.finished:
      return kReadyLabel;
  }
}

String _semanticLabel(TimerState state) {
  final remaining = formatRemainingWords(state.remaining);
  switch (state.status) {
    case TimerStatus.idle:
      return 'Iniciar sesión de ${state.phase.label}, '
          '${formatRemainingWords(state.phase.duration)}';
    case TimerStatus.running:
      return 'Pausar sesión de ${state.phase.label}, quedan $remaining';
    case TimerStatus.paused:
      return 'Reanudar sesión de ${state.phase.label}, quedan $remaining';
    case TimerStatus.finished:
      final next = state.phase.next;
      return 'Iniciar ${next.label}, ${formatRemainingWords(next.duration)}';
  }
}
