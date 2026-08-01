import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
// import 'signup_page.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: Supabase.instance.client.auth.currentSession != null
    ? const Scaffold(body: Center(child: Text('خوش اومدی، لاگین کردی ✅')))
    : const LoginPage(),
        )
  ;
  }
}