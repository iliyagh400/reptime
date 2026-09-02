import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ---- Reptime Design Language: Dark Terrarium palette ----
  static const _ink = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _cream = Color(0xFF141C17);
  static const _line = Color(0xFF3A463C);
  static const _leaf = Color(0xFF486344);
  static const _terracotta = Color(0xFFB86F4D);
  static const _surface = Color(0xFF263229);

  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ثبت‌نام موفق بود ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: _surface,
      prefixIcon: Icon(icon, color: _muted, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _line.withOpacity(.78)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _terracotta, width: 1.4),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: _line.withOpacity(.78)),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: _ink,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _leaf,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _leaf.withOpacity(.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'R',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ساخت حساب جدید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'به رپتایم خوش اومدی، حسابتو بساز تا شروع کنیم',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _muted),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: _ink),
                  decoration: _fieldDecoration(
                      label: 'ایمیل', icon: Icons.mail_outline_rounded),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: _ink),
                  decoration: _fieldDecoration(
                      label: 'رمز عبور', icon: Icons.lock_outline_rounded),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _terracotta),
                      )
                    : SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _terracotta,
                            foregroundColor: const Color(0xFF171B17),
                            elevation: 4,
                            shadowColor: _terracotta.withOpacity(.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'ثبت‌نام',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
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
}