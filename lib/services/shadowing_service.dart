import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:listen_repeat/core/utils/logger.dart';
import 'package:listen_repeat/services/audio_service.dart';
import 'package:listen_repeat/services/recording_service.dart';

class ShadowingService {
  final AudioService audioService;
  final RecordingService recordingService;
  bool _isShadowing = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Completer<void>? _shadowingCompleter;
  String? _lastRecordingPath;

  ShadowingService({
    required this.audioService,
    required this.recordingService,
  });

  bool get isShadowing => _isShadowing;
  String? get lastRecordingPath => _lastRecordingPath;

  Future<void> startShadowing(String audioPath) async {
    if (_isShadowing) return;
    _isShadowing = true;
    _lastRecordingPath = null;
    _shadowingCompleter = Completer<void>();
    AppLogger.shadowing('Starting shadowing session');

    try {
      await audioService.load(audioPath);

      final recordingPath = await recordingService.startRecording();
      if (recordingPath == null) {
        throw Exception('Could not start recording for shadowing');
      }
      _lastRecordingPath = recordingPath;

      await audioService.play();

      _playerStateSubscription?.cancel();
      _playerStateSubscription = audioService.playerStateStream.listen((state) {
        if (!_isShadowing) return;
        if (state.processingState == ProcessingState.completed) {
          AppLogger.shadowing('Native audio completed');
          _finishShadowing();
        }
      });
    } catch (e) {
      AppLogger.e('Shadowing start failed', e);
      await stopShadowing();
      rethrow;
    }

    if (_shadowingCompleter != null) {
      await _shadowingCompleter!.future;
    }
  }

  Future<void> _finishShadowing() async {
    if (!_isShadowing) return;
    AppLogger.shadowing('Finishing shadowing session');
    try {
      await recordingService.stopRecording();
      await audioService.stop();
    } catch (e) {
      AppLogger.e('Error finishing shadowing', e);
    }
    _isShadowing = false;
    await _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    if (_shadowingCompleter != null && !_shadowingCompleter!.isCompleted) {
      _shadowingCompleter!.complete();
    }
  }

  Future<void> stopShadowing() async {
    if (!_isShadowing) return;
    AppLogger.shadowing('Stopping shadowing session');
    try {
      await recordingService.stopRecording();
      await audioService.stop();
    } catch (e) {
      AppLogger.e('Error stopping shadowing', e);
    }
    _isShadowing = false;
    await _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    if (_shadowingCompleter != null && !_shadowingCompleter!.isCompleted) {
      _shadowingCompleter!.complete();
    }
  }

  Future<void> dispose() async {
    await stopShadowing();
    AppLogger.shadowing('Shadowing service disposed');
  }
}
