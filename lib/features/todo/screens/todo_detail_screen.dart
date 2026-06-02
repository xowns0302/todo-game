import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/todo_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/providers/todo_provider.dart';
import '../../../core/providers/character_provider.dart';
import '../widgets/add_edit_todo_sheet.dart';
import 'focus_timer_screen.dart';

class TodoDetailScreen extends StatelessWidget {
  final String todoId;

  const TodoDetailScreen({super.key, required this.todoId});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, _) {
        final todo = provider.getTodoById(todoId);
        if (todo == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('할 일')),
            body: const Center(child: Text('삭제된 할 일입니다')),
          );
        }
        return _TodoDetailView(todo: todo);
      },
    );
  }
}

class _TodoDetailView extends StatelessWidget {
  final Todo todo;

  const _TodoDetailView({required this.todo});

  Color _priorityColor() {
    switch (todo.priority) {
      case 'HIGH': return const Color(0xFFEF4444);
      case 'LOW': return const Color(0xFF22C55E);
      default: return const Color(0xFFF59E0B);
    }
  }

  String _priorityLabel() {
    switch (todo.priority) {
      case 'HIGH': return '높음';
      case 'LOW': return '낮음';
      default: return '중간';
    }
  }

  Color _difficultyColor() {
    switch (todo.difficulty) {
      case 'HARD': return const Color(0xFFEF4444);
      case 'EASY': return const Color(0xFF22C55E);
      default: return const Color(0xFF3B82F6);
    }
  }

  String _difficultyLabel() {
    switch (todo.difficulty) {
      case 'HARD': return '어려움 (+40 XP)';
      case 'EASY': return '쉬움 (+10 XP)';
      default: return '보통 (+20 XP)';
    }
  }

  Future<String> _copyToDocuments(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final proofsDir = Directory('${dir.path}/proofs');
    await proofsDir.create(recursive: true);
    final ext = sourcePath.split('.').last;
    final filename = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final destPath = '${proofsDir.path}/$filename';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<void> _pickProof(BuildContext context, TodoProvider provider) async {
    final picker = ImagePicker();
    final charProvider = context.read<CharacterProvider>();
    final wasCompleted = todo.completed;
    final difficulty = todo.difficulty;
    final todoId = todo.id;
    final hasProof = todo.proofPath != null;

    Future<void> autoComplete() async {
      if (!wasCompleted) {
        await provider.toggleTodo(todoId);
        final gold = difficulty == 'HARD' ? 20 : difficulty == 'EASY' ? 5 : 10;
        await charProvider.onTodoCompleted(difficulty: difficulty, gold: gold);
      }
    }

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.primary),
              title: const Text('카메라로 사진 촬영'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                if (file == null || !context.mounted) return;
                final path = await _copyToDocuments(file.path);
                await provider.setProof(todoId, path, false);
                await autoComplete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppColors.primary),
              title: const Text('카메라로 동영상 촬영'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(minutes: 2));
                if (file == null || !context.mounted) return;
                final path = await _copyToDocuments(file.path);
                await provider.setProof(todoId, path, true);
                await autoComplete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('갤러리에서 선택'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (file == null || !context.mounted) return;
                final path = await _copyToDocuments(file.path);
                await provider.setProof(todoId, path, false);
                await autoComplete();
              },
            ),
            if (hasProof)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.destructive),
                title: const Text('인증 삭제 (완료 취소)', style: TextStyle(color: AppColors.destructive)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await provider.clearProof(todoId);
                  if (wasCompleted) await provider.toggleTodo(todoId);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSubtask(BuildContext context, TodoProvider provider) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('서브태스크 추가'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '서브태스크 내용...'),
          onSubmitted: (_) {
            if (ctrl.text.trim().isNotEmpty) {
              provider.addSubtask(todo.id, ctrl.text.trim());
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.addSubtask(todo.id, ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TodoProvider>();
    final category = CategoryModel.findById(todo.categoryId);
    final subtaskDone = todo.subtasks.where((s) => s.completed).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('할 일 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddEditTodoSheet(selectedDate: todo.date, todo: todo),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('삭제 확인'),
                  content: const Text('이 할 일을 삭제할까요?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('삭제', style: TextStyle(color: AppColors.destructive)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                provider.deleteTodo(todo.id);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title card
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: todo.completed ? AppColors.mutedForeground : AppColors.foreground,
                            decoration: todo.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      _completionBadge(),
                    ],
                  ),
                  if (todo.description != null) ...[
                    const SizedBox(height: 8),
                    Text(todo.description!,
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _infoChip(Icons.calendar_today,
                          DateFormat('M월 d일 (E)', 'ko').format(todo.date),
                          AppColors.mutedForeground),
                      if (category != null)
                        _infoChip(category.icon, category.name, category.color),
                      _infoChip(Icons.flag_outlined, _priorityLabel(), _priorityColor()),
                      _infoChip(Icons.bolt, _difficultyLabel(), _difficultyColor()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Completion status (proof photo required)
            _card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.completed ? '완료됨 🎉' : '미완료',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: todo.completed ? AppColors.primary : AppColors.foreground,
                          ),
                        ),
                        if (todo.completedAt != null)
                          Text(
                            DateFormat('M월 d일 HH:mm', 'ko').format(todo.completedAt!),
                            style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          todo.completed
                              ? '인증 사진 삭제 시 완료가 취소됩니다'
                              : '아래 인증 사진을 등록하면 자동 완료됩니다',
                          style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                        ),
                        Text(
                          '완료 시 +${todo.completionXp} XP',
                          style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    todo.completed ? Icons.check_circle : Icons.lock_outline,
                    color: todo.completed ? AppColors.primary : AppColors.mutedForeground,
                    size: 36,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Subtasks
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.checklist, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          const Text('서브태스크',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          if (todo.subtasks.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('$subtaskDone/${todo.subtasks.length}',
                                style: const TextStyle(
                                    color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
                        padding: EdgeInsets.zero,
                        onPressed: () => _addSubtask(context, provider),
                      ),
                    ],
                  ),
                  if (todo.subtasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('서브태스크가 없습니다',
                          style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                    )
                  else
                    ...todo.subtasks.map((subtask) => Consumer<TodoProvider>(
                          builder: (context, provider, _) => InkWell(
                            onTap: () => provider.toggleSubtask(todo.id, subtask.id),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: subtask.completed ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: subtask.completed
                                            ? AppColors.primary
                                            : AppColors.mutedForeground,
                                        width: 2,
                                      ),
                                    ),
                                    child: subtask.completed
                                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      subtask.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: subtask.completed
                                            ? AppColors.mutedForeground
                                            : AppColors.foreground,
                                        decoration: subtask.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: AppColors.mutedForeground),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => provider.deleteSubtask(todo.id, subtask.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Proof section (세트로그)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.photo_camera, size: 18, color: Color(0xFF14B8A6)),
                          SizedBox(width: 6),
                          Text('완료 인증',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          SizedBox(width: 6),
                          Text('+5 XP', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 11)),
                        ],
                      ),
                      Consumer<TodoProvider>(
                        builder: (context, provider, _) => TextButton(
                          onPressed: () => _pickProof(context, provider),
                          child: Text(todo.proofPath != null ? '변경' : '추가',
                              style: const TextStyle(color: AppColors.primary)),
                        ),
                      ),
                    ],
                  ),
                  if (todo.proofPath != null)
                    _buildProofPreview()
                  else
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.mutedForeground, size: 28),
                            SizedBox(height: 4),
                            Text('사진 또는 영상으로 완료를 인증하세요',
                                style: TextStyle(
                                    color: AppColors.mutedForeground, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Focus sessions
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      const Text('집중 기록',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      if (todo.totalFocusMinutes > 0) ...[
                        const SizedBox(width: 8),
                        Text('총 ${todo.totalFocusMinutes}분 (${todo.focusXp} XP)',
                            style: const TextStyle(
                                color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (todo.focusSessions.isEmpty)
                    const Text('아직 집중 기록이 없습니다',
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 13))
                  else
                    ...todo.focusSessions.map((s) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${s.durationMinutes}분',
                                    style: const TextStyle(
                                        color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Text('+${s.xpEarned} XP',
                                  style: const TextStyle(
                                      color: Color(0xFF8B5CF6), fontSize: 12)),
                              const Spacer(),
                              Text(DateFormat('M/d HH:mm').format(s.timestamp),
                                  style: const TextStyle(
                                      color: AppColors.mutedForeground, fontSize: 11)),
                            ],
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Start focus timer button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FocusTimerScreen(todoId: todo.id, todoTitle: todo.title),
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('집중 타이머 시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildProofPreview() {
    if (todo.proofIsVideo) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
              SizedBox(height: 8),
              Text('동영상 인증', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    final file = File(todo.proofPath!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        file,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 80,
          color: AppColors.muted,
          child: const Center(
              child: Icon(Icons.broken_image, color: AppColors.mutedForeground)),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: child,
      );

  Widget _completionBadge() {
    if (!todo.completed) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('완료',
          style: TextStyle(
              color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
