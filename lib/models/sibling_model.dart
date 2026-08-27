import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import 'student.dart';
import '../theme/app_colors.dart';

/// شريط تبديل الحسابات بين الإخوة — يظهر بأعلى الـ HomeShell فوق كل
/// التبويبات. الحساب الحالي يظهر مميّز بالذهبي، وبمجرد الضغط عأخ بيصير
/// هو الطالب النشط بكل شاشات التطبيق (لأنها كلها بتقرأ من نفس
/// StudentProvider). يختفي الشريط تلقائياً إذا ما في إخوة مسجلين.
class SiblingSwitcher extends StatelessWidget {
  const SiblingSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final student = provider.student;
    final siblings = provider.siblings;

    if (student == null || siblings.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 96,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _AccountChip(
            name: student.studentName.isNotEmpty ? student.studentName : 'أنا',
            subtitle: 'الحساب الحالي',
            isActive: true,
            isLoading: false,
            onTap: () {},
          ),
          ...siblings.map(
                (s) => _AccountChip(
              name: s.studentName.isNotEmpty ? s.studentName : 'غير معروف',
              subtitle: s.relation,
              isActive: false,
              isLoading: provider.isLoading,
              onTap: () => provider.switchToSibling(s),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _AccountChip({
    required this.name,
    required this.subtitle,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isLoading && !isActive ? 0.5 : 1,
        child: Container(
          width: 76,
          margin: const EdgeInsets.only(left: 12),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isActive
                        ? [AppColors.navy, AppColors.navyLight]
                        : [AppColors.gray200, AppColors.gray100],
                  ),
                  border: Border.all(
                    color: isActive ? AppColors.gold : AppColors.gray200,
                    width: isActive ? 2.5 : 1.5,
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(color: AppColors.gold.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Icon(Icons.person_rounded, color: isActive ? AppColors.white : AppColors.gray500, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? AppColors.navy : AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
