import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/services/lms_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';

/// Raw data inspector — shows everything Canvas returns before any filtering.
class LmsDebugSheet extends StatefulWidget {
  const LmsDebugSheet({super.key});

  @override
  State<LmsDebugSheet> createState() => _LmsDebugSheetState();
}

class _RawAssignment {
  final int id;
  final String courseName;
  final String name;
  final String? dueAt;
  final List<String> submissionTypes;
  final String? workflowState; // submission state
  final bool submitted;

  const _RawAssignment({
    required this.id,
    required this.courseName,
    required this.name,
    this.dueAt,
    required this.submissionTypes,
    this.workflowState,
    required this.submitted,
  });
}

enum _Status { idle, loading, done, error }

class _LmsDebugSheetState extends State<LmsDebugSheet> {
  _Status _status = _Status.idle;
  String? _error;
  List<LmsCourse> _courses = [];
  List<_RawAssignment> _all = [];
  String _filterCourse = '전체';
  String _filterType = '전체';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await StorageService.loadLmsToken();
    if (token == null || token.isEmpty) {
      setState(() { _status = _Status.error; _error = '저장된 토큰이 없습니다.\nLMS 연동 탭에서 먼저 토큰을 입력하세요.'; });
      return;
    }

    setState(() => _status = _Status.loading);

    try {
      final courses = await LmsService.fetchCourses(token);
      final raw = await _fetchAllRaw(token, courses);

      setState(() {
        _courses = courses;
        _all = raw;
        _status = _Status.done;
      });
    } on DioException catch (e) {
      setState(() {
        _status = _Status.error;
        _error = 'HTTP ${e.response?.statusCode}: ${e.response?.data?['errors']?[0]?['message'] ?? e.message}';
      });
    } catch (e) {
      setState(() { _status = _Status.error; _error = '$e'; });
    }
  }

  /// Fetches ALL assignments (no submission filter, no date filter) for inspection.
  Future<List<_RawAssignment>> _fetchAllRaw(String token, List<LmsCourse> courses) async {
    final result = <_RawAssignment>[];
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 25)));
    final authOpt = Options(headers: {'Authorization': 'Bearer $token'});
    const base = 'https://learning.hanyang.ac.kr/api/v1';

    for (final course in courses) {
      // ── Assignments ──────────────────────────────────────────────────────
      String? next = '$base/courses/${course.id}/assignments?per_page=100&include[]=submission&order_by=due_at';
      while (next != null) {
        final resp = await dio.get(next, options: authOpt);
        for (final a in resp.data as List) {
          final types = (a['submission_types'] as List?)?.map((s) => s.toString()).toList() ?? [];
          final sub = a['submission'] as Map?;
          final wf = sub?['workflow_state'] as String?;
          result.add(_RawAssignment(
            id: a['id'] as int,
            courseName: course.name,
            name: a['name'] as String,
            dueAt: a['due_at'] as String?,
            submissionTypes: types,
            workflowState: wf,
            submitted: wf != null && ['submitted', 'graded', 'pending_review'].contains(wf),
          ));
        }
        next = _nextLink(resp.headers.value('link'));
      }

      // ── Quizzes ──────────────────────────────────────────────────────────
      try {
        String? qNext = '$base/courses/${course.id}/quizzes?per_page=100';
        while (qNext != null) {
          final resp = await dio.get(qNext, options: authOpt);
          for (final q in resp.data as List) {
            result.add(_RawAssignment(
              id: q['id'] as int,
              courseName: course.name,
              name: q['title'] as String? ?? '(제목없음)',
              dueAt: q['due_at'] as String?,
              submissionTypes: ['quiz'],
              workflowState: null,
              submitted: false,
            ));
          }
          qNext = _nextLink(resp.headers.value('link'));
        }
      } catch (_) {}
    }

    result.sort((a, b) {
      if (a.dueAt == null && b.dueAt == null) return 0;
      if (a.dueAt == null) return 1;
      if (b.dueAt == null) return -1;
      return a.dueAt!.compareTo(b.dueAt!);
    });
    return result;
  }

  String? _nextLink(String? header) {
    if (header == null) return null;
    for (final part in header.split(',')) {
      if (part.contains('rel="next"')) {
        final m = RegExp(r'<([^>]+)>').firstMatch(part.trim());
        return m?.group(1);
      }
    }
    return null;
  }

  List<_RawAssignment> get _filtered {
    return _all.where((a) {
      if (_filterCourse != '전체' && a.courseName != _filterCourse) return false;
      if (_filterType == '미제출만' && a.submitted) return false;
      if (_filterType == '제출완료만' && !a.submitted) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildTopBar(),
          if (_status == _Status.loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_status == _Status.error) Expanded(child: Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.destructive)),
          ))),
          if (_status == _Status.done) ...[
            _buildFilters(),
            _buildSummaryBar(),
            Expanded(child: _buildList()),
          ],
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('🔍 LMS 원본 데이터', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh, size: 20), tooltip: '다시 불러오기'),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildTopBar() {
    if (_status != _Status.done) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('총 ${_all.length}개', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(' (${_courses.length}개 과목)', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              final text = _all.map((a) =>
                '${a.courseName} | ${a.name} | due:${a.dueAt ?? "없음"} | types:${a.submissionTypes.join(",")} | state:${a.workflowState ?? "없음"}'
              ).join('\n');
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('전체 목록이 클립보드에 복사됐습니다')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('전체 복사', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final courseNames = ['전체', ..._courses.map((c) => c.name)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _dropdown('과목', courseNames, _filterCourse, (v) => setState(() => _filterCourse = v)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _dropdown('필터', ['전체', '미제출만', '제출완료만'], _filterType, (v) => setState(() => _filterType = v)),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String value, void Function(String) onChange) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
      ),
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: (v) { if (v != null) onChange(v); },
    );
  }

  Widget _buildSummaryBar() {
    final filtered = _filtered;
    final submitted = filtered.where((a) => a.submitted).length;
    final unsubmitted = filtered.length - submitted;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _summaryChip('표시', '${filtered.length}', AppColors.primary),
          const SizedBox(width: 12),
          _summaryChip('미제출', '$unsubmitted', const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          _summaryChip('제출완료', '$submitted', const Color(0xFF22C55E)),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String count, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ', style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
      Text(count, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) {
      return const Center(child: Text('항목이 없습니다', style: TextStyle(color: AppColors.mutedForeground)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _buildCard(list[i]),
    );
  }

  Widget _buildCard(_RawAssignment a) {
    final dueAt = a.dueAt != null ? DateTime.parse(a.dueAt!).toLocal() : null;
    final dueStr = dueAt != null
        ? DateFormat('M/d(E) HH:mm', 'ko').format(dueAt)
        : '마감일 없음';
    final isPast = dueAt != null && dueAt.isBefore(DateTime.now());
    final stateColor = a.submitted
        ? const Color(0xFF22C55E)
        : isPast
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);
    final stateLabel = a.submitted ? '제출완료' : isPast ? '기한초과' : '미제출';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: a.submitted ? const Color(0xFF22C55E).withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: a.submitted ? TextDecoration.lineThrough : null,
                      color: a.submitted ? AppColors.mutedForeground : AppColors.foreground,
                    )),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(stateLabel,
                    style: TextStyle(fontSize: 10, color: stateColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              Text(a.courseName, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
              Text(dueStr,
                  style: TextStyle(
                      fontSize: 11,
                      color: isPast && !a.submitted ? const Color(0xFFEF4444) : AppColors.mutedForeground,
                      fontWeight: isPast && !a.submitted ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
          const SizedBox(height: 6),
          // Raw info row
          Wrap(
            spacing: 6, runSpacing: 4,
            children: [
              ...a.submissionTypes.map((t) => _rawChip(t, const Color(0xFF3B82F6))),
              if (a.workflowState != null)
                _rawChip(a.workflowState!, const Color(0xFF8B5CF6)),
              _rawChip('id:${a.id}', AppColors.mutedForeground),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rawChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontFamily: 'monospace')),
    );
  }
}
