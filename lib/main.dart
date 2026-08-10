import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'edit_pet_page.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await Supabase.initialize(
    url: 'https://psxcktkkrgtzudpcwiei.supabase.co',
    publishableKey: 'sb_publishable_lK-ZFUm1Ni8Ax8aM93m0jg_Tx_225Uc',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reptime',
      theme: ThemeData(
          scaffoldBackgroundColor: const Color.fromARGB(255, 141, 189, 90),
          primaryColor: const Color(0xFF3F5D45),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3F5D45),
            primary: const Color(0xFF3F5D45),
            secondary: const Color(0xFFC98A3E),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF3F5D45),
            foregroundColor: Colors.white,
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
            foregroundColor: Colors.white,
          ),
        ),
      home: Supabase.instance.client.auth.currentSession != null
    ? const HomePage()
    : const LoginPage(),
        )
  ;
  }
}