import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// شاشة انتظار (Skeleton) لتبويب "الرئيسية" بينما يتم تحميل بيانات الطالب.
///
/// نفس تخطيط [HomeScreen] بالضبط (كرت ترحيب + بطاقتان مميزتان + شبكة
/// اختصارات) لكن بمربعات رمادية متحركة (Shimmer) بدل المحتوى الحقيقي،
/// حتى ما يحصل "قفزة" بصرية لحظة وصول البيانات.
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // كرت الترحيب
            _box(height: 106, radius: 22),
            const SizedBox(height: 24),
            _box(width: 60, height: 12, radius: 6),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _box(height: 140, radius: 18)),
                const SizedBox(width: 12),
                Expanded(child: _box(height: 140, radius: 18)),
              ],
            ),
            const SizedBox(height: 22),
            _box(width: 90, height: 12, radius: 6),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: List.generate(6, (_) => _box(radius: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box({double? width, double? height, required double radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// يغلّف أي محتوى بتأثير لمعان (Shimmer) متحرك من اليمين لليسار.
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.6 + t * 3.2, 0),
              end: Alignment(-0.6 + t * 3.2, 0),
              colors: [
                AppColors.gray200,
                Colors.white.withOpacity(0.9),
                AppColors.gray200,
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
