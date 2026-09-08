import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// عارض صور بشاشة كاملة — يفتح من GalleryAlbumScreen عند الضغط على أي
/// صورة بالألبوم. تكبير/تصغير بالقرص (Pinch-to-zoom) وتنقّل بالسحب
/// بين كل صور الألبوم، مع عدّاد الموقع الحالي بالأعلى.
class GalleryMediaViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String title;

  const GalleryMediaViewerScreen({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    required this.title,
  });

  @override
  State<GalleryMediaViewerScreen> createState() => _GalleryMediaViewerScreenState();
}

class _GalleryMediaViewerScreenState extends State<GalleryMediaViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      widget.imageUrls[i],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2.4),
                        );
                      },
                      errorBuilder: (_, __, ___) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                          const SizedBox(height: 10),
                          Text('تعذر تحميل الصورة', style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SafeArea(
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
                    if (widget.imageUrls.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '${_index + 1} / ${widget.imageUrls.length}',
                          style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
