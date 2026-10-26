import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// RF10: pede permissão de notificação e registra o token FCM do aparelho
// em usuarios/{uid}/tokens/{token}, de onde as Cloud Functions leem para
// enviar os alertas.
class NotificacaoService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _mensagemSubscription;

  DocumentReference<Map<String, dynamic>> _tokenDoc(String uid, String token) {
    return _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('tokens')
        .doc(token);
  }

  Future<void> registrar(
    String uid, {
    required void Function(RemoteMessage mensagem) onMensagem,
  }) async {
    try {
      final permissao = await _messaging.requestPermission();
      if (permissao.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await _messaging.getToken();
      if (token != null) {
        await _salvarToken(uid, token);
      }

      _tokenSubscription?.cancel();
      _tokenSubscription =
          _messaging.onTokenRefresh.listen((novo) => _salvarToken(uid, novo));

      // Com o app aberto, o Android não mostra a notificação sozinho.
      _mensagemSubscription?.cancel();
      _mensagemSubscription = FirebaseMessaging.onMessage.listen(onMensagem);
    } catch (e) {
      // Ex.: emulador sem Google Play Services. O app segue funcionando,
      // só não recebe push.
      debugPrint('Não foi possível registrar as notificações: $e');
    }
  }

  Future<void> _salvarToken(String uid, String token) {
    return _tokenDoc(uid, token).set({
      'plataforma': defaultTargetPlatform.name,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  // Chamado ao sair da conta, para o aparelho não receber mais os alertas
  // deste usuário.
  Future<void> remover(String uid) async {
    await _tokenSubscription?.cancel();
    await _mensagemSubscription?.cancel();
    _tokenSubscription = null;
    _mensagemSubscription = null;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _tokenDoc(uid, token).delete();
      }
    } catch (e) {
      debugPrint('Não foi possível remover o token: $e');
    }
  }
}
