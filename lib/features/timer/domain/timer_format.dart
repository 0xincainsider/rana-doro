String formatRemaining(Duration remaining) {
  final totalSeconds = remaining.inMilliseconds <= 0
      ? 0
      : (remaining.inMilliseconds / 1000).ceil();
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String formatRemainingWords(Duration remaining) {
  final totalSeconds = remaining.inMilliseconds <= 0
      ? 0
      : (remaining.inMilliseconds / 1000).ceil();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  if (minutes == 0) {
    return seconds == 1 ? '1 segundo' : '$seconds segundos';
  }
  if (seconds == 0) {
    return minutes == 1 ? '1 minuto' : '$minutes minutos';
  }
  final minuteLabel = minutes == 1 ? '1 minuto' : '$minutes minutos';
  final secondLabel = seconds == 1 ? '1 segundo' : '$seconds segundos';
  return '$minuteLabel $secondLabel';
}
