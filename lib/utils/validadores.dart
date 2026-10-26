// RNF02: mínimo de 8 caracteres, com maiúscula, minúscula, número e
// caractere especial.
String? validarSenhaForte(String? value) {
  if (value == null || value.isEmpty) {
    return 'Informe sua senha.';
  }

  final faltando = <String>[
    if (value.length < 8) '8 caracteres',
    if (!RegExp(r'[A-Z]').hasMatch(value)) '1 letra maiúscula',
    if (!RegExp(r'[a-z]').hasMatch(value)) '1 letra minúscula',
    if (!RegExp(r'[0-9]').hasMatch(value)) '1 número',
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) '1 caractere especial',
  ];
  if (faltando.isNotEmpty) {
    return 'A senha precisa ter: ${faltando.join(', ')}.';
  }

  return null;
}

String? validarEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Informe o e-mail.';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
    return 'E-mail inválido.';
  }
  return null;
}
