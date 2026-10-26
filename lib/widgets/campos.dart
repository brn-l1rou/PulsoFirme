import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

InputDecoration decoracaoCampoBranco({
  String? hintText,
  Widget? suffixIcon,
  Color corBorda = AppColors.primaria,
}) {
  OutlineInputBorder borda(Color cor) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cor, width: 2),
      );

  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 16),
    filled: true,
    fillColor: Colors.white,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: borda(corBorda),
    focusedBorder: borda(corBorda),
    errorBorder: borda(Colors.red),
    focusedErrorBorder: borda(Colors.red),
    errorStyle: TextStyle(
      color: corBorda == Colors.white ? Colors.white : Colors.red,
    ),
  );
}

class RotuloCampo extends StatelessWidget {
  final String texto;
  final Color cor;
  final double tamanho;

  const RotuloCampo(
    this.texto, {
    super.key,
    this.cor = AppColors.primaria,
    this.tamanho = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: TextStyle(
          color: cor,
          fontSize: tamanho,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

void mostrarMensagem(BuildContext context, String mensagem, {bool erro = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(mensagem),
      backgroundColor: erro ? Colors.red : Colors.green,
    ),
  );
}
