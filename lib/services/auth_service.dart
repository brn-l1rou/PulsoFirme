import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // RF21: o Firebase exige um login recente para trocar e-mail ou senha,
  // por isso a senha atual é confirmada antes.
  Future<User> _reautenticar(String senhaAtual) async {
    final usuario = _firebaseAuth.currentUser;
    if (usuario == null || usuario.email == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await usuario.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: usuario.email!, password: senhaAtual),
    );
    return usuario;
  }

  Future<void> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final usuario = await _reautenticar(senhaAtual);
    await usuario.updatePassword(novaSenha);
  }

  // O e-mail só muda depois que o usuário clicar no link enviado para o
  // endereço novo; o Firestore é atualizado no próximo login.
  Future<void> alterarEmail({
    required String senhaAtual,
    required String novoEmail,
  }) async {
    final usuario = await _reautenticar(senhaAtual);
    await usuario.verifyBeforeUpdateEmail(novoEmail);
  }

  static String mensagemDeErro(FirebaseAuthException e) {
    return switch (e.code) {
      'wrong-password' || 'invalid-credential' => 'Senha atual incorreta.',
      'email-already-in-use' => 'Este e-mail já está em uso.',
      'invalid-email' => 'O formato do e-mail é inválido.',
      'weak-password' => 'A nova senha é muito fraca.',
      'too-many-requests' => 'Muitas tentativas. Aguarde alguns minutos.',
      'requires-recent-login' => 'Entre novamente na conta e tente outra vez.',
      _ => 'Não foi possível concluir a alteração.',
    };
  }
}
