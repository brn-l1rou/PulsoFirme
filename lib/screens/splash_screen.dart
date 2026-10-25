import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirecionar();
  }

  // RF19: o Firebase Auth mantém a sessão salva no aparelho, então quem
  // já fez login vai direto para o app.
  Future<void> _redirecionar() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) {
      return;
    }

    final logado = FirebaseAuth.instance.currentUser != null;
    Navigator.pushReplacementNamed(context, logado ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaria,
      body: Center(
        child: Image.asset(
          'assets/logo_red_background.png',
          width: 180,
        ),
      ),
    );
  }
}
