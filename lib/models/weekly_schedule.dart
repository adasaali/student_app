/// موديلات البرنامج الأسبوعي — تطابق شكل رد get_weekly_schedule.php

class SchedulePeriod {
  final int id;
  final int periodNumber;
  final String label;

  SchedulePeriod({
    required this.id,
    required this.periodNumber,
    required this.label,
  });

  factory SchedulePeriod.fromJson(Map<String, dynamic> json) {
    return SchedulePeriod(
      id: json['id'] is int ? json['id'] : int.parse('${json['id']}'),
      periodNumber: json['period_number'] is int
          ? json['period_number']
          : int.parse('${json['period_number']}'),
      label: json['period_label']?.toString() ?? '',
    );
  }
}

class ScheduleSlot {
  final String subjectName;
  final String teacherName;

  ScheduleSlot({required this.subjectName, required this.teacherName});

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    return ScheduleSlot(
      subjectName: json['subject_name']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ?? '',
    );
  }
}

class WeeklySchedule {
  final String gradeName;
  final String sectionName;
  final List<SchedulePeriod> periods;
  final List<String> dayNames;
  final Map<String, ScheduleSlot> cells; // key: "{dayIndex}_{periodId}"

  WeeklySchedule({
    required this.gradeName,
    required this.sectionName,
    required this.periods,
    required this.dayNames,
    required this.cells,
  });

  /// يرجع الحصة الموجودة بيوم معيّن (index بالـ dayNames) وحصة معيّنة، أو null إذا فاضية
  ScheduleSlot? slotFor(int dayIndex, int periodId) {
    return cells['${dayIndex}_$periodId'];
  }

  /// إجمالي عدد الحصص المشغولة بالأسبوع
  int get totalPeriods => cells.length;

  bool get isEmpty => cells.isEmpty;

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final periodsJson = (json['periods'] as List? ?? []);
    final dayNamesJson = (json['day_names'] as List? ?? []);
    final cellsJson = (json['cells'] as Map? ?? {});

    return WeeklySchedule(
      gradeName: json['grade_name']?.toString() ?? '',
      sectionName: json['section_name']?.toString() ?? '',
      periods: periodsJson
          .map((e) => SchedulePeriod.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      dayNames: dayNamesJson.map((e) => e.toString()).toList(),
      cells: cellsJson.map((key, value) => MapEntry(
            key.toString(),
            ScheduleSlot.fromJson((value as Map).cast<String, dynamic>()),
          )),
    );
  }
}
