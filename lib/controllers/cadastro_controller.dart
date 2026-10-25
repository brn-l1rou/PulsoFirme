import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';

class CadastroController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> cadastrar({
    required String nome,
    required String dataNascimento,
    required String tipoUsuario,
    required String telefone,
    required String email,
    required String senha,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultadoAuth = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final uidUsuario = resultadoAuth.user!.uid;

      await _userService.saveUser(
        uid: uidUsuario,
        nome: nome,
        dataNascimento: dataNascimento,
        tipoUsuario: tipoUsuario,
        telefone: telefone,
        email: email,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseErrorToMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapFirebaseErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      default:
        return 'Erro ao cadastrar.';
    }
  }
}
