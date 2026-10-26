import 'package:flutter/material.dart';

import '../controllers/cadastro_controller.dart';

class TelaDeCadastro extends StatefulWidget {
  const TelaDeCadastro({super.key});

  @override
  State<TelaDeCadastro> createState() => _TelaDeCadastroState();
}

class _TelaDeCadastroState extends State<TelaDeCadastro> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  late final CadastroController _controller;

  String _tipoUsuario = 'paciente';
  bool _senhaVisivel = false;
  bool _confirmacaoVisivel = false;

  @override
  void initState() {
    super.initState();
    _controller = CadastroController();
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dataNascimentoController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _controller.dispose();
    super.dispose();
  }

  InputDecoration _decoracaoCampo({
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 18,
      ),
      filled: true,
      fillColor: const Color(0xFFCC2B25),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.white,
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.white,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  Future<void> _selecionarData() async {
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFCC2B25),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dataSelecionada != null) {
      final dataFormatada =
          '${dataSelecionada.day.toString().padLeft(2, '0')}/${dataSelecionada.month.toString().padLeft(2, '0')}/${dataSelecionada.year}';
      _dataNascimentoController.text = dataFormatada;
    }
  }

  String? _validarNome(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu nome completo.';
    }
    return null;
  }

  String? _validarData(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Selecione a data de nascimento.';
    }
    return null;
  }

  String? _validarTelefone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu telefone.';
    }

    final telefone = value.replaceAll(RegExp(r'\D'), '');
    if (telefone.length < 10) {
      return 'Telefone inválido.';
    }

    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu e-mail.';
    }

    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'E-mail inválido.';
    }

    return null;
  }

  String? _validarSenha(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe sua senha.';
    }

    // RNF02: mínimo de 8 caracteres, com maiúscula, minúscula, número e
    // caractere especial.
    final faltando = <String>[
      if (value.length < 8) '8 caracteres',
      if (!RegExp(r'[A-Z]').hasMatch(value)) '1 letra maiúscula',
      if (!RegExp(r'[a-z]').hasMatch(value)) '1 letra minúscula',
      if (!RegExp(r'[0-9]').hasMatch(value)) '1 número',
      if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) '1 caractere especial',
    ];
    if (faltando.isNotEmpty) {
      return 'A senha precisa ter: ${faltando.join(', ')}.';
    }

    return null;
  }

  Widget _botaoVisibilidade(bool visivel, VoidCallback onPressed) {
    return IconButton(
      tooltip: visivel ? 'Ocultar senha' : 'Mostrar senha',
      icon: Icon(
        visivel ? Icons.visibility_off : Icons.visibility,
        color: Colors.white,
      ),
      onPressed: onPressed,
    );
  }

  String? _validarConfirmacaoSenha(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirme sua senha.';
    }

    if (value != _senhaController.text) {
      return 'As senhas não conferem.';
    }

    return null;
  }

  Future<void> _fazerCadastro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    final sucesso = await _controller.cadastrar(
      nome: nome,
      dataNascimento: _dataNascimentoController.text.trim(),
      tipoUsuario: _tipoUsuario,
      telefone: _telefoneController.text.trim(),
      email: email,
      senha: senha,
    );

    if (!mounted) {
      return;
    }

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      return;
    }

    final mensagem = _controller.errorMessage ?? 'Erro ao cadastrar.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC2B25),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.asset(
                        'assets/logo_red_background.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: const BoxDecoration(
                  color: Color(0xFFCC2B25),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(80),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Cadastro',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nome Completo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nomeController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            decoration: _decoracaoCampo(hintText: 'Digite seu nome'),
                            validator: _validarNome,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data de Nascimento',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _dataNascimentoController,
                            readOnly: true,
                            onTap: _selecionarData,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            decoration: _decoracaoCampo(
                              hintText: 'Selecione a data',
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                              ),
                            ),
                            validator: _validarData,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'cuidador', label: Text('Cuidador')),
                            ButtonSegment(value: 'paciente', label: Text('Paciente')),
                          ],
                          selected: {_tipoUsuario},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _tipoUsuario = newSelection.first;
                            });
                          },
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              return Colors.transparent;
                            }),
                            foregroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFFCC2B25);
                              }
                              return Colors.white;
                            }),
                            side: WidgetStateProperty.all(
                              const BorderSide(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Número de Telefone',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _telefoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            decoration: _decoracaoCampo(hintText: '(11) 99999-9999'),
                            validator: _validarTelefone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'E-mail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            decoration: _decoracaoCampo(hintText: 'seuemail@email.com'),
                            validator: _validarEmail,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Senha',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _senhaController,
                            obscureText: !_senhaVisivel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            decoration: _decoracaoCampo(
                              hintText: '********',
                              suffixIcon: _botaoVisibilidade(_senhaVisivel, () {
                                setState(() => _senhaVisivel = !_senhaVisivel);
                              }),
                            ).copyWith(
                              errorMaxLines: 3,
                              helperText:
                                  'Mín. 8 caracteres, com maiúscula, minúscula, número e símbolo.',
                              helperMaxLines: 2,
                              helperStyle: const TextStyle(color: Colors.white70),
                            ),
                            validator: _validarSenha,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Confirmar Senha',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmarSenhaController,
                            obscureText: !_confirmacaoVisivel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            decoration: _decoracaoCampo(
                              hintText: '********',
                              suffixIcon: _botaoVisibilidade(_confirmacaoVisivel, () {
                                setState(() => _confirmacaoVisivel = !_confirmacaoVisivel);
                              }),
                            ),
                            validator: _validarConfirmacaoSenha,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5E5E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _controller.isLoading ? null : _fazerCadastro,
                          child: _controller.isLoading
                              ? const CircularProgressIndicator(
                                  color: Color(0xFFC82B21),
                                )
                              : const Text(
                                  'Cadastro',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC82B21),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
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
