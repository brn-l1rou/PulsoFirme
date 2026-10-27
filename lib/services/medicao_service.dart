import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/medicao.dart';
import '../models/registro_auditoria.dart';
import '../models/usuario.dart';

class MedicaoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _medicoes(String pacienteId) {
    return _firestore
        .collection('usuarios')
        .doc(pacienteId)
        .collection('medicoes');
  }

  CollectionReference<Map<String, dynamic>> _auditoria(String pacienteId) {
    return _firestore
        .collection('usuarios')
        .doc(pacienteId)
        .collection('auditoria');
  }

  // [ate] é exclusivo: para filtrar até um dia inteiro, passe o início
  // do dia seguinte.
  Stream<List<Medicao>> watchMedicoes(
    String pacienteId, {
    DateTime? desde,
    DateTime? ate,
  }) {
    Query<Map<String, dynamic>> query = _medicoes(pacienteId);
    if (desde != null) {
      query = query.where(
        'dataMedicao',
        isGreaterThanOrEqualTo: Timestamp.fromDate(desde),
      );
    }
    if (ate != null) {
      query = query.where('dataMedicao', isLessThan: Timestamp.fromDate(ate));
    }

    return query
        .orderBy('dataMedicao', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medicao.fromDoc(pacienteId, doc))
            .toList());
  }

  // Ordenado no app para não exigir índice composto no Firestore.
  Stream<List<RegistroAuditoria>> watchAuditoria(
    String pacienteId,
    String medicaoId,
  ) {
    return _auditoria(pacienteId)
        .where('medicaoId', isEqualTo: medicaoId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(RegistroAuditoria.fromDoc)
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data)));
  }

  // RF08: toda alteração em medições grava um registro de auditoria na
  // mesma operação (batch), então os dois são salvos juntos ou nenhum é.
  void _registrarAuditoria(
    WriteBatch batch, {
    required String pacienteId,
    required String medicaoId,
    required String acao,
    required Usuario responsavel,
    int? valorAnterior,
    int? valorNovo,
  }) {
    batch.set(_auditoria(pacienteId).doc(), {
      'medicaoId': medicaoId,
      'acao': acao,
      'uidResponsavel': responsavel.uid,
      'nomeResponsavel': responsavel.nome,
      'data': FieldValue.serverTimestamp(),
      'valorAnterior': valorAnterior,
      'valorNovo': valorNovo,
    });
  }

  // A data é definida pelo próprio app no momento do registro (RN07),
  // o que também permite salvar offline e sincronizar depois (RN22).
  Future<void> adicionarMedicao({
    required String pacienteId,
    required int valorMgdl,
    required StatusGlicemia status,
    required Usuario autor,
    String? observacao,
    String? contexto,
    List<String> sintomas = const [],
  }) {
    final batch = _firestore.batch();
    final medicao = _medicoes(pacienteId).doc();

    batch.set(medicao, {
      'valorMgdl': valorMgdl,
      'dataMedicao': Timestamp.now(),
      'status': status.name,
      'observacao': observacao,
      'contexto': contexto,
      'sintomas': sintomas,
      'registradoPor': autor.uid,
      'atualizadoPor': autor.uid,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    _registrarAuditoria(
      batch,
      pacienteId: pacienteId,
      medicaoId: medicao.id,
      acao: 'criacao',
      responsavel: autor,
      valorNovo: valorMgdl,
    );

    return batch.commit();
  }

  Future<void> atualizarMedicao({
    required Medicao medicao,
    required int valorMgdl,
    required DateTime dataMedicao,
    required StatusGlicemia status,
    required Usuario autor,
    String? contexto,
    List<String> sintomas = const [],
  }) {
    final batch = _firestore.batch();

    batch.update(_medicoes(medicao.pacienteId).doc(medicao.id), {
      'valorMgdl': valorMgdl,
      'dataMedicao': Timestamp.fromDate(dataMedicao),
      'status': status.name,
      'contexto': contexto,
      'sintomas': sintomas,
      'atualizadoPor': autor.uid,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    _registrarAuditoria(
      batch,
      pacienteId: medicao.pacienteId,
      medicaoId: medicao.id,
      acao: 'edicao',
      responsavel: autor,
      valorAnterior: medicao.valorMgdl,
      valorNovo: valorMgdl,
    );

    return batch.commit();
  }

  Future<void> excluirMedicao({
    required Medicao medicao,
    required Usuario autor,
  }) {
    final batch = _firestore.batch();

    batch.delete(_medicoes(medicao.pacienteId).doc(medicao.id));
    _registrarAuditoria(
      batch,
      pacienteId: medicao.pacienteId,
      medicaoId: medicao.id,
      acao: 'exclusao',
      responsavel: autor,
      valorAnterior: medicao.valorMgdl,
    );

    return batch.commit();
  }
}
