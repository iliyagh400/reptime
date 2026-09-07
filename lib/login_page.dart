import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // فیلدهای نگه‌دارنده خطای درون‌خطی
  String? _emailError;
  String? _passwordError;

  // پالت رنگی Dark Terrarium
  static const Color _bg = Color(0xFF141C17);
  static const Color _surface = Color(0xFF263229);
  static const Color _surfaceRaised = Color(0xFF2F3E33);
  static const Color _moss = Color(0xFF6E8B52);
  static const Color _lightMoss = Color(0xFF8FA876);
  static const Color _sand = Color(0xFFC8A66A);
  static const Color _ink = Color(0xFFECE8DD);
  static const Color _muted = Color(0xFFA8A99A);
  static const Color _line = Color(0xFF3A463C);
  static const Color _errorRed = Color(0xFFE57373);

  static const String _supportTelegramId = '@ReptimeSupport';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // بررسی وضعیت اشتراک ایمیل در دیتابیس
  Future<bool> _checkEmailAllowed(String email) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'can_register_email',
        params: {'check_email': email.trim().toLowerCase()},
      );
      return response == true;
    } catch (_) {
      return false;
    }
  }

  // دیالوگ اطلاع‌رسانی نیاز به اشتراک
  void _showNoSubscriptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _line, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _sand.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _sand.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: _sand,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'نیاز به اشتراک فعال',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'برای ورود و استفاده از برنامه، نیاز به اشتراک فعال دارید.\nجهت تهیه یا فعال‌سازی اشتراک با پشتیبانی در ارتباط باشید:',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF67B77C),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          _supportTelegramId,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(
                            const ClipboardData(text: _supportTelegramId),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'آیدی تلگرام پشتیبانی کپی شد ✅',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  color: _ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: _surfaceRaised,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: _line),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _sand.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _sand.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: _sand,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'کپی',
                                style: TextStyle(
                                  color: _sand,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _moss,
                    foregroundColor: _ink,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'متوجه شدم',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // فرآیند ورود و اعتبارسنجی
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailError = null;
      _passwordError = null;

      if (email.isEmpty) {
        _emailError = 'لطفاً ایمیل را وارد کنید';
      } else if (!email.contains('@') || !email.contains('.')) {
        _emailError = 'فرمت ایمیل نامعتبر است';
      }

      if (password.isEmpty) {
        _passwordError = 'لطفاً رمز عبور را وارد کنید';
      } else if (password.length < 6) {
        _passwordError = 'رمز عبور حداقل ۶ کاراکتر است';
      }
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);

    try {
      final allowed = await _checkEmailAllowed(email);
      if (!allowed) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showNoSubscriptionDialog();
        return;
      }

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message.contains('Invalid login credentials')
                ? 'ایمیل یا رمز عبور اشتباه است'
                : 'خطا در ورود: ${e.message}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Vazirmatn', color: _ink),
          ),
          backgroundColor: const Color(0xFF8B3A3A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطای ناشناخته: $e',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Vazirmatn', color: _ink),
          ),
          backgroundColor: const Color(0xFF8B3A3A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // متد کمکی برای ساخت حاشیه فیلدها
  OutlineInputBorder _buildOutlineBorder({required Color color, double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // هدر بالای فیلد با قابلیت نمایش خطا
  Widget _buildFieldHeader(String label, String? error) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (error != null)
            Text(
              error,
              style: const TextStyle(
                color: _errorRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // حباب تزئینی بالا
            Positioned(
              top: -60,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _moss.withValues(alpha: 0.12),
                ),
              ),
            ),
            // حباب تزئینی پایین
            Positioned(
              bottom: -70,
              right: -50,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _sand.withValues(alpha: 0.08),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // لوگوی شفاف Reptime
                        Center(
                          child: Container(
                            width: 90,
                            height: 90,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _surface.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _lightMoss.withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/reptime_logo.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // عناوین
                        const Text(
                          'خوش آمدید',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'برای ورود به حساب خود اطلاعات زیر را وارد کنید',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // کارت ورود
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: _line, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // فیلد ایمیل
                              _buildFieldHeader('ایمیل', _emailError),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 14.5,
                                ),
                                onChanged: (_) {
                                  if (_emailError != null) {
                                    setState(() => _emailError = null);
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'name@example.com',
                                  hintStyle: TextStyle(
                                    color: _muted.withValues(alpha: 0.55),
                                    fontSize: 13.5,
                                  ),
                                  hintTextDirection: TextDirection.ltr,
                                  prefixIcon: const Icon(
                                    Icons.alternate_email_rounded,
                                    color: _muted,
                                    size: 20,
                                  ),
                                  filled: true,
                                  fillColor: _bg,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: _buildOutlineBorder(
                                    color: _emailError != null ? _errorRed : _line,
                                  ),
                                  enabledBorder: _buildOutlineBorder(
                                    color: _emailError != null ? _errorRed : _line,
                                  ),
                                  focusedBorder: _buildOutlineBorder(
                                    color: _emailError != null ? _errorRed : _moss,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // فیلد رمز عبور
                              _buildFieldHeader('رمز عبور', _passwordError),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 14.5,
                                ),
                                onChanged: (_) {
                                  if (_passwordError != null) {
                                    setState(() => _passwordError = null);
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: TextStyle(
                                    color: _muted.withValues(alpha: 0.55),
                                    fontSize: 14,
                                  ),
                                  hintTextDirection: TextDirection.ltr,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: _muted,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _muted,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: _bg,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: _buildOutlineBorder(
                                    color: _passwordError != null ? _errorRed : _line,
                                  ),
                                  enabledBorder: _buildOutlineBorder(
                                    color: _passwordError != null ? _errorRed : _line,
                                  ),
                                  focusedBorder: _buildOutlineBorder(
                                    color: _passwordError != null ? _errorRed : _moss,
                                    width: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // دکمه ورود
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _moss,
                                    foregroundColor: _ink,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              _ink,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'ورود به حساب',
                                          style: TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // لینک هدایت به صفحه ثبت نام
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'حساب کاربری ندارید؟ ',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 13.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'ثبت‌نام کنید',
                                style: TextStyle(
                                  color: _sand,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
