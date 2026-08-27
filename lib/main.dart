import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/student_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';
import 'widgets/app_startup_screen.dart';
import 'widgets/no_connection_screen.dart';

/// معالج رسائل FCM بالخلفية (والتطبيق مقفول تماماً أو بالخلفية).
/// ⚠️ لازم تكون top-level function (مش داخل صنف) و@pragma('vm:entry-point')
/// لأنها بتشتغل بـisolate منفصل عن باقي التطبيق. أغلب رسائل الإشعارات
/// العادية (notification + data) بيعرضها نظام التشغيل تلقائياً بهالحالة
/// بدون أي كود إضافي منا؛ هاد المعالج بيصير ضروري بس لو بدنا نعالج
/// رسائل بيانات فقط (data-only) بالخلفية أو نعمل شي إضافي وقت وصولها.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // كل isolate منفصل لازم يهيّئ Firebase لحاله من الصفر.
  await Firebase.initializeApp();
}

/// Future مشتركة لتهيئة Firebase — أي كود تاني بالتطبيق (متل
/// NotificationService) لازم ينتظرها قبل ما يستخدم أي Firebase API،
/// عشان نضمن ترتيب صحيح حتى إنه صار التشغيل غير متزامن (async) هلق.
/// مثال الاستخدام: `await firebaseReadyFuture;` قبل أي نداء FCM.
late final Future<void> firebaseReadyFuture;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 تسريع بدء التشغيل: قبل هيك كنا منستنى Firebase.initializeApp()
  // (عملية شبكة/IO) قبل ما نطلق runApp() أصلاً — يعني المستخدم كان يشوف
  // شاشة سودا/فاضية لحد ما تخلص، وهاد أكبر سبب للبطء المحسوس بالفتح.
  // هلق منطلق الواجهة فوراً، وFirebase عم يتهيّأ بالخلفية بالتوازي.
  // ⚠️ مهم: أي كود بيستخدم Firebase (متل NotificationService) لازم
  // ينتظر firebaseReadyFuture قبل أول استخدام إله، وإلا ممكن يرجع نفس
  // خطأ "[core/no-app]" يلي كان قبل.
  firebaseReadyFuture = Firebase.initializeApp();

  // 🔔 تسجيل معالج الخلفية. ما لازم ننتظر firebaseReadyFuture هون —
  // onBackgroundMessage بس بتسجّل مرجع الدالة، والدالة نفسها بتهيّئ
  // Firebase من جديد جوا الـisolate المنفصل تبعها وقت ما تنفّذ فعلياً.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    // نسخة واحدة مشتركة من ApiService (مش singleton بحد ذاتها، فلازم
    // ننشئها مرة واحدة هون ونمررها لكل مكان محتاجها). لو كل شاشة صنعت
    // ApiService() لحالها، كانت كل وحدة رح يكون عندها _authToken منفصل
    // (فاضي)، فأي شاشة غير StudentProvider كانت رح تفشل بـ
    // NOT_AUTHENTICATED حتى لو المستخدم مسجّل دخول فعلياً.
    final apiService = ApiService();
    final notificationService = NotificationService(apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => StudentProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'بوابة الطالب',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // 🛡️ تثبيت حجم الخط ضمن مجال آمن (0.9x - 1.15x) على مستوى التطبيق
        // كامل. هاد بيمنع "bottom overflowed by X pixels" اللي بيصير على
        // أجهزة/إعدادات نظام فيها "حجم خط كبير" (Accessibility) وبتكبّر كل
        // النصوص أكتر من المساحات الثابتة (زي الشريط السفلي) المصممة عليها
        // — وهو السبب الأشيع لهيك overflow اللي بيختلف من جهاز لجهاز بدون
        // أي تغيير بالكود نفسه.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15),
            ),
            child: child!,
          );
        },
        home: const StartupGate(),
      ),
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  // 🔧 قبل هيك كان _checked بس بيتحقق من تسجيل الدخول (auto-login) وبعدها
  // بيفتح HomeShell فوراً — وHomeShell كانت هي يلي بتجيب بيانات الطالب
  // والإشعارات بالخلفية (initState)، فالمستخدم كان يشوف الواجهة وهي لسا
  // فاضية/سكيلتون لثانية أو تنتين. هلق الشاشة هاي نفسها بتستنى فعلياً:
  // 1) التحقق من تسجيل الدخول
  // 2) بيانات الطالب + قائمة الإخوة (fetchCoreData)
  // 3) إشعارات كل الإخوة سوا (fetchNotifications بدون studentId — نفس
  //    الدالة يلي بتجيب لكل الحسابات مرة وحدة، شوف تعليقها بـ
  //    StudentProvider)
  // 4) تسجيل الإشعارات الفورية (NotificationService.init)
  // وبس لما الكل ينجح، بتفتح واجهة HomeShell — مش قبل.
  _StartupPhase _phase = _StartupPhase.checkingAuth;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _phase = _StartupPhase.checkingAuth;
      _errorMessage = null;
    });

    final auth = context.read<AuthService>();
    await auth.tryAutoLogin();

    if (!auth.isLoggedIn) {
      if (mounted) setState(() => _phase = _StartupPhase.ready);
      return;
    }

    final token = await auth.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _phase = _StartupPhase.ready);
      return;
    }
    context.read<ApiService>().setToken(token);

    if (!mounted) return;
    final provider = context.read<StudentProvider>();

    setState(() => _phase = _StartupPhase.loadingProfile);
    await provider.fetchCoreData();
    if (provider.error != null) {
      if (mounted) {
        setState(() {
          _phase = _StartupPhase.error;
          _errorMessage = provider.error;
        });
      }
      return;
    }

    setState(() => _phase = _StartupPhase.loadingNotifications);
    // بدون studentId → بتجيب إشعارات الحساب الأساسي + كل إخوته سوا،
    // نفس ما موصوف بتعليق fetchNotifications() بـ StudentProvider.
    await provider.fetchNotifications();

    setState(() => _phase = _StartupPhase.registeringPush);
    try {
      await context.read<NotificationService>().init(studentProvider: provider);
    } catch (_) {
      // فشل تسجيل الإشعارات الفورية (صلاحية مرفوضة مثلاً) ما لازم يمنع
      // فتح التطبيق — التطبيق شغال منيح بدونها، بس بدون push فوري.
    }

    if (mounted) setState(() => _phase = _StartupPhase.ready);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _StartupPhase.checkingAuth:
        return const AppStartupScreen(statusText: 'جاري التحقق من الدخول...');
      case _StartupPhase.loadingProfile:
        return const AppStartupScreen(statusText: 'جاري تحميل بياناتك...');
      case _StartupPhase.loadingNotifications:
        return const AppStartupScreen(statusText: 'جاري جلب إشعارات كل الحسابات...');
      case _StartupPhase.registeringPush:
        return const AppStartupScreen(statusText: 'جاري تفعيل الإشعارات الفورية...');
      case _StartupPhase.error:
        return Scaffold(
          body: SafeArea(
            child: NoConnectionScreen(
              isRetrying: false,
              onRetry: _init,
            ),
          ),
        );
      case _StartupPhase.ready:
        final auth = context.watch<AuthService>();
        return auth.isLoggedIn ? const HomeShell() : const LoginScreen();
    }
  }
}

enum _StartupPhase {
  checkingAuth,
  loadingProfile,
  loadingNotifications,
  registeringPush,
  error,
  ready,
}