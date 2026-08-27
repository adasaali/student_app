import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';
import '../models/weekly_schedule.dart';
import '../services/api_service.dart';
import '../providers/student_provider.dart';

/// البرنامج الأسبوعي — تبويب بالشريط السفلي.
/// يعرض جدول الطالب الأسبوعي بشكل تبويبات أيام + بطاقات حصص (بدل جدول
/// عريض بالتصميم القديم يلي كان بيحتاج سكرول أفقي مزعج عالموبايل خصوصاً
/// مع العربي RTL). التصميم هلق متناسق مع باقي شاشات التطبيق
/// (StudentsScreen): خط Cairo، نفس نظام AppColors، ونفس شكل حالات
/// الفراغ/الخطأ.
///
/// 🎨 الألوان الأساسية (الكحلي/الذهبي أو الخمري حسب الأخ النشط) هلق
/// ديناميكية عبر [SiblingPalette.forStudent] — نفس المنطق يلي بـ
/// home_shell.dart — بدل ما تكون ثابتة على AppColors.navy/gold دايماً.
/// الألوان المحايدة (رمادي، أبيض) ضلت من AppColors متل ما هي.
class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  late Future<WeeklySchedule> _future;

  // 🔧 قبل هيك كانت الشاشة عم تجيب البرنامج مباشرة من ApiService بشكل
  // ثابت بـ initState() بدون أي وعي بـ "الحساب النشط" (activeStudentId)،
  // فلما تبدّل لأخ من شريط تبديل الحسابات، البرنامج الأسبوعي كان يضل
  // عارض برنامج صاحب التوكن الأساسي دايماً — بعكس باقي الشاشات
  // (الدرجات، الغياب) يلي كانت مربوطة صح. هلق منراقب activeStudentId
  // ومنعيد الجلب تلقائياً كل ما يتغيّر (تبديل حساب).
  int? _loadedForStudentId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeId = context.watch<StudentProvider>().activeStudentId;
    if (!_initialized || _loadedForStudentId != activeId) {
      _initialized = true;
      _loadedForStudentId = activeId;
      // بتمر من StudentProvider (مش ApiService مباشرة) عشان تضمن إن
      // التوكن معبّى قبل الطلب — هاد كان سبب رسالة "يرجى تسجيل الدخول"
      // الخاطئة رغم إن المستخدم مسجّل دخول فعلياً.
      _future = context.read<StudentProvider>().fetchWeeklySchedule();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = context.read<StudentProvider>().fetchWeeklySchedule();
    });
    await _future.catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    // بيانات الطالب النشط حالياً (الحساب الأساسي أو أخ مبدّل عليه) بتحدد
    // الثيم — نفس منطق home_shell بالظبط.
    final activeStudent = context.watch<StudentProvider>().student;
    final palette = SiblingPalette.forStudent(activeStudent?.studentName, gender: activeStudent?.gender, studentId: activeStudent?.studentId);

    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: SafeArea(
          child: FutureBuilder<WeeklySchedule>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: palette.goldMain));
              }

              if (snapshot.hasError) {
                return _buildMessage(
                  palette: palette,
                  icon: Icons.cloud_off_rounded,
                  title: 'تعذر تحميل البرنامج',
                  subtitle: snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'حدث خطأ أثناء جلب البرنامج',
                  onRetry: _reload,
                );
              }

              final schedule = snapshot.data!;
              if (schedule.isEmpty) {
                return _buildMessage(
                  palette: palette,
                  icon: Icons.calendar_month_rounded,
                  title: 'لا يوجد برنامج بعد',
                  subtitle: 'لم يتم إدخال البرنامج الأسبوعي لشعبتك بعد',
                  onRetry: _reload,
                );
              }

              return _ScheduleView(schedule: schedule, palette: palette, onRefresh: _reload);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required SiblingPalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: palette.primaryDark)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray500)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, color: palette.goldMain, size: 18),
              label: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: palette.goldMain, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

/// الجزء الرئيسي: عنوان الصف/الشعبة + تبويبات الأيام + بطاقات الحصص
class _ScheduleView extends StatefulWidget {
  final WeeklySchedule schedule;
  final SiblingPalette palette;
  final Future<void> Function() onRefresh;

  const _ScheduleView({required this.schedule, required this.palette, required this.onRefresh});

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // نبلّش من أول يوم فيه حصة فعلياً (بدل يوم فاضي)، وإلا أول يوم بالقائمة
    final firstNonEmptyDay = List.generate(widget.schedule.dayNames.length, (i) => i).firstWhere(
          (dayIndex) => widget.schedule.periods.any((p) => widget.schedule.slotFor(dayIndex, p.id) != null),
      orElse: () => 0,
    );
    _tabController = TabController(
      length: widget.schedule.dayNames.length,
      vsync: this,
      initialIndex: firstNonEmptyDay,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final palette = widget.palette;

    return Column(
      children: [
        // ── رأس الشاشة: الصف + الشعبة ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'البرنامج الأسبوعي',
                      style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800, color: palette.primaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${schedule.gradeName} • ${schedule.sectionName}',
                      style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: palette.goldMain.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available_rounded, size: 16, color: palette.goldMain),
                    const SizedBox(width: 6),
                    Text(
                      '${schedule.totalPeriods} حصة',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700, color: palette.primaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── تبويبات الأيام ──────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gray200, width: 1.2),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: LinearGradient(colors: [palette.primaryDark, palette.primaryLight]),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.gray500,
            labelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800),
            unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
            dividerColor: Colors.transparent,
            tabs: schedule.dayNames.map((d) => Tab(text: d)).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // ── محتوى اليوم المختار: بطاقات الحصص ───────────────────
        Expanded(
          child: RefreshIndicator(
            color: palette.goldMain,
            onRefresh: widget.onRefresh,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(schedule.dayNames.length, (dayIndex) {
                return _DaySchedule(schedule: schedule, dayIndex: dayIndex, palette: palette);
              }),
            ),
          ),
        ),
      ],
    );
  }
}

/// قائمة حصص يوم واحد
class _DaySchedule extends StatelessWidget {
  final WeeklySchedule schedule;
  final int dayIndex;
  final SiblingPalette palette;

  const _DaySchedule({required this.schedule, required this.dayIndex, required this.palette});

  @override
  Widget build(BuildContext context) {
    final periods = schedule.periods;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: periods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final period = periods[i];
        final slot = schedule.slotFor(dayIndex, period.id);
        return _PeriodCard(period: period, slot: slot, palette: palette);
      },
    );
  }
}

/// بطاقة حصة واحدة — إما فيها مادة/معلم، أو فاضية
class _PeriodCard extends StatelessWidget {
  final SchedulePeriod period;
  final ScheduleSlot? slot;
  final SiblingPalette palette;

  const _PeriodCard({required this.period, required this.slot, required this.palette});

  @override
  Widget build(BuildContext context) {
    final isEmpty = slot == null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200, width: 1.2),
      ),
      child: Row(
        children: [
          // رقم/عنوان الحصة
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isEmpty
                  ? null
                  : LinearGradient(colors: [palette.primaryDark, palette.primaryLight]),
              color: isEmpty ? AppColors.gray50 : null,
              borderRadius: BorderRadius.circular(12),
              border: isEmpty ? Border.all(color: AppColors.gray200) : null,
            ),
            child: Text(
              '${period.periodNumber}',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isEmpty ? AppColors.gray400 : AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmpty ? 'حصة فارغة' : slot!.subjectName,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isEmpty ? AppColors.gray400 : palette.primaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEmpty ? period.label : slot!.teacherName,
                  style: GoogleFonts.cairo(fontSize: 12, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          if (!isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: palette.goldMain.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                period.label,
                style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700, color: palette.goldMain),
              ),
            ),
        ],
      ),
    );
  }
}
