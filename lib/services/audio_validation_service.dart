class ValidationResult {
  final int score;
  final Duration nativeDuration;
  final Duration userDuration;
  final String feedback;

  const ValidationResult({
    required this.score,
    required this.nativeDuration,
    required this.userDuration,
    required this.feedback,
  });

  String get scoreLabel {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 55) return 'Fair';
    if (score >= 40) return 'Needs Work';
    return 'Keep Trying';
  }
}

class AudioValidationService {
  ValidationResult validate({
    required Duration nativeDuration,
    required Duration recordingDuration,
  }) {
    if (nativeDuration.inMilliseconds == 0 ||
        recordingDuration.inMilliseconds == 0) {
      return const ValidationResult(
        score: 0,
        nativeDuration: Duration.zero,
        userDuration: Duration.zero,
        feedback: 'Could not analyze audio. Try recording again.',
      );
    }

    final score = _calculateScore(nativeDuration, recordingDuration);
    final feedback = _getFeedback(score, nativeDuration, recordingDuration);

    return ValidationResult(
      score: score,
      nativeDuration: nativeDuration,
      userDuration: recordingDuration,
      feedback: feedback,
    );
  }

  int _calculateScore(Duration native, Duration user) {
    if (native.inMilliseconds == 0) return 0;

    final ratio = user.inMilliseconds / native.inMilliseconds;

    if (ratio >= 0.85 && ratio <= 1.15) return 100;
    if (ratio >= 0.70 && ratio <= 1.30) return 85;
    if (ratio >= 0.55 && ratio <= 1.45) return 70;
    if (ratio >= 0.40 && ratio <= 1.60) return 55;
    if (ratio >= 0.25 && ratio <= 1.80) return 40;
    if (ratio >= 0.15 && ratio <= 2.00) return 25;
    return 10;
  }

  String _getFeedback(int score, Duration native, Duration user) {
    final nativeSec = native.inMilliseconds / 1000.0;
    final userSec = user.inMilliseconds / 1000.0;
    final diff = userSec - nativeSec;

    if (score >= 85) {
      return 'Excellent pacing! Your timing matches the reference.';
    } else if (score >= 70) {
      return diff > 0
          ? 'Good! A bit slow \u2014 try speaking slightly faster.'
          : 'Good! A bit fast \u2014 try slowing down a touch.';
    } else if (score >= 55) {
      return diff > 0
          ? 'Speaking slowly. Reference: ${nativeSec.toStringAsFixed(1)}s, yours: ${userSec.toStringAsFixed(1)}s.'
          : 'Speaking quickly. Reference: ${nativeSec.toStringAsFixed(1)}s, yours: ${userSec.toStringAsFixed(1)}s.';
    } else if (score >= 40) {
      return diff > 0
          ? 'Too slow. Listen to the reference again and match its pace.'
          : 'Too fast. Listen to the reference again and speak more slowly.';
    } else {
      return 'Keep practicing! Listen to the reference several times, then try again.';
    }
  }
}
