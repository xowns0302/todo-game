import 'dart:async';
import 'package:flutter/material.dart';

enum TimerState { idle, running, paused, finished }

class TimerProvider extends ChangeNotifier {
  TimerState _state = TimerState.idle;
  int _targetSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  String? _currentTodoId;
  Timer? _timer;
  int _elapsedSeconds = 0;

  TimerState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get targetSeconds => _targetSeconds;
  int get elapsedSeconds => _elapsedSeconds;
  String? get currentTodoId => _currentTodoId;
  bool get isRunning => _state == TimerState.running;
  bool get isFinished => _state == TimerState.finished;

  double get progress =>
      _targetSeconds > 0 ? 1.0 - (_remainingSeconds / _targetSeconds) : 0.0;

  String get timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get elapsedMinutes => _elapsedSeconds ~/ 60;

  void setup(int durationMinutes, String todoId) {
    _timer?.cancel();
    _targetSeconds = durationMinutes * 60;
    _remainingSeconds = _targetSeconds;
    _currentTodoId = todoId;
    _elapsedSeconds = 0;
    _state = TimerState.idle;
    notifyListeners();
  }

  void start() {
    if (_state == TimerState.running) return;
    _state = TimerState.running;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _elapsedSeconds++;
      } else {
        _timer?.cancel();
        _state = TimerState.finished;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
  }

  void resume() => start();

  void stop() {
    _timer?.cancel();
    _elapsedSeconds = _targetSeconds - _remainingSeconds;
    _state = TimerState.idle;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _remainingSeconds = _targetSeconds;
    _elapsedSeconds = 0;
    _state = TimerState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
