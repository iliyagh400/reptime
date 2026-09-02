import 'package:flutter/material.dart';
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
  bool _showPassword = false;

  // Reptime Dark Terrarium palette
  static const _background = Color(0xFF141C17);
  static const _surface = Color(0xFF263229);
  static const _surfaceRaised = Color(0xFF2D3930);
  static const _forest = Color(0xFF17251D);
  static const _moss = Color(0xFF6E8B52);
  static const _leaf = Color(0xFF486344);
  static const _lightMoss = Color(0xFF879B5D);
  static const _terracotta = Color(0xFFB86F4D);
  static const _sand = Color(0xFFC8A66A);
  static const _text = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _line = Color(0xFF3A463C);

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _surfaceRaised,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Text(
              'خطا: $e',
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: _text),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted),
      floatingLabelStyle: const TextStyle(color: _lightMoss),
      prefixIcon: Icon(icon, color: _lightMoss, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _moss, width: 1.5),
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
                top: -100,
                left: -90,
                child: Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _leaf.withOpacity(.13),
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _terracotta.withOpacity(.07),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 50, 28, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_leaf, _forest],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _lightMoss.withOpacity(.30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.28),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'R',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: _text,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'به رپتایم خوش آمدید',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'با رپتایم هم خودت راحت‌تری، هم پتت',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 34),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: _line.withOpacity(.85)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.20),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'ورود به حساب',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'اطلاعات حسابت را وارد کن تا ادامه بدی',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _muted,
                                ),
                              ),
                              const SizedBox(height: 22),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(color: _text),
                                decoration: _inputDecoration(
                                  label: 'ایمیل',
                                  icon: Icons.mail_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(color: _text),
                                decoration: _inputDecoration(
                                  label: 'رمز عبور',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _muted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 54,
                                child: _isLoading
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: _leaf,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: _text,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          elevation: 0,
                                          backgroundColor: _moss,
                                          foregroundColor: _background,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        child: const Text('ورود'),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'حساب نداری؟',
                              style: TextStyle(color: _muted, fontSize: 13),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SignupPage(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: _sand,
                              ),
                              child: const Text(
                                'ثبت‌نام کن',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'نگهداری بهتر، زندگی بهتر',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted, fontSize: 11),
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
