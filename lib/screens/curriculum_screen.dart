import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/curriculum_item.dart';
import '../providers/student_provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';
import 'pdf_preview_screen.dart';

/// 🆕 المنهاج الرسمي — مربوطة بالسيرفر فعلياً عبر
/// StudentProvider.fetchCurriculum() (get_curriculum.php، مفلترة على
/// صف الحساب النشط) — بدل القائمة الوهمية الثابتة يلي كانت هون قبل.
/// نفس نمط WorksheetsScreen بالضبط (didChangeDependencies بيراقب
/// activeStudentId ويعيد الجلب تلقائياً عند تبديل الحساب).
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  int? _loadedForStudentId;
  bool _initialized = false;

  // تدوير على مجموعة ألوان ثابتة لكل مادة (حسب اسمها) — بديل عن
  // الألوان المخصصة يدوياً لكل مادة يلي كانت بالقائمة الوهمية القديمة.
  static const List<Color> _subjectPalette = [
    Color(0xFF2563EB), Color(0xFF059669), Color(0xFF9333EA),
    Color(0xFFD97706), Color(0xFF0D9488), Color(0xFFDC2626),
    Color(0xFF7C3AED), Color(0xFF0891B2),
  ];

  Color _colorForSubject(String name) => _subjectPalette[name.hashCode.abs() % _subjectPalette.length];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeId = context.watch<StudentProvider>().activeStudentId;
    if (!_initialized || _loadedForStudentId != activeId) {
      _initialized = true;
      _loadedForStudentId = activeId;
      context.read<StudentProvider>().fetchCurriculum();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, Color> _palette(String name, {String? gender, int? studentId}) {
    final p = SiblingPalette.forStudent(name, gender: gender, studentId: studentId);
    return {'primary': p.primaryDark, 'light': p.primaryLight ?? p.primaryDark.withOpacity(0.8), 'gold': p.goldMain};
  }

  /// يجمّع قائمة الملفات المسطّحة القادمة من السيرفر حسب المادة —
  /// نفس المادة قد يكون إلها أكثر من ملف (فصل أول/فصل ثاني...الخ).
  Map<String, List<CurriculumItem>> _groupBySubject(List<CurriculumItem> items) {
    final map = <String, List<CurriculumItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.subjectName, () => []).add(item);
    }
    return map;
  }

  Future<void> _openFile(BuildContext context, CurriculumItem file) async {
    final url = file.fileUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد ملف مرفق', style: GoogleFonts.cairo())),
      );
      return;
    }

    if (file.fileExtension == 'pdf') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(fileUrl: url, title: file.title),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الملف', style: GoogleFonts.cairo())),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final activeStudent = provider.student;
    final studentName = activeStudent?.studentName ?? '';
    final palette = _palette(studentName, gender: activeStudent?.gender, studentId: activeStudent?.studentId);
    final primary = palette['primary']!;
    final light = palette['light']!;
    final gold = palette['gold']!;

    final grouped = _groupBySubject(provider.curriculum);
    final subjectNames = grouped.keys.where((name) => _query.isEmpty || name.contains(_query)).toList()..sort();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: RefreshIndicator(
          color: primary,
          onRefresh: () => provider.fetchCurriculum(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(primary, light, gold)),
              if (provider.isLoadingCurriculum && provider.curriculum.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                )
              else if (provider.curriculumError != null && provider.curriculum.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorView(
                    message: provider.curriculumError!,
                    onRetry: () => provider.fetchCurriculum(),
                  ),
                )
              else ...[
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
                    sliver: subjectNames.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyState(primary))
                        : SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final subjectName = subjectNames[index];
                          final files = grouped[subjectName]!;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 300 + index * 60),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Transform.translate(offset: Offset(0, (1 - value) * 18), child: child),
                            ),
                            child: _buildSubjectTile(subjectName, files, _colorForSubject(subjectName)),
                          );
                        },
                        childCount: subjectNames.length,
                      ),
                    ),
                  ),
                ],
            ],
          ),
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

  Widget _buildSubjectTile(String subjectName, List<CurriculumItem> files, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 5))],
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
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
          ),
          title: Text(subjectName, style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B))),
          subtitle: Text('${files.length} ${files.length == 1 ? "ملف" : "ملفات"}', style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.gray400)),
          children: files.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openFile(context, f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f.title, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF334155)))),
                    Text(f.fileSizeLabel, style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.gray400)),
                    const SizedBox(width: 8),
                    Icon(Icons.file_download_outlined, color: color, size: 19),
                  ],
                ),
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
          Icon(Icons.menu_book_outlined, size: 56, color: primary.withOpacity(0.25)),
          const SizedBox(height: 12),
          Text(
            _query.isEmpty ? 'لا يوجد منهاج مرفوع لصفك حالياً' : 'لا توجد نتائج',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray400),
          ),
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 13.5, color: AppColors.gray600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
