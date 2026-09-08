/// عنصر اختبار واحد ("سبر كتابي" أو "تسميع") — مطابق لأعمدة رد
/// get_exams.php بالضبط.
///
/// حالتين:
/// - [isReleased] == false: تم تحديد موعد الاختبار بس المشرف لسا ما دخّل
///   العلامة (student_marks.marks لسا null) — بيظهر "لم تصدر نتيجته بعد".
/// - [isReleased] == true: المشرف صدّر العلامة، فـ [marks] موجودة.
class ExamItem {
  final int id;
  final int subjectId;
  final String subjectName;
  final String title;
  final String? description;
  final String type; // 'quiz' = سبر كتابي، 'recitation' = تسميع
  final DateTime? examDate;
  final double? totalMarks;
  final double? marks;
  final String? notes;
  final DateTime createdAt;

  const ExamItem({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.title,
    this.description,
    required this.type,
    this.examDate,
    this.totalMarks,
    this.marks,
    this.notes,
    required this.createdAt,
  });

  bool get isReleased => marks != null;
  bool get isRecitation => type == 'recitation';

  /// تسمية النوع للعرض بواجهة الطالب.
  String get typeLabel => isRecitation ? 'تسميع' : 'سبر كتابي';

  factory ExamItem.fromJson(Map<String, dynamic> json) {
    String? _cleanOrNull(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    double? _numOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return ExamItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      subjectId: json['subject_id'] is int ? json['subject_id'] as int : int.tryParse('${json['subject_id']}') ?? 0,
      subjectName: json['subject_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: _cleanOrNull(json['description']),
      type: json['type']?.toString() ?? 'quiz',
      examDate: _cleanOrNull(json['exam_date']) != null ? DateTime.tryParse(json['exam_date'].toString()) : null,
      totalMarks: _numOrNull(json['total_marks']),
      marks: _numOrNull(json['marks']),
      notes: _cleanOrNull(json['notes']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
