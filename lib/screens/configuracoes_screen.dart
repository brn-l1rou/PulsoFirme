import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/preferencias_controller.dart';
import '../controllers/sessao_controller.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';
import '../theme/app_colors.dart';
import '../utils/validadores.dart';
import '../widgets/campos.dart';

class ConfiguracoesScreen extends StatefulWidget {
  final SessaoController sessao;

  const ConfiguracoesScreen({super.key, required this.sessao});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final PreferenciasController _preferencias = PreferenciasController.instancia;
  final PinService _pinService = PinService();
  final AuthService _authService = AuthService();
  bool? _temPin;

  String get _uid => widget.sessao.usuario!.uid;

  @override
  void initState() {
    super.initState();
    _pinService.temPin(_uid).then((tem) {
      if (mounted) {
        setState(() => _temPin = tem);
      }
    });
  }

  Future<void> _alternarPin(bool ativar) async {
    if (!ativar) {
      await _pinService.removerPin(_uid);
      if (mounted) {
        setState(() => _temPin = false);
        mostrarMensagem(context, 'PIN removido.');
      }
      return;
    }

    final pin = await showDialog<String>(
      context: context,
      builder: (context) => const _DialogoNovoPin(),
    );
    if (pin == null) {
      return;
    }
    await _pinService.definirPin(_uid, pin);
    if (mounted) {
      setState(() => _temPin = true);
      mostrarMensagem(context, 'PIN definido! Ele será pedido ao abrir o app.');
    }
  }

  Future<void> _alterarSenha() async {
    final alterou = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogoConta(
        titulo: 'Alterar senha',
        rotuloNovo: 'Nova senha',
        novoEhSenha: true,
        validarNovo: validarSenhaForte,
        acao: (senhaAtual, novaSenha) => _authService.alterarSenha(
          senhaAtual: senhaAtual,
          novaSenha: novaSenha,
        ),
      ),
    );
    if (alterou == true && mounted) {
      mostrarMensagem(context, 'Senha alterada!');
    }
  }

  Future<void> _alterarEmail() async {
    final alterou = await showDialog<bool>(
      context: context,
      builder: (context) => _DialogoConta(
        titulo: 'Alterar e-mail',
        rotuloNovo: 'Novo e-mail',
        novoEhSenha: false,
        validarNovo: validarEmail,
        acao: (senhaAtual, novoEmail) => _authService.alterarEmail(
          senhaAtual: senhaAtual,
          novoEmail: novoEmail.toLowerCase(),
        ),
      ),
    );
    if (alterou == true && mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirme o novo e-mail'),
          content: const Text(
            'Enviamos um link para o novo endereço. O e-mail só muda depois '
            'que você clicar nele; em seguida, entre no app usando o e-mail novo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
    }
  }

  Widget _secao(String titulo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        titulo,
        style: const TextStyle(
          color: AppColors.primaria,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.primaria,
        foregroundColor: Colors.white,
        title: const Text('Configurações'),
      ),
      body: ListenableBuilder(
        listenable: _preferencias,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            _secao('Acessibilidade'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Tamanho do texto'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SegmentedButton<double>(
                segments: PreferenciasController.escalasFonte.entries
                    .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                    .toList(),
                selected: {_preferencias.escalaFonte},
                onSelectionChanged: (valor) =>
                    _preferencias.definirEscalaFonte(valor.first),
              ),
            ),
            SwitchListTile(
              activeTrackColor: AppColors.primaria,
              title: const Text('Modo simplificado'),
              subtitle: const Text(
                'Mostra só o essencial: registrar a glicemia com botões grandes.',
              ),
              value: _preferencias.modoSimplificado,
              onChanged: (ativo) async {
                await _preferencias.definirModoSimplificado(ativo);
                if (ativo && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            _secao('Segurança'),
            SwitchListTile(
              activeTrackColor: AppColors.primaria,
              title: const Text('PIN de acesso'),
              subtitle: const Text(
                'Pede um PIN de 4 dígitos sempre que o app for aberto.',
              ),
              value: _temPin ?? false,
              onChanged: _temPin == null ? null : _alternarPin,
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Alterar senha'),
              onTap: _alterarSenha,
            ),
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Alterar e-mail'),
              subtitle: Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
              ),
              onTap: _alterarEmail,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogoNovoPin extends StatefulWidget {
  const _DialogoNovoPin();

  @override
  State<_DialogoNovoPin> createState() => _DialogoNovoPinState();
}

class _DialogoNovoPinState extends State<_DialogoNovoPin> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration decoracao(String rotulo) =>
        InputDecoration(labelText: rotulo, counterText: '');

    return AlertDialog(
      title: const Text('Criar PIN'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _pinController,
              autofocus: true,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: decoracao('PIN (4 dígitos)'),
              validator: (valor) =>
                  (valor ?? '').length == 4 ? null : 'O PIN deve ter 4 dígitos.',
            ),
            TextFormField(
              controller: _confirmacaoController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: decoracao('Repita o PIN'),
              validator: (valor) =>
                  valor == _pinController.text ? null : 'Os PINs não conferem.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _pinController.text);
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// Diálogo comum para trocar senha ou e-mail: pede a senha atual (RF21:
// "insere as informações de login antigas") e o valor novo.
class _DialogoConta extends StatefulWidget {
  final String titulo;
  final String rotuloNovo;
  final bool novoEhSenha;
  final String? Function(String?) validarNovo;
  final Future<void> Function(String senhaAtual, String novo) acao;

  const _DialogoConta({
    required this.titulo,
    required this.rotuloNovo,
    required this.novoEhSenha,
    required this.validarNovo,
    required this.acao,
  });

  @override
  State<_DialogoConta> createState() => _DialogoContaState();
}

class _DialogoContaState extends State<_DialogoConta> {
  final _formKey = GlobalKey<FormState>();
  final _atualController = TextEditingController();
  final _novoController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _atualController.dispose();
    _novoController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await widget.acao(_atualController.text, _novoController.text.trim());
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = AuthService.mensagemDeErro(e));
    } catch (_) {
      setState(() => _erro = 'Não foi possível concluir a alteração.');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _atualController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (valor) =>
                    (valor ?? '').isEmpty ? 'Informe a senha atual.' : null,
              ),
              TextFormField(
                controller: _novoController,
                obscureText: widget.novoEhSenha,
                keyboardType: widget.novoEhSenha
                    ? TextInputType.visiblePassword
                    : TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: widget.rotuloNovo,
                  errorMaxLines: 3,
                ),
                validator: widget.validarNovo,
              ),
              if (widget.novoEhSenha)
                TextFormField(
                  controller: _confirmacaoController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Repita a nova senha'),
                  validator: (valor) => valor == _novoController.text
                      ? null
                      : 'As senhas não conferem.',
                ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_erro!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
