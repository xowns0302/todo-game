import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/character_model.dart';
import '../../../core/models/todo_model.dart';
import '../../../core/providers/character_provider.dart';
import '../../../core/providers/todo_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/stat_up_dialog.dart';
import '../widgets/pixel_runner_widget.dart';
import 'character_creation_screen.dart';
import '../../battle/screens/battle_screen.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  int _prevLevel = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final todoLevel = context.read<TodoProvider>().level;
    final charProvider = context.read<CharacterProvider>();
    if (charProvider.hasCharacter && todoLevel != _prevLevel && todoLevel > _prevLevel) {
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

  @override
  Widget build(BuildContext context) {
    final charProvider = context.watch<CharacterProvider>();
    final todoProvider = context.watch<TodoProvider>();

    if (!charProvider.isLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E40AF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: AssetImage('assets/images/loading_image.png'),
                width: 240,
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }

    if (!charProvider.hasCharacter) {
      return const CharacterCreationScreen();
    }

    final ch = charProvider.character!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(ch, todoProvider)),
            SliverToBoxAdapter(child: _buildHpBar(ch)),
            SliverToBoxAdapter(child: _buildTodayQuests(todoProvider)),
            SliverToBoxAdapter(child: _buildStats(ch)),
            SliverToBoxAdapter(child: _buildEquipment(ch, charProvider)),
            SliverToBoxAdapter(child: _buildInventory(ch, charProvider)),
            SliverToBoxAdapter(child: _buildBattleRecord(ch)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CharacterData ch, TodoProvider todoProvider) {
    final info = _typeInfo(ch.type);
    final level = todoProvider.level;
    final levelXp = todoProvider.currentLevelXp;
    final nextXp = todoProvider.xpToNextLevel;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [info.color.withOpacity(0.15), AppColors.card],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: PixelRunnerWidget(size: 78)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(info.name,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: info.color)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: info.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Lv.$level',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: info.color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('💰 ${ch.gold}G',
                        style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: nextXp > 0 ? levelXp / nextXp : 0,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(info.color),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$levelXp / $nextXp XP',
                        style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                  ],
                ),
              ),
            ],
          ),
          if (ch.statPoints > 0) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => StatUpDialog(points: ch.statPoints),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⬆️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text('스탯 포인트 ${ch.statPoints}개 배분하기',
                        style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final ch = context.read<CharacterProvider>().character!;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BattleScreen(character: ch)),
                ).then((_) => setState(() {}));
              },
              icon: const Icon(Icons.sports_kabaddi),
              label: const Text('전투 시작', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: info.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayQuests(TodoProvider todoProvider) {
    final today = DateTime.now();
    final todos = todoProvider.getTodosForDate(today);
    final done = todos.where((t) => t.completed).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.35)),
        boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.08), blurRadius: 8)],
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFDE68A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📜', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text('오늘의 퀘스트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$done/${todos.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                ),
              ],
            ),
          ),
          if (todos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('오늘의 퀘스트가 없습니다\n할 일 탭에서 추가해보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF92400E), fontSize: 13)),
            )
          else
            ...todos.asMap().entries.map((e) => _buildQuestItem(e.value, e.key == todos.length - 1)),
        ],
      ),
    );
  }

  Widget _buildQuestItem(Todo todo, bool isLast) {
    final xp = todo.completionXp;
    final gold = todo.difficulty == 'HARD' ? 20 : todo.difficulty == 'EASY' ? 5 : 10;
    final stars = todo.difficulty == 'HARD' ? 3 : todo.difficulty == 'EASY' ? 1 : 2;
    final textColor = todo.completed
        ? const Color(0xFF92400E).withOpacity(0.4)
        : const Color(0xFF78350F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: const Color(0xFFD97706).withOpacity(0.2))),
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : null,
      ),
      child: Row(
        children: [
          // 완료 체크박스
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: todo.completed ? const Color(0xFF22C55E) : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: todo.completed ? const Color(0xFF22C55E) : const Color(0xFF92400E).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: todo.completed
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 10),
          // 퀘스트 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    decoration: todo.completed ? TextDecoration.lineThrough : null,
                    decorationColor: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    // 별점 (난이도)
                    ...List.generate(3, (i) => Icon(
                      Icons.star,
                      size: 11,
                      color: i < stars
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFD97706).withOpacity(0.25),
                    )),
                    const SizedBox(width: 6),
                    Text('XP $xp',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6D28D9), fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('🪙 ${gold}G',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          // 완료 아이콘
          if (todo.completed)
            const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
        ],
      ),
    );
  }

  Widget _buildHpBar(CharacterData ch) {
    final ratio = ch.hpRatio;
    final hpColor = ratio > 0.5
        ? const Color(0xFF22C55E)
        : ratio > 0.25
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('❤️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text('HP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text('${ch.hp} / ${ch.maxHp}',
                  style: TextStyle(color: hpColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: hpColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(hpColor),
              minHeight: 14,
            ),
          ),
          if (ch.isDead) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                  SizedBox(width: 8),
                  Text('HP가 0! 할 일을 완료해서 HP를 회복하세요',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats(CharacterData ch) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('스탯', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statTile('💪', 'STR', ch.statStr, '물리 공격', const Color(0xFFEF4444))),
              const SizedBox(width: 10),
              Expanded(child: _statTile('🧠', 'INT', ch.statInt, '마법 공격', const Color(0xFF8B5CF6))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _statTile('💨', 'AGI', ch.statAgi, '속도·회피', const Color(0xFF22C55E))),
              const SizedBox(width: 10),
              Expanded(child: _statTile('❤️', 'VIT', ch.statVit, '체력 증가', const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _combatTile('⚔️', '공격력', ch.effectiveAtk)),
              Expanded(child: _combatTile('🛡️', '방어력', ch.effectiveDef)),
              Expanded(child: _combatTile('💨', '속도', ch.effectiveSpd)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String emoji, String label, int val, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
              Text('$val', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(desc, style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _combatTile(String emoji, String label, int val) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text('$val', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
      ],
    );
  }

  Widget _buildEquipment(CharacterData ch, CharacterProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('장비', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _equipSlot('⚔️', '무기', ch.equippedWeapon, EquipmentType.weapon, provider)),
              const SizedBox(width: 10),
              Expanded(child: _equipSlot('🛡️', '방어구', ch.equippedArmor, EquipmentType.armor, provider)),
              const SizedBox(width: 10),
              Expanded(child: _equipSlot('💍', '장신구', ch.equippedAccessory, EquipmentType.accessory, provider)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('길게 누르면 해제', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }

  Widget _equipSlot(String icon, String label, EquipmentItem? item, EquipmentType type, CharacterProvider provider) {
    return GestureDetector(
      onLongPress: item != null ? () => provider.unequipSlot(type) : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item != null ? _rarityColor(item.rarity) : AppColors.border),
        ),
        child: Column(
          children: [
            Text(item?.emoji ?? icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              item?.name ?? label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: item != null ? FontWeight.w600 : FontWeight.normal,
                  color: item != null ? _rarityColor(item.rarity) : AppColors.mutedForeground),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventory(CharacterData ch, CharacterProvider provider) {
    if (ch.inventory.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('인벤토리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              Text('${ch.inventory.length}개', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ...ch.inventory.map((item) {
            final equipped = item.id == ch.equippedWeaponId ||
                item.id == ch.equippedArmorId ||
                item.id == ch.equippedAccessoryId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: equipped ? _rarityColor(item.rarity) : AppColors.border),
              ),
              child: Row(
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          children: [
                            Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _rarityColor(item.rarity).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(item.rarityLabel,
                                  style: TextStyle(fontSize: 10, color: _rarityColor(item.rarity), fontWeight: FontWeight.w600)),
                            ),
                            if (equipped)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('장착중',
                                    style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        Text(_itemStats(item),
                            style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!equipped)
                        TextButton(
                          onPressed: () => provider.equipItem(item.id),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('장착', style: TextStyle(fontSize: 12)),
                        ),
                      TextButton(
                        onPressed: () => _confirmSell(item, provider),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          foregroundColor: AppColors.destructive,
                        ),
                        child: const Text('판매', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBattleRecord(CharacterData ch) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('전투 기록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          Text('🏆 ${ch.totalWins}승',
              style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Text('💀 ${ch.totalLosses}패',
              style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _confirmSell(EquipmentItem item, CharacterProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('${item.name} 판매'),
        content: Text('${_sellPrice(item.rarity)}G를 받고 판매하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); provider.sellItem(item.id); },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive, foregroundColor: Colors.white),
            child: const Text('판매'),
          ),
        ],
      ),
    );
  }

  int _sellPrice(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return 200;
      case EquipmentRarity.epic: return 80;
      case EquipmentRarity.rare: return 30;
      default: return 10;
    }
  }

  String _itemStats(EquipmentItem item) {
    final parts = <String>[];
    if (item.attackBonus > 0) parts.add('공격력 +${item.attackBonus}');
    if (item.defenseBonus > 0) parts.add('방어력 +${item.defenseBonus}');
    if (item.agilityBonus > 0) parts.add('민첩 +${item.agilityBonus}');
    if (item.hpBonus > 0) parts.add('HP +${item.hpBonus}');
    return parts.isEmpty ? '' : parts.join(' · ');
  }

  Color _rarityColor(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return const Color(0xFFF59E0B);
      case EquipmentRarity.epic: return const Color(0xFF8B5CF6);
      case EquipmentRarity.rare: return const Color(0xFF3B82F6);
      default: return const Color(0xFF94A3B8);
    }
  }

  _TypeInfo _typeInfo(CharacterType type) {
    switch (type) {
      case CharacterType.warrior:
        return _TypeInfo('⚔️', '전사', const Color(0xFFEF4444));
      case CharacterType.mage:
        return _TypeInfo('🔥', '마법사', const Color(0xFF8B5CF6));
      case CharacterType.rogue:
        return _TypeInfo('🗡️', '도적', const Color(0xFF22C55E));
    }
  }
}

class _TypeInfo {
  final String emoji;
  final String name;
  final Color color;
  const _TypeInfo(this.emoji, this.name, this.color);
}
