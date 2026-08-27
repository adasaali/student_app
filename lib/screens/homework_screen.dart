import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';
import '../widgets/placeholder_screen.dart';
import '../providers/student_provider.dart';
import '../models/homework_item.dart';

/// الواجبات — تُفتح من الدرج أو بلاطة "الواجبات" بالشاشة الرئيسية.
/// مربوطة فعلياً بـ StudentProvider.fetchHomework() (بعد ما كانت
/// شاشة placeholder بلا بيانات حقيقية). التصميم بألوان هوية الطالب
/// النشط حالياً (SiblingPalette)، وكل بطاقة واجب فيها مؤشر بصري
/// لإلحاحية موعد التسليم (فات موعده / اليوم / قريب / بعيد).
class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchHomework();
    });
  }

  Future<void> _reload() => context.read<StudentProvider>().fetchHomework();

  @override
  Widget build(BuildContext context) {
    final activeStudent = context.watch<StudentProvider>().student;
    final palette = SiblingPalette.forStudent(activeStudent?.studentName ?? '', gender: activeStudent?.gender, studentId: activeStudent?.studentId);

    return SectionScaffold(
      title: 'الواجبات',
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          final list = provider.homework;

          if (provider.isLoadingHomework && list.isEmpty) {
            return Center(child: CircularProgressIndicator(color: palette.goldMain));
          }

          if (provider.homeworkError != null && list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.gray400),
                    const SizedBox(height: 16),
                    Text('تعذر تحميل الواجبات',
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: palette.primaryDark)),
                    const SizedBox(height: 6),
                    Text(provider.homeworkError!,
                        textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray500)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _reload,
                      icon: Icon(Icons.refresh_rounded, color: palette.goldMain, size: 18),
                      label: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: palette.goldMain, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }

          if (list.isEmpty) {
            return RefreshIndicator(
              color: palette.goldMain,
              onRefresh: _reload,
              child: ListView(
                children: const [
                  SizedBox(height: 60),
                  PlaceholderContent(
                    title: 'لا توجد واجبات حالياً',
                    icon: Icons.edit_note_rounded,
                    accentColor: AppColors.gold,
                    subtitle: 'رح تظهر هون الواجبات المطلوبة من كل مادة ومواعيد تسليمها أول ما تُضاف',
                  ),
                ],
              ),
            );
          }

          // ترتيب: يلي إلها موعد تسليم أقرب (أو فات موعدها) أول، وبعدين
          // يلي بلا موعد محدد، وبينهم الأحدث إضافة أول.
          final sorted = [...list]..sort((a, b) {
            final da = a.daysUntilDue;
            final db = b.daysUntilDue;
            if (da == null && db == null) return b.createdAt.compareTo(a.createdAt);
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });

          return RefreshIndicator(
            color: palette.goldMain,
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _HomeworkCard(item: sorted[index], palette: palette),
            ),
          );
        },
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkItem item;
  final SiblingPalette palette;

  const _HomeworkCard({required this.item, required this.palette});

  /// حالة الإلحاحية بناءً على موعد التسليم — بتحدد لون شارة الموعد.
  ({Color color, String label})? _dueUrgency() {
    final days = item.daysUntilDue;
    if (days == null) return null;
    if (days < 0) return (color: AppColors.red, label: 'فات موعده');
    if (days == 0) return (color: AppColors.red, label: 'اليوم');
    if (days == 1) return (color: palette.goldMain, label: 'بكرا');
    if (days <= 3) return (color: palette.goldMain, label: 'خلال $days أيام');
    return (color: AppColors.gray400, label: '${item.dueDate!.year}-${item.dueDate!.month.toString().padLeft(2, '0')}-${item.dueDate!.day.toString().padLeft(2, '0')}');
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
    if (diff.inDays < 7) return 'قبل ${diff.inDays} يوم';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final urgency = _dueUrgency();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200, width: 1),
        boxShadow: [
          BoxShadow(color: palette.primaryDark.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أيقونة المادة — متدرّجة بلون هوية الطالب
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [palette.primaryDark, palette.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: palette.primaryDark.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Icon(
                    item.hasAssignment ? Icons.assignment_rounded : Icons.menu_book_rounded,
                    color: AppColors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subjectName,
                        style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.primaryDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.lessonName,
                        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (item.hasAssignment && item.assignmentDescription != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.primaryDark.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.primaryDark.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment_turned_in_rounded, size: 14, color: palette.primaryDark),
                        const SizedBox(width: 6),
                        Text('الواجب المطلوب',
                            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: palette.primaryDark)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.assignmentDescription!,
                      style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray700, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            if (item.notes != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: AppColors.gray400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.notes!,
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.gray500, height: 1.4, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            Row(
              children: [
                if (urgency != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: urgency.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_rounded, size: 12, color: urgency.color),
                        const SizedBox(width: 4),
                        Text(urgency.label, style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w800, color: urgency.color)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (!item.hasAssignment)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('بدون واجب — درس فقط',
                        style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.gray500)),
                  ),
                const Spacer(),
                Text(_relativeTime(item.createdAt),
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.gray400, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}