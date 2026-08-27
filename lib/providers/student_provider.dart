import 'dart:async';
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/student_model.dart';
import '../models/notification_item.dart';
import '../models/absence_record.dart';
import '../models/grade_report.dart';
import '../models/weekly_schedule.dart';
import '../models/homework_item.dart';
import '../models/announcement_item.dart';
import '../models/announcement_comment.dart';
import '../models/behavior_note.dart';
import '../models/worksheet_item.dart';
import '../models/calendar_event.dart';
import '../models/finance_data.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

/// ملخّص موحّد لحساب واحد (الطالب الأساسي أو أحد إخوته) — للاستخدام
/// بشريط تبديل الحسابات وبفلتر شاشة الإشعارات.
class AccountInfo {
  final int studentId;
  final String name;
  final bool isActive;
  final int unreadCount;
  final String? gender; // 'male'/'female' - لتلوين بطاقة الحساب بشريط تبديل الإخوة (SiblingPalette)

  const AccountInfo({
    required this.studentId,
    required this.name,
    required this.isActive,
    required this.unreadCount,
    this.gender,
  });
}

class StudentProvider extends ChangeNotifier {
  final ApiService _api;
  final AuthService _auth = AuthService();

  StudentProvider(this._api);

  Student? _student;
  List<Sibling> _siblings = [];
  List<StudentModel> _allStudents = [];
  bool _isLoading = false;
  String? _error;

  bool _isLoadingNotifications = false;

  List<AbsenceRecord> _absences = [];
  AbsenceStats _absenceStats = AbsenceStats.empty();
  bool _isLoadingAbsences = false;

  FinanceData _finance = FinanceData.empty();
  bool _isLoadingFinance = false;
  String? _financeError;

  List<HomeworkItem> _homework = [];
  bool _isLoadingHomework = false;
  String? _homeworkError;

  List<AnnouncementItem> _announcements = [];
  bool _isLoadingAnnouncements = false;
  String? _announcementsError;

  List<CalendarEvent> _calendarEvents = [];
  bool _isLoadingCalendarEvents = false;
  String? _calendarEventsError;

  List<BehaviorNote> _behaviorNotes = [];
  BehaviorNoteStats _behaviorNoteStats = BehaviorNoteStats.empty();
  bool _isLoadingBehaviorNotes = false;
  String? _behaviorNotesError;

  List<WorksheetItem> _worksheets = [];
  bool _isLoadingWorksheets = false;
  String? _worksheetsError;

  GradeReport? _gradeReport;
  bool _isLoadingGradeReport = false;
  String? _gradeReportError;
  bool _isSendingNote = false;
  int? _selectedAcademicYearId; // null = آخر/سنة حالية (السيرفر بيحددها تلقائياً)

  int _unreadMessages = 0;

  /// ==================== الحساب النشط (تبديل الإخوة) ====================
  /// null = صاحب التوكن نفسه (الحساب الأساسي). أي قيمة تانية = id تاع
  /// الأخ النشط حالياً. كل دوال الجلب (بيانات، غياب، درجات) بتمرر
  /// هالقيمة لـ ApiService عشان تجيب بيانات الحساب الصح، مش بيانات
  /// صاحب التوكن دايماً.
  int? _activeStudentId;
  int? get activeStudentId => _activeStudentId;
  bool get isSwitchedToSibling => _activeStudentId != null;

  /// id تاع صاحب التوكن الأساسي — ثابت طول الوقت (حتى لو مبدّل عأخ)،
  /// عكس activeStudentId يلي بيتغيّر. لازم لأي مكان بدو يعرف مين
  /// "الحساب الأساسي" فعلياً بغض النظر مين الحساب النشط هلق.
  int? _primaryStudentId;
  int? get primaryStudentId => _primaryStudentId;

  /// اسم كل حساب (أساسي + كل إخوته) بمكان واحد — id -> الاسم.
  Map<int, String> _accountNames = {};

  /// جنس كل حساب (أساسي + كل إخوته) بمكان واحد — id -> 'male'/'female'.
  /// تُستخدم لتلوين شريط تبديل الحسابات وبطاقات الإشعارات بلون صاحبها
  /// الفعلي (SiblingPalette) بدل حيلة طول الاسم القديمة.
  Map<int, String?> _accountGenders = {};

  Student? get student => _student;
  Student? get user => _student;
  List<Sibling> get siblings => _siblings;
  List<StudentModel> get allStudents => _allStudents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadMessages => _unreadMessages;

  bool get isLoadingNotifications => _isLoadingNotifications;

  List<AbsenceRecord> get absences => _absences;
  AbsenceStats get absenceStats => _absenceStats;
  bool get isLoadingAbsences => _isLoadingAbsences;

  FinanceData get finance => _finance;
  bool get isLoadingFinance => _isLoadingFinance;
  String? get financeError => _financeError;

  List<HomeworkItem> get homework => _homework;
  bool get isLoadingHomework => _isLoadingHomework;
  String? get homeworkError => _homeworkError;

  List<AnnouncementItem> get announcements => _announcements;
  bool get isLoadingAnnouncements => _isLoadingAnnouncements;
  String? get announcementsError => _announcementsError;

  List<CalendarEvent> get calendarEvents => _calendarEvents;
  bool get isLoadingCalendarEvents => _isLoadingCalendarEvents;
  String? get calendarEventsError => _calendarEventsError;

  List<BehaviorNote> get behaviorNotes => _behaviorNotes;
  BehaviorNoteStats get behaviorNoteStats => _behaviorNoteStats;
  bool get isLoadingBehaviorNotes => _isLoadingBehaviorNotes;
  String? get behaviorNotesError => _behaviorNotesError;

  List<WorksheetItem> get worksheets => _worksheets;
  bool get isLoadingWorksheets => _isLoadingWorksheets;
  String? get worksheetsError => _worksheetsError;

  GradeReport? get gradeReport => _gradeReport;
  bool get isLoadingGradeReport => _isLoadingGradeReport;
  String? get gradeReportError => _gradeReportError;
  bool get isSendingNote => _isSendingNote;
  int? get selectedAcademicYearId => _selectedAcademicYearId;

  /// ==================== إشعارات كل الحسابات سوا ====================
  /// مخزّنة بخريطة مفتاحها studentId (مش بس الحساب النشط حالياً)، عشان
  /// إشعارات أي أخ تضل موجودة وما تضيع/تصفر لما نبدّل الحساب النشط —
  /// هيك عدد إشعارات كل أخ بيضل ظاهر حتى وأنت واقف عحساب غيره.
  final Map<int, List<NotificationItem>> _notificationsByStudent = {};
  final Map<int, int> _unreadByStudent = {};

  /// كل إشعارات كل الحسابات مجمّعة بقائمة وحدة، الأحدث أولاً — لعرضها
  /// بشاشة الإشعارات بفلتر "الكل".
  List<NotificationItem> get notifications {
    final all = _notificationsByStudent.values.expand((e) => e).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  /// إشعارات حساب واحد بعينه (مثلاً لما المستخدم يفلتر عأخ محدد).
  List<NotificationItem> notificationsForAccount(int studentId) =>
      List.unmodifiable(_notificationsByStudent[studentId] ?? const []);

  /// إجمالي غير المقروء عبر كل الحسابات سوا — هو يلي بيظهر بجرس أعلى
  /// الشاشة وبالدرج، حتى لو في إشعارات لأخ مو واقف عحسابه هلق.
  int get unreadNotifications =>
      _unreadByStudent.values.fold(0, (sum, n) => sum + n);

  /// غير المقروء لحساب واحد بعينه.
  int unreadForAccount(int studentId) => _unreadByStudent[studentId] ?? 0;

  /// عدد الإشعارات غير المقروءة من نوع/أنواع محددة **للحساب النشط
  /// حالياً بس** — تُستخدم كعداد فوق أي بلاطة بالشاشة الرئيسية
  /// (غياب، واجبات، مالية...). بتاخد أكتر من نوع سوا لأنه أحياناً
  /// نفس الشاشة بيوصلها إشعار بأكتر من تسمية (مثلاً 'exam' و'exams').
  ///
  /// 🔧 قبل هيك كان في unreadAbsenceCount بس، مخصصة للغياب حصراً.
  /// هلق هيي مبنية فوق هاي الدالة العامة، وبقدر أي بلاطة بالشاشة
  /// الرئيسية تستخدمها بنفس الطريقة.
  int unreadCountForTypes(List<String> types) {
    final id = _activeStudentId ?? _primaryStudentId;
    if (id == null) return 0;
    return (_notificationsByStudent[id] ?? const [])
        .where((n) => types.contains(n.type) && !n.isRead)
        .length;
  }

  /// عدد إشعارات الغياب غير المقروءة **للحساب النشط حالياً بس** — تُستخدم
  /// كعداد فوق بلاطة "الغياب" بالشاشة الرئيسية.
  int get unreadAbsenceCount => unreadCountForTypes(const ['absence']);

  /// قائمة موحّدة لكل الحسابات (الأساسي + الإخوة) مع اسم كل وحدة وعدد
  /// إشعاراته غير المقروءة — تُستخدم بشريط تبديل الحسابات وبفلتر شاشة
  /// الإشعارات.
  List<AccountInfo> get accounts {
    final list = <AccountInfo>[];
    if (_primaryStudentId != null) {
      list.add(AccountInfo(
        studentId: _primaryStudentId!,
        name: _accountNames[_primaryStudentId!] ?? 'أنا',
        isActive: _activeStudentId == null,
        unreadCount: unreadForAccount(_primaryStudentId!),
        gender: _accountGenders[_primaryStudentId!],
      ));
    }
    for (final s in _siblings) {
      list.add(AccountInfo(
        studentId: s.studentId,
        name: s.studentName.isNotEmpty ? s.studentName : 'غير معروف',
        isActive: _activeStudentId == s.studentId,
        unreadCount: unreadForAccount(s.studentId),
        gender: s.gender,
      ));
    }
    return list;
  }

  Future<void> _ensureToken() async {
    final token = await _auth.getToken();
    if (token == null) throw ApiException('غير موثّق، يرجى تسجيل الدخول', code: 'NOT_AUTHENTICATED');
    _api.setToken(token);
  }

  /// جلب البيانات الأساسية (بيانات الطالب + الإخوة) — دايماً لصاحب التوكن
  /// نفسه (الحساب الأساسي)، وبترجّع الحساب النشط لصاحب التوكن.
  Future<void> fetchCoreData() async {
    _isLoading = true;
    _error = null;
    _activeStudentId = null;
    _selectedAcademicYearId = null;
    notifyListeners();

    try {
      await _ensureToken();

      final studentData = await _api.fetchStudentData();
      final siblingsData = await _api.fetchSiblings();

      _student = studentData;
      _siblings = siblingsData;
      _primaryStudentId = studentData.studentId;
      _accountNames = {
        studentData.studentId: studentData.studentName,
        for (final s in siblingsData) s.studentId: s.studentName,
      };
      _accountGenders = {
        studentData.studentId: studentData.gender,
        for (final s in siblingsData) s.studentId: s.gender,
      };
      _error = null;
    } catch (e) {
      _error = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // اسم بديل للتوافق مع الشاشات القديمة
  Future<void> fetchAllData() => fetchCoreData();

  /// جلب جميع الطلاب (شاشة القائمة العامة)
  Future<void> fetchAllStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _ensureToken();
      _allStudents = await _api.fetchAllStudents();
      _error = null;
    } catch (e) {
      _error = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ==================== تبديل الحساب النشط بين الإخوة ====================
  /// لما المستخدم يضغط عأخ من شريط "تبديل الحساب" بأعلى الـ HomeShell،
  /// بيصير هو الطالب النشط بكل شاشات التطبيق (لأن كلها بتعتمد على
  /// provider.student / provider.siblings مباشرة، وباقي الدوال هون
  /// بتمرر _activeStudentId تلقائياً لأي طلب API). حساب كل أخ منفصل
  /// كلياً عن غيره: بياناته، غيابه، درجاته، وإشعاراته (المخزّنة كل
  /// وحدة بخريطتها الخاصة) ما بتختلط ببعضها أبداً.
  ///
  /// السيرفر (get_student.php) بيتحقق من عنده كمان إنه sibling.studentId
  /// فعلاً أخ لصاحب التوكن (جدول student_siblings) قبل ما يرجع بياناته،
  /// فحتى لو التطبيق بعت id غلط، السيرفر بيرفضه.
  Future<void> switchToSibling(Sibling sibling) async {
    if (_activeStudentId == sibling.studentId) return; // نفس الحساب النشط أصلاً

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _ensureToken();
      final studentData = await _api.fetchStudentData(targetStudentId: sibling.studentId);

      _student = studentData;
      _activeStudentId = sibling.studentId;
      _error = null;

      // نفرّغ غياب/درجات/واجبات الحساب السابق حتى ما تظهر لحظياً لحساب
      // الأخ الجديد قبل ما ينعاد تحميلها فعلياً من كل شاشة. الإشعارات
      // مش منفرّغها — محفوظة أصلاً بخريطة خاصة بكل حساب، فبتضل ظاهرة
      // فوراً لهالأخ (حتى لو كانت محمّلة من قبل)، ومنحدّثها بالخلفية تحت.
      _absences = [];
      _absenceStats = AbsenceStats.empty();
      _homework = [];
      _homeworkError = null;
      _gradeReport = null;
      _selectedAcademicYearId = null;
      _behaviorNotes = [];
      _behaviorNoteStats = BehaviorNoteStats.empty();
      _behaviorNotesError = null;
      _worksheets = [];
      _worksheetsError = null;
    } catch (e) {
      _error = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // تحديث فوري (بالخلفية، بدون ما نعطّل فتح الواجهة) لإشعارات الأخ
    // يلي بدّلنا عليه، حتى تنعرض أحدث حالة إلها مباشرة.
    unawaited(fetchNotifications(studentId: sibling.studentId));
  }

  /// الرجوع لصاحب الحساب الأساسي (بعد ما كان مبدّل لأخ)
  Future<void> switchToPrimary() async {
    await fetchCoreData();
    if (_primaryStudentId != null) {
      unawaited(fetchNotifications(studentId: _primaryStudentId));
    }
  }

  /// تبديل الحساب النشط اعتماداً على id فقط (مثلاً لما نضغط إشعار تبع
  /// أخ ونحنا واقفين عحساب غيره) — بيحدد وحدو إذا لازم يرجع للأساسي
  /// أو يبدّل لأخ محدد.
  Future<void> switchToAccount(int studentId) async {
    if (studentId == _primaryStudentId) {
      if (_activeStudentId != null) await switchToPrimary();
      return;
    }
    final matches = _siblings.where((s) => s.studentId == studentId);
    if (matches.isEmpty) return;
    await switchToSibling(matches.first);
  }

  /// جلب إشعارات حساب واحد محدد بـ[studentId]، أو (لو تركناه فاضي)
  /// إشعارات **كل الحسابات سوا** (الأساسي + كل إخوته) بنفس الوقت —
  /// هيك عداد كل حساب بيضل محدّث حتى لو مو واقفين عليه.
  Future<void> fetchNotifications({int? studentId}) async {
    if (studentId == null && _primaryStudentId == null) return;

    _isLoadingNotifications = true;
    notifyListeners();

    try {
      await _ensureToken();

      final targets = studentId != null
          ? <int>{studentId}
          : <int>{
        if (_primaryStudentId != null) _primaryStudentId!,
        ..._siblings.map((s) => s.studentId),
      };

      await Future.wait(targets.map((id) async {
        try {
          // null = صاحب التوكن نفسه (الحساب الأساسي)، متل باقي دوال الـ API
          final apiTargetId = id == _primaryStudentId ? null : id;
          final result = await _api.fetchNotifications(targetStudentId: apiTargetId);
          // 🔍 مؤقت للتشخيص — اشطبه بعد ما تتأكد من القيم الحقيقية
          debugPrint('🔔 أنواع الإشعارات الخام: ${result.items.map((n) => n.type).toSet()}');
          final ownerName = _accountNames[id];
          final ownerGender = _accountGenders[id];
          _notificationsByStudent[id] = result.items
              .map((n) => n.copyWith(ownerId: id, ownerName: ownerName, ownerGender: ownerGender))
              .toList();
          _unreadByStudent[id] = result.unreadCount;
        } catch (_) {
          // ما منكسر باقي الحسابات إذا وحدة فشلت، ومنسيب بياناتها القديمة
        }
      }));
    } catch (_) {
      // فشل التوثيق مثلاً — منسيب كل شي متل ما هو
    } finally {
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  /// تعليم إشعارات حساب واحد (أو كل الحسابات لو تركناه فاضي) كمقروءة —
  /// تُستدعى لما يفتح المستخدم شاشة الإشعارات.
  Future<void> markNotificationsRead({int? studentId}) async {
    final targets = studentId != null
        ? <int>{studentId}
        : _unreadByStudent.keys.where((id) => (_unreadByStudent[id] ?? 0) > 0).toSet();

    final toMark = targets.where((id) => (_unreadByStudent[id] ?? 0) > 0);
    if (toMark.isEmpty) return;

    try {
      await _ensureToken();
      for (final id in toMark) {
        try {
          await _api.markNotificationsRead(
            targetStudentId: id == _primaryStudentId ? null : id,
          );
          _notificationsByStudent[id] = (_notificationsByStudent[id] ?? [])
              .map((n) => n.copyWith(isRead: true))
              .toList();
          _unreadByStudent[id] = 0;
        } catch (_) {}
      }
      notifyListeners();
    } catch (_) {}
  }

  /// جلب سجل الغياب للحساب النشط حالياً
  /// ⚠️ get_absences.php لسا ما انعدّل ليدعم ?student_id= (نفس تعديل
  /// get_student.php/get_notifications.php) — لحد ما ينعدّل، رح يرجع
  /// دايماً بيانات صاحب التوكن حتى لو كنت مبدّل عأخ.
  Future<void> fetchAbsences() async {
    _isLoadingAbsences = true;
    notifyListeners();

    try {
      await _ensureToken();
      final result = await _api.fetchAbsences(targetStudentId: _activeStudentId);
      _absences = result.items;
      _absenceStats = result.stats;
    } catch (e) {
      // نسيب القائمة القديمة
    } finally {
      _isLoadingAbsences = false;
      notifyListeners();
    }
  }

  /// جلب الحالة المالية (تبويبة "المالية") للحساب النشط حالياً — نفس
  /// نمط fetchAbsences بالضبط.
  Future<void> fetchFinance() async {
    _isLoadingFinance = true;
    _financeError = null;
    notifyListeners();

    try {
      await _ensureToken();
      _finance = await _api.fetchStudentFinance(targetStudentId: _activeStudentId);
    } catch (e) {
      _financeError = e is ApiException ? e.message : 'تعذر جلب الحالة المالية';
    } finally {
      _isLoadingFinance = false;
      notifyListeners();
    }
  }

  /// 🆕 جلب ملاحظات الحساب النشط حالياً (اللي أضافها المشرف عبر خاصية
  /// "الملاحظات") — نفس نمط fetchAbsences بالضبط.
  Future<void> fetchBehaviorNotes() async {
    _isLoadingBehaviorNotes = true;
    _behaviorNotesError = null;
    notifyListeners();

    try {
      await _ensureToken();
      final result = await _api.fetchBehaviorNotes(targetStudentId: _activeStudentId);
      _behaviorNotes = result.items;
      _behaviorNoteStats = result.stats;
      _behaviorNotesError = null;
    } catch (e) {
      _behaviorNotesError = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoadingBehaviorNotes = false;
      notifyListeners();
    }
  }

  /// 🆕 جلب أوراق العمل الخاصة بصف الحساب النشط حالياً (المشارَكة من
  /// قِبل الأدمن رقم 10 فقط) — نفس نمط fetchBehaviorNotes بالضبط.
  Future<void> fetchWorksheets() async {
    _isLoadingWorksheets = true;
    _worksheetsError = null;
    notifyListeners();

    try {
      await _ensureToken();
      _worksheets = await _api.fetchWorksheets(targetStudentId: _activeStudentId);
      _worksheetsError = null;
    } catch (e) {
      _worksheetsError = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoadingWorksheets = false;
      notifyListeners();
    }
  }

  /// جلب واجبات الحساب النشط حالياً (صف وشعبة هالحساب تحديداً) —
  /// نفس نمط fetchAbsences بالضبط.
  Future<void> fetchHomework() async {
    _isLoadingHomework = true;
    _homeworkError = null;
    notifyListeners();

    try {
      await _ensureToken();
      _homework = await _api.fetchHomework(targetStudentId: _activeStudentId);
      _homeworkError = null;
    } catch (e) {
      _homeworkError = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoadingHomework = false;
      notifyListeners();
    }
  }

  /// جلب إعلانات الحساب النشط حالياً (العامة + المستهدفة لصف وشعبة
  /// هالحساب) — نفس نمط fetchHomework/fetchAbsences بالضبط.
  Future<void> fetchAnnouncements() async {
    _isLoadingAnnouncements = true;
    _announcementsError = null;
    notifyListeners();

    try {
      await _ensureToken();
      _announcements = await _api.fetchAnnouncements(targetStudentId: _activeStudentId);
      _announcementsError = null;
    } catch (e) {
      _announcementsError = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoadingAnnouncements = false;
      notifyListeners();
    }
  }

  /// جلب التقويم المدرسي الرسمي — لا يعتمد على حساب معيّن (نفس التقويم
  /// لكل الطلاب)، فبعكس fetchHomework/fetchAnnouncements ما في حاجة
  /// لـ targetStudentId هون.
  Future<void> fetchCalendarEvents() async {
    _isLoadingCalendarEvents = true;
    _calendarEventsError = null;
    notifyListeners();

    try {
      await _ensureToken();
      _calendarEvents = await _api.fetchCalendarEvents();
      _calendarEventsError = null;
    } catch (e) {
      _calendarEventsError = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoadingCalendarEvents = false;
      notifyListeners();
    }
  }

  /// تبديل حالة الإعجاب بإعلان — تحديث فوري (optimistic) بالقائمة
  /// المحلية بمجرد رد السيرفر، بدون إعادة تحميل كامل قائمة الإعلانات.
  Future<void> toggleAnnouncementLike(int announcementId) async {
    try {
      await _ensureToken();
      final result = await _api.toggleAnnouncementLike(
        announcementId,
        targetStudentId: _activeStudentId,
      );
      _announcements = _announcements.map((a) {
        if (a.id != announcementId) return a;
        return a.copyWith(likeCount: result.likeCount, isLiked: result.isLiked);
      }).toList();
      notifyListeners();
    } catch (_) {
      // تفاعل غير حرج — ما منكسر الشاشة لو فشل، بس ما بيتغيّر الشكل
    }
  }

  /// جلب تعليقات إعلان معيّن (تُستخدم بالنافذة المنبثقة للتعليقات).
  Future<List<AnnouncementComment>> fetchAnnouncementComments(int announcementId) async {
    await _ensureToken();
    return _api.fetchAnnouncementComments(
      announcementId,
      targetStudentId: _activeStudentId,
    );
  }

  /// إضافة تعليق جديد على إعلان، وتحديث عدّاد التعليقات محلياً فوراً.
  Future<AnnouncementComment?> addAnnouncementComment(int announcementId, String text) async {
    try {
      await _ensureToken();
      final newComment = await _api.addAnnouncementComment(
        announcementId,
        text,
        targetStudentId: _activeStudentId,
      );
      _announcements = _announcements.map((a) {
        if (a.id != announcementId) return a;
        return a.copyWith(commentCount: a.commentCount + 1);
      }).toList();
      notifyListeners();
      return newComment;
    } catch (e) {
      return null;
    }
  }

  /// جلب البرنامج الأسبوعي للحساب النشط حالياً.
  /// 🔧 قبل هيك كانت WeeklyScheduleScreen بتحكي مباشرة مع ApiService
  /// (context.read<ApiService>().fetchWeeklySchedule(...))، وهاد كان
  /// بيتخطى _ensureToken() تماماً — يعني ما في ضمان إن _authToken
  /// بـApiService معبّى وقت الطلب. هلق الشاشة بتمر من هون متل باقي
  /// الشاشات، فـ _ensureToken() منضمن دايماً قبل الطلب.
  Future<WeeklySchedule> fetchWeeklySchedule() async {
    await _ensureToken();
    return _api.fetchWeeklySchedule(targetStudentId: _activeStudentId);
  }

  /// جلب تقرير الدرجات الكامل للحساب النشط حالياً (المواد + الترتيب + المحادثة مع الإدارة)
  /// [academicYearId]: لو محدد، بيجيب تقرير هالسنة بدل آخر سنة محفوظة بـ _selectedAcademicYearId.
  Future<void> fetchGradeReport({bool silent = false, int? academicYearId}) async {
    if (!silent) {
      _isLoadingGradeReport = true;
      _gradeReportError = null;
      notifyListeners();
    }

    try {
      await _ensureToken();
      final yearToUse = academicYearId ?? _selectedAcademicYearId;
      _gradeReport = await _api.fetchGradeReport(
        targetStudentId: _activeStudentId,
        academicYearId: yearToUse,
      );
      _selectedAcademicYearId = _gradeReport!.selectedAcademicYearId;
      _gradeReportError = null;
    } catch (e) {
      _gradeReportError = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoadingGradeReport = false;
      notifyListeners();
    }
  }

  /// تبديل السنة الدراسية المعروضة بشاشة الدرجات (مثلاً "السنة الماضية")
  Future<void> changeGradeReportYear(int academicYearId) async {
    if (_selectedAcademicYearId == academicYearId) return;
    await fetchGradeReport(academicYearId: academicYearId);
  }

  /// إرسال ملاحظة لإدارة المدرسة من شاشة الدرجات (باسم الحساب النشط حالياً)،
  /// وإعادة تحميل المحادثة بعد الإرسال
  Future<bool> sendParentNote(String note) async {
    if (note.trim().isEmpty) return false;

    _isSendingNote = true;
    notifyListeners();

    try {
      await _ensureToken();
      await _api.sendParentNote(note.trim(), targetStudentId: _activeStudentId);
      // نعيد تحميل التقرير بصمت عشان تظهر الملاحظة الجديدة بالمحادثة فوراً
      await fetchGradeReport(silent: true);
      return true;
    } catch (e) {
      _gradeReportError = e is ApiException ? e.message : e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSendingNote = false;
      notifyListeners();
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    await _auth.deleteToken();
    _api.clearToken();
    _student = null;
    _siblings = [];
    _allStudents = [];
    _activeStudentId = null;
    _primaryStudentId = null;
    _accountNames = {};
    _accountGenders = {};
    _notificationsByStudent.clear();
    _unreadByStudent.clear();
    _absences = [];
    _absenceStats = AbsenceStats.empty();
    _finance = FinanceData.empty();
    _financeError = null;
    _homework = [];
    _homeworkError = null;
    _announcements = [];
    _announcementsError = null;
    _calendarEvents = [];
    _calendarEventsError = null;
    _behaviorNotes = [];
    _behaviorNoteStats = BehaviorNoteStats.empty();
    _behaviorNotesError = null;
    _worksheets = [];
    _worksheetsError = null;
    _gradeReport = null;
    _selectedAcademicYearId = null;
    _unreadMessages = 0;
    notifyListeners();
  }
}