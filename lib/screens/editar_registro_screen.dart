import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/registro_controller.dart';
import '../controllers/sessao_controller.dart';
import '../models/medicao.dart';
import '../models/registro_auditoria.dart';
import '../models/usuario.dart';
import '../theme/app_colors.dart';
import '../services/medicao_service.dart';
import '../utils/formatadores.dart';
import '../widgets/cabecalho_curvo.dart';
import '../widgets/campos.dart';
import '../widgets/logo_app.dart';
import '../widgets/seletor_contexto.dart';

class EditarRegistroScreen extends StatefulWidget {
  final SessaoController sessao;
  final Medicao medicao;

  const EditarRegistroScreen({
    super.key,
    required this.sessao,
    required this.medicao,
  });

  @override
  State<EditarRegistroScreen> createState() => _EditarRegistroScreenState();
}

class _EditarRegistroScreenState extends State<EditarRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _horarioController = TextEditingController();
  late final TextEditingController _glicemiaController;
  late final RegistroController _controller;
  late DateTime _dataMedicao;
  String? _contexto;
  late Set<String> _sintomas;

  @override
  void initState() {
    super.initState();
    _dataMedicao = widget.medicao.dataMedicao;
    _contexto = widget.medicao.contexto;
    _sintomas = widget.medicao.sintomas.toSet();
    _horarioController.text = formatarDataHora(_dataMedicao);
    _glicemiaController =
        TextEditingController(text: widget.medicao.valorMgdl.toString());
    _controller = RegistroController();
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _horarioController.dispose();
    _glicemiaController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selecionarHorario() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataMedicao,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (data == null || !mounted) {
      return;
    }

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataMedicao),
    );
    if (hora == null) {
      return;
    }

    final selecionado =
        DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    if (selecionado.isAfter(DateTime.now())) {
      if (mounted) {
        mostrarMensagem(context, 'O horário não pode estar no futuro.', erro: true);
      }
      return;
    }

    setState(() {
      _dataMedicao = selecionado;
      _horarioController.text = formatarDataHora(_dataMedicao);
    });
  }

  Future<void> _salvar(Usuario paciente) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final status = await _controller.atualizar(
      paciente: paciente,
      medicao: widget.medicao,
      autor: widget.sessao.usuario!,
      valorMgdl: int.parse(_glicemiaController.text.trim()),
      dataMedicao: _dataMedicao,
      contexto: _contexto,
      sintomas: _sintomas.toList(),
    );

    if (!mounted) {
      return;
    }

    if (status == null) {
      mostrarMensagem(
        context,
        _controller.errorMessage ?? 'Erro ao salvar o registro.',
        erro: true,
      );
      return;
    }

    mostrarMensagem(context, 'Registro atualizado!');
    Navigator.pop(context);
  }

  Future<void> _excluir() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro?'),
        content: const Text('Esta ação não pode ser desfeita.'),
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
    if (confirmado != true) {
      return;
    }

    final sucesso = await _controller.excluir(
      widget.medicao,
      autor: widget.sessao.usuario!,
    );
    if (!mounted) {
      return;
    }

    if (sucesso) {
      mostrarMensagem(context, 'Registro excluído.');
      Navigator.pop(context);
    } else {
      mostrarMensagem(
        context,
        _controller.errorMessage ?? 'Erro ao excluir o registro.',
        erro: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.sessao.usuario!;
    final paciente = widget.sessao.pacienteSelecionado;
    if (paciente == null) {
      return const Scaffold(body: Center(child: Text('Paciente não encontrado.')));
    }

    final podeExcluir =
        RegistroController.podeExcluir(usuario: usuario, paciente: paciente);

    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CabecalhoCurvo(
                alturaTopo: 140,
                topo: const LogoApp(tamanho: 100),
                acaoEsquerda: const BackButton(color: Colors.white),
                acaoDireita: podeExcluir
                    ? IconButton(
                        tooltip: 'Excluir registro',
                        onPressed: _controller.isLoading ? null : _excluir,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      )
                    : null,
                titulo: const TituloCabecalho('Registro'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const RotuloCampo('Paciente'),
                    TextFormField(
                      initialValue: paciente.nome,
                      enabled: false,
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                      decoration: decoracaoCampoBranco().copyWith(
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primaria,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const RotuloCampo('Horário'),
                    TextFormField(
                      controller: _horarioController,
                      readOnly: true,
                      onTap: _selecionarHorario,
                      style: const TextStyle(fontSize: 18),
                      decoration: decoracaoCampoBranco(
                        suffixIcon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const RotuloCampo('Glicemia (mg/dL)'),
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        controller: _glicemiaController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 18),
                        decoration: decoracaoCampoBranco(
                          suffixIcon: const Icon(Icons.edit_outlined),
                        ),
                        validator: RegistroController.validarGlicemia,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SeletorContextoSintomas(
                      contexto: _contexto,
                      sintomas: _sintomas,
                      onContexto: (valor) => setState(() => _contexto = valor),
                      onSintomas: (valor) => setState(() => _sintomas = valor),
                    ),
                    if (widget.medicao.observacao != null) ...[
                      const SizedBox(height: 20),
                      const RotuloCampo('Observação'),
                      Text(
                        widget.medicao.observacao!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaria,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed:
                            _controller.isLoading ? null : () => _salvar(paciente),
                        child: _controller.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Salvar',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _HistoricoAuditoria(medicao: widget.medicao),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// RF08: mostra quem registrou e quem alterou a medição.
class _HistoricoAuditoria extends StatefulWidget {
  final Medicao medicao;

  const _HistoricoAuditoria({required this.medicao});

  @override
  State<_HistoricoAuditoria> createState() => _HistoricoAuditoriaState();
}

class _HistoricoAuditoriaState extends State<_HistoricoAuditoria> {
  late final Stream<List<RegistroAuditoria>> _stream = MedicaoService()
      .watchAuditoria(widget.medicao.pacienteId, widget.medicao.id);

  String _descricao(RegistroAuditoria registro) {
    final valores = switch (registro.acao) {
      'edicao' => ' (${registro.valorAnterior} → ${registro.valorNovo} mg/dL)',
      'criacao' => ' (${registro.valorNovo} mg/dL)',
      _ => '',
    };
    return '${registro.acaoFormatada} por ${registro.nomeResponsavel}$valores';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RegistroAuditoria>>(
      stream: _stream,
      builder: (context, snapshot) {
        final registros = snapshot.data ?? [];
        if (registros.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RotuloCampo('Histórico', tamanho: 16),
            ...registros.map((registro) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${formatarDataHora(registro.data)} • ${_descricao(registro)}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                )),
          ],
        );
      },
    );
  }
}
