import 'package:flutter/material.dart';

/// باليت الألوان الخاصة بحساب طالب معيّن (تتغيّر حسب جنسه وهويته، عشان
/// كل أخ يكون إله لون مختلف عن إخوته وقت تبديل الحساب من
/// [SiblingSwitcher]) — عائلة ذكور = درجات كحلي/أزرق مختلفة، عائلة
/// إناث = درجات خمري مختلفة، مع الحفاظ على نفس لمسة الذهبي جوا كل
/// عائلة حتى تضل الهوية البصرية للتطبيق موحّدة.
///
/// 🔧 هاد المنطق كان مكرّر جوا home_shell.dart (باسم _getLogoPalette)
/// وhome_screen.dart (باسم _getPalette) بنفس القيم بالظبط. نقلناه
/// هون لمكان واحد عشان أي شاشة بدها تتلوّن حسب الأخ النشط تستورد
/// [SiblingPalette.forStudent] بدل ما تعيد كتابة نفس الشرط والألوان.
///
/// 🔧 (تحديث) كانت مبنية على طول اسم الطالب (زوجي/فردي) كحيلة وقتية
/// للتفريق البصري بين الإخوة لحد ما صار عندنا عمود gender فعلي بقاعدة
/// البيانات. بعدين صارت تعتمد على الجنس بس — بس هاد رجّع نفس المشكلة
/// القديمة من ناحية تانية: إذا في أخوين ذكور (أو أختين)، كانوا ياخدوا
/// بالضبط نفس اللون، فمنيش قادر أميّز بينهم بأول نظرة بشريط تبديل
/// الحسابات. هلق منستخدم [studentId] (فريد لكل طالب) لاختيار درجة
/// مختلفة جوا نفس عائلة اللون تبع الجنس، فكل أخ ذكور بيصير إله ظل
/// كحلي مختلف، وكل أخت إناث بيصير إلها ظل خمري مختلف. بيضل الاسم
/// كاحتياط أخير إذا وصل [studentId] فاضي (زي حالة طالب لسا ما
/// انصنّف إدارياً من صفحة review_gender.php ولا عنده جنس ولا id).
class SiblingPalette {
  final Color primaryDark;
  final Color primaryLight;
  final Color goldMain;
  final Color goldLight;
  final Color accentColor;

  const SiblingPalette({
    required this.primaryDark,
    required this.primaryLight,
    required this.goldMain,
    required this.goldLight,
    required this.accentColor,
  });

  /// 🍷 عائلة الثيم الخمري (أنثى) — 4 درجات مختلفة (خمري/عنابي/موف/بني
  /// محروق) بنفس لمسة الذهبي، حتى تتميّز كل أخت عن أخواتها.
  static const _wineVariants = <SiblingPalette>[
    SiblingPalette(
      primaryDark: Color(0xFF6B0D10),
      primaryLight: Color(0xFF991B1F),
      goldMain: Color(0xFFDCB24B),
      goldLight: Color(0xFFF0D27B),
      accentColor: Color(0xFF1B1A42),
    ),
    SiblingPalette(
      primaryDark: Color(0xFF4A1046),
      primaryLight: Color(0xFF6E1B68),
      goldMain: Color(0xFFDCB24B),
      goldLight: Color(0xFFF0D27B),
      accentColor: Color(0xFF1B1A42),
    ),
    SiblingPalette(
      primaryDark: Color(0xFF7A1224),
      primaryLight: Color(0xFFA02338),
      goldMain: Color(0xFFDCB24B),
      goldLight: Color(0xFFF0D27B),
      accentColor: Color(0xFF1B1A42),
    ),
    SiblingPalette(
      primaryDark: Color(0xFF5C1A12),
      primaryLight: Color(0xFF7F2A1C),
      goldMain: Color(0xFFDCB24B),
      goldLight: Color(0xFFF0D27B),
      accentColor: Color(0xFF1B1A42),
    ),
  ];

  /// 🔵 عائلة الثيم الكحلي (ذكر) — 4 درجات مختلفة (كحلي/نيلي/أزرق
  /// فولاذي/كحلي مائل للتركواز) بنفس لمسة الذهبي، حتى يتميّز كل أخ عن
  /// إخوته.
  static const _navyVariants = <SiblingPalette>[
    SiblingPalette(
      primaryDark: Color(0xFF1B1A42),
      primaryLight: Color(0xFF28285C),
      goldMain: Color(0xFFC79831),
      goldLight: Color(0xFFDCB24B),
      accentColor: Color(0xFFE5282C),
    ),
    SiblingPalette(
      primaryDark: Color(0xFF241B54),
      primaryLight: Color(0xFF352878),
      goldMain: Color(0xFFC79831),
      goldLight: Color(0xFFDCB24B),
      accentColor: Color(0xFFE5282C),
    ),
    SiblingPalette(
      primaryDark: Color(0xFF14314A),
      primaryLight: Color(0xFF1F4D6E),
      goldMain: Color(0xFFC79831),
      goldLight: Color(0xFFDCB24B),
      accentColor: Color(0xFFE5282C),
    ),
    SiblingPalette(
      primaryDark: Color(0xFF0F3D3E),
      primaryLight: Color(0xFF17595A),
      goldMain: Color(0xFFC79831),
      goldLight: Color(0xFFDCB24B),
      accentColor: Color(0xFFE5282C),
    ),
  ];

  /// بيرجع فهرس ثابت (نفسه دايماً لنفس الطالب) لاختيار الدرجة جوا
  /// عائلة اللون. [studentId] هو المصدر الأدق لأنه فريد لكل طالب؛
  /// إذا مش متوفر (احتياط) منرجع لهاش بسيط على الاسم.
  static int _variantIndex(String? studentName, int? studentId, int variantCount) {
    if (studentId != null) return studentId % variantCount;
    final name = studentName ?? '';
    if (name.isEmpty) return 0;
    final hash = name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return hash % variantCount;
  }

  /// [gender]: 'male' أو 'female' كما يوصل من عمود std26.gender بالسيرفر.
  /// [studentId]: معرّف الطالب الفريد — بيُستخدم لاختيار درجة لون مختلفة
  /// جوا عائلة الجنس، حتى ما ياخد أخوين نفس اللون بالظبط.
  /// [studentName]: احتياطي فقط — يُستخدم كتمييز بصري مؤقت إذا
  /// [studentId] و[gender] مو متوفرين، حتى يبقى كل أخ متمايز بصرياً عن
  /// إخوته بدل ما يرجعوا كلهم لنفس اللون الافتراضي.
  factory SiblingPalette.forStudent(String? studentName, {String? gender, int? studentId}) {
    if (gender == 'female') {
      return _wineVariants[_variantIndex(studentName, studentId, _wineVariants.length)];
    }
    if (gender == 'male') {
      return _navyVariants[_variantIndex(studentName, studentId, _navyVariants.length)];
    }

    final name = studentName ?? '';
    final isAlternate = name.isNotEmpty && name.length % 2 == 0;
    final variants = isAlternate ? _wineVariants : _navyVariants;
    return variants[_variantIndex(studentName, studentId, variants.length)];
  }

  /// اختصار مباشر لما يكون الجنس (وممكن الـ id) متوفر بدون حاجة لاسم احتياطي.
  factory SiblingPalette.forGender(String? gender, {int? studentId}) =>
      SiblingPalette.forStudent(null, gender: gender, studentId: studentId);
}
