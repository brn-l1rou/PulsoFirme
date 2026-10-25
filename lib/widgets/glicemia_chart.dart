import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/medicao.dart';
import '../theme/app_colors.dart';
import '../utils/formatadores.dart';

// Gráfico de linha simples (RF22) desenhado com CustomPainter, sem
// dependências externas. A faixa sombreada mostra os limites do paciente.
class GlicemiaChart extends StatelessWidget {
  final List<Medicao> medicoes;
  final int limiteMinimo;
  final int limiteMaximo;

  const GlicemiaChart({
    super.key,
    required this.medicoes,
    required this.limiteMinimo,
    required this.limiteMaximo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black87),
      ),
      child: medicoes.length < 2
          ? const Center(
              child: Text(
                'Registre ao menos duas medições\npara visualizar o gráfico.',
                textAlign: TextAlign.center,
              ),
            )
          : CustomPaint(
              size: Size.infinite,
              painter: _GlicemiaPainter(
                // O gráfico é lido da esquerda (mais antiga) para a direita.
                medicoes: medicoes.reversed.toList(),
                limiteMinimo: limiteMinimo,
                limiteMaximo: limiteMaximo,
              ),
            ),
    );
  }
}

class _GlicemiaPainter extends CustomPainter {
  static const double _margemEsquerda = 34;
  static const double _margemInferior = 22;

  final List<Medicao> medicoes;
  final int limiteMinimo;
  final int limiteMaximo;

  _GlicemiaPainter({
    required this.medicoes,
    required this.limiteMinimo,
    required this.limiteMaximo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maiorValor = medicoes.map((m) => m.valorMgdl).reduce(math.max);
    final valorTopo = (math.max(maiorValor, 250) / 50).ceil() * 50.0;

    final area = Rect.fromLTRB(
      _margemEsquerda,
      0,
      size.width,
      size.height - _margemInferior,
    );

    double y(num valor) => area.bottom - (valor / valorTopo) * area.height;
    double x(int indice) =>
        area.left + indice * area.width / (medicoes.length - 1);

    final faixaNormal = Paint()
      ..color = AppColors.destaque.withValues(alpha: 0.12);
    canvas.drawRect(
      Rect.fromLTRB(area.left, y(limiteMaximo), area.right, y(limiteMinimo)),
      faixaNormal,
    );

    final grade = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    for (var valor = 0.0; valor <= valorTopo; valor += 50) {
      canvas.drawLine(Offset(area.left, y(valor)), Offset(area.right, y(valor)), grade);
      _escrever(canvas, valor.toInt().toString(), Offset(0, y(valor) - 7));
    }

    final linha = Paint()
      ..color = AppColors.grafico
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final caminho = Path();
    for (var i = 0; i < medicoes.length; i++) {
      final ponto = Offset(x(i), y(medicoes[i].valorMgdl));
      if (i == 0) {
        caminho.moveTo(ponto.dx, ponto.dy);
      } else {
        caminho.lineTo(ponto.dx, ponto.dy);
      }
    }
    canvas.drawPath(caminho, linha);

    for (var i = 0; i < medicoes.length; i++) {
      final medicao = medicoes[i];
      canvas.drawCircle(
        Offset(x(i), y(medicao.valorMgdl)),
        3.5,
        Paint()
          ..color = medicao.foraDoLimite
              ? AppColors.primaria
              : AppColors.grafico,
      );
    }

    final dataInicial = formatarData(medicoes.first.dataMedicao).substring(0, 5);
    final dataFinal = formatarData(medicoes.last.dataMedicao).substring(0, 5);
    _escrever(canvas, dataInicial, Offset(area.left, area.bottom + 6));
    _escrever(
      canvas,
      dataFinal,
      Offset(area.right - 30, area.bottom + 6),
    );
  }

  void _escrever(Canvas canvas, String texto, Offset posicao) {
    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(fontSize: 10, color: Colors.black54),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, posicao);
  }

  @override
  bool shouldRepaint(covariant _GlicemiaPainter oldDelegate) {
    return oldDelegate.medicoes != medicoes ||
        oldDelegate.limiteMinimo != limiteMinimo ||
        oldDelegate.limiteMaximo != limiteMaximo;
  }
}
