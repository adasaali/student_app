import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../theme/app_colors.dart';

/// شريط تسجيل صوتي — بيظهر مكان صندوق الكتابة العادي بالـ composer
/// وقت المستخدم يضغط زر المايك. عند الإرسال بيرجع مسار الملف المسجّل
/// عبر [onSend]، وعند الإلغاء بيمسح الملف المؤقت وبيرجع composer العادي.
class VoiceRecordBar extends StatefulWidget {
  final void Function(String filePath, Duration duration) onSend;
  final VoidCallback onCancel;

  const VoiceRecordBar({super.key, required this.onSend, required this.onCancel});

  @override
  State<VoiceRecordBar> createState() => _VoiceRecordBarState();
}

class _VoiceRecordBarState extends State<VoiceRecordBar> {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  String? _path;
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) setState(() => _hasError = true);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      _path = path;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
      if (mounted) setState(() => _isReady = true);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    try {
      final path = await _recorder.stop();
      final file = File(path ?? _path ?? '');
      if (await file.exists()) await file.delete();
    } catch (_) {}
    widget.onCancel();
  }

  Future<void> _confirmSend() async {
    _timer?.cancel();
    try {
      final path = await _recorder.stop();
      if (path == null) {
        widget.onCancel();
        return;
      }
      widget.onSend(path, _elapsed);
    } catch (_) {
      widget.onCancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'ما قدرنا نوصل للمايك — تأكد من صلاحية التسجيل',
                style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.red, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(onPressed: widget.onCancel, child: Text('إغلاق', style: GoogleFonts.cairo())),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          GestureDetector(
            onTap: _cancel,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 22),
            ),
          ),
          const SizedBox(width: 6),
          _isReady
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  builder: (context, v, child) => Opacity(opacity: v, child: child),
                  child: const Icon(Icons.fiber_manual_record_rounded, color: AppColors.red, size: 14),
                )
              : const SizedBox(
                  width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red)),
          const SizedBox(width: 8),
          Text(
            _fmt(_elapsed),
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gray700),
          ),
          const Spacer(),
          Text(
            'سجّل رسالتك الصوتية...',
            style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.gray400, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _isReady ? _confirmSend : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: AppColors.navy, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
