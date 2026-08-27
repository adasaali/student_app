/// عنصر واجب واحد — مطابق لأعمدة رد get_homework.php بالضبط.
class HomeworkItem {
  final int id;
  final String subjectName;
  final String lessonName;
  final bool hasAssignment;
  final String? assignmentDescription;
  final String? notes;
  final DateTime? dueDate;
  final DateTime createdAt;

  const HomeworkItem({
    required this.id,
    required this.subjectName,
    required this.lessonName,
    required this.hasAssignment,
    this.assignmentDescription,
    this.notes,
    this.dueDate,
    required this.createdAt,
  });

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    String? _cleanOrNull(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return HomeworkItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      subjectName: json['subject_name']?.toString() ?? '',
      lessonName: json['lesson_name']?.toString() ?? '',
      hasAssignment: json['has_assignment'] == true || json['has_assignment'] == 1 || json['has_assignment'] == '1',
      assignmentDescription: _cleanOrNull(json['assignment_description']),
      notes: _cleanOrNull(json['notes']),
      dueDate: _cleanOrNull(json['due_date']) != null ? DateTime.tryParse(json['due_date'].toString()) : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// كم يوم متبقي على تسليم الواجب (null لو ما في موعد تسليم محدد).
  /// سالب = فات موعده.
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return dueOnly.difference(todayOnly).inDays;
  }
}
