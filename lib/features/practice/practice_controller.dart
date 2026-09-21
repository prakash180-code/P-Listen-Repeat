import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:listen_repeat/core/utils/logger.dart';
import 'package:listen_repeat/data/models/lesson.dart';
import 'package:listen_repeat/data/models/phrase.dart';
import 'package:listen_repeat/data/repositories/progress_repository.dart';
import 'package:listen_repeat/services/audio_service.dart';
import 'package:listen_repeat/services/audio_validation_service.dart';
import 'package:listen_repeat/services/permission_service.dart';
import 'package:listen_repeat/services/recording_service.dart';
import 'package:listen_repeat/services/shadowing_service.dart';

class PracticeController extends ChangeNotifier {
  final AudioService audioService;
  final RecordingService recordingService;
  final ShadowingService shadowingService;
  final ProgressRepository progressRepository;
  final PermissionService permissionService;
  final AudioValidationService validationService;

  Lesson? _currentLesson;
  Phrase? _currentPhrase;
  String? _recordingPath;
  bool _isRecording = false;
  bool _isShadowing = false;
  bool _isLoading = false;
  String? _errorMessage;
  Duration _nativeDuration = Duration.zero;

  PracticeController({
    required this.audioService,
    required this.recordingService,
    required this.shadowingService,
    required this.progressRepository,
    required this.permissionService,
    required this.validationService,
  });

  Lesson? get currentLesson => _currentLesson;
  Phrase? get currentPhrase => _currentPhrase;
  String? get recordingPath => _recordingPath;
  bool get isRecording => _isRecording;
  bool get isShadowing => _isShadowing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? _shadowRecordingPath;
  ValidationResult? _validationResult;

  String? get shadowRecordingPath => _shadowRecordingPath;
  ValidationResult? get validationResult => _validationResult;

  Future<void> loadPhrase(Lesson lesson, Phrase phrase) async {
    _setLoading(true);
    clearError();

    try {
      _currentLesson = lesson;
      _currentPhrase = phrase;
      _recordingPath = null;
      _isRecording = false;
      _isShadowing = false;
      _shadowRecordingPath = null;
      _validationResult = null;

      await audioService.load(phrase.audioPath);
      _nativeDuration = audioService.duration ?? Duration.zero;
      AppLogger.i('Loaded phrase: ${phrase.text}');
    } catch (e) {
      _errorMessage = 'Failed to load phrase audio. Please try again.';
      AppLogger.e('Load phrase failed', e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startRepeatRecording() async {
    final granted = await permissionService.requestMicrophonePermission();
    if (!granted) {
      _errorMessage =
          'Microphone access is needed to record your speaking practice.';
      notifyListeners();
      return;
    }

    clearError();
    try {
      final path = await recordingService.startRecording();
      if (path != null) {
      _recordingPath = path;
      _isRecording = true;
      _validationResult = null;
      AppLogger.recording('Repeat recording started');
      } else {
        _errorMessage = 'Could not start recording. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'Recording failed. Please try again.';
      AppLogger.e('Repeat recording failed', e);
    }
    notifyListeners();
  }

  Future<void> stopRepeatRecording() async {
    try {
      await recordingService.stopRecording();
      _isRecording = false;
      _recordingPath = recordingService.currentPath;
      AppLogger.recording('Repeat recording stopped');
    } catch (e) {
      _errorMessage = 'Could not stop recording.';
      AppLogger.e('Stop recording failed', e);
    }
    notifyListeners();
  }

  Future<void> deleteRecording() async {
    try {
      await recordingService.deleteRecording();
      _recordingPath = null;
      AppLogger.recording('Recording deleted');
    } catch (e) {
      _errorMessage = 'Could not delete recording.';
      AppLogger.e('Delete recording failed', e);
    }
    notifyListeners();
  }

  bool _isPlayingRecording = false;
  bool get isPlayingRecording => _isPlayingRecording;

  Future<void> playRecording() async {
    if (_recordingPath == null) return;
    try {
      await audioService.load(_recordingPath!);
      _isPlayingRecording = true;
      notifyListeners();
      await audioService.play();
    } catch (e) {
      _errorMessage = 'Could not play recording.';
      AppLogger.e('Play recording failed', e);
    }
    _isPlayingRecording = false;
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    try {
      await audioService.stop();
    } catch (_) {}
    _isPlayingRecording = false;
    notifyListeners();
  }

  Future<void> startShadowing() async {
    if (_currentPhrase == null) return;

    final granted = await permissionService.requestMicrophonePermission();
    if (!granted) {
      _errorMessage =
          'Microphone access is needed for shadowing. Use headphones for best results.';
      notifyListeners();
      return;
    }

    clearError();
    _shadowRecordingPath = null;
    _validationResult = null;
    _isShadowing = true;
    notifyListeners();

    try {
      await shadowingService.startShadowing(_currentPhrase!.audioPath);
      _shadowRecordingPath = shadowingService.lastRecordingPath;
      if (_currentPhrase != null) {
        await progressRepository.markShadowed(_currentPhrase!.id);
      }
      AppLogger.shadowing(
          'Shadowing completed. Recording: $_shadowRecordingPath');
    } catch (e) {
      _errorMessage = 'Shadowing failed. Please try again.';
      AppLogger.e('Shadowing failed', e);
    } finally {
      _isShadowing = false;
      notifyListeners();
    }
  }

  Future<void> stopShadowing() async {
    await shadowingService.stopShadowing();
    _shadowRecordingPath = shadowingService.lastRecordingPath;
    _isShadowing = false;
    notifyListeners();
  }

  Future<void> playShadowRecording() async {
    if (_shadowRecordingPath == null) return;
    try {
      await audioService.load(_shadowRecordingPath!);
      _isPlayingRecording = true;
      notifyListeners();
      await audioService.play();
    } catch (e) {
      _errorMessage = 'Could not play shadow recording.';
      AppLogger.e('Play shadow recording failed', e);
    }
    _isPlayingRecording = false;
    notifyListeners();
  }

  Future<void> deleteShadowRecording() async {
    if (_shadowRecordingPath != null) {
      try {
        final file = File(_shadowRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _shadowRecordingPath = null;
    _validationResult = null;
    notifyListeners();
  }

  Future<void> validateRepeatRecording() async {
    if (_recordingPath == null || _currentPhrase == null) return;

    try {
      final recordingDuration =
          await AudioService.getDuration(_recordingPath!) ?? Duration.zero;

      _validationResult = validationService.validate(
        nativeDuration: _nativeDuration,
        recordingDuration: recordingDuration,
      );

      AppLogger.i(
          'Validation: native=${_nativeDuration.inMilliseconds}ms, recording=${recordingDuration.inMilliseconds}ms, score=${_validationResult!.score}');
    } catch (e) {
      _errorMessage = 'Could not analyze recording. Please try again.';
      AppLogger.e('Validation failed', e);
    }
    notifyListeners();
  }

  Future<void> completePhrase() async {
    if (_currentPhrase == null || _currentLesson == null) return;
    try {
      await progressRepository.markCompleted(_currentPhrase!.id);
      await progressRepository.saveLastActive(
        _currentLesson!.id,
        _currentPhrase!.id,
      );
      AppLogger.progress('Phrase completed: ${_currentPhrase!.text}');
    } catch (e) {
      _errorMessage = 'Could not save progress.';
      AppLogger.e('Complete phrase failed', e);
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    AppLogger.i('PracticeController disposed');
    super.dispose();
  }
}
