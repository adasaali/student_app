/// ورقة عمل واحدة — تقابل الصف يلي بيرجعه get_worksheets.php
/// (مصدرها جدول awraq_al_amal، تُشارَك فقط من قِبل الأدمن رقم 10 عبر
/// لوحة أوراق العمل).
///
/// ⚠️ [fileUrl] بيوصل كامل جاهز من السيرفر مباشرة (السيرفر هو يلي
/// بيبني الرابط الكامل، عكس imagePath بـ AnnouncementItem) — ما في
/// داعي تبنيلها رابط إضافي بالتطبيق.
class WorksheetItem {
  final int id;
  final String worksheetName;
  final String? gradeName;
  final String? fileUrl;
  final String? fileName;
  final DateTime createdAt;

  const WorksheetItem({
    required this.id,
    required this.worksheetName,
    this.gradeName,
    this.fileUrl,
    this.fileName,
    required this.createdAt,
  });

  String get fileExtension {
    final name = fileName;
    if (name == null || !name.contains('.')) return '';
    return name.split('.').last.toLowerCase();
  }

  factory WorksheetItem.fromJson(Map<String, dynamic> json) {
    String? _nullIfEmpty(dynamic v) {
      final s = (v as String?)?.trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return WorksheetItem(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] as int? ?? 0),
      worksheetName: json['worksheet_name']?.toString() ?? '',
      gradeName: _nullIfEmpty(json['grade_name'] as String?),
      fileUrl: _nullIfEmpty(json['file_url'] as String?),
      fileName: _nullIfEmpty(json['file_name'] as String?),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
