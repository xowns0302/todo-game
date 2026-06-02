import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_model.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';

class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];
  int _totalXp = 0;
  bool _isLoaded = false;

  static const _uuid = Uuid();

  List<Todo> get todos => _todos;
  int get totalXp => _totalXp;
  bool get isLoaded => _isLoaded;

  int get level {
    int remaining = _totalXp;
    int lvl = 1;
    while (remaining >= lvl * 100) {
      remaining -= lvl * 100;
      lvl++;
    }
    return lvl;
  }

  int get currentLevelXp {
    int remaining = _totalXp;
    int lvl = 1;
    while (remaining >= lvl * 100) {
      remaining -= lvl * 100;
      lvl++;
    }
    return remaining;
  }

  int get xpToNextLevel => level * 100;

  Future<void> init() async {
    _todos = await StorageService.loadTodos();
    _totalXp = await StorageService.loadTotalXp();
    _isLoaded = true;
    notifyListeners();
  }

  List<Todo> getTodosForDate(DateTime date) {
    const priorityOrder = ['HIGH', 'MEDIUM', 'LOW'];
    return _todos
        .where((t) =>
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day)
        .toList()
      ..sort((a, b) =>
          priorityOrder.indexOf(a.priority).compareTo(priorityOrder.indexOf(b.priority)));
  }

  // Returns dateKey ('yyyy-M-d') -> completion ratio (0.0–1.0)
  Map<String, double> getCompletionRatioByDate() {
    final Map<String, List<Todo>> byDate = {};
    for (final todo in _todos) {
      final key = '${todo.date.year}-${todo.date.month}-${todo.date.day}';
      byDate.putIfAbsent(key, () => []).add(todo);
    }
    return byDate.map((key, list) {
      final completed = list.where((t) => t.completed).length;
      return MapEntry(key, list.isEmpty ? 0.0 : completed / list.length);
    });
  }

  bool hasLmsTodo(String lmsId) => _todos.any((t) => t.lmsId == lmsId);

  Future<void> addTodo({
    required String title,
    String? description,
    required DateTime date,
    String priority = 'MEDIUM',
    String? categoryId,
    String? difficulty,
    List<String> subtaskTitles = const [],
    String? lmsId,
  }) async {
    final autoDifficulty = difficulty ?? await AiService.analyzeDifficulty(title);
    final todo = Todo(
      id: _uuid.v4(),
      title: title,
      description: description,
      date: date,
      priority: priority,
      categoryId: categoryId,
      difficulty: autoDifficulty,
      subtasks: subtaskTitles
          .map((t) => SubTask(id: _uuid.v4(), title: t))
          .toList(),
      lmsId: lmsId,
    );
    _todos.add(todo);
    await _save();
    notifyListeners();
  }

  Future<void> updateTodo(Todo updated) async {
    final idx = _todos.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    _todos[idx] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((t) => t.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> postponeTodo(String id) async {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final next = _todos[idx].date.add(const Duration(days: 1));
    _todos[idx] = _todos[idx].copyWith(date: next);
    await _save();
    notifyListeners();
  }

  Future<void> changeTodoDate(String id, DateTime date) async {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _todos[idx] = _todos[idx].copyWith(date: date);
    await _save();
    notifyListeners();
  }

  Future<void> toggleTodo(String id) async {
    final idx = _todos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final todo = _todos[idx];
    if (!todo.completed) {
      _todos[idx] = todo.copyWith(completed: true, completedAt: DateTime.now());
      _totalXp += todo.completionXp;
      await StorageService.saveTotalXp(_totalXp);
    } else {
      _todos[idx] = todo.copyWith(completed: false, clearCompletedAt: true);
      _totalXp = (_totalXp - todo.completionXp).clamp(0, 999999);
      await StorageService.saveTotalXp(_totalXp);
    }

    await _save();
    notifyListeners();
  }

  Future<void> toggleSubtask(String todoId, String subtaskId) async {
    final todoIdx = _todos.indexWhere((t) => t.id == todoId);
    if (todoIdx == -1) return;

    final todo = _todos[todoIdx];
    final subtasks = todo.subtasks.map((s) {
      if (s.id == subtaskId) return s.copyWith(completed: !s.completed);
      return s;
    }).toList();

    _todos[todoIdx] = todo.copyWith(subtasks: subtasks);
    await _save();
    notifyListeners();
  }

  Future<void> addSubtask(String todoId, String title) async {
    final idx = _todos.indexWhere((t) => t.id == todoId);
    if (idx == -1) return;
    final subtasks = [..._todos[idx].subtasks, SubTask(id: _uuid.v4(), title: title)];
    _todos[idx] = _todos[idx].copyWith(subtasks: subtasks);
    await _save();
    notifyListeners();
  }

  Future<void> deleteSubtask(String todoId, String subtaskId) async {
    final idx = _todos.indexWhere((t) => t.id == todoId);
    if (idx == -1) return;
    final subtasks = _todos[idx].subtasks.where((s) => s.id != subtaskId).toList();
    _todos[idx] = _todos[idx].copyWith(subtasks: subtasks);
    await _save();
    notifyListeners();
  }

  Future<void> addFocusSession(String todoId, FocusSession session) async {
    final idx = _todos.indexWhere((t) => t.id == todoId);
    if (idx == -1) return;

    final sessions = [..._todos[idx].focusSessions, session];
    _todos[idx] = _todos[idx].copyWith(focusSessions: sessions);
    _totalXp += session.xpEarned;
    await StorageService.saveTotalXp(_totalXp);
    await _save();
    notifyListeners();
  }

  Future<void> setProof(String todoId, String path, bool isVideo) async {
    final idx = _todos.indexWhere((t) => t.id == todoId);
    if (idx == -1) return;
    _todos[idx] = _todos[idx].copyWith(proofPath: path, proofIsVideo: isVideo);
    await _save();
    notifyListeners();
  }

  Future<void> clearProof(String todoId) async {
    final idx = _todos.indexWhere((t) => t.id == todoId);
    if (idx == -1) return;
    _todos[idx] = _todos[idx].copyWith(clearProof: true);
    await _save();
    notifyListeners();
  }

  Todo? getTodoById(String id) {
    try {
      return _todos.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> suggestSubtasks(String title) => AiService.suggestSubtasks(title);

  int get totalCompleted => _todos.where((t) => t.completed).length;
  int get totalFocusMinutes =>
      _todos.fold(0, (sum, t) => sum + t.totalFocusMinutes);
  int get hardCompleted =>
      _todos.where((t) => t.completed && t.difficulty == 'HARD').length;

  Future<void> _save() => StorageService.saveTodos(_todos);
}
