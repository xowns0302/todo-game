import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/character_provider.dart';
import '../../../core/theme/app_theme.dart';

class StatUpDialog extends StatefulWidget {
  final int points;
  const StatUpDialog({super.key, required this.points});

  @override
  State<StatUpDialog> createState() => _StatUpDialogState();
}

class _StatUpDialogState extends State<StatUpDialog> {
  int _remaining = 0;
  final Map<String, int> _added = {'str': 0, 'int': 0, 'agi': 0, 'vit': 0};

  @override
  void initState() {
    super.initState();
    _remaining = widget.points;
  }

  static const _statInfo = [
    {'key': 'str', 'label': '힘 (STR)', 'desc': '물리 공격력 증가', 'emoji': '💪', 'color': Color(0xFFEF4444)},
    {'key': 'int', 'label': '지능 (INT)', 'desc': '마법 공격력 증가', 'emoji': '🧠', 'color': Color(0xFF8B5CF6)},
    {'key': 'agi', 'label': '민첩 (AGI)', 'desc': '속도 및 회피율 증가', 'emoji': '💨', 'color': Color(0xFF22C55E)},
    {'key': 'vit', 'label': '체력 (VIT)', 'desc': '최대 HP 증가', 'emoji': '❤️', 'color': Color(0xFFF59E0B)},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          const Text('⬆️ 레벨 업!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('스탯 포인트 남음: $_remaining',
              style: const TextStyle(fontSize: 14, color: AppColors.mutedForeground)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statInfo.map((info) {
            final key = info['key'] as String;
            final color = info['color'] as Color;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(info['emoji'] as String, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info['label'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(info['desc'] as String,
                            style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _stepBtn(Icons.remove, color, () {
                        if (_added[key]! > 0) {
                          setState(() { _added[key] = _added[key]! - 1; _remaining++; });
                        }
                      }),
                      SizedBox(
                        width: 32,
                        child: Text('+${_added[key]}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                      ),
                      _stepBtn(Icons.add, color, () {
                        if (_remaining > 0) {
                          setState(() { _added[key] = _added[key]! + 1; _remaining--; });
                        }
                      }),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('나중에'),
        ),
        ElevatedButton(
          onPressed: _added.values.every((v) => v == 0) ? null : _apply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Future<void> _apply() async {
    final provider = context.read<CharacterProvider>();
    for (final entry in _added.entries) {
      for (var i = 0; i < entry.value; i++) {
        await provider.allocateStat(entry.key);
      }
    }
    if (mounted) Navigator.pop(context);
  }
}
