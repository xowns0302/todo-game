import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/todo_provider.dart';
import '../widgets/todo_item_widget.dart';
import '../widgets/add_edit_todo_sheet.dart';
import 'todo_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  List<DateTime?> _buildCalendarDays() {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final lastDay = DateTime(_month.year, _month.month + 1, 0);
    final startOffset = firstDay.weekday % 7; // 0=Sun, 6=Sat
    final days = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) days.add(null);
    for (int d = 1; d <= lastDay.day; d++) {
      days.add(DateTime(_month.year, _month.month, d));
    }
    // Pad to complete rows
    while (days.length % 7 != 0) days.add(null);
    return days;
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Color _cellColor(double ratio, int count) {
    if (count == 0) return Colors.transparent;
    if (ratio <= 0) return const Color(0xFFFFE4E4); // has todos but none done
    if (ratio < 0.5) return const Color(0xFFFEF3C7); // <50%
    if (ratio < 1.0) return const Color(0xFFD1FAE5); // 50-99%
    // All done - intensity based on count
    if (count >= 5) return const Color(0xFF059669);
    if (count >= 3) return const Color(0xFF10B981);
    return const Color(0xFF34D399);
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isFuture(DateTime d) => d.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, _) {
        final ratioMap = provider.getCompletionRatioByDate();
        final calDays = _buildCalendarDays();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCalendar(calDays, ratioMap, provider),
                      const SizedBox(height: 16),
                      _buildLegend(),
                      const SizedBox(height: 16),
                      if (_selectedDay != null)
                        _buildDayDetail(_selectedDay!, provider),
                    ],
                  ),
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
          const Text('캘린더',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                  _selectedDay = null;
                }),
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Text(
                DateFormat('yyyy년 M월', 'ko').format(_month),
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                  _selectedDay = null;
                }),
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    List<DateTime?> days,
    Map<String, double> ratioMap,
    TodoProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Day-of-week header
          Row(
            children: _weekdays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: d == '일'
                                    ? const Color(0xFFEF4444)
                                    : d == '토'
                                        ? const Color(0xFF3B82F6)
                                        : AppColors.mutedForeground)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          ...List.generate(days.length ~/ 7, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: List.generate(7, (col) {
                  final day = days[row * 7 + col];
                  if (day == null) return const Expanded(child: SizedBox());

                  final key = _dateKey(day);
                  final ratio = ratioMap[key];
                  final todos = provider.getTodosForDate(day);
                  final count = todos.length;
                  final cellColor = ratio != null ? _cellColor(ratio, count) : Colors.transparent;
                  final isSelected = _selectedDay != null &&
                      _selectedDay!.year == day.year &&
                      _selectedDay!.month == day.month &&
                      _selectedDay!.day == day.day;
                  final today = _isToday(day);
                  final future = _isFuture(day);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = isSelected ? null : day;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 44,
                        decoration: BoxDecoration(
                          color: future ? Colors.transparent : cellColor,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : today
                                  ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5)
                                  : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: today ? FontWeight.bold : FontWeight.normal,
                                color: future
                                    ? AppColors.mutedForeground.withOpacity(0.4)
                                    : today
                                        ? AppColors.primary
                                        : AppColors.foreground,
                              ),
                            ),
                            if (!future && count > 0)
                              Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: ratio == 1.0
                                      ? const Color(0xFF059669)
                                      : AppColors.mutedForeground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(const Color(0xFFFFE4E4), '미완료'),
        const SizedBox(width: 12),
        _legendItem(const Color(0xFFFEF3C7), '진행중'),
        const SizedBox(width: 12),
        _legendItem(const Color(0xFF34D399), '완료'),
        const SizedBox(width: 12),
        _legendItem(const Color(0xFF059669), '완료(多)'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
      ],
    );
  }

  Widget _buildDayDetail(DateTime day, TodoProvider provider) {
    final todos = provider.getTodosForDate(day);
    final completed = todos.where((t) => t.completed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('M월 d일 (E)', 'ko').format(day),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$completed/${todos.length} 완료',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (todos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('이 날의 할 일이 없습니다',
                  style: TextStyle(color: AppColors.mutedForeground)),
            ),
          )
        else
          ...todos.map((todo) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TodoItemWidget(
                  todo: todo,
                  //onToggle: () => provider.toggleTodo(todo.id),
                  onDelete: () => provider.deleteTodo(todo.id),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TodoDetailScreen(todoId: todo.id)),
                  ),
                ),
              )),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddEditTodoSheet(selectedDate: day),
            ),
            icon: const Icon(Icons.add),
            label: const Text('이 날에 할 일 추가'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
