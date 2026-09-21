import 'package:flutter/material.dart';
import 'package:listen_repeat/app.dart';
import 'package:listen_repeat/core/utils/logger.dart';
import 'package:listen_repeat/data/local/audio_asset_manager.dart';
import 'package:listen_repeat/data/local/storage_service.dart';
import 'package:listen_repeat/data/repositories/lesson_repository.dart';
import 'package:listen_repeat/data/repositories/progress_repository.dart';
import 'package:listen_repeat/features/practice/practice_controller.dart';
import 'package:listen_repeat/services/audio_service.dart';
import 'package:listen_repeat/services/audio_validation_service.dart';
import 'package:listen_repeat/services/permission_service.dart';
import 'package:listen_repeat/services/recording_service.dart';
import 'package:listen_repeat/services/shadowing_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    AppLogger.i('App starting');

    final storageService = StorageService();
    await storageService.init();

    final progressRepository = ProgressRepository(storageService);
    final lessonRepository = LessonRepository(
      storage: storageService,
      audioAssetManager: AudioAssetManager(),
      progressRepository: progressRepository,
    );
    await lessonRepository.loadLessons();

    final audioService = AudioService();
    final recordingService = RecordingService();
    final permissionService = PermissionService();

    runApp(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storageService),
          Provider<ProgressRepository>.value(value: progressRepository),
          Provider<LessonRepository>.value(value: lessonRepository),
          Provider<AudioService>.value(value: audioService),
          Provider<RecordingService>.value(value: recordingService),
          Provider<PermissionService>.value(value: permissionService),
          Provider<AudioValidationService>(
            create: (_) => AudioValidationService(),
          ),
          ProxyProvider2<AudioService, RecordingService, ShadowingService>(
            update: (context, audio, recording, _) => ShadowingService(
              audioService: audio,
              recordingService: recording,
            ),
          ),
          ChangeNotifierProvider(
            create: (context) {
              final audio = context.read<AudioService>();
              final recording = context.read<RecordingService>();
              final shadowing = context.read<ShadowingService>();
              final progress = context.read<ProgressRepository>();
              final permission = context.read<PermissionService>();
              final validation = context.read<AudioValidationService>();
              return PracticeController(
                audioService: audio,
                recordingService: recording,
                shadowingService: shadowing,
                progressRepository: progress,
                permissionService: permission,
                validationService: validation,
              );
            },
          ),
        ],
        child: const App(),
      ),
    );

    AppLogger.i('App initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize app: $e');
    debugPrintStack(stackTrace: stackTrace);
    AppLogger.e('App initialization failed', e, stackTrace);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to start app:\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
