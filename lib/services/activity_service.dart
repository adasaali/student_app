import 'dart:async';
import 'api_service.dart';

/// 🆕 ActivityService
/// طبقة صغيرة فوق ApiService.logActivity مسؤولة عن نظام "مين أونلاين
/// وشو عم يعمل" اللي المدير بيشوفه. مسؤوليتين رئيسيتين:
///
/// 1) logScreenView(...) — تسجيل بسيط لفتح شاشة (غياب، واجبات...).
/// 2) startViewSession(...) / endViewSession() — تتبّع "من وقت لوقت"
///    فتح الطالب صفحته أو صفحة أخ من إخوانه (المدة الفعلية بالثواني)،
///    مربوطة تلقائياً بلحظة تبديل الحساب (switchToAccount/Primary).
///
/// كل نداءاتها fire-and-forget (ما بتنتظرها الواجهة أبداً) — فشلها ما
/// بأثر على أي شاشة بالتطبيق.
class ActivityService {
  final ApiService _api;
  ActivityService(this._api);

  int? _sessionStudentId;
  DateTime? _sessionStartedAt;

  /// تسجيل دخول ناجح — تُنادى مرة وحدة بعد login() مباشرة.
  void logLogin() {
    unawaited(_api.logActivity('login'));
  }

  /// فتح شاشة معيّنة (غياب، واجبات، درجات...) للحساب النشط حالياً.
  /// [studentId] هو id الحساب النشط وقت الفتح (أساسي أو أخ).
  void logScreenView(String actionType, {int? studentId}) {
    unawaited(_api.logActivity(actionType, studentId: studentId));
  }

  /// تبدأ تتبع "مدة مشاهدة" صفحة حساب معيّن (أساسي أو أخ). إذا كانت في
  /// جلسة سابقة مفتوحة لحساب تاني، منسكرها ومنبعت مدتها أولاً قبل ما
  /// نبلش الجديدة — هيك ما بتضيع ولا لحظة من وقت المستخدم الفعلي.
  void startViewSession(int studentId) {
    if (_sessionStudentId == studentId) return; // نفس الجلسة أصلاً
    endViewSession(); // يسكّر ويبعت الجلسة السابقة (لو موجودة) أولاً
    _sessionStudentId = studentId;
    _sessionStartedAt = DateTime.now();
  }

  /// تسكّر الجلسة الحالية (لو موجودة) وتبعت مدتها بالثواني للسيرفر.
  /// تُنادى: قبل أي تبديل حساب، ولما يطلع المستخدم من التطبيق
  /// (AppLifecycleState.paused/detached)، ولما يسجل خروج.
  void endViewSession() {
    if (_sessionStudentId == null || _sessionStartedAt == null) return;

    final durationSecs = DateTime.now().difference(_sessionStartedAt!).inSeconds;
    final studentId = _sessionStudentId!;

    _sessionStudentId = null;
    _sessionStartedAt = null;

    // جلسات أقل من ثانيتين غالباً فتح وسكر بالغلط (سكرول سريع) — ما
    // فيها قيمة تحليلية، منتجاهلها حتى ما نزحم سجل النشاط بالفاضي.
    if (durationSecs < 2) return;

    unawaited(_api.logActivity('view_session', studentId: studentId, durationSecs: durationSecs));
  }
}
