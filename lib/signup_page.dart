import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'repositories/auth_repository.dart';
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // متغیرهای ذخیره پیام ارور اختصاصی هر فیلد
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Reptime Dark Terrarium theme colors
  static const _background = Color(0xFF141C17);
  static const _surface = Color(0xFF263229);
  static const _surfaceRaised = Color(0xFF2D3930);
  static const _forest = Color(0xFF17251D);
  static const _moss = Color(0xFF6E8B52);
  static const _leaf = Color(0xFF486344);
  static const _lightMoss = Color(0xFF8FA77B);
  static const _sand = Color(0xFFC8A66A);
  static const _text = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _line = Color(0xFF3A463C);
  static const _errorColor = Color(0xFFE57373); // رنگ ارور هماهنگ با تم

  static const String _supportTelegramId = '@ReptimeSupport';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showGeneralMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _line),
        ),
        behavior: SnackBarBehavior.floating,
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(text, style: const TextStyle(color: _text)),
        ),
      ),
    );
  }

    Future<bool> _checkEmailAllowed(String email) async {
    return await _authRepo.checkEmailAllowed(email);
  }


  void _showNoSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _line),
          ),
          title: Row(
            children: const [
              Icon(Icons.lock_person_rounded, color: _sand, size: 26),
              SizedBox(width: 10),
              Text(
                'نیاز به تهیه اشتراک',
                style: TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'کاربر گرامی برای استفاده از برنامه رپتایم و شروع نگه داری دقیقتر و بهینه از پت های با ارزشتون',
                style: TextStyle(color: _muted, fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'نیاز به اشتراک دارید برای تهیه دسترسی به برنامه با قیمت مناسب به آیدی پشتیبانی تلگرام پیام بدید',
                style: TextStyle(color: _muted, fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.send_rounded, color: Color(0xFF67B77C), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        _supportTelegramId,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: _text,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: _muted, size: 18),
                      tooltip: 'کپی آیدی',
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: _supportTelegramId),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: _surfaceRaised,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: _line),
                            ),
                            behavior: SnackBarBehavior.floating,
                            content: const Text(
                              'آیدی پشتیبانی کپی شد ✅',
                              style: TextStyle(color: _text),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'متوجه شدم',
                style: TextStyle(color: _moss, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
    // دیالوگ اختصاصی ایمیل تکراری با استایل دارک پروژه
  void _showAlreadyRegisteredDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _line, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 30,
                offset: Offset(0, 16),
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
                      color: _errorColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _errorColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      color: _errorColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ایمیل قبلاً ثبت شده',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'حساب کاربری موجود است',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                child: Text(
                  'برای این ایمیل قبلاً یک حساب کاربری ثبت شده است. لطفاً وارد شوید یا اگر رمز عبور را فراموش کرده‌اید از صفحه ورود آن را بازیابی کنید.',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    height: 1.6,
                    color: const Color(0xFFD6DDD4),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context); // بازگشت به صفحه لاگین
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _sand,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'رفتن به صفحه ورود',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // اعتبارسنجی فیلدها و ثبت‌نام
    // اعتبارسنجی فیلدها و ثبت‌نام کامل
  Future<void> _signup() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // ریست ارورها
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => _emailError = 'ایمیل را وارد کنید');
      hasError = true;
    } else if (!RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() => _emailError = 'فرمت ایمیل نامعتبر است');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'رمز عبور را وارد کنید');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'حداقل ۶ کاراکتر باشد');
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'تکرار رمز عبور را وارد کنید');
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'تکرار رمز با رمز عبور همخوانی ندارد');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final isAllowed = await _checkEmailAllowed(email);

      if (!isAllowed) {
        if (!mounted) return;
        _showNoSubscriptionDialog();
        return;
      }

     final res = await _authRepo.signUp(
          email: email,
          password: password,
        );

      if (!mounted) return;

      if (res.user != null && res.session != null) {
        // ثبت‌نام موفق + ورود مستقیم
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else if (res.user != null && res.session == null) {
        // ثبت‌نام انجام شد اما نیاز به تایید ایمیل دارد
        _showGeneralMessage('حساب ساخته شد؛ لینک تأیید به ایمیل شما ارسال گردید.');
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final raw = e.message.toLowerCase();
      
      // تشخیص خطای ثبت‌نام تکراری
      if (raw.contains('already registered') || e.statusCode == '422') {
        setState(() => _emailError = 'این ایمیل قبلاً ثبت‌نام کرده است');
        _showAlreadyRegisteredDialog();
      } else if (raw.contains('password') && raw.contains('weak')) {
        setState(() => _passwordError = 'رمز عبور انتخاب شده ضعیف است');
      } else if (raw.contains('rate limit')) {
        _showGeneralMessage('تعداد درخواست‌ها زیاد است؛ لطفاً کمی صبر کنید.');
      } else {
        _showGeneralMessage(e.message);
      }
    } catch (e) {
      _showGeneralMessage('خطایی در ثبت‌نام رخ داد. دوباره تلاش کنید.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  // ویجت عنوان بالای هر ورودی به همراه پیام ارور اختصاصی
  Widget _buildFieldHeader(String title, String? errorText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 2, left: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (errorText != null)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: 1.0,
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: _errorColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    errorText,
                    style: const TextStyle(
                      color: _errorColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool hasError = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _muted.withOpacity(0.55), fontSize: 13.5),
      prefixIcon: Icon(
        prefixIcon,
        color: hasError ? _errorColor : _lightMoss,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: hasError ? _errorColor.withOpacity(0.8) : _line,
          width: hasError ? 1.4 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: hasError ? _errorColor : _moss,
          width: 1.6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                left: -70,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _leaf.withOpacity(0.18),
                  ),
                ),
              ),
              Positioned(
                bottom: -90,
                right: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB86F4D).withOpacity(0.12),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // لوگوی اپلیکیشن
                          Center(
                            child: Container(
                              width: 96,
                              height: 96,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _surface.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: _lightMoss.withOpacity(0.28),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/reptime_logo.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                        const SizedBox(height: 22),
                        const Text(
                          'ایجاد حساب جدید',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _text,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'با رپتایم هم خودت راحت‌تری، هم پتت',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 30),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: _line, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.32),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'مشخصات حساب',
                                style: TextStyle(
                                  color: _text,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // فیلد ایمیل با هدر ارور
                              _buildFieldHeader('ایمیل', _emailError),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                onChanged: (_) {
                                  if (_emailError != null) setState(() => _emailError = null);
                                },
                                style: const TextStyle(
                                  color: _text,
                                  fontSize: 14.5,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'example@email.com',
                                  prefixIcon: Icons.alternate_email_rounded,
                                  hasError: _emailError != null,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // فیلد رمز عبور با هدر ارور
                              _buildFieldHeader('رمز عبور', _passwordError),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                textDirection: TextDirection.ltr,
                                onChanged: (_) {
                                  if (_passwordError != null) setState(() => _passwordError = null);
                                },
                                style: const TextStyle(
                                  color: _text,
                                  fontSize: 14.5,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'حداقل ۶ کاراکتر',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  hasError: _passwordError != null,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: _muted,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // فیلد تکرار رمز عبور با هدر ارور
                              _buildFieldHeader('تکرار رمز عبور', _confirmPasswordError),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: !_showConfirmPassword,
                                textDirection: TextDirection.ltr,
                                onChanged: (_) {
                                  if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                                },
                                style: const TextStyle(
                                  color: _text,
                                  fontSize: 14.5,
                                ),
                                decoration: _inputDecoration(
                                  hint: 'رمز عبور را مجدداً وارد کنید',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  hasError: _confirmPasswordError != null,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showConfirmPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: _muted,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showConfirmPassword = !_showConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // دکمه ثبت نام
                              SizedBox(
                                height: 54,
                                child: _isLoading
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: _leaf.withOpacity(0.35),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: _line),
                                        ),
                                        alignment: Alignment.center,
                                        child: const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: _sand,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _signup,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _moss,
                                          foregroundColor: _text,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                        ),
                                        child: const Text(
                                          'ثبت‌نام',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'قبلاً ثبت‌نام کردی؟',
                              style: TextStyle(color: _muted, fontSize: 13.5),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: _sand,
                              ),
                              child: const Text(
                                'وارد شو',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'نگهداری بهتر، زندگی بهتر',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 12,
                            letterSpacing: 0.2,
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
      ),
    );
  }
}
