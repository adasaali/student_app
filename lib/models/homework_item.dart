/// 🆕 مرفق واحد تابع لواجب/مقرر.
class HomeworkAttachment {
  final String fileName;
  final String fileUrl;
  final String? mimeType;
  final int? fileSize;

  const HomeworkAttachment({required this.fileName, required this.fileUrl, this.mimeType, this.fileSize});

  static HomeworkAttachment? fromJson(dynamic j) {
    if (j == null || j is! Map) return null;
    final url = j['file_url']?.toString();
    if (url == null || url.isEmpty) return null;
    return HomeworkAttachment(
      fileName: j['file_name']?.toString() ?? 'ملف',
      fileUrl: url,
      mimeType: j['mime_type']?.toString(),
      fileSize: j['file_size'] is int ? j['file_size'] as int : int.tryParse('${j['file_size']}'),
    );
  }
}

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
  final List<HomeworkAttachment> attachments; // 🆕

  const HomeworkItem({
    required this.id,
    required this.subjectName,
    required this.lessonName,
    required this.hasAssignment,
    this.assignmentDescription,
    this.notes,
    this.dueDate,
    required this.createdAt,
    this.attachments = const [],
  });

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    String? _cleanOrNull(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final rawAttachments = json['attachments'];
    final attachments = <HomeworkAttachment>[];
    if (rawAttachments is List) {
      for (final a in rawAttachments) {
        final att = HomeworkAttachment.fromJson(a);
        if (att != null) attachments.add(att);
      }
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
      attachments: attachments,
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
