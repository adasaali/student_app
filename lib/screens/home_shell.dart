import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../providers/student_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';
import '../widgets/sibling_switcher.dart';

import 'home_screen.dart';
import 'weekly_schedule_screen.dart';
import 'profile_screen.dart';
import 'grades_reports_screen.dart';
import 'student_notes_screen.dart';
import 'homework_screen.dart';
import 'exams_screen.dart';
import 'absence_screen.dart';
import 'finance_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'school_calendar_screen.dart';
import 'curriculum_screen.dart';
import 'worksheets_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WeeklyScheduleScreen(),
    const ProfileScreen(),
    const GradesReportsScreen(),
    const StudentNotesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 🔧 كان هون provider.fetchAllData() وprovider.fetchNotifications() —
    // انشالوا لأنه هلق StartupGate (main.dart) وLoginScreen بيستنوا
    // الاثنين فعلياً *قبل* ما توصل الواجهة أصلاً لهون. تكرارهم هون كان
    // بيعمل طلب شبكة إضافي بلا داعي كل مرة تنفتح فيها HomeShell.
    //
    // NotificationService.init() ضل هون كصمّام أمان إضافي (محمي أصلاً
    // بعلم _initialized داخلها، فاستدعاؤه مرتين آمن 100%) لأي مسار نادر
    // ممكن يوصل لهاي الشاشة بدون ما يمر بـStartupGate/LoginScreen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentProvider>();
      context.read<NotificationService>().init(studentProvider: provider);
    });
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  Future<void> _logout() async {
    await context.read<StudentProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Map<String, Color> _getLogoPalette(String studentName, {String? gender, int? studentId}) {
    final p = SiblingPalette.forStudent(studentName, gender: gender, studentId: studentId);
    return {
      'primaryDark': p.primaryDark,
      'primaryLight': p.primaryLight,
      'goldMain': p.goldMain,
      'goldLight': p.goldLight,
      'accentColor': p.accentColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final studentName = provider.student?.studentName ?? 'الطالب';
    final palette = _getLogoPalette(studentName, gender: provider.student?.gender, studentId: provider.student?.studentId);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_currentIndex != 0) _onTap(0);
        },
        child: Scaffold(
          backgroundColor: AppColors.gray50,
          extendBody: true,
          endDrawer: _buildDrawer(palette),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildTopBar(context, palette, provider),
                const SiblingSwitcher(),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildFloatingNavBar(palette),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Map<String, Color> palette, StudentProvider provider) {
    final student = provider.student;
    final name = (student != null && student.studentName.isNotEmpty) ? student.studentName : 'الطالب';
    final grade = student?.gradeName;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [palette['primaryDark']!, palette['primaryLight']!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: palette['primaryDark']!.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(top: -40, left: -30, child: _decorCircle(120, palette['goldMain']!.withOpacity(0.08))),
          Positioned(bottom: -55, right: -25, child: _decorCircle(150, Colors.white.withOpacity(0.04))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 42,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _GlassIconButton(
                              icon: Icons.notifications_none_rounded,
                              badgeCount: provider.unreadNotifications,
                              badgeColor: palette['accentColor']!,
                              onTap: () => _push(const NotificationsScreen()),
                            ),
                            const SizedBox(width: 8),
                            Builder(
                              builder: (ctx) => _GlassIconButton(
                                icon: Icons.menu_rounded,
                                badgeColor: palette['accentColor']!,
                                onTap: () => Scaffold.of(ctx).openEndDrawer(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'بوابة الطالب',
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.75),
                          letterSpacing: 1.1,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Builder(builder: (_) {
                          final student = provider.student;
                          // عداد غير المقروء — بث دوري (polling كل بضع
                          // ثواني) عبر ChatService الجديد المبني على
                          // MySQL بدل Firestore snapshots القديمة.
                          if (student == null || student.sectionId == null) {
                            return _MessengerIconButton(
                              badgeCount: 0,
                              goldMain: palette['goldMain']!,
                              goldLight: palette['goldLight']!,
                              badgeColor: palette['accentColor']!,
                              onTap: () => _push(const MessagesScreen()),
                            );
                          }
                          return StreamBuilder<int>(
                            // 🔧 قبل هيك ما كان في targetStudentId، فالعدّاد
                            // كان دايماً بيراقب حساب صاحب التوكن (الأساسي)
                            // بس — بغض النظر مين الأخ الفاتح حالياً. صار
                            // يمرر هوية الحساب النشط فعلياً (null لما يكون
                            // هو الحساب الأساسي نفسه، نفس نمط باقي الشاشات).
                            stream: ChatService(context.read<ApiService>()).watchTotalUnreadForStudent(
                              targetStudentId: provider.activeStudentId == provider.primaryStudentId
                                  ? null
                                  : provider.activeStudentId,
                            ),
                            builder: (context, snap) {
                              return _MessengerIconButton(
                                badgeCount: snap.data ?? 0,
                                goldMain: palette['goldMain']!,
                                goldLight: palette['goldLight']!,
                                badgeColor: palette['accentColor']!,
                                onTap: () => _push(const MessagesScreen()),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                // 👇 بطاقة "الاسم" (الترحيب + اسم الطالب + الصف) منطلعة ومنزلة
                // بأنيميشن slide + fade بس وأنت واقف بالصفحة الرئيسية
                // (index 0). أي تبويب تاني منطويها بنفس الحركة العكسية،
                // فبتحس إنها "بتطلع وبتنزل" مع التنقل، مش مجرد تختفي فجأة.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, -0.35),
                      end: Offset.zero,
                    ).animate(animation);
                    return ClipRect(
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: SlideTransition(
                          position: slide,
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                      ),
                    );
                  },
                  child: _currentIndex == 0
                      ? Column(
                    key: const ValueKey('student-name-card'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _greeting(),
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          color: palette['goldLight'],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (grade != null && grade.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: palette['goldMain']!.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: palette['goldLight']!.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      grade,
                                      style: GoogleFonts.cairo(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: palette['goldLight'],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      : const SizedBox.shrink(key: ValueKey('student-name-card-empty')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 17) return 'مرحباً بك 👋';
    return 'مساء الخير 🌙';
  }

  Widget _decorCircle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _buildDrawer(Map<String, Color> palette) {
    return Drawer(
      width: 290,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [palette['primaryDark']!, palette['primaryLight']!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 28),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: palette['goldMain']!.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.school_rounded, color: palette['goldMain'], size: 36),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'الأكاديمية الخاصة',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'بوابة الطالب',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: palette['goldLight'],
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DrawerItem(icon: Icons.calendar_month_rounded, label: 'البرنامج الأسبوعي', onTap: () { Navigator.pop(context); _onTap(1); }),
                    _DrawerItem(icon: Icons.edit_note_rounded, label: 'الواجبات', onTap: () { Navigator.pop(context); _push(const HomeworkScreen()); }),
                    _DrawerItem(icon: Icons.fact_check_rounded, label: 'الاختبارات', onTap: () { Navigator.pop(context); _push(const ExamsScreen()); }),
                    _DrawerItem(icon: Icons.event_busy_rounded, label: 'الغياب', onTap: () { Navigator.pop(context); _push(const AbsenceScreen()); }),
                    _DrawerItem(icon: Icons.account_balance_wallet_rounded, label: 'المالية', onTap: () { Navigator.pop(context); _push(const FinanceScreen()); }),
                    _DrawerItem(icon: Icons.note_alt_rounded, label: 'ملاحظات الطالب', onTap: () { Navigator.pop(context); _onTap(4); }),
                    _DrawerItem(icon: Icons.event_available_rounded, label: 'التقويم المدرسي', onTap: () { Navigator.pop(context); _push(const SchoolCalendarScreen()); }),
                    _DrawerItem(icon: Icons.menu_book_rounded, label: 'المنهاج الرسمي', onTap: () { Navigator.pop(context); _push(const CurriculumScreen()); }),
                    _DrawerItem(icon: Icons.description_rounded, label: 'أوراق العمل', onTap: () { Navigator.pop(context); _push(const WorksheetsScreen()); }),
                    Consumer<StudentProvider>(
                      builder: (context, provider, _) => _DrawerItem(
                        icon: Icons.notifications_outlined,
                        label: 'الإشعارات',
                        badge: provider.unreadNotifications > 0 ? '${provider.unreadNotifications}' : null,
                        badgeColor: palette['accentColor']!,
                        onTap: () { Navigator.pop(context); _push(const NotificationsScreen()); },
                      ),
                    ),
                    _DrawerItem(icon: Icons.settings_outlined, label: 'الإعدادات', onTap: () { Navigator.pop(context); _push(const SettingsScreen()); }),
                    _DrawerItem(icon: Icons.assessment_rounded, label: 'الدرجات والتقارير', onTap: () { Navigator.pop(context); _onTap(3); }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _logout();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'تسجيل الخروج',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(Map<String, Color> palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SizedBox(
        height: 90,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: palette['primaryDark']!.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Row(
                  children: [
                    Expanded(child: _NavItem(icon: Icons.calendar_month_rounded, label: 'البرنامج', isActive: _currentIndex == 1, activeColor: palette['primaryDark']!, onTap: () => _onTap(1))),
                    Expanded(child: _NavItem(icon: Icons.badge_rounded, label: 'الملف', isActive: _currentIndex == 2, activeColor: palette['primaryDark']!, onTap: () => _onTap(2))),
                    const SizedBox(width: 70),
                    Expanded(child: _NavItem(icon: Icons.assessment_rounded, label: 'الدرجات', isActive: _currentIndex == 3, activeColor: palette['primaryDark']!, onTap: () => _onTap(3))),
                    Expanded(child: _NavItem(icon: Icons.note_alt_rounded, label: 'الملاحظات', isActive: _currentIndex == 4, activeColor: palette['primaryDark']!, onTap: () => _onTap(4))),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () => _onTap(0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [palette['primaryDark']!, palette['primaryLight']!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _currentIndex == 0 ? palette['goldMain']! : Colors.white,
                      width: _currentIndex == 0 ? 3 : 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette['primaryDark']!.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.school_rounded, color: palette['goldMain'], size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final Color badgeColor;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, this.badgeCount = 0, required this.badgeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: Icon(icon, color: Colors.white, size: 21)),
                if (badgeCount > 0)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: GoogleFonts.cairo(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessengerIconButton extends StatelessWidget {
  final int badgeCount;
  final Color goldMain;
  final Color goldLight;
  final Color badgeColor;
  final VoidCallback onTap;

  const _MessengerIconButton({
    this.badgeCount = 0,
    required this.goldMain,
    required this.goldLight,
    required this.badgeColor,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [goldLight, goldMain],
              ),
              boxShadow: [
                BoxShadow(color: goldMain.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF141334), size: 19),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: GoogleFonts.cairo(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : AppColors.gray400,
              size: isActive ? 23 : 21,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10.5,
              height: 1.1,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive ? activeColor : AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.badge,
    this.badgeColor,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.75), size: 21),
      title: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      trailing: badge != null
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: badgeColor ?? AppColors.red, borderRadius: BorderRadius.circular(10)),
        child: Text(
          badge!,
          style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.white),
        ),
      )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      horizontalTitleGap: 12,
      minLeadingWidth: 22,
    );
  }
}