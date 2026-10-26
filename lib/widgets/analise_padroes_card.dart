import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/analise_padroes.dart';
import '../theme/app_colors.dart';
import '../utils/formatadores.dart';

// RN19-RN21: mostra a análise de padrões mais recente do paciente.
class AnalisePadroesCard extends StatefulWidget {
  final String pacienteId;

  const AnalisePadroesCard({super.key, required this.pacienteId});

  @override
  State<AnalisePadroesCard> createState() => _AnalisePadroesCardState();
}

class _AnalisePadroesCardState extends State<AnalisePadroesCard> {
  late Stream<AnalisePadroes?> _stream = _criarStream();

  Stream<AnalisePadroes?> _criarStream() {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.pacienteId)
        .collection('insights')
        .doc('atual')
        .snapshots()
        .map((doc) => doc.exists ? AnalisePadroes.fromDoc(doc) : null);
  }

  @override
  void didUpdateWidget(covariant AnalisePadroesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pacienteId != widget.pacienteId) {
      _stream = _criarStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AnalisePadroes?>(
      stream: _stream,
      builder: (context, snapshot) {
        final analise = snapshot.data;
        if (analise == null) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.grafico, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      analise.geradaPorIa ? Icons.auto_awesome : Icons.insights,
                      color: AppColors.grafico,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        analise.geradaPorIa
                            ? 'Análise de padrões (IA)'
                            : 'Análise de padrões',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.grafico,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(analise.resumo, style: const TextStyle(fontSize: 15)),
                ...analise.pontos.map((ponto) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(ponto)),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
                // RN21: os insights não substituem orientação médica.
                Text(
                  'Baseado em ${analise.totalMedicoes} medições, atualizado em '
                  '${formatarDataHora(analise.geradaEm)}. Informação apenas de '
                  'apoio: não substitui a orientação do seu médico.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
