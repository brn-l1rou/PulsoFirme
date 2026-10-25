import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/sessao_controller.dart';
import '../models/convite.dart';
import '../models/usuario.dart';
import '../services/convite_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cabecalho_curvo.dart';
import '../widgets/campos.dart';

class PerfilScreen extends StatefulWidget {
  final SessaoController sessao;
  final VoidCallback onSair;

  const PerfilScreen({super.key, required this.sessao, required this.onSair});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final UserService _userService = UserService();
  final ConviteService _conviteService = ConviteService();

  bool _vinculosAbertos = false;
  String? _chaveCuidadores;
  Future<List<Usuario>>? _cuidadores;
  Stream<List<Convite>>? _convites;

  Usuario get _usuario => widget.sessao.usuario!;

  Future<List<Usuario>> _vinculados() {
    if (_usuario.isCuidador) {
      return Future.value(widget.sessao.pacientes);
    }

    final chave = _usuario.cuidadoresAutorizados.join(',');
    if (_cuidadores == null || _chaveCuidadores != chave) {
      _chaveCuidadores = chave;
      _cuidadores = _userService.getUsuarios(_usuario.cuidadoresAutorizados);
    }
    return _cuidadores!;
  }

  Stream<List<Convite>> _convitesPendentes() {
    // As regras do Firestore comparam com o e-mail do token de login.
    final email = FirebaseAuth.instance.currentUser?.email ?? _usuario.email;
    return _convites ??= _conviteService.watchConvitesPendentes(email);
  }

  Future<String?> _pedirTexto({
    required String titulo,
    required String valorInicial,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final controller = TextEditingController(text: valorInicial);
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: teclado,
            autofocus: true,
            validator: validator,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    try {
      await acao();
      if (mounted) {
        mostrarMensagem(context, sucesso);
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagem(context, 'Não foi possível concluir a ação.', erro: true);
      }
    }
  }

  Future<void> _editarTelefone() async {
    final telefone = await _pedirTexto(
      titulo: 'Telefone',
      valorInicial: _usuario.telefone,
      teclado: TextInputType.phone,
      validator: (value) {
        final digitos = (value ?? '').replaceAll(RegExp(r'\D'), '');
        return digitos.length < 10 ? 'Telefone inválido.' : null;
      },
    );
    if (telefone == null) {
      return;
    }
    await _executar(
      () => _userService.atualizarDados(_usuario.uid, telefone: telefone),
      'Telefone atualizado!',
    );
  }

  Future<void> _editarNome() async {
    final nome = await _pedirTexto(
      titulo: 'Nome completo',
      valorInicial: _usuario.nome,
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Informe seu nome.' : null,
    );
    if (nome == null) {
      return;
    }
    await _executar(
      () => _userService.atualizarDados(_usuario.uid, nome: nome),
      'Nome atualizado!',
    );
  }

  // RN15: limites mínimo e máximo configuráveis por paciente.
  Future<void> _editarLimites() async {
    final minimoController =
        TextEditingController(text: _usuario.limiteMinimo.toString());
    final maximoController =
        TextEditingController(text: _usuario.limiteMaximo.toString());
    final formKey = GlobalKey<FormState>();

    String? validarLimite(String? value) {
      final numero = int.tryParse(value ?? '');
      if (numero == null || numero <= 0 || numero > 600) {
        return 'Valor inválido.';
      }
      return null;
    }

    final salvar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limites de glicemia (mg/dL)'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: minimoController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Mínimo'),
                validator: validarLimite,
              ),
              TextFormField(
                controller: maximoController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Máximo'),
                validator: (value) {
                  final erro = validarLimite(value);
                  if (erro != null) {
                    return erro;
                  }
                  final minimo = int.tryParse(minimoController.text) ?? 0;
                  return int.parse(value!) <= minimo
                      ? 'O máximo deve ser maior que o mínimo.'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    final minimo = int.tryParse(minimoController.text);
    final maximo = int.tryParse(maximoController.text);
    minimoController.dispose();
    maximoController.dispose();
    if (salvar != true || minimo == null || maximo == null) {
      return;
    }

    await _executar(
      () => _userService.atualizarLimites(
        _usuario.uid,
        limiteMinimo: minimo,
        limiteMaximo: maximo,
      ),
      'Limites atualizados!',
    );
  }

  // RF07: o paciente convida o cuidador pelo e-mail de cadastro dele.
  Future<void> _convidarCuidador() async {
    final email = await _pedirTexto(
      titulo: 'E-mail do cuidador',
      valorInicial: '',
      teclado: TextInputType.emailAddress,
      validator: (value) {
        final texto = (value ?? '').trim().toLowerCase();
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
          return 'E-mail inválido.';
        }
        if (texto == _usuario.email.toLowerCase()) {
          return 'Informe o e-mail de outra pessoa.';
        }
        return null;
      },
    );
    if (email == null) {
      return;
    }
    await _executar(
      () => _conviteService.convidarCuidador(
        paciente: _usuario,
        emailCuidador: email,
      ),
      'Convite enviado! O cuidador verá o convite no perfil dele.',
    );
  }

  Future<void> _responderConvite(Convite convite, {required bool aceitar}) {
    if (!aceitar) {
      return _executar(
        () => _conviteService.recusarConvite(convite),
        'Convite recusado.',
      );
    }

    return _executar(() async {
      await _conviteService.aceitarConvite(
        convite: convite,
        cuidadorUid: _usuario.uid,
      );
      await widget.sessao.recarregarPacientes();
    }, 'Agora você acompanha ${convite.pacienteNome}!');
  }

  Future<void> _confirmarSaida() async {
    final sair = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (sair == true) {
      widget.onSair();
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _usuario;
    final idade = usuario.idade;

    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          CabecalhoCurvo(
            alturaTopo: 160,
            topo: const AvatarUsuario(tamanho: 130),
            acaoDireita: IconButton(
              tooltip: 'Sair',
              onPressed: _confirmarSaida,
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
            titulo: Column(
              children: [
                GestureDetector(
                  onTap: _editarNome,
                  child: TituloCabecalho(usuario.nome),
                ),
                Text(usuario.tipoFormatado, style: const TextStyle(fontSize: 16)),
                if (idade != null)
                  Text('$idade anos', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoLinha(rotulo: 'E-mail', valor: usuario.email),
          _InfoLinha(
            rotulo: 'Telefone',
            valor: usuario.telefone,
            onEditar: _editarTelefone,
          ),
          if (usuario.isPaciente)
            _InfoLinha(
              rotulo: 'Limites de glicemia',
              valor: '${usuario.limiteMinimo} a ${usuario.limiteMaximo} mg/dL',
              onEditar: _editarLimites,
            ),
          const SizedBox(height: 20),
          _botaoVinculos(),
          if (_vinculosAbertos) _listaVinculos(),
          const SizedBox(height: 12),
          if (usuario.isPaciente)
            Center(
              child: TextButton.icon(
                onPressed: _convidarCuidador,
                icon: const Icon(Icons.person_add_alt, color: AppColors.primaria),
                label: const Text(
                  'Convidar cuidador',
                  style: TextStyle(
                    color: AppColors.primaria,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            _convitesRecebidos(),
        ],
      ),
    );
  }

  Widget _botaoVinculos() {
    final rotulo = _usuario.isPaciente ? 'Cuidadores' : 'Pacientes';
    return Center(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(240, 48),
          side: const BorderSide(color: AppColors.primaria, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => setState(() => _vinculosAbertos = !_vinculosAbertos),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rotulo,
              style: const TextStyle(
                color: AppColors.primaria,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              _vinculosAbertos ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: AppColors.primaria,
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaVinculos() {
    return FutureBuilder<List<Usuario>>(
      future: _vinculados(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaria),
            ),
          );
        }

        final vinculados = snapshot.data ?? [];
        if (vinculados.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhum vínculo ainda.', textAlign: TextAlign.center),
          );
        }

        return Column(
          children: vinculados
              .map((v) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 50),
                    leading: const Icon(Icons.person, color: AppColors.primaria),
                    title: Text(v.nome),
                    subtitle: Text(v.telefone),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _convitesRecebidos() {
    return StreamBuilder<List<Convite>>(
      stream: _convitesPendentes(),
      builder: (context, snapshot) {
        final convites = snapshot.data ?? [];
        if (convites.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RotuloCampo('Convites recebidos', tamanho: 16),
              ...convites.map((convite) => Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${convite.pacienteNome} convidou você para '
                            'acompanhar as medições.',
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    _responderConvite(convite, aceitar: false),
                                child: const Text('Recusar'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaria,
                                ),
                                onPressed: () =>
                                    _responderConvite(convite, aceitar: true),
                                child: const Text(
                                  'Aceitar',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final String rotulo;
  final String valor;
  final VoidCallback? onEditar;

  const _InfoLinha({required this.rotulo, required this.valor, this.onEditar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 8, 30, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: const TextStyle(
              color: AppColors.primaria,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Flexible(
                child: Text(valor, style: const TextStyle(fontSize: 20)),
              ),
              if (onEditar != null)
                IconButton(
                  tooltip: 'Editar $rotulo',
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
