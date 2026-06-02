import 'gemini_service.dart';

// Heuristic fallbacks when Gemini API is unavailable
class AiService {
  static String autoSetDifficultyFallback(String title) {
    final lower = title.toLowerCase();
    const hardKeywords = ['시험', '발표', '프로젝트', '논문', '리포트', '제출', '최종', '마감', '소감문', '에세이'];
    const easyKeywords = ['확인', '읽기', '검토', '메모', '정리', '산책', '청소'];

    if (hardKeywords.any((k) => lower.contains(k)) || title.length > 20) return 'HARD';
    if (easyKeywords.any((k) => lower.contains(k)) || title.length <= 8) return 'EASY';
    return 'NORMAL';
  }

  static List<String> suggestSubtasksFallback(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('과제') || lower.contains('리포트') || lower.contains('보고서') ||
        lower.contains('소감문') || lower.contains('에세이')) {
      return ['주제 조사하기', '초안 작성하기', '검토 및 수정', '최종 제출'];
    }
    if (lower.contains('시험') || lower.contains('공부') || lower.contains('준비')) {
      return ['범위 확인하기', '핵심 내용 정리', '문제 풀기', '최종 복습'];
    }
    if (lower.contains('발표') || lower.contains('프레젠테이션')) {
      return ['자료 조사하기', '발표 자료 만들기', '발표 연습하기'];
    }
    if (lower.contains('프로젝트') || lower.contains('개발')) {
      return ['요구사항 분석', '설계하기', '구현하기', '테스트하기'];
    }
    if (lower.contains('운동') || lower.contains('헬스')) {
      return ['워밍업 (5분)', '본 운동', '쿨다운 & 스트레칭'];
    }
    final parts = title.split(RegExp(r'[,，、&]|그리고| and '));
    if (parts.length > 1) return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    return ['준비하기', '실행하기', '마무리하기'];
  }

  /// Gemini API → 실패 시 휴리스틱 폴백
  static Future<String> analyzeDifficulty(String title) async {
    final result = await GeminiService.analyzeDifficulty(title);
    return result ?? autoSetDifficultyFallback(title);
  }

  /// Gemini API → 실패 시 휴리스틱 폴백
  static Future<List<String>> suggestSubtasks(String title) async {
    final result = await GeminiService.suggestSubtasks(title);
    return result ?? suggestSubtasksFallback(title);
  }

  static int calculateFocusXp(int durationMinutes) {
    if (durationMinutes <= 0) return 0;
    if (durationMinutes <= 10) return (durationMinutes * 0.5).round();
    if (durationMinutes <= 25) return durationMinutes;
    if (durationMinutes <= 50) return (durationMinutes * 1.5).round();
    return (durationMinutes * 2.0).round();
  }
}
