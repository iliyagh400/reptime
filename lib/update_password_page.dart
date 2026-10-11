import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_feedback.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool get _hasMinLength => _newPasswordController.text.length >= 6;
  bool get _passwordsMatch =>
      _newPasswordController.text.isNotEmpty &&
      _newPasswordController.text == _confirmPasswordController.text;

  bool get _isFormValid => _hasMinLength && _passwordsMatch;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

   Future<void> _updatePassword() async {
    if (!_isFormValid || _isLoading) return;

    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (!mounted) return;

           AppFeedback.showSuccess(
        context,
        'رمز عبور با موفقیت به‌روزرسانی شد. لطفاً وارد شوید.',
      );


      // خروج ایمن از نشست ریکاوری بدون متوقف شدن در صورت خطای شبکه
      try {
        await supabase.auth.signOut();
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (_) {
      if (!mounted) return;
            AppFeedback.showError(
        context,
        'خطایی در به‌روزرسانی رمز عبور رخ داد (ممکن است لینک منقضی شده باشد). لطفاً دوباره درخواست دهید.',
      );

    } catch (_) {
      if (!mounted) return;
            AppFeedback.showError(
        context,
        'خطای غیرمنتظره‌ای رخ داد. لطفاً اتصال اینترنت را بررسی کرده و مجدداً تلاش کنید.',
      );

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    const bgDark = Color(0xFF0F172A);
    const cardBg = Color(0xFF1E293B);
    const textLight = Color(0xFFF8FAFC);
    const textMuted = Color(0xFF94A3B8);
    const accentGreen = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'تغییر رمز عبور',
          style: GoogleFonts.vazirmatn(
            color: textLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textLight, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_reset_rounded,
                  size: 64,
                  color: accentGreen,
                ),
                const SizedBox(height: 20),
                Text(
                  'رمز عبور جدید',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vazirmatn(
                    color: textLight,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لطفاً رمز عبور جدید خود را وارد کنید.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vazirmatn(
                    color: textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  style: GoogleFonts.vazirmatn(color: textLight, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'رمز عبور جدید',
                    labelStyle: GoogleFonts.vazirmatn(color: textMuted, fontSize: 13),
                    hintText: 'حداقل ۶ کاراکتر',
                    hintStyle: GoogleFonts.vazirmatn(color: textMuted.withValues(alpha: 0.5), fontSize: 12),
                    prefixIcon: const Icon(Icons.lock_outline, color: textMuted, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        color: textMuted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: GoogleFonts.vazirmatn(color: textLight, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'تکرار رمز عبور جدید',
                    labelStyle: GoogleFonts.vazirmatn(color: textMuted, fontSize: 13),
                    hintText: 'رمز عبور جدید را دوباره وارد کنید',
                    hintStyle: GoogleFonts.vazirmatn(color: textMuted.withValues(alpha: 0.5), fontSize: 12),
                    prefixIcon: const Icon(Icons.lock_clock_outlined, color: textMuted, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                _buildRequirementRow('حداقل ۶ کاراکتر', _hasMinLength),
                const SizedBox(height: 8),
                _buildRequirementRow('همخوانی رمزهای عبور', _passwordsMatch),
                const SizedBox(height: 32),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isFormValid && !_isLoading ? _updatePassword : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: accentGreen.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'ثبت رمز جدید',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: met ? const Color(0xFF10B981) : const Color(0xFF64748B),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.vazirmatn(
            color: met ? const Color(0xFFF8FAFC) : const Color(0xFF64748B),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}
