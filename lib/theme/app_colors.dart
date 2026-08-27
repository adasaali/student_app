import 'package:flutter/material.dart';

/// لوحة ألوان موحّدة لكامل التطبيق — مصدر واحد للحقيقة
/// (كانت هذه الفئة مكررة بشكل مستقل داخل كل شاشة بقيم مختلفة قليلاً؛
/// تم توحيدها هنا ليستوردها الجميع بدل إعادة تعريفها).
class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF16213E);
  static const Color navyLight = Color(0xFF2C3E67);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE9CB6B);
  static const goldPale = Color(0xFFFDF6E3);

  static const Color red = Color(0xFFE5484D);
  static const Color green = Color(0xFF2FAE6B);

  static const Color white = Colors.white;

  static const Color gray50 = Color(0xFFF7F8FA);
  static const Color gray100 = Color(0xFFEFF1F5);
  static const Color gray200 = Color(0xFFE3E6EC);
  static const Color gray300 = Color(0xFFC9CEDA);
  static const Color gray400 = Color(0xFFA0A7B7);
  static const Color gray500 = Color(0xFF7B8394);
  static const Color gray600 = Color(0xFF5A6272);
  static const Color gray700 = Color(0xFF3F4656);
  static const Color gray800 = Color(0xFF262B36);
}
