import 'package:cloud_firestore/cloud_firestore.dart';

// RF05: remédio do paciente com dosagem e horários diários. O lembrete
// de cada horário é enviado pela Cloud Function "verificarAgendamentos".
class Medicamento {
  final String id;
  final String pacienteId;
  final String nome;
  final String dosagem;
  final List<String> horarios;
  final bool ativo;

  const Medicamento({
    required this.id,
    required this.pacienteId,
    required this.nome,
    required this.dosagem,
    required this.horarios,
    this.ativo = true,
  });

  factory Medicamento.fromDoc(
    String pacienteId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Medicamento(
      id: doc.id,
      pacienteId: pacienteId,
      nome: data['nome'] as String? ?? '',
      dosagem: data['dosagem'] as String? ?? '',
      horarios: List<String>.from(data['horarios'] as List? ?? [])..sort(),
      ativo: data['ativo'] as bool? ?? true,
    );
  }
}

// RF08: confirmação de que uma dose foi tomada, com quem confirmou.
class TomadaMedicamento {
  final String medicamentoId;
  final String horario;
  final String nomeConfirmadoPor;
  final DateTime data;

  const TomadaMedicamento({
    required this.medicamentoId,
    required this.horario,
    required this.nomeConfirmadoPor,
    required this.data,
  });

  factory TomadaMedicamento.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TomadaMedicamento(
      medicamentoId: data['medicamentoId'] as String? ?? '',
      horario: data['horario'] as String? ?? '',
      nomeConfirmadoPor: data['nomeConfirmadoPor'] as String? ?? '',
      data: (data['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
