import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/medicao.dart';
import '../models/usuario.dart';
import '../utils/formatadores.dart';

// RF16: consolida as medições do período em um PDF para o médico.
class RelatorioPdfService {
  static const PdfColor _vermelho = PdfColor.fromInt(0xFFCC2B25);

  Future<Uint8List> gerar({
    required Usuario paciente,
    required List<Medicao> medicoes,
    required int dias,
  }) async {
    // A fonte do app tem os acentos do português.
    final fonte = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'),
    );
    final fonteNegrito = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'),
    );
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/logo_red_background.png'))
          .buffer
          .asUint8List(),
    );

    final ordenadas = [...medicoes]
      ..sort((a, b) => a.dataMedicao.compareTo(b.dataMedicao));
    final valores = ordenadas.map((m) => m.valorMgdl).toList();
    final hoje = DateTime.now();
    final inicio = hoje.subtract(Duration(days: dias - 1));

    final documento = pw.Document(
      theme: pw.ThemeData.withFont(base: fonte, bold: fonteNegrito),
    );

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _cabecalho(logo),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Gerado em ${formatarDataHora(hoje)} pelo Pulso Firme - '
            'página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          _dadosPaciente(paciente, inicio, hoje),
          pw.SizedBox(height: 16),
          _resumo(ordenadas, valores),
          pw.SizedBox(height: 16),
          if (ordenadas.isEmpty)
            pw.Text('Nenhuma medição registrada no período.')
          else
            _tabela(ordenadas),
          pw.SizedBox(height: 16),
          pw.Text(
            'Valores fora da faixa definida para o paciente estão destacados. '
            'Este relatório é informativo e não substitui avaliação médica.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return documento.save();
  }

  Future<void> compartilhar({
    required Uint8List pdf,
    required Usuario paciente,
  }) async {
    final nomeArquivo =
        'relatorio_glicemia_${paciente.nome.split(' ').first.toLowerCase()}.pdf';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(pdf, mimeType: 'application/pdf')],
        fileNameOverrides: [nomeArquivo],
        subject: 'Relatório de glicemia - ${paciente.nome}',
        text: 'Relatório de glicemia de ${paciente.nome} gerado pelo Pulso Firme.',
      ),
    );
  }

  pw.Widget _cabecalho(pw.ImageProvider logo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _vermelho, width: 2)),
      ),
      child: pw.Row(
        children: [
          pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(logo, width: 40, height: 40),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            'Relatório de Glicemia',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _vermelho,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _dadosPaciente(Usuario paciente, DateTime inicio, DateTime fim) {
    final idade = paciente.idade;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _linha('Paciente', paciente.nome),
        if (idade != null)
          _linha('Idade', '$idade anos (nasc. ${paciente.dataNascimento})'),
        _linha('Período', '${formatarData(inicio)} a ${formatarData(fim)}'),
        _linha(
          'Faixa desejada',
          '${paciente.limiteMinimo} a ${paciente.limiteMaximo} mg/dL',
        ),
      ],
    );
  }

  pw.Widget _linha(String rotulo, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$rotulo: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  pw.Widget _resumo(List<Medicao> medicoes, List<int> valores) {
    String texto(int? valor) => valor == null ? '-' : '$valor mg/dL';
    final media = valores.isEmpty
        ? null
        : (valores.reduce((a, b) => a + b) / valores.length).round();
    final acima =
        medicoes.where((m) => m.status == StatusGlicemia.acima).length;
    final abaixo =
        medicoes.where((m) => m.status == StatusGlicemia.abaixo).length;

    final itens = {
      'Medições': '${medicoes.length}',
      'Média': texto(media),
      'Mínima': texto(valores.isEmpty ? null : valores.reduce(math.min)),
      'Máxima': texto(valores.isEmpty ? null : valores.reduce(math.max)),
      'Acima do limite': '$acima',
      'Abaixo do limite': '$abaixo',
    };

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: itens.entries
          .map((item) => pw.Container(
                width: 160,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.key,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      item.value,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  pw.Widget _tabela(List<Medicao> medicoes) {
    String situacao(StatusGlicemia status) => switch (status) {
          StatusGlicemia.acima => 'Acima',
          StatusGlicemia.abaixo => 'Abaixo',
          StatusGlicemia.normal => 'Normal',
        };

    return pw.TableHelper.fromTextArray(
      headers: [
        'Data',
        'Hora',
        'Glicemia (mg/dL)',
        'Situação',
        'Momento',
        'Sintomas / observação',
      ],
      data: medicoes
          .map((m) => [
                formatarData(m.dataMedicao),
                formatarHora(m.dataMedicao),
                '${m.valorMgdl}',
                situacao(m.status),
                m.contextoFormatado ?? '',
                [...m.sintomas, ?m.observacao].join('; '),
              ])
          .toList(),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: _vermelho),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerLeft,
        5: pw.Alignment.centerLeft,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.6),
        3: const pw.FlexColumnWidth(1.4),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(3.5),
      },
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellDecoration: (index, data, rowNum) {
        final foraDoLimite = index == 3 && data != 'Normal';
        return foraDoLimite
            ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFADBD8))
            : const pw.BoxDecoration();
      },
    );
  }
}
