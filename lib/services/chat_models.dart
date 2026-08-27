enum ConversationType { group, private }

/// محادثة (جماعية تبع شعبة، أو خاصة بين مشرف وطالب).
/// صار مصدرها الآن endpoint (get_chat_conversations.php) بدل Firestore —
/// السيرفر نفسه بيحسب unread_count الخاص بصاحب التوكن الحالي، فما عاد
/// في داعي نحمل خارطة last_read_count كاملة على الكلاينت.
class ChatConversation {
  final int id;
  final ConversationType type;
  final int? sectionId; // للجماعية
  final String? sectionName;
  final int? supervisorId; // فاضي بالجماعية، موجود دايماً بالخاصة
  final String? supervisorName; // اسم مشرف هالمحادثة الخاصة (فاضي بالجماعية)
  final int? studentId; // للخاصة
  final String? studentName;
  final bool isLocked;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderType; // 'student' | 'supervisor'
  final int? lastSenderId;
  final int messageCount;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.type,
    this.sectionId,
    this.sectionName,
    this.supervisorId,
    this.supervisorName,
    this.studentId,
    this.studentName,
    required this.isLocked,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderType,
    this.lastSenderId,
    this.messageCount = 0,
    this.unreadCount = 0,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return ChatConversation(
      id: j['id'] is int ? j['id'] as int : int.parse(j['id'].toString()),
      type: j['type'] == 'group' ? ConversationType.group : ConversationType.private,
      sectionId: j['section_id'] == null ? null : int.parse(j['section_id'].toString()),
      sectionName: j['section_name'] as String?,
      supervisorId: j['supervisor_id'] == null ? null : int.parse(j['supervisor_id'].toString()),
      supervisorName: j['supervisor_name'] as String?,
      studentId: j['student_id'] == null ? null : int.parse(j['student_id'].toString()),
      studentName: j['student_name'] as String?,
      isLocked: j['is_locked'] as bool? ?? false,
      lastMessage: j['last_message'] as String?,
      lastMessageAt: parseDate(j['last_message_at']),
      lastSenderType: j['last_sender_type'] as String?,
      lastSenderId: j['last_sender_id'] == null ? null : int.parse(j['last_sender_id'].toString()),
      messageCount: j['message_count'] as int? ?? 0,
      unreadCount: j['unread_count'] as int? ?? 0,
    );
  }
}

class ChatMessage {
  final int id;
  final String senderType; // 'supervisor' | 'student'
  final int senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;
  // 🔧 حالة القراءة الحقيقية من السيرفر (مبنية على chat_reads):
  // true = الطرف التاني قرأها، false = لسا مو مقروءة، null = محادثة
  // جماعية (ما في "قارئ واحد" نقارن فيه، فما منعرض شيكة قراءة أصلاً).
  final bool? isRead;

  ChatMessage({
    required this.id,
    required this.senderType,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    return ChatMessage(
      id: j['id'] is int ? j['id'] as int : int.parse(j['id'].toString()),
      senderType: j['sender_type'] as String,
      senderId: j['sender_id'] is int ? j['sender_id'] as int : int.parse(j['sender_id'].toString()),
      senderName: j['sender_name'] as String? ?? '',
      text: j['text'] as String? ?? '',
      createdAt: j['created_at'] == null ? null : DateTime.tryParse(j['created_at'].toString()),
      isRead: j['is_read'] as bool?,
    );
  }
}