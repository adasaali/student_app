import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/gallery_album.dart';
import '../providers/student_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'gallery_media_viewer_screen.dart';
import 'gallery_video_player_screen.dart';

/// تفاصيل ألبوم واحد بالمعرض — شبكة كل الصور والفيديوهات فيه.
/// الضغط على صورة يفتحها بعارض ملء الشاشة (مع باقي صور الألبوم).
/// الضغط على فيديو مرفوع فعليًا يفتحه بمشغّل داخلي (GalleryVideoPlayerScreen)،
/// أما فيديو خارجي (رابط يوتيوب مثلاً) فبيفتح ببرنامج خارجي (ما في
/// طريقة تشغّل رابط يوتيوب بمشغّل عادي جوا التطبيق).
class GalleryAlbumScreen extends StatefulWidget {
  final int albumId;
  final String title;

  const GalleryAlbumScreen({super.key, required this.albumId, required this.title});

  @override
  State<GalleryAlbumScreen> createState() => _GalleryAlbumScreenState();
}

class _GalleryAlbumScreenState extends State<GalleryAlbumScreen> {
  bool _loading = true;
  String? _error;
  GalleryAlbum? _album;

  String get _rootUrl => ApiService.baseUrl.replaceFirst(RegExp(r'api/?$'), '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final activeId = context.read<StudentProvider>().activeStudentId;
      final api = context.read<ApiService>();
      final album = await api.fetchGalleryAlbumDetail(widget.albumId, targetStudentId: activeId);
      if (!mounted) return;
      setState(() => _album = album);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تحميل الألبوم');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openImage(List<GalleryMediaItem> images, GalleryMediaItem tapped) {
    final urls = images.map((m) => m.resolvedUrl(_rootUrl)).whereType<String>().toList();
    final index = images.indexOf(tapped);
    if (urls.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryMediaViewerScreen(
          imageUrls: urls,
          initialIndex: index.clamp(0, urls.length - 1),
          title: widget.title,
        ),
      ),
    );
  }

  Future<void> _openVideo(GalleryMediaItem video) async {
    final url = video.resolvedUrl(_rootUrl);
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('رابط الفيديو غير صالح', style: GoogleFonts.cairo())),
        );
      }
      return;
    }

    // فيديو مرفوع فعليًا على السيرفر (ملف مباشر، is_external = false) —
    // بيتشغّل جوا التطبيق بمشغّل GalleryVideoPlayerScreen.
    if (!video.isExternal) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GalleryVideoPlayerScreen(videoUrl: url, title: widget.title),
        ),
      );
      return;
    }

    // فيديو خارجي (رابط يوتيوب مثلاً) — مو ملف مباشر، ما فيه طريقة
    // نشغّله بمشغّل عادي جوا التطبيق، فبيفتح ببرنامج/متصفح خارجي.
    await _openExternalVideo(url);
  }

  Future<void> _openExternalVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('رابط الفيديو غير صالح', style: GoogleFonts.cairo())),
        );
      }
      return;
    }

    // ⚠️ ما بنستخدم canLaunchUrl() قبل الفتح: مكتبة url_launcher بترجّعها
    // false بشكل خاطئ لروابط https سليمة 100% على أندرويد 11+ لو
    // AndroidManifest.xml ما فيه إعلان <queries> (قيود ظهور الحزم
    // Package Visibility). التوصية الرسمية بالمكتبة: نحاول launchUrl
    // مباشرة ونمسك أي خطأ فعلي بدل ما نعتمد على الفحص المسبق.
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الفيديو', style: GoogleFonts.cairo())),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الفيديو', style: GoogleFonts.cairo())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = _album?.media ?? const <GalleryMediaItem>[];
    final images = media.where((m) => m.isImage).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.navy),
          title: Text(widget.title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
        ),
        body: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: _load,
          child: _loading && _album == null
              ? const _CenteredLoader()
              : (_error != null && _album == null)
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : media.isEmpty
                      ? const _EmptyMedia()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 30),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: media.length,
                          itemBuilder: (context, i) {
                            final m = media[i];
                            final url = m.resolvedUrl(_rootUrl);
                            return GestureDetector(
                              onTap: () => m.isImage ? _openImage(images, m) : _openVideo(m),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (m.isImage && url != null)
                                      Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            color: AppColors.gray100,
                                            child: const Center(
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppColors.gray100,
                                          child: const Icon(Icons.broken_image_outlined, color: AppColors.gray400, size: 22),
                                        ),
                                      )
                                    else
                                      Container(
                                        color: AppColors.navy,
                                        child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 30),
                                      ),
                                    if (m.isVideo)
                                      const Positioned(
                                        bottom: 5,
                                        right: 5,
                                        child: Icon(Icons.videocam_rounded, color: Colors.white, size: 16),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();
  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator(color: AppColors.gold)),
        ],
      );
}

class _EmptyMedia extends StatelessWidget {
  const _EmptyMedia();
  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.photo_outlined, size: 52, color: AppColors.navy.withOpacity(0.2)),
          const SizedBox(height: 12),
          Center(
            child: Text('لا توجد صور أو فيديوهات بهذا الألبوم بعد', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray400, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 44),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray600, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
            child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
