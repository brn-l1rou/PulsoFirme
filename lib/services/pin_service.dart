import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// PIN de 4 dígitos para abrir o app sem digitar a senha (seção 2.1.4 do
// relatório). Só o hash do PIN é guardado, no armazenamento seguro do
// aparelho (Android Keystore), e não no Firestore: um PIN de 4 dígitos
// seria fácil de descobrir a partir do hash se outras pessoas o lessem.
class PinService {
  static const int maximoTentativas = 5;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _chavePin(String uid) => 'pin_$uid';
  String _chaveTentativas(String uid) => 'pin_tentativas_$uid';

  String _hash(String uid, String pin) =>
      sha256.convert(utf8.encode('pulso-firme:$uid:$pin')).toString();

  Future<bool> temPin(String uid) async {
    try {
      return await _storage.containsKey(key: _chavePin(uid));
    } catch (e) {
      debugPrint('Não foi possível ler o PIN: $e');
      return false;
    }
  }

  Future<void> definirPin(String uid, String pin) async {
    await _storage.write(key: _chavePin(uid), value: _hash(uid, pin));
    await _storage.delete(key: _chaveTentativas(uid));
  }

  Future<void> removerPin(String uid) async {
    await _storage.delete(key: _chavePin(uid));
    await _storage.delete(key: _chaveTentativas(uid));
  }

  // Retorna quantas tentativas ainda restam (0 = bloqueado) ou null se o
  // PIN estiver certo.
  Future<int?> verificar(String uid, String pin) async {
    final salvo = await _storage.read(key: _chavePin(uid));
    if (salvo != null && salvo == _hash(uid, pin)) {
      await _storage.delete(key: _chaveTentativas(uid));
      return null;
    }

    final erros =
        int.tryParse(await _storage.read(key: _chaveTentativas(uid)) ?? '') ?? 0;
    final novosErros = erros + 1;
    await _storage.write(key: _chaveTentativas(uid), value: '$novosErros');
    return (maximoTentativas - novosErros).clamp(0, maximoTentativas);
  }
}
