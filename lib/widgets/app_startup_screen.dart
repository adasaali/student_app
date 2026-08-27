import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// شاشة الانتظار الكاملة عند فتح التطبيق — مبنية حول شعار المدرسة نفسه.
///
/// الشعار محطوط فوق بطاقة بيضا دائرية (مش مباشرة عالخلفية الكحلية)
/// لأنو عناصر الشعار (الكتاب الكحلي تحديداً) بتختفي إذا حطيناها مباشرة
/// فوق خلفية بنفس درجة اللون تقريباً — البطاقة البيضا بتخلي الشعار
/// يبين بألوانه الحقيقية وبتضيفله عمق (ظل ناعم).
///
/// حركتان بسيطتان بس مقصودتان (مش كتير عشان يضل احترافي وهادئ):
/// 1) دخول الشعار: تكبير خفيف + تلاشي (scale 0.82→1، opacity 0→1)
///    مرة وحدة عند فتح الشاشة — إحساس "استقرار" بدل ما يقفز فجأة.
/// 2) هالة ذهبية خلف البطاقة بتنبض بهدوء (توسّع + تلاشي بطيء متكرر) —
///    نفس فكرة splash screens الاحترافية (تفاصيل حركة صغيرة تعطي إحساس
///    "حي" بدون ما تلفت الانتباه عن الشعار نفسه).
class AppStartupScreen extends StatefulWidget {
  final String statusText;
  const AppStartupScreen({super.key, required this.statusText});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _scale = CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _entrance, curve: const Interval(0, 0.6, curve: Curves.easeOut));

    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, AppColors.navyLight],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 168,
                height: 168,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // الهالة الذهبية النابضة خلف البطاقة
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final t = _pulse.value;
                        return Container(
                          width: 130 + (t * 38),
                          height: 130 + (t * 38),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldLight.withOpacity((1 - t) * 0.22),
                          ),
                        );
                      },
                    ),
                    // البطاقة البيضا + الشعار، بحركة الدخول
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.82, end: 1).animate(_scale),
                      child: FadeTransition(
                        opacity: _fade,
                        child: Container(
                          width: 132,
                          height: 132,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.22),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.6),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              FadeTransition(
                opacity: _fade,
                child: Text(
                  'مدرسة الأكاديمية',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeTransition(
                opacity: _fade,
                child: Text(
                  'بوابة الطالب',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldLight.withOpacity(0.85),
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.goldLight.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  widget.statusText,
                  key: ValueKey(widget.statusText),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
