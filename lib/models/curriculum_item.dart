/// ملف منهج دراسي واحد — يقابل الصف يلي بيرجعه get_curriculum.php
/// (مصدره جدول curricula، مفلتر على صف الطالب فعلياً).
///
/// ⚠️ [fileUrl] بيوصل كامل جاهز من السيرفر مباشرة (نفس نمط
/// WorksheetItem.fileUrl بالضبط) — ما في داعي تبنيلها رابط إضافي
/// بالتطبيق.
class CurriculumItem {
  final int id;
  final String title;
  final int subjectId;
  final String subjectName;
  final String? gradeName;
  final String? fileUrl;
  final String? fileName;
  final int fileSize;
  final DateTime createdAt;

  const CurriculumItem({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    this.gradeName,
    this.fileUrl,
    this.fileName,
    required this.fileSize,
    required this.createdAt,
  });

  String get fileExtension {
    final name = fileName;
    if (name == null || !name.contains('.')) return '';
    return name.split('.').last.toLowerCase();
  }

  String get fileSizeLabel {
    final mb = fileSize / 1024 / 1024;
    return '${mb.toStringAsFixed(mb < 10 ? 2 : 1)} MB';
  }

  factory CurriculumItem.fromJson(Map<String, dynamic> json) {
    String? _nullIfEmpty(dynamic v) {
      final s = (v as String?)?.trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return CurriculumItem(
      id: json['id'] is String ? int.parse(json['id']) : (json['id'] as int? ?? 0),
      title: json['title']?.toString() ?? '',
      subjectId: json['subject_id'] is String ? int.parse(json['subject_id']) : (json['subject_id'] as int? ?? 0),
      subjectName: json['subject_name']?.toString() ?? '',
      gradeName: _nullIfEmpty(json['grade_name'] as String?),
      fileUrl: _nullIfEmpty(json['file_url'] as String?),
      fileName: _nullIfEmpty(json['file_name'] as String?),
      fileSize: json['file_size'] is String ? int.parse(json['file_size']) : (json['file_size'] as int? ?? 0),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
