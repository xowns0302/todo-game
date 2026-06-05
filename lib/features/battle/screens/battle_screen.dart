import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/character_model.dart';
import '../../../core/providers/character_provider.dart';
import '../../../core/providers/todo_provider.dart';
import '../../../core/theme/app_theme.dart';

class BattleScreen extends StatefulWidget {
  final CharacterData character;
  final Enemy? initialEnemy;
  const BattleScreen({super.key, required this.character, this.initialEnemy});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {

  Enemy? _selectedEnemy;
  BattleResult? _result;

  // Animation controllers
  late final AnimationController _playerAtkCtrl;
  late final AnimationController _enemyAtkCtrl;
  late final AnimationController _shakeCtrl;
  late final Animation<Offset> _playerAtkAnim;
  late final Animation<Offset> _enemyAtkAnim;

  // Battle playback
  int _eventIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playerAtkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _enemyAtkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _playerAtkAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0.5, 0))
        .animate(CurvedAnimation(parent: _playerAtkCtrl, curve: Curves.easeInOut));
    _enemyAtkAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.5, 0))
        .animate(CurvedAnimation(parent: _enemyAtkCtrl, curve: Curves.easeInOut));
    _shakeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _shakeCtrl.reset();
    });

    // Start battle immediately if an enemy was pre-selected
    if (widget.initialEnemy != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedEnemy = widget.initialEnemy;
          _startBattle();
        });
      });
    }
  }

  @override
  void dispose() {
    _playerAtkCtrl.dispose();
    _enemyAtkCtrl.dispose();
    _shakeCtrl.dispose(); // used for shake effect via addStatusListener
    super.dispose();
  }

  String get _playerEmoji {
    switch (widget.character.type) {
      case CharacterType.warrior: return '⚔️';
      case CharacterType.mage: return '🧙';
      case CharacterType.rogue: return '🥷';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedEnemy == null) return _buildEnemySelect();
    if (_isPlaying || _result == null) return _buildBattleArena();
    return _buildResult();
  }

  // ─── ENEMY SELECTION ───────────────────────────────────────────────────────

  Widget _buildEnemySelect() {
    final player = widget.character;
    final boss = Enemy.bossForLevel(player.level);
    final stages = Enemy.stageEnemies(player.level);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: const Text('전투 선택', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Daily boss
          _sectionTitle('일일 보스'),
          _enemyCard(boss, isBoss: true),
          const SizedBox(height: 20),
          _sectionTitle('스테이지 몬스터'),
          ...stages.map((e) => _enemyCard(e, isBoss: false)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _enemyCard(Enemy enemy, {required bool isBoss}) {
    final borderColor = isBoss ? const Color(0xFFEF4444) : AppColors.border;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedEnemy = enemy;
        _startBattle();
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isBoss ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: isBoss
                    ? const Color(0xFFEF4444).withOpacity(0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(enemy.emoji, style: const TextStyle(fontSize: 32))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(enemy.name,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isBoss ? const Color(0xFFEF4444) : AppColors.foreground)),
                      const SizedBox(width: 6),
                      Text('Lv.${enemy.level}',
                          style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statChip('❤️', '${enemy.maxHp}'),
                      const SizedBox(width: 8),
                      _statChip('⚔️', '${enemy.attack}'),
                      const SizedBox(width: 8),
                      _statChip('🛡️', '${enemy.defense}'),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('💰 ${enemy.goldReward}G',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('✨ ${enemy.xpReward}XP',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (isBoss)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('드롭 80%',
                        style: TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                  )
                else
                  const Text('드롭 30%',
                      style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String icon, String val) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(val, style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
      ],
    );
  }

  // ─── BATTLE ARENA ──────────────────────────────────────────────────────────

  void _startBattle() {
    final result = BattleEngine.simulate(widget.character, _selectedEnemy!);
    _result = result;
    _eventIndex = 0;
    _isPlaying = true;
    // Apply result immediately — do NOT wait for animation to finish
    // because user can press back before events play out (mounted = false)
    _applyResult();
    _playNextEvent();
  }

  Future<void> _playNextEvent() async {
    if (!mounted || !_isPlaying) return;
    if (_eventIndex >= (_result?.events.length ?? 0)) {
      setState(() { _isPlaying = false; });
      return;
    }

    final event = _result!.events[_eventIndex];
    setState(() => _eventIndex++);

    switch (event.type) {
      case BattleEventType.playerAttack:
      case BattleEventType.playerSkill:
        await _playerAtkCtrl.forward();
        _playerAtkCtrl.reverse();
        _shakeCtrl.forward(from: 0);
        break;
      case BattleEventType.enemyAttack:
        await _enemyAtkCtrl.forward();
        _enemyAtkCtrl.reverse();
        _shakeCtrl.forward(from: 0);
        break;
      default:
        break;
    }

    await Future.delayed(const Duration(milliseconds: 600));
    _playNextEvent();
  }

  Future<void> _applyResult() async {
    if (_result == null || !mounted) return;
    await context.read<CharacterProvider>().applyBattleResult(_result!);
    if (!mounted) return;
    await context.read<TodoProvider>().addBattleXp(_result!.xpGained);
  }

  Widget _buildBattleArena() {
    final enemy = _selectedEnemy!;
    final result = _result;
    final currentEvent = result != null && _eventIndex > 0
        ? result.events[_eventIndex - 1]
        : null;

    final playerHp = currentEvent?.playerHp ?? widget.character.hp;
    final enemyHp = currentEvent?.enemyHp ?? enemy.maxHp;
    final playerHpRatio = (playerHp / widget.character.maxHp).clamp(0.0, 1.0);
    final enemyHpRatio = (enemyHp / enemy.maxHp).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text(enemy.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Battle field
          Expanded(
            child: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                    ),
                  ),
                ),
                // Stars
                const _StarField(),
                // Ground line
                Positioned(
                  bottom: 100,
                  left: 0, right: 0,
                  child: Container(height: 2, color: Colors.white.withOpacity(0.1)),
                ),
                // Enemy sprite + HP
                Positioned(
                  top: 40, right: 30,
                  child: Column(
                    children: [
                      _buildHpBarCompact(enemyHpRatio, enemy.name, '${enemyHp}/${enemy.maxHp}', const Color(0xFFEF4444)),
                      const SizedBox(height: 12),
                      SlideTransition(
                        position: _enemyAtkAnim,
                        child: _buildSprite(enemy.emoji, 72, isEnemy: true),
                      ),
                    ],
                  ),
                ),
                // Player sprite + HP
                Positioned(
                  bottom: 110, left: 30,
                  child: Column(
                    children: [
                      SlideTransition(
                        position: _playerAtkAnim,
                        child: _buildSprite(_playerEmoji, 72, isEnemy: false),
                      ),
                      const SizedBox(height: 12),
                      _buildHpBarCompact(playerHpRatio, '나', '${playerHp}/${widget.character.maxHp}', const Color(0xFF22C55E)),
                    ],
                  ),
                ),
                // Event log
                Positioned(
                  bottom: 10, left: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentEvent?.message ?? '전투 시작!',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Event list
          Container(
            height: 160,
            color: const Color(0xFF16213E),
            child: result == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: _eventIndex,
                    itemBuilder: (_, i) {
                      final ev = result.events[_eventIndex - 1 - i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          ev.message,
                          style: TextStyle(
                            color: _eventColor(ev.type),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSprite(String emoji, double size, {required bool isEnemy}) {
    return Transform.scale(
      scaleX: isEnemy ? -1 : 1,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.6))),
      ),
    );
  }

  Widget _buildHpBarCompact(double ratio, String name, String hpText, Color color) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(hpText, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ─── RESULT ────────────────────────────────────────────────────────────────

  Widget _buildResult() {
    final result = _result!;
    final won = result.playerWon;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(won ? '🏆' : '💀', style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(
                won ? '승리!' : '패배...',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: won ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _resultRow('✨ 획득 XP', '+${result.xpGained}', AppColors.primary),
                    const SizedBox(height: 10),
                    _resultRow('💰 획득 골드', won ? '+${result.goldGained}G' : '0G', const Color(0xFFF59E0B)),
                    const SizedBox(height: 10),
                    _resultRow('❤️ HP 손실', '-${result.hpLost}', const Color(0xFFEF4444)),
                    if (result.droppedItem != null) ...[
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(result.droppedItem!.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('아이템 드롭!',
                                  style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                              Text(result.droppedItem!.name,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: result.droppedItem!.rarityColor)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('돌아가기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Color _eventColor(BattleEventType type) {
    switch (type) {
      case BattleEventType.playerAttack:
      case BattleEventType.playerSkill:
        return const Color(0xFF60A5FA);
      case BattleEventType.enemyAttack:
        return const Color(0xFFFCA5A5);
      case BattleEventType.victory:
        return const Color(0xFF4ADE80);
      case BattleEventType.defeat:
        return const Color(0xFFEF4444);
      default:
        return Colors.white70;
    }
  }
}

// Simple star field background
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _StarPainter extends CustomPainter {
  static final _stars = List.generate(40, (i) {
    final x = (i * 137.508 % 1.0);
    final y = (i * 91.337 % 1.0);
    final r = (i % 3 + 1) * 0.8;
    return (x, y, r);
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.4);
    for (final (x, y, r) in _stars) {
      canvas.drawCircle(Offset(x * size.width, y * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
