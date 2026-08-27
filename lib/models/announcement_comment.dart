/// موديل تعليق واحد على إعلان — يقابل الصف يلي بيرجعه
/// get_announcement_comments.php / add_announcement_comment.php.
class AnnouncementComment {
  final int id;
  final String authorName;
  final String role; // 'student' | 'admin' | 'supervisor' | ...
  final String comment;
  final DateTime createdAt;
  final bool isMine;

  const AnnouncementComment({
    required this.id,
    required this.authorName,
    required this.role,
    required this.comment,
    required this.createdAt,
    this.isMine = false,
  });

  factory AnnouncementComment.fromJson(Map<String, dynamic> json) {
    return AnnouncementComment(
      id: int.tryParse(json['id'].toString()) ?? 0,
      authorName: json['author_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isMine: json['is_mine'] == true || json['is_mine'] == 1 || json['is_mine'] == '1',
    );
  }
}
