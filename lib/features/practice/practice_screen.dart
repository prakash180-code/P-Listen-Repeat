import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:listen_repeat/data/models/lesson.dart';
import 'package:listen_repeat/data/models/phrase.dart';
import 'package:listen_repeat/data/repositories/lesson_repository.dart';
import 'package:listen_repeat/features/practice/practice_controller.dart';
import 'package:listen_repeat/services/audio_service.dart';
import 'package:listen_repeat/services/audio_validation_service.dart';
import 'package:listen_repeat/services/recording_service.dart';
import 'package:just_audio/just_audio.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PracticeController>(
      builder: (context, controller, child) {
        final lesson = controller.currentLesson;
        final phrase = controller.currentPhrase;

        if (controller.isLoading && phrase == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (phrase == null || lesson == null) {
          return const Scaffold(
            body: Center(child: Text('No phrase selected')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(lesson.title), elevation: 0),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 16),
              Text(
                phrase.text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'US English',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.clearError,
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _StepIndicator(
                label: 'STEP 1',
                title: 'Listen',
                child: _ListenStep(phrase: phrase),
              ),
              const SizedBox(height: 24),
              _StepIndicator(
                label: 'STEP 2',
                title: 'Repeat',
                child: const _RepeatStep(),
              ),
              const SizedBox(height: 24),
              _StepIndicator(
                label: 'STEP 3',
                title: 'Shadow',
                child: _ShadowStep(phrase: phrase),
              ),
              const SizedBox(height: 24),
              _CompleteStep(lesson: lesson, phrase: phrase),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final String label;
  final String title;
  final Widget child;

  const _StepIndicator({
    required this.label,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _ListenStep extends StatelessWidget {
  final Phrase phrase;

  const _ListenStep({required this.phrase});

  @override
  Widget build(BuildContext context) {
    final audioService = context.read<AudioService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<Duration>(
              stream: audioService.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: audioService.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    final max = duration.inMilliseconds.toDouble().clamp(
                      0,
                      double.infinity,
                    );
                    final maxVal = max > 0 ? max : 1.0;
                    return Column(
                      children: [
                        Slider(
                          value: position.inMilliseconds
                              .toDouble()
                              .clamp(0.0, maxVal)
                              .toDouble(),
                          max: maxVal.toDouble(),
                          onChanged: (value) {
                            audioService.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                        Row(
                          children: [
                            Text(_formatDuration(position)),
                            const Spacer(),
                            Text(_formatDuration(duration)),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<PlayerState>(
              stream: audioService.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return StreamBuilder<Duration>(
                  stream: audioService.positionStream,
                  builder: (context, posSnapshot) {
                    final currentPos = posSnapshot.data ?? Duration.zero;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.replay_10),
                          onPressed: () {
                            final newPos =
                                currentPos - const Duration(seconds: 10);
                            audioService.seek(
                              newPos > Duration.zero ? newPos : Duration.zero,
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          iconSize: 48,
                          icon: Icon(
                            playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                          ),
                          onPressed: playing
                              ? audioService.pause
                              : audioService.play,
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.forward_10),
                          onPressed: () {
                            final newPos =
                                currentPos + const Duration(seconds: 10);
                            audioService.seek(newPos);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Speed:'),
                const SizedBox(width: 8),
                _SpeedChip(rate: 0.75, audioService: audioService),
                const SizedBox(width: 8),
                _SpeedChip(rate: 1.0, audioService: audioService),
                const SizedBox(width: 8),
                _SpeedChip(rate: 1.25, audioService: audioService),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _SpeedChip extends StatelessWidget {
  final double rate;
  final AudioService audioService;

  const _SpeedChip({required this.rate, required this.audioService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: Stream.periodic(
          const Duration(milliseconds: 100), (_) => audioService.currentSpeed),
      initialData: audioService.currentSpeed,
      builder: (context, snapshot) {
        final current = snapshot.data ?? 1.0;
        return ChoiceChip(
          label: Text('${rate}x'),
          selected: current == rate,
          onSelected: (_) => audioService.setSpeed(rate),
        );
      },
    );
  }
}

class _RepeatStep extends StatelessWidget {
  const _RepeatStep();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PracticeController>();
    final recordingService = context.read<RecordingService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (controller.isRecording) ...[
              StreamBuilder<Duration>(
                stream: recordingService.recordingDurationStream,
                initialData: Duration.zero,
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  return Column(
                    children: [
                      const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Recording',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.stopRepeatRecording,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Recording'),
              ),
            ] else if (controller.recordingPath != null) ...[
              if (controller.isPlayingRecording) ...[
                StreamBuilder<Duration>(
                  stream: context.read<AudioService>().positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    return Column(
                      children: [
                        const Icon(Icons.volume_up, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          '${pos.inMinutes.toString().padLeft(2, '0')}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.stopPlayback,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Playback'),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.playRecording,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.startRepeatRecording,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Re-record'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.validateRepeatRecording,
                        icon: const Icon(Icons.analytics),
                        label: const Text('Validate'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: controller.deleteRecording,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
              if (controller.validationResult != null) ...[
                const SizedBox(height: 16),
                _ValidationResultCard(result: controller.validationResult!),
              ],
            ] else ...[
              const Text('Repeat the phrase yourself'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.startRepeatRecording,
                icon: const Icon(Icons.mic),
                label: const Text('Start Recording'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShadowStep extends StatelessWidget {
  final Phrase phrase;

  const _ShadowStep({required this.phrase});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PracticeController>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (controller.isShadowing) ...[
              const Icon(Icons.headphones, size: 48),
              const SizedBox(height: 8),
              const Text('Listening and speaking at the same time...'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.stopShadowing,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Shadowing'),
              ),
            ] else if (controller.shadowRecordingPath != null) ...[
              if (controller.isPlayingRecording) ...[
                StreamBuilder<Duration>(
                  stream: context.read<AudioService>().positionStream,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    return Column(
                      children: [
                        const Icon(Icons.volume_up, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          '${pos.inMinutes.toString().padLeft(2, '0')}:${(pos.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.stopPlayback,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Playback'),
                ),
              ] else ...[
                const Text('Shadow recording saved.'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.playShadowRecording,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Shadow'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.startShadowing,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Record Again'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: controller.deleteShadowRecording,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Recording'),
                ),
              ],
            ] else ...[
              const Text(
                  'Use headphones for the best shadowing experience.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.startShadowing,
                icon: const Icon(Icons.headphones),
                label: const Text('Start Shadowing'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ValidationResultCard extends StatelessWidget {
  final ValidationResult result;

  const _ValidationResultCard({required this.result});

  Color _scoreColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 55) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  String _fmt(Duration d) {
    final ms = d.inMilliseconds;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(result.score);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: result.score / 100,
                        strokeWidth: 6,
                        backgroundColor: color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      Center(
                        child: Text(
                          '${result.score}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.scoreLabel,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.feedback,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Ref: ${_fmt(result.nativeDuration)}',
                    style: Theme.of(context).textTheme.labelSmall),
                Text('You: ${_fmt(result.userDuration)}',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteStep extends StatelessWidget {
  final Lesson lesson;
  final Phrase phrase;

  const _CompleteStep({required this.lesson, required this.phrase});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PracticeController>();
    final lessonRepo = context.read<LessonRepository>();
    final phrases = lessonRepo.getPhrasesForLesson(lesson.id);
    final currentIndex = phrases.indexWhere((p) => p.id == phrase.id);
    final hasNext = currentIndex >= 0 && currentIndex < phrases.length - 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await controller.completePhrase();
                if (hasNext && context.mounted) {
                  final nextPhrase = phrases[currentIndex + 1];
                  await controller.loadPhrase(lesson, nextPhrase);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lesson complete! Great work.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle),
              label: Text(hasNext ? 'Complete & Next' : 'Complete Phrase'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (hasNext) ...[
              const SizedBox(height: 12),
              Text(
                'Next: "${phrases[currentIndex + 1].text}"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
