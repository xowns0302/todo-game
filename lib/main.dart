import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/todo_provider.dart';
import 'core/providers/timer_provider.dart';
import 'core/providers/character_provider.dart';
import 'core/models/character_model.dart';
import 'features/todo/screens/todo_screen.dart';
import 'features/todo/screens/calendar_screen.dart';
import 'features/battle/screens/battle_tab_screen.dart';
import 'features/item/screens/item_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('ko', null);
  runApp(const LmsTodoApp());
}

class LmsTodoApp extends StatelessWidget {
  const LmsTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()..init()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => CharacterProvider()..init()),
      ],
      child: MaterialApp(
        title: 'TODO HERO',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _bobController;
  late Animation<double> _bobAnimation;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    _bobAnimation = Tween<double>(begin: -4.5, end: 4.5).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  void _switchTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodoScreen(onSwitchToCalendar: () => _switchTab(1)),
      const CalendarScreen(),
      const BattleTabScreen(),
      const ItemScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildGlobalHeroCard(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  // ── 전역 상단 캐릭터 HUD ─────────────────────────────────────────────────────

  Widget _buildGlobalHeroCard() {
    return Consumer2<CharacterProvider, TodoProvider>(
      builder: (context, charProvider, todoProvider, _) {
        final topPad = MediaQuery.of(context).padding.top;
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1F2D3D), Color(0xFF0D1520)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: const Border(
              bottom: BorderSide(color: AppColors.goldBorder, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldBorder.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _StripePainter()))),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 캐릭터 HUD
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 12),
                      child: !charProvider.hasCharacter
                          ? _buildNoCharHud()
                          : _buildCharHud(charProvider, todoProvider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoCharHud() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('⚔️', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Text('아이템 탭에서 캐릭터를 만들어보세요!',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCharHud(CharacterProvider charProvider, TodoProvider todoProvider) {
    final ch = charProvider.character!;
    final level = todoProvider.level;
    final levelXp = todoProvider.currentLevelXp;
    final nextXp = todoProvider.xpToNextLevel;
    final xpRatio = nextXp > 0 ? levelXp / nextXp : 0.0;
    final typeColor = _typeColor(ch.type);
    final typeName = _typeName(ch.type);

    return Row(
      children: [
        // 바운싱 스프라이트
        AnimatedBuilder(
          animation: _bobAnimation,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _bobAnimation.value),
            child: child,
          ),
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: typeColor.withOpacity(0.55), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: typeColor.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/images/hero1.PNG',
                width: 62,
                height: 62,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // 스탯 영역
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    typeName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: typeColor.withOpacity(0.8), blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: typeColor.withOpacity(0.5), width: 1),
                    ),
                    child: Text('Lv.$level',
                        style: TextStyle(
                            color: typeColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  const Icon(Icons.monetization_on, color: AppColors.gold, size: 14),
                  const SizedBox(width: 3),
                  Text('${ch.gold}G',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: AppColors.gold.withOpacity(0.5), blurRadius: 4)],
                      )),
                ],
              ),
              const SizedBox(height: 10),
              // EXP 바
              Row(children: [
                const SizedBox(
                    width: 32,
                    child: Text('EXP', style: TextStyle(color: Colors.white38, fontSize: 10))),
                Expanded(child: _compactBar(xpRatio, AppColors.neonBlue)),
                const SizedBox(width: 5),
                Text('$levelXp/$nextXp',
                    style: const TextStyle(color: AppColors.neonBlue, fontSize: 10)),
              ]),
              const SizedBox(height: 6),
              // HP 바
              Row(children: [
                const SizedBox(
                    width: 32,
                    child: Text(' HP', style: TextStyle(color: Colors.white38, fontSize: 10))),
                Expanded(child: _compactBar(ch.hpRatio, AppColors.complete)),
                const SizedBox(width: 5),
                Text('${ch.hp}/${ch.maxHp}',
                    style: const TextStyle(color: AppColors.complete, fontSize: 10)),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactBar(double value, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: color.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 7,
        ),
      ),
    );
  }

  // ── 하단 네비게이션 바 ───────────────────────────────────────────────────────

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.goldBorder, width: 2)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(children: [
            _navItem(0, Icons.checklist_outlined, Icons.checklist, '할 일'),
            _navItem(1, Icons.calendar_month_outlined, Icons.calendar_month, '캘린더'),
            _navItem(2, Icons.sports_kabaddi_outlined, Icons.sports_kabaddi, '전투'),
            _navItem(3, Icons.inventory_2_outlined, Icons.inventory_2, '아이템'),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final active = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? AppColors.primary : AppColors.mutedForeground,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primary : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 헬퍼 ────────────────────────────────────────────────────────────────────

  Color _typeColor(CharacterType type) {
    switch (type) {
      case CharacterType.warrior: return const Color(0xFFEF4444);
      case CharacterType.mage:    return const Color(0xFF8B5CF6);
      case CharacterType.rogue:   return const Color(0xFF22C55E);
    }
  }

  String _typeName(CharacterType type) {
    switch (type) {
      case CharacterType.warrior: return '전사';
      case CharacterType.mage:    return '마법사';
      case CharacterType.rogue:   return '도적';
    }
  }

}

// 카드 배경 대각선 스트라이프 패턴
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x06FFFFFF)
      ..strokeWidth = 1.5;
    const gap = 12.0;
    final diag = size.height;
    for (double x = -diag; x < size.width + diag; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + diag, diag), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
