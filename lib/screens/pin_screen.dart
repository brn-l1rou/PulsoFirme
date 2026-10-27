import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/pin_service.dart';
import '../theme/app_colors.dart';
import '../widgets/campos.dart';
import '../widgets/logo_app.dart';

// Pede o PIN de 4 dígitos ao abrir o app quando o usuário já está logado.
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final PinService _pinService = PinService();
  String _digitado = '';
  String? _erro;
  bool _verificando = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _digitar(String digito) async {
    if (_verificando || _digitado.length >= 4) {
      return;
    }
    setState(() {
      _digitado += digito;
      _erro = null;
    });
    if (_digitado.length == 4) {
      await _verificar();
    }
  }

  Future<void> _verificar() async {
    setState(() => _verificando = true);
    final restantes = await _pinService.verificar(_uid, _digitado);
    if (!mounted) {
      return;
    }

    if (restantes == null) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    if (restantes == 0) {
      await _sairDaConta('Muitas tentativas erradas. Entre com sua senha.');
      return;
    }

    setState(() {
      _digitado = '';
      _verificando = false;
      _erro = 'PIN incorreto. $restantes tentativa(s) restante(s).';
    });
  }

  // Esquecer o PIN ou errar demais obriga a entrar de novo com a senha.
  Future<void> _sairDaConta(String mensagem) async {
    await _pinService.removerPin(_uid);
    await FirebaseAuth.instance.signOut();
    if (!mounted) {
      return;
    }
    mostrarMensagem(context, mensagem, erro: true);
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _tecla(String rotulo, {VoidCallback? onTap, IconData? icone}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 76,
        height: 76,
        child: TextButton(
          style: TextButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            foregroundColor: Colors.white,
          ),
          onPressed: onTap ?? () => _digitar(rotulo),
          child: icone != null
              ? Icon(icone, size: 28)
              : Text(rotulo, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaria,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const LogoApp(tamanho: 90),
                const SizedBox(height: 20),
                const Text(
                  'Digite seu PIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    4,
                    (i) => Container(
                      margin: const EdgeInsets.all(8),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: i < _digitado.length ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: _erro == null
                      ? null
                      : Text(
                          _erro!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
                for (final linha in const [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                ])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: linha.map((d) => _tecla(d)).toList(),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 92),
                    _tecla('0'),
                    _tecla(
                      'Apagar',
                      icone: Icons.backspace_outlined,
                      onTap: () {
                        if (_digitado.isNotEmpty) {
                          setState(() => _digitado =
                              _digitado.substring(0, _digitado.length - 1));
                        }
                      },
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () =>
                      _sairDaConta('Entre com seu e-mail e senha para continuar.'),
                  child: const Text(
                    'Esqueci meu PIN',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
