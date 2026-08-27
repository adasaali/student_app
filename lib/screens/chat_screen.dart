import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/chat_models.dart';
import '../services/chat_service.dart';
import '../theme/chat_theme.dart';
import '../theme/sibling_palette.dart';

const List<String> _arabicMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

String _formatClock(DateTime? dt) {
  if (dt == null) return '';
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'م' : 'ص';
  return '$h:$m $period';
}

String _formatDaySeparator(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'اليوم';
  if (diff == 1) return 'أمس';
  return '${dt.day} ${_arabicMonths[dt.month - 1]}';
}

class ChatScreen extends StatefulWidget {
  final ChatConversation conversation;
  final ChatService chatService;
  final int currentStudentId; // لتحديد أي رسالة "مني" (بدل Firebase uid سابقاً)
  final String? activeStudentName; // لتلوين الشاشة حسب الأخ النشط (SiblingPalette)
  final String? activeStudentGender; // 'male'/'female' - نفس الغرض، لون دقيق بدل تخمين الاسم
  // 🔧 لازم نمررها لكل نداء بـ chatService (مو بس لجلب لائحة المحادثات) —
  // السيرفر بيتحقق من صاحب التوكن الفعلي إذا كنا مبدّلين لأخ.
  final int? targetStudentId;
  const ChatScreen({
    super.key,
    required this.conversation,
    required this.chatService,
    required this.currentStudentId,
    this.activeStudentName,
    this.activeStudentGender,
    this.targetStudentId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late ChatConversation _conversation; // بننحدّث لحظياً من الـ stream
  bool _sending = false;

  // 🔧 قبل هيك كان في jumpTo(maxScrollExtent) عالبناء (build) كل مرة الـ
  // StreamBuilder ينحدّث فيها — وبما إنو في polling كل 3 ثواني (شوف
  // chat_service.dart)، كان عم ينزل المستخدم لتحت غصباً عنو وهو عم يقرأ
  // رسائل قديمة، حتى لو ما في رسالة جديدة أصلاً. هلق منتحقق:
  // 1) أول تحميل للمحادثة → ننزل لتحت مرة وحدة.
  // 2) بعد هيك → ننزل بس إذا كان المستخدم أصلاً قريب من آخر المحادثة
  //    (يعني ما رجع يقرأ رسائل قديمة)، أو إذا عدد الرسائل زاد (رسالة جديدة
  //    وصلت أو أنا بعتت وحدة) وهو عند آخر شي.
  bool _didInitialScroll = false;
  bool _userNearBottom = true;
  int _lastMessageCount = 0;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // "قريب من تحت" يعني أقل من 80 بكسل عن الآخر — هامش بسيط.
    _userNearBottom = (pos.maxScrollExtent - pos.pixels) < 80;
  }

  SiblingPalette get _palette => SiblingPalette.forStudent(
    widget.activeStudentName,
    gender: widget.activeStudentGender,
    studentId: widget.currentStudentId,
  );

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    widget.chatService.markRead(_conversation.id, targetStudentId: widget.targetStudentId);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _conversation.type == ConversationType.private || !_conversation.isLocked;

  void _insertEmoji(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    final cursor = selection.start >= 0 ? selection.start : text.length;
    final newText = text.replaceRange(cursor, cursor, emoji);
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + emoji.length),
    );
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty || _sending || !_canSend) return;
    setState(() => _sending = true);
    try {
      await widget.chatService.sendMessage(
        conversationId: _conversation.id,
        text: text,
        targetStudentId: widget.targetStudentId,
      );
      _textController.clear();
    } catch (e) {
      if (mounted) {
        // 🔧 قبل هيك كانت الرسالة ثابتة "تعذّر إرسال الرسالة" بغض النظر
        // عن السبب الحقيقي (403 محادثة مش تبعك، 404 مش موجودة، خطأ
        // سيرفر...). هلق منعرض نص الخطأ الفعلي القادم من السيرفر
        // (ApiException.message) عشان نعرف السبب الحقيقي مباشرة من
        // الشاشة نفسها بدون ما نحتاج نفتح Logcat.
        final reason = e is ApiException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: ChatTheme.danger,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text('تعذّر إرسال الرسالة: $reason', style: ChatTheme.body(color: Colors.white, weight: FontWeight.w700)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = _conversation.type == ConversationType.group;
    final title = isGroup ? (_conversation.sectionName ?? 'الشعبة') : (_conversation.supervisorName ?? 'المشرف');
    final subtitle = isGroup ? 'محادثة جماعية' : 'محادثة خاصة';

    return Scaffold(
      backgroundColor: ChatTheme.parchment,
      body: Column(
        children: [
          _ChatHeader(
            title: title,
            subtitle: subtitle,
            icon: isGroup ? Icons.groups_2_rounded : Icons.school_rounded,
            palette: _palette,
          ),
          if (isGroup && _conversation.isLocked)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: ChatTheme.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ChatTheme.dangerBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, size: 16, color: ChatTheme.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'المشرف قفل المحادثة الجماعية حالياً — بس فيك تراسله عالخاص',
                      style: ChatTheme.body(color: ChatTheme.danger, weight: FontWeight.w700, size: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              color: ChatTheme.parchment,
              child: StreamBuilder<List<ChatMessage>>(
                stream: widget.chatService.watchMessages(_conversation.id, targetStudentId: widget.targetStudentId),
                builder: (context, snap) {
                  if (snap.hasError && !snap.hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 30, color: ChatTheme.danger),
                            const SizedBox(height: 10),
                            Text('تعذّر تحميل الرسائل', style: ChatTheme.display(size: 14.5, color: ChatTheme.ink)),
                            const SizedBox(height: 4),
                            Text('تأكد من اتصالك وحاول مرة ثانية',
                                style: ChatTheme.body(size: 12, color: ChatTheme.inkMuted)),
                          ],
                        ),
                      ),
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _palette.primaryDark, strokeWidth: 2.6),
                          const SizedBox(height: 10),
                          Text('عم نجيب الرسائل...', style: ChatTheme.body(size: 12, color: ChatTheme.inkMuted)),
                        ],
                      ),
                    );
                  }
                  final messages = snap.data ?? [];
                  if (messages.isEmpty) {
                    return _EmptyChat(palette: _palette);
                  }
                  final isFirstLoad = !_didInitialScroll;
                  final hasNewMessages = messages.length != _lastMessageCount;
                  final shouldAutoScroll = isFirstLoad || (hasNewMessages && _userNearBottom);
                  _lastMessageCount = messages.length;
                  if (shouldAutoScroll) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        _didInitialScroll = true;
                        _userNearBottom = true;
                      }
                    });
                  }

                  final items = <Widget>[];
                  DateTime? lastDay;
                  for (var i = 0; i < messages.length; i++) {
                    final m = messages[i];
                    final mine = m.senderType == 'student' && m.senderId == widget.currentStudentId;
                    if (m.createdAt != null) {
                      final day = DateTime(m.createdAt!.year, m.createdAt!.month, m.createdAt!.day);
                      if (lastDay == null || day != lastDay) {
                        items.add(_DateChip(label: _formatDaySeparator(m.createdAt!)));
                        lastDay = day;
                      }
                    }
                    final showTail = i == messages.length - 1 ||
                        messages[i + 1].senderId != m.senderId ||
                        messages[i + 1].senderType != m.senderType;
                    items.add(_MessageBubble(
                      message: m,
                      mine: mine,
                      showSenderName: isGroup && !mine,
                      showTail: showTail,
                      palette: _palette,
                    ));
                  }

                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                    children: items,
                  );
                },
              ),
            ),
          ),
          if (_canSend)
            _ComposerBar(
              controller: _textController,
              sending: _sending,
              onSend: _send,
              onEmoji: _insertEmoji,
              palette: _palette,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: ChatTheme.parchmentCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block_rounded, size: 15, color: ChatTheme.inkMuted),
                  const SizedBox(width: 6),
                  Text(
                    'الكتابة معطّلة — المحادثة مقفولة من المشرف',
                    textAlign: TextAlign.center,
                    style: ChatTheme.body(size: 12.5, color: ChatTheme.inkMuted, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final SiblingPalette palette;
  const _ChatHeader({required this.title, required this.subtitle, required this.icon, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 16, right: 10, left: 6),
      decoration: BoxDecoration(
        color: palette.primaryDark,
        border: Border(bottom: BorderSide(color: palette.goldMain, width: 2)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ChatSeal(
            size: 42,
            ringColor: palette.goldMain,
            fillColor: Colors.white.withOpacity(0.08),
            child: Icon(icon, color: palette.goldLight, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChatTheme.display(size: 16, color: Colors.white)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: ChatTheme.body(size: 11, color: palette.goldLight, weight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: ChatTheme.parchmentCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ChatTheme.hairlineStrong),
        ),
        child: Text(label, style: ChatTheme.body(size: 11, color: ChatTheme.inkMuted, weight: FontWeight.w700)),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final SiblingPalette palette;
  const _EmptyChat({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatSeal(
            size: 76,
            ringColor: palette.goldMain,
            fillColor: ChatTheme.parchmentDeep,
            ringWidth: 1.6,
            child: Icon(Icons.forum_outlined, size: 30, color: palette.primaryDark),
          ),
          const SizedBox(height: 16),
          Text('لا رسائل بعد', style: ChatTheme.display(size: 15.5, color: ChatTheme.ink)),
          const SizedBox(height: 5),
          Text('ابعت أول رسالة وابدأ المحادثة',
              style: ChatTheme.body(size: 12.5, color: ChatTheme.inkMuted)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final bool showSenderName;
  final bool showTail;
  final SiblingPalette palette;
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.showSenderName,
    required this.showTail,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? palette.primaryDark : ChatTheme.parchmentCard,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : (showTail ? 4 : 16)),
          bottomRight: Radius.circular(mine ? (showTail ? 4 : 16) : 16),
        ),
        border: mine ? Border.all(color: palette.primaryDark) : Border.all(color: ChatTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSenderName)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.senderName,
                style: ChatTheme.body(size: 11, weight: FontWeight.w800, color: palette.primaryDark),
              ),
            ),
          Text(
            message.text,
            style: ChatTheme.body(size: 13.5, color: mine ? Colors.white : ChatTheme.ink, height: 1.45),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatClock(message.createdAt),
                style: ChatTheme.body(
                  size: 10,
                  color: mine ? Colors.white.withOpacity(0.75) : ChatTheme.inkFaint,
                ),
              ),
              // 🔧 قبل هيك كانت شيكة done_all ثابتة دايماً بغض النظر عن
              // الواقع. هلق: شيكة وحدة رمادية = تم الإرسال بس، شيكة
              // مزدوجة رمادية = لسا ما انقرأت، شيكة مزدوجة ذهبية = تم
              // القراءة فعلاً من الطرف التاني (message.isRead == true).
              // بالمحادثة الجماعية (isRead == null) منعرض شيكة الإرسال بس.
              if (mine) ...[
                const SizedBox(width: 3),
                Icon(
                  message.isRead == null ? Icons.done_rounded : Icons.done_all_rounded,
                  size: 13,
                  color: message.isRead == true
                      ? palette.goldLight
                      : Colors.white.withOpacity(0.6),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (mine || !showSenderName) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Align(alignment: mine ? Alignment.centerLeft : Alignment.centerRight, child: bubble),
      );
    }

    // بفقاعات المشرف بالمحادثة الجماعية منضيف "ختم" بأول حرف من اسمو.
    final initial = message.senderName.isNotEmpty ? message.senderName.substring(0, 1) : '؟';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: bubble),
          const SizedBox(width: 8),
          ChatSeal(
            size: 26,
            ringColor: palette.goldMain,
            fillColor: palette.primaryDark,
            ringWidth: 1.2,
            child: Text(initial, style: ChatTheme.display(size: 11, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ComposerBar extends StatefulWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final ValueChanged<String> onEmoji;
  final SiblingPalette palette;
  const _ComposerBar({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onEmoji,
    required this.palette,
  });

  @override
  State<_ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<_ComposerBar> {
  // 😊 هاي الإيموجيات بتنكتب جوا نص الرسالة نفسها (اختيار المستخدم) —
  // مش زخرفة بالواجهة، هي أداة إدخال متل أي زر.
  static const _quickEmojis = ['🙂', '👍', '❤️', '🙏', '👏', '😅'];
  bool _showEmojiRow = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: ChatTheme.parchmentCard,
        border: Border(top: BorderSide(color: ChatTheme.hairline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _showEmojiRow ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _quickEmojis
                    .map((e) => GestureDetector(
                  onTap: () => widget.onEmoji(e),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: ChatTheme.parchment,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ChatTheme.hairline),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ))
                    .toList(),
              ),
            ),
            secondChild: const SizedBox(height: 0),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => setState(() => _showEmojiRow = !_showEmojiRow),
                icon: Icon(
                  _showEmojiRow ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
                  color: ChatTheme.inkMuted,
                  size: 22,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: ChatTheme.parchment,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ChatTheme.hairline),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => widget.onSend(),
                    cursorColor: widget.palette.primaryDark,
                    style: ChatTheme.body(size: 13.5, color: ChatTheme.ink),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      hintStyle: ChatTheme.body(size: 13, color: ChatTheme.inkFaint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.sending ? null : widget.onSend,
                child: ChatSeal(
                  size: 42,
                  ringColor: widget.palette.goldMain,
                  fillColor: widget.palette.primaryDark,
                  ringWidth: 1.6,
                  child: widget.sending
                      ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Icon(Icons.send_rounded, color: widget.palette.goldLight, size: 19),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}  