import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:listen_repeat/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isDisposed = false;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  double get currentSpeed => _currentSpeed;
  Duration? get duration => _player.duration;

  double _currentSpeed = 1.0;

  Future<void> load(String path) async {
    try {
      AppLogger.audio('Loading audio: $path');
      if (path.startsWith('assets/')) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${path.replaceAll('/', '_')}');
        if (!await file.exists()) {
          final ByteData data = await rootBundle.load(path);
          await file.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
        }
        AppLogger.audio('Asset copied to temp: ${file.path}');
        await _player.setFilePath(file.path);
      } else {
        await _player.setFilePath(path);
      }
      AppLogger.audio('Audio loaded successfully');
    } catch (e) {
      AppLogger.e('Failed to load audio: $path', e);
      rethrow;
    }
  }

  Future<void> play() async {
    if (_isDisposed) return;
    try {
      AppLogger.audio('Play');
      await _player.play();
    } catch (e) {
      AppLogger.e('Play failed', e);
    }
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    try {
      AppLogger.audio('Pause');
      await _player.pause();
    } catch (e) {
      AppLogger.e('Pause failed', e);
    }
  }

  Future<void> stop() async {
    if (_isDisposed) return;
    try {
      AppLogger.audio('Stop');
      await _player.stop();
    } catch (e) {
      AppLogger.e('Stop failed', e);
    }
  }

  Future<void> seek(Duration position) async {
    if (_isDisposed) return;
    try {
      await _player.seek(position);
    } catch (e) {
      AppLogger.e('Seek failed', e);
    }
  }

  Future<void> setSpeed(double rate) async {
    if (_isDisposed) return;
    try {
      await _player.setSpeed(rate);
      _currentSpeed = rate;
      AppLogger.audio('Playback speed set to $rate');
    } catch (e) {
      AppLogger.e('Set playback rate failed', e);
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    AppLogger.audio('Dispose');
    await _player.dispose();
  }

  static Future<Duration?> getDuration(String path) async {
    final player = AudioPlayer();
    try {
      if (path.startsWith('assets/')) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${path.replaceAll('/', '_')}');
        if (!await file.exists()) {
          final ByteData data = await rootBundle.load(path);
          await file.writeAsBytes(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
        }
        await player.setFilePath(file.path);
      } else {
        await player.setFilePath(path);
      }
      return player.duration;
    } catch (e) {
      return null;
    } finally {
      await player.dispose();
    }
  }
}
