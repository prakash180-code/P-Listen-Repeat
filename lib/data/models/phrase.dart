class Phrase {
  final String id;
  final String lessonId;
  final String text;
  final String audioPath;
  final String? pronunciationText;
  final int order;
  final String difficulty;

  const Phrase({
    required this.id,
    required this.lessonId,
    required this.text,
    required this.audioPath,
    this.pronunciationText,
    required this.order,
    this.difficulty = 'medium',
  });

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      text: json['text'] as String,
      audioPath: json['audioPath'] as String,
      pronunciationText: json['pronunciationText'] as String?,
      order: json['order'] as int,
      difficulty: json['difficulty'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lessonId': lessonId,
    'text': text,
    'audioPath': audioPath,
    'pronunciationText': pronunciationText,
    'order': order,
    'difficulty': difficulty,
  };
}
