import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/foto_service.dart';
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

// Foto de perfil redonda; sem foto (ou sem [uid]), mostra o ícone padrão.
class AvatarUsuario extends StatefulWidget {
  final String? uid;
  final double tamanho;
  final double borda;

  const AvatarUsuario({super.key, this.uid, this.tamanho = 110, this.borda = 3});

  @override
  State<AvatarUsuario> createState() => _AvatarUsuarioState();
}

class _AvatarUsuarioState extends State<AvatarUsuario> {
  Stream<Uint8List?>? _foto;

  @override
  void initState() {
    super.initState();
    _assinar();
  }

  @override
  void didUpdateWidget(covariant AvatarUsuario oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _assinar();
    }
  }

  void _assinar() {
    final uid = widget.uid;
    _foto = uid == null
        ? null
        // Sem permissão (ex.: vínculo desfeito) mostra só o ícone.
        : FotoService().watchFoto(uid).handleError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Uint8List?>(
      stream: _foto,
      builder: (context, snapshot) {
        final foto = snapshot.data;
        return Container(
          width: widget.tamanho,
          height: widget.tamanho,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: widget.borda),
            image: foto == null
                ? null
                : DecorationImage(image: MemoryImage(foto), fit: BoxFit.cover),
          ),
          child: foto != null
              ? null
              : Icon(
                  Icons.person,
                  size: widget.tamanho * 0.7,
                  color: AppColors.primaria,
                ),
        );
      },
    );
  }
}
