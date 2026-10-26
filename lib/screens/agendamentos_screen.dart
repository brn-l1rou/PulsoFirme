import 'package:flutter/material.dart';

import '../controllers/sessao_controller.dart';
import '../models/agendamento.dart';
import '../services/agendamento_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cabecalho_curvo.dart';
import '../widgets/campos.dart';
import '../widgets/logo_app.dart';

// RF14: medições programadas do paciente selecionado.
class AgendamentosScreen extends StatefulWidget {
  final SessaoController sessao;

  const AgendamentosScreen({super.key, required this.sessao});

  @override
  State<AgendamentosScreen> createState() => _AgendamentosScreenState();
}

class _AgendamentosScreenState extends State<AgendamentosScreen> {
  final AgendamentoService _service = AgendamentoService();
  Stream<List<Agendamento>>? _stream;

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    try {
      await acao();
      if (mounted) {
        mostrarMensagem(context, sucesso);
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagem(context, 'Não foi possível concluir a ação.', erro: true);
      }
    }
  }

  Future<void> _novoAgendamento(String pacienteId) async {
    final dados = await showDialog<_DadosAgendamento>(
      context: context,
      builder: (context) => const _DialogoAgendamento(),
    );
    if (dados == null) {
      return;
    }

    await _executar(
      () => _service.criar(
        pacienteId: pacienteId,
        hora: dados.hora,
        frequencia: dados.frequencia,
        diaSemana: dados.diaSemana,
        toleranciaMinutos: dados.toleranciaMinutos,
        criadoPor: widget.sessao.usuario!.uid,
      ),
      'Medição agendada!',
    );
  }

  Future<void> _excluir(Agendamento agendamento) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir agendamento?'),
        content: Text(agendamento.descricao),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.primaria),
            ),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await _executar(() => _service.excluir(agendamento), 'Agendamento excluído.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final paciente = widget.sessao.pacienteSelecionado;
    if (paciente == null) {
      return const Scaffold(body: Center(child: Text('Nenhum paciente selecionado.')));
    }
    _stream ??= _service.watchAgendamentos(paciente.uid);

    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Agendar medição',
        backgroundColor: AppColors.primaria,
        shape: const CircleBorder(),
        onPressed: () => _novoAgendamento(paciente.uid),
        child: const Icon(Icons.add, color: Colors.white, size: 36),
      ),
      body: Column(
        children: [
          CabecalhoCurvo(
            alturaTopo: 130,
            topo: const LogoApp(tamanho: 90),
            acaoEsquerda: const BackButton(color: Colors.white),
            titulo: Column(
              children: [
                const TituloCabecalho('Agendamentos'),
                Text(paciente.nome, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(30, 8, 30, 8),
            child: Text(
              'Você e os cuidadores recebem um lembrete no horário e um aviso '
              'se a medição não for registrada dentro da tolerância.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Agendamento>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar os agendamentos.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaria),
                  );
                }

                final agendamentos = snapshot.data!;
                if (agendamentos.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma medição agendada.\nToque no + para agendar.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: agendamentos.length,
                  itemBuilder: (context, index) {
                    final agendamento = agendamentos[index];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.alarm,
                          color: AppColors.primaria,
                          size: 32,
                        ),
                        title: Text(
                          agendamento.descricao,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Tolerância: ${agendamento.toleranciaMinutos} min',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: agendamento.ativo,
                              activeTrackColor: AppColors.primaria,
                              onChanged: (ativo) => _executar(
                                () => _service.alterarAtivo(agendamento, ativo),
                                ativo ? 'Agendamento ativado.' : 'Agendamento pausado.',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Excluir',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _excluir(agendamento),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DadosAgendamento {
  final String hora;
  final String frequencia;
  final int? diaSemana;
  final int toleranciaMinutos;

  const _DadosAgendamento({
    required this.hora,
    required this.frequencia,
    required this.diaSemana,
    required this.toleranciaMinutos,
  });
}

class _DialogoAgendamento extends StatefulWidget {
  const _DialogoAgendamento();

  @override
  State<_DialogoAgendamento> createState() => _DialogoAgendamentoState();
}

class _DialogoAgendamentoState extends State<_DialogoAgendamento> {
  static const Map<String, String> _nomesFrequencia = {
    'diaria': 'Diária',
    'semanal': 'Semanal',
    'quinzenal': 'Quinzenal',
  };

  TimeOfDay _hora = const TimeOfDay(hour: 8, minute: 0);
  String _frequencia = 'diaria';
  int _diaSemana = DateTime.now().weekday;
  int _tolerancia = 30;

  String get _horaFormatada =>
      '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';

  Future<void> _escolherHora() async {
    final hora = await showTimePicker(context: context, initialTime: _hora);
    if (hora != null) {
      setState(() => _hora = hora);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agendar medição'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text('Horário: $_horaFormatada'),
            onTap: _escolherHora,
          ),
          DropdownButtonFormField<String>(
            initialValue: _frequencia,
            decoration: const InputDecoration(labelText: 'Frequência'),
            items: Agendamento.frequencias
                .map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(_nomesFrequencia[f]!),
                    ))
                .toList(),
            onChanged: (valor) => setState(() => _frequencia = valor!),
          ),
          if (_frequencia != 'diaria')
            DropdownButtonFormField<int>(
              initialValue: _diaSemana,
              decoration: const InputDecoration(labelText: 'Dia da semana'),
              items: List.generate(
                7,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(Agendamento.nomesDias[i]),
                ),
              ),
              onChanged: (valor) => setState(() => _diaSemana = valor!),
            ),
          DropdownButtonFormField<int>(
            initialValue: _tolerancia,
            decoration: const InputDecoration(
              labelText: 'Avisar se não medir em até',
            ),
            items: const [15, 30, 60, 120]
                .map((m) => DropdownMenuItem(value: m, child: Text('$m minutos')))
                .toList(),
            onChanged: (valor) => setState(() => _tolerancia = valor!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            _DadosAgendamento(
              hora: _horaFormatada,
              frequencia: _frequencia,
              diaSemana: _frequencia == 'diaria' ? null : _diaSemana,
              toleranciaMinutos: _tolerancia,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
