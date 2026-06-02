import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum LmsItemType { assignment, quiz, exam }

class LmsCourse {
  final int id;
  final String name;
  const LmsCourse({required this.id, required this.name});
}

class LmsAssignment {
  final int id;
  final int courseId;
  final String courseName;
  final String name;
  final DateTime? dueAt;
  final LmsItemType itemType;
  final bool submitted;

  const LmsAssignment({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.name,
    this.dueAt,
    required this.itemType,
    required this.submitted,
  });

  String get difficulty {
    if (itemType == LmsItemType.exam || itemType == LmsItemType.quiz) return 'HARD';
    final lower = name.toLowerCase();
    const hardKeywords = ['소감문', '에세이', '보고서', '논문', '발표', '프로젝트', '시험', '설계'];
    if (hardKeywords.any((k) => lower.contains(k))) return 'HARD';
    return 'NORMAL';
  }

  String get priority {
    if (dueAt == null) return 'MEDIUM';
    final days = dueAt!.difference(DateTime.now()).inDays;
    if (days <= 3) return 'HIGH';
    if (days <= 7) return 'MEDIUM';
    return 'LOW';
  }

  String get typeLabel {
    switch (itemType) {
      case LmsItemType.quiz: return '퀴즈';
      case LmsItemType.exam: return '시험';
      case LmsItemType.assignment: return '과제';
    }
  }

  String get typeEmoji {
    switch (itemType) {
      case LmsItemType.quiz: return '📝';
      case LmsItemType.exam: return '📋';
      case LmsItemType.assignment: return '📚';
    }
  }
}

class LmsService {
  static const _base = 'https://learning.hanyang.ac.kr/api/v1';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
  ));

  static Options _auth(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  /// Returns active student courses.
  static Future<List<LmsCourse>> fetchCourses(String token) async {
    final all = await _getAll(
      '$_base/courses',
      token,
      params: {'enrollment_type': 'student', 'enrollment_state': 'active'},
    );
    return all
        .map((c) => LmsCourse(id: c['id'] as int, name: c['name'] as String))
        .toList();
  }

  /// Fetches unsubmitted assignments AND quizzes for all courses.
  /// Also includes items due within the last 3 days (recently missed).
  static Future<List<LmsAssignment>> fetchUnsubmitted(
    String token,
    List<LmsCourse> courses,
  ) async {
    final result = <LmsAssignment>[];
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day); // 오늘 00:00 이후만

    for (final course in courses) {
      final items = await Future.wait([
        _fetchAssignments(token, course, cutoff),
        _fetchQuizzes(token, course, cutoff),
      ]);
      for (final list in items) {
        result.addAll(list);
      }
    }

    // Deduplicate by id (quizzes can appear in both endpoints)
    final seen = <int>{};
    final deduped = result.where((a) => seen.add(a.id)).toList();

    deduped.sort((a, b) => (a.dueAt ?? DateTime(9999)).compareTo(b.dueAt ?? DateTime(9999)));
    return deduped;
  }

  // ─── Assignments ─────────────────────────────────────────────────────────

  static Future<List<LmsAssignment>> _fetchAssignments(
    String token,
    LmsCourse course,
    DateTime cutoff,
  ) async {
    try {
      final raw = await _getAll(
        '$_base/courses/${course.id}/assignments',
        token,
        params: {
          'include[]': 'submission',
          'order_by': 'due_at',
        },
      );

      return raw
          .map((a) => _parseAssignment(a, course))
          .whereType<LmsAssignment>()
          .where((a) {
            // 마감일 없는 것 제외
            if (a.dueAt == null) return false;
            // 오늘 이전 마감 제외
            if (a.dueAt!.isBefore(cutoff)) return false;
            // 이미 제출·채점된 것 제외
            return !a.submitted;
          })
          .toList();
    } on DioException catch (e) {
      debugPrint('[LMS] assignments ${course.id}: HTTP ${e.response?.statusCode}');
      return [];
    }
  }

  static LmsAssignment? _parseAssignment(
      Map<String, dynamic> a, LmsCourse course) {
    final dueRaw = a['due_at'] as String?;
    final dueAt = dueRaw != null ? DateTime.parse(dueRaw).toLocal() : null;

    final types = (a['submission_types'] as List<dynamic>?)
            ?.map((s) => s.toString())
            .toList() ??
        [];

    // types:none = 교수 수동 채점 방식 (시험, 수기 과제 등) → 과제로 처리
    // discussion_topic = 토론 게시판 제출
    // online_quiz = 퀴즈
    // external_tool / online_upload / online_text_entry = 일반 과제
    LmsItemType itemType;
    final name = (a['name'] as String? ?? '').toLowerCase();
    if (types.contains('online_quiz')) {
      itemType = LmsItemType.quiz;
    } else if (RegExp(r'시험|중간고사|기말고사|exam|midterm|final').hasMatch(name)) {
      itemType = LmsItemType.exam;
    } else {
      itemType = LmsItemType.assignment;
    }

    final submission = a['submission'] as Map<String, dynamic>?;
    final workflowState = submission?['workflow_state'] as String?;
    final submitted = workflowState != null &&
        ['submitted', 'graded', 'pending_review'].contains(workflowState);

    return LmsAssignment(
      id: a['id'] as int,
      courseId: course.id,
      courseName: course.name,
      name: a['name'] as String,
      dueAt: dueAt,
      itemType: itemType,
      submitted: submitted,
    );
  }

  // ─── Classic Quizzes ────────────────────────────────────────────────────

  static Future<List<LmsAssignment>> _fetchQuizzes(
    String token,
    LmsCourse course,
    DateTime cutoff,
  ) async {
    try {
      final raw = await _getAll(
        '$_base/courses/${course.id}/quizzes',
        token,
        params: {},
      );

      return raw.expand((q) {
        final dueRaw = q['due_at'] as String?;
        if (dueRaw == null) return <LmsAssignment>[];
        final dueAt = DateTime.parse(dueRaw).toLocal();
        if (dueAt.isBefore(cutoff)) return <LmsAssignment>[];

        final name = q['title'] as String? ?? '';
        final isExam = RegExp(r'시험|중간고사|기말고사|exam|midterm|final', caseSensitive: false).hasMatch(name);

        return [
          LmsAssignment(
            id: q['id'] as int,
            courseId: course.id,
            courseName: course.name,
            name: name,
            dueAt: dueAt,
            itemType: isExam ? LmsItemType.exam : LmsItemType.quiz,
            submitted: false,
          ),
        ];
      }).toList();
    } on DioException catch (e) {
      // 404 = quizzes not enabled for this course → ignore
      if (e.response?.statusCode != 404) {
        debugPrint('[LMS] quizzes ${course.id}: HTTP ${e.response?.statusCode}');
      }
      return [];
    }
  }

  // ─── Pagination helper ──────────────────────────────────────────────────

  /// Follows Canvas Link header pagination and returns all items.
  static Future<List<Map<String, dynamic>>> _getAll(
    String url,
    String token, {
    Map<String, dynamic> params = const {},
  }) async {
    final result = <Map<String, dynamic>>[];
    String? next = url;

    while (next != null) {
      final isFirstCall = next == url;
      final resp = await _dio.get(
        next,
        queryParameters: isFirstCall ? {'per_page': 100, ...params} : null,
        options: _auth(token),
      );

      final list = resp.data as List<dynamic>;
      result.addAll(list.cast<Map<String, dynamic>>());

      next = _parseNextLink(resp.headers.value('link'));
    }

    return result;
  }

  /// Parses the `Link: <url>; rel="next"` header.
  static String? _parseNextLink(String? linkHeader) {
    if (linkHeader == null) return null;
    for (final part in linkHeader.split(',')) {
      if (part.contains('rel="next"')) {
        final match = RegExp(r'<([^>]+)>').firstMatch(part.trim());
        return match?.group(1);
      }
    }
    return null;
  }
}
