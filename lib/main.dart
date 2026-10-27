import 'package:early_pulso_firme/controllers/preferencias_controller.dart';
import 'package:early_pulso_firme/firebase_options.dart';
import 'package:early_pulso_firme/screens/cadastro_screen.dart';
import 'package:early_pulso_firme/screens/home_screen.dart';
import 'package:early_pulso_firme/screens/login_screen.dart';
import 'package:early_pulso_firme/screens/pin_screen.dart';
import 'package:early_pulso_firme/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PreferenciasController.instancia.carregar();

  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final preferencias = PreferenciasController.instancia;
    return ListenableBuilder(
      listenable: preferencias,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        // RNF05: o tamanho escolhido no app soma-se ao ajuste de fonte do
        // sistema.
        builder: (context, child) {
          final sistema = MediaQuery.textScalerOf(context).scale(1);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(sistema * preferencias.escalaFonte),
            ),
            child: child!,
          );
        },
        theme: ThemeData(
          fontFamily: 'PlusJakartaSans',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFCC2B25)),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const TelaLogin(),
          '/cadastro': (context) => const TelaDeCadastro(),
          '/home': (context) => const HomeScreen(),
          '/pin': (context) => const PinScreen(),
        },
      ),
    );
  }
}
