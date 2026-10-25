import 'package:early_pulso_firme/firebase_options.dart';
import 'package:early_pulso_firme/screens/cadastro_screen.dart';
import 'package:early_pulso_firme/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MeuApp());
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home'),
      ),
    );
  }
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'PlusJakartaSans',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const TelaLogin(),
        '/cadastro': (context) => const TelaDeCadastro(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

