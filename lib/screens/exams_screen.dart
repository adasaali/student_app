import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/placeholder_screen.dart';

/// الاختبارات — تُفتح من قائمة الدرج (Drawer).
/// TODO: اربط مع StudentProvider / ApiService لما يتوفر endpoint الاختبارات.
class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'الاختبارات',
      body: PlaceholderContent(
        title: 'الاختبارات',
        icon: Icons.fact_check_rounded,
        accentColor: AppColors.navy,
        subtitle: 'رح يظهر هون جدول الاختبارات القادمة ونتائجها',
      ),
    );
  }
}
