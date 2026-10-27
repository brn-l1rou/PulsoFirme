import 'package:cloud_firestore/cloud_firestore.dart';

// RF14: medição recorrente. Os lembretes e o aviso de medição perdida
// (RF15) são enviados pela Cloud Function "verificarAgendamentos".
class Agendamento {
  static const List<String> frequencias = ['diaria', 'semanal', 'quinzenal'];
  static const List<String> nomesDias = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];

  final String id;
  final String pacienteId;
  final String hora;
  final String frequencia;
  // 1 = segunda ... 7 = domingo (mesmo padrão do DateTime.weekday).
  final int? diaSemana;
  final String dataInicio;
  final int toleranciaMinutos;
  final bool ativo;

  const Agendamento({
    required this.id,
    required this.pacienteId,
    required this.hora,
    required this.frequencia,
    required this.dataInicio,
    this.diaSemana,
    this.toleranciaMinutos = 30,
    this.ativo = true,
  });

  String get descricao {
    final dia = diaSemana == null ? '' : nomesDias[diaSemana! - 1];
    return switch (frequencia) {
      'semanal' => 'Toda $dia às $hora',
      'quinzenal' => 'A cada 15 dias, $dia às $hora',
      _ => 'Todos os dias às $hora',
    };
  }

  factory Agendamento.fromDoc(
    String pacienteId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Agendamento(
      id: doc.id,
      pacienteId: pacienteId,
      hora: data['hora'] as String? ?? '00:00',
      frequencia: data['frequencia'] as String? ?? 'diaria',
      diaSemana: (data['diaSemana'] as num?)?.toInt(),
      dataInicio: data['dataInicio'] as String? ?? '',
      toleranciaMinutos: (data['toleranciaMinutos'] as num?)?.toInt() ?? 30,
      ativo: data['ativo'] as bool? ?? true,
    );
  }
}
