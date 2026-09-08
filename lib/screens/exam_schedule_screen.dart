import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';
import '../widgets/placeholder_screen.dart';
import '../providers/student_provider.dart';
import '../models/exam_schedule.dart';

/// جدول الامتحانات — تُفتح من الشاشة الرئيسية (منفصلة عن ExamsScreen
/// يلي بتعرض نتائج/درجات الاختبارات). مربوطة بـ
/// StudentProvider.fetchExamSchedule() اللي بيجيب "البرنامج الامتحاني"
/// الرسمي يلي المدير ضافه من admin/exam_schedule/exam_schedule.php
/// (تاريخ كل امتحان + المادة + المقررات الداخلة فيه + التعليمات
/// الامتحانية بعد الجدول).
class ExamScheduleScreen extends StatefulWidget {
  const ExamScheduleScreen({super.key});

  @override
  State<ExamScheduleScreen> createState() => _ExamScheduleScreenState();
}

class _ExamScheduleScreenState extends State<ExamScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchExamSchedule();
    });
  }

  Future<void> _reload() => context.read<StudentProvider>().fetchExamSchedule();

  @override
  Widget build(BuildContext context) {
    final activeStudent = context.watch<StudentProvider>().student;
    final palette = SiblingPalette.forStudent(activeStudent?.studentName ?? '', gender: activeStudent?.gender, studentId: activeStudent?.studentId);

    return SectionScaffold(
      title: 'الامتحانات',
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          final list = provider.examSchedules;

          if (provider.isLoadingExamSchedule && list.isEmpty) {
            return Center(child: CircularProgressIndicator(color: palette.goldMain));
          }

          if (provider.examScheduleError != null && list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.gray400),
                    const SizedBox(height: 16),
                    Text('تعذر تحميل البرنامج الامتحاني',
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: palette.primaryDark)),
                    const SizedBox(height: 6),
                    Text(provider.examScheduleError!,
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
                    title: 'لا يوجد برنامج امتحاني بعد',
                    icon: Icons.event_note_rounded,
                    accentColor: AppColors.navy,
                    subtitle: 'رح يظهر هون جدول الامتحانات القادمة بتواريخها والمقررات الداخلة فيها أول ما تُضاف',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: palette.goldMain,
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _ExamScheduleCard(schedule: list[index], palette: palette),
            ),
          );
        },
      ),
    );
  }
}

class _ExamScheduleCard extends StatelessWidget {
  final ExamSchedule schedule;
  final SiblingPalette palette;

  const _ExamScheduleCard({required this.schedule, required this.palette});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.primaryDark, palette.primaryLight],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_note_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    schedule.scheduleName,
                    style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          if (schedule.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: _HeaderCell('التاريخ')),
                        Expanded(flex: 3, child: _HeaderCell('المادة')),
                        Expanded(flex: 5, child: _HeaderCell('المقررات الداخلة بالامتحان')),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.gray200),
                  ...schedule.items.map((row) => _ExamRow(row: row, palette: palette, formatDate: _formatDate)),
                ],
              ),
            ),

          if (schedule.instructions != null && schedule.instructions!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.goldMain.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.goldMain.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_rounded, size: 17, color: palette.goldMain),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('التعليمات الامتحانية',
                              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800, color: palette.primaryDark)),
                          const SizedBox(height: 4),
                          Text(schedule.instructions!,
                              style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.gray700, height: 1.6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gray500),
    );
  }
}

class _ExamRow extends StatelessWidget {
  final ExamScheduleRow row;
  final SiblingPalette palette;
  final String Function(DateTime) formatDate;

  const _ExamRow({required this.row, required this.palette, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray100, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.examDate != null ? formatDate(row.examDate!) : '—',
              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: palette.primaryDark),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.subjectName,
              style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              row.curriculumText?.isNotEmpty == true ? row.curriculumText! : '—',
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.gray600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
