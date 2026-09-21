import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:listen_repeat/data/models/lesson.dart';
import 'package:listen_repeat/data/repositories/lesson_repository.dart';
import 'package:listen_repeat/data/repositories/progress_repository.dart';
import 'package:listen_repeat/features/practice/practice_controller.dart';
import 'package:listen_repeat/features/practice/practice_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lessonRepo = context.watch<LessonRepository>();
    final progressRepo = context.watch<ProgressRepository>();
    final lessons = lessonRepo.getLessons();
    final allProgress = progressRepo.getAllProgress();
    final lastActive = progressRepo.getLastActive();

    final completedCount = allProgress.where((p) => p.completed).length;
    final daysPracticed = allProgress
        .where((p) => p.lastPracticed != null)
        .map(
          (p) => DateTime(
            p.lastPracticed!.year,
            p.lastPracticed!.month,
            p.lastPracticed!.day,
          ),
        )
        .toSet()
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Listen & Repeat'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (lastActive.$1 != null && lastActive.$2 != null)
            _ContinueCard(lessonId: lastActive.$1!, phraseId: lastActive.$2!),
          const SizedBox(height: 24),
          _ProgressSummary(
            completedCount: completedCount,
            lessonsStarted: lessons.length,
            daysPracticed: daysPracticed,
          ),
          const SizedBox(height: 24),
          Text('Lessons', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          ...lessons.map((lesson) => _LessonTile(lesson: lesson)),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String lessonId;
  final String phraseId;

  const _ContinueCard({required this.lessonId, required this.phraseId});

  @override
  Widget build(BuildContext context) {
    final lessonRepo = context.read<LessonRepository>();
    final lesson = lessonRepo.getLesson(lessonId);
    if (lesson == null) return const SizedBox.shrink();

    final phrases = lessonRepo.getPhrasesForLesson(lessonId);
    final currentIndex = phrases.indexWhere((p) => p.id == phraseId);
    final total = phrases.length;
    final current = currentIndex >= 0 ? currentIndex + 1 : 1;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () async {
          if (currentIndex >= 0 && currentIndex < phrases.length) {
            final controller = context.read<PracticeController>();
            await controller.loadPhrase(lesson, phrases[currentIndex]);
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: controller,
                    child: const PracticeScreen(),
                  ),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Continue Learning',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(lesson.title, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text(
                'Phrase $current of $total',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: total > 0 ? current / total : 0,
                minHeight: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final int completedCount;
  final int lessonsStarted;
  final int daysPracticed;

  const _ProgressSummary({
    required this.completedCount,
    required this.lessonsStarted,
    required this.daysPracticed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: 'Completed', value: '$completedCount'),
                _StatItem(label: 'Lessons', value: '$lessonsStarted'),
                _StatItem(label: 'Days', value: '$daysPracticed'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;

  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final lessonRepo = context.read<LessonRepository>();
    final phrases = lessonRepo.getPhrasesForLesson(lesson.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(lesson.title),
        subtitle: Text('${phrases.length} phrases'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          if (phrases.isNotEmpty) {
            final controller = context.read<PracticeController>();
            await controller.loadPhrase(lesson, phrases.first);
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: controller,
                    child: const PracticeScreen(),
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }
}
