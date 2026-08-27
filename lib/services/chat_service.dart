import 'dart:async';
import 'api_service.dart';
import 'chat_models.dart';

/// نسخة الشات الجديدة — بديل كامل عن chat_service.dart القديم المبني
/// على Firestore. نفس الوظائف (محادثة جماعية + خاصة، عداد غير مقروء،
/// قفل/فتح، إرسال رسالة) بس مصدر البيانات هلق MySQL عبر [ApiService].
///
/// بما إنه ما في أكتر real-time listener (Firestore snapshots)، منعتمد
/// على polling خفيف (Timer.periodic) وبنغلفه بـ Stream عادي عشان
/// الشاشات (chat_screen.dart / messages_screen.dart) تضل تستخدم
/// StreamBuilder متل ما هي بدون أي تغيير بالمنطق عندها.
///
/// 🔧 [targetStudentId] مضاف بكل دالة هون (نفس نمط fetchAbsences/
/// fetchHomework بـ ApiService) عشان تبديل الحساب لأخ ينعكس فعلياً على
/// الشات — قبل هيك كانت كل الدوال بتجيب/بترسل دايماً باسم صاحب التوكن
/// بغض النظر مين الحساب النشط بالتطبيق.
class ChatService {
  final ApiService _api;
  ChatService(this._api);

  // ─────────────────────────────────────────────────────────
  // محادثات الطالب (الجماعية + الخاصة مع مشرفه)
  // ─────────────────────────────────────────────────────────

  Future<List<ChatConversation>> fetchStudentConversations({int? targetStudentId}) async {
    final list = await _api.fetchChatConversations(targetStudentId: targetStudentId);
    return list.map(ChatConversation.fromJson).toList();
  }

  /// بث دوري (كل [interval]) بمحادثات الطالب — بديل watchStudentConversations.
  Stream<List<ChatConversation>> watchStudentConversations({
    int? targetStudentId,
    Duration interval = const Duration(seconds: 6),
  }) {
    return _poll(() => fetchStudentConversations(targetStudentId: targetStudentId), interval);
  }

  /// عداد إجمالي غير مقروء لأيقونة الجرس بالشاشة الرئيسية.
  Stream<int> watchTotalUnreadForStudent({int? targetStudentId, Duration interval = const Duration(seconds: 6)}) {
    return watchStudentConversations(targetStudentId: targetStudentId, interval: interval)
        .map((list) => list.fold<int>(0, (sum, c) => sum + c.unreadCount));
  }

  // ─────────────────────────────────────────────────────────
  // رسائل محادثة معيّنة
  // ─────────────────────────────────────────────────────────

  Future<List<ChatMessage>> fetchMessages(int conversationId, {int? targetStudentId}) async {
    final list = await _api.fetchChatMessages(conversationId, targetStudentId: targetStudentId);
    return list.map(ChatMessage.fromJson).toList();
  }

  /// بث دوري (كل [interval]) برسائل محادثة معيّنة — بديل watchMessages.
  Stream<List<ChatMessage>> watchMessages(
      int conversationId, {
        int? targetStudentId,
        Duration interval = const Duration(seconds: 3),
      }) {
    return _poll(() => fetchMessages(conversationId, targetStudentId: targetStudentId), interval);
  }

  // ─────────────────────────────────────────────────────────
  // إرسال رسالة / تعليم كمقروء
  // ─────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required int conversationId,
    required String text,
    int? targetStudentId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _api.sendChatMessage(
      conversationId: conversationId,
      text: trimmed,
      targetStudentId: targetStudentId,
    );
  }

  Future<void> markRead(int conversationId, {int? targetStudentId}) =>
      _api.markChatRead(conversationId, targetStudentId: targetStudentId);

  // ─────────────────────────────────────────────────────────
  // Helper: يحوّل أي Future<T> Function() لبث دوري (polling stream).
  // ─────────────────────────────────────────────────────────
  Stream<T> _poll<T>(Future<T> Function() fetch, Duration interval) {
    late StreamController<T> controller;
    Timer? timer;

    Future<void> tick() async {
      try {
        final data = await fetch();
        if (!controller.isClosed) controller.add(data);
      } catch (e) {
        // 🔧 قبل كان الخطأ بينبلع بصمت هون، فلو الطلب فشل بشكل مستمر
        // (انقطاع نت، توكن منتهي، سيرفر واقع...) الـ StreamBuilder بيضل
        // واقف على "hasData == false" للأبد ويعرض سبينر تحميل بلا نهاية
        // من غير ما يعرف المستخدم إنو في مشكلة فعلية. هلق منبعت الخطأ
        // عالـ stream (بدون ما نقفلو) عشان الواجهة تقدر تعرض حالة خطأ
        // واضحة، وبنفس الوقت الـ Timer بضل شغال وبيعيد المحاولة —
        // أول نجاح جاي بيصحح الحالة تلقائياً.
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<T>.broadcast(
      onListen: () {
        tick();
        timer = Timer.periodic(interval, (_) => tick());
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
      },
    );

    return controller.stream;
  }
}