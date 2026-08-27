/// موديل إعلان واحد — يقابل الصف يلي بيرجعه get_announcements.php.
///
/// ⚠️ [imagePath] نسبي (مثلاً "uploads/announcements/xxx.jpg") — لازم
/// تبنيلها رابط كامل بإضافة دومين السيرفر (نفس فكرة أي صورة/مرفق
/// تاني بالتطبيق). راجع [imageUrl] تحت.
class AnnouncementItem {
  final int id;
  final String title;
  final String? content;
  final String? imagePath;
  final String? videoUrl;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  const AnnouncementItem({
    required this.id,
    required this.title,
    this.content,
    this.imagePath,
    this.videoUrl,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    String? _nullIfEmpty(dynamic v) {
      final s = (v as String?)?.trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return AnnouncementItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      content: _nullIfEmpty(json['content'] as String?),
      imagePath: _nullIfEmpty(json['image_path'] as String?),
      videoUrl: _nullIfEmpty(json['video_url'] as String?),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      likeCount: int.tryParse(json['like_count']?.toString() ?? '0') ?? 0,
      commentCount: int.tryParse(json['comment_count']?.toString() ?? '0') ?? 0,
      isLiked: json['is_liked'] == true || json['is_liked'] == 1 || json['is_liked'] == '1',
    );
  }

  /// رابط الصورة الكامل — عدّل baseUrl حسب دومين السيرفر عندك (نفس
  /// الـbase URL يلي ApiService عم يستخدمه لباقي الطلبات).
  String? imageUrl(String baseUrl) {
    if (imagePath == null) return null;
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = imagePath!.startsWith('/') ? imagePath!.substring(1) : imagePath!;
    return '$cleanBase/$cleanPath';
  }

  /// نسخة معدّلة — تُستخدم للتحديث الفوري (optimistic) لعدد اللايكات/
  /// حالة الإعجاب/عدد التعليقات بعد تفاعل المستخدم، بدون إعادة تحميل
  /// كامل قائمة الإعلانات من السيرفر.
  AnnouncementItem copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLiked,
  }) {
    return AnnouncementItem(
      id: id,
      title: title,
      content: content,
      imagePath: imagePath,
      videoUrl: videoUrl,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}