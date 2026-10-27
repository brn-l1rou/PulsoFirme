import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/sessao_controller.dart';
import '../models/convite.dart';
import '../models/usuario.dart';
import '../services/convite_service.dart';
import '../services/foto_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cabecalho_curvo.dart';
import '../widgets/campos.dart';
import '../widgets/dialogos.dart';
import 'agendamentos_screen.dart';
import 'configuracoes_screen.dart';
import 'medicamentos_screen.dart';

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
  final FotoService _fotoService = FotoService();
  bool _salvandoFoto = false;

  bool _vinculosAbertos = false;
  String? _chaveCuidadores;
  Future<List<Usuario>>? _cuidadores;
  Stream<List<Convite>>? _convites;

  Usuario get _usuario => widget.sessao.usuario!;

  // O Future fica em cache para o FutureBuilder não recarregar a lista a
  // cada rebuild; só muda quando os vínculos mudam.
  Future<List<Usuario>> _vinculados() {
    final ids = _usuario.isCuidador
        ? widget.sessao.pacientes.map((p) => p.uid).toList()
        : _usuario.cuidadoresAutorizados;
    final chave = ids.join(',');
    if (_cuidadores == null || _chaveCuidadores != chave) {
      _chaveCuidadores = chave;
      _cuidadores = _usuario.isCuidador
          ? Future.value(widget.sessao.pacientes)
          : _userService.getUsuarios(ids);
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
    return showDialog<String>(
      context: context,
      builder: (context) => DialogoTexto(
        titulo: titulo,
        valorInicial: valorInicial,
        teclado: teclado,
        validator: validator,
      ),
    );
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
    final limites = await showDialog<LimitesGlicemia>(
      context: context,
      builder: (context) => DialogoLimites(
        minimoInicial: _usuario.limiteMinimo,
        maximoInicial: _usuario.limiteMaximo,
      ),
    );
    if (limites == null) {
      return;
    }

    await _executar(
      () => _userService.atualizarLimites(
        _usuario.uid,
        limiteMinimo: limites.minimo,
        limiteMaximo: limites.maximo,
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
    try {
      await _conviteService.convidarCuidador(
        paciente: _usuario,
        emailCuidador: email,
      );
    } catch (_) {
      if (mounted) {
        mostrarMensagem(context, 'Não foi possível criar o convite.', erro: true);
      }
      return;
    }
    if (!mounted) {
      return;
    }

    // RF07: além de aparecer no app do cuidador, o convite pode ser
    // avisado por e-mail ou WhatsApp pelo menu de compartilhar.
    final avisar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convite criado!'),
        content: Text(
          'Quando $email entrar no app, verá o convite na aba Perfil. '
          'Quer avisar a pessoa por WhatsApp ou e-mail?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Agora não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Avisar'),
          ),
        ],
      ),
    );
    if (avisar == true) {
      await _conviteService.compartilharConvite(paciente: _usuario);
    }
  }

  // RF07: código de convite para enviar por qualquer app.
  Future<void> _gerarCodigo() async {
    try {
      final codigo = await _conviteService.gerarCodigo(_usuario);
      await _conviteService.compartilharConvite(
        paciente: _usuario,
        codigo: codigo,
      );
    } catch (_) {
      if (mounted) {
        mostrarMensagem(context, 'Não foi possível gerar o código.', erro: true);
      }
    }
  }

  Future<void> _usarCodigo() async {
    final codigo = await _pedirTexto(
      titulo: 'Código de convite',
      valorInicial: '',
      validator: (value) => RegExp(r'^[A-Za-z0-9]{6}$').hasMatch((value ?? '').trim())
          ? null
          : 'O código tem 6 letras e números.',
    );
    if (codigo == null) {
      return;
    }

    try {
      final nome = await _conviteService.aceitarCodigo(codigo);
      await widget.sessao.recarregarPacientes();
      if (mounted) {
        mostrarMensagem(context, 'Agora você acompanha $nome!');
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        mostrarMensagem(
          context,
          e.message ?? 'Não foi possível usar o código.',
          erro: true,
        );
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagem(context, 'Não foi possível usar o código.', erro: true);
      }
    }
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

  Future<void> _desvincular(Usuario outro) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Desvincular ${outro.nome}?'),
        content: Text(
          _usuario.isPaciente
              ? 'Este cuidador deixará de ver suas medições e de receber seus alertas.'
              : 'Você deixará de ver as medições e de receber os alertas deste paciente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Desvincular',
              style: TextStyle(color: AppColors.primaria),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true) {
      return;
    }

    await _executar(() async {
      await _conviteService.desvincular(
        pacienteId: _usuario.isPaciente ? _usuario.uid : outro.uid,
        cuidadorId: _usuario.isPaciente ? outro.uid : _usuario.uid,
      );
      await widget.sessao.recarregarPacientes();
    }, 'Vínculo removido.');
  }

  Widget _fotoEditavel(String uid) {
    return Semantics(
      button: true,
      label: 'Alterar foto de perfil',
      child: GestureDetector(
        onTap: _salvandoFoto ? null : _alterarFoto,
        child: Stack(
          children: [
            AvatarUsuario(uid: uid, tamanho: 130),
            Positioned(
              right: 4,
              bottom: 4,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaria,
                child: _salvandoFoto
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.photo_camera, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _alterarFoto() async {
    final opcao = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(context, 'galeria'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remover foto'),
              onTap: () => Navigator.pop(context, 'remover'),
            ),
          ],
        ),
      ),
    );
    if (opcao == null) {
      return;
    }

    setState(() => _salvandoFoto = true);
    try {
      if (opcao == 'remover') {
        await _fotoService.remover(_usuario.uid);
      } else {
        final salvou = await _fotoService.escolherESalvar(
          _usuario.uid,
          usarCamera: opcao == 'camera',
        );
        if (salvou && mounted) {
          mostrarMensagem(context, 'Foto atualizada!');
        }
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagem(context, 'Não foi possível salvar a foto.', erro: true);
      }
    } finally {
      if (mounted) {
        setState(() => _salvandoFoto = false);
      }
    }
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
            topo: _fotoEditavel(usuario.uid),
            acaoEsquerda: IconButton(
              tooltip: 'Configurações',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfiguracoesScreen(sessao: widget.sessao),
                ),
              ),
              icon: const Icon(Icons.settings, color: Colors.white),
            ),
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
          if (widget.sessao.pacienteSelecionado != null) ...[
            _botaoDoPaciente(
              icone: Icons.alarm,
              rotulo: 'Medições agendadas',
              tela: (sessao) => AgendamentosScreen(sessao: sessao),
            ),
            _botaoDoPaciente(
              icone: Icons.medication,
              rotulo: 'Medicamentos',
              tela: (sessao) => MedicamentosScreen(sessao: sessao),
            ),
          ],
          const SizedBox(height: 20),
          _botaoVinculos(),
          if (_vinculosAbertos) _listaVinculos(),
          const SizedBox(height: 12),
          if (usuario.isPaciente)
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                _botaoTexto(
                  Icons.person_add_alt,
                  'Convidar por e-mail',
                  _convidarCuidador,
                ),
                _botaoTexto(Icons.share, 'Enviar código de convite', _gerarCodigo),
              ],
            )
          else ...[
            Center(
              child: _botaoTexto(
                Icons.vpn_key_outlined,
                'Tenho um código de convite',
                _usarCodigo,
              ),
            ),
            _convitesRecebidos(),
          ],
        ],
      ),
    );
  }

  Widget _botaoTexto(IconData icone, String rotulo, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icone, color: AppColors.primaria),
      label: Text(
        rotulo,
        style: const TextStyle(
          color: AppColors.primaria,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Atalhos que valem para o paciente acompanhado (o próprio usuário, ou o
  // paciente selecionado no caso do cuidador).
  Widget _botaoDoPaciente({
    required IconData icone,
    required String rotulo,
    required Widget Function(SessaoController sessao) tela,
  }) {
    final paciente = widget.sessao.pacienteSelecionado!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 4, 30, 0),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primaria),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => tela(widget.sessao)),
        ),
        icon: Icon(icone, color: AppColors.primaria),
        label: Text(
          _usuario.isPaciente ? rotulo : '$rotulo de ${paciente.nome}',
          style: const TextStyle(color: AppColors.primaria),
        ),
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
                    leading: AvatarUsuario(uid: v.uid, tamanho: 40, borda: 0),
                    title: Text(v.nome),
                    subtitle: Text(v.telefone),
                    trailing: IconButton(
                      tooltip: 'Desvincular',
                      icon: const Icon(Icons.link_off, color: AppColors.primaria),
                      onPressed: () => _desvincular(v),
                    ),
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
