import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';
import '../widgets/placeholder_screen.dart';
import '../providers/student_provider.dart';
import '../models/exam_item.dart';

/// الاختبارات — تُفتح من قائمة الدرج (Drawer).
/// مربوطة فعلياً بـ StudentProvider.fetchExams() (بعد ما كانت شاشة
/// placeholder بلا بيانات حقيقية). أول ما المشرف يحدد موعد "سبر" جديد
/// من تطبيقه، الاختبار بيظهر هون فوراً بحالة "لم تصدر نتيجته بعد"،
/// وأول ما يدخّل المشرف العلامة (student_marks.marks) بتظهر العلامة
/// بنفس البطاقة — بدون ما الطالب يحتاج يفتح شاشة تانية.
class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchExams();
    });
  }

  Future<void> _reload() => context.read<StudentProvider>().fetchExams();

  @override
  Widget build(BuildContext context) {
    final activeStudent = context.watch<StudentProvider>().student;
    final palette = SiblingPalette.forStudent(activeStudent?.studentName ?? '', gender: activeStudent?.gender, studentId: activeStudent?.studentId);

    return SectionScaffold(
      title: 'الاختبارات',
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          final list = provider.exams;

          if (provider.isLoadingExams && list.isEmpty) {
            return Center(child: CircularProgressIndicator(color: palette.goldMain));
          }

          if (provider.examsError != null && list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.gray400),
                    const SizedBox(height: 16),
                    Text('تعذر تحميل الاختبارات',
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: palette.primaryDark)),
                    const SizedBox(height: 6),
                    Text(provider.examsError!,
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
                    title: 'لا توجد اختبارات حالياً',
                    icon: Icons.fact_check_rounded,
                    accentColor: AppColors.navy,
                    subtitle: 'رح يظهر هون جدول الاختبارات القادمة ونتائجها أول ما يحددها المشرف',
                  ),
                ],
              ),
            );
          }

          // ترتيب: الأحدث موعداً أول.
          final sorted = [...list]..sort((a, b) {
            final da = a.examDate;
            final db = b.examDate;
            if (da == null && db == null) return b.createdAt.compareTo(a.createdAt);
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });

          return RefreshIndicator(
            color: palette.goldMain,
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ExamCard(item: sorted[index], palette: palette),
            ),
          );
        },
      ),
    );
  }
}

/// شارة صغيرة تفرّق بصرياً بين "سبر كتابي" (كحلي) و"تسميع" (ذهبي) —
/// أول شي بيشوفه الطالب بالبطاقة عشان يعرف نوع الاختبار من أول نظرة.
class _TypeBadge extends StatelessWidget {
  final ExamItem item;
  const _TypeBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isRecitation ? AppColors.gold : AppColors.navy;
    final icon = item.isRecitation ? Icons.record_voice_over_rounded : Icons.edit_document;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(item.typeLabel, style: GoogleFonts.cairo(fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamItem item;
  final SiblingPalette palette;

  const _ExamCard({required this.item, required this.palette});

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
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
                  child: Icon(item.isRecitation ? Icons.record_voice_over_rounded : Icons.edit_document, color: AppColors.white, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.subjectName,
                              style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.primaryDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _TypeBadge(item: item),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
                // شارة العلامة (لو صدرت) أو حالة الانتظار
                _ResultBadge(item: item),
              ],
            ),

            if (item.description != null) ...[
              const SizedBox(height: 10),
              Text(
                item.description!,
                style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.gray700, height: 1.4),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              children: [
                if (item.examDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.primaryDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_rounded, size: 12, color: palette.primaryDark),
                        const SizedBox(width: 4),
                        Text(_formatDate(item.examDate!),
                            style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w800, color: palette.primaryDark)),
                      ],
                    ),
                  ),
              ],
            ),

            if (item.isReleased && item.notes != null) ...[
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
          ],
        ),
      ),
    );
  }
}

/// شارة نتيجة الاختبار — علامة/أعلى_علامة لو صدرت، أو "لم تصدر نتيجته
/// بعد" برمادي هادئ لو لسا المشرف ما دخّلها (بيتغيّر تلقائياً لما تنضاف).
class _ResultBadge extends StatelessWidget {
  final ExamItem item;
  const _ResultBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    if (!item.isReleased) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 14, color: AppColors.gray400),
            const SizedBox(height: 2),
            Text('لم تصدر\nنتيجته بعد',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gray500, height: 1.2)),
          ],
        ),
      );
    }

    final total = item.totalMarks;
    final markText = total != null
        ? '${_trim(item.marks!)}/${_trim(total)}'
        : _trim(item.marks!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        markText,
        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.green),
      ),
    );
  }

  String _trim(double v) => (v == v.roundToDouble()) ? v.toInt().toString() : v.toStringAsFixed(2);
}
