import 'dart:math';
import 'package:flutter/material.dart' show Color;

enum CharacterType { warrior, mage, rogue }

enum EquipmentType { weapon, armor, accessory }

enum EquipmentRarity { common, rare, epic, legendary }

// ───────────────── Equipment ─────────────────

class EquipmentItem {
  final String id;
  final String name;
  final String emoji;
  final EquipmentType type;
  final EquipmentRarity rarity;
  final int attackBonus;
  final int defenseBonus;
  final int agilityBonus;
  final int hpBonus;

  const EquipmentItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.type,
    required this.rarity,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.agilityBonus = 0,
    this.hpBonus = 0,
  });

  Color get rarityColor {
    switch (rarity) {
      case EquipmentRarity.rare: return const Color(0xFF3B82F6);
      case EquipmentRarity.epic: return const Color(0xFF8B5CF6);
      case EquipmentRarity.legendary: return const Color(0xFFF59E0B);
      default: return const Color(0xFF94A3B8);
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case EquipmentRarity.rare: return '레어';
      case EquipmentRarity.epic: return '에픽';
      case EquipmentRarity.legendary: return '전설';
      default: return '일반';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'emoji': emoji,
        'type': type.index, 'rarity': rarity.index,
        'atk': attackBonus, 'def': defenseBonus,
        'agi': agilityBonus, 'hp': hpBonus,
      };

  factory EquipmentItem.fromJson(Map<String, dynamic> j) => EquipmentItem(
        id: j['id'], name: j['name'], emoji: j['emoji'],
        type: EquipmentType.values[j['type'] as int],
        rarity: EquipmentRarity.values[j['rarity'] as int],
        attackBonus: j['atk'] as int? ?? 0,
        defenseBonus: j['def'] as int? ?? 0,
        agilityBonus: j['agi'] as int? ?? 0,
        hpBonus: j['hp'] as int? ?? 0,
      );
}

// ───────────────── Character Data ─────────────────

class CharacterData {
  final CharacterType type;
  final int level;      // mirrors TodoProvider level
  final int gold;
  final int currentHp;
  final int statStr;
  final int statInt;
  final int statAgi;
  final int statVit;    // HP stat
  final int statPoints; // unspent points
  final List<EquipmentItem> inventory;
  final String? equippedWeaponId;
  final String? equippedArmorId;
  final String? equippedAccessoryId;
  final int totalWins;
  final int totalLosses;
  final String? lastBossDate;           // 'yyyy-MM-dd'
  final String? lastDailyClearDate;     // 'yyyy-MM-dd'
  final String? dailyBattleDate;        // 'yyyy-MM-dd' — 일일 전투 추적 기준일
  final List<String> defeatedEnemyIds;  // 오늘 처치한 적 ID 목록

  const CharacterData({
    required this.type,
    this.level = 1,
    this.gold = 0,
    this.currentHp = -1, // -1 = use maxHp
    this.statStr = 5,
    this.statInt = 5,
    this.statAgi = 5,
    this.statVit = 5,
    this.statPoints = 0,
    this.inventory = const [],
    this.equippedWeaponId,
    this.equippedArmorId,
    this.equippedAccessoryId,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.lastBossDate,
    this.lastDailyClearDate,
    this.dailyBattleDate,
    this.defeatedEnemyIds = const [],
  });

  bool isEnemyDefeatedToday(String enemyId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (dailyBattleDate != today) return false;
    return defeatedEnemyIds.contains(enemyId);
  }

  int get maxHp => 50 + (statVit * 10) + (level * 5) + _equippedHpBonus;

  int get hp => currentHp < 0 ? maxHp : currentHp;

  double get hpRatio => maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0;

  bool get isDead => hp <= 0;

  // Effective combat stats (base + equipment)
  int get effectiveAtk {
    int base = type == CharacterType.mage
        ? statInt * 2
        : type == CharacterType.warrior
            ? statStr * 2
            : statStr + statAgi;
    return base + _equippedAtkBonus;
  }

  int get effectiveDef => statVit + _equippedDefBonus;

  int get effectiveSpd => statAgi + _equippedAgiBonus;

  EquipmentItem? get equippedWeapon =>
      equippedWeaponId == null ? null : inventory.cast<EquipmentItem?>().firstWhere(
            (e) => e?.id == equippedWeaponId,
            orElse: () => null,
          );

  EquipmentItem? get equippedArmor =>
      equippedArmorId == null ? null : inventory.cast<EquipmentItem?>().firstWhere(
            (e) => e?.id == equippedArmorId,
            orElse: () => null,
          );

  EquipmentItem? get equippedAccessory =>
      equippedAccessoryId == null ? null : inventory.cast<EquipmentItem?>().firstWhere(
            (e) => e?.id == equippedAccessoryId,
            orElse: () => null,
          );

  int get _equippedAtkBonus =>
      (equippedWeapon?.attackBonus ?? 0) +
      (equippedArmor?.attackBonus ?? 0) +
      (equippedAccessory?.attackBonus ?? 0);

  int get _equippedDefBonus =>
      (equippedWeapon?.defenseBonus ?? 0) +
      (equippedArmor?.defenseBonus ?? 0) +
      (equippedAccessory?.defenseBonus ?? 0);

  int get _equippedAgiBonus =>
      (equippedWeapon?.agilityBonus ?? 0) +
      (equippedArmor?.agilityBonus ?? 0) +
      (equippedAccessory?.agilityBonus ?? 0);

  int get _equippedHpBonus =>
      (equippedWeapon?.hpBonus ?? 0) +
      (equippedArmor?.hpBonus ?? 0) +
      (equippedAccessory?.hpBonus ?? 0);

  CharacterData copyWith({
    int? level,
    int? gold,
    int? currentHp,
    int? statStr,
    int? statInt,
    int? statAgi,
    int? statVit,
    int? statPoints,
    List<EquipmentItem>? inventory,
    String? equippedWeaponId,
    String? equippedArmorId,
    String? equippedAccessoryId,
    bool clearWeapon = false,
    bool clearArmor = false,
    bool clearAccessory = false,
    int? totalWins,
    int? totalLosses,
    String? lastBossDate,
    String? lastDailyClearDate,
    String? dailyBattleDate,
    List<String>? defeatedEnemyIds,
  }) {
    return CharacterData(
      type: type,
      level: level ?? this.level,
      gold: gold ?? this.gold,
      currentHp: currentHp ?? this.currentHp,
      statStr: statStr ?? this.statStr,
      statInt: statInt ?? this.statInt,
      statAgi: statAgi ?? this.statAgi,
      statVit: statVit ?? this.statVit,
      statPoints: statPoints ?? this.statPoints,
      inventory: inventory ?? this.inventory,
      equippedWeaponId: clearWeapon ? null : (equippedWeaponId ?? this.equippedWeaponId),
      equippedArmorId: clearArmor ? null : (equippedArmorId ?? this.equippedArmorId),
      equippedAccessoryId: clearAccessory ? null : (equippedAccessoryId ?? this.equippedAccessoryId),
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      lastBossDate: lastBossDate ?? this.lastBossDate,
      lastDailyClearDate: lastDailyClearDate ?? this.lastDailyClearDate,
      dailyBattleDate: dailyBattleDate ?? this.dailyBattleDate,
      defeatedEnemyIds: defeatedEnemyIds ?? this.defeatedEnemyIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'level': level,
        'gold': gold,
        'currentHp': currentHp,
        'statStr': statStr,
        'statInt': statInt,
        'statAgi': statAgi,
        'statVit': statVit,
        'statPoints': statPoints,
        'inventory': inventory.map((e) => e.toJson()).toList(),
        'equippedWeaponId': equippedWeaponId,
        'equippedArmorId': equippedArmorId,
        'equippedAccessoryId': equippedAccessoryId,
        'totalWins': totalWins,
        'totalLosses': totalLosses,
        'lastBossDate': lastBossDate,
        'lastDailyClearDate': lastDailyClearDate,
        'dailyBattleDate': dailyBattleDate,
        'defeatedEnemyIds': defeatedEnemyIds,
      };

  factory CharacterData.fromJson(Map<String, dynamic> j) => CharacterData(
        type: CharacterType.values[j['type'] as int],
        level: j['level'] as int? ?? 1,
        gold: j['gold'] as int? ?? 0,
        currentHp: j['currentHp'] as int? ?? -1,
        statStr: j['statStr'] as int? ?? 5,
        statInt: j['statInt'] as int? ?? 5,
        statAgi: j['statAgi'] as int? ?? 5,
        statVit: j['statVit'] as int? ?? 5,
        statPoints: j['statPoints'] as int? ?? 0,
        inventory: (j['inventory'] as List<dynamic>? ?? [])
            .map((e) => EquipmentItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        equippedWeaponId: j['equippedWeaponId'] as String?,
        equippedArmorId: j['equippedArmorId'] as String?,
        equippedAccessoryId: j['equippedAccessoryId'] as String?,
        totalWins: j['totalWins'] as int? ?? 0,
        totalLosses: j['totalLosses'] as int? ?? 0,
        lastBossDate: j['lastBossDate'] as String?,
        lastDailyClearDate: j['lastDailyClearDate'] as String?,
        dailyBattleDate: j['dailyBattleDate'] as String?,
        defeatedEnemyIds: (j['defeatedEnemyIds'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );

  // Starting stats per class
  static CharacterData initial(CharacterType type) {
    switch (type) {
      case CharacterType.warrior:
        return CharacterData(type: type, statStr: 8, statInt: 3, statAgi: 4, statVit: 8, currentHp: -1);
      case CharacterType.mage:
        return CharacterData(type: type, statStr: 3, statInt: 10, statAgi: 5, statVit: 5, currentHp: -1);
      case CharacterType.rogue:
        return CharacterData(type: type, statStr: 6, statInt: 4, statAgi: 10, statVit: 5, currentHp: -1);
    }
  }
}

// ───────────────── Enemy ─────────────────

class Enemy {
  final String id;
  final String name;
  final String emoji;
  final int level;
  final int maxHp;
  final int attack;
  final int defense;
  final int speed;
  final int xpReward;
  final int goldReward;
  final List<EquipmentItem> possibleDrops;
  final bool isBoss;

  const Enemy({
    required this.id,
    required this.name,
    required this.emoji,
    required this.level,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.speed,
    required this.xpReward,
    required this.goldReward,
    this.possibleDrops = const [],
    this.isBoss = false,
  });

  static Enemy bossForLevel(int playerLevel) {
    final lvl = (playerLevel * 1.5).ceil();
    return Enemy(
      id: 'boss',
      name: '일일 보스',
      emoji: lvl >= 15 ? '🐉' : lvl >= 8 ? '👹' : '💀',
      level: lvl,
      maxHp: 200 + lvl * 30,
      attack: 20 + lvl * 4,
      defense: 10 + lvl * 2,
      speed: 8 + lvl,
      xpReward: 50 + lvl * 10,
      goldReward: 30 + lvl * 5,
      possibleDrops: _randomDrops(EquipmentRarity.rare),
      isBoss: true,
    );
  }

  static List<Enemy> stageEnemies(int playerLevel) {
    if (playerLevel <= 3) {
      return [
        Enemy(id: 'stage_0', name: '슬라임', emoji: '🟢', level: 1, maxHp: 30, attack: 5, defense: 0, speed: 3, xpReward: 10, goldReward: 5, possibleDrops: _randomDrops(EquipmentRarity.common)),
        Enemy(id: 'stage_1', name: '버섯괴물', emoji: '🍄', level: 2, maxHp: 45, attack: 7, defense: 1, speed: 2, xpReward: 15, goldReward: 7, possibleDrops: _randomDrops(EquipmentRarity.common)),
        Enemy(id: 'stage_2', name: '박쥐', emoji: '🦇', level: 3, maxHp: 35, attack: 9, defense: 0, speed: 6, xpReward: 18, goldReward: 9, possibleDrops: _randomDrops(EquipmentRarity.common)),
      ];
    } else if (playerLevel <= 8) {
      return [
        Enemy(id: 'stage_0', name: '고블린', emoji: '👺', level: 5, maxHp: 80, attack: 15, defense: 5, speed: 5, xpReward: 30, goldReward: 12, possibleDrops: _randomDrops(EquipmentRarity.common)),
        Enemy(id: 'stage_1', name: '늑대', emoji: '🐺', level: 6, maxHp: 70, attack: 18, defense: 3, speed: 8, xpReward: 35, goldReward: 14, possibleDrops: _randomDrops(EquipmentRarity.rare)),
        Enemy(id: 'stage_2', name: '해골 병사', emoji: '💀', level: 8, maxHp: 100, attack: 20, defense: 8, speed: 4, xpReward: 40, goldReward: 18, possibleDrops: _randomDrops(EquipmentRarity.rare)),
      ];
    } else if (playerLevel <= 15) {
      return [
        Enemy(id: 'stage_0', name: '오크', emoji: '👹', level: 10, maxHp: 200, attack: 35, defense: 15, speed: 5, xpReward: 60, goldReward: 25, possibleDrops: _randomDrops(EquipmentRarity.rare)),
        Enemy(id: 'stage_1', name: '다크 엘프', emoji: '🧝', level: 12, maxHp: 170, attack: 40, defense: 10, speed: 12, xpReward: 70, goldReward: 30, possibleDrops: _randomDrops(EquipmentRarity.epic)),
        Enemy(id: 'stage_2', name: '어둠의 기사', emoji: '🏴', level: 15, maxHp: 300, attack: 50, defense: 18, speed: 6, xpReward: 80, goldReward: 35, possibleDrops: _randomDrops(EquipmentRarity.epic)),
      ];
    } else {
      return [
        Enemy(id: 'stage_0', name: '원소 정령', emoji: '🌪️', level: 18, maxHp: 400, attack: 60, defense: 20, speed: 10, xpReward: 100, goldReward: 50, possibleDrops: _randomDrops(EquipmentRarity.epic)),
        Enemy(id: 'stage_1', name: '악마 군주', emoji: '😈', level: 22, maxHp: 500, attack: 75, defense: 25, speed: 8, xpReward: 130, goldReward: 65, possibleDrops: _randomDrops(EquipmentRarity.legendary)),
        Enemy(id: 'stage_2', name: '불사 드래곤', emoji: '🔥', level: 25, maxHp: 700, attack: 90, defense: 30, speed: 7, xpReward: 160, goldReward: 80, possibleDrops: _randomDrops(EquipmentRarity.legendary)),
      ];
    }
  }

  static List<EquipmentItem> _randomDrops(EquipmentRarity rarity) {
    final rng = Random();
    final weapons = [
      EquipmentItem(id: 'w_${rarity.index}_1', name: _weaponName(rarity), emoji: _weaponEmoji(rarity), type: EquipmentType.weapon, rarity: rarity, attackBonus: _statBonus(rarity)),
    ];
    final armors = [
      EquipmentItem(id: 'a_${rarity.index}_1', name: _armorName(rarity), emoji: _armorEmoji(rarity), type: EquipmentType.armor, rarity: rarity, defenseBonus: _statBonus(rarity), hpBonus: _statBonus(rarity) * 2),
    ];
    final accessories = [
      EquipmentItem(id: 'acc_${rarity.index}_1', name: _accessoryName(rarity), emoji: '💍', type: EquipmentType.accessory, rarity: rarity, agilityBonus: _statBonus(rarity)),
    ];
    return rng.nextBool() ? weapons : rng.nextBool() ? armors : accessories;
  }

  static int _statBonus(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return 15;
      case EquipmentRarity.epic: return 10;
      case EquipmentRarity.rare: return 5;
      default: return 2;
    }
  }

  static String _weaponName(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return '전설의 검';
      case EquipmentRarity.epic: return '에픽 검';
      case EquipmentRarity.rare: return '강철 검';
      default: return '낡은 검';
    }
  }

  static String _weaponEmoji(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return '⚡';
      case EquipmentRarity.epic: return '🗡️';
      case EquipmentRarity.rare: return '⚔️';
      default: return '🔪';
    }
  }

  static String _armorName(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return '신성한 갑옷';
      case EquipmentRarity.epic: return '에픽 갑옷';
      case EquipmentRarity.rare: return '강철 갑옷';
      default: return '가죽 갑옷';
    }
  }

  static String _armorEmoji(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return '🛡️';
      case EquipmentRarity.epic: return '🥋';
      case EquipmentRarity.rare: return '🦺';
      default: return '👕';
    }
  }

  static String _accessoryName(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return '전설의 반지';
      case EquipmentRarity.epic: return '에픽 목걸이';
      case EquipmentRarity.rare: return '은 반지';
      default: return '낡은 장신구';
    }
  }
}

// ───────────────── Battle ─────────────────

enum BattleEventType { playerAttack, enemyAttack, playerSkill, dodge, victory, defeat }

class BattleEvent {
  final BattleEventType type;
  final String message;
  final int playerDmg;  // damage player took
  final int enemyDmg;   // damage enemy took
  final int playerHp;
  final int enemyHp;

  const BattleEvent({
    required this.type,
    required this.message,
    this.playerDmg = 0,
    this.enemyDmg = 0,
    required this.playerHp,
    required this.enemyHp,
  });
}

class BattleResult {
  final bool playerWon;
  final bool isBoss;
  final String enemyId;
  final List<BattleEvent> events;
  final int xpGained;
  final int goldGained;
  final int hpLost;
  final EquipmentItem? droppedItem;

  const BattleResult({
    required this.playerWon,
    required this.isBoss,
    required this.enemyId,
    required this.events,
    required this.xpGained,
    required this.goldGained,
    required this.hpLost,
    this.droppedItem,
  });
}

class BattleEngine {
  static BattleResult simulate(CharacterData player, Enemy enemy) {
    final rng = Random();
    final events = <BattleEvent>[];

    int playerHp = player.hp;
    int enemyHp = enemy.maxHp;

    final playerFirst = player.effectiveSpd >= enemy.speed;
    int round = 0;

    while (playerHp > 0 && enemyHp > 0 && round < 30) {
      round++;

      // Player's turn
      if (playerFirst || round > 1) {
        final evaded = rng.nextDouble() < _evasionChance(enemy.speed, player.effectiveSpd);
        if (evaded) {
          events.add(BattleEvent(
            type: BattleEventType.dodge,
            message: '${enemy.name}이(가) 공격을 회피했다!',
            playerHp: playerHp, enemyHp: enemyHp,
          ));
        } else {
          final isSkill = round % 3 == 0; // skill every 3rd round
          final dmg = _calcDamage(player.effectiveAtk, enemy.defense, rng, isSkill ? 1.5 : 1.0);
          enemyHp = max(0, enemyHp - dmg);

          final skillName = _skillName(player.type);
          events.add(BattleEvent(
            type: isSkill ? BattleEventType.playerSkill : BattleEventType.playerAttack,
            message: isSkill
                ? '$skillName! ${enemy.name}에게 $dmg 데미지!'
                : '${enemy.name}에게 $dmg 데미지!',
            enemyDmg: dmg,
            playerHp: playerHp, enemyHp: enemyHp,
          ));
        }
      }

      if (enemyHp <= 0) break;

      // Enemy's turn
      final playerEvaded = rng.nextDouble() < _evasionChance(player.effectiveSpd, enemy.speed);
      if (playerEvaded) {
        events.add(BattleEvent(
          type: BattleEventType.dodge,
          message: '공격을 회피했다!',
          playerHp: playerHp, enemyHp: enemyHp,
        ));
      } else {
        final dmg = _calcDamage(enemy.attack, player.effectiveDef, rng, 1.0);
        playerHp = max(0, playerHp - dmg);
        events.add(BattleEvent(
          type: BattleEventType.enemyAttack,
          message: '${enemy.name}의 공격! $dmg 데미지!',
          playerDmg: dmg,
          playerHp: playerHp, enemyHp: enemyHp,
        ));
      }
    }

    final won = enemyHp <= 0;
    final hpLost = player.hp - playerHp;

    // Drop check
    EquipmentItem? drop;
    if (won && enemy.possibleDrops.isNotEmpty) {
      final dropChance = enemy.isBoss ? 0.8 : 0.3;
      if (rng.nextDouble() < dropChance) {
        drop = enemy.possibleDrops[rng.nextInt(enemy.possibleDrops.length)];
        drop = EquipmentItem(
          id: 'drop_${DateTime.now().millisecondsSinceEpoch}',
          name: drop.name,
          emoji: drop.emoji,
          type: drop.type,
          rarity: drop.rarity,
          attackBonus: drop.attackBonus,
          defenseBonus: drop.defenseBonus,
          agilityBonus: drop.agilityBonus,
          hpBonus: drop.hpBonus,
        );
      }
    }

    events.add(BattleEvent(
      type: won ? BattleEventType.victory : BattleEventType.defeat,
      message: won ? '승리! 🎉' : '패배... 💀',
      playerHp: playerHp, enemyHp: enemyHp,
    ));

    return BattleResult(
      playerWon: won,
      isBoss: enemy.isBoss,
      enemyId: enemy.id,
      events: events,
      xpGained: won ? enemy.xpReward : (enemy.xpReward ~/ 4),
      goldGained: won ? enemy.goldReward : 0,
      hpLost: hpLost.clamp(0, player.hp),
      droppedItem: drop,
    );
  }

  static double _evasionChance(int mySpd, int enemySpd) {
    final diff = mySpd - enemySpd;
    return diff > 0 ? (diff * 0.03).clamp(0.0, 0.25) : 0.0;
  }

  static int _calcDamage(int atk, int def, Random rng, double multiplier) {
    final base = max(1, atk - def);
    final variance = (base * 0.2 * rng.nextDouble()).round();
    return max(1, ((base + variance) * multiplier).round());
  }

  static String _skillName(CharacterType type) {
    switch (type) {
      case CharacterType.warrior: return '⚔️ 강타';
      case CharacterType.mage: return '🔥 화염구';
      case CharacterType.rogue: return '🗡️ 독 투척';
    }
  }
}
