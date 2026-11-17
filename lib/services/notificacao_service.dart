import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// RF10: pede permissão de notificação e registra o token FCM do aparelho
// em usuarios/{uid}/tokens/{token}, de onde as Cloud Functions leem para
// enviar os alertas.
class NotificacaoService {
  // Canal de alta prioridade (banner e som). O mesmo id é o canal padrão do
  // FCM no AndroidManifest e o usado pelas Cloud Functions.
  static const AndroidNotificationChannel canal = AndroidNotificationChannel(
    'alertas_pulso_firme',
    'Alertas de glicemia',
    description: 'Valores fora da faixa, SOS, lembretes e medições perdidas.',
    importance: Importance.high,
  );

  static final FlutterLocalNotificationsPlugin _locais =
      FlutterLocalNotificationsPlugin();
  static bool _locaisIniciadas = false;

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

  AndroidFlutterLocalNotificationsPlugin? get _android => _locais
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> _iniciarLocais() async {
    if (_locaisIniciadas) {
      return;
    }
    await _locais.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notificacao'),
      ),
    );
    await _android?.createNotificationChannel(canal);
    _locaisIniciadas = true;
  }

  Future<void> registrar(String uid) async {
    try {
      await _iniciarLocais();

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

      // Com o app aberto, o Android não exibe a notificação recebida; ela é
      // mostrada aqui, no mesmo canal, para aparecer igual na barra de status.
      _mensagemSubscription?.cancel();
      _mensagemSubscription = FirebaseMessaging.onMessage.listen(_exibir);
    } catch (e) {
      // Ex.: emulador sem Google Play Services. O app segue funcionando,
      // só não recebe push.
      debugPrint('Não foi possível registrar as notificações: $e');
    }
  }

  Future<void> _exibir(RemoteMessage mensagem) async {
    final notificacao = mensagem.notification;
    if (notificacao == null) {
      return;
    }
    await _locais.show(
      id: mensagem.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: notificacao.title,
      body: notificacao.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          canal.id,
          canal.name,
          channelDescription: canal.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notificacao',
          color: const Color(0xFFCC2B25),
          styleInformation: BigTextStyleInformation(notificacao.body ?? ''),
        ),
      ),
    );
  }

  // Usado nas configurações para mostrar se as notificações estão ativas.
  Future<bool> notificacoesAtivas() async {
    try {
      await _iniciarLocais();
      return await _android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  // Pede a permissão de novo (Android 13+). Se o usuário já recusou de vez,
  // o Android não mostra o pedido e é preciso ativar nas configurações.
  Future<bool> pedirPermissao() async {
    await _iniciarLocais();
    return await _android?.requestNotificationsPermission() ?? false;
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
