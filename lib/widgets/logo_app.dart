import 'package:flutter/material.dart';

class LogoApp extends StatelessWidget {
  final double tamanho;

  const LogoApp({super.key, this.tamanho = 110});

  @override
  Widget build(BuildContext context) {
    final raio = tamanho * 0.23;
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(raio),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(raio),
        child: Image.asset(
          'assets/logo_white_background.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
