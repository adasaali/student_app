import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/attachment_model.dart';
import '../../theme/app_colors.dart';

/// شاشة معلومات ملف — لأي مرفق ما إله معاينة أصلية جوا التطبيق بعد
/// (Word / Excel / أنواع تانية). بتعرض بس أيقونة النوع + اسم الملف +
/// حجمه (لو معروف)، من دون أي زر "فتح خارج التطبيق" — التزاماً بإنه
/// كل شي لازم يضل جوا التطبيق.
class FileInfoScreen extends StatelessWidget {
  final Attachment attachment;

  const FileInfoScreen({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text('تفاصيل الملف', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: attachment.color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(attachment.icon, color: attachment.color, size: 44),
                ),
                const SizedBox(height: 20),
                Text(
                  attachment.fileName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.gray800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    _Chip(text: attachment.extensionLabel),
                    if (attachment.readableSize != null) _Chip(text: attachment.readableSize!),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'لا تتوفر معاينة داخل التطبيق لهذا النوع من الملفات بعد.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.gray500, fontWeight: FontWeight.w600, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray600)),
    );
  }
}
