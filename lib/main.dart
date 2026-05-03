import 'package:flutter/material.dart';
import 'package:early_pulso_firme/screens/login_screen.dart';

void main() {
  runApp(const MeuApp());
}

// O MaterialApp é a configuração geral do app
class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // remove a faixa "debug"
      theme: ThemeData(
        fontFamily: 'PlusJakartaSans', // Define a fonte padrão do app
      ), 
      home: const TelaDeLogin(), // Chama a tela que criamos abaixo
    );
  }
}

