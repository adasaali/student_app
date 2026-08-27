import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/student_provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';

class _CurriculumFile {
  final String title;
  final String type; // pdf, video, link
  final String size;

  const _CurriculumFile({required this.title, required this.type, required this.size});

  IconData get icon {
    switch (type) {
      case 'video':
        return Icons.play_circle_fill_rounded;
      case 'link':
        return Icons.link_rounded;
      default:
        return Icons.picture_as_pdf_rounded;
    }
  }
}

class _Subject {
  final String name;
  final IconData icon;
  final Color color;
  final int unitsCount;
  final List<_CurriculumFile> files;

  const _Subject({
    required this.name,
    required this.icon,
    required this.color,
    required this.unitsCount,
    required this.files,
  });
}

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // TODO: استبدال هالقائمة بربط حقيقي مع StudentProvider أو نداء API خاص
  // بجلب المنهاج الرسمي المعتمد حسب صف الطالب فعلياً من السيرفر.
  late final List<_Subject> _subjects = [
    _Subject(name: 'الرياضيات', icon: Icons.calculate_rounded, color: const Color(0xFF2563EB), unitsCount: 8, files: const [
      _CurriculumFile(title: 'الوحدة الأولى - الأعداد', type: 'pdf', size: '2.4 MB'),
      _CurriculumFile(title: 'شرح مرئي - المعادلات', type: 'video', size: '18 د'),
      _CurriculumFile(title: 'الوحدة الثانية - الهندسة', type: 'pdf', size: '3.1 MB'),
    ]),
    _Subject(name: 'اللغة العربية', icon: Icons.menu_book_rounded, color: const Color(0xFF059669), unitsCount: 6, files: const [
      _CurriculumFile(title: 'كتاب النصوص', type: 'pdf', size: '4.0 MB'),
      _CurriculumFile(title: 'قواعد النحو', type: 'pdf', size: '1.8 MB'),
    ]),
    _Subject(name: 'اللغة الإنجليزية', icon: Icons.translate_rounded, color: const Color(0xFF9333EA), unitsCount: 7, files: const [
      _CurriculumFile(title: 'Student Book', type: 'pdf', size: '5.2 MB'),
      _CurriculumFile(title: 'Grammar Guide', type: 'pdf', size: '2.0 MB'),
    ]),
    _Subject(name: 'العلوم', icon: Icons.science_rounded, color: const Color(0xFFD97706), unitsCount: 9, files: const [
      _CurriculumFile(title: 'الوحدة - الكائنات الحية', type: 'pdf', size: '3.6 MB'),
      _CurriculumFile(title: 'تجربة مخبرية', type: 'video', size: '12 د'),
    ]),
    _Subject(name: 'التربية الإسلامية', icon: Icons.mosque_rounded, color: const Color(0xFF0D9488), unitsCount: 5, files: const [
      _CurriculumFile(title: 'كتاب التربية الإسلامية', type: 'pdf', size: '2.9 MB'),
    ]),
    _Subject(name: 'الدراسات الاجتماعية', icon: Icons.public_rounded, color: const Color(0xFFDC2626), unitsCount: 6, files: const [
      _CurriculumFile(title: 'الوحدة - الجغرافيا', type: 'pdf', size: '3.3 MB'),
      _CurriculumFile(title: 'خرائط تفاعلية', type: 'link', size: 'رابط'),
    ]),
  ];

  List<_Subject> get _filtered => _query.isEmpty
      ? _subjects
      : _subjects.where((s) => s.name.contains(_query)).toList();

  Map<String, Color> _palette(String name, {String? gender, int? studentId}) {
    final p = SiblingPalette.forStudent(name, gender: gender, studentId: studentId);
    return {'primary': p.primaryDark, 'light': p.primaryLight ?? p.primaryDark.withOpacity(0.8), 'gold': p.goldMain};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeStudent = context.watch<StudentProvider>().student;
    final studentName = activeStudent?.studentName ?? '';
    final palette = _palette(studentName, gender: activeStudent?.gender, studentId: activeStudent?.studentId);
    final primary = palette['primary']!;
    final light = palette['light']!;
    final gold = palette['gold']!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(primary, light, gold)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(width: 4, height: 18, decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 8),
                    Text('المواد الدراسية', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
              sliver: _filtered.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState(primary))
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final subject = _filtered[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + index * 60),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(offset: Offset(0, (1 - value) * 18), child: child),
                      ),
                      child: _buildSubjectTile(subject, primary),
                    );
                  },
                  childCount: _filtered.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary, Color light, Color gold) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [primary, light]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: -35, left: -25, child: _decorCircle(120, gold.withOpacity(0.08))),
            Positioned(bottom: -45, right: -20, child: _decorCircle(100, Colors.white.withOpacity(0.05))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _GlassBackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(width: 12),
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(13)),
                      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المنهاج الرسمي', style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('المعتمد من وزارة التربية والتعليم', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      style: GoogleFonts.cairo(fontSize: 13.5, color: Colors.white, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن مادة...',
                        hintStyle: GoogleFonts.cairo(fontSize: 13.5, color: Colors.white.withOpacity(0.55)),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7), size: 21),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectTile(_Subject subject, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: subject.color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
          collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
          leading: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [subject.color, subject.color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(subject.icon, color: Colors.white, size: 24),
          ),
          title: Text(subject.name, style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          subtitle: Text('${subject.unitsCount} وحدات دراسية', style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.gray400)),
          children: subject.files.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: subject.color.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(f.icon, color: subject.color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f.title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155)))),
                  Text(f.size, style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.gray400)),
                  const SizedBox(width: 8),
                  Icon(Icons.file_download_outlined, color: subject.color, size: 19),
                ],
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: primary.withOpacity(0.25)),
          const SizedBox(height: 12),
          Text('لا توجد نتائج', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray400)),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
