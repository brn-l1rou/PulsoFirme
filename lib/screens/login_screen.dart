import 'package:flutter/material.dart';
import 'cadastro_screen.dart';

class TelaDeLogin extends StatelessWidget {
  const TelaDeLogin({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFFCC2B25), 
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                  ),
                  
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Image.asset(
                      'assets/logo_white_background.png',
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
                color: Color(0xFFF9F5F5), // Cor branca/off-white
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

            // CAMPO DE EMAIL
            // O Padding dá margens nas laterais para o campo não encostar na tela
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Email', // O texto que fica de hint
                  filled: true,
                  fillColor: const Color(0xFFFFFFFF), // Fundo branco
                  // Tira a linha de baixo padrão do Android e arredonda as bordas
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFC82B21), //borda colorida
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFC82B21),
                      width: 2,
                    )
                  )
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // CAMPO DE SENHA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                obscureText: true, // Esconde o texto digitado (***)
                decoration: InputDecoration(
                  hintText: 'Senha',
                  filled: true,
                  fillColor: const Color(0xFFE5E5E5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFC82B21), //borda colorida
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFC82B21),
                      width: 2,
                    )
                  )
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // BOTÃO DE LOGIN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              // SizedBox aqui é usado para forçar o botão a ter uma largura e altura específicas
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC2B25), // Botão vermelho
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Bordas arredondadas
                    ),
                  ),
                  onPressed: () {
                    // Aqui entrará a lógica de login no futuro
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 20, 
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 15),

            // TEXTO DE CADASTRO NO RODAPÉ
            // Usamos uma Row (Linha) para colocar um texto do lado do outro
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centraliza os itens na linha
              children: [
                const Text(
                  'Não tem conta? ',
                  style: TextStyle(color: Color(0xFF00BFA5)),
                ),
                GestureDetector( // Faz o texto ser clicável
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TelaDeCadastro()
                      ),
                    );
                  },
                  child: const Text(
                    'Cadastro',
                    style: TextStyle(
                      color: Color(0xFF00BFA5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 181), // preenchimento da tela branca para que o fundo vermelho não apareça
               ],
              ), 
            ),

          ], // 
        ),
      ), 
    ); 
  }
}