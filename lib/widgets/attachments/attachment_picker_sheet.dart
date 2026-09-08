import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../theme/app_colors.dart';

/// ورقة اختيار مرفق — بتترسم من زر الإرفاق (📎) بالـ composer.
/// بترجع [File] محلي جاهز للرفع، أو null لو المستخدم لغى.
///
/// الاستخدام:
/// ```dart
/// final file = await showAttachmentPickerSheet(context);
/// if (file != null) { /* ارفعه عبر ApiService */ }
/// ```
Future<File?> showAttachmentPickerSheet(BuildContext context) {
  return showModalBottomSheet<File?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _AttachmentPickerSheet(),
  );
}

class _AttachmentPickerSheet extends StatelessWidget {
  const _AttachmentPickerSheet();

  Future<void> _pick(BuildContext context, Future<File?> Function() picker) async {
    try {
      final file = await picker();
      if (context.mounted) Navigator.of(context).pop(file);
    } catch (_) {
      if (context.mounted) Navigator.of(context).pop(null);
    }
  }

  Future<File?> _fromImagePicker(ImageSource source, {bool video = false}) async {
    final picker = ImagePicker();
    final XFile? x = video
        ? await picker.pickVideo(source: source, maxDuration: const Duration(minutes: 5))
        : await picker.pickImage(source: source, imageQuality: 85);
    return x == null ? null : File(x.path);
  }

  Future<File?> _fromFilePicker() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = result?.files.single.path;
    return path == null ? null : File(path);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              Text('إرفاق ملف', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Option(
                    icon: Icons.camera_alt_rounded,
                    label: 'كاميرا',
                    color: const Color(0xFF7C4DFF),
                    onTap: () => _pick(context, () => _fromImagePicker(ImageSource.camera)),
                  ),
                  _Option(
                    icon: Icons.image_rounded,
                    label: 'صورة',
                    color: const Color(0xFF00897B),
                    onTap: () => _pick(context, () => _fromImagePicker(ImageSource.gallery)),
                  ),
                  _Option(
                    icon: Icons.videocam_rounded,
                    label: 'فيديو',
                    color: const Color(0xFFE53935),
                    onTap: () => _pick(context, () => _fromImagePicker(ImageSource.gallery, video: true)),
                  ),
                  _Option(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'ملف',
                    color: const Color(0xFF1565C0),
                    onTap: () => _pick(context, _fromFilePicker),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Option({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.gray700)),
        ],
      ),
    );
  }
}
