enum TimerPhase {
  focus(Duration(minutes: 25), 'enfoque'),
  rest(Duration(minutes: 5), 'descanso');

  const TimerPhase(this.duration, this.label);

  final Duration duration;
  final String label;

  TimerPhase get next =>
      this == TimerPhase.focus ? TimerPhase.rest : TimerPhase.focus;
}
