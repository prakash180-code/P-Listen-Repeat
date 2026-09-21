import 'dart:io';

import 'package:flutter/services.dart';
import 'package:listen_repeat/core/constants/app_constants.dart';
import 'package:listen_repeat/core/utils/logger.dart';
import 'package:path/path.dart' as p;

class AudioAssetManager {
  static const _channel = MethodChannel('listen_repeat/audio_assets');

  Future<String?> getAssetAudioPath(String relativePath) async {
    try {
      final base = await _getAssetBasePath();
      final fullPath = p.join(base, relativePath);
      if (await File(fullPath).exists()) {
        return fullPath;
      }
      AppLogger.w('Audio asset not found: $fullPath');
      return null;
    } catch (e) {
      AppLogger.e('Failed to resolve audio path', e);
      rethrow;
    }
  }

  Future<String> _getAssetBasePath() async {
    try {
      final result = await _channel.invokeMethod<String>('getAssetBasePath');
      if (result != null) return result;
    } catch (_) {}
    return AppConstants.audioAssetBase;
  }
}
