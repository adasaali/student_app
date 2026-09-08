/// سطر واحد بجدول الامتحانات: تاريخ الامتحان - المادة - المقررات
/// الداخلة بالامتحان. مطابق لأعمدة رد get_exam_schedule.php بالضبط.
class ExamScheduleRow {
  final DateTime? examDate;
  final String subjectName;
  final String? curriculumText;

  const ExamScheduleRow({
    this.examDate,
    required this.subjectName,
    this.curriculumText,
  });

  factory ExamScheduleRow.fromJson(Map<String, dynamic> json) {
    String? cleanOrNull(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final dateStr = cleanOrNull(json['exam_date']);

    return ExamScheduleRow(
      examDate: dateStr != null ? DateTime.tryParse(dateStr) : null,
      subjectName: json['subject_name']?.toString() ?? '',
      curriculumText: cleanOrNull(json['curriculum_text']),
    );
  }
}

/// برنامج امتحاني واحد ("امتحانات نصف الفصل الأول" مثلاً) — فيه اسمه،
/// صفوف الجدول، والتعليمات الامتحانية اللي بتظهر بعد الجدول. يديره
/// الأدمن من admin/exam_schedule/exam_schedule.php.
class ExamSchedule {
  final int id;
  final String scheduleName;
  final String? instructions;
  final List<ExamScheduleRow> items;

  const ExamSchedule({
    required this.id,
    required this.scheduleName,
    this.instructions,
    required this.items,
  });

  factory ExamSchedule.fromJson(Map<String, dynamic> json) {
    String? cleanOrNull(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return ExamSchedule(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      scheduleName: json['schedule_name']?.toString() ?? '',
      instructions: cleanOrNull(json['instructions']),
      items: (json['items'] as List? ?? [])
          .map((e) => ExamScheduleRow.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
