import 'dart:async';

/// Debounces rapid calls to a single delayed execution.
/// Useful for preventing redundant extraction requests during fast swipes.
class Debouncer {
  Debouncer({required this.duration});

  final Duration duration;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void cancel() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }
}
