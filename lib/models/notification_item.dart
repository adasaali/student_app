class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String type; // 'absence' وممكن أنواع ثانية بالمستقبل
  final bool isRead;
  final DateTime createdAt;

  /// معرّف واسم صاحب هالإشعار (الطالب الأساسي أو أحد إخوته).
  /// ما بيجي من السيرفر مباشرة — منحطّه إحنا بـ StudentProvider لما
  /// منجيب إشعارات كل حساب (أساسي/أخ) على حدا، عشان نقدر نميّز
  /// إشعار كل حساب لما نعرضهم سوا بقائمة موحّدة.
  final int? ownerId;
  final String? ownerName;
  final String? ownerGender; // 'male'/'female' - لتلوين بطاقة الإشعار بلون صاحبها الفعلي (SiblingPalette)

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.ownerId,
    this.ownerName,
    this.ownerGender,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  NotificationItem copyWith({
    bool? isRead,
    int? ownerId,
    String? ownerName,
    String? ownerGender,
  }) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerGender: ownerGender ?? this.ownerGender,
    );
  }
}
