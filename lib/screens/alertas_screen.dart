import 'package:flutter/material.dart';

import '../controllers/sessao_controller.dart';
import '../models/medicao.dart';
import '../services/medicao_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatadores.dart';

enum _FiltroTipo { todas, acima, abaixo }

enum _FiltroPeriodo { hoje, semana, mes }

// RN16: lista as medições fora dos limites configurados para o paciente.
class AlertasScreen extends StatefulWidget {
  final SessaoController sessao;

  const AlertasScreen({super.key, required this.sessao});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final MedicaoService _medicaoService = MedicaoService();
  _FiltroTipo _tipo = _FiltroTipo.todas;
  _FiltroPeriodo _periodo = _FiltroPeriodo.hoje;
  String? _chaveDoStream;
  Stream<List<Medicao>>? _stream;

  Stream<List<Medicao>> _medicoesDe(String pacienteId) {
    final chave = '$pacienteId-${_periodo.name}';
    if (_stream == null || _chaveDoStream != chave) {
      _chaveDoStream = chave;
      final hoje = DateTime.now();
      final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);
      final inicio = switch (_periodo) {
        _FiltroPeriodo.hoje => inicioDoDia,
        _FiltroPeriodo.semana => inicioDoDia.subtract(const Duration(days: 6)),
        _FiltroPeriodo.mes => inicioDoDia.subtract(const Duration(days: 29)),
      };
      _stream = _medicaoService.watchMedicoes(pacienteId, desde: inicio);
    }
    return _stream!;
  }

  bool _passaNoFiltro(Medicao medicao) {
    return switch (_tipo) {
      _FiltroTipo.todas => medicao.foraDoLimite,
      _FiltroTipo.acima => medicao.status == StatusGlicemia.acima,
      _FiltroTipo.abaixo => medicao.status == StatusGlicemia.abaixo,
    };
  }

  @override
  Widget build(BuildContext context) {
    final paciente = widget.sessao.pacienteSelecionado;

    return Scaffold(
      backgroundColor: AppColors.primaria,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.fundo,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BackButton(color: AppColors.primaria),
                ),
                const Text(
                  'Alertas',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaria,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Filtro<_FiltroTipo>(
            rotulo: 'Tipo notificação:',
            valor: _tipo,
            opcoes: const {
              _FiltroTipo.todas: 'TODAS',
              _FiltroTipo.acima: 'ACIMA',
              _FiltroTipo.abaixo: 'ABAIXO',
            },
            onChanged: (valor) => setState(() => _tipo = valor),
          ),
          const SizedBox(height: 10),
          _Filtro<_FiltroPeriodo>(
            rotulo: 'Período notificação:',
            valor: _periodo,
            opcoes: const {
              _FiltroPeriodo.hoje: 'HOJE',
              _FiltroPeriodo.semana: '7 DIAS',
              _FiltroPeriodo.mes: '30 DIAS',
            },
            onChanged: (valor) => setState(() => _periodo = valor),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: paciente == null
                ? const SizedBox.shrink()
                : StreamBuilder<List<Medicao>>(
                    stream: _medicoesDe(paciente.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const _MensagemBranca('Erro ao carregar os alertas.');
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final alertas =
                          snapshot.data!.where(_passaNoFiltro).toList();
                      if (alertas.isEmpty) {
                        return const _MensagemBranca(
                          'Nenhum alerta no período selecionado.',
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: alertas.length,
                        itemBuilder: (context, index) =>
                            _AlertaCard(medicao: alertas[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Filtro<T> extends StatelessWidget {
  final String rotulo;
  final T valor;
  final Map<T, String> opcoes;
  final ValueChanged<T> onChanged;

  const _Filtro({
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rotulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: valor,
              iconEnabledColor: AppColors.primaria,
              style: const TextStyle(
                color: AppColors.destaque,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlusJakartaSans',
              ),
              items: opcoes.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (novo) {
                if (novo != null) {
                  onChanged(novo);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final Medicao medicao;

  const _AlertaCard({required this.medicao});

  @override
  Widget build(BuildContext context) {
    final acima = medicao.status == StatusGlicemia.acima;
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: const Icon(
          Icons.warning_rounded,
          color: AppColors.primaria,
          size: 36,
        ),
        title: Text(
          acima ? 'Medição acima do limite!' : 'Medição abaixo do limite!',
          style: const TextStyle(
            color: AppColors.primaria,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${formatarDataHora(medicao.dataMedicao)} • ${medicao.valorMgdl} mg/dL',
        ),
      ),
    );
  }
}

class _MensagemBranca extends StatelessWidget {
  final String texto;

  const _MensagemBranca(this.texto);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
