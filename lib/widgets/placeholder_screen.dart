import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// محتوى عام قابل لإعادة الاستخدام لأي قسم لسا ما ربطناه بالـ API
/// (بدون Scaffold — يستخدم مباشرة كمحتوى تبويب بالشريط السفلي).
/// لما يتوفر endpoint حقيقي للقسم، بدّل هالمحتوى بمحتوى فعلي.
class PlaceholderContent extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final Color accentColor;

  const PlaceholderContent({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle = 'هالقسم قيد التجهيز حالياً، رح يكون متاح قريباً',
    this.accentColor = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, color: accentColor, size: 42),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.cairo(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray500, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// إطار موحّد (AppBar + خلفية + RTL) لأي شاشة فرعية تُفتح Navigator.push
/// من قائمة الدرج (Drawer) فوق الـ HomeShell — بيرجع بسهم رجوع تلقائي.
class SectionScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const SectionScaffold({super.key, required this.title, required this.body, this.actions});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.navy),
          title: Text(title, style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy)),
          actions: actions,
        ),
        body: body,
      ),
    );
  }
}
