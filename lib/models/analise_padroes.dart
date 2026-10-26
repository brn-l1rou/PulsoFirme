import 'package:cloud_firestore/cloud_firestore.dart';

// RN19/RN20: análise do histórico gerada pela Cloud Function
// "analisarPadroes" a cada nova medição (usuarios/{id}/insights/atual).
class AnalisePadroes {
  final String resumo;
  final List<String> pontos;
  // "ia" (Gemini) ou "estatistica" (quando a IA não está disponível).
  final String origem;
  final DateTime geradaEm;
  final int totalMedicoes;

  const AnalisePadroes({
    required this.resumo,
    required this.pontos,
    required this.origem,
    required this.geradaEm,
    required this.totalMedicoes,
  });

  bool get geradaPorIa => origem == 'ia';

  factory AnalisePadroes.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AnalisePadroes(
      resumo: data['resumo'] as String? ?? '',
      pontos: List<String>.from(data['pontos'] as List? ?? []),
      origem: data['origem'] as String? ?? 'estatistica',
      geradaEm: (data['geradaEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalMedicoes: (data['totalMedicoes'] as num?)?.toInt() ?? 0,
    );
  }
}
