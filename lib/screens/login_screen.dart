import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../providers/student_provider.dart';
import '../theme/app_colors.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;
  bool _btnPressed = false;
  bool _success = false;
  String? _errorMessage;

  late final AnimationController _entrance;
  late final Animation<double> _heroFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _cardSlide;
  late final Animation<double> _fieldsFade;
  late final Animation<Offset> _fieldsSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _userFocus.addListener(_onFocusChange);
    _passFocus.addListener(_onFocusChange);
    _entrance.forward();
  }

  void _setupAnimations() {
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _heroFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _logoFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
    ));

    _cardSlide = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
    );

    _fieldsFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
    );
    _fieldsSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOutCubic),
    ));
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _userFocus.removeListener(_onFocusChange);
    _passFocus.removeListener(_onFocusChange);
    _userFocus.dispose();
    _passFocus.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
      _success = false;
    });

    try {
      final api = ApiService();
      final result = await api.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (result['status'] == 'success') {
        final token = result['token'];
        await context.read<AuthService>().saveToken(token);

        // نفس النسخة المشتركة من ApiService (مش المتغيّر المحلي api)
        // عشان التوكن ينحفظ بمكان واحد متسق تستخدمه كل الشاشات
        // (بما فيها شاشة الرسائل الجديدة المبنية على MySQL).
        context.read<ApiService>().setToken(token);

        // تسجيل الـ FCM token عشان الطالب يقدر يستقبل إشعارات push حقيقية
        // 🔧 كانت هون NotificationService.registerDeviceToken(api) — دالة
        // static مش موجودة أصلاً؛ NotificationService مصمّمة كـinstance
        // عادي مربوط بـProvider. وبعدين كانت فيها مشكلة تانية: كان
        // فيها callback بيتفحّص mounted تبع LoginScreen بالذات — وبما
        // إن LoginScreen بتنكسر فوراً بعد الانتقال لـHomeShell، كان
        // fetchNotifications() ما بينفّذ إطلاقاً بعد أول شاشة، فالعداد
        // ما كان يتحدث إلا بإعادة فتح التطبيق من الصفر. هلق منمرر
        // studentProvider مباشرة — نسخة وحيدة بتعيش طول الجلسة كاملة،
        // مش مرتبطة بأي شاشة قابلة للانكسار.
        if (mounted) {
          context.read<NotificationService>().init(
            studentProvider: context.read<StudentProvider>(),
          );
        }

        final studentProvider = context.read<StudentProvider>();
        await studentProvider.fetchCoreData();

        if (!mounted) return;

        if (studentProvider.error != null) {
          setState(() {
            _errorMessage = studentProvider.error;
          });
          return;
        }

        // 🔧 كانت ناقصة هون — قبل هيك كان هالاستدعاء بس بـ HomeShell.initState
        // (بالخلفية، بعد ما تنفتح الواجهة أصلاً)، فالمستخدم كان يشوف
        // الشاشة الرئيسية لثانية أو تنتين قبل ما تتحدث عدّادات الإشعارات
        // تبع الإخوة. هلق منستناها هون كمان قبل الانتقال.
        await studentProvider.fetchNotifications();
        if (!mounted) return;

        setState(() => _success = true);
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );

        studentProvider.fetchAllStudents();
        return;
      }

      setState(() {
        _errorMessage = result['message'] ?? 'بيانات غير صحيحة';
      });
    } on ApiException catch (e) {
      // كانت هذه الحالة تُستبدل سابقاً برسالة عامة ثابتة "تعذر الاتصال بالخادم"
      // بغض النظر عن السبب الحقيقي (بيانات خاطئة/انتهاء صلاحية/خطأ سيرفر...).
      // الآن نعرض رسالة الخطأ الفعلية القادمة من ApiService.
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHero(),
                      _buildOverlappingCard(),
                      const SizedBox(height: 24),
                      _buildFooter(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return FadeTransition(
      opacity: _heroFade,
      child: Container(
        height: 380,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.navy,
              Color(0xFF0D0D2B),
              AppColors.navyLight,
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPatternPainter(),
              ),
            ),
            _FloatingShape(
              top: 40,
              right: 30,
              size: 100,
              color: AppColors.gold.withOpacity(0.12),
              delay: 0,
            ),
            _FloatingShape(
              top: 180,
              left: 20,
              size: 70,
              color: AppColors.red.withOpacity(0.08),
              delay: 2,
            ),
            _FloatingShape(
              bottom: 60,
              right: 60,
              size: 50,
              color: Colors.white.withOpacity(0.06),
              delay: 4,
            ),
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.red.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogoRing(),
                      const SizedBox(height: 16),
                      Text(
                        'الأكاديمية الخاصة',
                        style: GoogleFonts.cairo(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'بوابة الطالب',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.goldLight,
                          letterSpacing: 3,
                        ),
                      ),
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

  Widget _buildLogoRing() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.02),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.25),
            blurRadius: 60,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.school_rounded, color: AppColors.gold, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlappingCard() {
    return Transform.translate(
      offset: const Offset(0, -70),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: FadeTransition(
          opacity: _cardSlide,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_cardSlide),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.12),
                    blurRadius: 60,
                    offset: const Offset(0, -10),
                  ),
                  BoxShadow(
                    color: AppColors.navy.withOpacity(0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  children: [
                    _buildShimmerBar(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
                      child: FadeTransition(
                        opacity: _fieldsFade,
                        child: SlideTransition(
                          position: _fieldsSlide,
                          child: _buildFormContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBar() {
    return Container(
      height: 4,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navy,
            AppColors.gold,
            AppColors.red,
            AppColors.gold,
            AppColors.navy,
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'تسجيل الدخول',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أهلاً بك مجدداً في منصتك التعليمية',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _buildErrorMessage(),
          if (_errorMessage != null) const SizedBox(height: 16),

          _fieldLabel('الرقم التعريفي / رقم الهاتف'),
          const SizedBox(height: 8),
          _AcademyField(
            controller: _usernameController,
            focusNode: _userFocus,
            hint: 'أدخل الرقم التعريفي أو رقم هاتف الأب',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            validator: (v) =>
            (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
          ),
          const SizedBox(height: 20),

          _fieldLabel('كلمة المرور'),
          const SizedBox(height: 8),
          _AcademyField(
            controller: _passwordController,
            focusNode: _passFocus,
            hint: 'أدخل كلمة المرور',
            icon: Icons.lock_outline,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            suffix: IconButton(
              splashRadius: 18,
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.gray400,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) =>
            (v == null || v.length < 4) ? 'كلمة المرور 4 أحرف على الأقل' : null,
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'نسيت كلمة المرور؟',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildLoginButton(),
          const SizedBox(height: 24),

          _buildDivider(),
          const SizedBox(height: 20),

          _buildQuickAccess(),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => SizeTransition(
        sizeFactor: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: _errorMessage == null
          ? const SizedBox.shrink(key: ValueKey('no-error'))
          : Container(
        key: const ValueKey('error'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.06),
          border: Border.all(
            color: AppColors.red.withOpacity(0.15),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: GoogleFonts.cairo(
                  color: AppColors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    final isSuccess = _success;
    final bgGradient = isSuccess
        ? const LinearGradient(colors: [AppColors.green, Color(0xFF1E6B2E)])
        : const LinearGradient(colors: [AppColors.navy, AppColors.navyLight]);

    return GestureDetector(
      onTapDown: (_) => setState(() => _btnPressed = true),
      onTapUp: (_) => setState(() => _btnPressed = false),
      onTapCancel: () => setState(() => _btnPressed = false),
      onTap: _loading
          ? null
          : () {
        HapticFeedback.lightImpact();
        _login();
      },
      child: AnimatedScale(
        scale: _btnPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isSuccess
                    ? AppColors.green.withOpacity(0.3)
                    : AppColors.navy.withOpacity(0.25),
                blurRadius: _btnPressed ? 15 : 25,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _loading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isSuccess ? 'تم الدخول بنجاح' : 'دخول',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSuccess ? Icons.check : Icons.arrow_forward,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, AppColors.gray200]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'أو',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.gray400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.gray200, Colors.transparent]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccess() {
    return Row(
      children: [
        Expanded(
          child: _QuickButton(
            icon: Icons.chat_bubble_outline,
            label: 'تواصل معنا',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickButton(
            icon: Icons.help_outline,
            label: 'المساعدة',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      '© 2026 مدرسة الأكاديمية الخاصة',
      style: GoogleFonts.cairo(
        fontSize: 12,
        color: AppColors.gray400,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// حقل نصي بأسلوب الأكاديمية
class _AcademyField extends StatelessWidget {
  const _AcademyField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused ? AppColors.gold.withOpacity(0.6) : AppColors.gray200,
          width: focused ? 2 : 1.5,
        ),
        boxShadow: focused
            ? [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.gray800,
        ),
        cursorColor: AppColors.gold,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(
            fontSize: 15,
            color: AppColors.gray400,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: focused ? AppColors.gold : AppColors.gray400,
            size: 20,
          ),
          suffixIcon: suffix,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          errorStyle: GoogleFonts.cairo(
            fontSize: 12,
            color: AppColors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        validator: validator,
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.gray600),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingShape extends StatefulWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final double delay;

  const _FloatingShape({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
    required this.delay,
  });

  @override
  State<_FloatingShape> createState() => _FloatingShapeState();
}

class _FloatingShapeState extends State<_FloatingShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(seconds: widget.delay.toInt()), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: widget.top,
          bottom: widget.bottom,
          left: widget.left,
          right: widget.right,
          child: Transform.translate(
            offset: Offset(0, _animation.value * -20),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.color, widget.color.withOpacity(0.3)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}