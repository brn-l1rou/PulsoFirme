import 'package:cloud_firestore/cloud_firestore.dart';

class Convite {
  final String id;
  final String pacienteId;
  final String pacienteNome;
  final String emailCuidador;
  final String status;

  const Convite({
    required this.id,
    required this.pacienteId,
    required this.pacienteNome,
    required this.emailCuidador,
    required this.status,
  });

  factory Convite.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Convite(
      id: doc.id,
      pacienteId: data['pacienteId'] as String? ?? '',
      pacienteNome: data['pacienteNome'] as String? ?? '',
      emailCuidador: data['emailCuidador'] as String? ?? '',
      status: data['status'] as String? ?? 'pendente',
    );
  }
}
