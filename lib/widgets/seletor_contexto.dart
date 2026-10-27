import 'package:flutter/material.dart';

import '../models/medicao.dart';
import '../theme/app_colors.dart';
import 'campos.dart';

// RF12/RF13: escolha do momento da medição e dos sintomas, usada nas
// telas de adicionar (fundo vermelho) e editar (fundo claro).
class SeletorContextoSintomas extends StatelessWidget {
  final String? contexto;
  final Set<String> sintomas;
  final ValueChanged<String?> onContexto;
  final ValueChanged<Set<String>> onSintomas;
  final bool fundoEscuro;

  const SeletorContextoSintomas({
    super.key,
    required this.contexto,
    required this.sintomas,
    required this.onContexto,
    required this.onSintomas,
    this.fundoEscuro = false,
  });

  @override
  Widget build(BuildContext context) {
    final corRotulo = fundoEscuro ? Colors.white : AppColors.primaria;

    Widget chip({
      required String rotulo,
      required bool selecionado,
      required ValueChanged<bool> onSelected,
    }) {
      return FilterChip(
        label: Text(rotulo),
        selected: selecionado,
        onSelected: onSelected,
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: fundoEscuro ? const Color(0xFF8E1C17) : AppColors.primaria,
        side: BorderSide(
          color: fundoEscuro ? Colors.white : AppColors.primaria,
        ),
        labelStyle: TextStyle(
          color: selecionado ? Colors.white : AppColors.primaria,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RotuloCampo('Momento da medição (opcional)', cor: corRotulo),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: contextosMedicao.entries
              .map((e) => chip(
                    rotulo: e.value,
                    selecionado: contexto == e.key,
                    // Tocar de novo no mesmo chip desmarca.
                    onSelected: (marcado) => onContexto(marcado ? e.key : null),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        RotuloCampo('Sintomas (opcional)', cor: corRotulo),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: sintomasDisponiveis
              .map((sintoma) => chip(
                    rotulo: sintoma,
                    selecionado: sintomas.contains(sintoma),
                    onSelected: (marcado) {
                      final novos = {...sintomas};
                      marcado ? novos.add(sintoma) : novos.remove(sintoma);
                      onSintomas(novos);
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}
