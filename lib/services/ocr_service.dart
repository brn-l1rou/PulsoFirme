import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class LeituraImagem {
  final File imagem;
  final int? valor;

  const LeituraImagem({required this.imagem, this.valor});
}

// RF04: lê o valor exibido na tela de um medidor de glicemia.
class OcrService {
  // Faixa de valores que um glicosímetro costuma exibir (mg/dL).
  static const int _valorMinimo = 20;
  static const int _valorMaximo = 600;

  final ImagePicker _picker = ImagePicker();

  // Retorna null se o usuário cancelar a captura.
  Future<LeituraImagem?> lerMedidor({required bool usarCamera}) async {
    final foto = await _picker.pickImage(
      source: usarCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (foto == null) {
      return null;
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final texto = await recognizer.processImage(
        InputImage.fromFilePath(foto.path),
      );
      return LeituraImagem(
        imagem: File(foto.path),
        valor: _escolherValor(texto),
      );
    } finally {
      await recognizer.close();
    }
  }

  // No visor do medidor, a glicemia é o número com os maiores dígitos;
  // data, hora e unidade aparecem em fonte menor.
  int? _escolherValor(RecognizedText texto) {
    int? melhorValor;
    double melhorAltura = 0;

    for (final bloco in texto.blocks) {
      for (final linha in bloco.lines) {
        for (final elemento in linha.elements) {
          final digitos = elemento.text.replaceAll(RegExp(r'[^0-9]'), '');
          if (digitos.isEmpty || digitos.length > 3) {
            continue;
          }
          // Evita confundir horários (12:30) e datas (25/10) com a glicemia.
          if (RegExp(r'[:/]').hasMatch(elemento.text)) {
            continue;
          }

          final valor = int.parse(digitos);
          if (valor < _valorMinimo || valor > _valorMaximo) {
            continue;
          }

          final altura = elemento.boundingBox.height;
          if (altura > melhorAltura) {
            melhorAltura = altura;
            melhorValor = valor;
          }
        }
      }
    }

    return melhorValor;
  }
}
