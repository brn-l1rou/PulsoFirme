import 'package:flutter/material.dart';

import '../controllers/sessao_controller.dart';
import '../models/medicao.dart';
import '../services/medicao_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cabecalho_curvo.dart';
import '../widgets/medicao_card.dart';
import '../widgets/seletor_paciente.dart';
import 'adicionar_registro_screen.dart';
import 'alertas_screen.dart';
import 'editar_registro_screen.dart';

class RegistrosScreen extends StatefulWidget {
  final SessaoController sessao;

  const RegistrosScreen({super.key, required this.sessao});

  @override
  State<RegistrosScreen> createState() => _RegistrosScreenState();
}

class _RegistrosScreenState extends State<RegistrosScreen> {
  final MedicaoService _medicaoService = MedicaoService();
  String? _pacienteDoStream;
  Stream<List<Medicao>>? _stream;

  Stream<List<Medicao>> _medicoesDe(String pacienteId) {
    if (_stream == null || _pacienteDoStream != pacienteId) {
      _pacienteDoStream = pacienteId;
      _stream = _medicaoService.watchMedicoes(pacienteId);
    }
    return _stream!;
  }

  @override
  Widget build(BuildContext context) {
    final sessao = widget.sessao;
    final usuario = sessao.usuario!;
    final paciente = sessao.pacienteSelecionado;

    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: paciente == null
          ? null
          : FloatingActionButton(
              tooltip: 'Adicionar registro',
              backgroundColor: AppColors.primaria,
              shape: const CircleBorder(),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdicionarRegistroScreen(sessao: sessao),
                ),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 40),
            ),
      body: Column(
        children: [
          CabecalhoCurvo(
            alturaTopo: 130,
            topo: const AvatarUsuario(tamanho: 100),
            acaoDireita: paciente == null
                ? null
                : IconButton(
                    tooltip: 'Alertas',
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlertasScreen(sessao: sessao),
                      ),
                    ),
                  ),
            titulo: usuario.isPaciente
                ? TituloCabecalho(usuario.nome)
                : Center(child: SeletorPaciente(sessao: sessao)),
          ),
          Expanded(
            child: paciente == null
                ? const _SemPaciente()
                : StreamBuilder<List<Medicao>>(
                    stream: _medicoesDe(paciente.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Erro ao carregar os registros.'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaria,
                          ),
                        );
                      }

                      final medicoes = snapshot.data!;
                      if (medicoes.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum registro ainda.\nToque no + para adicionar.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: medicoes.length,
                        itemBuilder: (context, index) => MedicaoCard(
                          medicao: medicoes[index],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditarRegistroScreen(
                                sessao: sessao,
                                medicao: medicoes[index],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SemPaciente extends StatelessWidget {
  const _SemPaciente();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Center(
        child: Text(
          'Você ainda não acompanha nenhum paciente.\n\n'
          'Peça para o paciente enviar um convite para o seu e-mail '
          'e aceite-o na aba Perfil.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
