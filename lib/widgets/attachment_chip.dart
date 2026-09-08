import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'attachment_preview_screen.dart';

/// 🆕 عرض مرفق واحد (بالشات أو بالمقررات) — صورة كمصغّرة قابلة للنقر،
/// وأي نوع تاني كبطاقة (أيقونة + اسم + حجم). النقر يفتح المعاينة
/// الموحّدة جوا التطبيق (AttachmentPreviewScreen) — أبداً لا يفتح شي لبرا.
class AttachmentChip extends StatelessWidget {
  final String fileUrl;
  final String fileName;
  final String? mimeType;
  final int? fileSize;
  final bool dense; // true = داخل فقاعة شات (أضيق)، false = بطاقة مقرر

  // 🆕 يُستخدمان فقط لتلوين مشغّل التسجيل الصوتي (زر التشغيل + الموجة)
  // بنفس هوية شاشة الشات (SiblingPalette) بدل لون ثابت. اختياريان حتى
  // ما ينكسر استخدام AttachmentChip بمكان تاني (بطاقات المقررات) بدون
  // ما يمررهم.
  final bool mine; // true = فقاعتي أنا (خلفية غامقة) → الأزرار بتنعكس
  final Color? accentColor;

  const AttachmentChip({
    super.key,
    required this.fileUrl,
    required this.fileName,
    this.mimeType,
    this.fileSize,
    this.dense = false,
    this.mine = false,
    this.accentColor,
  });

  String get _extension {
    final n = fileName.contains('.') ? fileName : fileUrl;
    return n.contains('.') ? n.split('.').last.toLowerCase().split('?').first : '';
  }

  bool get _isImage => (mimeType?.startsWith('image/') ?? false) || ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(_extension);
  bool get _isVideo => (mimeType?.startsWith('video/') ?? false) || ['mp4', 'mov', 'm4v', '3gp', 'webm'].contains(_extension);
  bool get _isAudio => (mimeType?.startsWith('audio/') ?? false) || ['m4a', 'mp3', 'wav', 'aac', 'ogg'].contains(_extension);
  bool get _isPdf => mimeType == 'application/pdf' || _extension == 'pdf';

  IconData get _icon {
    if (_isAudio) return Icons.audiotrack_rounded;
    if (_isPdf) return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx'].contains(_extension)) return Icons.description_rounded;
    if (['xls', 'xlsx'].contains(_extension)) return Icons.grid_on_rounded;
    if (['ppt', 'pptx'].contains(_extension)) return Icons.slideshow_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color get _iconColor {
    if (_isAudio) return Colors.redAccent;
    if (_isPdf) return const Color(0xFFDC2626);
    if (['doc', 'docx'].contains(_extension)) return const Color(0xFF2563EB);
    if (['xls', 'xlsx'].contains(_extension)) return const Color(0xFF059669);
    return AppColors.gray500;
  }

  String get _sizeLabel {
    if (fileSize == null || fileSize == 0) return '';
    final mb = fileSize! / 1024 / 1024;
    return mb >= 1 ? '${mb.toStringAsFixed(1)} MB' : '${(fileSize! / 1024).toStringAsFixed(0)} KB';
  }

  void _open(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AttachmentPreviewScreen(fileUrl: fileUrl, fileName: fileName, mimeType: mimeType),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return GestureDetector(
        onTap: () => _open(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            fileUrl,
            width: dense ? 180 : double.infinity,
            height: dense ? 180 : 160,
            fit: BoxFit.cover,
            loadingBuilder: (c, child, p) => p == null ? child : Container(
              width: dense ? 180 : double.infinity, height: dense ? 180 : 160,
              color: AppColors.gray100,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorBuilder: (c, e, s) => Container(
              width: dense ? 180 : double.infinity, height: dense ? 180 : 160,
              color: AppColors.gray100,
              child: const Icon(Icons.broken_image_rounded, color: AppColors.gray400),
            ),
          ),
        ),
      );
    }

    if (_isVideo) {
      return GestureDetector(
        onTap: () => _open(context),
        child: Container(
          width: dense ? 180 : double.infinity,
          height: dense ? 180 : 160,
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40)),
        ),
      );
    }

    // 🆕 صوت → مشغّل مضمّن بشكل واتساب (زر تشغيل + موجة + وقت)، بدون
    // فتح شاشة معاينة منفصلة — التشغيل بيصير بمكانه جوا الفقاعة نفسها.
    if (_isAudio) {
      return Container(
        width: dense ? 220 : double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: dense ? Colors.white.withOpacity(0.12) : AppColors.gray50,
          borderRadius: BorderRadius.circular(10),
          border: dense ? null : Border.all(color: AppColors.gray200),
        ),
        child: _VoiceMessagePlayer(
          key: ValueKey(fileUrl),
          fileUrl: fileUrl,
          mine: mine,
          accentColor: accentColor ?? AppColors.navy,
        ),
      );
    }

    // PDF/Word/أي ملف تاني → بطاقة أفقية (زي ما كانت).
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: dense ? 190 : double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: dense ? Colors.white.withOpacity(0.12) : AppColors.gray50,
          borderRadius: BorderRadius.circular(10),
          border: dense ? null : Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Icon(_icon, color: dense ? Colors.white : _iconColor, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: dense ? Colors.white : AppColors.gray800)),
                  if (_sizeLabel.isNotEmpty)
                    Text(_sizeLabel, style: GoogleFonts.cairo(fontSize: 10.5, color: dense ? Colors.white70 : AppColors.gray500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🆕 مشغّل تسجيل صوتي مضمّن (inline) بشكل مطابق لرسائل الصوت بواتساب:
/// زر تشغيل/إيقاف دائري + شريط "موجة" (شكلي — ما في بيانات أمبليتيود
/// فعلية من الملف) بيتلوّن حسب موقع التشغيل الحالي + عداد الوقت، وإمكانية
/// الضغط على أي نقطة بالموجة للقفز إليها (seek). لا يفتح أي شاشة/تطبيق
/// خارجي — التشغيل بالكامل جوا الفقاعة.
class _VoiceMessagePlayer extends StatefulWidget {
  final String fileUrl;
  final bool mine;
  final Color accentColor;

  const _VoiceMessagePlayer({
    super.key,
    required this.fileUrl,
    required this.mine,
    required this.accentColor,
  });

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  static const int _barCount = 27;
  static const List<double> _speeds = [1.0, 1.5, 2.0];

  final _player = AudioPlayer();
  late final List<double> _waveform;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _loading = false;
  bool _hadError = false;
  int _speedIndex = 0; // فهرس داخل _speeds — زر السرعة (1x/1.5x/2x) متل واتساب.

  @override
  void initState() {
    super.initState();
    _waveform = _generateWaveform();

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) async {
      await _player.seek(Duration.zero);
      if (mounted) setState(() { _isPlaying = false; _position = Duration.zero; });
    });

    // 🔧 نحمّل مصدر الملف فوراً (بدون تشغيل) حتى تظهر مدة التسجيل
    // مباشرة من أول ما تفتح الشات، متل واتساب بالضبط — مش لما يضغط
    // المستخدم زر التشغيل أول مرة بس.
    _player.setSourceUrl(widget.fileUrl).catchError((_) {
      if (mounted) setState(() => _hadError = true);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// موجة ثابتة شكلياً (مش من الملف الفعلي) — بس نفس الملف دايماً بيطلع
  /// إله نفس الشكل (seed = رابط الملف) بدل ما يتغيّر عشوائياً كل rebuild.
  List<double> _generateWaveform() {
    final rnd = Random(widget.fileUrl.hashCode);
    return List.generate(_barCount, (_) => 0.25 + rnd.nextDouble() * 0.75);
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }
    setState(() => _loading = true);
    try {
      await _player.resume();
    } catch (_) {
      if (mounted) setState(() => _hadError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _seekToRatio(double ratio) {
    if (_duration == Duration.zero) return;
    _player.seek(Duration(milliseconds: (_duration.inMilliseconds * ratio).round()));
  }

  /// دورة سرعة التشغيل 1x → 1.5x → 2x → 1x، بالضبط متل واتساب.
  Future<void> _cycleSpeed() async {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
    await _player.setPlaybackRate(_speeds[_speedIndex]);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final trackColor = widget.mine ? Colors.white.withOpacity(0.4) : AppColors.gray300;
    final playedColor = widget.mine ? Colors.white : widget.accentColor;
    final textColor = widget.mine ? Colors.white.withOpacity(0.85) : AppColors.gray600;
    final buttonBg = widget.mine ? Colors.white : widget.accentColor;
    final iconColor = widget.mine ? widget.accentColor : Colors.white;

    if (_hadError) {
      return Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text('تعذّر تحميل التسجيل الصوتي', style: GoogleFonts.cairo(fontSize: 11.5, color: textColor)),
        ],
      );
    }

    final played = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    final playedBars = (played * _barCount).round();

    // قبل أي تشغيل: منعرض مدة التسجيل الكاملة (متل واتساب). أثناء/بعد
    // التشغيل: منعرض الوقت الحالي.
    final displayed = (_isPlaying || _position > Duration.zero) ? _position : _duration;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: buttonBg, shape: BoxShape.circle),
            child: _loading
                ? Padding(
              padding: const EdgeInsets.all(9),
              child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
            )
                : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: iconColor, size: 19),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // الموجة + "الكرة" اللي بتمشي فوقها مع موقع التشغيل الحالي
              // (متل واتساب بالضبط)، مو بس تلوين الأعمدة.
              SizedBox(
                height: 22,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final ratio = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                        _seekToRatio(ratio);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List.generate(_barCount, (i) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  height: 20 * _waveform[i],
                                  decoration: BoxDecoration(
                                    color: i < playedBars ? playedColor : trackColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ),
                          Align(
                            // AlignmentDirectional (مو Alignment العادي) عشان
                            // تتبع اتجاه RTL نفسه يلي ماشي فيه الـRow (بار
                            // index 0 عالبداية = يمين بواجهتنا العربية)، وإلا
                            // كانت الكرة رح تتحرك بعكس اتجاه تلوين الموجة.
                            alignment: AlignmentDirectional(played * 2 - 1, 0),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: playedColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: playedColor.withOpacity(0.4), blurRadius: 3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _fmt(displayed),
                    style: GoogleFonts.cairo(fontSize: 10.5, color: textColor, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  // زر سرعة التشغيل (1x/1.5x/2x) — نفس فكرة واتساب تماماً.
                  GestureDetector(
                    onTap: _cycleSpeed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: trackColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_speeds[_speedIndex] == _speeds[_speedIndex].roundToDouble() ? _speeds[_speedIndex].toInt() : _speeds[_speedIndex]}x',
                        style: GoogleFonts.cairo(fontSize: 9.5, color: textColor, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // شارة مايك صغيرة (متل أفاتار الرسائل الصوتية بواتساب) بدل ما
        // نعرض أيقونة ملف عادية — بتأكد بصرياً إنها "رسالة صوتية" لا ملف.
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: buttonBg.withOpacity(widget.mine ? 0.9 : 1),
          ),
          child: Icon(Icons.mic_rounded, size: 13, color: iconColor),
        ),
      ],
    );
  }
}