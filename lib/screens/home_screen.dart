import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/sessao_controller.dart';
import '../theme/app_colors.dart';
import 'perfil_screen.dart';
import 'registros_screen.dart';
import 'relatorio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SessaoController _sessao = SessaoController();
  int _abaAtual = 1;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }
    _sessao.iniciar(uid);
  }

  @override
  void dispose() {
    _sessao.dispose();
    super.dispose();
  }

  Future<void> _sair() async {
    await _sessao.sair();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _sessao,
      builder: (context, _) {
        if (_sessao.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.primaria,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (_sessao.usuario == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_sessao.errorMessage ?? 'Erro ao carregar o usuário.'),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _sair, child: const Text('Voltar ao login')),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _abaAtual,
            children: [
              RelatorioScreen(sessao: _sessao),
              RegistrosScreen(sessao: _sessao),
              PerfilScreen(sessao: _sessao, onSair: _sair),
            ],
          ),
          bottomNavigationBar: _BarraNavegacao(
            abaAtual: _abaAtual,
            onSelecionar: (aba) => setState(() => _abaAtual = aba),
          ),
        );
      },
    );
  }
}

class _BarraNavegacao extends StatelessWidget {
  final int abaAtual;
  final ValueChanged<int> onSelecionar;

  const _BarraNavegacao({required this.abaAtual, required this.onSelecionar});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaria,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(0, const Icon(Icons.bar_chart_rounded), 'Relatório'),
              _item(1, const _IconeRegistro(), 'Registros'),
              _item(2, const Icon(Icons.person), 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int indice, Widget icone, String rotulo) {
    final selecionado = indice == abaAtual;
    return Semantics(
      label: rotulo,
      selected: selecionado,
      button: true,
      child: InkResponse(
        onTap: () => onSelecionar(indice),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: selecionado ? Colors.white : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconTheme(
            data: IconThemeData(
              color: selecionado ? AppColors.primaria : Colors.white,
              size: 32,
            ),
            child: Center(child: icone),
          ),
        ),
      ),
    );
  }
}

// Gota com um "+" dentro, como no protótipo.
class _IconeRegistro extends StatelessWidget {
  const _IconeRegistro();

  @override
  Widget build(BuildContext context) {
    final cor = IconTheme.of(context).color;
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.water_drop_outlined),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Icon(Icons.add, size: 14, color: cor),
        ),
      ],
    );
  }
}
