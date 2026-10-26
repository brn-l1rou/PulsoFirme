import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/sessao_controller.dart';
import '../models/alerta.dart';
import '../models/medicao.dart';
import '../services/alerta_service.dart';
import '../services/medicao_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatadores.dart';
import '../widgets/campos.dart';

enum _FiltroTipo { todas, acima, abaixo, perdida, agendada, sos }

enum _FiltroPeriodo { hoje, semana, mes }

// Item exibido na lista, vindo de uma medição fora do limite (RN16) ou de
// um alerta gravado em usuarios/{id}/alertas (SOS, agendada, perdida).
class _ItemAlerta {
  final _FiltroTipo tipo;
  final DateTime data;
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Uri? link;

  const _ItemAlerta({
    required this.tipo,
    required this.data,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    this.link,
  });

  factory _ItemAlerta.daMedicao(Medicao medicao) {
    final acima = medicao.status == StatusGlicemia.acima;
    return _ItemAlerta(
      tipo: acima ? _FiltroTipo.acima : _FiltroTipo.abaixo,
      data: medicao.dataMedicao,
      titulo: acima ? 'Medição acima do limite!' : 'Medição abaixo do limite!',
      subtitulo:
          '${formatarDataHora(medicao.dataMedicao)} • ${medicao.valorMgdl} mg/dL',
      icone: Icons.warning_rounded,
    );
  }

  static _ItemAlerta? doAlerta(Alerta alerta) {
    final quando = formatarDataHora(alerta.criadoEm);
    return switch (alerta.tipo) {
      'sos' => _ItemAlerta(
          tipo: _FiltroTipo.sos,
          data: alerta.criadoEm,
          titulo: 'SOS - pedido de ajuda!',
          subtitulo: alerta.temLocalizacao
              ? '$quando • Toque para ver a localização'
              : '$quando • Localização indisponível',
          icone: Icons.sos,
          link: alerta.linkMapa,
        ),
      'perdida' => _ItemAlerta(
          tipo: _FiltroTipo.perdida,
          data: alerta.criadoEm,
          titulo: 'Medição perdida - ${alerta.hora ?? ''}',
          subtitulo: quando,
          icone: Icons.alarm_off,
        ),
      'agendada' => _ItemAlerta(
          tipo: _FiltroTipo.agendada,
          data: alerta.criadoEm,
          titulo: 'Medição agendada - ${alerta.hora ?? ''}',
          subtitulo: quando,
          icone: Icons.alarm,
        ),
      _ => null,
    };
  }
}

class AlertasScreen extends StatefulWidget {
  final SessaoController sessao;

  const AlertasScreen({super.key, required this.sessao});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final MedicaoService _medicaoService = MedicaoService();
  final AlertaService _alertaService = AlertaService();
  _FiltroTipo _tipo = _FiltroTipo.todas;
  _FiltroPeriodo _periodo = _FiltroPeriodo.hoje;
  String? _chaveDosStreams;
  Stream<List<Medicao>>? _medicoes;
  Stream<List<Alerta>>? _alertas;

  void _prepararStreams(String pacienteId) {
    final chave = '$pacienteId-${_periodo.name}';
    if (_chaveDosStreams == chave) {
      return;
    }

    _chaveDosStreams = chave;
    final hoje = DateTime.now();
    final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);
    final inicio = switch (_periodo) {
      _FiltroPeriodo.hoje => inicioDoDia,
      _FiltroPeriodo.semana => inicioDoDia.subtract(const Duration(days: 6)),
      _FiltroPeriodo.mes => inicioDoDia.subtract(const Duration(days: 29)),
    };
    _medicoes = _medicaoService.watchMedicoes(pacienteId, desde: inicio);
    _alertas = _alertaService.watchAlertas(pacienteId, desde: inicio);
  }

  List<_ItemAlerta> _juntar(List<Medicao> medicoes, List<Alerta> alertas) {
    final itens = [
      ...medicoes.where((m) => m.foraDoLimite).map(_ItemAlerta.daMedicao),
      ...alertas.map(_ItemAlerta.doAlerta).whereType<_ItemAlerta>(),
    ]..sort((a, b) => b.data.compareTo(a.data));

    if (_tipo == _FiltroTipo.todas) {
      return itens;
    }
    return itens.where((item) => item.tipo == _tipo).toList();
  }

  Future<void> _abrirLink(Uri link) async {
    final abriu = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      mostrarMensagem(context, 'Não foi possível abrir o mapa.', erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paciente = widget.sessao.pacienteSelecionado;
    if (paciente != null) {
      _prepararStreams(paciente.uid);
    }

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
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackButton(color: AppColors.primaria),
                ),
                Text(
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
              _FiltroTipo.perdida: 'PERDIDAS',
              _FiltroTipo.agendada: 'AGENDADAS',
              _FiltroTipo.sos: 'SOS',
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
                    stream: _medicoes,
                    builder: (context, medicoes) => StreamBuilder<List<Alerta>>(
                      stream: _alertas,
                      builder: (context, alertas) {
                        if (medicoes.hasError) {
                          return const _MensagemBranca(
                            'Erro ao carregar os alertas.',
                          );
                        }
                        if (!medicoes.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        }

                        // Se os alertas do servidor falharem, ainda mostramos
                        // os de glicemia fora do limite.
                        final itens = _juntar(
                          medicoes.data!,
                          alertas.data ?? const [],
                        );
                        if (itens.isEmpty) {
                          return const _MensagemBranca(
                            'Nenhum alerta no período selecionado.',
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: itens.length,
                          itemBuilder: (context, index) {
                            final item = itens[index];
                            return _AlertaCard(
                              item: item,
                              onTap: item.link == null
                                  ? null
                                  : () => _abrirLink(item.link!),
                            );
                          },
                        );
                      },
                    ),
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
  final _ItemAlerta item;
  final VoidCallback? onTap;

  const _AlertaCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(item.icone, color: AppColors.primaria, size: 36),
        title: Text(
          item.titulo,
          style: const TextStyle(
            color: AppColors.primaria,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(item.subtitulo),
        trailing: onTap == null ? null : const Icon(Icons.map_outlined),
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
