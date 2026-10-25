import 'package:flutter/material.dart';

import '../controllers/sessao_controller.dart';
import '../theme/app_colors.dart';

// Botão vermelho com o nome do paciente. Para cuidadores com mais de um
// paciente vinculado, permite trocar o paciente acompanhado.
class SeletorPaciente extends StatelessWidget {
  final SessaoController sessao;

  const SeletorPaciente({super.key, required this.sessao});

  @override
  Widget build(BuildContext context) {
    final paciente = sessao.pacienteSelecionado;
    final podeTrocar = sessao.pacientes.length > 1;

    return PopupMenuButton<String>(
      enabled: podeTrocar,
      onSelected: sessao.selecionarPaciente,
      itemBuilder: (context) => sessao.pacientes
          .map((p) => PopupMenuItem(value: p.uid, child: Text(p.nome)))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaria,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                paciente?.nome ?? 'Nenhum paciente',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (podeTrocar) ...[
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primaria,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
