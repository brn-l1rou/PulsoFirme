import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/sessao_controller.dart';
import '../models/medicao.dart';
import '../services/medicao_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cabecalho_curvo.dart';
import '../widgets/glicemia_chart.dart';
import '../widgets/logo_app.dart';
import '../widgets/medicao_card.dart';
import '../widgets/seletor_paciente.dart';

class RelatorioScreen extends StatefulWidget {
  final SessaoController sessao;

  const RelatorioScreen({super.key, required this.sessao});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  static const List<int> _periodos = [7, 30, 90];

  final MedicaoService _medicaoService = MedicaoService();
  int _dias = 30;
  String? _chaveDoStream;
  Stream<List<Medicao>>? _stream;

  Stream<List<Medicao>> _medicoesDe(String pacienteId) {
    final chave = '$pacienteId-$_dias';
    if (_stream == null || _chaveDoStream != chave) {
      _chaveDoStream = chave;
      final hoje = DateTime.now();
      final inicio = DateTime(hoje.year, hoje.month, hoje.day)
          .subtract(Duration(days: _dias - 1));
      _stream = _medicaoService.watchMedicoes(pacienteId, desde: inicio);
    }
    return _stream!;
  }

  @override
  Widget build(BuildContext context) {
    final paciente = widget.sessao.pacienteSelecionado;

    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          CabecalhoCurvo(
            alturaTopo: 140,
            topo: const LogoApp(tamanho: 100),
            titulo: Column(
              children: [
                const TituloCabecalho('Relatório'),
                const SizedBox(height: 10),
                SeletorPaciente(sessao: widget.sessao),
              ],
            ),
          ),
          if (paciente == null)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                'Nenhum paciente para exibir.',
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: _periodos
                    .map((dias) => ChoiceChip(
                          label: Text('$dias dias'),
                          selected: _dias == dias,
                          selectedColor: AppColors.primaria,
                          labelStyle: TextStyle(
                            color: _dias == dias
                                ? Colors.white
                                : AppColors.primaria,
                            fontWeight: FontWeight.bold,
                          ),
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _dias = dias),
                        ))
                    .toList(),
              ),
            ),
            StreamBuilder<List<Medicao>>(
              stream: _medicoesDe(paciente.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'Erro ao carregar o relatório.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaria,
                      ),
                    ),
                  );
                }

                final medicoes = snapshot.data!;
                return Column(
                  children: [
                    _Resumo(medicoes: medicoes),
                    const SizedBox(height: 12),
                    GlicemiaChart(
                      medicoes: medicoes,
                      limiteMinimo: paciente.limiteMinimo,
                      limiteMaximo: paciente.limiteMaximo,
                    ),
                    const SizedBox(height: 12),
                    ...medicoes.map((m) => MedicaoCard(medicao: m)),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  final List<Medicao> medicoes;

  const _Resumo({required this.medicoes});

  @override
  Widget build(BuildContext context) {
    final valores = medicoes.map((m) => m.valorMgdl).toList();
    final media = valores.isEmpty
        ? '-'
        : (valores.reduce((a, b) => a + b) / valores.length).round().toString();
    final minimo = valores.isEmpty ? '-' : valores.reduce(math.min).toString();
    final maximo = valores.isEmpty ? '-' : valores.reduce(math.max).toString();
    final alertas = medicoes.where((m) => m.foraDoLimite).length.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _item('Média', media),
          _item('Mínima', minimo),
          _item('Máxima', maximo),
          _item('Alertas', alertas),
        ],
      ),
    );
  }

  Widget _item(String rotulo, String valor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            rotulo,
            style: const TextStyle(
              color: AppColors.primaria,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
