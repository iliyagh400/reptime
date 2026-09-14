// lib/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'repositories/auth_repository.dart';
import 'login_page.dart';
import 'home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthRepository _authRepo = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authRepo.authStateChanges,
      builder: (context, snapshot) {
        // وضعیت اولیه قبل از لود شدن سوپابیس
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;

        // کاربر لاگین نکرده است
        if (session == null) {
          return const LoginPage();
        }

        // کاربر لاگین است؛ اکنون بررسی جدول allowed_users
        return FutureBuilder<bool>(
          future: _authRepo.isUserAllowed(),
          builder: (context, allowSnapshot) {
            if (allowSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final isAllowed = allowSnapshot.data ?? false;

            if (!isAllowed) {
              // در صورت مجاز نبودن ایمیل کاربر
              return Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 72,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'دسترسی غیرمجاز',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'حساب کاربری (${_authRepo.currentUserEmail ?? ''}) در لیست کاربران مجاز ثبت نشده است.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _authRepo.signOut();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('خروج و ورود با حسابی دیگر'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // کاربر لاگین است و دسترسی مجاز دارد -> ورود به صفحه اصلی
            return const HomePage();
          },
        );
      },
    );
  }
}
