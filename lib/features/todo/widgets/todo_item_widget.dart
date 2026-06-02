import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/todo_model.dart';
import '../../../core/models/category_model.dart';

class TodoItemWidget extends StatelessWidget {
  final Todo todo;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onDelete,
    required this.onTap,
  });

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
      case 'HARD': return '어려움';
      case 'EASY': return '쉬움';
      default: return '보통';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool completed = todo.completed;
    final category = CategoryModel.findById(todo.categoryId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: completed ? AppColors.primary : AppColors.border,
            width: completed ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 완료 상태 아이콘 (비대화형)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: completed ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: completed ? AppColors.primary : AppColors.mutedForeground,
                  width: 2,
                ),
              ),
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : const Icon(Icons.photo_camera_outlined,
                      color: AppColors.mutedForeground, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: completed ? AppColors.mutedForeground : AppColors.foreground,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (category != null)
                        _chip(category.name, category.color),
                      _chip(_priorityLabel(), _priorityColor()),
                      _chip(_difficultyLabel(), _difficultyColor()),
                      if (todo.subtasks.isNotEmpty)
                        _chip(
                          '${todo.subtasks.where((s) => s.completed).length}/${todo.subtasks.length}',
                          AppColors.mutedForeground,
                          icon: Icons.checklist,
                        ),
                      if (todo.totalFocusMinutes > 0)
                        _chip(
                          '${todo.totalFocusMinutes}분',
                          const Color(0xFF8B5CF6),
                          icon: Icons.timer_outlined,
                        ),
                      if (todo.proofPath != null)
                        _chip(
                          todo.proofIsVideo ? '영상 인증' : '사진 인증',
                          const Color(0xFF14B8A6),
                          icon: todo.proofIsVideo ? Icons.videocam : Icons.photo_camera,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline, color: AppColors.destructive, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
