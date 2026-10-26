import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/pin_service.dart';
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

    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // PIN de acesso, se o usuário ativou nas configurações.
    final temPin = await PinService().temPin(usuario.uid);
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, temPin ? '/pin' : '/home');
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
