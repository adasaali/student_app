import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// هوية بصرية موحّدة لشاشتي "الرسائل" و"المحادثة" — طابع أكاديمي/رسمي
/// (حبر كحلي + لمسة ذهبية على خلفية عاجية دافئة) بدل التدرجات اللونية
/// والإيموجي يلي كانت مستخدمة بالتصميم القديم. الإيموجي هلق محصور
/// جوا نص الرسائل نفسها (يلي بيكتبها المستخدم) — مو بعناصر الواجهة.
///
/// كل لون هون محسوب عشان يأمّن تباين كافي مع اللي حواليه — ما في نص
/// فاتح على خلفية فاتحة بأي مكان بالشاشتين.
class ChatTheme {
  ChatTheme._();

  /// خلفية عاجية دافئة بدل الأبيض الجليدي/الرمادي البارد.
  static const Color parchment = Color(0xFFFBF8F1);
  static const Color parchmentCard = Color(0xFFFFFFFF);
  static const Color parchmentDeep = Color(0xFFF3EDE0);

  /// حبر كحلي غامق — كل نص أساسي بيتكتب فيه، تباين عالي بكل مكان.
  static const Color ink = Color(0xFF13152C);
  static const Color inkMuted = Color(0xFF51546C);
  static const Color inkFaint = Color(0xFF787C94);

  /// خطوط فاصلة دافئة (بدل الرمادي البارد).
  static const Color hairline = Color(0xFFE6DCC6);
  static const Color hairlineStrong = Color(0xFFD5C69A);

  static const Color danger = Color(0xFFAE2A22);
  static const Color dangerBg = Color(0xFFFBEAE7);
  static const Color dangerBorder = Color(0xFFE7C3BD);

  /// الخط العريض المميّز (Kufi هندسي) — للعناوين فقط، بوقار وثبات.
  static TextStyle display({
    double size = 18,
    FontWeight weight = FontWeight.w800,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.notoKufiArabic(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// خط المتن (Cairo) — الرسائل، الوصف، أي نص طويل.
  static TextStyle body({
    double size = 13.5,
    FontWeight weight = FontWeight.w500,
    Color color = ink,
    double? height,
  }) =>
      GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color, height: height);
}

/// "الختم" — شارة دائرية بحلقتين (حلقة خارجية + تعبئة داخلية) هي
/// العنصر البصري المميّز المتكرر بالشاشتين (أيقونة الهيدر، الأفاتار،
/// أيقونة الحالة الفارغة) بدل الدوائر متدرّجة الألوان القديمة.
class ChatSeal extends StatelessWidget {
  final double size;
  final Color ringColor;
  final Color fillColor;
  final Widget child;
  final double ringWidth;

  const ChatSeal({
    super.key,
    required this.size,
    required this.ringColor,
    required this.fillColor,
    required this.child,
    this.ringWidth = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.09),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ringColor, width: ringWidth)),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: fillColor),
        child: Center(child: child),
      ),
    );
  }
}
