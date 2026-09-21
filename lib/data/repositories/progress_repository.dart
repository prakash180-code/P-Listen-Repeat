import 'package:listen_repeat/core/utils/logger.dart';
import 'package:listen_repeat/data/local/storage_service.dart';
import 'package:listen_repeat/data/models/phrase.dart';
import 'package:listen_repeat/data/models/progress.dart';

class ProgressRepository {
  final StorageService storage;

  ProgressRepository(this.storage);

  Future<void> ensureProgressEntries(List<Phrase> phrases) async {
    for (final phrase in phrases) {
      if (storage.getProgress(phrase.id) == null) {
        await storage.saveProgress(Progress(phraseId: phrase.id));
      }
    }
  }

  Progress? getProgress(String phraseId) => storage.getProgress(phraseId);

  Future<void> markListened(String phraseId) async {
    final progress =
        storage.getProgress(phraseId) ?? Progress(phraseId: phraseId);
    final updated = progress.copyWith(
      listened: true,
      lastPracticed: DateTime.now(),
      attempts: progress.attempts + 1,
    );
    await storage.saveProgress(updated);
    AppLogger.progress('Marked listened: $phraseId');
  }

  Future<void> markRepeated(String phraseId) async {
    final progress =
        storage.getProgress(phraseId) ?? Progress(phraseId: phraseId);
    final updated = progress.copyWith(
      repeated: true,
      lastPracticed: DateTime.now(),
      attempts: progress.attempts + 1,
    );
    await storage.saveProgress(updated);
    AppLogger.progress('Marked repeated: $phraseId');
  }

  Future<void> markShadowed(String phraseId) async {
    final progress =
        storage.getProgress(phraseId) ?? Progress(phraseId: phraseId);
    final updated = progress.copyWith(
      shadowed: true,
      lastPracticed: DateTime.now(),
      attempts: progress.attempts + 1,
    );
    await storage.saveProgress(updated);
    AppLogger.progress('Marked shadowed: $phraseId');
  }

  Future<void> markCompleted(String phraseId) async {
    final progress =
        storage.getProgress(phraseId) ?? Progress(phraseId: phraseId);
    final updated = progress.copyWith(
      completed: true,
      lastPracticed: DateTime.now(),
      attempts: progress.attempts + 1,
    );
    await storage.saveProgress(updated);
    AppLogger.progress('Marked completed: $phraseId');
  }

  Future<void> saveLastActive(String lessonId, String phraseId) async {
    await storage.saveLastActivePhrase(lessonId, phraseId);
  }

  (String? lessonId, String? phraseId) getLastActive() =>
      storage.getLastActivePhrase();

  List<Progress> getAllProgress() => storage.getAllProgress();

  Future<void> resetProgress() async {
    await storage.clearAll();
    AppLogger.i('Progress reset');
  }
}
