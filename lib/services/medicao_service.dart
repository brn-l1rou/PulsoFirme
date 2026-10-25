import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medicao.dart';

class MedicaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _medicoes(String pacienteId) {
    return _firestore
        .collection('usuarios')
        .doc(pacienteId)
        .collection('medicoes');
  }

  Stream<List<Medicao>> watchMedicoes(String pacienteId, {DateTime? desde}) {
    Query<Map<String, dynamic>> query = _medicoes(pacienteId);
    if (desde != null) {
      query = query.where(
        'dataMedicao',
        isGreaterThanOrEqualTo: Timestamp.fromDate(desde),
      );
    }

    return query
        .orderBy('dataMedicao', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medicao.fromDoc(pacienteId, doc))
            .toList());
  }

  // A data é definida pelo próprio app no momento do registro (RN07),
  // o que também permite salvar offline e sincronizar depois (RN22).
  Future<void> adicionarMedicao({
    required String pacienteId,
    required int valorMgdl,
    required StatusGlicemia status,
    required String registradoPor,
    String? observacao,
  }) {
    return _medicoes(pacienteId).add({
      'valorMgdl': valorMgdl,
      'dataMedicao': Timestamp.now(),
      'status': status.name,
      'observacao': observacao,
      'registradoPor': registradoPor,
      'atualizadoPor': registradoPor,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizarMedicao({
    required String pacienteId,
    required String medicaoId,
    required int valorMgdl,
    required DateTime dataMedicao,
    required StatusGlicemia status,
    required String atualizadoPor,
  }) {
    return _medicoes(pacienteId).doc(medicaoId).update({
      'valorMgdl': valorMgdl,
      'dataMedicao': Timestamp.fromDate(dataMedicao),
      'status': status.name,
      'atualizadoPor': atualizadoPor,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluirMedicao({
    required String pacienteId,
    required String medicaoId,
  }) {
    return _medicoes(pacienteId).doc(medicaoId).delete();
  }
}
