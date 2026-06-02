import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/character_model.dart';
import '../../../core/providers/character_provider.dart';
import '../../../core/theme/app_theme.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  CharacterType? _selected;

  static const _classes = [
    _ClassInfo(
      type: CharacterType.warrior,
      emoji: '⚔️',
      name: '전사',
      desc: '강인한 체력과 높은 공격력으로\n정면 돌파하는 근접 전투의 달인',
      statLabels: ['STR +8', 'INT +3', 'AGI +4', 'VIT +8'],
      color: Color(0xFFEF4444),
      skill: '강타 — 3라운드마다 1.5배 피해',
    ),
    _ClassInfo(
      type: CharacterType.mage,
      emoji: '🔥',
      name: '마법사',
      desc: '높은 마력으로 강력한 마법을\n구사하는 원거리 공격형 직업',
      statLabels: ['STR +3', 'INT +10', 'AGI +5', 'VIT +5'],
      color: Color(0xFF8B5CF6),
      skill: '화염구 — 3라운드마다 1.5배 피해',
    ),
    _ClassInfo(
      type: CharacterType.rogue,
      emoji: '🗡️',
      name: '도적',
      desc: '빠른 민첩성으로 회피하고\n독으로 적을 약화시키는 트릭스터',
      statLabels: ['STR +6', 'INT +4', 'AGI +10', 'VIT +5'],
      color: Color(0xFF22C55E),
      skill: '독 투척 — 3라운드마다 1.5배 피해',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('직업을 선택하세요',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('나중에 변경할 수 없으니 신중하게 선택하세요.',
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 14)),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: _classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final info = _classes[i];
                    final isSelected = _selected == info.type;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = info.type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? info.color : AppColors.border,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: info.color.withOpacity(0.25), blurRadius: 16, spreadRadius: 2)]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: info.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(info.emoji,
                                    style: const TextStyle(fontSize: 32)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(info.name,
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? info.color : AppColors.foreground)),
                                      const SizedBox(width: 8),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: info.color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text('선택됨',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: info.color,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(info.desc,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.mutedForeground,
                                          height: 1.5)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: info.statLabels.map((s) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: info.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(s, style: TextStyle(fontSize: 11, color: info.color, fontWeight: FontWeight.w600)),
                                    )).toList(),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('✦ ${info.skill}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('모험 시작!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    await context.read<CharacterProvider>().createCharacter(_selected!);
    // CharacterProvider notifies listeners → CharacterScreen rebuilds automatically
  }
}

class _ClassInfo {
  final CharacterType type;
  final String emoji;
  final String name;
  final String desc;
  final List<String> statLabels;
  final Color color;
  final String skill;

  const _ClassInfo({
    required this.type,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.statLabels,
    required this.color,
    required this.skill,
  });
}
