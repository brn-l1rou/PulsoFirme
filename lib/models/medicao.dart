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

// RF12: momento da medição em relação às refeições.
const Map<String, String> contextosMedicao = {
  'jejum': 'Jejum',
  'pre_prandial': 'Antes da refeição',
  'pos_prandial': 'Após a refeição',
  'antes_dormir': 'Antes de dormir',
};

// RF13: sintomas que podem ser marcados no momento da medição.
const List<String> sintomasDisponiveis = [
  'Tontura',
  'Suor frio',
  'Cansaço',
  'Tremores',
  'Fome excessiva',
  'Sede excessiva',
  'Visão turva',
  'Dor de cabeça',
  'Confusão',
  'Palpitação',
];

class Medicao {
  final String id;
  final String pacienteId;
  final int valorMgdl;
  final DateTime dataMedicao;
  final StatusGlicemia status;
  final String? observacao;
  final String registradoPor;
  final String? contexto;
  final List<String> sintomas;

  const Medicao({
    required this.id,
    required this.pacienteId,
    required this.valorMgdl,
    required this.dataMedicao,
    required this.status,
    required this.registradoPor,
    this.observacao,
    this.contexto,
    this.sintomas = const [],
  });

  bool get foraDoLimite => status != StatusGlicemia.normal;

  String? get contextoFormatado =>
      contexto == null ? null : contextosMedicao[contexto];

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
      contexto: data['contexto'] as String?,
      sintomas: List<String>.from(data['sintomas'] as List? ?? []),
    );
  }
}
