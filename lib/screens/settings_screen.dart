import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/placeholder_screen.dart';
import 'change_password_screen.dart';

/// الإعدادات — تُفتح من قائمة الدرج (Drawer).
///
/// 🆕 كانت شاشة placeholder فاضية. هلق فيها فعليًا:
/// 1) تغيير كلمة السر — بتفتح [ChangePasswordScreen] بوضع اختياري
///    (isForced: false)، يعني معها زر رجوع وبترجع لهون بعد النجاح
///    بدل ما تنقل المستخدم لـHomeShell زي وضعها الإجباري بعد أول دخول.
/// 2) تفعيل الإشعارات — مفتاح (Switch) بيعكس صلاحية الإشعارات الفعلية
///    عند نظام التشغيل (عبر FirebaseMessaging.getNotificationSettings،
///    نفس الآلية يلي بتستخدمها NotificationService.init بـmain.dart).
///    ⚠️ مهم: أندرويد وiOS ما بيسمحوا لأي تطبيق يفتح نافذة صلاحية
///    الإشعارات أكتر من مرة وحدة برمجيًا — لو المستخدم رفضها قبل هيك
///    (أو بده يلغيها بعد ما وافق)، الطريقة الوحيدة إنه يفتح إعدادات
///    النظام يدويًا (عبر app_settings)، فمنوجهه لهناك بدل ما نحاول
///    نغيّرها مباشرة من جوا التطبيق.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  // null = لسا عم نتحقق من حالة الصلاحية الحالية عند فتح الشاشة.
  bool? _notificationsEnabled;
  bool _updatingNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshNotificationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // لو المستخدم راح لإعدادات النظام وبدّل الصلاحية يدويًا ثم رجع
  // للتطبيق، لازم نحدّث حالة المفتاح لتعكس القرار الفعلي يلي أخده.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotificationStatus();
    }
  }

  Future<void> _refreshNotificationStatus() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final enabled = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (mounted) setState(() => _notificationsEnabled = enabled);
    } catch (_) {
      // لو فشل التحقق لأي سبب، منسيب المفتاح بحالته الحالية بدل ما نكسر الشاشة.
    }
  }

  Future<void> _onToggleNotifications(bool value) async {
    setState(() => _updatingNotifications = true);
    try {
      final current = await FirebaseMessaging.instance.getNotificationSettings();

      if (current.authorizationStatus == AuthorizationStatus.notDetermined) {
        // أول مرة نطلب فيها الصلاحية فعليًا — نافذة النظام بتطلع مباشرة.
        final result = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        final enabled = result.authorizationStatus == AuthorizationStatus.authorized ||
            result.authorizationStatus == AuthorizationStatus.provisional;
        if (mounted) setState(() => _notificationsEnabled = enabled);
      } else {
        // الصلاحية اتحددت مسبقًا (مفعّلة أو مرفوضة) — النظام ما بيسمح
        // نعيد طلبها برمجيًا، فلازم يغيّرها المستخدم بنفسه من الإعدادات.
        await AppSettings.openAppSettings(type: AppSettingsType.notification);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('غيّر حالة الإشعارات من إعدادات النظام، وبترجع تتحدث هون تلقائيًا')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _updatingNotifications = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'الإعدادات',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSectionLabel('الحساب'),
          _SettingsTile(
            icon: Icons.lock_reset_rounded,
            iconColor: AppColors.navy,
            title: 'تغيير كلمة السر',
            subtitle: 'حدّد كلمة سر جديدة لحسابك',
            trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.gray400),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen(isForced: false)),
              );
            },
          ),
          const SizedBox(height: 20),
          _SettingsSectionLabel('الإشعارات'),
          _SettingsTile(
            icon: Icons.notifications_active_rounded,
            iconColor: AppColors.gold,
            title: 'تفعيل الإشعارات',
            subtitle: _notificationsEnabled == null
                ? 'جاري التحقق من الحالة...'
                : (_notificationsEnabled!
                    ? 'الإشعارات مفعّلة على هالجهاز'
                    : 'الإشعارات متوقفة — فعّلها حتى توصلك التنبيهات فورًا'),
            trailing: _updatingNotifications || _notificationsEnabled == null
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Switch(
                    value: _notificationsEnabled!,
                    activeColor: AppColors.gold,
                    onChanged: _onToggleNotifications,
                  ),
            onTap: (_updatingNotifications || _notificationsEnabled == null)
                ? null
                : () => _onToggleNotifications(!_notificationsEnabled!),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  final String label;
  const _SettingsSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 10),
      child: Text(
        label,
        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray500),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray200, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.gray500, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}