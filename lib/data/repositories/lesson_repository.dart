import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:listen_repeat/core/constants/app_constants.dart';
import 'package:listen_repeat/core/utils/logger.dart';
import 'package:listen_repeat/data/models/lesson.dart';
import 'package:listen_repeat/data/models/phrase.dart';
import 'package:listen_repeat/data/local/audio_asset_manager.dart';
import 'package:listen_repeat/data/local/storage_service.dart';
import 'package:listen_repeat/data/repositories/progress_repository.dart';

class LessonRepository {
  final StorageService storage;
  final AudioAssetManager audioAssetManager;
  final ProgressRepository progressRepository;
  final Map<String, List<Phrase>> _phrasesByLesson = {};

  LessonRepository({
    required this.storage,
    required this.audioAssetManager,
    required this.progressRepository,
  });

  Future<void> loadLessons() async {
    try {
      final jsonString = await rootBundle.loadString(
        AppConstants.lessonsAssetPath,
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      final lessons = <Lesson>[];
      _phrasesByLesson.clear();

      for (final item in jsonList) {
        final lesson = Lesson.fromJson(item as Map<String, dynamic>);
        lessons.add(lesson);

        final phrasesJson = item['phrases'] as List<dynamic>? ?? [];
        final phrases = <Phrase>[];
        for (final p in phrasesJson) {
          final phrase = Phrase.fromJson(p as Map<String, dynamic>);
          phrases.add(phrase);
        }
        _phrasesByLesson[lesson.id] = phrases;
      }

      await storage.saveLessons(lessons);
      final allPhrases = _phrasesByLesson.values.expand((e) => e).toList();
      await progressRepository.ensureProgressEntries(allPhrases);
      AppLogger.i(
        'Loaded ${lessons.length} lessons with ${allPhrases.length} phrases',
      );
    } catch (e, stackTrace) {
      AppLogger.e('Failed to load lessons', e, stackTrace);
      rethrow;
    }
  }

  List<Lesson> getLessons() => storage.getLessons();

  Lesson? getLesson(String id) => storage.getLesson(id);

  List<Phrase> getPhrasesForLesson(String lessonId) {
    return _phrasesByLesson[lessonId] ?? [];
  }

  Future<Phrase> resolveAudioPath(Phrase phrase) async {
    final fullPath = await audioAssetManager.getAssetAudioPath(
      phrase.audioPath,
    );
    return Phrase(
      id: phrase.id,
      lessonId: phrase.lessonId,
      text: phrase.text,
      audioPath: fullPath ?? phrase.audioPath,
      pronunciationText: phrase.pronunciationText,
      order: phrase.order,
      difficulty: phrase.difficulty,
    );
  }
}
