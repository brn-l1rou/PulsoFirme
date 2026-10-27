import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Os diálogos são StatefulWidgets para que os TextEditingControllers só
// sejam descartados quando o diálogo sai da árvore (depois da animação
// de fechamento), e não logo que o resultado é devolvido.

class DialogoTexto extends StatefulWidget {
  final String titulo;
  final String valorInicial;
  final TextInputType teclado;
  final String? Function(String?)? validator;

  const DialogoTexto({
    super.key,
    required this.titulo,
    this.valorInicial = '',
    this.teclado = TextInputType.text,
    this.validator,
  });

  @override
  State<DialogoTexto> createState() => _DialogoTextoState();
}

class _DialogoTextoState extends State<DialogoTexto> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.valorInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: widget.teclado,
          autofocus: true,
          validator: widget.validator,
          onFieldSubmitted: (_) => _confirmar(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _confirmar, child: const Text('Salvar')),
      ],
    );
  }
}

class LimitesGlicemia {
  final int minimo;
  final int maximo;

  const LimitesGlicemia(this.minimo, this.maximo);
}

class DialogoLimites extends StatefulWidget {
  final int minimoInicial;
  final int maximoInicial;

  const DialogoLimites({
    super.key,
    required this.minimoInicial,
    required this.maximoInicial,
  });

  @override
  State<DialogoLimites> createState() => _DialogoLimitesState();
}

class _DialogoLimitesState extends State<DialogoLimites> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minimoController;
  late final TextEditingController _maximoController;

  @override
  void initState() {
    super.initState();
    _minimoController =
        TextEditingController(text: widget.minimoInicial.toString());
    _maximoController =
        TextEditingController(text: widget.maximoInicial.toString());
  }

  @override
  void dispose() {
    _minimoController.dispose();
    _maximoController.dispose();
    super.dispose();
  }

  String? _validarLimite(String? value) {
    final numero = int.tryParse(value ?? '');
    if (numero == null || numero <= 0 || numero > 600) {
      return 'Valor inválido.';
    }
    return null;
  }

  String? _validarMaximo(String? value) {
    final erro = _validarLimite(value);
    if (erro != null) {
      return erro;
    }
    final minimo = int.tryParse(_minimoController.text) ?? 0;
    return int.parse(value!) <= minimo
        ? 'O máximo deve ser maior que o mínimo.'
        : null;
  }

  void _confirmar() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(
        context,
        LimitesGlicemia(
          int.parse(_minimoController.text),
          int.parse(_maximoController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Limites de glicemia (mg/dL)'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _minimoController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Mínimo'),
              validator: _validarLimite,
            ),
            TextFormField(
              controller: _maximoController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Máximo'),
              validator: _validarMaximo,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(onPressed: _confirmar, child: const Text('Salvar')),
      ],
    );
  }
}
