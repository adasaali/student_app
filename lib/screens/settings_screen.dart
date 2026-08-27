import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/placeholder_screen.dart';

/// الإعدادات — تُفتح من قائمة الدرج (Drawer).
/// TODO: أضف هون خيارات حقيقية (اللغة، الإشعارات، تغيير كلمة السر...).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionScaffold(
      title: 'الإعدادات',
      body: PlaceholderContent(
        title: 'الإعدادات',
        icon: Icons.settings_rounded,
        accentColor: AppColors.gray400,
        subtitle: 'رح تقدر من هون تتحكم بإعدادات حسابك وتفضيلاتك',
      ),
    );
  }
}
