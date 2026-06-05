import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/character_model.dart';
import '../../../core/providers/character_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../character/screens/character_creation_screen.dart';
import '../../character/widgets/stat_up_dialog.dart';

class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key});

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charProvider = context.watch<CharacterProvider>();

    if (!charProvider.isLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E40AF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(image: AssetImage('assets/images/loading_image.png'), width: 240),
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
    return _buildMain(context, ch, charProvider);
  }

  Widget _buildMain(BuildContext context, CharacterData ch, CharacterProvider provider) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 탭 헤더 (스탯포인트 배너 + 탭바만) ───────────────────
          Container(
            color: AppColors.card,
            child: Column(
              children: [
                if (ch.statPoints > 0)
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => StatUpDialog(points: ch.statPoints),
                    ),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                      ),
                      child: Row(children: [
                        Icon(Icons.arrow_upward, color: AppColors.gold, size: 18,
                            shadows: [Shadow(color: AppColors.gold.withOpacity(0.7), blurRadius: 8)]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('스탯 포인트 ${ch.statPoints}개를 배분하세요!',
                              style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  shadows: [Shadow(color: AppColors.gold.withOpacity(0.5), blurRadius: 4)])),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.gold, size: 18),
                      ]),
                    ),
                  ),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.shield_outlined, size: 18), text: '장비 & 스탯'),
                    Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: '인벤토리'),
                    Tab(icon: Icon(Icons.store_outlined, size: 18), text: '상점'),
                  ],
                  labelColor: AppColors.gold,
                  unselectedLabelColor: AppColors.mutedForeground,
                  indicatorColor: AppColors.gold,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  dividerColor: AppColors.border,
                ),
              ],
            ),
          ),
          // ── 탭 콘텐츠 ────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEquipStatsTab(ch, provider),
                _buildInventoryTab(ch, provider),
                _buildShopTab(ch, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // Tab 1: 장비 & 스탯
  // ════════════════════════════════════════════════════════

  Widget _buildEquipStatsTab(CharacterData ch, CharacterProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('⚔️ 장착 장비'),
          const SizedBox(height: 10),
          _buildEquipSlots(ch, provider),
          const SizedBox(height: 20),
          _sectionTitle('📊 캐릭터 스탯'),
          const SizedBox(height: 10),
          _buildStats(ch),
          const SizedBox(height: 16),
          _buildCombatStats(ch),
          const SizedBox(height: 20),
          _buildHpBar(ch),
          const SizedBox(height: 20),
          _buildBattleRecord(ch),
        ],
      ),
    );
  }

  Widget _buildEquipSlots(CharacterData ch, CharacterProvider provider) {
    return Row(
      children: [
        Expanded(child: _equipSlot('⚔️', '무기', ch.equippedWeapon, EquipmentType.weapon, provider)),
        const SizedBox(width: 10),
        Expanded(child: _equipSlot('🛡️', '방어구', ch.equippedArmor, EquipmentType.armor, provider)),
        const SizedBox(width: 10),
        Expanded(child: _equipSlot('💍', '장신구', ch.equippedAccessory, EquipmentType.accessory, provider)),
      ],
    );
  }

  Widget _equipSlot(String icon, String label, EquipmentItem? item, EquipmentType type, CharacterProvider provider) {
    final rarityColor = item != null ? _rarityColor(item.rarity) : AppColors.border;
    return GestureDetector(
      onLongPress: item != null ? () => provider.unequipSlot(type) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: item != null ? rarityColor.withOpacity(0.6) : AppColors.border,
              width: item != null ? 1.5 : 1),
          boxShadow: item != null
              ? [
                  BoxShadow(
                      color: rarityColor.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item?.emoji ?? icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              item?.name ?? label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: item != null ? FontWeight.bold : FontWeight.normal,
                color: item != null ? rarityColor : AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item != null) ...[
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: rarityColor.withOpacity(0.4)),
                ),
                child: Text(item.rarityLabel,
                    style: TextStyle(
                        fontSize: 9, color: rarityColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text('장착중',
                  style: TextStyle(
                      fontSize: 9,
                      color: AppColors.complete.withOpacity(0.8),
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStats(CharacterData ch) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _statCard('💪', 'STR', ch.statStr, const Color(0xFFEF4444))),
          const SizedBox(width: 10),
          Expanded(child: _statCard('🧠', 'INT', ch.statInt, const Color(0xFF8B5CF6))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _statCard('💨', 'AGI', ch.statAgi, const Color(0xFF22C55E))),
          const SizedBox(width: 10),
          Expanded(child: _statCard('❤️', 'VIT', ch.statVit, const Color(0xFFF59E0B))),
        ]),
      ],
    );
  }

  Widget _statCard(String emoji, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.mutedForeground)),
            Text('$value',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                    shadows: [
                      Shadow(color: color.withOpacity(0.6), blurRadius: 6)
                    ])),
          ]),
        ],
      ),
    );
  }

  Widget _buildCombatStats(CharacterData ch) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _combatStatCell('⚔️', '공격력', ch.effectiveAtk, const Color(0xFFEF4444))),
          _divider(),
          Expanded(child: _combatStatCell('🛡️', '방어력', ch.effectiveDef, const Color(0xFF3B82F6))),
          _divider(),
          Expanded(child: _combatStatCell('💨', '속도', ch.effectiveSpd, const Color(0xFF22C55E))),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: AppColors.border);
  }

  Widget _combatStatCell(String emoji, String label, int val, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text('$val',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: [
                  Shadow(color: color.withOpacity(0.5), blurRadius: 4)
                ])),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.mutedForeground)),
      ],
    );
  }

  Widget _buildHpBar(CharacterData ch) {
    final ratio = ch.hpRatio;
    final hpColor = ratio > 0.5
        ? AppColors.complete
        : ratio > 0.25
            ? AppColors.gold
            : AppColors.destructive;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: hpColor, size: 16,
                  shadows: [Shadow(color: hpColor.withOpacity(0.7), blurRadius: 6)]),
              const SizedBox(width: 8),
              const Text('HP',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.foreground)),
              const Spacer(),
              Text('${ch.hp} / ${ch.maxHp}',
                  style: TextStyle(
                      color: hpColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      shadows: [
                        Shadow(color: hpColor.withOpacity(0.5), blurRadius: 4)
                      ])),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                    color: hpColor.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: hpColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                minHeight: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleRecord(CharacterData ch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('전투 기록',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.foreground)),
          const Spacer(),
          Text('🏆 ${ch.totalWins}승',
              style: const TextStyle(
                  color: AppColors.complete, fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Text('💀 ${ch.totalLosses}패',
              style: const TextStyle(
                  color: AppColors.destructive, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // Tab 2: 인벤토리
  // ════════════════════════════════════════════════════════

  Widget _buildInventoryTab(CharacterData ch, CharacterProvider provider) {
    if (ch.inventory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(child: Text('🎒', style: TextStyle(fontSize: 40))),
            ),
            const SizedBox(height: 16),
            const Text('인벤토리가 비어있습니다',
                style: TextStyle(
                    color: AppColors.mutedForeground, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('전투에서 승리하거나 상점에서 구매하세요!',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: ch.inventory.length,
      itemBuilder: (_, i) {
        final item = ch.inventory[i];
        final equipped = item.id == ch.equippedWeaponId ||
            item.id == ch.equippedArmorId ||
            item.id == ch.equippedAccessoryId;
        final rarityColor = _rarityColor(item.rarity);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: equipped ? rarityColor.withOpacity(0.6) : AppColors.border,
                width: equipped ? 1.5 : 1),
            boxShadow: equipped
                ? [
                    BoxShadow(
                        color: rarityColor.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1)
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 6, children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: rarityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.rarityLabel,
                            style: TextStyle(
                                fontSize: 10,
                                color: rarityColor,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (equipped)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.complete.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.complete.withOpacity(0.4)),
                          ),
                          child: const Text('장착중',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.complete,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
                    const SizedBox(height: 3),
                    Text(_itemStats(item),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.mutedForeground)),
                  ],
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                if (!equipped)
                  TextButton(
                    onPressed: () => provider.equipItem(item.id),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero),
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
              ]),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  // Tab 3: 상점
  // ════════════════════════════════════════════════════════

  static const _shopCatalog = [
    _ShopItem(
      id: 'shop_golden_pen',
      name: '황금 만년필 검',
      emoji: '✒️',
      description: '황금으로 빚은 전설의 필기구. 글씨처럼 날카롭다.',
      type: EquipmentType.weapon,
      rarity: EquipmentRarity.rare,
      price: 50,
      attackBonus: 8,
    ),
    _ShopItem(
      id: 'shop_titanium_ruler',
      name: '티타늄 자 방패',
      emoji: '📐',
      description: '정밀한 측정만큼 완벽한 방어를 자랑한다.',
      type: EquipmentType.armor,
      rarity: EquipmentRarity.rare,
      price: 60,
      defenseBonus: 6,
      hpBonus: 20,
    ),
    _ShopItem(
      id: 'shop_swift_ring',
      name: '신속의 반지',
      emoji: '💫',
      description: '착용 시 몸이 바람처럼 가벼워진다.',
      type: EquipmentType.accessory,
      rarity: EquipmentRarity.rare,
      price: 45,
      agilityBonus: 5,
    ),
    _ShopItem(
      id: 'shop_graduation_cap',
      name: '용감한 학사모',
      emoji: '🎓',
      description: '졸업의 의지가 담긴 모자. 강인한 방어력 제공.',
      type: EquipmentType.armor,
      rarity: EquipmentRarity.rare,
      price: 55,
      defenseBonus: 4,
      hpBonus: 30,
    ),
    _ShopItem(
      id: 'shop_scholar_staff',
      name: '학사 지팡이',
      emoji: '🪄',
      description: '지식의 힘이 결집된 마력의 지팡이.',
      type: EquipmentType.weapon,
      rarity: EquipmentRarity.epic,
      price: 90,
      attackBonus: 12,
    ),
    _ShopItem(
      id: 'shop_lunchbox',
      name: '회복의 도시락',
      emoji: '🍱',
      description: '어머니의 손맛이 담긴 도시락. 최대 HP 대폭 증가.',
      type: EquipmentType.accessory,
      rarity: EquipmentRarity.common,
      price: 40,
      hpBonus: 50,
    ),
    _ShopItem(
      id: 'shop_steel_bag',
      name: '강철 책가방',
      emoji: '🎒',
      description: '무거운 책을 들고 단련된 최강의 방어구.',
      type: EquipmentType.armor,
      rarity: EquipmentRarity.epic,
      price: 120,
      defenseBonus: 10,
      hpBonus: 40,
    ),
    _ShopItem(
      id: 'shop_lightning_sword',
      name: '번개의 검',
      emoji: '⚡',
      description: '빛보다 빠른 타격을 자랑하는 전설의 검.',
      type: EquipmentType.weapon,
      rarity: EquipmentRarity.legendary,
      price: 200,
      attackBonus: 20,
    ),
  ];

  Widget _buildShopTab(CharacterData ch, CharacterProvider provider) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildShopCard(_shopCatalog[i], ch, provider),
              childCount: _shopCatalog.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopCard(_ShopItem shopItem, CharacterData ch, CharacterProvider provider) {
    final canAfford = ch.gold >= shopItem.price;
    final rarityColor = _rarityColor(shopItem.rarity);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: rarityColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: rarityColor.withOpacity(0.15),
              blurRadius: 10,
              spreadRadius: 1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 이모지 + 희귀도
            Column(children: [
              Text(shopItem.emoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: rarityColor.withOpacity(0.4)),
                ),
                child: Text(shopItem.rarity.label,
                    style: TextStyle(
                        fontSize: 10,
                        color: rarityColor,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
            // 이름 + 스탯
            Column(children: [
              Text(shopItem.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground)),
              const SizedBox(height: 6),
              _buildShopStats(shopItem),
            ]),
            // 가격 + 구매
            Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on,
                      color: canAfford ? AppColors.gold : AppColors.mutedForeground,
                      size: 16),
                  const SizedBox(width: 3),
                  Text('${shopItem.price}G',
                      style: TextStyle(
                          color: canAfford ? AppColors.gold : AppColors.mutedForeground,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canAfford
                      ? () => _buyItem(shopItem, provider)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford ? AppColors.gold : AppColors.border,
                    foregroundColor: canAfford ? Colors.black87 : AppColors.mutedForeground,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: canAfford ? 3 : 0,
                  ),
                  child: Text(canAfford ? '구매' : '금 부족',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildShopStats(_ShopItem item) {
    final stats = <Widget>[];
    if (item.attackBonus > 0) {
      stats.add(_shopStat('⚔️', '+${item.attackBonus}', const Color(0xFFEF4444)));
    }
    if (item.defenseBonus > 0) {
      stats.add(_shopStat('🛡️', '+${item.defenseBonus}', const Color(0xFF3B82F6)));
    }
    if (item.agilityBonus > 0) {
      stats.add(_shopStat('💨', '+${item.agilityBonus}', const Color(0xFF22C55E)));
    }
    if (item.hpBonus > 0) {
      stats.add(_shopStat('❤️', '+${item.hpBonus}', const Color(0xFFF59E0B)));
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: stats,
    );
  }

  Widget _shopStat(String emoji, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 2),
        Text(val, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Future<void> _buyItem(_ShopItem shopItem, CharacterProvider provider) async {
    final item = EquipmentItem(
      id: 'bought_${shopItem.id}_${DateTime.now().millisecondsSinceEpoch}',
      name: shopItem.name,
      emoji: shopItem.emoji,
      type: shopItem.type,
      rarity: shopItem.rarity,
      attackBonus: shopItem.attackBonus,
      defenseBonus: shopItem.defenseBonus,
      agilityBonus: shopItem.agilityBonus,
      hpBonus: shopItem.hpBonus,
    );
    final success = await provider.purchaseItem(item, shopItem.price);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? '${shopItem.name} 구매 완료! 💰'
          : '골드가 부족합니다'),
      backgroundColor:
          success ? AppColors.complete.withOpacity(0.85) : AppColors.destructive.withOpacity(0.85),
    ));
  }

  // ── 공통 유틸 ─────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground));
  }

  void _confirmSell(EquipmentItem item, CharacterProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${item.name} 판매'),
        content: Text('${_sellPrice(item.rarity)}G를 받고 판매하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.sellItem(item.id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.destructive,
                foregroundColor: Colors.white),
            child: const Text('판매'),
          ),
        ],
      ),
    );
  }

  Color _rarityColor(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return const Color(0xFFF59E0B);
      case EquipmentRarity.epic: return const Color(0xFF8B5CF6);
      case EquipmentRarity.rare: return const Color(0xFF3B82F6);
      default: return const Color(0xFF94A3B8);
    }
  }

  String _itemStats(EquipmentItem item) {
    final parts = <String>[];
    if (item.attackBonus > 0) parts.add('공격 +${item.attackBonus}');
    if (item.defenseBonus > 0) parts.add('방어 +${item.defenseBonus}');
    if (item.agilityBonus > 0) parts.add('민첩 +${item.agilityBonus}');
    if (item.hpBonus > 0) parts.add('HP +${item.hpBonus}');
    return parts.isEmpty ? '스탯 없음' : parts.join(' · ');
  }

  int _sellPrice(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return 200;
      case EquipmentRarity.epic: return 80;
      case EquipmentRarity.rare: return 30;
      default: return 10;
    }
  }
}

// ── 상점 아이템 데이터 ───────────────────────────────────────────────────────

class _ShopItem {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final EquipmentType type;
  final EquipmentRarity rarity;
  final int price;
  final int attackBonus;
  final int defenseBonus;
  final int agilityBonus;
  final int hpBonus;

  const _ShopItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.type,
    required this.rarity,
    required this.price,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.agilityBonus = 0,
    this.hpBonus = 0,
  });
}

extension _RarityLabel on EquipmentRarity {
  String get label {
    switch (this) {
      case EquipmentRarity.legendary: return '전설';
      case EquipmentRarity.epic: return '에픽';
      case EquipmentRarity.rare: return '레어';
      default: return '일반';
    }
  }
}
