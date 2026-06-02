import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  static const List<CategoryModel> defaults = [
    CategoryModel(id: 'study', name: '공부', color: Color(0xFF3B82F6), icon: Icons.school),
    CategoryModel(id: 'health', name: '운동', color: Color(0xFF22C55E), icon: Icons.fitness_center),
    CategoryModel(id: 'personal', name: '개인', color: Color(0xFFA855F7), icon: Icons.person),
    CategoryModel(id: 'work', name: '업무', color: Color(0xFFF59E0B), icon: Icons.work),
    CategoryModel(id: 'social', name: '약속', color: Color(0xFFEC4899), icon: Icons.people),
    CategoryModel(id: 'hobby', name: '취미', color: Color(0xFF14B8A6), icon: Icons.palette),
  ];

  static CategoryModel? findById(String? id) {
    if (id == null) return null;
    try {
      return defaults.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
