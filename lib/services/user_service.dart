import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _firestore.collection('usuarios');

  Future<void> saveUser({
    required String uid,
    required String nome,
    required String dataNascimento,
    required String tipoUsuario,
    required String telefone,
    required String email,
  }) {
    return _usuarios.doc(uid).set({
      'nome': nome,
      'dataNascimento': dataNascimento,
      'tipoUsuario': tipoUsuario,
      'telefone': telefone,
      'email': email.toLowerCase(),
      'cuidadoresAutorizados': <String>[],
      'pacientesVinculados': <String>[],
      if (tipoUsuario == 'paciente') ...{
        'limiteMinimo': Usuario.limiteMinimoPadrao,
        'limiteMaximo': Usuario.limiteMaximoPadrao,
      },
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _usuarios.doc(uid).get();
  }

  Stream<Usuario?> watchUsuario(String uid) {
    return _usuarios.doc(uid).snapshots().map(
          (doc) => doc.exists ? Usuario.fromDoc(doc) : null,
        );
  }

  // Ignora os usuários que não podem mais ser lidos (por exemplo, um
  // paciente que desfez o vínculo), em vez de falhar a lista inteira.
  Future<List<Usuario>> getUsuarios(List<String> uids) async {
    final usuarios = await Future.wait(uids.map((uid) async {
      try {
        final doc = await _usuarios.doc(uid).get();
        return doc.exists ? Usuario.fromDoc(doc) : null;
      } on FirebaseException {
        return null;
      }
    }));
    return usuarios.whereType<Usuario>().toList();
  }

  Future<void> atualizarDados(
    String uid, {
    String? nome,
    String? telefone,
  }) {
    return _usuarios.doc(uid).update({
      'nome': ?nome,
      'telefone': ?telefone,
    });
  }

  Future<void> atualizarLimites(
    String uid, {
    required int limiteMinimo,
    required int limiteMaximo,
  }) {
    return _usuarios.doc(uid).update({
      'limiteMinimo': limiteMinimo,
      'limiteMaximo': limiteMaximo,
    });
  }
}
