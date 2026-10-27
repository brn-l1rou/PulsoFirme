import 'package:flutter/material.dart';

import '../controllers/sessao_controller.dart';
import '../models/medicamento.dart';
import '../services/medicamento_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatadores.dart';
import '../widgets/cabecalho_curvo.dart';
import '../widgets/campos.dart';
import '../widgets/logo_app.dart';

// RF05: remédios do paciente, com confirmação de cada dose do dia (RF08).
class MedicamentosScreen extends StatefulWidget {
  final SessaoController sessao;

  const MedicamentosScreen({super.key, required this.sessao});

  @override
  State<MedicamentosScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends State<MedicamentosScreen> {
  final MedicamentoService _service = MedicamentoService();
  Stream<List<Medicamento>>? _medicamentos;
  Stream<List<TomadaMedicamento>>? _tomadas;

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

  Future<void> _novo(String pacienteId) async {
    final dados = await showDialog<_DadosMedicamento>(
      context: context,
      builder: (context) => const _DialogoMedicamento(),
    );
    if (dados == null) {
      return;
    }

    await _executar(
      () => _service.criar(
        pacienteId: pacienteId,
        nome: dados.nome,
        dosagem: dados.dosagem,
        horarios: dados.horarios,
        criadoPor: widget.sessao.usuario!.uid,
      ),
      'Medicamento cadastrado!',
    );
  }

  Future<void> _confirmar(Medicamento medicamento, String horario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar dose?'),
        content: Text(
          '${medicamento.nome} ${medicamento.dosagem} das $horario foi tomado agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmado != true) {
      return;
    }

    await _executar(
      () => _service.confirmarTomada(
        medicamento: medicamento,
        horario: horario,
        autor: widget.sessao.usuario!,
      ),
      'Dose confirmada!',
    );
  }

  Future<void> _excluir(Medicamento medicamento) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir ${medicamento.nome}?'),
        content: const Text('Os lembretes deste remédio deixarão de ser enviados.'),
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
      await _executar(() => _service.excluir(medicamento), 'Medicamento excluído.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final paciente = widget.sessao.pacienteSelecionado;
    if (paciente == null) {
      return const Scaffold(body: Center(child: Text('Nenhum paciente selecionado.')));
    }
    _medicamentos ??= _service.watchMedicamentos(paciente.uid);
    _tomadas ??= _service.watchTomadasDoDia(paciente.uid, DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.fundo,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Cadastrar medicamento',
        backgroundColor: AppColors.primaria,
        shape: const CircleBorder(),
        onPressed: () => _novo(paciente.uid),
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
                const TituloCabecalho('Medicamentos'),
                Text(paciente.nome, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(30, 8, 30, 8),
            child: Text(
              'Toque em um horário para confirmar a dose de hoje. Todos os '
              'vinculados recebem um lembrete em cada horário.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Medicamento>>(
              stream: _medicamentos,
              builder: (context, medicamentos) => StreamBuilder<List<TomadaMedicamento>>(
                stream: _tomadas,
                builder: (context, tomadas) {
                  if (medicamentos.hasError) {
                    return const Center(
                      child: Text('Erro ao carregar os medicamentos.'),
                    );
                  }
                  if (!medicamentos.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaria),
                    );
                  }

                  final lista = medicamentos.data!;
                  if (lista.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum medicamento cadastrado.\nToque no + para adicionar.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final confirmadas = tomadas.data ?? const [];
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: lista.length,
                    itemBuilder: (context, index) => _CartaoMedicamento(
                      medicamento: lista[index],
                      tomadas: confirmadas
                          .where((t) => t.medicamentoId == lista[index].id)
                          .toList(),
                      onConfirmar: (horario) => _confirmar(lista[index], horario),
                      onAtivo: (ativo) => _executar(
                        () => _service.alterarAtivo(lista[index], ativo),
                        ativo ? 'Lembretes ativados.' : 'Lembretes pausados.',
                      ),
                      onExcluir: () => _excluir(lista[index]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoMedicamento extends StatelessWidget {
  final Medicamento medicamento;
  final List<TomadaMedicamento> tomadas;
  final ValueChanged<String> onConfirmar;
  final ValueChanged<bool> onAtivo;
  final VoidCallback onExcluir;

  const _CartaoMedicamento({
    required this.medicamento,
    required this.tomadas,
    required this.onConfirmar,
    required this.onAtivo,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication, color: AppColors.primaria, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicamento.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(medicamento.dosagem),
                    ],
                  ),
                ),
                Switch(
                  value: medicamento.ativo,
                  activeTrackColor: AppColors.primaria,
                  onChanged: onAtivo,
                ),
                IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onExcluir,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medicamento.horarios.map((horario) {
                TomadaMedicamento? tomada;
                for (final t in tomadas) {
                  if (t.horario == horario) {
                    tomada = t;
                  }
                }

                if (tomada != null) {
                  return Chip(
                    avatar: const Icon(Icons.check_circle, color: AppColors.destaque),
                    label: Text(
                      '$horario • ${tomada.nomeConfirmadoPor.split(' ').first} '
                      'às ${formatarHora(tomada.data)}',
                    ),
                  );
                }
                return ActionChip(
                  avatar: const Icon(Icons.schedule, color: AppColors.primaria),
                  label: Text('$horario • confirmar'),
                  onPressed: () => onConfirmar(horario),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DadosMedicamento {
  final String nome;
  final String dosagem;
  final List<String> horarios;

  const _DadosMedicamento(this.nome, this.dosagem, this.horarios);
}

class _DialogoMedicamento extends StatefulWidget {
  const _DialogoMedicamento();

  @override
  State<_DialogoMedicamento> createState() => _DialogoMedicamentoState();
}

class _DialogoMedicamentoState extends State<_DialogoMedicamento> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dosagemController = TextEditingController();
  final List<String> _horarios = [];
  String? _erroHorarios;

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    super.dispose();
  }

  Future<void> _adicionarHorario() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (hora == null) {
      return;
    }
    final texto =
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (!_horarios.contains(texto)) {
        _horarios
          ..add(texto)
          ..sort();
      }
      _erroHorarios = null;
    });
  }

  void _salvar() {
    final valido = _formKey.currentState!.validate();
    if (_horarios.isEmpty) {
      setState(() => _erroHorarios = 'Adicione pelo menos um horário.');
      return;
    }
    if (valido) {
      Navigator.pop(
        context,
        _DadosMedicamento(
          _nomeController.text.trim(),
          _dosagemController.text.trim(),
          List.of(_horarios),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String? obrigatorio(String? valor) =>
        (valor == null || valor.trim().isEmpty) ? 'Campo obrigatório.' : null;

    return AlertDialog(
      title: const Text('Novo medicamento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomeController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome (ex.: Metformina)'),
                validator: obrigatorio,
              ),
              TextFormField(
                controller: _dosagemController,
                decoration: const InputDecoration(
                  labelText: 'Dosagem (ex.: 500 mg, 10 UI)',
                ),
                validator: obrigatorio,
              ),
              const SizedBox(height: 16),
              const Text('Horários', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 6,
                children: [
                  ..._horarios.map((horario) => InputChip(
                        label: Text(horario),
                        onDeleted: () => setState(() => _horarios.remove(horario)),
                      )),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Horário'),
                    onPressed: _horarios.length >= 12 ? null : _adicionarHorario,
                  ),
                ],
              ),
              if (_erroHorarios != null)
                Text(_erroHorarios!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
