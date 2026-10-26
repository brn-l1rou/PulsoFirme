import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/registro_controller.dart';
import '../controllers/sessao_controller.dart';
import '../models/medicao.dart';
import '../models/usuario.dart';
import '../services/ocr_service.dart';
import '../theme/app_colors.dart';
import '../widgets/campos.dart';
import '../widgets/logo_app.dart';
import '../widgets/seletor_contexto.dart';

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
  final OcrService _ocrService = OcrService();
  late final RegistroController _controller;
  File? _imagem;
  bool _lendoImagem = false;
  String? _contexto;
  Set<String> _sintomas = {};

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

  // RF04/RF09: lê o valor do medidor por foto. O Android/iOS pede a
  // permissão da câmera na primeira vez que ela é usada.
  Future<void> _leituraPorImagem({required bool usarCamera}) async {
    setState(() => _lendoImagem = true);
    LeituraImagem? leitura;
    try {
      leitura = await _ocrService.lerMedidor(usarCamera: usarCamera);
    } on PlatformException catch (e) {
      if (mounted) {
        mostrarMensagem(
          context,
          e.code.contains('access_denied')
              ? 'Permita o acesso à câmera/galeria nas configurações do aparelho.'
              : 'Não foi possível abrir a imagem.',
          erro: true,
        );
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagem(context, 'Não foi possível ler a imagem.', erro: true);
      }
    } finally {
      if (mounted) {
        setState(() => _lendoImagem = false);
      }
    }

    if (leitura == null || !mounted) {
      return;
    }

    setState(() => _imagem = leitura!.imagem);

    if (leitura.candidatos.isEmpty) {
      final mensagem = switch (leitura.foraDaFaixaDoMedidor) {
        'HI' => 'O medidor mostra "HI": glicemia acima do que ele consegue '
            'medir. Procure atendimento médico.',
        'LO' => 'O medidor mostra "LO": glicemia abaixo do que ele consegue '
            'medir. Procure atendimento médico.',
        _ => 'Não identificamos o valor. Tente fotografar só o visor, de '
            'frente, sem reflexo, ou digite o valor.',
      };
      mostrarMensagem(context, mensagem, erro: true);
      return;
    }

    // RN10: o valor lido só é usado depois de confirmado pelo usuário.
    final escolhido = await showDialog<int>(
      context: context,
      builder: (context) => _DialogoConfirmarLeitura(
        candidatos: leitura!.candidatos,
      ),
    );
    if (escolhido != null) {
      _glicemiaController.text = escolhido.toString();
    }
  }

  Future<void> _salvar(Usuario paciente) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final status = await _controller.registrar(
      paciente: paciente,
      autor: widget.sessao.usuario!,
      valorMgdl: int.parse(_glicemiaController.text.trim()),
      observacao: _observacaoController.text,
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
                            onPressed: _lendoImagem
                                ? null
                                : () => _leituraPorImagem(usarCamera: false),
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tirar foto',
                            onPressed: _lendoImagem
                                ? null
                                : () => _leituraPorImagem(usarCamera: true),
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
                        clipBehavior: Clip.antiAlias,
                        child: _lendoImagem
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppColors.primaria,
                                    ),
                                    SizedBox(height: 12),
                                    Text('Lendo o visor...'),
                                  ],
                                ),
                              )
                            : _imagem != null
                                ? Image.file(_imagem!, fit: BoxFit.cover)
                                : const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'Tire uma foto só do visor do medidor, '
                                        'de frente e sem reflexo, para '
                                        'preencher o valor (opcional)',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Color(0xFF666666)),
                                      ),
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
                      SeletorContextoSintomas(
                        fundoEscuro: true,
                        contexto: _contexto,
                        sintomas: _sintomas,
                        onContexto: (valor) => setState(() => _contexto = valor),
                        onSintomas: (valor) => setState(() => _sintomas = valor),
                      ),
                      const SizedBox(height: 16),
                      const RotuloCampo('Observação (opcional)', cor: Colors.white),
                      TextFormField(
                        controller: _observacaoController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 16),
                        decoration: decoracaoCampoBranco(
                          hintText: 'Ex.: comi mais doce no almoço',
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

// RN10: o usuário confirma o valor lido ou escolhe outra opção.
class _DialogoConfirmarLeitura extends StatelessWidget {
  final List<int> candidatos;

  const _DialogoConfirmarLeitura({required this.candidatos});

  @override
  Widget build(BuildContext context) {
    final principal = candidatos.first;
    final outros = candidatos.skip(1).toList();

    return AlertDialog(
      title: const Text('Confirme o valor lido'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Identificamos na imagem:'),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$principal mg/dL',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaria,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Confira se é o mesmo valor do medidor.'),
          if (outros.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Não é? Talvez seja:'),
            Wrap(
              spacing: 8,
              children: outros
                  .map((valor) => ActionChip(
                        label: Text('$valor'),
                        onPressed: () => Navigator.pop(context, valor),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vou digitar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaria),
          onPressed: () => Navigator.pop(context, principal),
          child: const Text(
            'Usar este valor',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
