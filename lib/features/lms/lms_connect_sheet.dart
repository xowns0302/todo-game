import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/providers/todo_provider.dart';
import '../../core/services/lms_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import 'lms_debug_sheet.dart';

class LmsConnectSheet extends StatefulWidget {
  const LmsConnectSheet({super.key});

  @override
  State<LmsConnectSheet> createState() => _LmsConnectSheetState();
}

enum _Step { token, loading, preview, done }

class _LmsConnectSheetState extends State<LmsConnectSheet> {
  final _tokenCtrl = TextEditingController();
  _Step _step = _Step.token;
  String? _error;

  List<LmsCourse> _courses = [];
  List<LmsAssignment> _assignments = [];
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    // Pre-fill saved token
    StorageService.loadLmsToken().then((t) {
      if (t != null && mounted) _tokenCtrl.text = t;
    });
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      setState(() => _error = '토큰을 입력하세요.');
      return;
    }

    setState(() { _step = _Step.loading; _error = null; });

    final provider = context.read<TodoProvider>();

    try {
      final courses = await LmsService.fetchCourses(token);
      final assignments = await LmsService.fetchUnsubmitted(token, courses);

      // Filter out assignments that already exist as todos
      final fresh = assignments.where((a) => !provider.hasLmsTodo('${a.id}')).toList();

      await StorageService.saveLmsToken(token);

      if (!mounted) return;
      setState(() {
        _courses = courses;
        _assignments = fresh;
        _selected.addAll(fresh.map((a) => a.id));
        _step = _Step.preview;
      });
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (!mounted) return;
      setState(() {
        _step = _Step.token;
        _error = code == 401 || code == 403
            ? '토큰이 올바르지 않습니다. Canvas에서 다시 발급받아 주세요.'
            : '연결 실패 (HTTP $code). 네트워크를 확인하세요.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _step = _Step.token; _error = '오류: $e'; });
    }
  }

  Future<void> _import() async {
    final toImport = _assignments.where((a) => _selected.contains(a.id)).toList();
    if (toImport.isEmpty) return;

    setState(() => _step = _Step.loading);

    final provider = context.read<TodoProvider>();
    for (final a in toImport) {
      final date = a.dueAt!;
      final dateOnly = DateTime(date.year, date.month, date.day);
      final timeStr = DateFormat('HH:mm').format(date);
      await provider.addTodo(
        title: '${a.typeEmoji} ${a.name}',
        description: '[${a.courseName}] ${a.typeLabel} · $timeStr까지',
        date: dateOnly,
        priority: a.priority,
        categoryId: 'study',
        difficulty: a.difficulty,
        lmsId: '${a.id}',
      );
    }

    if (!mounted) return;
    setState(() => _step = _Step.done);
  }

  Widget _buildSheetHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const Row(
          children: [
            Text('🎓', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('LMS 연동',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Canvas (learning.hanyang.ac.kr) 과제를 자동으로 할 일에 추가합니다.',
          style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Preview 단계: 전체 높이 차지 + 리스트 스크롤 + 버튼 하단 고정
    if (_step == _Step.preview) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildSheetHeader(),
            ),
            Expanded(child: _buildPreviewList()),
            _buildPreviewFooter(bottomInset),
          ],
        ),
      );
    }

    // 나머지 단계: 콘텐츠 크기에 맞게 축소
    return Container(
      padding: EdgeInsets.only(
        top: 24, left: 20, right: 20,
        bottom: bottomInset + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSheetHeader(),
            if (_step == _Step.loading) _buildLoading(),
            if (_step == _Step.token) _buildTokenStep(),
            if (_step == _Step.done) _buildDone(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Canvas에서 과제 불러오는 중...'),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // How-to hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('토큰 발급 방법',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 6),
              Text(
                '1. learning.hanyang.ac.kr 접속 → 로그인\n'
                '2. 우측 상단 계정 아이콘 → 설정(Settings)\n'
                '3. Approved Integrations → New Access Token\n'
                '4. 생성된 토큰 복사 후 아래에 붙여넣기',
                style: TextStyle(fontSize: 12, color: AppColors.mutedForeground, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _tokenCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Canvas API 토큰',
            hintText: '토큰을 붙여넣으세요',
            hintStyle: const TextStyle(color: AppColors.mutedForeground),
            filled: true,
            fillColor: AppColors.background,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () => _tokenCtrl.clear(),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.destructive, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.destructive, fontSize: 12)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _connect,
            icon: const Icon(Icons.sync),
            label: const Text('과제 불러오기', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const LmsDebugSheet(),
            ),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('원본 데이터 확인'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // 스크롤 가능한 리스트 영역
  Widget _buildPreviewList() {
    if (_assignments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✅', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('새로운 미제출 과제가 없습니다!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('이미 모든 과제를 제출했거나\n오늘 이후 마감이 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedForeground)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 고정 헤더 (타이틀 + 전체선택 + 과목칩)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('미제출 ${_assignments.length}개 발견',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      if (_selected.length == _assignments.length) {
                        _selected.clear();
                      } else {
                        _selected.addAll(_assignments.map((a) => a.id));
                      }
                    }),
                    child: Text(
                      _selected.length == _assignments.length ? '전체 해제' : '전체 선택',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: _courses.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(c.name,
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
            ],
          ),
        ),
        // 스크롤 과제 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            itemCount: _assignments.length,
            itemBuilder: (_, i) => _buildAssignmentItem(_assignments[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentItem(LmsAssignment a) {
    final isSelected = _selected.contains(a.id);
    final dueStr = a.dueAt != null
        ? DateFormat('M월 d일 (E) HH:mm까지', 'ko').format(a.dueAt!)
        : '마감일 없음';
    final daysLeft = a.dueAt?.difference(DateTime.now()).inDays ?? 99;
    final urgentColor = daysLeft <= 3
        ? const Color(0xFFEF4444)
        : daysLeft <= 7
            ? const Color(0xFFF59E0B)
            : AppColors.mutedForeground;

    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) _selected.remove(a.id);
        else _selected.add(a.id);
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.mutedForeground,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _typeBadge(a.itemType),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(a.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(a.courseName,
                            style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const Text(' · ', style: TextStyle(color: AppColors.mutedForeground)),
                      Text(dueStr,
                          style: TextStyle(fontSize: 11, color: urgentColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _priorityBadge(a.priority),
          ],
        ),
      ),
    );
  }

  // 하단 고정 버튼 영역
  Widget _buildPreviewFooter(double bottomInset) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 16),
      child: _assignments.isEmpty
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('닫기'),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = _Step.token),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('다시 연결'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selected.isEmpty ? null : _import,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _selected.isEmpty ? '선택 없음' : '${_selected.length}개 할 일로 추가',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('할 일 추가 완료!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${_assignments.where((a) => _selected.contains(a.id)).length}개의 Canvas 과제가\n할 일 목록에 추가됐습니다.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('닫기', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(LmsItemType type) {
    final (color, label) = switch (type) {
      LmsItemType.exam   => (const Color(0xFFEF4444), '시험'),
      LmsItemType.quiz   => (const Color(0xFF8B5CF6), '퀴즈'),
      LmsItemType.assignment => (const Color(0xFF3B82F6), '과제'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _priorityBadge(String priority) {
    final color = priority == 'HIGH'
        ? const Color(0xFFEF4444)
        : priority == 'LOW'
            ? const Color(0xFF22C55E)
            : const Color(0xFFF59E0B);
    final label = priority == 'HIGH' ? '긴급' : priority == 'LOW' ? '여유' : '보통';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
