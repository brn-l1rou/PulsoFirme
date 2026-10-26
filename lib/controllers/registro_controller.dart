import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/medicao.dart';
import '../models/usuario.dart';
import '../services/medicao_service.dart';

class RegistroController extends ChangeNotifier {
  static const int valorMaximoAceito = 1000;

  final MedicaoService _medicaoService = MedicaoService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // RN06: o valor da glicemia deve ser numérico, positivo e válido.
  static String? validarGlicemia(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o valor da glicemia.';
    }

    final valor = int.tryParse(value.trim());
    if (valor == null) {
      return 'Informe apenas números.';
    }
    if (valor <= 0 || valor > valorMaximoAceito) {
      return 'Valor de glicemia inválido.';
    }

    return null;
  }

  // Retorna o status da medição salva, ou null em caso de erro.
  Future<StatusGlicemia?> registrar({
    required Usuario paciente,
    required Usuario autor,
    required int valorMgdl,
    String? observacao,
  }) {
    final status = classificarGlicemia(
      valor: valorMgdl,
      limiteMinimo: paciente.limiteMinimo,
      limiteMaximo: paciente.limiteMaximo,
    );

    return _executar(() async {
      await _aguardarEscrita(_medicaoService.adicionarMedicao(
        pacienteId: paciente.uid,
        valorMgdl: valorMgdl,
        status: status,
        autor: autor,
        observacao: (observacao == null || observacao.trim().isEmpty)
            ? null
            : observacao.trim(),
      ));
      return status;
    });
  }

  Future<StatusGlicemia?> atualizar({
    required Usuario paciente,
    required Medicao medicao,
    required Usuario autor,
    required int valorMgdl,
    required DateTime dataMedicao,
  }) {
    final status = classificarGlicemia(
      valor: valorMgdl,
      limiteMinimo: paciente.limiteMinimo,
      limiteMaximo: paciente.limiteMaximo,
    );

    return _executar(() async {
      await _aguardarEscrita(_medicaoService.atualizarMedicao(
        medicao: medicao,
        valorMgdl: valorMgdl,
        dataMedicao: dataMedicao,
        status: status,
        autor: autor,
      ));
      return status;
    });
  }

  Future<bool> excluir(Medicao medicao, {required Usuario autor}) async {
    final resultado = await _executar(() async {
      await _aguardarEscrita(_medicaoService.excluirMedicao(
        medicao: medicao,
        autor: autor,
      ));
      return true;
    });
    return resultado ?? false;
  }

  // RN13: o paciente só exclui se não tiver cuidadores; cuidadores
  // vinculados sempre podem excluir.
  static bool podeExcluir({required Usuario usuario, required Usuario paciente}) {
    if (usuario.isCuidador) {
      return paciente.cuidadoresAutorizados.contains(usuario.uid);
    }
    return usuario.uid == paciente.uid &&
        paciente.cuidadoresAutorizados.isEmpty;
  }

  // Sem conexão, a escrita só é confirmada quando a internet voltar.
  // O Firestore já guarda a alteração localmente e sincroniza depois
  // (RN22), então não deixamos a tela travada esperando o servidor.
  Future<void> _aguardarEscrita(Future<void> escrita) async {
    try {
      await escrita.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // Escrita pendente: será enviada quando a conexão voltar.
    }
  }

  Future<T?> _executar<T>(Future<T> Function() acao) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await acao();
    } on FirebaseException catch (e) {
      _errorMessage = e.code == 'permission-denied'
          ? 'Você não tem permissão para esta ação.'
          : 'Erro ao salvar o registro.';
      return null;
    } catch (_) {
      _errorMessage = 'Erro inesperado ao salvar o registro.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
