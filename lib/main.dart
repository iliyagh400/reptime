import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_gate.dart';
import 'update_password_page.dart';
import 'notification_service.dart';

// کلید سراسری برای ناوبری هنگام دریافت رویدادهای دیپ‌لینک
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  await Supabase.initialize(
    url: 'https://psxcktkkrgtzudpcwiei.supabase.co',
    anonKey: 'sb_publishable_lK-ZFUm1Ni8Ax8aM93m0jg_Tx_225Uc',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // گوش دادن به تغییرات وضعیت احراز هویت (مخصوصاً دیپ‌لینک بازیابی رمز)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const UpdatePasswordPage(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Reptime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF8DBD5A),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3F5D45),
          secondary: Color(0xFFC98A3E),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF3F5D45),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        textTheme: GoogleFonts.vazirmatnTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F5D45),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFC98A3E),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
