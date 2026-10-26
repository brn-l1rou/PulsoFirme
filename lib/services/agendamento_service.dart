import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agendamento.dart';

class AgendamentoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _agendamentos(String pacienteId) {
    return _firestore
        .collection('usuarios')
        .doc(pacienteId)
        .collection('agendamentos');
  }

  Stream<List<Agendamento>> watchAgendamentos(String pacienteId) {
    return _agendamentos(pacienteId).orderBy('hora').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Agendamento.fromDoc(pacienteId, doc))
              .toList(),
        );
  }

  Future<void> criar({
    required String pacienteId,
    required String hora,
    required String frequencia,
    required int? diaSemana,
    required int toleranciaMinutos,
    required String criadoPor,
  }) {
    final hoje = DateTime.now();
    final dataInicio = '${hoje.year}-'
        '${hoje.month.toString().padLeft(2, '0')}-'
        '${hoje.day.toString().padLeft(2, '0')}';

    return _agendamentos(pacienteId).add({
      'hora': hora,
      'frequencia': frequencia,
      'diaSemana': frequencia == 'diaria' ? null : diaSemana,
      'dataInicio': dataInicio,
      'toleranciaMinutos': toleranciaMinutos,
      'ativo': true,
      'criadoPor': criadoPor,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> alterarAtivo(Agendamento agendamento, bool ativo) {
    return _agendamentos(agendamento.pacienteId)
        .doc(agendamento.id)
        .update({'ativo': ativo});
  }

  Future<void> excluir(Agendamento agendamento) {
    return _agendamentos(agendamento.pacienteId).doc(agendamento.id).delete();
  }
}
