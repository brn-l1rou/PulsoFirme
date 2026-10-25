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

  Future<List<Usuario>> getUsuarios(List<String> uids) async {
    final docs = await Future.wait(uids.map((uid) => _usuarios.doc(uid).get()));
    return docs.where((doc) => doc.exists).map(Usuario.fromDoc).toList();
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
