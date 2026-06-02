import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/category_model.dart';
import '../../../core/providers/todo_provider.dart';
import '../../../core/services/gemini_service.dart';

class NlTodoSheet extends StatefulWidget {
  const NlTodoSheet({super.key});

  @override
  State<NlTodoSheet> createState() => _NlTodoSheetState();
}

class _NlTodoSheetState extends State<NlTodoSheet> {
  final _ctrl = TextEditingController();
  bool _isLoading = false;
  ParsedTodo? _parsed;
  String? _errorMsg;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final input = _ctrl.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isLoading = true;
      _parsed = null;
      _errorMsg = null;
    });

    // API 키 체크
    String? apiKey;
    try {
      final dotenv = await _getDotenvKey();
      apiKey = dotenv;
    } catch (_) {}

    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) setState(() {
        _isLoading = false;
        _errorMsg = 'API 키를 불러올 수 없습니다. .env 파일을 확인하세요.';
      });
      return;
    }

    final result = await GeminiService.parseNaturalLanguage(input);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result != null) {
        _parsed = result;
      } else {
        _errorMsg = 'AI 분석 실패.\n터미널 로그를 확인하거나\naistudio.google.com에서 사용량을 확인하세요.';
      }
    });
  }

  Future<String?> _getDotenvKey() async {
    try {
      final key = GeminiService.apiKey;
      return key.isNotEmpty ? key : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirm() async {
    if (_parsed == null) return;
    final provider = context.read<TodoProvider>();
    await provider.addTodo(
      title: _parsed!.title,
      description: _parsed!.description,
      date: _parsed!.date,
      priority: _parsed!.priority,
      categoryId: _parsed!.categoryId,
      difficulty: _parsed!.difficulty,
      subtaskTitles: _parsed!.subtasks,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                Text('✨', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Text('AI Helper',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '"내일 12시까지 사회봉사 소감문 작성" 처럼 자연스럽게 입력하세요',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Input field
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: '예) 다음 주 금요일 오후 6시까지 자료구조 과제 제출',
                hintStyle: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              ),
              onSubmitted: (_) => _analyze(),
            ),
            const SizedBox(height: 12),

            // Analyze button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyze,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'AI 분석 중...' : 'AI 분석'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // Error
            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.destructive, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMsg!,
                          style: const TextStyle(
                              color: AppColors.destructive, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            // Parsed result preview
            if (_parsed != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('분석 결과',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: AppColors.mutedForeground)),
              const SizedBox(height: 10),
              _buildPreviewCard(_parsed!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _parsed = null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('다시 입력'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('등록하기'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ParsedTodo p) {
    final category = CategoryModel.findById(p.categoryId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              const Icon(Icons.task_alt, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(p.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date & time
          _previewRow(
            Icons.calendar_today,
            DateFormat('yyyy년 M월 d일 (E)', 'ko').format(p.date) +
                (p.dueTime != null ? ' ${p.dueTime}까지' : ''),
            AppColors.primary,
          ),
          if (p.description != null) ...[
            const SizedBox(height: 6),
            _previewRow(Icons.notes, p.description!, AppColors.mutedForeground),
          ],
          const SizedBox(height: 8),

          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (category != null)
                _tag(category.name, category.color, icon: category.icon),
              _tag(_priorityLabel(p.priority), _priorityColor(p.priority)),
              _tag(_difficultyLabel(p.difficulty), _difficultyColor(p.difficulty)),
            ],
          ),

          // Subtasks
          if (p.subtasks.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.checklist, size: 14, color: AppColors.mutedForeground),
                const SizedBox(width: 4),
                Text('서브태스크 ${p.subtasks.length}개',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            ...p.subtasks.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 5, color: AppColors.mutedForeground),
                      const SizedBox(width: 8),
                      Text(s, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _previewRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: color)),
        ),
      ],
    );
  }

  Widget _tag(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'HIGH': return const Color(0xFFEF4444);
      case 'LOW': return const Color(0xFF22C55E);
      default: return const Color(0xFFF59E0B);
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'HIGH': return '우선순위 높음';
      case 'LOW': return '우선순위 낮음';
      default: return '우선순위 중간';
    }
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'HARD': return const Color(0xFFEF4444);
      case 'EASY': return const Color(0xFF22C55E);
      default: return const Color(0xFF3B82F6);
    }
  }

  String _difficultyLabel(String d) {
    switch (d) {
      case 'HARD': return '난이도 어려움';
      case 'EASY': return '난이도 쉬움';
      default: return '난이도 보통';
    }
  }
}
