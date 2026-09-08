import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_colors.dart';

/// عارض صورة بملء الشاشة مع إمكانية التكبير بالإصبع (pinch to zoom).
/// يفتح من [openAttachment] لأي مرفق صورة، بالشات أو بالمقررات.
class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;

  const FullscreenImageViewer({super.key, required this.imageUrl, this.title = 'صورة'});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const CircularProgressIndicator(color: AppColors.gold),
              errorWidget: (context, url, error) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white38, size: 48),
                  const SizedBox(height: 10),
                  Text('تعذر تحميل الصورة', style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
