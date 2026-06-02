import 'package:flutter/foundation.dart';
import '../models/character_model.dart';
import '../services/storage_service.dart';

class CharacterProvider extends ChangeNotifier {
  CharacterData? _character;
  bool _isLoaded = false;

  CharacterData? get character => _character;
  bool get isLoaded => _isLoaded;
  bool get hasCharacter => _character != null;

  Future<void> init() async {
    _character = await StorageService.loadCharacter();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> createCharacter(CharacterType type) async {
    _character = CharacterData.initial(type);
    await _save();
    notifyListeners();
  }

  // Called when todo is completed — restore HP
  Future<void> onTodoCompleted({required String difficulty, required int gold}) async {
    if (_character == null) return;
    final hpRestore = difficulty == 'HARD' ? 15 : difficulty == 'NORMAL' ? 10 : 5;
    final newHp = (_character!.hp + hpRestore).clamp(0, _character!.maxHp);
    _character = _character!.copyWith(
      currentHp: newHp,
      gold: _character!.gold + gold,
    );
    await _save();
    notifyListeners();
  }

  // Called when todo is missed (past due, not completed)
  Future<void> onTodoMissed({required String difficulty}) async {
    if (_character == null) return;
    final hpLoss = difficulty == 'HARD' ? 20 : difficulty == 'NORMAL' ? 10 : 5;
    final newHp = (_character!.hp - hpLoss).clamp(0, _character!.maxHp);
    _character = _character!.copyWith(currentHp: newHp);
    await _save();
    notifyListeners();
  }

  // Sync level from TodoProvider
  Future<void> syncLevel(int level) async {
    if (_character == null) return;
    if (_character!.level == level) return;

    final levelsGained = level - _character!.level;
    if (levelsGained <= 0) return;

    _character = _character!.copyWith(
      level: level,
      statPoints: _character!.statPoints + levelsGained,
    );
    await _save();
    notifyListeners();
  }

  // Allocate stat point on level up
  Future<void> allocateStat(String stat) async {
    if (_character == null || _character!.statPoints <= 0) return;
    _character = _character!.copyWith(
      statStr: stat == 'str' ? _character!.statStr + 1 : null,
      statInt: stat == 'int' ? _character!.statInt + 1 : null,
      statAgi: stat == 'agi' ? _character!.statAgi + 1 : null,
      statVit: stat == 'vit' ? _character!.statVit + 1 : null,
      statPoints: _character!.statPoints - 1,
    );
    await _save();
    notifyListeners();
  }

  // Apply battle result
  Future<void> applyBattleResult(BattleResult result) async {
    if (_character == null) return;
    final newHp = (_character!.hp - result.hpLost).clamp(0, _character!.maxHp);
    var updated = _character!.copyWith(
      currentHp: newHp,
      gold: _character!.gold + result.goldGained,
      totalWins: result.playerWon ? _character!.totalWins + 1 : null,
      totalLosses: result.playerWon ? null : _character!.totalLosses + 1,
      lastBossDate: result.playerWon && result.isBoss
          ? DateTime.now().toIso8601String().substring(0, 10)
          : null,
    );
    if (result.droppedItem != null) {
      updated = updated.copyWith(
        inventory: [..._character!.inventory, result.droppedItem!],
      );
    }
    _character = updated;
    await _save();
    notifyListeners();
  }

  // Equip an item from inventory
  Future<void> equipItem(String itemId) async {
    if (_character == null) return;
    final item = _character!.inventory.where((e) => e.id == itemId).firstOrNull;
    if (item == null) return;

    _character = _character!.copyWith(
      equippedWeaponId: item.type == EquipmentType.weapon ? itemId : null,
      equippedArmorId: item.type == EquipmentType.armor ? itemId : null,
      equippedAccessoryId: item.type == EquipmentType.accessory ? itemId : null,
    );
    await _save();
    notifyListeners();
  }

  // Unequip slot
  Future<void> unequipSlot(EquipmentType slot) async {
    if (_character == null) return;
    _character = _character!.copyWith(
      clearWeapon: slot == EquipmentType.weapon,
      clearArmor: slot == EquipmentType.armor,
      clearAccessory: slot == EquipmentType.accessory,
    );
    await _save();
    notifyListeners();
  }

  // Sell item from inventory
  Future<void> sellItem(String itemId) async {
    if (_character == null) return;
    final item = _character!.inventory.where((e) => e.id == itemId).firstOrNull;
    if (item == null) return;
    final price = _sellPrice(item.rarity);
    _character = _character!.copyWith(
      inventory: _character!.inventory.where((e) => e.id != itemId).toList(),
      gold: _character!.gold + price,
    );
    await _save();
    notifyListeners();
  }

  int _sellPrice(EquipmentRarity r) {
    switch (r) {
      case EquipmentRarity.legendary: return 200;
      case EquipmentRarity.epic: return 80;
      case EquipmentRarity.rare: return 30;
      default: return 10;
    }
  }

  // Restore HP with gold (shop)
  Future<bool> restoreHpWithGold(int amount) async {
    if (_character == null) return false;
    const cost = 20;
    if (_character!.gold < cost) return false;
    final newHp = (_character!.hp + amount).clamp(0, _character!.maxHp);
    _character = _character!.copyWith(currentHp: newHp, gold: _character!.gold - cost);
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> _save() async {
    if (_character != null) await StorageService.saveCharacter(_character!);
  }
}
