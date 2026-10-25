import 'package:flutter/material.dart';

import '../models/medicao.dart';
import '../theme/app_colors.dart';
import '../utils/formatadores.dart';

class MedicaoCard extends StatelessWidget {
  final Medicao medicao;
  final VoidCallback? onTap;

  const MedicaoCard({super.key, required this.medicao, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                medicao.foraDoLimite
                    ? Icons.warning_rounded
                    : Icons.check_circle_rounded,
                size: 38,
                color: medicao.foraDoLimite
                    ? AppColors.primaria
                    : AppColors.destaque,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data – Horário',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaria,
                      ),
                    ),
                    Text(
                      formatarDataHora(medicao.dataMedicao),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Text(
                    'Glicemia',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaria,
                    ),
                  ),
                  Text(
                    '${medicao.valorMgdl}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaria,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
