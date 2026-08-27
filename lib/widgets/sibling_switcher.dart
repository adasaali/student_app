import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';

/// شريط تبديل الحسابات بين الإخوة — يظهر بأعلى الـ HomeShell فوق كل
/// التبويبات. الحساب الحالي يظهر مميّز بالذهبي، وبمجرد الضغط عأخ بيصير
/// هو الطالب النشط بكل شاشات التطبيق (لأنها كلها بتقرأ من نفس
/// StudentProvider) — حسابه منفصل كلياً عن حساب الطالب الأساسي (بياناته
/// وغيابه ودرجاته وإشعاراته). كل بطاقة حساب بتحمل عداد إشعاراته غير
/// المقروءة الخاص فيها، حتى لو الحساب النشط هلق هو أخ تاني — هيك بتعرف
/// فوراً إذا في إشعارات جديدة لأي أخ بدون ما تضطر تبدّل عليه. يختفي
/// الشريط تلقائياً إذا ما في إخوة مسجلين.
class SiblingSwitcher extends StatelessWidget {
  const SiblingSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final accounts = provider.accounts;

    if (accounts.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 96,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: accounts
            .map(
              (a) => _AccountChip(
            name: a.name.isNotEmpty ? a.name : (a.isActive ? 'أنا' : 'غير معروف'),
            subtitle: a.isActive ? 'الحساب الحالي' : 'تبديل',
            isActive: a.isActive,
            isLoading: provider.isLoading,
            unreadCount: a.unreadCount,
            // 🎨 كل أخ بلونه الخاص حسب جنسه الفعلي (blue=ذكر / خمري=أنثى)
            // — نفس منطق SiblingPalette يلي محسوب بباقي شاشات التطبيق.
            // مش بس الحساب النشط يتلوّن، إنما كل بطاقة بالشريط بتاخد
            // ألوان صاحبها بالضبط، حتى قبل ما تبدّل عليه.
            palette: SiblingPalette.forStudent(a.name, gender: a.gender, studentId: a.studentId),
            onTap: () => provider.switchToAccount(a.studentId),
          ),
        )
            .toList(),
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isActive;
  final bool isLoading;
  final int unreadCount;
  final SiblingPalette palette;
  final VoidCallback onTap;

  const _AccountChip({
    required this.name,
    required this.subtitle,
    required this.isActive,
    required this.isLoading,
    required this.unreadCount,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (isLoading || isActive) ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: isLoading && !isActive ? 0.5 : 1,
        child: Container(
          width: 76,
          margin: const EdgeInsets.only(left: 12),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // 🎨 كل أخ بلون دائرته الخاص (من باليته)، مش
                      // كحلي ثابت للحساب النشط ورمادي للباقي.
                      gradient: LinearGradient(
                        colors: isActive
                            ? [palette.primaryDark, palette.primaryLight]
                            : [palette.primaryDark.withOpacity(0.25), palette.primaryLight.withOpacity(0.18)],
                      ),
                      border: Border.all(
                        color: isActive ? palette.goldMain : palette.primaryDark.withOpacity(0.25),
                        width: isActive ? 2.5 : 1.5,
                      ),
                      boxShadow: isActive
                          ? [BoxShadow(color: palette.goldMain.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: isActive ? AppColors.white : palette.primaryDark.withOpacity(0.55),
                      size: 26,
                    ),
                  ),
                  // عداد إشعارات هالحساب بعينه — منفصل تماماً عن باقي
                  // الحسابات، حتى لو مو الحساب النشط هلق.
                  if (unreadCount > 0)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.white),
                          ),
                        ),
                      ),
                    ),
                ],
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
                  color: isActive ? palette.primaryDark : AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}