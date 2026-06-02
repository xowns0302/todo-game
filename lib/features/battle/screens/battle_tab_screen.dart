import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/character_model.dart';
import '../../../core/providers/character_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'battle_screen.dart';

/// Shown in the bottom nav tab — always reads fresh character, then navigates
/// to a new BattleScreen route so each fight starts with current state.
class BattleTabScreen extends StatelessWidget {
  const BattleTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final charProvider = context.watch<CharacterProvider>();

    if (!charProvider.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!charProvider.hasCharacter) {
      return const _NoBattleScreen();
    }

    final ch = charProvider.character!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _BattleEnemySelectBody(character: ch),
      ),
    );
  }
}

class _BattleEnemySelectBody extends StatelessWidget {
  final CharacterData character;
  const _BattleEnemySelectBody({required this.character});

  @override
  Widget build(BuildContext context) {
    final boss = Enemy.bossForLevel(character.level);
    final stages = Enemy.stageEnemies(character.level);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _header(character),
        const SizedBox(height: 20),
        _sectionTitle('⚠️ 일일 보스'),
        _enemyCard(context, boss, isBoss: true),
        const SizedBox(height: 20),
        _sectionTitle('🗺️ 스테이지 몬스터'),
        ...stages.map((e) => _enemyCard(context, e, isBoss: false)),
      ],
    );
  }

  Widget _header(CharacterData ch) {
    final typeInfo = _typeInfoFor(ch.type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(typeInfo.$1, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeInfo.$2,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('⚔️ ${ch.effectiveAtk}  🛡️ ${ch.effectiveDef}  💨 ${ch.effectiveSpd}',
                    style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('❤️ ${ch.hp}/${ch.maxHp}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('💰 ${ch.gold}G',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFF59E0B))),
            ],
          ),
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

  Widget _enemyCard(BuildContext context, Enemy enemy, {required bool isBoss}) {
    final borderColor = isBoss ? const Color(0xFFEF4444) : AppColors.border;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BattleScreen(character: character, initialEnemy: enemy),
          ),
        );
      },
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
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: isBoss
                    ? const Color(0xFFEF4444).withOpacity(0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(enemy.emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(enemy.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isBoss ? const Color(0xFFEF4444) : AppColors.foreground)),
                  const SizedBox(height: 4),
                  Text('Lv.${enemy.level}  ❤️ ${enemy.maxHp}  ⚔️ ${enemy.attack}  🛡️ ${enemy.defense}',
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('💰 ${enemy.goldReward}G',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                Text('✨ ${enemy.xpReward}XP',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                Text(isBoss ? '드롭 80%' : '드롭 30%',
                    style: TextStyle(
                        fontSize: 11,
                        color: isBoss ? const Color(0xFFEF4444) : AppColors.mutedForeground)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (String, String) _typeInfoFor(CharacterType type) {
    switch (type) {
      case CharacterType.warrior: return ('⚔️', '전사');
      case CharacterType.mage: return ('🔥', '마법사');
      case CharacterType.rogue: return ('🗡️', '도적');
    }
  }
}

class _NoBattleScreen extends StatelessWidget {
  const _NoBattleScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('⚔️', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              Text('캐릭터를 먼저 생성하세요',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('캐릭터 탭에서 직업을 선택하면\n전투를 시작할 수 있습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedForeground)),
            ],
          ),
        ),
      ),
    );
  }
}
