import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

// Foto de perfil de pacientes e cuidadores.
//
// A foto é reduzida para 256x256 e salva como JPEG em base64 em
// usuarios/{uid}/publico/foto (cerca de 20 KB). Ficar no Firestore, e não
// no Storage, evita configurar outro serviço, funciona offline e usa as
// mesmas regras de vínculo: só quem está vinculado vê a foto.
class FotoService {
  static const int tamanho = 256;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore
      .collection('usuarios')
      .doc(uid)
      .collection('publico')
      .doc('foto');

  Stream<Uint8List?> watchFoto(String uid) {
    return _doc(uid).snapshots().map((doc) {
      final base64 = doc.data()?['imagem'] as String?;
      return base64 == null ? null : base64Decode(base64);
    });
  }

  // Retorna false se o usuário cancelar a escolha.
  Future<bool> escolherESalvar(String uid, {required bool usarCamera}) async {
    final foto = await _picker.pickImage(
      source: usarCamera ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1024,
    );
    if (foto == null) {
      return false;
    }

    final jpeg = await compute(_prepararFoto, await File(foto.path).readAsBytes());
    await _doc(uid).set({
      'imagem': base64Encode(jpeg),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Future<void> remover(String uid) => _doc(uid).delete();

  // Roda em um isolate: corrige a rotação, recorta o centro em quadrado e
  // reduz a foto.
  static Uint8List _prepararFoto(Uint8List bytes) {
    final original = img.decodeImage(bytes);
    if (original == null) {
      throw const FormatException('Imagem inválida');
    }
    final imagem = img.bakeOrientation(original);
    final lado = imagem.width < imagem.height ? imagem.width : imagem.height;
    final quadrada = img.copyCrop(
      imagem,
      x: (imagem.width - lado) ~/ 2,
      y: (imagem.height - lado) ~/ 2,
      width: lado,
      height: lado,
    );
    return img.encodeJpg(
      img.copyResize(quadrada, width: tamanho, height: tamanho),
      quality: 80,
    );
  }
}
