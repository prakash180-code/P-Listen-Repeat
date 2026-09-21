class Progress {
  final String phraseId;
  bool listened;
  bool repeated;
  bool shadowed;
  bool completed;
  int attempts;
  DateTime? lastPracticed;

  Progress({
    required this.phraseId,
    this.listened = false,
    this.repeated = false,
    this.shadowed = false,
    this.completed = false,
    this.attempts = 0,
    this.lastPracticed,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      phraseId: json['phraseId'] as String,
      listened: json['listened'] as bool? ?? false,
      repeated: json['repeated'] as bool? ?? false,
      shadowed: json['shadowed'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      attempts: json['attempts'] as int? ?? 0,
      lastPracticed: json['lastPracticed'] != null
          ? DateTime.parse(json['lastPracticed'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'phraseId': phraseId,
    'listened': listened,
    'repeated': repeated,
    'shadowed': shadowed,
    'completed': completed,
    'attempts': attempts,
    'lastPracticed': lastPracticed?.toIso8601String(),
  };

  Progress copyWith({
    String? phraseId,
    bool? listened,
    bool? repeated,
    bool? shadowed,
    bool? completed,
    int? attempts,
    DateTime? lastPracticed,
  }) {
    return Progress(
      phraseId: phraseId ?? this.phraseId,
      listened: listened ?? this.listened,
      repeated: repeated ?? this.repeated,
      shadowed: shadowed ?? this.shadowed,
      completed: completed ?? this.completed,
      attempts: attempts ?? this.attempts,
      lastPracticed: lastPracticed ?? this.lastPracticed,
    );
  }
}
