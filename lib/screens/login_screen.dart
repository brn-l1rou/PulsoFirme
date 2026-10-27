import 'package:flutter/material.dart';

import '../controllers/login_controller.dart';
import 'cadastro_screen.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  late final LoginController _controller;
  bool _senhaVisivel = false;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _controller.dispose();
    super.dispose();
  }

  InputDecoration _decoracaoCampo({
    String? hintText,
    required Color fillColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      hintStyle: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 18,
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFC82B21),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFC82B21),
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

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu e-mail.';
    }

    final email = value.trim();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) {
      return 'E-mail inválido.';
    }

    return null;
  }

  String? _validarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe sua senha.';
    }

    return null;
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    final sucesso = await _controller.signIn(
      email: email,
      password: senha,
    );

    if (!mounted) {
      return;
    }

    if (sucesso) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    final mensagem = _controller.errorMessage ?? 'Erro ao realizar login.';
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
      backgroundColor: const Color(0xFFCC2B25),
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
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(35),
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(35),
                     child: Image.asset(
                       'assets/logo_white_background.png',
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
                 color: Color(0xFFF9F5F5),
                 borderRadius: BorderRadius.only(
                   topLeft: Radius.circular(80),
                 ),
               ),
               child: Column(
                 children: [
                   const Text(
                     'Login',
                     style: TextStyle(
                       fontSize: 36,
                       fontWeight: FontWeight.bold,
                       color: Color(0xFFCC2B25),
                     ),
                   ),
                   const SizedBox(height: 40),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 30),
                     child: TextFormField(
                       controller: _emailController,
                       keyboardType: TextInputType.emailAddress,
                       style: const TextStyle(
                         color: Colors.black,
                         fontSize: 18,
                       ),
                       decoration: _decoracaoCampo(
                         hintText: 'Email',
                         fillColor: const Color(0xFFFFFFFF),
                       ),
                       validator: _validarEmail,
                     ),
                   ),
                   const SizedBox(height: 20),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 30),
                     child: TextFormField(
                       controller: _senhaController,
                       obscureText: !_senhaVisivel,
                       style: const TextStyle(
                         color: Colors.black,
                         fontSize: 18,
                       ),
                       decoration: _decoracaoCampo(
                         hintText: 'Senha',
                         fillColor: const Color(0xFFE5E5E5),
                         // RF18: mostrar/ocultar a senha digitada.
                         suffixIcon: IconButton(
                           tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                           icon: Icon(
                             _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                             color: const Color(0xFF666666),
                           ),
                           onPressed: () {
                             setState(() {
                               _senhaVisivel = !_senhaVisivel;
                             });
                           },
                         ),
                       ),
                       validator: _validarSenha,
                     ),
                   ),
                   const SizedBox(height: 40),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 30),
                     child: SizedBox(
                       width: double.infinity,
                       height: 55,
                       child: ElevatedButton(
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFFCC2B25),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(10),
                           ),
                         ),
                         onPressed: _controller.isLoading ? null : _fazerLogin,
                         child: _controller.isLoading
                             ? const CircularProgressIndicator(color: Colors.white)
                             : const Text(
                                 'Login',
                                 style: TextStyle(
                                   fontSize: 20,
                                   fontWeight: FontWeight.bold,
                                   color: Colors.white,
                                 ),
                               ),
                       ),
                     ),
                   ),
                   const SizedBox(height: 15),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Text(
                         'Não tem conta? ',
                         style: TextStyle(color: Color(0xFF00796B)),
                       ),
                       GestureDetector(
                         onTap: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => const TelaDeCadastro(),
                             ),
                           );
                         },
                         child: const Text(
                           'Cadastro',
                           style: TextStyle(
                             color: Color(0xFF00796B),
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 181),
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
