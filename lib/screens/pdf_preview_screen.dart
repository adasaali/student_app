import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// معاينة PDF بشاشة كاملة جوا التطبيق — بتفتح من WorksheetsScreen (أو
/// أي شاشة تانية بدها تعرض ملف PDF) بدل ما تفتح الملف ببرنامج خارجي.
///
/// ⚠️ flutter_pdfview (عكس Syncfusion) بيعرض بس من ملف محلي، مش من
/// رابط مباشر — فمنحمّل الملف أول لمجلد temp (عبر Dio + path_provider،
/// الاثنين أصلاً من deps المشروع) وبعدين منعرضه بـ PDFView.
class PdfPreviewScreen extends StatefulWidget {
  final String fileUrl;
  final String title;

  const PdfPreviewScreen({super.key, required this.fileUrl, required this.title});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final Dio _dio = Dio();

  String? _localPath;
  bool _isDownloading = true;
  bool _hasError = false;

  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadFile();
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
    });
    try {
      final dir = await getTemporaryDirectory();
      final safeName = 'worksheet_${widget.fileUrl.hashCode}.pdf';
      final savePath = '${dir.path}/$safeName';
      final file = File(savePath);

      // لو الملف محمّل مسبقاً بنفس المسار (زيارة سابقة لنفس الرابط)
      // ما داعي نعيد التحميل.
      if (!(await file.exists()) || (await file.length()) == 0) {
        await _dio.download(widget.fileUrl, savePath);
      }

      if (!mounted) return;
      setState(() {
        _localPath = savePath;
        _isDownloading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isDownloading = false;
      });
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.fileUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الملف', style: GoogleFonts.cairo())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          actions: [
            if (_totalPages > 0 && !_hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'فتح خارج التطبيق',
              onPressed: _openExternally,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isDownloading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_hasError || _localPath == null) {
      return _buildErrorView();
    }
    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      fitPolicy: FitPolicy.BOTH,
      onRender: (pages) {
        setState(() => _totalPages = pages ?? 0);
      },
      onPageChanged: (page, total) {
        setState(() => _currentPage = page ?? 0);
      },
      onError: (error) {
        setState(() => _hasError = true);
      },
      onPageError: (page, error) {
        setState(() => _hasError = true);
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              'تعذر تحميل الملف داخل التطبيق',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _downloadFile,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)),
                  child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openExternally,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text('فتح خارج التطبيق', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.navy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
