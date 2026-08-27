import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/worksheet_item.dart';
import '../providers/student_provider.dart';
import '../theme/app_colors.dart';
import '../theme/sibling_palette.dart';
import 'pdf_preview_screen.dart';

/// أوراق العمل — تُعرض هون أوراق العمل الحقيقية المشارَكة من قِبل
/// الأدمن رقم 10 (عبر لوحة أوراق العمل → get_worksheets.php) لصف
/// الطالب النشط حالياً. مربوطة بـ StudentProvider.fetchWorksheets()
/// (نفس نمط StudentNotesScreen بالضبط: didChangeDependencies بيراقب
/// activeStudentId ويعيد الجلب تلقائياً عند تبديل الحساب).
class WorksheetsScreen extends StatefulWidget {
  const WorksheetsScreen({super.key});

  @override
  State<WorksheetsScreen> createState() => _WorksheetsScreenState();
}

class _WorksheetsScreenState extends State<WorksheetsScreen> {
  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  int? _loadedForStudentId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeId = context.watch<StudentProvider>().activeStudentId;
    if (!_initialized || _loadedForStudentId != activeId) {
      _initialized = true;
      _loadedForStudentId = activeId;
      context.read<StudentProvider>().fetchWorksheets();
    }
  }

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  Map<String, Color> _palette(String name, {String? gender, int? studentId}) {
    final p = SiblingPalette.forStudent(name, gender: gender, studentId: studentId);
    return {'primary': p.primaryDark, 'light': p.primaryLight ?? p.primaryDark.withOpacity(0.8), 'gold': p.goldMain};
  }

  IconData _iconForExtension(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _openFile(BuildContext context, WorksheetItem sheet) async {
    final url = sheet.fileUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد ملف مرفق بهالورقة', style: GoogleFonts.cairo())),
      );
      return;
    }

    // ملفات PDF بتتفتح بمعاينة شاشة كاملة جوا التطبيق نفسه.
    // أي نوع ملف تاني (صور، Word، Excel...) بيضل يفتح ببرنامج خارجي
    // متل ما كان قبل.
    if (sheet.fileExtension == 'pdf') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(fileUrl: url, title: sheet.worksheetName),
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

    final worksheets = provider.worksheets;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: RefreshIndicator(
          color: primary,
          onRefresh: () => provider.fetchWorksheets(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(primary, light, gold, worksheets.length)),
              if (provider.isLoadingWorksheets && worksheets.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                )
              else if (provider.worksheetsError != null && worksheets.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorView(
                    message: provider.worksheetsError!,
                    onRetry: () => provider.fetchWorksheets(),
                  ),
                )
              else if (worksheets.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(primary),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final sheet = worksheets[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 300 + index * 60),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(offset: Offset(0, (1 - value) * 18), child: child),
                          ),
                          child: _buildWorksheetCard(sheet),
                        );
                      },
                      childCount: worksheets.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary, Color light, Color gold, int total) {
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
                      child: const Icon(Icons.description_rounded, color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Text('أوراق العمل', style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: Row(
                      children: [
                        Text('$total', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(width: 8),
                        Text('ورقة عمل متاحة', style: GoogleFonts.cairo(fontSize: 12.5, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600)),
                      ],
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

  Widget _buildWorksheetCard(WorksheetItem sheet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openFile(context, sheet),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Icon(_iconForExtension(sheet.fileExtension), color: AppColors.gold, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sheet.worksheetName, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.navy)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(_formatDate(sheet.createdAt), style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.gray400)),
                      if (sheet.gradeName != null) ...[
                        const SizedBox(width: 8),
                        Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gray400)),
                        const SizedBox(width: 8),
                        Text(sheet.gradeName!, style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.gray400)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.file_download_outlined, color: AppColors.gold, size: 19),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 56, color: primary.withOpacity(0.25)),
            const SizedBox(height: 12),
            Text('لا توجد أوراق عمل حالياً', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray400)),
            const SizedBox(height: 6),
            Text(
              'رح تظهر هون أوراق العمل أول ما تُشارَك',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.gray400, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ],
        ),
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
