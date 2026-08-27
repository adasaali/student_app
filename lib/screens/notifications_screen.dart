import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';
import '../widgets/placeholder_screen.dart';
import '../providers/student_provider.dart';
import '../models/notification_item.dart';
import 'absence_screen.dart';
import 'homework_screen.dart';
import 'exams_screen.dart';
import 'finance_screen.dart';
import 'grades_reports_screen.dart';
import 'student_notes_screen.dart';
import 'announcements_screen.dart';
import 'exam_schedule_screen.dart';
import 'gallery_screen.dart';
import 'transportation_screen.dart';

/// الإشعارات — تُفتح من جرس الإشعارات بأعلى الـ HomeShell أو من الدرج.
/// بتعرض إشعارات كل الحسابات (الطالب الأساسي + كل إخوته) سوا بقائمة
/// وحدة، وبتفلترهم حسب الحساب لما تحب تشوف واحد لحاله. كل بطاقة
/// إشعار محدد عليها لمين هي (اسم الحساب صاحبها)، وبالضغط عليها بتاخدك
/// عالواجهة المرتبطة بنوع الإشعار — وإذا كان الإشعار لأخ غير الحساب
/// النشط هلق، بتبدّل تلقائياً لحسابه أول.
///
/// 🎨 التصميم الجديد: كل بطاقة إشعار ملوّنة بهوية **صاحبها** (نفس
/// SiblingPalette يلي محسوب من اسمه بباقي شاشات التطبيق) — مش لون
/// ثابت حسب النوع. الأيقونة لسا بتفرّق حسب النوع (غياب/واجب/مالية...)،
/// بس الخلفية والحدود والشارات كلها بهوية صاحب الإشعار. هيك بلمحة
/// وحدة تعرف إشعار مين وأنت عم تسكرول، حتى قبل ما تقرا اسمه.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// null = فلتر "الكل" (كل الحسابات سوا). أي قيمة تانية = id حساب محدد.
  int? _filterStudentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<StudentProvider>();
      await provider.fetchNotifications();
      // نعلّم كل الإشعارات (كل الحسابات) كمقروءة بعد ثانية من فتح الشاشة
      // (يعطي وقت يشوفهم المستخدم)
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) context.read<StudentProvider>().markNotificationsRead();
      });
    });
  }

  /// 🔀 تحويل الإشعار للشاشة المرتبطة بنوعه — وسّعناها لتغطي كل
  /// الشاشات الرئيسية بالتطبيق، مش الغياب بس.
  /// ⚠️ القيم هون (homework, exam, finance...) لازم تطابق بالضبط
  /// القيمة يلي السيرفر عم يخزّنها بعمود type بجدول الإشعارات. حالياً
  /// 'absence' هو المؤكد الوحيد (راجع تعليق NotificationItem.type) —
  /// لما تفعّل باقي الأنواع بالباك-إند، لازم تتأكد الأسماء متطابقة
  /// تماماً وإلا الإشعار بيضل يفتح جوا شاشة الإشعارات نفسها (fallback).
  Widget? _screenForType(String type) {
    switch (type) {
      case 'absence':
        return const AbsenceScreen();
      case 'homework':
        return const HomeworkScreen();
      case 'exam':
      case 'exams':
        return const ExamsScreen();
      case 'exam_schedule':
        return const ExamScheduleScreen();
      case 'finance':
        return const FinanceScreen();
      case 'grade':
      case 'grades':
        return const SectionScaffold(title: 'الدرجات والتقارير', body: GradesReportsScreen());
      case 'note':
      case 'student_note':
      case 'behavior_note':
        return const SectionScaffold(title: 'الملاحظات', body: StudentNotesScreen());
      case 'announcement':
        return const AnnouncementsScreen();
      case 'gallery':
        return const GalleryScreen();
      case 'transportation':
        return const TransportationScreen();
      default:
        return null; // إعلان عام غير مصنّف — يضل ضمن شاشة الإشعارات نفسها
    }
  }

  Future<void> _openNotification(NotificationItem item) async {
    final provider = context.read<StudentProvider>();
    final ownerId = item.ownerId;
    final currentId = provider.activeStudentId ?? provider.primaryStudentId;

    if (ownerId != null && ownerId != currentId) {
      await provider.switchToAccount(ownerId);
    }

    final screen = _screenForType(item.type);
    if (screen != null && mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'الإشعارات',
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          final accounts = provider.accounts;
          final showFilters = accounts.length > 1;

          final list = _filterStudentId == null
              ? provider.notifications
              : provider.notificationsForAccount(_filterStudentId!);

          Widget body;

          if (provider.isLoadingNotifications && list.isEmpty) {
            body = const Center(child: CircularProgressIndicator(color: AppColors.gold));
          } else if (list.isEmpty) {
            body = RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () => provider.fetchNotifications(studentId: _filterStudentId),
              child: ListView(
                children: const [
                  SizedBox(height: 60),
                  PlaceholderContent(
                    title: 'لا توجد إشعارات حالياً',
                    icon: Icons.notifications_none_rounded,
                    accentColor: AppColors.red,
                    subtitle: 'رح تظهر هون كل إشعارات المدرسة والإدارة أول ما توصل',
                  ),
                ],
              ),
            );
          } else {
            final rows = _buildGroupedRows(list);
            body = RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () => provider.fetchNotifications(studentId: _filterStudentId),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  if (row is String) {
                    return Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 4 : 18, bottom: 10),
                      child: Text(
                        row,
                        style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.gray500),
                      ),
                    );
                  }
                  final item = row as NotificationItem;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NotificationCard(
                      item: item,
                      showOwner: showFilters,
                      onTap: () => _openNotification(item),
                    ),
                  );
                },
              ),
            );
          }

          return Column(
            children: [
              if (showFilters)
                _AccountFilterBar(
                  accounts: accounts,
                  selectedId: _filterStudentId,
                  onSelect: (id) => setState(() => _filterStudentId = id),
                ),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }

  /// يحوّل قائمة الإشعارات المسطّحة لقائمة فيها عناوين تجميع حسب
  /// التاريخ (اليوم / أمس / أقدم) — لمسة تنظيم بصري بدل قائمة طويلة
  /// بلا تصنيف. بيفترض إن [items] مرتبة تنازلياً حسب التاريخ (الأحدث
  /// أول) متل ما بترجعها الـprovider عادة.
  List<Object> _buildGroupedRows(List<NotificationItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final rows = <Object>[];
    String? lastLabel;

    for (final item in items) {
      final d = item.createdAt;
      final day = DateTime(d.year, d.month, d.day);
      final String label;
      if (day == today) {
        label = 'اليوم';
      } else if (day == yesterday) {
        label = 'أمس';
      } else {
        label = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }

      if (label != lastLabel) {
        rows.add(label);
        lastLabel = label;
      }
      rows.add(item);
    }
    return rows;
  }
}

/// شريط فلتر أفقي: "الكل" + كل حساب على حدا مع عداد غير مقروئه —
/// كل حساب هلق بلونه الخاص (SiblingPalette) عشان ينسجم بصرياً مع
/// بطاقات الإشعارات وشريط تبديل الحسابات بأعلى الشاشة الرئيسية.
class _AccountFilterBar extends StatelessWidget {
  final List<AccountInfo> accounts;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  const _AccountFilterBar({
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        children: [
          _FilterChip(
            label: 'الكل',
            count: accounts.fold(0, (sum, a) => sum + a.unreadCount),
            selected: selectedId == null,
            color: AppColors.navy,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...accounts.map(
                (a) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label: a.name,
                count: a.unreadCount,
                selected: selectedId == a.studentId,
                color: SiblingPalette.forStudent(a.name, gender: a.gender, studentId: a.studentId).primaryDark,
                onTap: () => onSelect(a.studentId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.gray700,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.25) : AppColors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// بطاقة إشعار — ملوّنة بهوية صاحبها (SiblingPalette)، والأيقونة
/// بتفرّق حسب النوع. شريط ملوّن جانبي + أيقونة بخلفية متدرّجة + شارة
/// اسم الحساب كلها بنفس هوية صاحب الإشعار.
class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final bool showOwner;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.showOwner, required this.onTap});

  IconData _iconFor(String type) {
    switch (type) {
      case 'absence':
        return Icons.event_busy_rounded;
      case 'homework':
        return Icons.edit_note_rounded;
      case 'exam':
      case 'exams':
      case 'exam_schedule':
        return Icons.fact_check_rounded;
      case 'finance':
        return Icons.account_balance_wallet_rounded;
      case 'grade':
      case 'grades':
        return Icons.assessment_rounded;
      case 'note':
      case 'student_note':
        return Icons.note_alt_rounded;
      case 'gallery':
        return Icons.photo_library_rounded;
      case 'transportation':
        return Icons.directions_bus_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
    if (diff.inDays < 7) return 'قبل ${diff.inDays} يوم';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 لون البطاقة بالكامل مبني على هوية صاحب الإشعار، مش نوعه.
    final palette = SiblingPalette.forStudent(item.ownerName ?? '', gender: item.ownerGender, studentId: item.ownerId);
    final icon = _iconFor(item.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: item.isRead ? AppColors.white : palette.primaryDark.withOpacity(0.035),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isRead ? AppColors.gray200 : palette.primaryDark.withOpacity(0.22),
              width: item.isRead ? 1 : 1.3,
            ),
            boxShadow: [
              BoxShadow(color: palette.primaryDark.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // شريط جانبي بلون صاحب الإشعار — أول شي بتحسّه العين
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: palette.primaryDark,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [palette.primaryDark, palette.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: palette.primaryDark.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Icon(icon, color: AppColors.white, size: 21),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.navy),
                                    ),
                                  ),
                                  if (!item.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 6, top: 3),
                                      decoration: BoxDecoration(color: palette.goldMain, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.message,
                                style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray600, height: 1.5),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (showOwner && (item.ownerName ?? '').isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: palette.primaryDark.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.person_rounded, size: 11, color: palette.primaryDark),
                                          const SizedBox(width: 3),
                                          Text(
                                            item.ownerName!,
                                            style: GoogleFonts.cairo(fontSize: 10.5, color: palette.primaryDark, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    _relativeTime(item.createdAt),
                                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.gray400, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.gray300),
                                ],
                              ),
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
        ),
      ),
    );
  }
}