import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/placeholder_screen.dart';

/// المعرض — ألبوم صور فعاليات المدرسة، تُفتح من الشاشة الرئيسية.
/// TODO: اربط مع StudentProvider / ApiService لما يتوفر endpoint المعرض.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'المعرض',
      body: PlaceholderContent(
        title: 'ألبوم الصور',
        icon: Icons.photo_library_rounded,
        accentColor: AppColors.red,
        subtitle: 'رح تظهر هون صور فعاليات وأنشطة المدرسة أول ما تنضاف',
      ),
    );
  }
}
