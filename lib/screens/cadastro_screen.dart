import 'package:flutter/material.dart';

class TelaDeCadastro extends StatefulWidget {
  const TelaDeCadastro({super.key});

  @override
  State<TelaDeCadastro> createState() => _TelaDeCadastroState();
}
  class _TelaDeCadastroState extends State<TelaDeCadastro>{
    String tipoUsuario = 'paciente'; //valorInicial

    @override
    Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      // SingleChildScrollView permite que a tela role se o teclado do celular abrir,
      // evitando que os elementos fiquem espremidos.
      body: SingleChildScrollView(
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
                    color: Color(0xFFCC2B25),
                    borderRadius: BorderRadius.circular(35),
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Image.asset(
                      'assets/logo_red_background.png',
                      fit: BoxFit.contain, // Ajusta a imagem dentro do quadrado branco
                    ),
                  ),
                ),
              ),
            ),

            Container(
              width: double.infinity,
              // O padding interno para os elementos não colarem nas bordas
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFFCC2B25), // Cor vermelha
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

                  // CAMPO NOME COMPLETO
                  // O Padding dá margens nas laterais para o campo não encostar na tela
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
                        const SizedBox(height: 8), // Espaço entre o texto e a caixa
                        TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFCC2B25),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // CAMPO DE DATA DE NASCIMENTO
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
                        TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFCC2B25),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  //CAMPO DE PACIETENTE/CUIDADOR
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SizedBox(
                      width: double.infinity, // Força a largura total da tela (respeitando as margens de 30)
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'cuidador', label: Text('Cuidador')),
                          ButtonSegment(value: 'paciente', label: Text('Paciente')),
                        ],
                        selected: {tipoUsuario},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            tipoUsuario = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          // Aumenta a altura vertical do botão para alinhar ao tamanho dos TextFields
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

                  // CAMPO DE NÚMERO DE TELEFONE
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
                        TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFCC2B25),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // CAMPO E-MAIL
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
                        TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFCC2B25),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // CAMPO DE SENHA
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
                        TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '******',
                            hintStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFCC2B25),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // CAMPO DE CONFIRMAÇÃO DE SENHA
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
                        TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: '******',
                            hintStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFCC2B25),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFFFFF),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),



                  // BOTÃO DE CADASTRO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    // SizedBox aqui é usado para forçar o botão a ter uma largura e altura específicas
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5E5E5), // Botão vermelho
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Bordas arredondadas
                          ),
                        ),
                        onPressed: () {
                          // Aqui entrará a lógica de login no futuro
                        },
                        child: const Text(
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

          ], //
        ),
      ),
    );
  }
}