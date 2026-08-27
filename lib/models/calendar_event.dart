import 'package:flutter/material.dart';

/// أنواع أحداث التقويم المدرسي — نفس القيم المخزّنة بعمود event_type
/// بجدول calendar_events (شوف calendar_events.sql).
enum CalendarEventType {
  teacherStart,
  studentStart,
  examPeriod,
  midYearBreak,
  holiday,
  activity,
  meeting,
  other;

  static CalendarEventType fromApi(String? value) {
    switch (value) {
      case 'teacher_start':
        return CalendarEventType.teacherStart;
      case 'student_start':
        return CalendarEventType.studentStart;
      case 'exam_period':
        return CalendarEventType.examPeriod;
      case 'mid_year_break':
        return CalendarEventType.midYearBreak;
      case 'holiday':
        return CalendarEventType.holiday;
      case 'activity':
        return CalendarEventType.activity;
      case 'meeting':
        return CalendarEventType.meeting;
      default:
        return CalendarEventType.other;
    }
  }
}

/// حدث واحد بالتقويم المدرسي — مطابق لأعمدة رد get_calendar_events.php
/// بالضبط. نفس البيانات يلي بيديرها الأدمن من صفحة
/// admin/calendar/school_calendar.php.
class CalendarEvent {
  final int id;
  final String title;
  final String? subtitle;
  final DateTime startDate;
  final DateTime? endDate; // شامِلة — null يعني حدث يوم واحد
  final CalendarEventType type;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.subtitle,
    required this.startDate,
    this.endDate,
    required this.type,
  });

  DateTime get rangeEnd => endDate ?? startDate;

  /// هل يقع اليوم [d] ضمن مدة هذا الحدث؟
  bool includesDay(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  /// هل تتقاطع مدة الحدث مع الشهر [monthStart] (أول يوم بالشهر)؟
  bool overlapsMonth(DateTime monthStart) {
    final monthEndExclusive = DateTime(monthStart.year, monthStart.month + 1, 1);
    return startDate.isBefore(monthEndExclusive) &&
        rangeEnd.isAfter(monthStart.subtract(const Duration(days: 1)));
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    String? cleanOrNull(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final endRaw = cleanOrNull(json['end_date']);

    return CalendarEvent(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: cleanOrNull(json['subtitle']),
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: endRaw != null ? DateTime.tryParse(endRaw) : null,
      type: CalendarEventType.fromApi(json['event_type']?.toString()),
    );
  }

  Color get color {
    switch (type) {
      case CalendarEventType.teacherStart:
        return const Color(0xFFF5A623);
      case CalendarEventType.studentStart:
        return const Color(0xFF5B9BD5);
      case CalendarEventType.examPeriod:
        return const Color(0xFF7CB342);
      case CalendarEventType.midYearBreak:
        return const Color(0xFFE0A585);
      case CalendarEventType.holiday:
        return const Color(0xFF06B6D4);
      case CalendarEventType.activity:
        return const Color(0xFFDB2777);
      case CalendarEventType.meeting:
        return const Color(0xFF9333EA);
      case CalendarEventType.other:
        return const Color(0xFF64748B);
    }
  }

  IconData get icon {
    switch (type) {
      case CalendarEventType.teacherStart:
        return Icons.school_rounded;
      case CalendarEventType.studentStart:
        return Icons.backpack_rounded;
      case CalendarEventType.examPeriod:
        return Icons.fact_check_rounded;
      case CalendarEventType.midYearBreak:
        return Icons.beach_access_rounded;
      case CalendarEventType.holiday:
        return Icons.celebration_rounded;
      case CalendarEventType.activity:
        return Icons.sports_soccer_rounded;
      case CalendarEventType.meeting:
        return Icons.groups_rounded;
      case CalendarEventType.other:
        return Icons.event_note_rounded;
    }
  }

  String get typeLabel {
    switch (type) {
      case CalendarEventType.teacherStart:
        return 'دوام تدريسي';
      case CalendarEventType.studentStart:
        return 'بدء دوام';
      case CalendarEventType.examPeriod:
        return 'امتحانات';
      case CalendarEventType.midYearBreak:
        return 'عطلة';
      case CalendarEventType.holiday:
        return 'عطلة رسمية';
      case CalendarEventType.activity:
        return 'نشاط';
      case CalendarEventType.meeting:
        return 'اجتماع';
      case CalendarEventType.other:
        return 'حدث';
    }
  }
}
