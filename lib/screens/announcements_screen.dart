import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/announcement_item.dart';
import '../models/announcement_comment.dart';
import '../providers/student_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/placeholder_screen.dart';

/// الإعلانات — أخبار وإعلانات إدارة المدرسة، تُفتح من الشاشة الرئيسية.
///
/// ⚠️ بيعتمد هالملف على إضافتين لازم تكونوا موجودين بـStudentProvider:
///   - `List<AnnouncementItem> announcements`
///   - `Future<void> fetchAnnouncements({int? studentId})`
/// وعلى إضافة بـApiService: `Future<List<AnnouncementItem>> getAnnouncements(...)`.
/// راجع الشرح المرفق بالمحادثة للسنيبت المطلوب لصقو هناك، ولثابت
/// baseUrl المستخدم تحت لبناء روابط الصور.
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: 'الإعلانات',
      body: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          final list = provider.announcements;
          final isLoading = provider.isLoadingAnnouncements;

          if (isLoading && list.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          if (list.isEmpty) {
            return RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () => provider.fetchAnnouncements(),
              child: ListView(
                children: const [
                  SizedBox(height: 60),
                  PlaceholderContent(
                    title: 'لا توجد إعلانات حالياً',
                    icon: Icons.campaign_rounded,
                    accentColor: AppColors.red,
                    subtitle: 'رح تظهر هون كل إعلانات وأخبار إدارة المدرسة أول ما توصل',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () => provider.fetchAnnouncements(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AnnouncementCard(item: list[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementItem item;

  const _AnnouncementCard({required this.item});

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
    if (diff.inDays < 7) return 'قبل ${diff.inDays} يوم';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openVideo(BuildContext context) async {
    final url = item.videoUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الرابط', style: GoogleFonts.cairo())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // baseUrl الحقيقي المستخدم بباقي طلبات التطبيق (ApiService.baseUrl
    // ينتهي بـ"/api/" — الصور مخزّنة خارج مجلد الـapi على مستوى الجذر،
    // فمنشيل جزء "api/" منه قبل ما نبني رابط الصورة).
    final baseUrl = ApiService.baseUrl.replaceFirst(RegExp(r'api/?$'), '');
    final imageUrl = item.imageUrl(baseUrl);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200, width: 1),
        boxShadow: [
          BoxShadow(color: AppColors.navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _relativeTime(item.createdAt),
                        style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.gray400, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (item.content != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                item.content!,
                style: GoogleFonts.cairo(fontSize: 13.5, color: AppColors.gray600, height: 1.6),
              ),
            ),

          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 180,
                    alignment: Alignment.center,
                    color: AppColors.gray100,
                    child: const CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: AppColors.gray100,
                  child: Icon(Icons.image_not_supported_rounded, color: AppColors.gray300, size: 28),
                ),
              ),
            ),

          if (item.videoUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: InkWell(
                onTap: () => _openVideo(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, color: AppColors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'مشاهدة الفيديو',
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.read<StudentProvider>().toggleAnnouncementLike(item.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          item.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                          color: item.isLiked ? AppColors.red : AppColors.gray400,
                        ),
                        const SizedBox(width: 6),
                        Text('${item.likeCount}', style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.gray500, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _CommentsSheet(announcementId: item.id, announcementTitle: item.title),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.mode_comment_outlined, size: 17, color: AppColors.gray400),
                        const SizedBox(width: 6),
                        Text('${item.commentCount}', style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.gray500, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// نافذة منبثقة (bottom sheet) لعرض تعليقات إعلان معيّن وإضافة تعليق
/// جديد — بستايل فقاعات محادثة بسيط (تعليقاتي يمين، تعليقات غيري يسار)
/// نفس روح شاشات المحادثة الموجودة أصلاً بالتطبيق.
class _CommentsSheet extends StatefulWidget {
  final int announcementId;
  final String announcementTitle;

  const _CommentsSheet({required this.announcementId, required this.announcementTitle});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AnnouncementComment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await context.read<StudentProvider>().fetchAnnouncementComments(widget.announcementId);
      if (!mounted) return;
      setState(() {
        _comments = result;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل التعليقات';
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final added = await context.read<StudentProvider>().addAnnouncementComment(widget.announcementId, text);
    if (!mounted) return;

    if (added != null) {
      setState(() {
        _comments = [..._comments, added];
        _controller.clear();
        _isSending = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } else {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال التعليق، حاول مرة أخرى', style: GoogleFonts.cairo())),
      );
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
    return 'قبل ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        height: mediaQuery.size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'التعليقات',
                      style: GoogleFonts.cairo(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.navy),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.gray400),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.gray200),
            Expanded(child: _buildBody()),
            const Divider(height: 1, color: AppColors.gray200),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray500)),
      );
    }
    if (_comments.isEmpty) {
      return Center(
        child: Text(
          'لا توجد تعليقات بعد — كن أول من يعلّق',
          style: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray400),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      itemCount: _comments.length,
      itemBuilder: (context, index) => _CommentBubble(comment: _comments[index], relativeTime: _relativeTime),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: GoogleFonts.cairo(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'اكتب تعليقك هنا...',
                  hintStyle: GoogleFonts.cairo(fontSize: 13, color: AppColors.gray400),
                  filled: true,
                  fillColor: AppColors.gray100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _isSending ? null : _send,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 19),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final AnnouncementComment comment;
  final String Function(DateTime) relativeTime;

  const _CommentBubble({required this.comment, required this.relativeTime});

  @override
  Widget build(BuildContext context) {
    final isMine = comment.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.gold : AppColors.gray100,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(16),
            topLeft: const Radius.circular(16),
            bottomRight: Radius.circular(isMine ? 4 : 16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  comment.authorName,
                  style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ),
            Text(
              comment.comment,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                color: isMine ? Colors.white : AppColors.gray600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              relativeTime(comment.createdAt),
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: isMine ? Colors.white.withOpacity(0.75) : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}