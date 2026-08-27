import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../models/student.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fade1;
  late Animation<double> _fade2;
  late Animation<double> _fade3;
  late Animation<double> _fade4;
  late Animation<double> _fade5;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fade1 = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.35, curve: Curves.easeOut));
    _fade2 = CurvedAnimation(parent: _animController, curve: const Interval(0.1, 0.45, curve: Curves.easeOut));
    _fade3 = CurvedAnimation(parent: _animController, curve: const Interval(0.25, 0.6, curve: Curves.easeOut));
    _fade4 = CurvedAnimation(parent: _animController, curve: const Interval(0.4, 0.75, curve: Curves.easeOut));
    _fade5 = CurvedAnimation(parent: _animController, curve: const Interval(0.55, 0.9, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    await context.read<StudentProvider>().fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProvider>(context);

    if (provider.isLoading && provider.student == null) {
      return const _DashboardSkeleton();
    }

    if (provider.error != null && provider.student == null) {
      return _ErrorState(
        message: provider.error!,
        onRetry: () => provider.fetchAllData(),
      );
    }

    final student = provider.student;
    final siblings = provider.siblings;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.gold,
        backgroundColor: AppColors.white,
        displacement: 20,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: FadeTransition(opacity: _fade1, child: _buildAppBar(context))),
            SliverToBoxAdapter(child: FadeTransition(opacity: _fade2, child: _buildGreeting(student))),
            SliverToBoxAdapter(child: FadeTransition(opacity: _fade3, child: _buildClassCard(student))),
            SliverToBoxAdapter(child: FadeTransition(opacity: _fade4, child: _buildQuickActions())),
            SliverToBoxAdapter(child: FadeTransition(opacity: _fade5, child: _buildSiblingsSection(siblings))),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
      ),
    );
  }

  // ==================== APP BAR ====================
  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openEndDrawer(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.menu_rounded, color: AppColors.navy, size: 22),
              ),
            ),
          ),
          const Spacer(),
          Text(
            'بوابة الطالب',
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ==================== GREETING ====================
  Widget _buildGreeting(Student? student) {
    final name = student?.studentName.isNotEmpty == true ? student!.studentName : 'طالب';
    final studentId = student?.studentId.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'صباح الخير،',
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray500),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.cairo(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.navy, height: 1.15),
          ),
          const SizedBox(height: 6),
          Text(
            'الرقم التعريفي: $studentId',
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  // ==================== CLASS CARD ====================
  Widget _buildClassCard(Student? student) {
    final className = student?.gradeName ?? '-';
    final section = student?.sectionName ?? '-';

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.navy, AppColors.navyLight],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.22), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.gold.withOpacity(0.2), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.red.withOpacity(0.1), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.goldLight, size: 24),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'الصف الدراسي',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الصف $className',
                style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.white, height: 1.1),
              ),
              const SizedBox(height: 8),
              Text(
                'الشعبة: $section — العام الدراسي 2025/2026',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== QUICK ACTIONS ====================
  Widget _buildQuickActions() {
    final actions = [
      _ActionItem(icon: Icons.calendar_month_rounded, label: 'الجدول الدراسي', color: AppColors.gold, bgColor: AppColors.goldPale),
      _ActionItem(icon: Icons.description_rounded, label: 'التقارير', color: AppColors.navy, bgColor: const Color(0xFFE8E8F5)),
      _ActionItem(icon: Icons.chat_bubble_rounded, label: 'التواصل', color: AppColors.red, bgColor: const Color(0xFFFDE8E8)),
      _ActionItem(icon: Icons.access_time_filled_rounded, label: 'الغياب والتأخير', color: const Color(0xFF2E7D32), bgColor: const Color(0xFFE8F5E9)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('الوصول السريع', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: actions.map((a) => _ActionCard(item: a)).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== SIBLINGS ====================
  Widget _buildSiblingsSection(List<Sibling> siblings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('الإخوة المسجلون', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${siblings.length}',
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          siblings.isEmpty
              ? const _EmptySiblings()
              : Column(children: siblings.map((s) => _SiblingCard(sibling: s)).toList()),
        ],
      ),
    );
  }
}

// ==================== ACTION CARD ====================
class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  _ActionItem({required this.icon, required this.label, required this.color, required this.bgColor});
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;

  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.gray200, width: 1.5), borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: item.bgColor, borderRadius: BorderRadius.circular(16)),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(item.label, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray800)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SIBLING CARD ====================
class _SiblingCard extends StatelessWidget {
  final Sibling sibling;

  const _SiblingCard({required this.sibling});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.gray200, width: 1.5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.navy, AppColors.navyLight]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sibling.studentName.isNotEmpty ? sibling.studentName : 'غير معروف',
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الصف ${sibling.gradeName ?? '-'}',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.goldPale, borderRadius: BorderRadius.circular(10)),
              child: Text(
                sibling.relation,
                style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== EMPTY SIBLINGS ====================
class _EmptySiblings extends StatelessWidget {
  const _EmptySiblings();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gray200)),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.people_outline, color: AppColors.gray400, size: 28),
          ),
          const SizedBox(height: 16),
          Text('لا يوجد إخوة مسجلون', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.gray600)),
          const SizedBox(height: 4),
          Text('يمكنك إضافة إخوة من إعدادات الحساب', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.gray400)),
        ],
      ),
    );
  }
}

// ==================== ERROR STATE ====================
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 36),
            ),
            const SizedBox(height: 20),
            Text('تعذر تحميل البيانات', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray600)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.navy, AppColors.navyLight]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.2), blurRadius: 20)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, color: AppColors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('إعادة المحاولة', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SKELETON ====================
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 44, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(14))),
          const SizedBox(height: 24),
          Container(height: 80, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 20),
          Container(height: 160, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(20)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(20)))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(20)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(20)))),
            ],
          ),
        ],
      ),
    );
  }
}
