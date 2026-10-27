import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medicamento.dart';
import '../models/usuario.dart';

class MedicamentoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _paciente(String pacienteId) =>
      _firestore.collection('usuarios').doc(pacienteId);

  static String dataDoDia(DateTime data) =>
      '${data.year}-${data.month.toString().padLeft(2, '0')}-'
      '${data.day.toString().padLeft(2, '0')}';

  Stream<List<Medicamento>> watchMedicamentos(String pacienteId) {
    return _paciente(pacienteId)
        .collection('medicamentos')
        .orderBy('nome')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medicamento.fromDoc(pacienteId, doc))
            .toList());
  }

  Stream<List<TomadaMedicamento>> watchTomadasDoDia(
    String pacienteId,
    DateTime dia,
  ) {
    return _paciente(pacienteId)
        .collection('tomadas')
        .where('dataDose', isEqualTo: dataDoDia(dia))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(TomadaMedicamento.fromDoc).toList());
  }

  Future<void> criar({
    required String pacienteId,
    required String nome,
    required String dosagem,
    required List<String> horarios,
    required String criadoPor,
  }) {
    return _paciente(pacienteId).collection('medicamentos').add({
      'nome': nome,
      'dosagem': dosagem,
      'horarios': horarios,
      'ativo': true,
      'criadoPor': criadoPor,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> alterarAtivo(Medicamento medicamento, bool ativo) {
    return _paciente(medicamento.pacienteId)
        .collection('medicamentos')
        .doc(medicamento.id)
        .update({'ativo': ativo});
  }

  Future<void> excluir(Medicamento medicamento) {
    return _paciente(medicamento.pacienteId)
        .collection('medicamentos')
        .doc(medicamento.id)
        .delete();
  }

  // O id da confirmação é fixo por remédio, dia e horário, então a mesma
  // dose não é confirmada duas vezes (as regras não deixam sobrescrever).
  Future<void> confirmarTomada({
    required Medicamento medicamento,
    required String horario,
    required Usuario autor,
  }) {
    final hoje = dataDoDia(DateTime.now());
    final id = '${medicamento.id}_${hoje}_${horario.replaceAll(':', '')}';

    return _paciente(medicamento.pacienteId).collection('tomadas').doc(id).set({
      'medicamentoId': medicamento.id,
      'nomeMedicamento': medicamento.nome,
      'dosagem': medicamento.dosagem,
      'horario': horario,
      'dataDose': hoje,
      'confirmadoPor': autor.uid,
      'nomeConfirmadoPor': autor.nome,
      'data': FieldValue.serverTimestamp(),
    });
  }
}
