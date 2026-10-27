import 'package:flutter/material.dart';

import '../controllers/sessao_controller.dart';
import '../models/medicao.dart';
import '../models/usuario.dart';
import '../services/medicao_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatadores.dart';
import '../widgets/cabecalho_curvo.dart';
import '../widgets/acao_sos.dart';
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

  Future<void> _enviarSos(Usuario paciente) async {
    setState(() => _enviandoSos = true);
    await enviarSosComConfirmacao(context, paciente);
    if (mounted) {
      setState(() => _enviandoSos = false);
    }
  }

  // RF20: filtro do histórico por período (null = todos os registros).
  DateTimeRange? _filtro;

  Stream<List<Medicao>> _medicoesDe(String pacienteId) {
    final chave = '$pacienteId-${_filtro?.start}-${_filtro?.end}';
    if (_stream == null || _pacienteDoStream != chave) {
      _pacienteDoStream = chave;
      final filtro = _filtro;
      _stream = _medicaoService.watchMedicoes(
        pacienteId,
        desde: filtro?.start,
        // O fim do período inclui o dia inteiro.
        ate: filtro?.end.add(const Duration(days: 1)),
      );
    }
    return _stream!;
  }

  Future<void> _escolherPeriodo() async {
    final hoje = DateTime.now();
    final periodo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(hoje.year, hoje.month, hoje.day),
      initialDateRange: _filtro,
      helpText: 'Filtrar registros por data',
      saveText: 'Filtrar',
    );
    if (periodo != null) {
      setState(() => _filtro = periodo);
    }
  }

  Widget _barraFiltro() {
    final filtro = _filtro;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(
              Icons.date_range,
              size: 18,
              color: AppColors.primaria,
            ),
            label: Text(
              filtro == null
                  ? 'Filtrar por data'
                  : '${formatarData(filtro.start)} a ${formatarData(filtro.end)}',
            ),
            onPressed: _escolherPeriodo,
          ),
          if (filtro != null)
            IconButton(
              tooltip: 'Limpar filtro',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _filtro = null),
            ),
        ],
      ),
    );
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
            topo: AvatarUsuario(uid: paciente?.uid, tamanho: 100),
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
          if (paciente != null) _barraFiltro(),
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
                        return Center(
                          child: Text(
                            _filtro == null
                                ? 'Nenhum registro ainda.\nToque no + para adicionar.'
                                : 'Nenhum registro no período escolhido.',
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
