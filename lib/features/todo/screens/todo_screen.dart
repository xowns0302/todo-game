import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/todo_model.dart';
import '../../../core/providers/todo_provider.dart';
import '../../../core/providers/character_provider.dart';
import '../../character/widgets/stat_up_dialog.dart';
import 'todo_detail_screen.dart';

class TodoScreen extends StatefulWidget {
  final VoidCallback onSwitchToCalendar;

  const TodoScreen({super.key, required this.onSwitchToCalendar});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  DateTime _selectedDate = DateTime.now();
  int _prevLevel = 0;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final todoLevel = context.read<TodoProvider>().level;
    final charProvider = context.read<CharacterProvider>();
    if (charProvider.hasCharacter && todoLevel > _prevLevel) {
      _prevLevel = todoLevel;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await charProvider.syncLevel(todoLevel);
        if (!mounted) return;
        final pts = charProvider.character?.statPoints ?? 0;
        if (pts > 0) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => StatUpDialog(points: pts),
          );
        }
      });
    }
  }

  Widget _glowBar({required double value, required Color color, double height = 8}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.55), blurRadius: 8, spreadRadius: 0),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: color.withOpacity(0.18),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: height,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, _) {
        final todos = todoProvider.getTodosForDate(_selectedDate);
        final todayTodos = todoProvider.getTodosForDate(DateTime.now());
        final completed = todos.where((t) => t.completed).length;
        final isViewingToday = _isToday(_selectedDate);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildDateNav()),
                  SliverToBoxAdapter(child: _buildProgressBar(completed, todos.length)),
                  if (todos.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildTodoCard(todos[i], todoProvider),
                          ),
                          childCount: todos.length,
                        ),
                      ),
                    ),
                  // 오늘의 퀘스트 올 클리어 보상 박스
                  if (isViewingToday)
                    SliverToBoxAdapter(
                      child: Consumer<CharacterProvider>(
                        builder: (_, charProvider, __) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          child: _DailyRewardBox(
                            todayQuests: todayTodos,
                            isClaimed: charProvider.isDailyRewardClaimed(),
                          ),
                        ),
                      ),
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
              Positioned(
                bottom: 24,
                right: 20,
                child: FloatingActionButton(
                  heroTag: 'todo_fab',
                  onPressed: widget.onSwitchToCalendar,
                  backgroundColor: AppColors.primary,
                  elevation: 6,
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 날짜 네비게이션 ───────────────────────────────────────────────────────────

  Widget _buildDateNav() {
    final isToday = _isToday(_selectedDate);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left, () => setState(() =>
              _selectedDate = _selectedDate.subtract(const Duration(days: 1)))),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = DateTime.now()),
              child: Column(
                children: [
                  Text(
                    DateFormat('M월 d일 (E)', 'ko').format(_selectedDate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neonBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.neonBlue.withOpacity(0.4)),
                      ),
                      child: const Text('오늘',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.neonBlue,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _navBtn(Icons.chevron_right, () => setState(() =>
              _selectedDate = _selectedDate.add(const Duration(days: 1)))),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.mutedForeground, size: 20),
      ),
    );
  }

  // ── 진행률 바 ─────────────────────────────────────────────────────────────

  Widget _buildProgressBar(int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;
    final isDone = total > 0 && completed == total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone ? AppColors.complete.withOpacity(0.5) : AppColors.primary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDone ? AppColors.complete : AppColors.primary).withOpacity(0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.auto_awesome,
                      color: isDone ? AppColors.complete : AppColors.mutedForeground,
                      size: 14),
                  const SizedBox(width: 6),
                  Text('퀘스트 진행률',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDone ? AppColors.complete : AppColors.mutedForeground)),
                ]),
                Text('$completed / $total',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDone ? AppColors.complete : AppColors.neonBlue)),
              ],
            ),
            const SizedBox(height: 8),
            _glowBar(
                value: progress,
                color: isDone ? AppColors.complete : AppColors.neonBlue,
                height: 8),
            if (isDone) ...[
              const SizedBox(height: 8),
              const Text('🎉  모든 퀘스트 클리어!',
                  style: TextStyle(
                      color: AppColors.complete,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  // ── 투두 카드 ─────────────────────────────────────────────────────────────

  Widget _buildTodoCard(Todo todo, TodoProvider provider) {
    final completed = todo.completed;
    final gold = todo.difficulty == 'HARD' ? 20 : todo.difficulty == 'EASY' ? 5 : 10;

    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.neonBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.calendar_today, color: AppColors.neonBlue, size: 20),
          SizedBox(width: 8),
          Text('내일로 미루기',
              style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.bold)),
        ]),
      ),
      confirmDismiss: (_) async {
        if (todo.completed) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('완료된 항목은 미룰 수 없습니다'),
            duration: Duration(seconds: 2),
          ));
          return false;
        }
        return true;
      },
      onDismissed: (_) async {
        final originalDate = todo.date;
        await provider.postponeTodo(todo.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${todo.title}" 내일로 미뤘습니다'),
          action: SnackBarAction(
            label: '취소',
            textColor: AppColors.neonBlue,
            onPressed: () {
              final t = provider.getTodoById(todo.id);
              if (t != null) provider.changeTodoDate(todo.id, originalDate);
            },
          ),
        ));
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TodoDetailScreen(todoId: todo.id)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: completed
                  ? AppColors.complete.withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3)),
              if (completed)
                BoxShadow(
                    color: AppColors.complete.withOpacity(0.12),
                    blurRadius: 10,
                    spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: completed ? AppColors.complete : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: completed ? AppColors.complete : AppColors.mutedForeground,
                    width: 2,
                  ),
                  boxShadow: completed
                      ? [
                          BoxShadow(
                              color: AppColors.complete.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1)
                        ]
                      : null,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: completed ? AppColors.mutedForeground : AppColors.foreground,
                        decoration: completed ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    _priorityChips(todo),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('+XP',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFA78BFA),
                          fontWeight: FontWeight.w700)),
                  Text('+${todo.completionXp}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA78BFA),
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, color: AppColors.gold, size: 13),
                      const SizedBox(width: 2),
                      Text('+${gold}G',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.mutedForeground, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityChips(Todo todo) {
    final priorityColor = todo.priority == 'HIGH'
        ? AppColors.destructive
        : todo.priority == 'LOW'
            ? AppColors.complete
            : AppColors.gold;
    final priorityLabel =
        todo.priority == 'HIGH' ? '긴급' : todo.priority == 'LOW' ? '여유' : '보통';
    final diffColor = todo.difficulty == 'HARD'
        ? AppColors.destructive
        : todo.difficulty == 'EASY'
            ? AppColors.complete
            : AppColors.primary;
    final diffLabel = todo.difficulty == 'HARD'
        ? '어려움'
        : todo.difficulty == 'EASY'
            ? '쉬움'
            : '보통';

    return Wrap(spacing: 5, children: [
      _chip(priorityLabel, priorityColor),
      _chip(diffLabel, diffColor),
    ]);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10),
              ],
            ),
            child: const Center(child: Text('🗡️', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 16),
          const Text('오늘의 퀘스트가 없습니다',
              style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('+ 버튼으로 퀘스트를 추가하세요!',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── 일일 퀘스트 올 클리어 보상 박스 ───────────────────────────────────────────

class _DailyRewardBox extends StatefulWidget {
  final List<Todo> todayQuests;
  final bool isClaimed;

  const _DailyRewardBox({required this.todayQuests, required this.isClaimed});

  @override
  State<_DailyRewardBox> createState() => _DailyRewardBoxState();
}

class _DailyRewardBoxState extends State<_DailyRewardBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  int get _questCount => widget.todayQuests.length;
  int get _completedCount => widget.todayQuests.where((t) => t.completed).length;
  bool get _isAllComplete => _questCount > 0 && _completedCount == _questCount;
  // 퀘스트 수가 많을수록 빛나는 강도 상승 (최대 1.0)
  double get _shineFactor => (_questCount / 5.0).clamp(0.3, 1.0);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_DailyRewardBox old) {
    super.didUpdateWidget(old);
    if (old.isClaimed != widget.isClaimed ||
        old.todayQuests.length != widget.todayQuests.length ||
        old.todayQuests.where((t) => t.completed).length != _completedCount) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    final shouldPulse = _isAllComplete && !widget.isClaimed;
    if (shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!shouldPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0.6;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questCount == 0) return const SizedBox.shrink();
    if (widget.isClaimed) return _buildClaimed();
    if (_isAllComplete) return _buildClaimable();
    return _buildLocked();
  }

  Widget _buildLocked() {
    final bonusGold = _questCount * 10;
    final bonusXp = _questCount * 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.25), width: 2),
      ),
      child: Row(children: [
        const Text('🔒', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('일일 퀘스트 올 클리어 보상',
                style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              '$_completedCount/$_questCount 완료  •  +${bonusGold}G  +${bonusXp} XP',
              style: TextStyle(
                  color: AppColors.mutedForeground.withOpacity(0.65), fontSize: 10),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildClaimable() {
    final bonusGold = _questCount * 10;
    final bonusXp = _questCount * 5;
    final sf = _shineFactor;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(_pulseAnim.value * sf * 0.65),
                blurRadius: 8 + _pulseAnim.value * 22 * sf,
                spreadRadius: _pulseAnim.value * 3 * sf,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold, width: 2),
          gradient: LinearGradient(
            colors: [AppColors.card, AppColors.gold.withOpacity(0.06), AppColors.card],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(children: [
          Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '퀘스트 올 클리어! 보상 수령 가능 🎊',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    shadows: [Shadow(color: AppColors.gold.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 3),
                Row(children: [
                  Text('+${bonusGold}G',
                      style: const TextStyle(
                          color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Text('+${bonusXp} XP',
                      style: const TextStyle(
                          color: Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _claimReward,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('🎉  보상 수령하기',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildClaimed() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.complete.withOpacity(0.35), width: 2),
      ),
      child: const Row(children: [
        Text('✅', style: TextStyle(fontSize: 22)),
        SizedBox(width: 12),
        Text('오늘의 보상을 수령했습니다',
            style: TextStyle(
                color: AppColors.complete, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }

  Future<void> _claimReward() async {
    final bonusGold = _questCount * 10;
    final bonusXp = _questCount * 5;
    final charProvider = context.read<CharacterProvider>();
    final todoProvider = context.read<TodoProvider>();

    await charProvider.claimDailyReward(questCount: _questCount);
    await todoProvider.addDailyBonusXp(_questCount);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold, width: 2),
            boxShadow: [
              BoxShadow(
                  color: AppColors.gold.withOpacity(0.5), blurRadius: 24, spreadRadius: 3),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🏆', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            const Text(
              '일일 퀘스트 올 클리어!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: AppColors.gold, blurRadius: 12)],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_questCount개의 퀘스트 완료',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _rewardBadge('💰', '+${bonusGold}G', AppColors.gold),
              const SizedBox(width: 16),
              _rewardBadge('✨', '+${bonusXp} XP', const Color(0xFFA78BFA)),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('수령 완료! 🎊',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _rewardBadge(String emoji, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.45)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
      ]),
    );
  }
}
