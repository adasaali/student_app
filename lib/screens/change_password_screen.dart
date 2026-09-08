import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'home_shell.dart';

/// شاشة إجبارية تظهر بعد أول تسجيل دخول (لما يكون الطالب لسا مسجّل
/// دخول بكلمة السر الافتراضية = رقم هاتف الأب أو الأم). ما فيها زر
/// رجوع — لازم يحدّد كلمة سر دائمة قبل ما يكمل لباقي التطبيق.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await context.read<ApiService>().changePassword(_newPasswordController.text.trim());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } on ApiException catch (e) {
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
      child: PopScope(
        // ما بدنا نسمح له يرجع لشاشة الدخول أو يتخطى الشاشة قبل ما يغيّر
        // كلمة السر — لهيك منمنع الرجوع.
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.gray50,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.lock_reset, size: 56, color: AppColors.gold),
                      const SizedBox(height: 16),
                      Text(
                        'خلّينا نأمّن حسابك',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'دخلت بكلمة سر مؤقتة (رقم هاتف). لازم تحدد كلمة سر خاصة فيك قبل ما تكمل.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppColors.gray600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _PasswordField(
                        controller: _newPasswordController,
                        hint: 'كلمة السر الجديدة',
                        obscure: _obscureNew,
                        onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
                          if (v.trim().length < 6) return 'على الأقل 6 خانات';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _PasswordField(
                        controller: _confirmPasswordController,
                        hint: 'تأكيد كلمة السر',
                        obscure: _obscureConfirm,
                        onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) {
                          if (v != _newPasswordController.text) return 'كلمتا السر غير متطابقتين';
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text(
                                  'حفظ ومتابعة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
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
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggleObscure,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200, width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray800),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(fontSize: 15, color: AppColors.gray400),
          prefixIcon: Icon(Icons.lock_outline, color: AppColors.gray400, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.gray400,
              size: 20,
            ),
            onPressed: onToggleObscure,
          ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          errorStyle: GoogleFonts.cairo(fontSize: 12, color: AppColors.red, fontWeight: FontWeight.w500),
        ),
        validator: validator,
      ),
    );
  }
}
