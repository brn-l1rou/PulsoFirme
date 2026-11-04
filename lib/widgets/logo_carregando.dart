import 'package:flutter/material.dart';

// Animação das telas de carregamento: a gota cai sobre o monitor, espirra e
// se forma de novo.
//
// O arquivo usado é assets/animacao_carregando.gif, uma versão otimizada de
// assets/Pulso_Firme_loading.gif (6,5 MB): sem o primeiro segundo parado,
// cerca de 5 vezes mais rápida (ciclo de ~1,4 s, que cabe inteiro na tela
// de abertura), reduzida para 400 px e com o fundo já no vermelho das telas (#CC2B25),
// para o símbolo branco animar direto sobre o fundo, como no protótipo da
// tela de loading. Com a opção de reduzir animações, mostra o símbolo parado.
class LogoCarregando extends StatelessWidget {
  final double tamanho;
  final String? mensagem;

  const LogoCarregando({super.key, this.tamanho = 260, this.mensagem});

  @override
  Widget build(BuildContext context) {
    final semAnimacao = MediaQuery.of(context).disableAnimations;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        semAnimacao
            ? Image.asset(
                'assets/icone/icone_foreground.png',
                width: tamanho,
                height: tamanho * 0.77,
                semanticLabel: 'Pulso Firme',
              )
            : Image.asset(
                'assets/animacao_carregando.gif',
                width: tamanho,
                gaplessPlayback: true,
                semanticLabel: 'Pulso Firme carregando',
              ),
        if (mensagem != null) ...[
          const SizedBox(height: 8),
          Text(
            mensagem!,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ],
    );
  }
}
