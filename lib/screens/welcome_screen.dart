import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

/// 🆕 صفحة عامة عن المدرسة تظهر قبل شاشة تسجيل الدخول.
///
/// الهدف: أي زائر (بما فيهم مراجع متجر التطبيقات) يقدر يفتح التطبيق
/// ويشوف محتوى حقيقي عن المدرسة ومميزات البوابة **بدون** ما يحتاج
/// يسجّل دخول. تسجيل الدخول نفسه صار خطوة اختيارية/تالية (زر بالأسفل)
/// وليس أول شي بيواجه المستخدم.
///
/// ملاحظة: هاي الشاشة ثابتة (مش بتجيب أي بيانات من السيرفر ولا بتحتاج
/// توكن) — كل المحتوى فيها عام ومكتوب يدوياً، تماماً متل موقع تعريفي.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _whatsappPhone = '963933950222'; // نفس رقم الدعم بشاشة الدخول

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/$_whatsappPhone');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب، تأكد من تثبيت التطبيق')),
      );
    }
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Hero(),
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AboutCard(),
                            const SizedBox(height: 28),
                            _SectionTitle(
                              title: 'مميزات بوابة الطالب',
                              subtitle: 'كل شي متعلق بمشوار ابنك/ابنتك الدراسي، بمكان واحد',
                            ),
                            const SizedBox(height: 16),
                            _FeaturesGrid(),
                            const SizedBox(height: 28),
                            _ContactCard(onWhatsApp: () => _openWhatsApp(context)),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _BottomLoginBar(onLogin: () => _goToLogin(context)),
      ),
    );
  }
}

// ─────────────────────────────── Hero ───────────────────────────────

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy,
            Color(0xFF0D0D2B),
            AppColors.navyLight,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded, color: AppColors.navy, size: 44),
          ),
          const SizedBox(height: 20),
          Text(
            'مدرسة الأكاديمية الخاصة',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'بوابة أولياء الأمور والطلاب',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── About ───────────────────────────────

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldPale,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'نبذة عن المدرسة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'مدرسة الأكاديمية الخاصة صرح تعليمي يجمع بين المنهاج الأكاديمي '
            'القوي وبيئة تربوية داعمة، بهدف تخريج جيل قادر على التفكير '
            'والإبداع. عبر بوابة الطالب الإلكترونية، بنسهّل التواصل بين '
            'المدرسة وأولياء الأمور، وبنوفر متابعة يومية شفافة لكل ما '
            'يخص المسيرة الدراسية للطالب.',
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              height: 1.75,
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Section title ───────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.gray800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.cairo(
            fontSize: 12.5,
            color: AppColors.gray500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────── Features grid ───────────────────────────────

class _FeatureData {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureData(this.icon, this.title, this.desc);
}

class _FeaturesGrid extends StatelessWidget {
  static const _features = [
    _FeatureData(Icons.menu_book_rounded, 'الواجبات والمناهج', 'متابعة الواجبات اليومية والمواد الدراسية'),
    _FeatureData(Icons.grade_rounded, 'العلامات والتقارير', 'نتائج الاختبارات وتقارير الأداء الدراسي'),
    _FeatureData(Icons.event_note_rounded, 'الجدول والتقويم', 'الجدول الأسبوعي وتقويم الفعاليات المدرسية'),
    _FeatureData(Icons.how_to_reg_rounded, 'الحضور والغياب', 'متابعة حضور الطالب اليومي أولاً بأول'),
    _FeatureData(Icons.chat_bubble_outline_rounded, 'التواصل مع المدرسة', 'رسائل مباشرة مع المعلمين والإدارة'),
    _FeatureData(Icons.photo_library_outlined, 'معرض الصور والفعاليات', 'أبرز لحظات ونشاطات الطلاب'),
    _FeatureData(Icons.directions_bus_filled_rounded, 'النقل المدرسي', 'معلومات خطوط وأوقات الباص المدرسي'),
    _FeatureData(Icons.notifications_active_outlined, 'إشعارات فورية', 'تنبيهات لحظية بكل جديد يخص ابنك'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, i) {
        final f = _features[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(f.icon, color: AppColors.navy, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                f.title,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  f.desc,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────── Contact ───────────────────────────────

class _ContactCard extends StatelessWidget {
  final VoidCallback onWhatsApp;
  const _ContactCard({required this.onWhatsApp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navyLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تواصل معنا',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'عندك استفسار عن التسجيل أو البوابة؟ فريقنا جاهز يساعدك',
            style: GoogleFonts.cairo(
              fontSize: 12.5,
              color: AppColors.white.withOpacity(0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onWhatsApp,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_rounded, size: 18, color: AppColors.navy),
                    const SizedBox(width: 8),
                    Text(
                      'راسلنا عبر واتساب',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Bottom login bar ───────────────────────────────

class _BottomLoginBar extends StatelessWidget {
  final VoidCallback onLogin;
  const _BottomLoginBar({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'تسجيل الدخول لبوابة الطالب',
                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
