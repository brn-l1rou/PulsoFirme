import 'package:cloud_firestore/cloud_firestore.dart';

// Alertas gravados em usuarios/{pacienteId}/alertas:
// - "sos": criado pelo paciente no botão de emergência (RF06);
// - "agendada" e "perdida": criados pela Cloud Function (RF14/RF15);
// - "medicamento": lembrete de dose criado pela Cloud Function (RF05).
// Os alertas de glicemia fora do limite vêm das próprias medições.
class Alerta {
  final String id;
  final String tipo;
  final DateTime criadoEm;
  final String? hora;
  final String? descricao;
  final double? latitude;
  final double? longitude;

  const Alerta({
    required this.id,
    required this.tipo,
    required this.criadoEm,
    this.hora,
    this.descricao,
    this.latitude,
    this.longitude,
  });

  bool get temLocalizacao => latitude != null && longitude != null;

  Uri? get linkMapa => temLocalizacao
      ? Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
        )
      : null;

  factory Alerta.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Alerta(
      id: doc.id,
      tipo: data['tipo'] as String? ?? '',
      criadoEm: (data['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hora: data['hora'] as String?,
      descricao: data['descricao'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }
}
