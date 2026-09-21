import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';
import 'package:listen_repeat/core/constants/app_constants.dart';
import 'package:listen_repeat/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;
  bool _isRecording = false;
  DateTime? _recordStartTime;
  Timer? _durationTimer;
  Duration _currentDuration = Duration.zero;

  bool get isRecording => _isRecording;
  String? get currentPath => _currentPath;
  Duration get recordingDuration => _currentDuration;
  Stream<Duration> get recordingDurationStream => Stream.periodic(
    const Duration(milliseconds: 500),
    (_) => _currentDuration,
  );

  Future<String?> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        AppLogger.w('Microphone permission not granted for recording');
        return null;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = p.join(
        tempDir.path,
        '${AppConstants.recordingsDirectory}_$timestamp.m4a',
      );

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

      _currentPath = path;
      _isRecording = true;
      _recordStartTime = DateTime.now();
      _currentDuration = Duration.zero;
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (_recordStartTime != null) {
          _currentDuration = DateTime.now().difference(_recordStartTime!);
        }
      });
      AppLogger.recording('Started recording: $path');
      return path;
    } catch (e) {
      AppLogger.e('Failed to start recording', e);
      return null;
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    try {
      AppLogger.recording('Stopping recording');
      final path = await _recorder.stop();
      _currentPath = path;
      _isRecording = false;
      _durationTimer?.cancel();
      _durationTimer = null;
      _recordStartTime = null;
      AppLogger.recording('Stopped recording: $path');
    } catch (e) {
      AppLogger.e('Failed to stop recording', e);
      _isRecording = false;
      _durationTimer?.cancel();
      _durationTimer = null;
      _recordStartTime = null;
    }
  }

  Future<void> deleteRecording() async {
    try {
      if (_currentPath != null) {
        final file = File(_currentPath!);
        if (await file.exists()) {
          await file.delete();
          AppLogger.recording('Deleted recording: $_currentPath');
        }
      }
      _currentPath = null;
      _currentDuration = Duration.zero;
    } catch (e) {
      AppLogger.e('Failed to delete recording', e);
    }
  }

  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }
      await _recorder.dispose();
      AppLogger.recording('Recording service disposed');
    } catch (_) {}
  }
}
