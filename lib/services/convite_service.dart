import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:share_plus/share_plus.dart';

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

  // RF07 (link/código): o paciente gera um código de 6 caracteres válido
  // por 7 dias e envia por WhatsApp, e-mail ou outro app.
  static const String _alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const Duration validadeCodigo = Duration(days: 7);

  Future<String> gerarCodigo(Usuario paciente) async {
    final aleatorio = Random.secure();
    for (var tentativa = 0; tentativa < 3; tentativa++) {
      final codigo = List.generate(
        6,
        (_) => _alfabeto[aleatorio.nextInt(_alfabeto.length)],
      ).join();
      try {
        // As regras só permitem criar, então um código repetido falha e
        // outro é sorteado.
        await _firestore.collection('convitesCodigo').doc(codigo).set({
          'pacienteId': paciente.uid,
          'pacienteNome': paciente.nome,
          'criadoEm': FieldValue.serverTimestamp(),
          'expiraEm': Timestamp.fromDate(DateTime.now().add(validadeCodigo)),
          'usado': false,
        });
        return codigo;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') {
          rethrow;
        }
      }
    }
    throw StateError('Não foi possível gerar um código.');
  }

  Future<void> compartilharConvite({
    required Usuario paciente,
    String? codigo,
  }) {
    final instrucoes = codigo == null
        ? 'Entre no app Pulso Firme com este e-mail e aceite o convite na aba Perfil.'
        : 'No app Pulso Firme, abra a aba Perfil, toque em "Tenho um código '
            'de convite" e digite: $codigo (válido por 7 dias).';
    return SharePlus.instance.share(
      ShareParams(
        subject: 'Convite para acompanhar ${paciente.nome} no Pulso Firme',
        text: 'Olá! ${paciente.nome} convidou você para acompanhar as medições '
            'de glicemia no Pulso Firme.\n\n$instrucoes',
      ),
    );
  }

  // A validação e o vínculo são feitos pela Cloud Function, porque o
  // cuidador não tem permissão para ler o convite antes de aceitar.
  Future<String> aceitarCodigo(String codigo) async {
    final resultado = await FirebaseFunctions.instance
        .httpsCallable('aceitarConvitePorCodigo')
        .call<Map<String, dynamic>>({'codigo': codigo.trim().toUpperCase()});
    return resultado.data['pacienteNome'] as String? ?? 'o paciente';
  }

  Future<void> recusarConvite(Convite convite) {
    return _convites.doc(convite.id).update({
      'status': 'recusado',
      'respondidoEm': FieldValue.serverTimestamp(),
    });
  }
}
