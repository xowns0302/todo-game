import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/todo_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/providers/todo_provider.dart';
import '../../../core/services/ai_service.dart';

class AddEditTodoSheet extends StatefulWidget {
  final DateTime selectedDate;
  final Todo? todo; // null = add mode

  const AddEditTodoSheet({super.key, required this.selectedDate, this.todo});

  @override
  State<AddEditTodoSheet> createState() => _AddEditTodoSheetState();
}

class _AddEditTodoSheetState extends State<AddEditTodoSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _priority;
  late String _difficulty;
  late String? _categoryId;
  late List<String> _subtaskTitles;
  final _subtaskCtrl = TextEditingController();
  bool _aiSubtaskLoading = false;
  bool _aiDifficultyLoading = false;

  bool get isEdit => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? 'MEDIUM';
    _difficulty = t?.difficulty ?? 'NORMAL';
    _categoryId = t?.categoryId;
    _subtaskTitles = t?.subtasks.map((s) => s.title).toList() ?? [];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subtaskCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final provider = context.read<TodoProvider>();
    if (isEdit) {
      final updated = widget.todo!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        priority: _priority,
        difficulty: _difficulty,
        categoryId: _categoryId,
        clearCategory: _categoryId == null,
      );
      provider.updateTodo(updated);
    } else {
      provider.addTodo(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        date: widget.selectedDate,
        priority: _priority,
        categoryId: _categoryId,
        difficulty: _difficulty,
        subtaskTitles: _subtaskTitles,
      );
    }
    Navigator.pop(context);
  }

  void _onTitleChanged(String value) {
    if (!isEdit && value.trim().isNotEmpty) {
      _updateDifficultyFromAi(value.trim());
    }
  }

  Future<void> _updateDifficultyFromAi(String title) async {
    setState(() => _aiDifficultyLoading = true);
    final difficulty = await AiService.analyzeDifficulty(title);
    if (mounted) setState(() {
      _difficulty = difficulty;
      _aiDifficultyLoading = false;
    });
  }

  void _addSubtask() {
    final text = _subtaskCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtaskTitles.add(text);
      _subtaskCtrl.clear();
    });
  }

  Future<void> _loadAiSubtasks() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _aiSubtaskLoading = true);
    final suggestions = await AiService.suggestSubtasks(_titleCtrl.text.trim());
    if (mounted) setState(() {
      _subtaskTitles = suggestions;
      _aiSubtaskLoading = false;
    });
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
            // Handle
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit ? '할 일 수정' : '할 일 추가',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            Text(
              DateFormat('yyyy년 M월 d일 (E)', 'ko').format(widget.selectedDate),
              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: !isEdit,
              onChanged: _onTitleChanged,
              decoration: _inputDecoration('할 일을 입력하세요...'),
            ),
            const SizedBox(height: 10),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: _inputDecoration('메모 (선택)'),
            ),
            const SizedBox(height: 16),

            // Priority
            _sectionLabel('우선순위'),
            const SizedBox(height: 8),
            Row(
              children: [
                _priorityChip('HIGH', '높음', const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _priorityChip('MEDIUM', '중간', const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _priorityChip('LOW', '낮음', const Color(0xFF22C55E)),
              ],
            ),
            const SizedBox(height: 16),

            // Difficulty
            _sectionLabel('난이도'),
            const SizedBox(height: 4),
            Row(
              children: [
                if (_aiDifficultyLoading) ...[
                  const SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 6),
                  const Text('AI 분석 중...', style: TextStyle(fontSize: 11, color: Color(0xFF8B5CF6))),
                ] else ...[
                  const Icon(Icons.auto_fix_high, size: 14, color: AppColors.mutedForeground),
                  const SizedBox(width: 4),
                  const Text('AI 자동 설정', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _difficultyChip('EASY', '쉬움', const Color(0xFF22C55E)),
                const SizedBox(width: 8),
                _difficultyChip('NORMAL', '보통', const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _difficultyChip('HARD', '어려움', const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 16),

            // Category
            _sectionLabel('카테고리'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _categoryChip(null, '없음', AppColors.mutedForeground),
                ...CategoryModel.defaults.map((c) =>
                    _categoryChipModel(c)),
              ],
            ),
            const SizedBox(height: 16),

            // Subtasks (add only mode)
            if (!isEdit) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel('서브태스크'),
                  TextButton.icon(
                    onPressed: (!_aiSubtaskLoading && _titleCtrl.text.trim().isNotEmpty)
                        ? _loadAiSubtasks
                        : null,
                    icon: _aiSubtaskLoading
                        ? const SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, size: 14),
                    label: Text(
                      _aiSubtaskLoading ? 'AI 분석 중...' : 'AI 추천',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._subtaskTitles.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, size: 16, color: AppColors.mutedForeground),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e.value, style: const TextStyle(fontSize: 14))),
                    GestureDetector(
                      onTap: () => setState(() => _subtaskTitles.removeAt(e.key)),
                      child: const Icon(Icons.close, size: 16, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              )),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskCtrl,
                      decoration: _inputDecoration('서브태스크 추가...'),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addSubtask,
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isEdit ? '수정' : '추가'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.foreground),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.mutedForeground),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      );

  Widget _priorityChip(String value, String label, Color color) {
    final selected = _priority == value;
    return GestureDetector(
      onTap: () => setState(() => _priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : AppColors.mutedForeground)),
      ),
    );
  }

  Widget _difficultyChip(String value, String label, Color color) {
    final selected = _difficulty == value;
    return GestureDetector(
      onTap: () => setState(() => _difficulty = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : AppColors.mutedForeground)),
      ),
    );
  }

  Widget _categoryChip(String? value, String label, Color color) {
    final selected = _categoryId == value;
    return GestureDetector(
      onTap: () => setState(() => _categoryId = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : AppColors.mutedForeground)),
      ),
    );
  }

  Widget _categoryChipModel(CategoryModel cat) {
    final selected = _categoryId == cat.id;
    return GestureDetector(
      onTap: () => setState(() => _categoryId = cat.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cat.color.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? cat.color : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat.icon, size: 14, color: selected ? cat.color : AppColors.mutedForeground),
            const SizedBox(width: 4),
            Text(cat.name,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? cat.color : AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}
