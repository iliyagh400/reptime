import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  String? _emailError;
  String? _passwordError;

  // پالت رنگی Dark Terrarium
  static const _bg = Color(0xFF141C17);
  static const _surface = Color(0xFF1B241E);
  static const _surfaceRaised = Color(0xFF263229);
  static const _moss = Color(0xFF6E8B52);
  static const _sand = Color(0xFFD4A373);
  static const _sandHover = Color(0xFFE8C39E);
  static const _textMuted = Color(0xFF8A9A86);
  static const _line = Color(0xFF2D3B30);
  static const _ink = Color(0xFF0D1410);
  static const _errorRed = Color(0xFFE57373);

  static const String _supportTelegramId = '@reptimewithyou';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _checkEmailAllowed(String email) async {
    try {
      final res = await Supabase.instance.client
          .rpc('can_register_email', params: {'check_email': email.trim().toLowerCase()});
      return res == true;
    } catch (_) {
      return false;
    }
  }
    // دیالوگ «ایمیل قبلاً ثبت شده است»
  void _showAlreadyRegisteredDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: _line, width: 1.2),
          ),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _errorRed.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _errorRed.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: _errorRed,
              size: 28,
            ),
          ),
          title: Text(
            'این ایمیل قبلاً ثبت شده است',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          content: Text(
            'برای این ایمیل یک حساب کاربری در رپتایم وجود دارد.\n'
            'لطفاً وارد حساب خود شوید یا رمز عبور را بازیابی کنید.',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 13,
              height: 1.7,
              color: _textMuted,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: _textMuted),
              child: Text(
                'بستن',
                style: GoogleFonts.vazirmatn(fontSize: 13.5),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _moss,
                foregroundColor: _ink,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'متوجه شدم',
                style: GoogleFonts.vazirmatn(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoSubscriptionDialog(BuildContext context) {
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
                      color: _sand.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _sand.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: _sand,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نیاز به اشتراک فعال',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'دسترسی اختصاصی Reptime',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12,
                            color: _textMuted,
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
                  color: _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                child: Text(
                  'این حساب دارای اشتراک فعال نیست. برای ورود، ابتدا باید اشتراک فعال تهیه کرده باشید.',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    height: 1.6,
                    color: const Color(0xFFD6DDD4),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'کپی آیدی تلگرام',
                      onPressed: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: _supportTelegramId),
                        );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              backgroundColor: _surfaceRaised,
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'آیدی تلگرام کپی شد',
                                style: GoogleFonts.vazirmatn(color: Colors.white),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 20, color: _sand),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'پشتیبانی و تهیه اشتراک',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 11.5,
                              color: _textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            _supportTelegramId,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _sand,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _moss,
                    foregroundColor: _ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'متوجه شدم',
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
    // دیالوگ پشتیبانی
  void _showSupportDialog() {
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
                      color: _sand.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _sand.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: _sand,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'پشتیبانی Reptime',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'پاسخگویی به سوالات و مشکلات',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12,
                            color: _textMuted,
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
                  color: _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                child: Text(
                  'در صورت بروز هرگونه مشکل در ورود، ثبت‌نام یا تهیه اشتراک، می‌توانید از طریق تلگرام با پشتیبانی در ارتباط باشید:',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    height: 1.6,
                    color: const Color(0xFFD6DDD4),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _surfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'کپی آیدی تلگرام',
                      onPressed: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: _supportTelegramId),
                        );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              backgroundColor: _surfaceRaised,
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'آیدی تلگرام کپی شد',
                                style: GoogleFonts.vazirmatn(color: Colors.white),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 20, color: _sand),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'آیدی تلگرام پشتیبانی',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 11.5,
                              color: _textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            _supportTelegramId,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _sand,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _moss,
                    foregroundColor: _ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'بستن',
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

  // دیالوگ معرفی Reptime (علامت سوال)
  void _showAboutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
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
                      color: _moss.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _moss.withValues(alpha: 0.35)),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: _moss,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'درباره Reptime',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'دستیار و پلتفرم تخصصی خزندگان',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 12,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رپتایم  چیه و چیکار میکنه؟',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _sand,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ' یک پلتفرم جامع برای یاداوری، مدیریت، ثبت چرخه نگهداری، پایش سلامت و زمان‌بندی تغذیه خزندگان و حیوانات خاص \n\nرپتایم اینجاست تا با یاداوری،مانیتور کردن ،ثبت و بررسی روتین ها و اتفاق های پت شما نگه داری رو به حرفه ای ترین و با کیفیت ترین ورژن خودش برسونه',
                      style: GoogleFonts.vazirmatn(
                        fontSize: 12.5,
                        height: 1.7,
                        color: const Color(0xFFD6DDD4),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _moss,
                    foregroundColor: _ink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'متوجه شدم',
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

  Future<bool> _userExists(String email) async {
  try {
    final result = await Supabase.instance.client.rpc(
      'user_exists_by_email',
      params: {
        'check_email': email.trim().toLowerCase(),
      },
    );

    return result == true;
  } catch (e) {
    debugPrint('user_exists_by_email error: $e');

    // برای جلوگیری از افشای اطلاعات در صورت خطای RPC،
    // به‌صورت پیش‌فرض ایمیل را موجود فرض می‌کنیم.
    return true;
  }
}

  // دیالوگ فراموشی رمز عبور
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                        color: _moss.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _moss.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: _moss, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'بازیابی رمز عبور',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ارسال لینک به ایمیل شما',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'ایمیل حساب کاربری خود را وارد کنید تا لینک بازیابی رمز برای شما ارسال شود.',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFFD6DDD4),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.vazirmatn(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    hintStyle: GoogleFonts.vazirmatn(color: _textMuted.withValues(alpha: 0.6), fontSize: 13),
                    filled: true,
                    fillColor: _bg,
                    prefixIcon: const Icon(Icons.mail_outline_rounded, color: _textMuted, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: _buildOutlineBorder(_line, 1.2),
                    enabledBorder: _buildOutlineBorder(_line, 1.2),
                    focusedBorder: _buildOutlineBorder(_moss, 1.6),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textMuted,
                          side: const BorderSide(color: _line),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text('انصراف', style: GoogleFonts.vazirmatn(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final email = resetEmailController.text.trim();
                                if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: _errorRed,
                                      content: Text('لطفاً یک ایمیل معتبر وارد کنید.', style: GoogleFonts.vazirmatn()),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isSubmitting = true);

                                try {
                                  await Supabase.instance.client.auth.resetPasswordForEmail(
                                    email,
                                    redirectTo: 'reptime://reset-password',
                                  );

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: _moss,
                                        content: Text(
                                          'لینک بازیابی به ایمیل شما ارسال شد. لطفاً صندوق ایمیل خود را بررسی کنید.',
                                          style: GoogleFonts.vazirmatn(color: Colors.white),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: _errorRed,
                                        content: Text('خطا در ارسال ایمیل بازیابی: $e', style: GoogleFonts.vazirmatn()),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setDialogState(() => isSubmitting = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _moss,
                          foregroundColor: _ink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
                              )
                            : Text(
                                'ارسال لینک',
                                style: GoogleFonts.vazirmatn(fontSize: 14, fontWeight: FontWeight.w700),
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
    );
  }

    Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => _emailError = 'ایمیل را وارد کنید');
      hasError = true;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'فرمت ایمیل نامعتبر است');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'رمز عبور را وارد کنید');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'رمز عبور باید حداقل ۶ کاراکتر باشد');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      // ۱) اول احراز هویت، بدون گیت اشتراک
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // ۲) بعد از ورود موفق، بررسی اشتراک
      final isAllowed = await _checkEmailAllowed(email);
      if (!isAllowed) {
        // خارج کردن از اکانت تا یوزر اشتراک‌نداشت وارد نشود
        await Supabase.instance.client.auth.signOut();
        _showNoSubscriptionDialog(context);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      final raw = e.message.toLowerCase();

      // نمایش خطاهای احراز هویت بالای فیلدها، مثل ساین‌آپ
     if (raw.contains('invalid login credentials') ||
    raw.contains('invalid credentials')) {
  final exists = await _userExists(email);

  if (!mounted) return;
      setState(() {
        if (exists) {
          _emailError = null;
          _passwordError = 'رمز عبور اشتباه است.';
        } else {
          _emailError = 'کاربری با این ایمیل یافت نشد.';
          _passwordError = null;
        }
      });
      } else if (raw.contains('email not confirmed')) {
        setState(() => _emailError = 'ایمیل شما هنوز تایید نشده است.');
      } else if (raw.contains('invalid email')) {
        setState(() => _emailError = 'فرمت ایمیل نامعتبر است.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'اطلاعات ورود یافت نشد.',
              style: GoogleFonts.vazirmatn(color: Colors.white),
            ),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در اتصال به سرور.',
              style: GoogleFonts.vazirmatn(color: Colors.white),
            ),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Widget _buildFieldHeader(String label, String? errorText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.vazirmatn(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD6DDD4),
            ),
          ),
          if (errorText != null)
            Flexible(
              child: Text(
                errorText,
                style: GoogleFonts.vazirmatn(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _errorRed,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  OutlineInputBorder _buildOutlineBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: size.height * 0.04),

                  // لوگو و نام برند
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _surfaceRaised.withValues(alpha: 0.7),
                            border: Border.all(color: _line, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(
                                'assets/reptime_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  'assets/reptime_logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error2, stackTrace2) => Center(
                                    child: Text(
                                      'R',
                                      style: GoogleFonts.cinzel(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        color: _sand,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Reptime',
                          style: GoogleFonts.cinzel(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'خوش آمدید، وارد حساب خود شوید',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 13.5,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * 0.045),

                  // کارت فرم ورود
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: _line, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // فیلد ایمیل
                        _buildFieldHeader('ایمیل', _emailError),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.vazirmatn(color: Colors.white, fontSize: 14),
                          onChanged: (_) {
                            if (_emailError != null) setState(() => _emailError = null);
                          },
                          decoration: InputDecoration(
                            hintText: 'name@example.com',
                            hintStyle: GoogleFonts.vazirmatn(
                              color: _textMuted.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: _bg,
                            prefixIcon: const Icon(Icons.mail_outline_rounded, color: _textMuted, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: _buildOutlineBorder(
                              _emailError != null ? _errorRed : _line,
                              _emailError != null ? 1.4 : 1.2,
                            ),
                            enabledBorder: _buildOutlineBorder(
                              _emailError != null ? _errorRed : _line,
                              _emailError != null ? 1.4 : 1.2,
                            ),
                            focusedBorder: _buildOutlineBorder(
                              _emailError != null ? _errorRed : _moss,
                              1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // فیلد رمز عبور
                        _buildFieldHeader('رمز عبور', _passwordError),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.vazirmatn(color: Colors.white, fontSize: 14),
                          onChanged: (_) {
                            if (_passwordError != null) setState(() => _passwordError = null);
                          },
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: GoogleFonts.vazirmatn(
                              color: _textMuted.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: _bg,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: _textMuted, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: _textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: _buildOutlineBorder(
                              _passwordError != null ? _errorRed : _line,
                              _passwordError != null ? 1.4 : 1.2,
                            ),
                            enabledBorder: _buildOutlineBorder(
                              _passwordError != null ? _errorRed : _line,
                              _passwordError != null ? 1.4 : 1.2,
                            ),
                            focusedBorder: _buildOutlineBorder(
                              _passwordError != null ? _errorRed : _moss,
                              1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // دکمه فراموشی رمز عبور (با ماوس اشاره‌گر و Hover شنی روشن)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: ButtonStyle(
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              ),
                              minimumSize: const WidgetStatePropertyAll(Size.zero),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              overlayColor: WidgetStatePropertyAll(_sand.withValues(alpha: 0.08)),
                              mouseCursor: WidgetStateMouseCursor.clickable,
                            ),
                            child: Builder(
                              builder: (context) {
                                return Text(
                                  'فراموشی رمز عبور؟',
                                  style: GoogleFonts.vazirmatn(
                                    fontSize: 12.5,
                                    color: _sand,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // دکمه ورود
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _moss,
                              foregroundColor: _ink,
                              elevation: 0,
                              disabledBackgroundColor: _moss.withValues(alpha: 0.35),
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
                                      color: _ink,
                                    ),
                                  )
                                : Text(
                                    'ورود به حساب',
                                    style: GoogleFonts.vazirmatn(
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

                  // فوتر و دکمه ثبت‌نام با Hover و اشاره‌گر دست (Clickable Cursor)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'حساب کاربری ندارید؟ ',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 13.5,
                            color: _textMuted,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupPage()),
                            );
                          },
                          style: ButtonStyle(
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            minimumSize: const WidgetStatePropertyAll(Size.zero),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            overlayColor: WidgetStatePropertyAll(_sand.withValues(alpha: 0.1)),
                            mouseCursor: WidgetStateMouseCursor.clickable,
                            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return _sandHover;
                              }
                              return _sand;
                            }),
                          ),
                          child: Text(
                            'ثبت‌نام کنید',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                                    const SizedBox(height: 18),

                  // دکمه‌های آیکونی پایین صفحه (پشتیبانی و درباره ما)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // آیکون پشتیبانی
                      Tooltip(
                        message: 'پشتیبانی',
                        child: InkWell(
                          onTap: _showSupportDialog,
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: _sand.withValues(alpha: 0.1),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _surfaceRaised.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _line),
                            ),
                            child: const Icon(
                              Icons.headset_mic_outlined,
                              color: _textMuted,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // آیکون درباره رپتایم (علامت سوال)
                      Tooltip(
                        message: 'درباره رپتایم',
                        child: InkWell(
                          onTap: _showAboutDialog,
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: _moss.withValues(alpha: 0.1),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _surfaceRaised.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _line),
                            ),
                            child: const Icon(
                              Icons.help_outline_rounded,
                              color: _textMuted,
                              size: 20,
                            ),
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
    );
  }
}