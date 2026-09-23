class LyricLine {
  const LyricLine({
    required this.timeMs,
    required this.text,
  });

  final int timeMs;
  final String text;

  bool get isGap => text.trim().isEmpty;

  @override
  String toString() => 'LyricLine(timeMs: $timeMs, text: "$text")';
}
