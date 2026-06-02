import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/todo_provider.dart';
import '../widgets/todo_item_widget.dart';
import '../widgets/add_edit_todo_sheet.dart';
import '../widgets/nl_todo_sheet.dart';
import 'todo_detail_screen.dart';
import '../../lms/lms_connect_sheet.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  DateTime _selectedDate = DateTime.now();

  String _formatDate(DateTime date) =>
      DateFormat('yyyy년 M월 d일 (E)', 'ko').format(date);

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showAddTodo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTodoSheet(selectedDate: _selectedDate),
    );
  }

  void _showLmsConnect() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LmsConnectSheet(),
    );
  }

  void _showNlInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NlTodoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, _) {
        final todos = provider.getTodosForDate(_selectedDate);
        final completed = todos.where((t) => t.completed).length;
        final total = todos.length;
        final progress = total > 0 ? completed / total : 0.0;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildProgressCard(completed, total, progress),
                        const SizedBox(height: 12),
                        if (todos.isEmpty)
                          _buildEmptyState()
                        else
                          ...todos.map((todo) => Dismissible(
                                key: Key(todo.id),
                                direction: DismissDirection.startToEnd,
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Color(0xFF3B82F6)),
                                      SizedBox(width: 8),
                                      Text('내일로 미루기',
                                          style: TextStyle(
                                              color: Color(0xFF3B82F6),
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                confirmDismiss: (_) async {
                                  if (todo.completed) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('완료된 항목은 미룰 수 없습니다'),
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return false;
                                  }
                                  return true;
                                },
                                onDismissed: (_) async {
                                  final originalDate = todo.date;
                                  await provider.postponeTodo(todo.id);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('"${todo.title}" 내일로 미뤘습니다'),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: '취소',
                                        onPressed: () {
                                          final t = provider.getTodoById(todo.id);
                                          if (t != null) provider.changeTodoDate(todo.id, originalDate);
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: TodoItemWidget(
                                    todo: todo,
                                    onDelete: () => provider.deleteTodo(todo.id),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TodoDetailScreen(todoId: todo.id),
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 24,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // AI 자연어 버튼
                    FloatingActionButton.extended(
                      heroTag: 'nl_fab',
                      onPressed: _showNlInput,
                      backgroundColor: const Color(0xFF8B5CF6),
                      icon: const Text('✨', style: TextStyle(fontSize: 16)),
                      label: const Text('AI로 추가',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    // 일반 추가 버튼
                    FloatingActionButton(
                      heroTag: 'add_fab',
                      onPressed: _showAddTodo,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'TODO',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showLmsConnect,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎓', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text('LMS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(
                    () => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Column(
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (_isToday(_selectedDate))
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('오늘', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                ],
              ),
              IconButton(
                onPressed: () => setState(
                    () => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedDate = DateTime.now()),
              icon: const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              label: const Text('오늘로 이동', style: TextStyle(color: Colors.white70)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('오늘 진행률', style: TextStyle(color: AppColors.mutedForeground)),
              Text(
                '$completed / $total',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.muted,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          if (total > 0 && completed == total) ...[
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🎉 ', style: TextStyle(fontSize: 16)),
                Text('모든 할 일 완료!',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.mutedForeground),
            SizedBox(height: 16),
            Text('이 날의 할 일이 없습니다', style: TextStyle(color: AppColors.mutedForeground)),
            SizedBox(height: 4),
            Text('+ 버튼을 눌러 추가해보세요!',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
