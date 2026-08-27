import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../theme/sibling_palette.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentProvider>();
      if (provider.student == null && !provider.isLoading) {
        provider.fetchCoreData();
      }
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor(String studentName, {String? gender, int? studentId}) {
    return SiblingPalette.forStudent(studentName, gender: gender, studentId: studentId).primaryDark;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentProvider>(context);

    if (provider.isLoading && provider.student == null) {
      return const _ProfileSkeleton();
    }
    if (provider.error != null && provider.student == null) {
      return _EmptyProfile(message: provider.error!, onRetry: () => provider.fetchCoreData());
    }
    if (provider.student == null) {
      return _EmptyProfile(message: 'لا توجد بيانات', onRetry: () => provider.fetchCoreData());
    }

    final student = provider.student!;
    final fields = student.profileFields;
    final primaryColor = _getPrimaryColor(student.studentName, gender: student.gender, studentId: student.studentId);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 120),
                child: Column(
                  children: [
                    _SectionCard(
                      title: 'البيانات الشخصية',
                      icon: Icons.badge_rounded,
                      themeColor: primaryColor,
                      fields: _pick(fields, [
                        'معرف الطالب', 'الاسم الكامل', 'تاريخ الميلاد', 'مكان الميلاد',
                        'السجل المدني', 'كود الطالب', 'محافظة الأصل',
                      ]),
                    ),
                    _SectionCard(
                      title: 'معلومات العائلة',
                      icon: Icons.family_restroom_rounded,
                      themeColor: primaryColor,
                      fields: _pick(fields, [
                        'اسم الأب', 'اسم الجد', 'اسم الأم',
                        'رقم هاتف الأب', 'رقم هاتف الأم', 'عمل الأب', 'عمل الأم',
                      ]),
                    ),
                    _SectionCard(
                      title: 'العنوان',
                      icon: Icons.location_on_rounded,
                      themeColor: primaryColor,
                      fields: _pick(fields, [
                        'المنطقة', 'الشارع', 'رقم المبنى', 'رقم الطابق',
                        'رقم الشقة', 'ملاحظات العنوان', 'العنوان التفصيلي',
                      ]),
                    ),
                    _SectionCard(
                      title: 'الخدمات والمالية',
                      icon: Icons.verified_user_rounded,
                      themeColor: primaryColor,
                      fields: _pick(fields, [
                        'النقل', 'حالة الدفع', 'ملاحظات', 'حالة التدقيق',
                        'الصف', 'الشعبة', 'الموجه', 'المدرسة السابقة', 'تاريخ التسجيل', 'نوع الطالب',
                      ]),
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

  Map<String, String?> _pick(Map<String, String?> all, List<String> keys) {
    final m = <String, String?>{};
    for (final k in keys) {
      if (all.containsKey(k)) m[k] = all[k];
    }
    return m;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color themeColor;
  final Map<String, String?> fields;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.themeColor,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final visible = fields.entries
        .where((e) => (e.value ?? '-').trim().isNotEmpty && e.value != '-' && e.value != 'null')
        .toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: themeColor, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: visible.map((e) => _InfoRow(label: e.key, value: e.value ?? '-')).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _EmptyProfile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.person_off_outlined, color: Color(0xFF94A3B8), size: 36),
            ),
            const SizedBox(height: 20),
            Text('لا توجد بيانات', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF64748B))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(height: 180, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 20),
          Container(height: 180, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(24))),
          const SizedBox(height: 20),
          Container(height: 180, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(24))),
        ],
      ),
    );
  }
}