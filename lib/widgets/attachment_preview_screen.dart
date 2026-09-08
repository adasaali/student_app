import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../screens/pdf_preview_screen.dart';
import '../theme/app_colors.dart';

/// 🆕 معاينة موحّدة داخل التطبيق لأي نوع مرفق (صورة/فيديو/صوت/PDF/
/// Word أو أي ملف آخر) — تُستخدم بالشات وبالمقررات. ما في أي فتح
/// لبرنامج/متصفح خارجي بأي مسار من مساراتها.
class AttachmentPreviewScreen extends StatelessWidget {
  final String fileUrl;
  final String fileName;
  final String? mimeType;

  const AttachmentPreviewScreen({
    super.key,
    required this.fileUrl,
    required this.fileName,
    this.mimeType,
  });

  String get _extension {
    final n = fileName.contains('.') ? fileName : fileUrl;
    final ext = n.contains('.') ? n.split('.').last.toLowerCase() : '';
    return ext.split('?').first;
  }

  bool get _isImage =>
      (mimeType?.startsWith('image/') ?? false) ||
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(_extension);

  bool get _isVideo =>
      (mimeType?.startsWith('video/') ?? false) ||
      ['mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv'].contains(_extension);

  bool get _isAudio =>
      (mimeType?.startsWith('audio/') ?? false) ||
      ['m4a', 'mp3', 'wav', 'aac', 'ogg'].contains(_extension);

  bool get _isPdf => mimeType == 'application/pdf' || _extension == 'pdf';

  @override
  Widget build(BuildContext context) {
    if (_isPdf) {
      // نفس شاشة معاينة PDF الموجودة أصلاً (أوراق العمل/المنهاج).
      return PdfPreviewScreen(fileUrl: fileUrl, title: fileName);
    }
    if (_isImage) return _ImagePreview(fileUrl: fileUrl, fileName: fileName);
    if (_isVideo) return _VideoPreview(fileUrl: fileUrl, fileName: fileName);
    if (_isAudio) return _AudioPreview(fileUrl: fileUrl, fileName: fileName);
    // أي نوع تاني (Word/Excel/PowerPoint/نص/إلخ) → عارض مستندات جوا
    // التطبيق عبر WebView (Google Docs Viewer) — يضل داخل التطبيق تماماً.
    return _DocumentPreview(fileUrl: fileUrl, fileName: fileName);
  }
}

class _PreviewScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Color backgroundColor;
  const _PreviewScaffold({required this.title, required this.child, this.backgroundColor = Colors.black});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
        body: child,
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String fileUrl;
  final String fileName;
  const _ImagePreview({required this.fileUrl, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return _PreviewScaffold(
      title: fileName,
      child: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.network(
            fileUrl,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: AppColors.gold);
            },
            errorBuilder: (context, error, stack) => const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  const _VideoPreview({required this.fileUrl, required this.fileName});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.fileUrl))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      }).catchError((_) {
        if (mounted) setState(() => _error = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PreviewScaffold(
      title: widget.fileName,
      child: Center(
        child: _error
            ? const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 48)
            : !_ready
                ? const CircularProgressIndicator(color: AppColors.gold)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller),
                        GestureDetector(
                          onTap: () => setState(() {
                            _controller.value.isPlaying ? _controller.pause() : _controller.play();
                          }),
                          child: AnimatedOpacity(
                            opacity: _controller.value.isPlaying ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 64),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _AudioPreview extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  const _AudioPreview({required this.fileUrl, required this.fileName});

  @override
  State<_AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<_AudioPreview> {
  final _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((p) => mounted ? setState(() => _position = p) : null);
    _player.onDurationChanged.listen((d) => mounted ? setState(() => _duration = d) : null);
    _player.onPlayerStateChanged.listen((s) => mounted ? setState(() => _isPlaying = s == PlayerState.playing) : null);
    _player.setSourceUrl(widget.fileUrl);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return _PreviewScaffold(
      title: widget.fileName,
      backgroundColor: AppColors.navy,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.audiotrack_rounded, color: AppColors.gold, size: 64),
              const SizedBox(height: 20),
              Slider(
                value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                max: _duration.inMilliseconds == 0 ? 1 : _duration.inMilliseconds.toDouble(),
                activeColor: AppColors.gold,
                inactiveColor: Colors.white24,
                onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(_position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(_fmt(_duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IconButton(
                iconSize: 56,
                color: AppColors.gold,
                icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                onPressed: () => _isPlaying ? _player.pause() : _player.resume(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentPreview extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  const _DocumentPreview({required this.fileUrl, required this.fileName});

  @override
  State<_DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<_DocumentPreview> {
  late final WebViewController _webController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final viewerUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.fileUrl)}';
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => mounted ? setState(() => _loading = false) : null,
      ))
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return _PreviewScaffold(
      title: widget.fileName,
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          WebViewWidget(controller: _webController),
          if (_loading) const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        ],
      ),
    );
  }
}
