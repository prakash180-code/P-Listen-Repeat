import 'dart:developer';

class AppLogger {
  static void i(String message) => log('[INFO] $message');
  static void w(String message) => log('[WARN] $message');
  static void e(String message, [Object? error, StackTrace? stackTrace]) =>
      log('[ERROR] $message', error: error, stackTrace: stackTrace);
  static void audio(String message) => log('[AUDIO] $message');
  static void recording(String message) => log('[RECORDING] $message');
  static void shadowing(String message) => log('[SHADOWING] $message');
  static void progress(String message) => log('[PROGRESS] $message');
}
