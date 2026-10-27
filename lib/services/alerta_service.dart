import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/alerta.dart';

class AlertaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _alertas(String pacienteId) {
    return _firestore
        .collection('usuarios')
        .doc(pacienteId)
        .collection('alertas');
  }

  Stream<List<Alerta>> watchAlertas(String pacienteId, {required DateTime desde}) {
    return _alertas(pacienteId)
        .where('criadoEm', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Alerta.fromDoc).toList());
  }

  // RF06: a Cloud Function "notificarSos" envia o push para os cuidadores
  // assim que este documento é criado.
  Future<void> enviarSos({
    required String pacienteId,
    Position? posicao,
  }) {
    return _alertas(pacienteId).add({
      'tipo': 'sos',
      'criadoPor': pacienteId,
      'criadoEm': FieldValue.serverTimestamp(),
      'latitude': posicao?.latitude,
      'longitude': posicao?.longitude,
    });
  }

  // Retorna null se o usuário negar a permissão ou o GPS estiver
  // desligado; o SOS é enviado mesmo sem localização.
  Future<Position?> obterLocalizacao() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      // Sem sinal de GPS a tempo: usa a última posição conhecida.
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }
}
