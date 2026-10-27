import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Preferências deste aparelho (não vão para o Firestore), já que o mesmo
// usuário pode querer fonte maior ou modo simplificado só em um celular.
class PreferenciasController extends ChangeNotifier {
  static final PreferenciasController instancia = PreferenciasController._();

  PreferenciasController._();

  // RNF05: tamanhos de fonte disponíveis, somados ao ajuste do sistema.
  static final Map<double, String> escalasFonte = {
    1.0: 'Normal',
    1.15: 'Grande',
    1.3: 'Muito grande',
  };

  static const String _chaveEscala = 'escalaFonte';
  static const String _chaveModoSimplificado = 'modoSimplificado';

  SharedPreferences? _prefs;
  double _escalaFonte = 1.0;
  bool _modoSimplificado = false;

  double get escalaFonte => _escalaFonte;

  // RNF04: tela única com o essencial para registrar a medição.
  bool get modoSimplificado => _modoSimplificado;

  Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _escalaFonte = prefs.getDouble(_chaveEscala) ?? 1.0;
      _modoSimplificado = prefs.getBool(_chaveModoSimplificado) ?? false;
    } catch (e) {
      debugPrint('Não foi possível carregar as preferências: $e');
    }
  }

  Future<void> definirEscalaFonte(double escala) async {
    _escalaFonte = escala;
    notifyListeners();
    await _prefs?.setDouble(_chaveEscala, escala);
  }

  Future<void> definirModoSimplificado(bool ativo) async {
    _modoSimplificado = ativo;
    notifyListeners();
    await _prefs?.setBool(_chaveModoSimplificado, ativo);
  }
}
