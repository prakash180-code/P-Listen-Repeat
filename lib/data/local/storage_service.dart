import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:listen_repeat/core/utils/logger.dart';
import 'package:listen_repeat/data/models/lesson.dart';
import 'package:listen_repeat/data/models/progress.dart';

class StorageService {
  static const String _lessonsKey = 'lessons';
  static const String _progressKey = 'progress';
  static const String _settingsKey = 'settings';

  SharedPreferences? _prefs;

  Future<void> init() async {
    AppLogger.i('Initializing storage service');
    _prefs = await SharedPreferences.getInstance();
    AppLogger.i('Storage service initialized');
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  Future<void> saveLessons(List<Lesson> lessons) async {
    final jsonList = lessons.map((l) => l.toJson()).toList();
    await prefs.setString(_lessonsKey, jsonEncode(jsonList));
    AppLogger.i('Saved ${lessons.length} lessons');
  }

  List<Lesson> getLessons() {
    final jsonString = prefs.getString(_lessonsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((j) => Lesson.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Lesson? getLesson(String id) {
    return getLessons()
        .where((l) => l.id == id)
        .cast<Lesson?>()
        .firstWhere((l) => l != null, orElse: () => null);
  }

  Future<void> saveProgress(Progress progress) async {
    final all = getAllProgressMap();
    all[progress.phraseId] = progress.toJson();
    await prefs.setString(_progressKey, jsonEncode(all));
    AppLogger.progress('Saved progress for phrase ${progress.phraseId}');
  }

  Progress? getProgress(String phraseId) {
    final all = getAllProgressMap();
    final json = all[phraseId];
    if (json == null) return null;
    return Progress.fromJson(json as Map<String, dynamic>);
  }

  List<Progress> getAllProgress() {
    final all = getAllProgressMap();
    return all.values
        .map((json) => Progress.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> getAllProgressMap() {
    final jsonString = prefs.getString(_progressKey);
    if (jsonString == null) return {};
    final Map<String, dynamic> map = jsonDecode(jsonString);
    return map;
  }

  Future<void> saveLastActivePhrase(String lessonId, String phraseId) async {
    final settings = _getSettingsMap();
    settings['lastActiveLessonId'] = lessonId;
    settings['lastActivePhraseId'] = phraseId;
    await prefs.setString(_settingsKey, jsonEncode(settings));
    AppLogger.progress('Saved last active phrase: $phraseId');
  }

  (String? lessonId, String? phraseId) getLastActivePhrase() {
    final settings = _getSettingsMap();
    final lessonId = settings['lastActiveLessonId'] as String?;
    final phraseId = settings['lastActivePhraseId'] as String?;
    return (lessonId, phraseId);
  }

  Map<String, dynamic> _getSettingsMap() {
    final jsonString = prefs.getString(_settingsKey);
    if (jsonString == null) return {};
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  Future<void> clearAll() async {
    await prefs.remove(_lessonsKey);
    await prefs.remove(_progressKey);
    await prefs.remove(_settingsKey);
    AppLogger.i('Cleared all local data');
  }
}
