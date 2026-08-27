class AbsenceRecord {
  final int id;
  final DateTime date;
  final String status; // 'absent' | 'present'
  final String? reason;

  AbsenceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.reason,
  });

  bool get isAbsent => status == 'absent';

  factory AbsenceRecord.fromJson(Map<String, dynamic> json) {
    return AbsenceRecord(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      date: DateTime.tryParse(json['attendance_date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'absent',
      reason: (json['reason'] == null || json['reason'] == '') ? null : json['reason'],
    );
  }
}

class AbsenceStats {
  final int totalAbsences;
  final int thisMonthAbsences;

  AbsenceStats({required this.totalAbsences, required this.thisMonthAbsences});

  factory AbsenceStats.fromJson(Map<String, dynamic> json) {
    return AbsenceStats(
      totalAbsences: json['total_absences'] ?? 0,
      thisMonthAbsences: json['this_month_absences'] ?? 0,
    );
  }

  factory AbsenceStats.empty() => AbsenceStats(totalAbsences: 0, thisMonthAbsences: 0);
}
