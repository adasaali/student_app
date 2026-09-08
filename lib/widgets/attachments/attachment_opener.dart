import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/attachment_model.dart';
import '../../screens/pdf_preview_screen.dart';
import '../../screens/gallery_video_player_screen.dart';
import '../../theme/app_colors.dart';
import 'audio_message_player.dart';
import 'file_info_screen.dart';
import 'fullscreen_image_viewer.dart';

/// نقطة دخول موحّدة لفتح أي مرفق — بتقرر لحالها أي معاينة تفتح حسب
/// [Attachment.type]، كلها جوا التطبيق (ولا شي بيطلع لبرا):
///
/// - صورة  → [FullscreenImageViewer] (تكبير بالإصبع)
/// - فيديو → [GalleryVideoPlayerScreen] (نفس مشغّل فيديوهات المعرض)
/// - صوت   → مشغّل صوت بـ bottom sheet (نفس [AudioMessagePlayer] اللي
///           بالفقاعة، لاستخدامه من مكان مو شات — متل قائمة مرفقات مقرر)
/// - PDF   → [PdfPreviewScreen]
/// - Word / Excel / غيره → [FileInfoScreen] (بدون أي زر فتح خارجي)
void openAttachment(BuildContext context, Attachment attachment) {
  switch (attachment.type) {
    case AttachmentType.image:
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(imageUrl: attachment.url, title: attachment.fileName),
      ));
      return;

    case AttachmentType.video:
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GalleryVideoPlayerScreen(videoUrl: attachment.url, title: attachment.fileName),
      ));
      return;

    case AttachmentType.audio:
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _AudioPreviewSheet(attachment: attachment),
      );
      return;

    case AttachmentType.pdf:
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(fileUrl: attachment.url, title: attachment.fileName),
      ));
      return;

    case AttachmentType.word:
    case AttachmentType.excel:
    case AttachmentType.other:
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FileInfoScreen(attachment: attachment),
      ));
      return;
  }
}

class _AudioPreviewSheet extends StatelessWidget {
  final Attachment attachment;
  const _AudioPreviewSheet({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(attachment.icon, color: attachment.color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attachment.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AudioMessagePlayer(audioUrl: attachment.url),
            ],
          ),
        ),
      ),
    );
  }
}
