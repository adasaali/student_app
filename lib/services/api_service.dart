import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
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

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => 'ApiException: $message (Code: $code, Status: $statusCode)';
}

class ApiService {
  static const String baseUrl = 'https://student.academy-school.com/api/';
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 2;

  // ملاحظة هامة: كان هذا الملف يستخدم HttpClient/IOClient من dart:io،
  // وهذه المكتبة غير متوفرة إطلاقاً على Flutter Web (لن يُصرّف المشروع
  // أساساً إذا شُغّل على المتصفح). استبدلناه بـ http.Client() العادي الذي
  // يعمل على كل المنصات (أندرويد/iOS/ويب/ديسكتوب) دون أي تعديل إضافي.
  final http.Client _client = http.Client();
  String? _authToken;

  void setToken(String token) => _authToken = token;
  void clearToken() => _authToken = null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  dynamic _handleResponse(http.Response response) {
    developer.log('Response [${response.statusCode}]: ${response.body}', name: 'ApiService');

    final body = _safeDecode(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return body;
      case 400:
        throw ApiException(
          (body is Map ? body['message'] : null) ?? 'طلب غير صالح',
          statusCode: 400,
          code: 'BAD_REQUEST',
        );
      case 401:
        throw ApiException(
          'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى',
          statusCode: 401,
          code: 'UNAUTHORIZED',
        );
      case 429:
        throw ApiException(
          'محاولات كثيرة، يرجى الانتظار',
          statusCode: 429,
          code: 'RATE_LIMITED',
        );
      case 500:
      case 502:
      case 503:
        throw ApiException(
          (body is Map ? body['message'] : null) ?? 'تعذر الاتصال بالخادم، حاول مرة أخرى',
          statusCode: response.statusCode,
          code: 'SERVER_ERROR',
        );
      default:
        throw ApiException(
          (body is Map ? body['message'] : null) ?? 'حدث خطأ غير متوقع',
          statusCode: response.statusCode,
          code: 'UNKNOWN_ERROR',
        );
    }
  }

  dynamic _safeDecode(String body) {
    try {
      if (body.trim().isEmpty) return null;
      return jsonDecode(body);
    } catch (e) {
      developer.log('JSON decode error: $e', name: 'ApiService');
      return null;
    }
  }

  Future<http.Response> _requestWithRetry(
      Future<http.Response> Function() request, {
        int retries = 0,
      }) async {
    try {
      developer.log('Request attempt ${retries + 1}', name: 'ApiService');
      final response = await request().timeout(_timeout);
      return response;
    } on TimeoutException {
      developer.log('Timeout', name: 'ApiService');
      if (retries < _maxRetries) {
        return _requestWithRetry(request, retries: retries + 1);
      }
      throw ApiException('انتهى وقت الانتظار، حاول مرة أخرى', code: 'TIMEOUT');
    } on FormatException catch (e) {
      developer.log('Format error: $e', name: 'ApiService');
      throw ApiException('رد غير متوقع من الخادم', code: 'INVALID_RESPONSE');
    } catch (e) {
      // يغطي SocketException / HandshakeException / أي خطأ اتصال آخر
      // (dart:io غير متاح على الويب لذا لا يمكن التعامل معها بأنواعها الصريحة هنا)
      developer.log('Connection error: $e', name: 'ApiService');
      if (retries < _maxRetries) {
        await Future.delayed(Duration(seconds: 1 * (retries + 1)));
        return _requestWithRetry(request, retries: retries + 1);
      }
      throw ApiException('لا يوجد اتصال بالإنترنت أو الخادم غير متاح', code: 'NO_CONNECTION');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _requestWithRetry(() => _client.post(
      Uri.parse('${baseUrl}api_login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
      }),
    ));

    final data = _handleResponse(response);

    if (data is! Map || data['status'] != 'success') {
      throw ApiException(
        (data is Map ? data['message'] : null) ?? 'فشل تسجيل الدخول',
        code: 'LOGIN_FAILED',
      );
    }

    if (data['token'] != null) {
      setToken(data['token']);
    }

    return data.cast<String, dynamic>();
  }

  /// [targetStudentId]: لو محدد (بعد تبديل الحساب لأخ)، بيجيب بيانات هالأخ
  /// بدل بيانات صاحب التوكن. السيرفر بيتحقق إنه فعلاً أخ قبل ما يرجع بياناته.
  Future<Student> fetchStudentData({int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_student.php').replace(
      queryParameters: targetStudentId != null ? {'student_id': '$targetStudentId'} : null,
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    final data = body is Map && body['status'] == 'success' ? body['data'] : body;

    if (data is! Map) {
      throw ApiException('بيانات الطالب غير صالحة', code: 'INVALID_DATA');
    }

    return Student.fromJson(data.cast<String, dynamic>());
  }

  Future<List<Sibling>> fetchSiblings() async {
    _ensureAuthenticated();

    final response = await _requestWithRetry(() => _client.get(
      Uri.parse('${baseUrl}siblings.php'),
      headers: _headers,
    ));

    final body = _handleResponse(response);

    // بعض الـ APIs تُرجع القائمة مباشرة، وبعضها يغلفها بـ {status, data}
    final list = body is List ? body : (body is Map ? body['data'] : null);

    if (list is! List) {
      throw ApiException('بيانات الإخوة غير صالحة', code: 'INVALID_DATA');
    }

    return list.map((e) => Sibling.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<List<StudentModel>> fetchAllStudents() async {
    _ensureAuthenticated();

    final response = await _requestWithRetry(() => _client.get(
      Uri.parse('${baseUrl}students.php'),
      headers: _headers,
    ));

    final body = _handleResponse(response);

    final list = body is List ? body : (body is Map ? body['data'] : null);

    if (list is! List) {
      throw ApiException('قائمة الطلاب غير صالحة', code: 'INVALID_DATA');
    }

    return list.map((e) => StudentModel.fromJson((e as Map).cast<String, dynamic>())).toList();
  }


  // ─────────────────────────────────────────────────────────
  // الشات (MySQL) — بديل نظام الشات القديم المبني على Firestore.
  // كل شي هلق endpoint واحد بيسجّل الرسالة ويبعث الـ push بنفس
  // الوقت، فما عاد في داعي لنداء notifyChatMessage منفصل بعد الإرسال.
  // ─────────────────────────────────────────────────────────

  /// يجيب محادثتي الطالب (الجماعية + الخاصة مع مشرفه)، وينشئهم أول
  /// مرة لو ما كانوا موجودين بعد.
  /// [targetStudentId]: لو محدد (بعد تبديل الحساب لأخ)، بيجيب محادثات
  /// هالأخ بدل محادثات صاحب التوكن — نفس نمط fetchAbsences/fetchHomework.
  /// ⚠️ يتطلب إن get_chat_conversations.php يدعم ?student_id= ويتحقق إنه
  /// فعلاً أخ لصاحب التوكن (جدول student_siblings) قبل ما يرجع بياناته.
  Future<List<Map<String, dynamic>>> fetchChatConversations({int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_chat_conversations.php').replace(
      queryParameters: targetStudentId != null ? {'student_id': '$targetStudentId'} : null,
    );

    final response = await _requestWithRetry(() => _client.get(uri, headers: _headers));

    final body = _handleResponse(response);
    final list = body is Map ? body['data'] : null;
    if (list is! List) {
      throw ApiException('بيانات المحادثات غير صالحة', code: 'INVALID_DATA');
    }
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  /// [targetStudentId]: لازم نمرره كمان هون (مش بس بجلب لائحة المحادثات)
  /// لأنه السيرفر حالياً بيتحقق إنه صاحب التوكن نفسه صاحب المحادثة —
  /// من دون هالباراميتر رح يرفض فتح محادثة أخ حتى لو الـ id صحيح.
  Future<List<Map<String, dynamic>>> fetchChatMessages(int conversationId, {int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_chat_messages.php').replace(
      queryParameters: {
        'conversation_id': '$conversationId',
        if (targetStudentId != null) 'student_id': '$targetStudentId',
      },
    );

    final response = await _requestWithRetry(() => _client.get(uri, headers: _headers));

    final body = _handleResponse(response);
    final list = body is Map ? body['data'] : null;
    if (list is! List) {
      throw ApiException('بيانات الرسائل غير صالحة', code: 'INVALID_DATA');
    }
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<void> sendChatMessage({
    required int conversationId,
    required String text,
    int? targetStudentId,
  }) async {
    _ensureAuthenticated();

    final response = await _requestWithRetry(() => _client.post(
          Uri.parse('${baseUrl}send_chat_message.php'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'conversation_id': conversationId,
            'text': text,
            if (targetStudentId != null) 'student_id': targetStudentId,
          }),
        ));

    final body = _handleResponse(response);
    if (body is! Map || body['status'] != 'success') {
      throw ApiException(
        (body is Map ? body['message'] : null) ?? 'تعذّر إرسال الرسالة',
        code: 'SEND_MESSAGE_FAILED',
      );
    }
  }

  Future<void> markChatRead(int conversationId, {int? targetStudentId}) async {
    _ensureAuthenticated();

    await _requestWithRetry(() => _client.post(
          Uri.parse('${baseUrl}mark_chat_read.php'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'conversation_id': conversationId,
            if (targetStudentId != null) 'student_id': targetStudentId,
          }),
        ));
  }

  Future<void> registerFcmToken(String fcmToken, String platform) async {
    _ensureAuthenticated();

    final response = await _requestWithRetry(() => _client.post(
      Uri.parse('${baseUrl}register_fcm_token.php'),
      headers: _headers,
      body: jsonEncode({
        'fcm_token': fcmToken,
        'platform': platform,
      }),
    ));

    // لا نكسر تسجيل الدخول لو فشل تسجيل التوكن، بس نسجل الخطأ فقط
    try {
      _handleResponse(response);
    } catch (e) {
      developer.log('FCM token registration failed: $e', name: 'ApiService');
    }
  }

  Future<({List<NotificationItem> items, int unreadCount})> fetchNotifications({int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_notifications.php').replace(
      queryParameters: targetStudentId != null ? {'student_id': '$targetStudentId'} : null,
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success') {
      throw ApiException('تعذر جلب الإشعارات', code: 'INVALID_DATA');
    }

    final list = (body['data'] as List? ?? [])
        .map((e) => NotificationItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final unreadCount = body['unread_count'] is int
        ? body['unread_count'] as int
        : int.tryParse('${body['unread_count']}') ?? 0;

    return (items: list, unreadCount: unreadCount);
  }

  /// [targetStudentId]: لتعليم إشعارات حساب أخ محدد كمقروءة بعد تبديل
  /// الحساب. ⚠️ mark_notifications_read.php لسا ما انعدّل ليدعم student_id
  /// (نفس ملاحظة get_absences.php/get_weekly_schedule.php) — لحد ما ينعدّل
  /// رح يتجاهل السيرفر هالحقل ويعلّم دايماً إشعارات صاحب التوكن الأساسي.
  Future<void> markNotificationsRead({int? notificationId, int? targetStudentId}) async {
    _ensureAuthenticated();

    await _requestWithRetry(() => _client.post(
      Uri.parse('${baseUrl}mark_notifications_read.php'),
      headers: _headers,
      body: jsonEncode({
        if (notificationId != null) 'notification_id': notificationId,
        if (targetStudentId != null) 'student_id': targetStudentId,
      }),
    ));
  }

  /// [targetStudentId]: لو محدد (بعد تبديل الحساب لأخ)، بيجيب غياب هالأخ
  /// بدل غياب صاحب التوكن. السيرفر بيتحقق إنه فعلاً أخ (عبر
  /// sibling_group_members) قبل ما يرجع بياناته — مدعوم فعلياً بالسيرفر.
  Future<({List<AbsenceRecord> items, AbsenceStats stats})> fetchAbsences({int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_absences.php').replace(
      queryParameters: targetStudentId != null ? {'student_id': '$targetStudentId'} : null,
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success') {
      throw ApiException('تعذر جلب سجل الغياب', code: 'INVALID_DATA');
    }

    final list = (body['data'] as List? ?? [])
        .map((e) => AbsenceRecord.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final stats = body['stats'] is Map
        ? AbsenceStats.fromJson((body['stats'] as Map).cast<String, dynamic>())
        : AbsenceStats.empty();

    return (items: list, stats: stats);
  }

  /// 🆕 [targetStudentId]: لو محدد (بعد تبديل الحساب لأخ)، بيجيب
  /// ملاحظات هالأخ (اللي أضافها المشرف عبر خاصية "الملاحظات") بدل
  /// ملاحظات صاحب التوكن — نفس نمط fetchAbsences بالضبط.
  Future<({List<BehaviorNote> items, BehaviorNoteStats stats})> fetchBehaviorNotes({int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_student_notes.php').replace(
      queryParameters: targetStudentId != null ? {'student_id': '$targetStudentId'} : null,
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success') {
      throw ApiException('تعذر جلب الملاحظات', code: 'INVALID_DATA');
    }

    final list = (body['data'] as List? ?? [])
        .map((e) => BehaviorNote.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final stats = body['stats'] is Map
        ? BehaviorNoteStats.fromJson((body['stats'] as Map).cast<String, dynamic>())
        : BehaviorNoteStats.empty();

    return (items: list, stats: stats);
  }

  /// 🆕 [targetStudentId]: لو محدد (بعد تبديل الحساب لأخ)، بيجيب أوراق
  /// عمل صف هالأخ بدل صف صاحب التوكن — نفس نمط fetchBehaviorNotes
  /// بالضبط. أوراق العمل هون مشارَكة فقط من قِبل الأدمن رقم 10 (يتحقق
  /// منها السيرفر بلوحة الإضافة نفسها، مش هون).
  Future<List<WorksheetItem>> fetchWorksheets({int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_worksheets.php').replace(
      queryParameters: targetStudentId != null ? {'student_id': '$targetStudentId'} : null,
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success') {
      throw ApiException('تعذر جلب أوراق العمل', code: 'INVALID_DATA');
    }

    return (body['data'] as List? ?? [])
        .map((e) => WorksheetItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// [targetStudentId]: لو محدد (بعد تبديل الحساب لأخ)، بيجيب واجبات
  /// صف وشعبة هالأخ بدل صف وشعبة صاحب التوكن. السيرفر بيتحقق إنه
  /// فعلاً أخ (عبر sibling_group_members) قبل ما يرجع بياناته — نفس
  /// نمط fetchAbsences بالضبط.
  Future<List<HomeworkItem>> fetchHomework({int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_homework.php').replace(
      queryParameters: targetStudentId != null ? {'student_id': '$targetStudentId'} : null,
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success') {
      throw ApiException('تعذر جلب الواجبات', code: 'INVALID_DATA');
    }

    final list = (body['data'] as List? ?? [])
        .map((e) => HomeworkItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return list;
  }

  /// [targetStudentId]: لو محدد (بعد تبديل الحساب لأخ)، بيجيب إعلانات
  /// صف وشعبة هالأخ (بالإضافة للإعلانات العامة) بدل صف وشعبة صاحب
  /// التوكن. السيرفر بيتحقق إنه فعلاً أخ (عبر sibling_group_members)
  /// قبل ما يرجع بياناته — نفس نمط fetchHomework/fetchAbsences بالضبط.
  Future<List<AnnouncementItem>> fetchAnnouncements({int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_announcements.php').replace(
      queryParameters: targetStudentId != null ? {'student_id': '$targetStudentId'} : null,
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success') {
      throw ApiException('تعذر جلب الإعلانات', code: 'INVALID_DATA');
    }

    final list = (body['data'] as List? ?? [])
        .map((e) => AnnouncementItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return list;
  }

  /// جلب التقويم المدرسي الرسمي (بدء الدوام، الامتحانات، العطل...) —
  /// يديره الأدمن من admin/calendar/school_calendar.php. لا يعتمد على
  /// طالب معيّن، فما في حاجة لـ targetStudentId هون.
  Future<List<CalendarEvent>> fetchCalendarEvents() async {
    _ensureAuthenticated();

    final response = await _requestWithRetry(() => _client.get(
      Uri.parse('${baseUrl}get_calendar_events.php'),
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success') {
      throw ApiException(
        (body is Map ? body['message'] : null) ?? 'تعذر جلب التقويم المدرسي',
        code: 'INVALID_DATA',
      );
    }

    return (body['data'] as List? ?? [])
        .map((e) => CalendarEvent.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// تبديل حالة الإعجاب بإعلان (إعجاب/إلغاء إعجاب) — السيرفر بيقرر
  /// الحالة الجديدة تلقائياً حسب الحالة الحالية، وبيرجّع العدّاد
  /// المحدّث فوراً.
  Future<({int likeCount, bool isLiked})> toggleAnnouncementLike(
      int announcementId, {
        int? targetStudentId,
      }) async {
    _ensureAuthenticated();

    final response = await _requestWithRetry(() => _client.post(
      Uri.parse('${baseUrl}toggle_announcement_like.php'),
      headers: _headers,
      body: jsonEncode({
        'announcement_id': announcementId,
        if (targetStudentId != null) 'student_id': targetStudentId,
      }),
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success') {
      throw ApiException(
        (body is Map ? body['message'] : null) ?? 'تعذر تسجيل الإعجاب',
        code: 'LIKE_FAILED',
      );
    }

    final likeCount = body['like_count'] is int
        ? body['like_count'] as int
        : int.tryParse('${body['like_count']}') ?? 0;
    final isLiked = body['is_liked'] == true;

    return (likeCount: likeCount, isLiked: isLiked);
  }

  /// جلب تعليقات إعلان معيّن، الأقدم أولاً.
  Future<List<AnnouncementComment>> fetchAnnouncementComments(
      int announcementId, {
        int? targetStudentId,
      }) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_announcement_comments.php').replace(
      queryParameters: {
        'announcement_id': '$announcementId',
        if (targetStudentId != null) 'student_id': '$targetStudentId',
      },
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success') {
      throw ApiException('تعذر جلب التعليقات', code: 'INVALID_DATA');
    }

    return (body['data'] as List? ?? [])
        .map((e) => AnnouncementComment.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// إضافة تعليق جديد على إعلان — بيرجّع التعليق المضاف فوراً (بدون
  /// حاجة لإعادة تحميل كامل القائمة).
  Future<AnnouncementComment> addAnnouncementComment(
      int announcementId,
      String comment, {
        int? targetStudentId,
      }) async {
    _ensureAuthenticated();

    final response = await _requestWithRetry(() => _client.post(
      Uri.parse('${baseUrl}add_announcement_comment.php'),
      headers: _headers,
      body: jsonEncode({
        'announcement_id': announcementId,
        'comment': comment,
        if (targetStudentId != null) 'student_id': targetStudentId,
      }),
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success' || body['comment'] is! Map) {
      throw ApiException(
        (body is Map ? body['message'] : null) ?? 'تعذر إضافة التعليق',
        code: 'COMMENT_FAILED',
      );
    }

    return AnnouncementComment.fromJson((body['comment'] as Map).cast<String, dynamic>());
  }

  /// جلب البرنامج الأسبوعي للحساب النشط حالياً (صاحب التوكن أو الأخ
  /// المبدّل عليه). [targetStudentId]: مدعوم فعلياً بالسيرفر عبر
  /// sibling_group_members، نفس get_student.php/get_absences.php.
  Future<WeeklySchedule> fetchWeeklySchedule({int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_weekly_schedule.php').replace(
      queryParameters: targetStudentId != null ? {'student_id': '$targetStudentId'} : null,
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success' || body['data'] is! Map) {
      throw ApiException(
        (body is Map ? body['message'] : null) ?? 'تعذر جلب البرنامج الأسبوعي',
        code: 'INVALID_DATA',
      );
    }

    return WeeklySchedule.fromJson((body['data'] as Map).cast<String, dynamic>());
  }

  /// [targetStudentId]: لو محدد (بعد تبديل الحساب لأخ)، بيجيب تقرير هالأخ.
  /// [academicYearId]: لو محدد، بيجيب تقرير سنة دراسية سابقة بدل السنة الحالية.
  Future<GradeReport> fetchGradeReport({int? targetStudentId, int? academicYearId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_grade_report.php').replace(
      queryParameters: {
        if (targetStudentId != null) 'student_id': '$targetStudentId',
        if (academicYearId != null) 'academic_year_id': '$academicYearId',
      },
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success' || body['data'] is! Map) {
      throw ApiException(
        (body is Map ? body['message'] : null) ?? 'تعذر جلب تقرير الدرجات',
        code: 'INVALID_DATA',
      );
    }

    return GradeReport.fromJson((body['data'] as Map).cast<String, dynamic>());
  }

  /// جلب الحالة المالية للطالب (تبويبة "المالية"): الأقساط والخدمات،
  /// النقل، سجل الدفعات، السلفة، والمبلغ المتبقي — من get_student_finance.php
  /// (نفس نمط target_id/sibling الموجود بباقي endpoints).
  Future<FinanceData> fetchStudentFinance({int? targetStudentId}) async {
    _ensureAuthenticated();

    final uri = Uri.parse('${baseUrl}get_student_finance.php').replace(
      queryParameters: targetStudentId != null ? {'student_id': '$targetStudentId'} : null,
    );

    final response = await _requestWithRetry(() => _client.get(
      uri,
      headers: _headers,
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success' || body['data'] is! Map) {
      throw ApiException(
        (body is Map ? body['message'] : null) ?? 'تعذر جلب الحالة المالية',
        code: 'INVALID_DATA',
      );
    }

    return FinanceData.fromJson((body['data'] as Map).cast<String, dynamic>());
  }

  /// إرسال ملاحظة لولي الأمر إلى إدارة المدرسة (تظهر بمحادثة شاشة الدرجات)
  /// [targetStudentId]: لو محدد، الملاحظة بتترسل باسم هالأخ (بعد تبديل الحساب).
  Future<void> sendParentNote(String note, {int? targetStudentId}) async {
    _ensureAuthenticated();

    final response = await _requestWithRetry(() => _client.post(
      Uri.parse('${baseUrl}add_parent_note.php'),
      headers: _headers,
      body: jsonEncode({
        'note': note,
        if (targetStudentId != null) 'target_student_id': targetStudentId,
      }),
    ));

    final body = _handleResponse(response);

    if (body is! Map || body['status'] != 'success') {
      throw ApiException(
        (body is Map ? body['message'] : null) ?? 'تعذر إرسال الملاحظة',
        code: 'SEND_NOTE_FAILED',
      );
    }
  }

  void _ensureAuthenticated() {
    if (_authToken == null) {
      throw ApiException('يجب تسجيل الدخول أولاً', code: 'NOT_AUTHENTICATED');
    }
  }

  void dispose() => _client.close();
}