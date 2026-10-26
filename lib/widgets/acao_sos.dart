import 'dart:async';

import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/alerta_service.dart';
import '../theme/app_colors.dart';
import 'campos.dart';

// RF06: confirma e envia um alerta de emergência com a localização do
// paciente para todos os cuidadores vinculados. Usado na tela de
// Registros e no modo simplificado.
Future<void> enviarSosComConfirmacao(
  BuildContext context,
  Usuario paciente,
) async {
  if (paciente.cuidadoresAutorizados.isEmpty) {
    mostrarMensagem(
      context,
      'Você ainda não tem cuidadores vinculados para receber o SOS.',
      erro: true,
    );
    return;
  }

  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.sos, color: AppColors.primaria, size: 48),
      title: const Text('Enviar pedido de ajuda?'),
      content: const Text(
        'Seus cuidadores receberão um alerta de emergência com a sua '
        'localização atual.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaria),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Enviar SOS', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  if (confirmado != true || !context.mounted) {
    return;
  }

  try {
    final alertaService = AlertaService();
    final posicao = await alertaService.obterLocalizacao();
    await alertaService
        .enviarSos(pacienteId: paciente.uid, posicao: posicao)
        .timeout(const Duration(seconds: 10));
    if (context.mounted) {
      mostrarMensagem(
        context,
        posicao == null
            ? 'SOS enviado (sem localização: verifique o GPS e a permissão).'
            : 'SOS enviado com a sua localização!',
      );
    }
  } on TimeoutException {
    // O Firestore mantém o alerta na fila e envia quando a conexão voltar.
    if (context.mounted) {
      mostrarMensagem(
        context,
        'Sem conexão: o SOS será enviado quando a internet voltar. '
        'Se for urgente, ligue 192.',
        erro: true,
      );
    }
  } catch (_) {
    if (context.mounted) {
      mostrarMensagem(
        context,
        'Não foi possível enviar o SOS. Se for urgente, ligue 192.',
        erro: true,
      );
    }
  }
}
