class Task {
  int id;
  String title;
  bool isCompleted;
  DateTime? date;

  Task({int? id, required this.title, this.isCompleted = false, this.date})
    : id = id ?? (DateTime.now().millisecondsSinceEpoch % 2147483647);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'date': date?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] ?? false,
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
    );
  }
}
