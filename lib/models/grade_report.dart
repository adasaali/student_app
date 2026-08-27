/// موديلات تقرير الدرجات — تقابل تماماً الـ JSON الراجع من get_grade_report.php

class AcademicYearOption {
  final int rowId;
  final int academicYearId;
  final String yearName;

  AcademicYearOption({required this.rowId, required this.academicYearId, required this.yearName});

  factory AcademicYearOption.fromJson(Map<String, dynamic> json) => AcademicYearOption(
    rowId: json['row_id'] ?? 0,
    academicYearId: json['academic_year_id'] ?? 0,
    yearName: json['year_name'] ?? '',
  );
}

class Trend {
  final String cssClass; // up / down / flat
  final String icon; // ▲ ▼ —
  final String text; // تحسن / تراجع / ثبات

  Trend({required this.cssClass, required this.icon, required this.text});

  factory Trend.fromJson(Map<String, dynamic> json) => Trend(
    cssClass: json['class'] ?? 'flat',
    icon: json['icon'] ?? '—',
    text: json['text'] ?? 'ثبات',
  );
}

class Award {
  final String text;
  final String colorHex;

  Award({required this.text, required this.colorHex});

  factory Award.fromJson(Map<String, dynamic> json) => Award(
    text: json['text'] ?? '',
    colorHex: json['color'] ?? '#64748b',
  );
}

/// شهر واحد ضمن فصل دراسي (شفهي / وظائف / مذاكرة / امتحان)
class MonthScore {
  final String label;
  final num? oral;
  final num? assign;
  final num? study;
  final num? exam;
  final bool enabled;

  MonthScore({
    required this.label,
    this.oral,
    this.assign,
    this.study,
    this.exam,
    required this.enabled,
  });

  factory MonthScore.fromJson(Map<String, dynamic> json) => MonthScore(
    label: json['label'] ?? '',
    oral: json['oral'],
    assign: json['assign'],
    study: json['study'],
    exam: json['exam'],
    enabled: json['enabled'] ?? true,
  );
}

/// فصل دراسي كامل لمادة أساسية (بنظام الشهور: صفوف 1-6)
class SemesterDetail {
  final num final_;
  final List<MonthScore> months;

  SemesterDetail({required this.final_, required this.months});

  factory SemesterDetail.fromJson(Map<String, dynamic> json) => SemesterDetail(
    final_: json['final'] ?? 0,
    months: (json['months'] as List? ?? [])
        .map((e) => MonthScore.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// فصل دراسي لمادة بنظام الامتحانات (صفوف 7-12): مكوّنات بدون تفصيل شهري
class SemesterExamDetail {
  final num final_;
  final num? oral;
  final num? assign;
  final num? activity;
  final num? study;
  final num? exam;

  SemesterExamDetail({
    required this.final_,
    this.oral,
    this.assign,
    this.activity,
    this.study,
    this.exam,
  });

  factory SemesterExamDetail.fromJson(Map<String, dynamic> json) => SemesterExamDetail(
    final_: json['final'] ?? 0,
    oral: json['oral'],
    assign: json['assign'],
    activity: json['activity'],
    study: json['study'],
    exam: json['exam'],
  );
}

class BasicSubjectReport {
  final String name;
  final num fullScore;
  final String? calcOption;
  final bool isExamType;
  final SemesterDetail? sem1;
  final SemesterDetail? sem2;
  final SemesterExamDetail? sem1Exam;
  final SemesterExamDetail? sem2Exam;
  final num yearly;
  final Trend trend;
  final bool isPerfect;

  BasicSubjectReport({
    required this.name,
    required this.fullScore,
    this.calcOption,
    required this.isExamType,
    this.sem1,
    this.sem2,
    this.sem1Exam,
    this.sem2Exam,
    required this.yearly,
    required this.trend,
    required this.isPerfect,
  });

  factory BasicSubjectReport.fromJson(Map<String, dynamic> json) {
    final isExam = json['is_exam_type'] == true;
    return BasicSubjectReport(
      name: json['name'] ?? '',
      fullScore: json['full_score'] ?? 100,
      calcOption: json['calc_option'],
      isExamType: isExam,
      sem1: !isExam && json['sem1'] != null ? SemesterDetail.fromJson(json['sem1']) : null,
      sem2: !isExam && json['sem2'] != null ? SemesterDetail.fromJson(json['sem2']) : null,
      sem1Exam: isExam && json['sem1'] != null ? SemesterExamDetail.fromJson(json['sem1']) : null,
      sem2Exam: isExam && json['sem2'] != null ? SemesterExamDetail.fromJson(json['sem2']) : null,
      yearly: json['yearly'] ?? 0,
      trend: Trend.fromJson(json['trend'] ?? {}),
      isPerfect: json['is_perfect'] ?? false,
    );
  }
}

class EnrichmentSubjectReport {
  final String name;
  final num fullScore;
  final num sem1;
  final num sem2;
  final num yearly;
  final Trend trend;
  final bool isPerfect;

  EnrichmentSubjectReport({
    required this.name,
    required this.fullScore,
    required this.sem1,
    required this.sem2,
    required this.yearly,
    required this.trend,
    required this.isPerfect,
  });

  factory EnrichmentSubjectReport.fromJson(Map<String, dynamic> json) => EnrichmentSubjectReport(
    name: json['name'] ?? '',
    fullScore: json['full_score'] ?? 100,
    sem1: json['sem1'] ?? 0,
    sem2: json['sem2'] ?? 0,
    yearly: json['yearly'] ?? 0,
    trend: Trend.fromJson(json['trend'] ?? {}),
    isPerfect: json['is_perfect'] ?? false,
  );
}

class ParentNote {
  final int id;
  final String noteText;
  final String? adminReply;
  final DateTime createdAt;
  final DateTime? repliedAt;

  ParentNote({
    required this.id,
    required this.noteText,
    this.adminReply,
    required this.createdAt,
    this.repliedAt,
  });

  factory ParentNote.fromJson(Map<String, dynamic> json) => ParentNote(
    id: json['id'] ?? 0,
    noteText: json['note_text'] ?? '',
    adminReply: json['admin_reply'],
    createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    repliedAt: json['replied_at'] != null ? DateTime.tryParse(json['replied_at']) : null,
  );
}

class GradeReport {
  final String studentName;
  final String gradeName;
  final String sectionName;
  final String? academicYear;
  final bool useExamGrades;
  final num grandPct;
  final num grandTotal;
  final num grandMax;
  final int rank;
  final int totalStudents;
  final int subjectsCount;
  final bool passed;
  final String nextGrade;
  final Award award;
  final num basicSum;
  final num basicMax;
  final num basicPct;
  final num? enrichSum;
  final num? enrichMax;
  final num? enrichPct;
  final List<BasicSubjectReport> basicSubjects;
  final List<EnrichmentSubjectReport> enrichmentSubjects;
  final List<ParentNote> notes;
  final List<AcademicYearOption> availableYears;
  final int selectedAcademicYearId;

  GradeReport({
    required this.studentName,
    required this.gradeName,
    required this.sectionName,
    this.academicYear,
    required this.useExamGrades,
    required this.grandPct,
    required this.grandTotal,
    required this.grandMax,
    required this.rank,
    required this.totalStudents,
    required this.subjectsCount,
    required this.passed,
    required this.nextGrade,
    required this.award,
    required this.basicSum,
    required this.basicMax,
    required this.basicPct,
    this.enrichSum,
    this.enrichMax,
    this.enrichPct,
    required this.basicSubjects,
    required this.enrichmentSubjects,
    required this.notes,
    required this.availableYears,
    required this.selectedAcademicYearId,
  });

  bool get hasEnrichment => enrichMax != null && (enrichMax ?? 0) > 0;

  bool get hasUnreadReply => notes.any((n) => n.adminReply != null && n.adminReply!.isNotEmpty);

  bool get hasMultipleYears => availableYears.length > 1;

  factory GradeReport.fromJson(Map<String, dynamic> json) => GradeReport(
    studentName: json['student_name'] ?? '',
    gradeName: json['grade_name'] ?? '',
    sectionName: json['section_name'] ?? '',
    academicYear: json['academic_year'],
    useExamGrades: json['use_exam_grades'] ?? false,
    grandPct: json['grand_pct'] ?? 0,
    grandTotal: json['grand_total'] ?? 0,
    grandMax: json['grand_max'] ?? 0,
    rank: json['rank'] ?? 0,
    totalStudents: json['total_students'] ?? 0,
    subjectsCount: json['subjects_count'] ?? 0,
    passed: json['passed'] ?? false,
    nextGrade: json['next_grade'] ?? '',
    award: Award.fromJson(json['award'] ?? {}),
    basicSum: json['basic_sum'] ?? 0,
    basicMax: json['basic_max'] ?? 0,
    basicPct: json['basic_pct'] ?? 0,
    enrichSum: json['enrich_sum'],
    enrichMax: json['enrich_max'],
    enrichPct: json['enrich_pct'],
    basicSubjects: (json['basic_subjects'] as List? ?? [])
        .map((e) => BasicSubjectReport.fromJson(e as Map<String, dynamic>))
        .toList(),
    enrichmentSubjects: (json['enrichment_subjects'] as List? ?? [])
        .map((e) => EnrichmentSubjectReport.fromJson(e as Map<String, dynamic>))
        .toList(),
    notes: (json['notes'] as List? ?? [])
        .map((e) => ParentNote.fromJson(e as Map<String, dynamic>))
        .toList(),
    availableYears: (json['available_years'] as List? ?? [])
        .map((e) => AcademicYearOption.fromJson(e as Map<String, dynamic>))
        .toList(),
    selectedAcademicYearId: json['selected_academic_year_id'] ?? 0,
  );
}