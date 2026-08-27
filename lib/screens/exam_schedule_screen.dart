import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/placeholder_screen.dart';

/// جدول الامتحانات — تُفتح من الشاشة الرئيسية (منفصلة عن ExamsScreen
/// يلي بتعرض نتائج/درجات الاختبارات).
/// TODO: اربط مع StudentProvider / ApiService لما يتوفر endpoint جدول الامتحانات.
class ExamScheduleScreen extends StatelessWidget {
  const ExamScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'جدول الامتحانات',
      body: PlaceholderContent(
        title: 'مواعيد الامتحانات',
        icon: Icons.event_note_rounded,
        accentColor: AppColors.navy,
        subtitle: 'رح يظهر هون جدول الامتحانات القادمة بتواريخها وقاعاتها',
      ),
    );
  }
}
