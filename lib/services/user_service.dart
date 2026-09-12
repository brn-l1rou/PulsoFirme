import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUser({
    required String uid,
    required String nome,
    required String dataNascimento,
    required String tipoUsuario,
    required String telefone,
    required String email,
  }) {
    return _firestore.collection('usuarios').doc(uid).set({
      'nome': nome,
      'dataNascimento': dataNascimento,
      'tipoUsuario': tipoUsuario,
      'telefone': telefone,
      'email': email,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _firestore.collection('usuarios').doc(uid).get();
  }
}
