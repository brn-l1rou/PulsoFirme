import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/registro_controller.dart';
import '../controllers/sessao_controller.dart';
import '../models/medicao.dart';
import '../models/usuario.dart';
import '../theme/app_colors.dart';
import '../widgets/campos.dart';
import '../widgets/logo_app.dart';

class AdicionarRegistroScreen extends StatefulWidget {
  final SessaoController sessao;

  const AdicionarRegistroScreen({super.key, required this.sessao});

  @override
  State<AdicionarRegistroScreen> createState() =>
      _AdicionarRegistroScreenState();
}

class _AdicionarRegistroScreenState extends State<AdicionarRegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _glicemiaController = TextEditingController();
  final _observacaoController = TextEditingController();
  late final RegistroController _controller;

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
    _observacaoController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // RF04/RF09: a leitura por imagem (OCR) ainda será implementada.
  void _leituraPorImagem() {
    mostrarMensagem(context, 'Leitura por imagem em desenvolvimento.');
  }

  Future<void> _salvar(Usuario paciente) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final status = await _controller.registrar(
      paciente: paciente,
      registradoPor: widget.sessao.usuario!.uid,
      valorMgdl: int.parse(_glicemiaController.text.trim()),
      observacao: _observacaoController.text,
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

    // RF11: avisa na hora quando a leitura está fora dos limites.
    if (status != StatusGlicemia.normal) {
      await _mostrarAlerta(paciente, status);
      if (!mounted) {
        return;
      }
    } else {
      mostrarMensagem(context, 'Registro salvo com sucesso!');
    }

    Navigator.pop(context);
  }

  Future<void> _mostrarAlerta(Usuario paciente, StatusGlicemia status) {
    final acima = status == StatusGlicemia.acima;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_rounded,
          color: AppColors.primaria,
          size: 48,
        ),
        title: Text(
          acima ? 'Glicemia acima do limite!' : 'Glicemia abaixo do limite!',
        ),
        content: Text(
          'O valor registrado está fora da faixa definida para '
          '${paciente.nome} (${paciente.limiteMinimo} a '
          '${paciente.limiteMaximo} mg/dL). '
          'Siga as orientações médicas e, se necessário, procure atendimento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessao = widget.sessao;
    final paciente = sessao.pacienteSelecionado;

    return Scaffold(
      backgroundColor: AppColors.primaria,
      body: SafeArea(
        child: paciente == null
            ? const Center(
                child: Text(
                  'Nenhum paciente selecionado.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: BackButton(color: Colors.white),
                      ),
                      const Center(child: LogoApp(tamanho: 100)),
                      const SizedBox(height: 16),
                      if (sessao.usuario!.isCuidador)
                        Center(
                          child: Text(
                            'Paciente: ${paciente.nome}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Escolher imagem',
                            onPressed: _leituraPorImagem,
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tirar foto',
                            onPressed: _leituraPorImagem,
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            'Imagem do medidor (opcional)',
                            style: TextStyle(color: Color(0xFF7A7A7A)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const RotuloCampo('Glicemia (mg/dL)', cor: Colors.white),
                      TextFormField(
                        controller: _glicemiaController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 18),
                        decoration: decoracaoCampoBranco(
                          hintText: 'Ex.: 120',
                          corBorda: Colors.white,
                        ),
                        validator: RegistroController.validarGlicemia,
                      ),
                      const SizedBox(height: 16),
                      const RotuloCampo('Observação (opcional)', cor: Colors.white),
                      TextFormField(
                        controller: _observacaoController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 16),
                        decoration: decoracaoCampoBranco(
                          hintText: 'Ex.: após o almoço, tontura...',
                          corBorda: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _controller.isLoading
                              ? null
                              : () => _salvar(paciente),
                          child: _controller.isLoading
                              ? const CircularProgressIndicator(
                                  color: AppColors.primaria,
                                )
                              : const Text(
                                  'Salvar',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaria,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
