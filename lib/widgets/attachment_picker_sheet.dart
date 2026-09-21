import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_colors.dart';

/// 🆕 نتيجة اختيار مرفق: الملف المحلي + نوعه (يحدد شكل المعاينة والحقل
/// اللي بينبعت فيه للسيرفر). 'file' = أي نوع تاني (PDF/Word/إلخ).
enum AttachmentKind { image, video, audio, file }

class PickedAttachment {
  final File file;
  final AttachmentKind kind;
  const PickedAttachment(this.file, this.kind);
}

/// شيت اختيار مرفق موحّد (يُستخدم بالشات وبإضافة مقرر جديد) — صورة من
/// المعرض/الكاميرا، فيديو، تسجيل صوتي مباشر، أو أي ملف (PDF/Word/إلخ).
/// ما في أي فتح لتطبيق خارجي — التسجيل الصوتي نفسه صاير جوا الشيت.
Future<PickedAttachment?> showAttachmentPickerSheet(BuildContext context) {
  return showModalBottomSheet<PickedAttachment>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AttachmentPickerSheet(),
  );
}

class _AttachmentPickerSheet extends StatefulWidget {
  const _AttachmentPickerSheet();

  @override
  State<_AttachmentPickerSheet> createState() => _AttachmentPickerSheetState();
}

class _AttachmentPickerSheetState extends State<_AttachmentPickerSheet> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  DateTime? _recordStartedAt;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  String? _errorMsg;
  bool _errorOpensSettings = false;

  // نعرض الخطأ داخل الشيت نفسه (الـ SnackBar بيظهر ورا الشيت المنبثق).
  void _showMsg(String msg, {bool openSettings = false}) {
    if (!mounted) return;
    setState(() {
      _errorMsg = msg;
      _errorOpensSettings = openSettings;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (picked != null && mounted) {
        Navigator.pop(context, PickedAttachment(File(picked.path), AttachmentKind.image));
      }
    } catch (_) {
      _showMsg(
        source == ImageSource.camera
            ? 'تعذّر فتح الكاميرا — تأكد من السماح بالوصول من الإعدادات'
            : 'تعذّر فتح مكتبة الصور — تأكد من السماح بالوصول من الإعدادات',
        openSettings: true,
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked != null && mounted) {
        Navigator.pop(context, PickedAttachment(File(picked.path), AttachmentKind.video));
      }
    } catch (_) {
      _showMsg('تعذّر اختيار الفيديو', openSettings: true);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      final path = result?.files.single.path;
      if (path != null && mounted) {
        Navigator.pop(context, PickedAttachment(File(path), AttachmentKind.file));
      }
    } catch (_) {
      _showMsg('تعذّر اختيار الملف');
    }
  }

  Future<void> _startRecording() async {
    try {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        _showMsg('تحتاج صلاحية الميكروفون للتسجيل — فعّلها من الإعدادات', openSettings: true);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      if (!mounted) {
        await _recorder.stop();
        return;
      }
      setState(() {
        _isRecording = true;
        _recordStartedAt = DateTime.now();
        _recordDuration = Duration.zero;
      });
      _tickRecordDuration();
    } catch (_) {
      _showMsg('تعذّر بدء التسجيل الصوتي، حاول مرة أخرى');
    }
  }

  void _tickRecordDuration() async {
    while (_isRecording && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording || !mounted) return;
      setState(() => _recordDuration = DateTime.now().difference(_recordStartedAt!));
    }
  }

  Future<void> _stopRecording({required bool keep}) async {
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }
    if (mounted) setState(() => _isRecording = false);
    if (!keep || path == null) {
      if (path != null) {
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
      return;
    }
    if (mounted) {
      Navigator.pop(context, PickedAttachment(File(path), AttachmentKind.audio));
    }
  }

  String _durationLabel(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _isRecording ? _buildRecordingView() : _buildOptionsGrid(),
        ),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 16),
        Text('إرفاق ملف', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy)),
        const SizedBox(height: 16),
        if (_errorMsg != null) ...[
          Text(
            _errorMsg!,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.red, fontWeight: FontWeight.w600),
          ),
          if (_errorOpensSettings)
            TextButton(
              onPressed: () => AppSettings.openAppSettings(),
              child: Text('فتح الإعدادات', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Option(icon: Icons.photo_library_rounded, label: 'صورة', color: AppColors.gold, onTap: () => _pickImage(ImageSource.gallery)),
            _Option(icon: Icons.camera_alt_rounded, label: 'كاميرا', color: AppColors.navy, onTap: () => _pickImage(ImageSource.camera)),
            _Option(icon: Icons.videocam_rounded, label: 'فيديو', color: Colors.deepPurple, onTap: _pickVideo),
            _Option(icon: Icons.mic_rounded, label: 'تسجيل صوتي', color: Colors.redAccent, onTap: _startRecording),
            _Option(icon: Icons.insert_drive_file_rounded, label: 'ملف', color: Colors.teal, onTap: _pickFile),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        Container(
          width: 64, height: 64,
          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 14),
        Text(_durationLabel(_recordDuration), style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(height: 4),
        Text('جاري التسجيل...', style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.gray500)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => _stopRecording(keep: false),
              icon: const Icon(Icons.close_rounded, color: AppColors.red),
              label: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.red, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _stopRecording(keep: true),
              icon: const Icon(Icons.check_rounded),
              label: Text('إرسال', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
            ),
          ],
        ),
      ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray700)),
        ],
      ),
    );
  }
}