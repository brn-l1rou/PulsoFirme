import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class LeituraImagem {
  final File imagem;

  // Valores encontrados, do mais provável para o menos provável.
  final List<int> candidatos;

  // O medidor mostrou "HI" (acima da faixa) ou "LO" (abaixo).
  final String? foraDaFaixaDoMedidor;

  const LeituraImagem({
    required this.imagem,
    this.candidatos = const [],
    this.foraDaFaixaDoMedidor,
  });

  int? get valor => candidatos.isEmpty ? null : candidatos.first;
}

// RF04: lê o valor exibido na tela de um medidor de glicemia.
//
// Visores de LCD (dígitos de 7 segmentos) costumam confundir o
// reconhecimento de texto. Por isso a foto é lida em várias versões
// (original, alto contraste, invertida e recorte do centro) e os números
// encontrados são somados em uma votação.
class OcrService {
  // Faixa de valores que um glicosímetro exibe (mg/dL).
  static const int _valorMinimo = 20;
  static const int _valorMaximo = 600;

  // Trocas comuns ao ler dígitos de LCD como letras.
  static const Map<String, String> _trocas = {
    'O': '0', 'o': '0', 'D': '0', 'Q': '0', 'U': '0',
    'I': '1', 'l': '1', 'i': '1', '|': '1', '!': '1', 'L': '1',
    'Z': '2', 'z': '2',
    'E': '3',
    'A': '4', 'h': '4',
    'S': '5', 's': '5',
    'G': '6', 'b': '6',
    'T': '7', 'J': '7',
    'B': '8',
    'g': '9', 'q': '9',
  };

  final ImagePicker _picker = ImagePicker();

  // Retorna null se o usuário cancelar a captura.
  Future<LeituraImagem?> lerMedidor({required bool usarCamera}) async {
    final foto = await _picker.pickImage(
      source: usarCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 95,
    );
    if (foto == null) {
      return null;
    }

    final pasta = await Directory.systemTemp.createTemp('ocr_');
    final caminhos = await compute(_gerarVariacoes, [foto.path, pasta.path]);

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final votos = <int, double>{};
    String? foraDaFaixa;
    try {
      for (final caminho in caminhos) {
        final texto = await recognizer.processImage(
          InputImage.fromFilePath(caminho),
        );
        foraDaFaixa ??= _detectarForaDaFaixa(texto);
        _contarVotos(texto, votos);
      }
    } finally {
      await recognizer.close();
      pasta.delete(recursive: true).ignore();
    }

    final candidatos = votos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return LeituraImagem(
      imagem: File(foto.path),
      candidatos: candidatos.take(3).map((e) => e.key).toList(),
      foraDaFaixaDoMedidor: candidatos.isEmpty ? foraDaFaixa : null,
    );
  }

  // Roda em um isolate para não travar a tela enquanto processa a foto.
  static Future<List<String>> _gerarVariacoes(List<String> argumentos) async {
    final original = argumentos[0];
    final pasta = argumentos[1];
    final caminhos = [original];

    final decodificada = img.decodeImage(await File(original).readAsBytes());
    if (decodificada == null) {
      return caminhos;
    }

    // Aplica a rotação da câmera (EXIF) antes de gerar as versões.
    final base = img.bakeOrientation(decodificada);

    Future<void> salvar(String nome, img.Image imagem) async {
      final caminho = '$pasta/$nome.jpg';
      await File(caminho).writeAsBytes(img.encodeJpg(imagem, quality: 95));
      caminhos.add(caminho);
    }

    final contraste = img.adjustColor(
      img.normalize(img.grayscale(img.Image.from(base)), min: 0, max: 255),
      contrast: 1.6,
    );
    await salvar('contraste', contraste);

    // Visores com fundo escuro e dígitos claros.
    await salvar('invertida', img.invert(img.Image.from(contraste)));

    // Normalmente o visor fica no centro da foto; o recorte ampliado
    // deixa os dígitos maiores e tira textos impressos do aparelho.
    final largura = (contraste.width * 0.6).round();
    final altura = (contraste.height * 0.6).round();
    final recorte = img.copyCrop(
      contraste,
      x: (contraste.width - largura) ~/ 2,
      y: (contraste.height - altura) ~/ 2,
      width: largura,
      height: altura,
    );
    await salvar(
      'centro',
      img.copyResize(recorte, width: (largura * 1.5).round()),
    );

    return caminhos;
  }

  String? _detectarForaDaFaixa(RecognizedText texto) {
    final tudo = texto.text.toUpperCase().replaceAll(RegExp(r'\s'), '');
    if (tudo.contains('HI')) {
      return 'HI';
    }
    if (tudo.contains('LO')) {
      return 'LO';
    }
    return null;
  }

  void _contarVotos(RecognizedText texto, Map<int, double> votos) {
    for (final bloco in texto.blocks) {
      final temUnidade =
          RegExp(r'mg|dl', caseSensitive: false).hasMatch(bloco.text);

      for (final linha in bloco.lines) {
        // Horários (12:30) e datas (25/10) não são a glicemia.
        if (RegExp(r'\d\s*[:/]\s*\d').hasMatch(linha.text)) {
          continue;
        }

        final altura = linha.boundingBox.height.toDouble();
        final peso = altura * (temUnidade ? 1.5 : 1);

        // Lê a linha inteira sem espaços, o que junta dígitos de LCD que
        // o reconhecimento separa ("1 2 0" -> 120).
        final semEspacos = _normalizar(linha.text.replaceAll(' ', ''));
        for (final numero in RegExp(r'\d+').allMatches(semEspacos)) {
          _votar(numero.group(0)!, peso, votos);
        }

        // Também considera cada palavra separadamente, com peso menor,
        // para quando a linha junta o valor com outros números.
        for (final elemento in linha.elements) {
          final normalizado = _normalizar(elemento.text);
          for (final numero in RegExp(r'\d+').allMatches(normalizado)) {
            _votar(
              numero.group(0)!,
              elemento.boundingBox.height * 0.8 * (temUnidade ? 1.5 : 1),
              votos,
            );
          }
        }
      }
    }
  }

  void _votar(String digitos, double peso, Map<int, double> votos) {
    if (digitos.length < 2 || digitos.length > 3) {
      return;
    }
    final valor = int.parse(digitos);
    if (valor < _valorMinimo || valor > _valorMaximo) {
      return;
    }
    votos[valor] = (votos[valor] ?? 0) + peso;
  }

  // Só troca letras por dígitos em textos que já são quase só números,
  // para não transformar palavras como "Glucose" em números.
  String _normalizar(String texto) {
    final caracteres = texto.split('');
    final digitos = caracteres.where((c) => RegExp(r'\d').hasMatch(c)).length;
    final trocaveis = caracteres.where(_trocas.containsKey).length;
    if (digitos == 0 || digitos + trocaveis < caracteres.length * 0.7) {
      return texto;
    }
    return caracteres.map((c) => _trocas[c] ?? c).join();
  }
}
