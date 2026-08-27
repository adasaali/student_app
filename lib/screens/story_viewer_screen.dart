import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/announcement_story.dart';
import '../theme/app_colors.dart';

/// عارض القصص/الإعلانات بشاشة كاملة بأسلوب انستغرام:
/// أشرطة تقدّم بالأعلى تتقدّم تلقائياً، ولمس النص الأيمن = التالي،
/// النص الأيسر = السابق، وزر إغلاق أعلى اليسار.
class StoryViewerScreen extends StatefulWidget {
  final List<AnnouncementStory> stories;
  final int initialIndex;

  const StoryViewerScreen({super.key, required this.stories, this.initialIndex = 0});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late int _index;
  late AnimationController _controller;
  static const _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goNext();
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_index >= widget.stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
    _controller
      ..reset()
      ..forward();
  }

  void _goPrevious() {
    if (_index <= 0) {
      _controller
        ..reset()
        ..forward();
      return;
    }
    setState(() => _index--);
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_index];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [story.color.withOpacity(0.85), AppColors.navy],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: List.generate(widget.stories.length, (i) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: i == _index
                                ? AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, _) => FractionallySizedBox(
                                      alignment: Alignment.centerRight,
                                      widthFactor: _controller.value,
                                      child: Container(
                                        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2)),
                                      ),
                                    ),
                                  )
                                : (i < _index
                                    ? Container(decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2)))
                                    : const SizedBox.shrink()),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                          child: Icon(story.icon, color: AppColors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'إعلان المدرسة',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.close_rounded, color: AppColors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(story.icon, color: AppColors.white, size: 64),
                          const SizedBox(height: 24),
                          Text(
                            story.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.white),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            story.body,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(fontSize: 14.5, color: Colors.white.withOpacity(0.85), height: 1.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // مناطق اللمس: يمين = التالي، يسار = السابق (نفس تعامل انستغرام)
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _goNext)),
                  Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _goPrevious)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
