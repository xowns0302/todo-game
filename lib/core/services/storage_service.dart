import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_model.dart';
import '../models/character_model.dart';

class StorageService {
  static const _todosKey = 'todos_v1';
  static const _totalXpKey = 'total_xp';
  static const _characterKey = 'character_v1';

  static Future<List<Todo>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_todosKey);
    if (jsonStr == null) return [];
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((j) => Todo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveTodos(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _todosKey, jsonEncode(todos.map((t) => t.toJson()).toList()));
  }

  static Future<int> loadTotalXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalXpKey) ?? 0;
  }

  static Future<void> saveTotalXp(int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalXpKey, xp);
  }

  static Future<CharacterData?> loadCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_characterKey);
    if (str == null) return null;
    return CharacterData.fromJson(jsonDecode(str) as Map<String, dynamic>);
  }

  static Future<void> saveCharacter(CharacterData character) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_characterKey, jsonEncode(character.toJson()));
  }

  // ── LMS ──────────────────────────────────────────────────────────────────
  static const _lmsTokenKey = 'lms_token';
  static Future<String?> loadLmsToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lmsTokenKey);
  }

  static Future<void> saveLmsToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lmsTokenKey, token);
  }

  static Future<void> clearLmsToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lmsTokenKey);
  }

}
