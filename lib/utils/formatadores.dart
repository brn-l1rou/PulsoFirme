String _doisDigitos(int valor) => valor.toString().padLeft(2, '0');

String formatarData(DateTime data) {
  return '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year}';
}

String formatarHora(DateTime data) {
  return '${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}';
}

String formatarDataHora(DateTime data) {
  return '${formatarData(data)} - ${formatarHora(data)}';
}

// Converte uma data no formato dd/MM/yyyy (como salvo no cadastro).
DateTime? converterData(String texto) {
  final partes = texto.split('/');
  if (partes.length != 3) {
    return null;
  }

  final dia = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final ano = int.tryParse(partes[2]);
  if (dia == null || mes == null || ano == null) {
    return null;
  }

  return DateTime(ano, mes, dia);
}

int? calcularIdade(String dataNascimento) {
  final nascimento = converterData(dataNascimento);
  if (nascimento == null) {
    return null;
  }

  final hoje = DateTime.now();
  var idade = hoje.year - nascimento.year;
  final aindaNaoFezAniversario = hoje.month < nascimento.month ||
      (hoje.month == nascimento.month && hoje.day < nascimento.day);
  if (aindaNaoFezAniversario) {
    idade--;
  }

  return idade;
}
