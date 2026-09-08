import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/gallery_album.dart';
import '../providers/student_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'gallery_album_screen.dart';

/// المعرض — ألبومات صور وفيديوهات فعاليات وأنشطة المدرسة، مربوطة
/// بـ StudentProvider.fetchGalleryAlbums() (نفس نمط WorksheetsScreen
/// بالضبط: didChangeDependencies بيراقب activeStudentId ويعيد الجلب
/// تلقائياً عند تبديل الحساب لأخ).
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int? _loadedForStudentId;
  bool _initialized = false;

  String get _rootUrl => ApiService.baseUrl.replaceFirst(RegExp(r'api/?$'), '');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeId = context.watch<StudentProvider>().activeStudentId;
    if (!_initialized || _loadedForStudentId != activeId) {
      _initialized = true;
      _loadedForStudentId = activeId;
      context.read<StudentProvider>().fetchGalleryAlbums();
    }
  }

  void _openAlbum(GalleryAlbum album) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryAlbumScreen(albumId: album.id, title: album.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final albums = provider.galleryAlbums;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.navy),
          title: Text('المعرض', style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy)),
        ),
        body: RefreshIndicator(
          color: AppColors.red,
          onRefresh: () => provider.fetchGalleryAlbums(),
          child: (provider.isLoadingGallery && albums.isEmpty)
              ? const _CenteredLoader()
              : (provider.galleryError != null && albums.isEmpty)
                  ? _ErrorView(message: provider.galleryError!, onRetry: () => provider.fetchGalleryAlbums())
                  : albums.isEmpty
                      ? const _EmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.86,
                          ),
                          itemCount: albums.length,
                          itemBuilder: (context, i) {
                            final a = albums[i];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(milliseconds: 250 + i * 60),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(offset: Offset(0, (1 - value) * 16), child: child),
                              ),
                              child: _AlbumCard(album: a, rootUrl: _rootUrl, onTap: () => _openAlbum(a)),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final GalleryAlbum album;
  final String rootUrl;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.rootUrl, required this.onTap});

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = album.resolvedCoverUrl(rootUrl);
    final isVideoCover = album.coverType == 'video';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl != null && !isVideoCover)
                      Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: AppColors.gray100,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.gray100,
                          child: const Icon(Icons.image_outlined, size: 30, color: AppColors.gray400),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.gray100,
                        child: Icon(
                          isVideoCover ? Icons.videocam_rounded : Icons.photo_library_outlined,
                          size: 32,
                          color: AppColors.gray400,
                        ),
                      ),
                    if (isVideoCover)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                      ),
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_rounded, color: Colors.white, size: 11),
                            const SizedBox(width: 4),
                            Text('${album.mediaCount}', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy)),
                  const SizedBox(height: 3),
                  Text(_formatDate(album.createdAt), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.gray400, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        const SizedBox(height: 70),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(28)),
            child: const Icon(Icons.photo_library_rounded, color: AppColors.red, size: 42),
          ),
        ),
        const SizedBox(height: 24),
        Center(child: Text('ألبوم الصور', style: GoogleFonts.cairo(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.navy))),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'رح تظهر هون صور فعاليات وأنشطة المدرسة أول ما تنضاف',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray500, height: 1.6),
          ),
        ),
      ],
    );
  }
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
