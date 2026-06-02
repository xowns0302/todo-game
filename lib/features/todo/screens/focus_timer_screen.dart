import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/todo_model.dart';
import '../../../core/providers/todo_provider.dart';
import '../../../core/providers/timer_provider.dart';
import '../../../core/services/ai_service.dart';

class FocusTimerScreen extends StatefulWidget {
  final String todoId;
  final String todoTitle;

  const FocusTimerScreen({super.key, required this.todoId, required this.todoTitle});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  static const _uuid = Uuid();
  static const _presets = [5, 10, 15, 25, 30, 45, 60];
  int _selectedMinutes = 25;
  bool _sessionSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimerProvider>().setup(_selectedMinutes, widget.todoId);
    });
  }

  @override
  void dispose() {
    // Ensure timer is stopped when leaving
    final timer = context.read<TimerProvider>();
    if (timer.isRunning) timer.stop();
    super.dispose();
  }

  void _selectPreset(int minutes, TimerProvider timer) {
    if (timer.isRunning) return;
    setState(() => _selectedMinutes = minutes);
    timer.setup(minutes, widget.todoId);
  }

  Future<void> _saveSession(BuildContext context, int elapsedMinutes) async {
    if (_sessionSaved || elapsedMinutes <= 0) return;
    _sessionSaved = true;
    final xp = AiService.calculateFocusXp(elapsedMinutes);
    final session = FocusSession(
      id: _uuid.v4(),
      durationMinutes: elapsedMinutes,
      xpEarned: xp,
      timestamp: DateTime.now(),
    );
    await context.read<TodoProvider>().addFocusSession(widget.todoId, session);
    if (context.mounted) {
      _showCompletionDialog(context, elapsedMinutes, xp);
    }
  }

  void _showCompletionDialog(BuildContext context, int minutes, int xp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('집중 완료!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$minutes분 집중',
                style: const TextStyle(color: AppColors.mutedForeground)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Text('+$xp XP 획득!',
                      style: const TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimerProvider, TodoProvider>(
      builder: (context, timer, todoProvider, _) {
        // Auto-save when timer finishes
        if (timer.isFinished && !_sessionSaved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _saveSession(context, timer.elapsedMinutes);
          });
        }

        final previewXp = AiService.calculateFocusXp(_selectedMinutes);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('집중 타이머'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (timer.isRunning || timer.state == TimerState.paused) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('타이머 중단'),
                      content: const Text('타이머를 중단하고 나가겠습니까?\n지금까지 집중한 시간은 기록됩니다.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('계속 집중')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('나가기'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    final elapsed = timer.elapsedMinutes;
                    timer.stop();
                    if (elapsed > 0) await _saveSession(context, elapsed);
                    if (context.mounted && !_sessionSaved) Navigator.pop(context);
                  }
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Todo title
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.task_alt, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.todoTitle,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Duration presets
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final min = _presets[i];
                      final selected = _selectedMinutes == min;
                      return GestureDetector(
                        onTap: () => _selectPreset(min, timer),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF8B5CF6) : AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? const Color(0xFF8B5CF6) : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '$min분',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Circular timer
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: CustomPaint(
                            painter: _TimerPainter(
                              progress: timer.progress,
                              isFinished: timer.isFinished,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    timer.timeDisplay,
                                    style: const TextStyle(
                                      fontSize: 52,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.foreground,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  Text(
                                    timer.isRunning
                                        ? '집중 중...'
                                        : timer.state == TimerState.paused
                                            ? '일시정지'
                                            : timer.isFinished
                                                ? '완료!'
                                                : '시작하기',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: timer.isRunning
                                          ? const Color(0xFF8B5CF6)
                                          : AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // XP preview
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Color(0xFF8B5CF6), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '$_selectedMinutes분 완료 시 +$previewXp XP',
                                style: const TextStyle(
                                  color: Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '* 집중 시간이 길수록 XP 가중치 증가',
                          style: TextStyle(color: AppColors.mutedForeground, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (timer.isRunning || timer.state == TimerState.paused) ...[
                      // Stop button
                      _controlButton(
                        icon: Icons.stop,
                        label: '종료',
                        color: AppColors.destructive,
                        onTap: () async {
                          final elapsed = timer.elapsedMinutes;
                          timer.stop();
                          if (elapsed > 0) await _saveSession(context, elapsed);
                        },
                      ),
                      const SizedBox(width: 20),
                      // Pause/Resume button
                      _controlButton(
                        icon: timer.isRunning ? Icons.pause : Icons.play_arrow,
                        label: timer.isRunning ? '일시정지' : '재개',
                        color: const Color(0xFF8B5CF6),
                        size: 72,
                        onTap: () {
                          if (timer.isRunning) {
                            timer.pause();
                          } else {
                            timer.resume();
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      // Reset button
                      _controlButton(
                        icon: Icons.refresh,
                        label: '초기화',
                        color: AppColors.mutedForeground,
                        onTap: () {
                          timer.reset();
                          setState(() => _sessionSaved = false);
                        },
                      ),
                    ] else ...[
                      // Start button
                      GestureDetector(
                        onTap: () {
                          setState(() => _sessionSaved = false);
                          timer.start();
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: size * 0.45),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final bool isFinished;

  _TimerPainter({required this.progress, required this.isFinished});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = AppColors.muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // Progress arc
    final progressPaint = Paint()
      ..color = isFinished ? const Color(0xFF22C55E) : const Color(0xFF8B5CF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.isFinished != isFinished;
}
