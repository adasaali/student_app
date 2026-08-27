import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/chat_theme.dart';
import '../theme/sibling_palette.dart';
import '../providers/student_provider.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/chat_models.dart';
import 'chat_screen.dart';

String _relativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return 'قبل ${diff.inDays} يوم';
  return '${dt.day}/${dt.month}';
}

/// الرسائل — تُفتح من أيقونة الرسائل بأعلى الـ HomeShell.
/// بتعرض محادثة الشعبة الجماعية (مفتوحة لكل الطلاب) + المحادثة
/// الخاصة مع المشرف (تتكوّن تلقائياً بأول رسالة).
///
/// السيرفر (get_chat_conversations.php) هو يلي بيضمن وجود المحادثتين
/// وبيحسب عداد غير المقروء، فهون بس عرض + بث دوري (polling).
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final ChatService _chat;
  Stream<List<ChatConversation>>? _conversationsStream;
  int? _streamStudentId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chat = ChatService(context.read<ApiService>());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final student = provider.student;
    // 🔧 activeStudentId هو نفسه يلي بيمرّر لكل شاشة تانية (غياب/واجبات/
    // إعلانات...) بعد تبديل الحساب لأخ. provider.student نفسه بينحدّث
    // لبيانات الأخ لحظة التبديل، فـ studentId/palette تبعو صح تلقائياً؛
    // بس لازم نبعت activeStudentId صراحة لـ ChatService عشان يطلب
    // محادثات هالأخ بالتحديد من السيرفر (مش محادثات صاحب التوكن دايماً).
    final activeStudentId = provider.activeStudentId;
    final palette = SiblingPalette.forStudent(student?.studentName, gender: student?.gender, studentId: student?.studentId);

    if (student == null || student.sectionId == null) {
      return _MessagesScaffold(
        palette: palette,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تعذّر تحديد شعبتك حالياً، حاول لاحقاً',
              textAlign: TextAlign.center,
              style: ChatTheme.body(size: 13, color: ChatTheme.inkMuted, weight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    final studentId = student.studentId;

    if (_conversationsStream == null || _streamStudentId != activeStudentId) {
      _streamStudentId = activeStudentId;
      _conversationsStream = _chat.watchStudentConversations(targetStudentId: activeStudentId);
    }

    return _MessagesScaffold(
      palette: palette,
      body: StreamBuilder<List<ChatConversation>>(
        stream: _conversationsStream,
        builder: (context, snap) {
          if (snap.hasError && !snap.hasData) {
            // 🔧 مؤقت للتشخيص — هاد السطر بيطبع السبب الحقيقي وراء
            // "تعذّر تحميل المحادثات" بدل ما يضل مخفي عن المستخدم/المطوّر.
            // شوفي الـ Run console (أو Logcat) بـ Android Studio لحظة
            // ما يطلع الخطأ، ودوّري عسطر يبلش بـ "🔴 خطأ محادثات:".
            debugPrint('🔴 خطأ محادثات: ${snap.error}');
            return _ErrorState(
              palette: palette,
              onRetry: () => setState(() {
                _conversationsStream = _chat.watchStudentConversations(targetStudentId: activeStudentId);
              }),
            );
          }
          if (!snap.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: palette.primaryDark, strokeWidth: 2.6),
                  const SizedBox(height: 10),
                  Text('عم نجيب محادثاتك...', style: ChatTheme.body(size: 12, color: ChatTheme.inkMuted)),
                ],
              ),
            );
          }

          final list = snap.data!;
          ChatConversation? group;
          // 🔧 قبل هيك كان في محادثة خاصة وحدة بس (مشرف واحد مفترض).
          // هلق ممكن يكون في أكتر من مشرف على نفس الشعبة، فكل وحدة
          // منهم إلها محادثة خاصة مستقلة — بطاقة لكل وحدة.
          final privates = <ChatConversation>[];
          for (final c in list) {
            if (c.type == ConversationType.group) group = c;
            if (c.type == ConversationType.private) privates.add(c);
          }
          // ترتيب ثابت (الأحدث رسالة أولاً) حتى ما يترجرج ترتيب البطاقات
          // بين كل تحديث بولينغ.
          privates.sort((a, b) {
            final at = a.lastMessageAt;
            final bt = b.lastMessageAt;
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            children: [
              _ConversationCard(
                icon: Icons.groups_2_rounded,
                title: 'محادثة الشعبة',
                subtitle: group?.isLocked == true
                    ? 'مقفولة من المشرف حالياً'
                    : (group?.lastMessage ?? 'لا توجد رسائل بعد — كن أول من يكتب'),
                time: _relativeTime(group?.lastMessageAt),
                unread: group?.unreadCount ?? 0,
                locked: group?.isLocked ?? false,
                palette: palette,
                onTap: group == null
                    ? null
                    : () => _openChat(context, group!, studentId, activeStudentId, student.studentName, palette, activeStudentGender: student.gender),
              ),
              if (privates.isEmpty) ...[
                const SizedBox(height: 12),
                _ConversationCard(
                  icon: Icons.school_rounded,
                  title: 'مراسلة المشرف',
                  subtitle: 'ما في مشرف محدد لشعبتك حالياً',
                  time: '',
                  unread: 0,
                  locked: false,
                  palette: palette,
                  onTap: null,
                ),
              ] else
                for (final p in privates) ...[
                  const SizedBox(height: 12),
                  _ConversationCard(
                    icon: Icons.school_rounded,
                    title: 'مراسلة ${p.supervisorName ?? "المشرف"}',
                    subtitle: p.lastMessage ?? 'ابدأ محادثة خاصة مع المشرف',
                    time: _relativeTime(p.lastMessageAt),
                    unread: p.unreadCount,
                    locked: false,
                    palette: palette,
                    onTap: () => _openChat(context, p, studentId, activeStudentId, student.studentName, palette, activeStudentGender: student.gender),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }

  void _openChat(
      BuildContext context,
      ChatConversation conversation,
      int studentId,
      int? activeStudentId,
      String activeStudentName,
      SiblingPalette palette, {
        String? activeStudentGender,
      }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: conversation,
          chatService: _chat,
          currentStudentId: studentId,
          targetStudentId: activeStudentId,
          activeStudentName: activeStudentName,
          activeStudentGender: activeStudentGender,
        ),
      ),
    );
  }
}

class _MessagesScaffold extends StatelessWidget {
  final Widget body;
  final SiblingPalette palette;
  const _MessagesScaffold({required this.body, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatTheme.parchment,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 14, bottom: 20, right: 20, left: 20),
            decoration: BoxDecoration(
              color: palette.primaryDark,
              border: Border(bottom: BorderSide(color: palette.goldMain, width: 2)),
            ),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('الرسائل', style: ChatTheme.display(size: 20, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('محادثاتك مع الشعبة والمشرف',
                          style: ChatTheme.body(size: 11.5, color: palette.goldLight, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final SiblingPalette palette;
  final VoidCallback onRetry;
  const _ErrorState({required this.palette, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatSeal(
              size: 64,
              ringColor: ChatTheme.dangerBorder,
              fillColor: ChatTheme.dangerBg,
              child: Icon(Icons.wifi_off_rounded, size: 26, color: ChatTheme.danger),
            ),
            const SizedBox(height: 14),
            Text('تعذّر تحميل المحادثات', style: ChatTheme.display(size: 15, color: ChatTheme.ink)),
            const SizedBox(height: 5),
            Text('تأكد من اتصالك بالإنترنت وحاول مرة ثانية',
                textAlign: TextAlign.center,
                style: ChatTheme.body(size: 12.5, color: ChatTheme.inkMuted)),
            const SizedBox(height: 16),
            Material(
              color: palette.primaryDark,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onRetry,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 17, color: palette.goldLight),
                      const SizedBox(width: 7),
                      Text('إعادة المحاولة', style: ChatTheme.body(size: 13, weight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final int unread;
  final bool locked;
  final SiblingPalette palette;
  final VoidCallback? onTap;

  const _ConversationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    required this.locked,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final hasUnread = unread > 0;
    return Material(
      color: ChatTheme.parchmentCard,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasUnread ? palette.goldMain : ChatTheme.hairline, width: hasUnread ? 1.4 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ChatSeal(
                      size: 50,
                      ringColor: disabled ? ChatTheme.hairlineStrong : palette.goldMain,
                      fillColor: disabled ? ChatTheme.parchmentDeep : palette.primaryDark,
                      child: Icon(icon, size: 21, color: disabled ? ChatTheme.inkFaint : palette.goldLight),
                    ),
                    if (hasUnread)
                      Positioned(
                        top: -2,
                        left: -2,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.accentColor,
                            border: Border.all(color: ChatTheme.parchmentCard, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ChatTheme.display(
                                    size: 14.5, weight: hasUnread ? FontWeight.w800 : FontWeight.w700, color: ChatTheme.ink)),
                          ),
                          if (time.isNotEmpty)
                            Text(time,
                                style: ChatTheme.body(
                                    size: 10.5,
                                    color: hasUnread ? palette.primaryDark : ChatTheme.inkFaint,
                                    weight: hasUnread ? FontWeight.w700 : FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ChatTheme.body(
                                  color: locked ? ChatTheme.danger : ChatTheme.inkMuted,
                                  size: 12.5,
                                  weight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                )),
                          ),
                          const SizedBox(width: 6),
                          if (hasUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: palette.accentColor, borderRadius: BorderRadius.circular(20)),
                              child: Text('$unread',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          else if (!disabled)
                            Icon(Icons.chevron_left_rounded, color: ChatTheme.inkFaint, size: 20),
                        ],
                      ),
                    ],
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