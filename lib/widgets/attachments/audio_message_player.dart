import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../theme/app_colors.dart';

/// مشغّل صوت مضمّن — يترسم جوا فقاعة الشات مباشرة (مو شاشة منفصلة)
/// لرسائل صوتية أو أي مرفق صوتي. يدعم تشغيل/إيقاف مؤقت + شريط تقدّم
/// قابل للسحب + عرض الوقت الحالي/الكلي.
///
/// [isMine] بيلوّن الودجت حسب إذا الرسالة مبعوتة مني أو مستلمة —
/// نفس منطق تلوين فقاعات الشات العادية بـ chat_screen.dart.
class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final bool isMine;

  const AudioMessagePlayer({super.key, required this.audioUrl, this.isMine = false});

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();

  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_hasError) {
      setState(() {
        _hasError = false;
      });
    }
    try {
      if (_state == PlayerState.playing) {
        await _player.pause();
      } else {
        setState(() => _isLoading = true);
        await _player.play(UrlSource(widget.audioUrl));
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isMine ? AppColors.navy : AppColors.gray800;
    final accent = widget.isMine ? AppColors.navy : AppColors.gold;
    final isPlaying = _state == PlayerState.playing;
    final total = _duration.inMilliseconds > 0 ? _duration : const Duration(seconds: 1);
    final progress = (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return SizedBox(
      width: 210,
      child: Row(
        children: [
          GestureDetector(
            onTap: _isLoading ? null : _toggle,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: accent.withOpacity(0.15), shape: BoxShape.circle),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                    )
                  : Icon(
                      _hasError
                          ? Icons.error_outline_rounded
                          : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      color: accent,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: accent,
                    inactiveTrackColor: accent.withOpacity(0.2),
                    thumbColor: accent,
                  ),
                  child: Slider(
                    value: progress,
                    onChanged: _duration.inMilliseconds == 0
                        ? null
                        : (v) {
                            final target = Duration(milliseconds: (v * _duration.inMilliseconds).round());
                            _player.seek(target);
                          },
                  ),
                ),
                Text(
                  _hasError ? 'تعذر تشغيل الملف الصوتي' : '${_fmt(_position)} / ${_fmt(_duration)}',
                  style: GoogleFonts.cairo(fontSize: 10.5, color: fg.withOpacity(0.65), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
