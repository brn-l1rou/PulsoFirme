import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/preferencias_controller.dart';
import '../controllers/registro_controller.dart';
import '../controllers/sessao_controller.dart';
import '../models/medicao.dart';
import '../models/usuario.dart';
import '../services/medicao_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatadores.dart';
import '../widgets/acao_sos.dart';
import '../widgets/campos.dart';
import '../widgets/logo_app.dart';

// RNF04: interface simplificada para quem tem pouca familiaridade com
// tecnologia. Uma tela só, com texto grande, para registrar a glicemia.
class ModoSimplificadoScreen extends StatefulWidget {
  final SessaoController sessao;

  const ModoSimplificadoScreen({super.key, required this.sessao});

  @override
  State<ModoSimplificadoScreen> createState() => _ModoSimplificadoScreenState();
}

class _ModoSimplificadoScreenState extends State<ModoSimplificadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _glicemiaController = TextEditingController();
  final MedicaoService _medicaoService = MedicaoService();
  late final RegistroController _controller;
  String? _pacienteDoStream;
  Stream<List<Medicao>>? _ultimas;

  @override
  void initState() {
    super.initState();
    _controller = RegistroController();
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _glicemiaController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Stream<List<Medicao>> _ultimasDe(String pacienteId) {
    if (_ultimas == null || _pacienteDoStream != pacienteId) {
      _pacienteDoStream = pacienteId;
      _ultimas = _medicaoService.watchMedicoes(
        pacienteId,
        desde: DateTime.now().subtract(const Duration(days: 7)),
      );
    }
    return _ultimas!;
  }

  Future<void> _registrar(Usuario paciente) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();

    final status = await _controller.registrar(
      paciente: paciente,
      autor: widget.sessao.usuario!,
      valorMgdl: int.parse(_glicemiaController.text.trim()),
    );
    if (!mounted) {
      return;
    }

    if (status == null) {
      mostrarMensagem(
        context,
        _controller.errorMessage ?? 'Erro ao salvar.',
        erro: true,
      );
      return;
    }

    _glicemiaController.clear();
    if (status == StatusGlicemia.normal) {
      mostrarMensagem(context, 'Medição salva!');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, color: AppColors.primaria, size: 56),
        title: Text(
          status == StatusGlicemia.acima ? 'GLICEMIA ALTA' : 'GLICEMIA BAIXA',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'A medição foi salva e os cuidadores foram avisados. Siga as '
          'orientações médicas.',
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDI', style: TextStyle(fontSize: 20)),
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
      backgroundColor: AppColors.primaria,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        PreferenciasController.instancia.definirModoSimplificado(false),
                    icon: const Icon(Icons.apps, color: Colors.white),
                    label: const Text(
                      'Modo completo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const Center(child: LogoApp(tamanho: 80)),
                const SizedBox(height: 16),
                if (paciente == null)
                  const Text(
                    'Nenhum paciente vinculado.\nPeça ajuda para configurar o app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  )
                else ...[
                  _seletorPaciente(paciente),
                  const SizedBox(height: 16),
                  _ultimaMedicao(paciente),
                  const SizedBox(height: 24),
                  const Text(
                    'Valor do medidor (mg/dL)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _glicemiaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    decoration: decoracaoCampoBranco(
                      hintText: '120',
                      corBorda: Colors.white,
                    ).copyWith(
                      errorStyle: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    validator: RegistroController.validarGlicemia,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 80,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed:
                          _controller.isLoading ? null : () => _registrar(paciente),
                      child: _controller.isLoading
                          ? const CircularProgressIndicator(color: AppColors.primaria)
                          : const Text(
                              'REGISTRAR',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaria,
                              ),
                            ),
                    ),
                  ),
                  if (usuario.isPaciente) ...[
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 70,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => enviarSosComConfirmacao(context, usuario),
                        icon: const Icon(Icons.sos, color: Colors.white, size: 36),
                        label: const Text(
                          'PEDIR AJUDA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _seletorPaciente(Usuario paciente) {
    final pacientes = widget.sessao.pacientes;
    if (pacientes.length <= 1) {
      return Text(
        paciente.nome,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Cuidador com vários pacientes: um botão grande para cada um.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: pacientes
          .map((p) => ChoiceChip(
                label: Text(p.nome, style: const TextStyle(fontSize: 20)),
                selected: p.uid == paciente.uid,
                onSelected: (_) => widget.sessao.selecionarPaciente(p.uid),
              ))
          .toList(),
    );
  }

  Widget _ultimaMedicao(Usuario paciente) {
    return StreamBuilder<List<Medicao>>(
      stream: _ultimasDe(paciente.uid),
      builder: (context, snapshot) {
        final ultima =
            (snapshot.data?.isNotEmpty ?? false) ? snapshot.data!.first : null;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ultima == null
              ? const Text(
                  'Nenhuma medição nos últimos 7 dias.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                )
              : Column(
                  children: [
                    const Text('Última medição', style: TextStyle(fontSize: 18)),
                    Text(
                      '${ultima.valorMgdl} mg/dL',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: ultima.foraDoLimite
                            ? AppColors.primaria
                            : AppColors.destaque,
                      ),
                    ),
                    Text(
                      formatarDataHora(ultima.dataMedicao),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
