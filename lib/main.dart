import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      home: Scaffold(
        appBar: AppBar(title: const Text('Reptime')),
        body: const Center(
          child: Text('اتصال به Supabase با موفقیت انجام شد ✅'),
        ),
      ),
    );
  }
}