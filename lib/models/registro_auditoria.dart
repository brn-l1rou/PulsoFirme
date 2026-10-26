import 'package:cloud_firestore/cloud_firestore.dart';

// RF08: log imutável de quem criou, editou ou excluiu cada medição
// (coleção "Auditoria_confirmacao" do diagrama do banco de dados).
class RegistroAuditoria {
  final String id;
  final String medicaoId;
  final String acao;
  final String uidResponsavel;
  final String nomeResponsavel;
  final DateTime data;
  final int? valorAnterior;
  final int? valorNovo;

  const RegistroAuditoria({
    required this.id,
    required this.medicaoId,
    required this.acao,
    required this.uidResponsavel,
    required this.nomeResponsavel,
    required this.data,
    this.valorAnterior,
    this.valorNovo,
  });

  String get acaoFormatada => switch (acao) {
        'criacao' => 'Registrado',
        'edicao' => 'Editado',
        'exclusao' => 'Excluído',
        _ => acao,
      };

  factory RegistroAuditoria.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RegistroAuditoria(
      id: doc.id,
      medicaoId: data['medicaoId'] as String? ?? '',
      acao: data['acao'] as String? ?? '',
      uidResponsavel: data['uidResponsavel'] as String? ?? '',
      nomeResponsavel: data['nomeResponsavel'] as String? ?? '',
      data: (data['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      valorAnterior: (data['valorAnterior'] as num?)?.toInt(),
      valorNovo: (data['valorNovo'] as num?)?.toInt(),
    );
  }
}
