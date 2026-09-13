import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // اعتبارسنجی زنده
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
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      // به‌روزرسانی رمز عبور کاربر لاگین‌شده با توکن ریکاوری
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text.trim()),
      );

      if (!mounted) return;

      // نمایش پیام موفقیت
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Please login with your new password.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // خروج از سشن موقت و هدایت به صفحه لاگین
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                  const SizedBox(height: 16),
                  const Text(
                    'Set New Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your new password below to secure your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: textMuted),
                  ),
                  const SizedBox(height: 32),

                  // فیلد رمز عبور جدید
                  const Text('New Password', style: TextStyle(color: textLight, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    style: const TextStyle(color: textLight),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cardBg,
                      hintText: 'At least 6 characters',
                      hintStyle: const TextStyle(color: textMuted),
                      prefixIcon: const Icon(Icons.lock_outline, color: textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                          color: textMuted,
                        ),
                        onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // فیلد تکرار رمز عبور جدید
                  const Text('Confirm New Password', style: TextStyle(color: textLight, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: textLight),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cardBg,
                      hintText: 'Re-enter your new password',
                      hintStyle: const TextStyle(color: textMuted),
                      prefixIcon: const Icon(Icons.lock_clock_outlined, color: textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: textMuted,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // چک‌لیست اعتبارسنجی زنده
                  _buildRequirementRow('At least 6 characters', _hasMinLength),
                  const SizedBox(height: 6),
                  _buildRequirementRow('Passwords match', _passwordsMatch),

                  const SizedBox(height: 28),

                  // دکمه تایید و ذخیره
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isFormValid && !_isLoading ? _updatePassword : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        disabledBackgroundColor: accentGreen.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              'Update Password',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isMet ? const Color(0xFF10B981) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? const Color(0xFFF8FAFC) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
