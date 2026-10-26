import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/sessao_controller.dart';
import '../models/medicao.dart';
import '../models/usuario.dart';
import '../services/alerta_service.dart';
import '../services/medicao_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cabecalho_curvo.dart';
import '../widgets/campos.dart';
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
  bool _enviandoSos = false;

  // RF06: envia um alerta de emergência com a localização do paciente
  // para todos os cuidadores vinculados.
  Future<void> _enviarSos(Usuario paciente) async {
    if (paciente.cuidadoresAutorizados.isEmpty) {
      mostrarMensagem(
        context,
        'Você ainda não tem cuidadores vinculados para receber o SOS.',
        erro: true,
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.sos, color: AppColors.primaria, size: 48),
        title: const Text('Enviar pedido de ajuda?'),
        content: const Text(
          'Seus cuidadores receberão um alerta de emergência com a sua '
          'localização atual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaria),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmado != true) {
      return;
    }

    setState(() => _enviandoSos = true);
    try {
      final alertaService = AlertaService();
      final posicao = await alertaService.obterLocalizacao();
      await alertaService
          .enviarSos(pacienteId: paciente.uid, posicao: posicao)
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        mostrarMensagem(
          context,
          posicao == null
              ? 'SOS enviado (sem localização: verifique o GPS e a permissão).'
              : 'SOS enviado com a sua localização!',
        );
      }
    } on TimeoutException {
      // O Firestore mantém o alerta na fila e envia quando a conexão voltar.
      if (mounted) {
        mostrarMensagem(
          context,
          'Sem conexão: o SOS será enviado quando a internet voltar. '
          'Se for urgente, ligue 192.',
          erro: true,
        );
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagem(
          context,
          'Não foi possível enviar o SOS. Se for urgente, ligue 192.',
          erro: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviandoSos = false);
      }
    }
  }

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
            acaoEsquerda: usuario.isPaciente
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _enviandoSos ? null : () => _enviarSos(usuario),
                      child: _enviandoSos
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.primaria,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SOS',
                              style: TextStyle(
                                color: AppColors.primaria,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  )
                : null,
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
