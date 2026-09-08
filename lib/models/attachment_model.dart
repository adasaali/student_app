import 'package:flutter/material.dart';

/// نوع المرفق — بنحدده من الامتداد (وبالإضافة mime_type إذا السيرفر بعته).
enum AttachmentType { image, video, audio, pdf, word, excel, other }

/// موديل مرفق موحّد — مستخدم بالشات (ChatMessage) وبالمقررات
/// (HomeworkItem / HomeworkModel) بالتطبيقين (طالب + مشرف).
///
/// السيرفر (الباك إند) لازم يرجع لكل مرفق على الأقل: id, url, fileName
/// (أو ما يعادلهم). الباقي (النوع، الأيقونة، الحجم المقروء) منحسبه
/// محلياً على الكلاينت عشان ما نحمّل الباك إند شغل عرض هو مش مسؤول عنه.
@immutable
class Attachment {
  final int? id;
  final String url;
  final String fileName;
  final AttachmentType type;

  /// حجم الملف بالبايت — اختياري (لو السيرفر رجعه)، منستخدمه لعرض
  /// حجم مقروء ("2.4 MB") جنب اسم الملف.
  final int? sizeBytes;

  /// مدة الفيديو/الصوت بالثواني — اختياري (لو السيرفر رجعها)، وإلا
  /// منحسبها وقت التشغيل من الملف نفسه.
  final int? durationSeconds;

  /// عرض/طول الصورة أو الفيديو الأصلي — يساعد بحساب نسبة العرض للطول
  /// بمعاينة الشات قبل ما الصورة تحمّل فعلياً (تلافي "قفزة" بالـ layout).
  final int? width;
  final int? height;

  const Attachment({
    this.id,
    required this.url,
    required this.fileName,
    required this.type,
    this.sizeBytes,
    this.durationSeconds,
    this.width,
    this.height,
  });

  factory Attachment.fromJson(Map<String, dynamic> j) {
    final url = (j['url'] ?? j['file_url'] ?? j['attachment_url'] ?? '').toString();
    final name = (j['file_name'] ?? j['fileName'] ?? j['name'] ?? _guessNameFromUrl(url)).toString();
    return Attachment(
      id: j['id'] == null ? null : int.tryParse(j['id'].toString()),
      url: url,
      fileName: name,
      type: typeFromName(j['mime_type']?.toString() ?? name),
      sizeBytes: j['size_bytes'] == null ? null : int.tryParse(j['size_bytes'].toString()),
      durationSeconds: j['duration_seconds'] == null ? null : int.tryParse(j['duration_seconds'].toString()),
      width: j['width'] == null ? null : int.tryParse(j['width'].toString()),
      height: j['height'] == null ? null : int.tryParse(j['height'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'url': url,
        'file_name': fileName,
        if (sizeBytes != null) 'size_bytes': sizeBytes,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

  static String _guessNameFromUrl(String url) {
    if (url.isEmpty) return 'ملف';
    final clean = url.split('?').first;
    final parts = clean.split('/');
    return parts.isNotEmpty && parts.last.isNotEmpty ? parts.last : 'ملف';
  }

  static const _imageExt = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'};
  static const _videoExt = {'mp4', 'mov', 'm4v', '3gp', 'avi', 'mkv', 'webm'};
  static const _audioExt = {'mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'amr', 'flac'};
  static const _wordExt = {'doc', 'docx'};
  static const _excelExt = {'xls', 'xlsx', 'csv'};

  /// بيحدد [AttachmentType] من اسم الملف أو من mime type (لو موجود
  /// بصيغة "image/jpeg" مثلاً).
  static AttachmentType typeFromName(String nameOrMime) {
    final lower = nameOrMime.toLowerCase();

    if (lower.contains('/')) {
      // شكله mime type: image/jpeg, video/mp4, audio/mpeg, application/pdf...
      if (lower.startsWith('image/')) return AttachmentType.image;
      if (lower.startsWith('video/')) return AttachmentType.video;
      if (lower.startsWith('audio/')) return AttachmentType.audio;
      if (lower.contains('pdf')) return AttachmentType.pdf;
      if (lower.contains('word') || lower.contains('msword') || lower.contains('officedocument.wordprocessingml')) {
        return AttachmentType.word;
      }
      if (lower.contains('sheet') || lower.contains('excel') || lower.contains('csv')) {
        return AttachmentType.excel;
      }
      return AttachmentType.other;
    }

    final ext = lower.contains('.') ? lower.split('.').last : lower;
    if (_imageExt.contains(ext)) return AttachmentType.image;
    if (_videoExt.contains(ext)) return AttachmentType.video;
    if (_audioExt.contains(ext)) return AttachmentType.audio;
    if (ext == 'pdf') return AttachmentType.pdf;
    if (_wordExt.contains(ext)) return AttachmentType.word;
    if (_excelExt.contains(ext)) return AttachmentType.excel;
    return AttachmentType.other;
  }

  IconData get icon {
    switch (type) {
      case AttachmentType.image:
        return Icons.image_rounded;
      case AttachmentType.video:
        return Icons.videocam_rounded;
      case AttachmentType.audio:
        return Icons.mic_rounded;
      case AttachmentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case AttachmentType.word:
        return Icons.description_rounded;
      case AttachmentType.excel:
        return Icons.table_chart_rounded;
      case AttachmentType.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color get color {
    switch (type) {
      case AttachmentType.image:
        return const Color(0xFF7C4DFF);
      case AttachmentType.video:
        return const Color(0xFFE53935);
      case AttachmentType.audio:
        return const Color(0xFF00897B);
      case AttachmentType.pdf:
        return const Color(0xFFD32F2F);
      case AttachmentType.word:
        return const Color(0xFF1565C0);
      case AttachmentType.excel:
        return const Color(0xFF2E7D32);
      case AttachmentType.other:
        return const Color(0xFF757575);
    }
  }

  String get extensionLabel {
    final n = fileName.toLowerCase();
    return n.contains('.') ? n.split('.').last.toUpperCase() : type.name.toUpperCase();
  }

  /// حجم مقروء ("2.4 MB", "340 KB") — يرجع null لو ما في sizeBytes.
  String? get readableSize {
    final bytes = sizeBytes;
    if (bytes == null || bytes <= 0) return null;
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  /// هل معاينة الملف هذا مدعومة "أصلياً" جوا التطبيق (صورة/فيديو/صوت/PDF)
  /// أو لأ (Word/Excel/غيره) وبالتالي لازم شاشة معلومات بديلة.
  bool get hasNativePreview =>
      type == AttachmentType.image ||
      type == AttachmentType.video ||
      type == AttachmentType.audio ||
      type == AttachmentType.pdf;
}
