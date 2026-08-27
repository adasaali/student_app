/// ملاحظة سلوك (إيجابية / سلبية) بتوصل من تطبيق المشرف — خاصية
/// "الملاحظات" (api/get_student_notes.php ← api_supervisor/supervisor_notes.php).
/// منفصلة عن ملاحظة ولي الأمر (parent_note) الموجودة بتقرير الدرجات.
class BehaviorNote {
  final int id;
  final String noteType; // positive | negative
  final String noteText;
  final String? subjectName;
  final String? createdByName;
  final DateTime createdAt;

  BehaviorNote({
    required this.id,
    required this.noteType,
    required this.noteText,
    this.subjectName,
    this.createdByName,
    required this.createdAt,
  });

  bool get isPositive => noteType == 'positive';

  factory BehaviorNote.fromJson(Map<String, dynamic> json) {
    return BehaviorNote(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] as int? ?? 0),
      noteType: json['note_type']?.toString() ?? 'positive',
      noteText: json['note_text']?.toString() ?? '',
      subjectName: (json['subject_name'] == null || json['subject_name'].toString().isEmpty) ? null : json['subject_name'].toString(),
      createdByName: (json['created_by_name'] == null || json['created_by_name'].toString().isEmpty) ? null : json['created_by_name'].toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class BehaviorNoteStats {
  final int totalNotes;
  final int positiveCount;
  final int negativeCount;

  BehaviorNoteStats({required this.totalNotes, required this.positiveCount, required this.negativeCount});

  factory BehaviorNoteStats.fromJson(Map<String, dynamic> json) {
    return BehaviorNoteStats(
      totalNotes: json['total_notes'] ?? 0,
      positiveCount: json['positive_count'] ?? 0,
      negativeCount: json['negative_count'] ?? 0,
    );
  }

  factory BehaviorNoteStats.empty() => BehaviorNoteStats(totalNotes: 0, positiveCount: 0, negativeCount: 0);
}
