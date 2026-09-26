import 'dart:async';
import 'package:flutter/material.dart';

class SleepTimer extends ChangeNotifier {
  Timer? _timer;
  Timer? _ticker;
  DateTime? _endTime;

  bool get isActive => _timer != null && _timer!.isActive;
  Duration? get timeRemaining => _endTime != null ? _endTime!.difference(DateTime.now()) : null;

  void start(Duration duration, VoidCallback onSleep) {
    cancel();
    _endTime = DateTime.now().add(duration);
    _timer = Timer(duration, () {
      onSleep();
      cancel();
    });
    
    // Ticker to update UI every second
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
    
    notifyListeners();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _ticker?.cancel();
    _ticker = null;
    _endTime = null;
    notifyListeners();
  }
}
