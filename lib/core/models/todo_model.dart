class SubTask {
  final String id;
  final String title;
  final bool completed;

  const SubTask({required this.id, required this.title, this.completed = false});

  SubTask copyWith({String? title, bool? completed}) => SubTask(
        id: id,
        title: title ?? this.title,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
      };

  factory SubTask.fromJson(Map<String, dynamic> j) => SubTask(
        id: j['id'] as String,
        title: j['title'] as String,
        completed: j['completed'] as bool? ?? false,
      );
}

class FocusSession {
  final String id;
  final int durationMinutes;
  final int xpEarned;
  final DateTime timestamp;

  const FocusSession({
    required this.id,
    required this.durationMinutes,
    required this.xpEarned,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'durationMinutes': durationMinutes,
        'xpEarned': xpEarned,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FocusSession.fromJson(Map<String, dynamic> j) => FocusSession(
        id: j['id'] as String,
        durationMinutes: j['durationMinutes'] as int,
        xpEarned: j['xpEarned'] as int,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}

class Todo {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final bool completed;
  final DateTime? completedAt;
  final String priority; // HIGH, MEDIUM, LOW
  final String? categoryId;
  final String difficulty; // EASY, NORMAL, HARD
  final List<SubTask> subtasks;
  final List<FocusSession> focusSessions;
  final String? proofPath;
  final bool proofIsVideo;
  final String? lmsId;

  const Todo({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.completed = false,
    this.completedAt,
    this.priority = 'MEDIUM',
    this.categoryId,
    this.difficulty = 'NORMAL',
    this.subtasks = const [],
    this.focusSessions = const [],
    this.proofPath,
    this.proofIsVideo = false,
    this.lmsId,
  });

  int get totalFocusMinutes =>
      focusSessions.fold(0, (sum, s) => sum + s.durationMinutes);

  int get focusXp => focusSessions.fold(0, (sum, s) => sum + s.xpEarned);

  int get completionXp {
    int base = difficulty == 'HARD'
        ? 40
        : difficulty == 'EASY'
            ? 10
            : 20;
    if (proofPath != null) base += 5;
    if (subtasks.isNotEmpty && subtasks.every((s) => s.completed)) base += 10;
    return base;
  }

  int get totalXp => (completed ? completionXp : 0) + focusXp;

  Todo copyWith({
    String? title,
    String? description,
    DateTime? date,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? priority,
    String? categoryId,
    bool clearCategory = false,
    String? difficulty,
    List<SubTask>? subtasks,
    List<FocusSession>? focusSessions,
    String? proofPath,
    bool clearProof = false,
    bool? proofIsVideo,
    String? lmsId,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      priority: priority ?? this.priority,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      difficulty: difficulty ?? this.difficulty,
      subtasks: subtasks ?? this.subtasks,
      focusSessions: focusSessions ?? this.focusSessions,
      proofPath: clearProof ? null : (proofPath ?? this.proofPath),
      proofIsVideo: proofIsVideo ?? this.proofIsVideo,
      lmsId: lmsId ?? this.lmsId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
        'priority': priority,
        'categoryId': categoryId,
        'difficulty': difficulty,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'focusSessions': focusSessions.map((s) => s.toJson()).toList(),
        'proofPath': proofPath,
        'proofIsVideo': proofIsVideo,
        'lmsId': lmsId,
      };

  factory Todo.fromJson(Map<String, dynamic> j) => Todo(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        date: DateTime.parse(j['date'] as String),
        completed: j['completed'] as bool? ?? false,
        completedAt: j['completedAt'] != null
            ? DateTime.parse(j['completedAt'] as String)
            : null,
        priority: j['priority'] as String? ?? 'MEDIUM',
        categoryId: j['categoryId'] as String?,
        difficulty: j['difficulty'] as String? ?? 'NORMAL',
        subtasks: (j['subtasks'] as List<dynamic>? ?? [])
            .map((s) => SubTask.fromJson(s as Map<String, dynamic>))
            .toList(),
        focusSessions: (j['focusSessions'] as List<dynamic>? ?? [])
            .map((s) => FocusSession.fromJson(s as Map<String, dynamic>))
            .toList(),
        proofPath: j['proofPath'] as String?,
        proofIsVideo: j['proofIsVideo'] as bool? ?? false,
        lmsId: j['lmsId'] as String?,
      );
}
