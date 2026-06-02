import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ParsedTodo {
  final String title;
  final DateTime date;
  final String? dueTime;
  final String priority;
  final String difficulty;
  final String? categoryId;
  final List<String> subtasks;
  final String? description;

  const ParsedTodo({
    required this.title,
    required this.date,
    this.dueTime,
    required this.priority,
    required this.difficulty,
    this.categoryId,
    required this.subtasks,
    this.description,
  });
}

class GeminiService {
  static const _baseEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // 무료 티어 지원 모델 우선순위 순 (lite 계열이 무료 티어)
  static const _candidateModels = [
    'gemini-2.0-flash-lite',      // 무료 티어 ✓
    'gemini-2.5-flash-lite',      // 무료 티어 ✓
    'gemini-flash-lite-latest',   // lite 최신 alias
    'gemini-2.0-flash-lite-001',  // versioned
    'gemini-2.5-flash',           // 유료일 수 있음
    'gemini-2.0-flash',           // 유료
  ];

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));

  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get apiKey => _apiKey;

  // 실제로 동작하는 모델 캐시
  static String? _workingModel;

  /// API에서 사용 가능한 모델 목록을 조회해 첫 번째 작동 모델을 찾음
  static Future<String?> _findWorkingModel() async {
    if (_workingModel != null) return _workingModel;

    // ListModels로 실제 사용 가능한 모델 조회
    try {
      final resp = await _dio.get(
        '$_baseEndpoint?key=$_apiKey&pageSize=50',
      );
      final models = (resp.data['models'] as List<dynamic>? ?? []);
      final availableNames = models
          .map((m) => (m['name'] as String).replaceFirst('models/', ''))
          .toSet();
      debugPrint('[Gemini] 사용 가능한 모델: $availableNames');

      // 후보 중 실제로 있는 것만 필터링
      for (final candidate in _candidateModels) {
        if (availableNames.contains(candidate)) {
          debugPrint('[Gemini] 선택된 모델: $candidate');
          _workingModel = candidate;
          return _workingModel;
        }
      }
    } catch (e) {
      debugPrint('[Gemini] 모델 목록 조회 실패: $e');
    }

    // ListModels 실패 시 후보를 순서대로 직접 시도
    return null;
  }

  static Future<Map<String, dynamic>?> _call(String prompt) async {
    if (_apiKey.isEmpty) {
      debugPrint('[Gemini] API 키가 없습니다. .env 파일을 확인하세요.');
      return null;
    }

    // 작동하는 모델 탐색
    final preferredModel = await _findWorkingModel();
    final modelsToTry = preferredModel != null
        ? [preferredModel, ..._candidateModels.where((m) => m != preferredModel)]
        : _candidateModels;

    for (final model in modelsToTry) {
      try {
        final url = '$_baseEndpoint/$model:generateContent?key=$_apiKey';
        final response = await _dio.post(
          url,
          data: {
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'temperature': 0.1,
            },
          },
        );

        // 성공 시 이 모델을 캐시
        _workingModel = model;
        debugPrint('[Gemini] $model 성공');
        final text =
            response.data['candidates'][0]['content']['parts'][0]['text'] as String;
        return jsonDecode(text) as Map<String, dynamic>;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final msg = e.response?.data?['error']?['message'] ?? e.message;
        debugPrint('[Gemini] $model 실패 → HTTP $status: $msg');

        if (status == 401 || status == 403) {
          debugPrint('[Gemini] API 키 오류. 키를 확인하세요.');
          return null;
        }
        // 429(할당량), 404(없는 모델) → 다음 모델 시도
        _workingModel = null;
        continue;
      } catch (e) {
        debugPrint('[Gemini] 예상치 못한 오류: $e');
        return null;
      }
    }

    debugPrint('[Gemini] 모든 모델 시도 실패 — 무료 티어 한도 초과이거나 지원 모델 없음');
    return null;
  }

  /// 자연어 입력을 파싱하여 할 일 데이터로 변환
  static Future<ParsedTodo?> parseNaturalLanguage(String input) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}년 ${today.month}월 ${today.day}일 (${_weekdayKo(today.weekday)})';

    final prompt = '''
오늘 날짜: $todayStr

사용자의 자연어 입력을 할 일 정보로 파싱하세요. 한국어 날짜 표현을 정확히 해석하세요.

날짜 표현 규칙:
- "오늘" → 오늘
- "내일" → 내일
- "모레" → 모레
- "다음 주 [요일]" → 다음 주 해당 요일
- "[N]일 후" → N일 후
- 날짜 언급 없으면 오늘

시간 표현:
- "12시" = "12:00"
- "오후 3시" = "15:00"
- "오전 9시" = "09:00"
- "[N]시 [M]분" = "HH:MM"

우선순위(priority):
- "급하게", "꼭", "중요", "마감", "제출" → HIGH
- 일반적인 할 일 → MEDIUM
- "가능하면", "여유" → LOW

난이도(difficulty):
- 시험, 발표, 프로젝트, 논문, 소감문, 에세이, 보고서 → HARD
- 일반 과제, 공부 → NORMAL
- 확인, 산책, 간단한 일 → EASY

카테고리(categoryId) - 하나만 선택:
study(공부/과제/시험), health(운동/헬스), personal(개인), work(업무), social(약속/모임), hobby(취미)

입력: "$input"

JSON으로만 응답:
{
  "title": "할 일 제목 (간결하게)",
  "date": "YYYY-MM-DD",
  "dueTime": "HH:MM 또는 null",
  "priority": "HIGH|MEDIUM|LOW",
  "difficulty": "EASY|NORMAL|HARD",
  "categoryId": "study|health|personal|work|social|hobby|null",
  "subtasks": ["서브태스크1", "서브태스크2"],
  "description": "마감시간 등 추가 정보 또는 null"
}
''';

    final result = await _call(prompt);
    if (result == null) return null;

    try {
      final dateStr = result['date'] as String;
      final date = DateTime.parse(dateStr);

      return ParsedTodo(
        title: result['title'] as String,
        date: date,
        dueTime: result['dueTime'] == 'null' ? null : result['dueTime'] as String?,
        priority: result['priority'] as String? ?? 'MEDIUM',
        difficulty: result['difficulty'] as String? ?? 'NORMAL',
        categoryId: result['categoryId'] == 'null' ? null : result['categoryId'] as String?,
        subtasks: (result['subtasks'] as List<dynamic>? ?? [])
            .map((s) => s.toString())
            .toList(),
        description: result['description'] == 'null' ? null : result['description'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// 할 일 제목으로 서브태스크 추천
  static Future<List<String>?> suggestSubtasks(String title) async {
    final prompt = '''
다음 할 일에 대해 실용적인 서브태스크 3~5개를 한국어로 추천하세요.
할 일: "$title"

JSON으로만 응답:
{"subtasks": ["서브태스크1", "서브태스크2", "서브태스크3"]}
''';

    final result = await _call(prompt);
    if (result == null) return null;

    final list = result['subtasks'] as List<dynamic>?;
    return list?.map((s) => s.toString()).toList();
  }

  /// 할 일 제목으로 난이도 자동 설정
  static Future<String?> analyzeDifficulty(String title) async {
    final prompt = '''
다음 할 일의 난이도를 EASY, NORMAL, HARD 중 하나로 판단하세요.
할 일: "$title"

JSON으로만 응답:
{"difficulty": "EASY|NORMAL|HARD"}
''';

    final result = await _call(prompt);
    return result?['difficulty'] as String?;
  }

  static String _weekdayKo(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }
}
