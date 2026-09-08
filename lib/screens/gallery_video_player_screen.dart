import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';

/// مشغّل فيديو جوا التطبيق (ملء الشاشة) — لفيديوهات مرفوعة فعليًا
/// على السيرفر (ملف mp4 مباشر). ⚠️ ما بيشتغل لروابط خارجية زي يوتيوب
/// (هاي لازم تفتح ببرنامج خارجي، راجع GalleryAlbumScreen._openVideo).
class GalleryVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const GalleryVideoPlayerScreen({super.key, required this.videoUrl, required this.title});

  @override
  State<GalleryVideoPlayerScreen> createState() => _GalleryVideoPlayerScreenState();
}

class _GalleryVideoPlayerScreenState extends State<GalleryVideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _showControls = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..addListener(() => setState(() {}))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = _controller.value.isInitialized;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: Stack(
              children: [
                // ── الفيديو نفسه ──────────────────────────────────
                Center(
                  child: _hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.white38, size: 48),
                            const SizedBox(height: 10),
                            Text('تعذر تحميل الفيديو', style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12.5)),
                          ],
                        )
                      : isInitialized
                          ? AspectRatio(
                              aspectRatio: _controller.value.aspectRatio == 0 ? 16 / 9 : _controller.value.aspectRatio,
                              child: VideoPlayer(_controller),
                            )
                          : const CircularProgressIndicator(color: AppColors.gold),
                ),

                // ── زر تشغيل/إيقاف بالمنتصف ───────────────────────
                if (isInitialized && !_hasError && _showControls)
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                        child: Icon(
                          _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),

                // ── شريط علوي: إغلاق + العنوان ────────────────────
                if (_showControls)
                  Positioned(
                    top: 0,
                    right: 0,
                    left: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── شريط سفلي: التقدّم والوقت ─────────────────────
                if (isInitialized && !_hasError && _showControls)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            padding: EdgeInsets.zero,
                            colors: const VideoProgressColors(
                              playedColor: AppColors.gold,
                              bufferedColor: Colors.white30,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                _formatDuration(_controller.value.position),
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                _formatDuration(_controller.value.duration),
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
