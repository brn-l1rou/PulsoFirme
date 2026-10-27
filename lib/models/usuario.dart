import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/formatadores.dart';

class Usuario {
  static const int limiteMinimoPadrao = 70;
  static const int limiteMaximoPadrao = 180;

  final String uid;
  final String nome;
  final String email;
  final String telefone;
  final String dataNascimento;
  final String tipoUsuario;
  final List<String> cuidadoresAutorizados;
  final List<String> pacientesVinculados;
  final int limiteMinimo;
  final int limiteMaximo;

  const Usuario({
    required this.uid,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.dataNascimento,
    required this.tipoUsuario,
    this.cuidadoresAutorizados = const [],
    this.pacientesVinculados = const [],
    this.limiteMinimo = limiteMinimoPadrao,
    this.limiteMaximo = limiteMaximoPadrao,
  });

  bool get isPaciente => tipoUsuario == 'paciente';
  bool get isCuidador => tipoUsuario == 'cuidador';

  String get tipoFormatado => isPaciente ? 'Paciente' : 'Cuidador';

  int? get idade => calcularIdade(dataNascimento);

  // Documentos antigos podem não ter os campos de vínculo e limites,
  // por isso todos os campos têm valor padrão.
  factory Usuario.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Usuario(
      uid: doc.id,
      nome: data['nome'] as String? ?? '',
      email: data['email'] as String? ?? '',
      telefone: data['telefone'] as String? ?? '',
      dataNascimento: data['dataNascimento'] as String? ?? '',
      tipoUsuario: data['tipoUsuario'] as String? ?? 'paciente',
      cuidadoresAutorizados:
          List<String>.from(data['cuidadoresAutorizados'] as List? ?? []),
      pacientesVinculados:
          List<String>.from(data['pacientesVinculados'] as List? ?? []),
      limiteMinimo:
          (data['limiteMinimo'] as num?)?.toInt() ?? limiteMinimoPadrao,
      limiteMaximo:
          (data['limiteMaximo'] as num?)?.toInt() ?? limiteMaximoPadrao,
    );
  }
}
