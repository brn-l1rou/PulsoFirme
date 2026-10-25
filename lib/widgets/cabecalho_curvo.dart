import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Cabeçalho vermelho com a curva branca no canto esquerdo, usado em
// quase todas as telas do protótipo.
class CabecalhoCurvo extends StatelessWidget {
  final Widget topo;
  final Widget titulo;
  final double alturaTopo;
  final Widget? acaoEsquerda;
  final Widget? acaoDireita;

  const CabecalhoCurvo({
    super.key,
    required this.topo,
    required this.titulo,
    this.alturaTopo = 170,
    this.acaoEsquerda,
    this.acaoDireita,
  });

  @override
  Widget build(BuildContext context) {
    final topoSeguro = MediaQuery.of(context).padding.top;
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: alturaTopo + topoSeguro,
          color: AppColors.primaria,
          padding: EdgeInsets.only(top: topoSeguro),
          child: Stack(
            children: [
              Center(child: topo),
              if (acaoEsquerda != null)
                Positioned(top: 8, left: 8, child: acaoEsquerda!),
              if (acaoDireita != null)
                Positioned(top: 8, right: 8, child: acaoDireita!),
            ],
          ),
        ),
        Container(
          color: AppColors.primaria,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            decoration: const BoxDecoration(
              color: AppColors.fundo,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(60),
              ),
            ),
            child: titulo,
          ),
        ),
      ],
    );
  }
}

class TituloCabecalho extends StatelessWidget {
  final String texto;

  const TituloCabecalho(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.primaria,
      ),
    );
  }
}

class AvatarUsuario extends StatelessWidget {
  final double tamanho;

  const AvatarUsuario({super.key, this.tamanho = 110});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(
        Icons.person,
        size: tamanho * 0.7,
        color: AppColors.primaria,
      ),
    );
  }
}
