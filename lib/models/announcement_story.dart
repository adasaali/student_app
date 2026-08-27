import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// نموذج مبسّط لإعلان/"ستوري" يظهر بأعلى الصفحة الرئيسية.
/// ⚠️ بيانات تجريبية (Mock) حالياً — بدّل [mockAnnouncementStories]
/// ببيانات حقيقية من StudentProvider/ApiService بمجرد ما يتوفر
/// endpoint للإعلانات (عنوان، نص، وربما صورة بدل الأيقونة).
class AnnouncementStory {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final bool seen;

  const AnnouncementStory({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    this.seen = false,
  });
}

const List<AnnouncementStory> mockAnnouncementStories = [
  AnnouncementStory(
    id: '1',
    title: 'بدء التسجيل',
    body: 'بدء التسجيل للفصل الدراسي الثاني اعتباراً من الأحد القادم، يرجى مراجعة الإدارة لاستكمال الأوراق المطلوبة.',
    icon: Icons.how_to_reg_rounded,
    color: AppColors.gold,
  ),
  AnnouncementStory(
    id: '2',
    title: 'رحلة مدرسية',
    body: 'تنظّم المدرسة رحلة تعليمية لطلاب الصفوف العليا الأسبوع القادم، التفاصيل الكاملة عند المرشد الصفي.',
    icon: Icons.hiking_rounded,
    color: AppColors.navy,
  ),
  AnnouncementStory(
    id: '3',
    title: 'إجازة رسمية',
    body: 'تعلن إدارة المدرسة عن إجازة رسمية يوم الخميس القادم بمناسبة عطلة وطنية، ويُستأنف الدوام يوم الأحد.',
    icon: Icons.beach_access_rounded,
    color: AppColors.red,
  ),
  AnnouncementStory(
    id: '4',
    title: 'اجتماع أولياء الأمور',
    body: 'يسر إدارة المدرسة دعوتكم لاجتماع أولياء الأمور الفصلي لمناقشة المستوى الدراسي والخطط القادمة.',
    icon: Icons.groups_rounded,
    color: AppColors.navyLight,
    seen: true,
  ),
];
