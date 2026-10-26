import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

// Mantém o usuário logado e o paciente que está sendo acompanhado.
// Para pacientes, o paciente selecionado é o próprio usuário; para
// cuidadores, é um dos pacientes vinculados.
class SessaoController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  StreamSubscription<Usuario?>? _usuarioSubscription;

  Usuario? _usuario;
  List<Usuario> _pacientes = [];
  String? _pacienteSelecionadoId;
  bool _isLoading = true;
  String? _errorMessage;
  bool _descartado = false;

  Usuario? get usuario => _usuario;
  List<Usuario> get pacientes => _pacientes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Usuario? get pacienteSelecionado {
    final usuario = _usuario;
    if (usuario == null) {
      return null;
    }
    if (usuario.isPaciente) {
      return usuario;
    }

    for (final paciente in _pacientes) {
      if (paciente.uid == _pacienteSelecionadoId) {
        return paciente;
      }
    }
    return null;
  }

  void iniciar(String uid) {
    _usuarioSubscription?.cancel();
    _usuarioSubscription = _userService.watchUsuario(uid).listen(
      _atualizarUsuario,
      onError: (Object erro) {
        _errorMessage = 'Erro ao carregar os dados do usuário.';
        _isLoading = false;
        _notificar();
      },
    );
  }

  Future<void> _atualizarUsuario(Usuario? usuario) async {
    _usuario = usuario;
    _errorMessage = usuario == null ? 'Usuário não encontrado.' : null;

    if (usuario != null && usuario.isCuidador) {
      await recarregarPacientes();
    }

    _isLoading = false;
    _notificar();
  }

  Future<void> recarregarPacientes() async {
    final usuario = _usuario;
    if (usuario == null || !usuario.isCuidador) {
      return;
    }

    try {
      _pacientes = await _userService.getUsuarios(usuario.pacientesVinculados);
    } catch (_) {
      _pacientes = [];
    }

    final aindaVinculado =
        _pacientes.any((paciente) => paciente.uid == _pacienteSelecionadoId);
    if (!aindaVinculado) {
      _pacienteSelecionadoId =
          _pacientes.isNotEmpty ? _pacientes.first.uid : null;
    }
    _notificar();
  }

  // As cargas são assíncronas e podem terminar depois que a tela foi
  // fechada (por exemplo, ao sair da conta).
  void _notificar() {
    if (!_descartado) {
      notifyListeners();
    }
  }

  void selecionarPaciente(String pacienteId) {
    _pacienteSelecionadoId = pacienteId;
    notifyListeners();
  }

  Future<void> sair() async {
    await _usuarioSubscription?.cancel();
    _usuarioSubscription = null;
    await _authService.signOut();
  }

  @override
  void dispose() {
    _descartado = true;
    _usuarioSubscription?.cancel();
    super.dispose();
  }
}
