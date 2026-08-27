import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/student_provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';
import '../widgets/home_loading_skeleton.dart';
import '../widgets/no_connection_screen.dart';

// استيراد الشاشات
import 'weekly_schedule_screen.dart';
import 'homework_screen.dart';
import 'exams_screen.dart';
import 'absence_screen.dart';
import 'finance_screen.dart';
import 'grades_reports_screen.dart';
import 'student_notes_screen.dart';
import '../widgets/placeholder_screen.dart';
import 'transportation_screen.dart';
import 'announcements_screen.dart';
import 'exam_schedule_screen.dart';
import 'gallery_screen.dart';
import 'school_calendar_screen.dart';
import 'curriculum_screen.dart';
import 'worksheets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool _hasConnection = true;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final connected = !results.contains(ConnectivityResult.none);
      if (mounted) setState(() => _hasConnection = connected);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    final connected = !results.contains(ConnectivityResult.none);
    if (mounted) setState(() => _hasConnection = connected);
  }

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    await _checkConnection();
    if (_hasConnection && mounted) {
      await context.read<StudentProvider>().fetchAllData();
    }
    if (mounted) setState(() => _isRetrying = false);
  }

  Map<String, Color> _getPalette(String studentName, {String? gender, int? studentId}) {
    final p = SiblingPalette.forStudent(studentName, gender: gender, studentId: studentId);
    return {
      'primary': p.primaryDark,
      'primaryLight': p.primaryLight ?? p.primaryDark.withOpacity(0.8),
      'gold': p.goldMain,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasConnection) {
      return NoConnectionScreen(onRetry: _retry, isRetrying: _isRetrying);
    }

    final student = context.watch<StudentProvider>().student;

    if (student == null) {
      return const HomeLoadingSkeleton();
    }

    final palette = _getPalette(student.studentName, gender: student.gender, studentId: student.studentId);
    final primaryColor = palette['primary']!;
    final primaryLight = palette['primaryLight']!;
    final goldColor = palette['gold']!;

    // 🎨 الخدمات الأكاديمية مع ألوان مميزة وناعمة لكل تبويب لتسهيل التمييز البصري الفوري
    // 🔢 الترتيب الافتراضي المعتمد (يدوياً): الإعلانات، الملاحظات، أوراق
    // العمل، الغياب، المنهاج، الاختبارات، الامتحانات، الدرجات، المالية،
    // المعرض، التقويم، ثم النقل. البلاطات اللي إلها إشعارات غير مقروءة
    // بتتقدّم فوق هالترتيب الافتراضي تلقائياً (شوف الفرز تحت).
    final gridActions = <_QuickAction>[
      _QuickAction(
        'الإعلانات',
        Icons.campaign_rounded,
        const Color(0xFF4F46E5),
        const Color(0xFFEEF2FF),
            (_) => const AnnouncementsScreen(),
        notificationTypes: const ['announcement'],
      ),
      _QuickAction(
        'الملاحظات',
        Icons.edit_note_rounded,
        const Color(0xFF7C3AED),
        const Color(0xFFF5F3FF),
            (_) => const SectionScaffold(title: 'الملاحظات', body: StudentNotesScreen()),
        notificationTypes: const ['note', 'student_note', 'behavior_note'],
      ),
      _QuickAction(
        'أوراق\nالعمل',
        Icons.description_rounded,
        const Color(0xFF0369A1),
        const Color(0xFFF0F9FF),
            (_) => const WorksheetsScreen(),
        notificationTypes: const ['worksheet', 'worksheets'],
      ),
      _QuickAction(
        'الغياب',
        Icons.event_busy_rounded,
        const Color(0xFFDC2626),
        const Color(0xFFFEF2F2),
            (_) => const AbsenceScreen(),
        notificationTypes: const ['absence'],
      ),
      _QuickAction(
        'المنهاج\nالرسمي',
        Icons.menu_book_rounded,
        const Color(0xFF9333EA),
        const Color(0xFFFAF5FF),
            (_) => const CurriculumScreen(),
        notificationTypes: const ['curriculum'],
      ),
      _QuickAction(
        'الاختبارات',
        Icons.fact_check_rounded,
        const Color(0xFF2563EB),
        const Color(0xFFEFF6FF),
            (_) => const ExamsScreen(),
        notificationTypes: const ['exam', 'exams'],
      ),
      _QuickAction(
        'الامتحانات',
        Icons.event_note_rounded,
        const Color(0xFF0284C7),
        const Color(0xFFF0F9FF),
            (_) => const ExamScheduleScreen(),
        notificationTypes: const ['exam_schedule'],
      ),
      _QuickAction(
        'الدرجات',
        Icons.insights_rounded,
        const Color(0xFF0D9488),
        const Color(0xFFF0FDFA),
            (_) => const SectionScaffold(title: 'الدرجات والتقارير', body: GradesReportsScreen()),
        notificationTypes: const ['grade', 'grades'],
      ),
      _QuickAction(
        'المالية',
        Icons.account_balance_wallet_rounded,
        const Color(0xFFD97706),
        const Color(0xFFFFFBEB),
            (_) => const FinanceScreen(),
        notificationTypes: const ['finance'],
      ),
      _QuickAction(
        'المعرض',
        Icons.photo_library_rounded,
        const Color(0xFFDB2777),
        const Color(0xFFFDF2F8),
            (_) => const GalleryScreen(),
        notificationTypes: const ['gallery'],
      ),
      _QuickAction(
        'التقويم\nالمدرسي',
        Icons.event_available_rounded,
        const Color(0xFF059669),
        const Color(0xFFECFDF5),
            (_) => const SchoolCalendarScreen(),
        notificationTypes: const ['school_calendar', 'calendar'],
      ),
      _QuickAction(
        'النقل',
        Icons.directions_bus_rounded,
        const Color(0xFFEA580C),
        const Color(0xFFFFF7ED),
            (_) => const TransportationScreen(),
        notificationTypes: const ['transportation'],
      ),
    ];

    // 🔔 أولوية للبلاطات اللي عندها إشعارات غير مقروءة: بتترتّب فوق
    // الترتيب الافتراضي أعلاه (مع الحفاظ على ترتيبها النسبي فيما بينها،
    // وترتيب البلاطات الباقية زي ما هو بالأسفل).
    final studentProvider = context.watch<StudentProvider>();
    bool hasUnread(_QuickAction a) =>
        a.notificationTypes.isNotEmpty && studentProvider.unreadCountForTypes(a.notificationTypes) > 0;
    final sortedGridActions = <_QuickAction>[
      ...gridActions.where(hasUnread),
      ...gridActions.where((a) => !hasUnread(a)),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. قسم المهام الأساسية (البطاقات الملونة الحيوية)
          Row(
            children: [
              Expanded(
                child: _buildFilledCard(
                  context: context,
                  title: 'البرنامج\nالأسبوعي',
                  icon: Icons.calendar_today_rounded,
                  colorStart: primaryColor,
                  colorEnd: primaryLight,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilledCard(
                  context: context,
                  title: 'الواجبات\nوالمهام',
                  icon: Icons.assignment_rounded,
                  colorStart: goldColor,
                  colorEnd: const Color(0xFFEAB308),
                  textColor: const Color(0xFF1E293B),
                  // 🔔 عدد إشعارات الواجبات غير المقروءة — نفس منطق الغياب
                  // تماماً (unreadCountForTypes)، مش عدد الواجبات الكلي.
                  badgeCount: context.watch<StudentProvider>().unreadCountForTypes(const ['homework']),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeworkScreen())),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // 2. عنوان قسم الخدمات بستايل نظيف
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: goldColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'الخدمات الأكاديمية',
                style: GoogleFonts.cairo(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. شبكة الأقسام (تمييز بصري ذكي لكل تبويب لتسهيل وسرعة الاستخدام)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedGridActions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) => _buildDistinctiveGridTile(context, sortedGridActions[index]),
          ),
        ],
      ),
    );
  }

  // بطاقات رئيسية حيوية
  Widget _buildFilledCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color colorStart,
    required Color colorEnd,
    Color textColor = Colors.white,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: 116,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [colorStart, colorEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: colorStart.withOpacity(0.3),
            blurRadius: 18,
            spreadRadius: -2,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🔔 الشارة هلق Stack محلي حول الأيقونة نفسها بس —
                    // مش نسبةً لزاوية البطاقة كاملة. هيك ما بتحرّك أي
                    // عنصر تاني بالبطاقة (العنوان تحت ضل بمكانه تماماً،
                    // مافي أي "إزاحة" لباقي المحتوى)، وبتبين الشارة
                    // عائمة ومرتبطة بصرياً بالأيقونة مباشرة، بنفس زاوية
                    // (top/right) المستخدمة بباقي شارات التطبيق.
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(icon, color: textColor, size: 23),
                        ),
                        if (badgeCount > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colorStart, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  badgeCount > 9 ? '9+' : '$badgeCount',
                                  style: GoogleFonts.cairo(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // مربعات الشبكة المميزة لونياً بذكاء لتسهيل التمييز دون الإضرار بالجمالية
  Widget _buildDistinctiveGridTile(BuildContext context, _QuickAction action) {
    // 🔔 عدد إشعارات هالبلاطة تحديداً — context.watch هون بيعمل rebuild
    // فوري لهالبلاطة بس (مش الشاشة كلها) كل ما توصل إشعار جديد بأي
    // وقت، حتى وأنت واقف عالصفحة الرئيسية بالذات، بدون ما تسكّر التطبيق.
    final badgeCount = action.notificationTypes.isEmpty
        ? 0
        : context.watch<StudentProvider>().unreadCountForTypes(action.notificationTypes);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: action.color.withOpacity(0.07),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          highlightColor: action.color.withOpacity(0.05),
          splashColor: action.color.withOpacity(0.1),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: action.screenBuilder)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔔 نفس المبدأ: Stack محلي حول الأيقونة (48×48) بس، مش
              // حول البلاطة كاملة. الشارة هلق عائمة فعلياً على زاوية
              // الأيقونة (فوقها يمين)، ومحاذاة الأيقونة والنص تحتها
              // ضلت بالضبط متل ما كانت قبل — ما في أي إزاحة لأي عنصر.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: action.backgroundColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(action.icon, color: action.color, size: 23),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: GoogleFonts.cairo(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Widget Function(BuildContext) screenBuilder;
  // 🔔 أنواع الإشعارات المرتبطة بهالبلاطة — تُستخدم لحساب شارة العدد
  // فوقها عبر StudentProvider.unreadCountForTypes(). أكتر من نوع
  // احتياطاً لاختلاف التسمية المحتمل من السيرفر (مثلاً 'exam'/'exams').
  final List<String> notificationTypes;

  _QuickAction(
      this.label,
      this.icon,
      this.color,
      this.backgroundColor,
      this.screenBuilder, {
        this.notificationTypes = const [],
      });
}