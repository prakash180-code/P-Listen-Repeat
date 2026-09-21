class Lesson {
  final String id;
  final String title;
  final String description;
  final String level;
  final int order;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.order,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      level: json['level'] as String,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'level': level,
    'order': order,
  };
}
