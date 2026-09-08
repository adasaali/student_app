/// موديلات المعرض عند الطالب — تقابل get_gallery.php بوضعيه:
/// - وضع القائمة (بدون album_id): كل الألبومات المتاحة لصف/شعبة الطالب،
///   كل عنصر فيها بيرجع cover_url/cover_type/media_count بس (بدون media).
/// - وضع التفاصيل (؟album_id=): ألبوم واحد مع مصفوفة media كاملة.
///
/// ⚠️ الروابط (cover_url / media.url) نسبية غالباً (مثلاً
/// "uploads/gallery/xxx.jpg") — لازم تُبنى برابط كامل بإضافة دومين
/// السيرفر (نفس فكرة AnnouncementItem.imageUrl تماماً). لو كان الرابط
/// خارجي أصلاً (فيديو يوتيوب مثلاً) بيرجع كما هو بدون أي تعديل.
library;

String? _nullIfEmpty(dynamic v) {
  final s = (v as String?)?.trim();
  return (s == null || s.isEmpty) ? null : s;
}

String? _resolve(String? path, String rootUrl) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final cleanBase = rootUrl.endsWith('/') ? rootUrl.substring(0, rootUrl.length - 1) : rootUrl;
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;
  return '$cleanBase/$cleanPath';
}

/// عنصر واحد داخل ألبوم (صورة أو فيديو) — من مصفوفة "media" بوضع
/// تفاصيل الألبوم.
class GalleryMediaItem {
  final int id;
  final String mediaType; // 'image' | 'video'
  final String? path;
  final bool isExternal;
  final DateTime? createdAt;

  const GalleryMediaItem({
    required this.id,
    required this.mediaType,
    this.path,
    this.isExternal = false,
    this.createdAt,
  });

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';

  String? resolvedUrl(String rootUrl) => _resolve(path, rootUrl);

  factory GalleryMediaItem.fromJson(Map<String, dynamic> json) {
    return GalleryMediaItem(
      id: int.tryParse('${json['id']}') ?? 0,
      mediaType: json['media_type']?.toString() ?? 'image',
      path: _nullIfEmpty(json['url'] as String?),
      isExternal: json['is_external'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

/// ألبوم صور/فيديو — يقابل عنصر بمصفوفة "data" بوضع القائمة، أو
/// الكائن الكامل بمفتاح "data" بوضع تفاصيل الألبوم (مع media إضافية).
class GalleryAlbum {
  final int id;
  final String title;
  final String? description;
  final DateTime? createdAt;
  final int mediaCount;
  final String? coverPath;
  final String? coverType; // 'image' | 'video'
  final List<GalleryMediaItem> media;

  const GalleryAlbum({
    required this.id,
    required this.title,
    this.description,
    this.createdAt,
    this.mediaCount = 0,
    this.coverPath,
    this.coverType,
    this.media = const [],
  });

  String? resolvedCoverUrl(String rootUrl) => _resolve(coverPath, rootUrl);

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    final mediaList = <GalleryMediaItem>[];
    if (rawMedia is List) {
      for (final m in rawMedia) {
        if (m is Map) mediaList.add(GalleryMediaItem.fromJson(m.cast<String, dynamic>()));
      }
    }

    return GalleryAlbum(
      id: int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      description: _nullIfEmpty(json['description'] as String?),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      mediaCount: int.tryParse('${json['media_count'] ?? mediaList.length}') ?? mediaList.length,
      coverPath: _nullIfEmpty(json['cover_url'] as String?),
      coverType: json['cover_type']?.toString(),
      media: mediaList,
    );
  }
}
