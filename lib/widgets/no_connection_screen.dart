import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// شاشة "عدم الاتصال بالإنترنت" — تُعرض بدل المحتوى لما ما يكون في اتصال
/// فعّال بالشبكة، مع زر لإعادة المحاولة.
class NoConnectionScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isRetrying;

  const NoConnectionScreen({
    super.key,
    required this.onRetry,
    this.isRetrying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.navy.withOpacity(0.08), AppColors.gold.withOpacity(0.10)],
                ),
              ),
              child: Icon(Icons.wifi_off_rounded, size: 46, color: AppColors.navy.withOpacity(0.55)),
            ),
            const SizedBox(height: 22),
            Text(
              'لا يوجد اتصال بالإنترنت',
              style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              'تأكد من اتصالك بشبكة الواي فاي أو بيانات الجوال، وحاول مرة ثانية',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 26),
            Material(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: isRetrying ? null : onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRetrying)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                        )
                      else
                        const Icon(Icons.refresh_rounded, color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'إعادة المحاولة',
                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
