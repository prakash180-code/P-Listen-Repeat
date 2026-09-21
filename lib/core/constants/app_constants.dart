class AppConstants {
  static const String appName = 'P-Listen & Repeat';
  static const String defaultLocale = 'en_US';
  static const String lessonsAssetPath = 'assets/data/lessons.json';
  static const String recordingsDirectory = 'recordings';
  static const String audioAssetBase = 'assets/audio';
}

enum PracticeType { listen, repeat, shadow }

enum StepStatus { notStarted, inProgress, completed }
