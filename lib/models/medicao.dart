import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusGlicemia { normal, acima, abaixo }

StatusGlicemia classificarGlicemia({
  required int valor,
  required int limiteMinimo,
  required int limiteMaximo,
}) {
  if (valor > limiteMaximo) {
    return StatusGlicemia.acima;
  }
  if (valor < limiteMinimo) {
    return StatusGlicemia.abaixo;
  }
  return StatusGlicemia.normal;
}

class Medicao {
  final String id;
  final String pacienteId;
  final int valorMgdl;
  final DateTime dataMedicao;
  final StatusGlicemia status;
  final String? observacao;
  final String registradoPor;

  const Medicao({
    required this.id,
    required this.pacienteId,
    required this.valorMgdl,
    required this.dataMedicao,
    required this.status,
    required this.registradoPor,
    this.observacao,
  });

  bool get foraDoLimite => status != StatusGlicemia.normal;

  factory Medicao.fromDoc(
    String pacienteId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Medicao(
      id: doc.id,
      pacienteId: pacienteId,
      valorMgdl: (data['valorMgdl'] as num?)?.toInt() ?? 0,
      dataMedicao:
          (data['dataMedicao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: StatusGlicemia.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => StatusGlicemia.normal,
      ),
      observacao: data['observacao'] as String?,
      registradoPor: data['registradoPor'] as String? ?? '',
    );
  }
}
