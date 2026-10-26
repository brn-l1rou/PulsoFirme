import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/convite.dart';
import '../models/usuario.dart';

// O vínculo paciente/cuidador parte sempre de um convite criado pelo
// paciente (RN05). O id do convite é "pacienteId_emailCuidador", o que
// permite às regras do Firestore validar o aceite sem consultas extras.
class ConviteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _convites =>
      _firestore.collection('convites');

  Future<void> convidarCuidador({
    required Usuario paciente,
    required String emailCuidador,
  }) {
    final email = emailCuidador.trim().toLowerCase();
    return _convites.doc('${paciente.uid}_$email').set({
      'pacienteId': paciente.uid,
      'pacienteNome': paciente.nome,
      'emailCuidador': email,
      'status': 'pendente',
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Convite>> watchConvitesPendentes(String emailCuidador) {
    return _convites
        .where('emailCuidador', isEqualTo: emailCuidador.toLowerCase())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(Convite.fromDoc)
            .where((convite) => convite.status == 'pendente')
            .toList());
  }

  Future<void> aceitarConvite({
    required Convite convite,
    required String cuidadorUid,
  }) {
    final batch = _firestore.batch();
    final usuarios = _firestore.collection('usuarios');

    batch.update(usuarios.doc(convite.pacienteId), {
      'cuidadoresAutorizados': FieldValue.arrayUnion([cuidadorUid]),
    });
    batch.update(usuarios.doc(cuidadorUid), {
      'pacientesVinculados': FieldValue.arrayUnion([convite.pacienteId]),
    });
    batch.update(_convites.doc(convite.id), {
      'status': 'aceito',
      'respondidoEm': FieldValue.serverTimestamp(),
    });

    return batch.commit();
  }

  // Desfaz o vínculo dos dois lados. Pode ser feito pelo paciente ou pelo
  // cuidador; as regras permitem que cada um tire o próprio uid da lista
  // do outro.
  Future<void> desvincular({
    required String pacienteId,
    required String cuidadorId,
  }) {
    final batch = _firestore.batch();
    final usuarios = _firestore.collection('usuarios');

    batch.update(usuarios.doc(pacienteId), {
      'cuidadoresAutorizados': FieldValue.arrayRemove([cuidadorId]),
    });
    batch.update(usuarios.doc(cuidadorId), {
      'pacientesVinculados': FieldValue.arrayRemove([pacienteId]),
    });

    return batch.commit();
  }

  Future<void> recusarConvite(Convite convite) {
    return _convites.doc(convite.id).update({
      'status': 'recusado',
      'respondidoEm': FieldValue.serverTimestamp(),
    });
  }
}
