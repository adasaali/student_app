import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/student_provider.dart';
import 'api_service.dart';

/// خدمة الإشعارات الفورية (Push Notifications عبر Firebase Cloud Messaging).
///
/// الفرق بين هاد وبين `ApiService.registerFcmToken` القديمة: هاي الدالة
/// كانت موجودة بس ما كان حدا يستدعيها فعلياً، وما كان في أي مستمع
/// (listener) لرسائل FCM أصلاً — يعني حتى لو وصل push، التطبيق ما كان
/// يعرف عنه لحد ما المستخدم يعمل refresh يدوي (سحب لتحديث أو دخول
/// وخروج من شاشة الإشعارات).
///
/// هاد الملف بيضيف الجزء الناقص:
/// 1) يطلب صلاحية الإشعارات ويسجّل توكن الجهاز (ويعيد التسجيل لو
///    التوكن تجدد — FCM tokens بتتغيّر أحياناً).
/// 2) يستمع لثلاث حالات:
///    - `onMessage`: التطبيق مفتوح بالمقدمة → لازم نعرض الإشعار يدوياً
///      عبر flutter_local_notifications (FCM ما بيعرضه تلقائياً بهالحالة).
///    - `onMessageOpenedApp`: المستخدم ضغط على الإشعار والتطبيق كان
///      بالخلفية.
///    - `getInitialMessage`: التطبيق كان مقفول تماماً وانفتح بسبب
///      ضغطة على إشعار.
/// 3) بكل الحالات الثلاث (ما عدا الحالة العادية الرابعة "التطبيق
///    بالخلفية بدون ما يفتح") بينفّذ [onNotificationReceived] يلي
///    بيمررها المستدعي — هاي بتكون عادة StudentProvider.fetchNotifications()
///    يلي بتعمل notifyListeners() فتتحدث شارة الجرس فوراً بدون أي
///    تدخل يدوي من المستخدم.
class NotificationService {
  final ApiService _api;
  final FlutterLocalNotificationsPlugin _localPlugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'high_importance_channel';
  static const _channelName = 'إشعارات بوابة الطالب';
  static const _channelDescription = 'إشعارات فورية من إدارة المدرسة (واجبات، غياب، درجات...)';

  bool _initialized = false;

  NotificationService(this._api);

  /// [studentProvider]: نفس النسخة المشتركة عبر Provider (ChangeNotifierProvider
  /// بـ main.dart) — منستدعي عليها fetchNotifications() مباشرة بدل ما
  /// نعتمد على callback مربوط بحالة widget معيّن.
  ///
  /// ⚠️ قبل هيك كان في callback (onNotificationReceived) بيتفحّص `mounted`
  /// تبع الشاشة يلي استدعت init() — وبما إنه أول استدعاء فعلي كان من
  /// LoginScreen (بسبب حماية _initialized يلي بتمنع التسجيل مرتين)، وLoginScreen
  /// بتنكسر (dispose) فوراً بعد الانتقال لـHomeShell، صار `mounted` = false
  /// دايماً من أول ثانية، فـfetchNotifications() ما كانت تنفّذ إطلاقاً —
  /// والعداد ما كان يتحدث إلا بإعادة فتح التطبيق من الصفر (initState
  /// جديد). StudentProvider نفسه ما بينكسر أبداً طول الجلسة، فمرجعه
  /// المباشر هون آمن 100% بعكس أي widget State.
  Future<void> init({required StudentProvider studentProvider}) async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;

    // طلب الصلاحية — على أندرويد 13+ وiOS هاد بيطلع نافذة نظام فعلية.
    // لو المستخدم رفض، منكمل بالتسجيل عادي (ممكن يشتغل لاحقاً لو غيّر
    // رأيه من إعدادات الجهاز) بدل ما نكسر بقية التطبيق.
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // على iOS، لازم هاد الإعداد الإضافي عشان الإشعار يبين كنافذة
    // منبثقة والتطبيق مفتوح بالمقدمة (وإلا FCM بيتجاهله بصمت).
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // تسجيل التوكن الحالي + إعادة التسجيل تلقائياً لو FCM جدّده مستقبلاً.
    final token = await messaging.getToken();
    if (token != null) unawaited(_registerToken(token));
    messaging.onTokenRefresh.listen(_registerToken);

    // 1) التطبيق مفتوح بالمقدمة وقت وصول الإشعار
    FirebaseMessaging.onMessage.listen((message) async {
      await _showLocalNotification(message);
      studentProvider.fetchNotifications();
    });

    // 2) المستخدم ضغط على الإشعار والتطبيق كان بالخلفية (مو مقفول)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      studentProvider.fetchNotifications();
    });

    // 3) التطبيق كان مقفول تماماً وانفتح بسبب ضغطة على إشعار
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      studentProvider.fetchNotifications();
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      await _api.registerFcmToken(token, platform);
    } catch (e) {
      // ما منكسر تسجيل الدخول أو أي شي تاني لو تسجيل التوكن فشل —
      // نفس فلسفة registerFcmToken الأصلية بـApiService.
      debugPrint('FCM token registration failed: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // منطلبها إحنا بعدين عبر FirebaseMessaging.requestPermission
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localPlugin.initialize(settings: initSettings);

    // قناة أندرويد بأهمية عالية — لازمة عشان الإشعار يبين كنافذة
    // منبثقة (heads-up) مش بس يدخل شريط الإشعارات بصمت.
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _localPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return; // رسالة بيانات فقط (data-only)، بلا عنوان/نص لعرضه

    await _localPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }
}

/// مساعد صغير عشان نستدعي Future بدون await بشكل واضح ومقصود
/// (بدل ما ننسى الـ await ويظن حدا إنه سهو).
void unawaited(Future<void> future) {}