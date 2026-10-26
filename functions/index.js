const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

setGlobalOptions({ maxInstances: 10 });

// RN17: faixa "crítica" (mais severa que os limites do paciente), em mg/dL.
const LIMITE_CRITICO_MINIMO = 54;
const LIMITE_CRITICO_MAXIMO = 250;

// O Brasil não tem horário de verão desde 2019, então São Paulo é sempre
// UTC-3. Os horários dos agendamentos são salvos nesse fuso.
const FUSO = "America/Sao_Paulo";
const DESLOCAMENTO_UTC_HORAS = 3;

const TOKENS_INVALIDOS = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

// ---------------------------------------------------------------------------
// Auxiliares
// ---------------------------------------------------------------------------

async function buscarPaciente(pacienteId) {
  const doc = await db.collection("usuarios").doc(pacienteId).get();
  return doc.exists ? doc.data() : null;
}

// RN18: só o paciente e os cuidadores vinculados recebem notificações.
function destinatarios(pacienteId, paciente, { incluirPaciente, excluir }) {
  const uids = [...(paciente.cuidadoresAutorizados || [])];
  if (incluirPaciente) {
    uids.push(pacienteId);
  }
  return [...new Set(uids)].filter((uid) => uid !== excluir);
}

async function enviarPush(uids, { titulo, corpo, dados = {} }) {
  if (uids.length === 0) {
    return;
  }

  // Tokens ficam em usuarios/{uid}/tokens/{token} (salvos pelo app).
  const snapshots = await Promise.all(
    uids.map((uid) => db.collection("usuarios").doc(uid).collection("tokens").get()),
  );
  const referencias = snapshots.flatMap((snap) => snap.docs.map((doc) => doc.ref));
  if (referencias.length === 0) {
    logger.info("Nenhum aparelho registrado para", uids);
    return;
  }

  const resposta = await getMessaging().sendEachForMulticast({
    tokens: referencias.map((ref) => ref.id),
    notification: { title: titulo, body: corpo },
    data: Object.fromEntries(
      Object.entries(dados).map(([chave, valor]) => [chave, String(valor)]),
    ),
    android: { priority: "high" },
    apns: { payload: { aps: { sound: "default" } } },
  });

  // Remove tokens de aparelhos que desinstalaram o app ou trocaram de conta.
  const remocoes = resposta.responses
    .map((item, indice) => ({ item, ref: referencias[indice] }))
    .filter(({ item }) => !item.success && TOKENS_INVALIDOS.has(item.error?.code))
    .map(({ ref }) => ref.delete());
  await Promise.all(remocoes);

  logger.info(`Push "${titulo}": ${resposta.successCount} enviados, ${resposta.failureCount} falhas`);
}

// ---------------------------------------------------------------------------
// RF11 / RN16 / RN17: medição fora do limite
// ---------------------------------------------------------------------------

exports.notificarGlicemiaAnormal = onDocumentCreated(
  "usuarios/{pacienteId}/medicoes/{medicaoId}",
  async (event) => {
    const medicao = event.data?.data();
    if (!medicao || medicao.status === "normal") {
      return;
    }

    const { pacienteId } = event.params;
    const paciente = await buscarPaciente(pacienteId);
    if (!paciente) {
      return;
    }

    const valor = medicao.valorMgdl;
    const critico = valor < LIMITE_CRITICO_MINIMO || valor > LIMITE_CRITICO_MAXIMO;
    const direcao = medicao.status === "acima" ? "acima" : "abaixo";

    await enviarPush(
      destinatarios(pacienteId, paciente, {
        incluirPaciente: true,
        excluir: medicao.registradoPor,
      }),
      {
        titulo: critico
          ? `ALERTA CRÍTICO: glicemia de ${paciente.nome}`
          : `Glicemia ${direcao} do limite`,
        corpo: `${paciente.nome} registrou ${valor} mg/dL (${direcao} do limite).`,
        dados: { tipo: critico ? "critico" : direcao, pacienteId },
      },
    );
  },
);

// ---------------------------------------------------------------------------
// RF06: botão SOS
// ---------------------------------------------------------------------------

exports.notificarSos = onDocumentCreated(
  "usuarios/{pacienteId}/alertas/{alertaId}",
  async (event) => {
    const alerta = event.data?.data();
    if (!alerta || alerta.tipo !== "sos") {
      return;
    }

    const { pacienteId } = event.params;
    const paciente = await buscarPaciente(pacienteId);
    if (!paciente) {
      return;
    }

    const temLocalizacao = alerta.latitude != null && alerta.longitude != null;
    await enviarPush(
      destinatarios(pacienteId, paciente, { incluirPaciente: false }),
      {
        titulo: `SOS: ${paciente.nome} precisa de ajuda!`,
        corpo: temLocalizacao
          ? "Abra o app em Alertas para ver a localização."
          : "Localização indisponível. Entre em contato imediatamente.",
        dados: {
          tipo: "sos",
          pacienteId,
          latitude: alerta.latitude ?? "",
          longitude: alerta.longitude ?? "",
        },
      },
    );
  },
);

// ---------------------------------------------------------------------------
// RF14 / RF15: lembretes e medições perdidas
// ---------------------------------------------------------------------------

function agoraNoFuso(data) {
  const partes = Object.fromEntries(
    new Intl.DateTimeFormat("en-CA", {
      timeZone: FUSO,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      weekday: "short",
      hourCycle: "h23",
    })
      .formatToParts(data)
      .map((parte) => [parte.type, parte.value]),
  );
  const diasSemana = { Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7 };

  return {
    ano: Number(partes.year),
    mes: Number(partes.month),
    dia: Number(partes.day),
    diaSemana: diasSemana[partes.weekday],
    minutosDoDia: Number(partes.hour) * 60 + Number(partes.minute),
    dataIso: `${partes.year}-${partes.month}-${partes.day}`,
  };
}

function diasEntre(dataIsoInicio, dataIsoFim) {
  const inicio = Date.parse(`${dataIsoInicio}T00:00:00Z`);
  const fim = Date.parse(`${dataIsoFim}T00:00:00Z`);
  return Math.round((fim - inicio) / 86400000);
}

function ocorreHoje(agendamento, hoje) {
  switch (agendamento.frequencia) {
    case "semanal":
      return agendamento.diaSemana === hoje.diaSemana;
    case "quinzenal": {
      if (agendamento.diaSemana !== hoje.diaSemana) {
        return false;
      }
      const semanas = Math.floor(diasEntre(agendamento.dataInicio, hoje.dataIso) / 7);
      return semanas % 2 === 0;
    }
    default:
      return true;
  }
}

// create() falha se o documento já existir, o que evita alertas e pushes
// duplicados quando a função roda mais de uma vez na mesma janela.
async function criarAlertaUnico(pacienteId, alertaId, dados) {
  try {
    await db
      .collection("usuarios")
      .doc(pacienteId)
      .collection("alertas")
      .doc(alertaId)
      .create({ ...dados, criadoEm: FieldValue.serverTimestamp() });
    return true;
  } catch (erro) {
    if (erro.code === 6) {
      // ALREADY_EXISTS
      return false;
    }
    throw erro;
  }
}

async function processarAgendamento(doc, hoje, intervaloMinutos) {
  const agendamento = doc.data();
  if (!agendamento.ativo || !ocorreHoje(agendamento, hoje)) {
    return;
  }

  const pacienteId = doc.ref.parent.parent.id;
  const [hora, minuto] = agendamento.hora.split(":").map(Number);
  const minutoAgendado = hora * 60 + minuto;
  const passados = hoje.minutosDoDia - minutoAgendado;
  const tolerancia = agendamento.toleranciaMinutos ?? 30;

  const ehLembrete = passados >= 0 && passados < intervaloMinutos;
  // Só verifica dentro de 1h após a tolerância, para não gerar avisos
  // antigos quando a função é publicada no meio do dia.
  const ehVerificacao = passados >= tolerancia && passados < tolerancia + 60;
  if (!ehLembrete && !ehVerificacao) {
    return;
  }

  const paciente = await buscarPaciente(pacienteId);
  if (!paciente) {
    return;
  }
  const todos = destinatarios(pacienteId, paciente, { incluirPaciente: true });

  if (ehLembrete) {
    const criado = await criarAlertaUnico(pacienteId, `${doc.id}_${hoje.dataIso}_agendada`, {
      tipo: "agendada",
      hora: agendamento.hora,
      agendamentoId: doc.id,
    });
    if (criado) {
      await enviarPush(todos, {
        titulo: "Hora de medir a glicemia",
        corpo: `Medição de ${paciente.nome} agendada para ${agendamento.hora}.`,
        dados: { tipo: "agendada", pacienteId },
      });
    }
    return;
  }

  // Considera feita qualquer medição a partir de 1h antes do horário.
  const horarioAgendado = new Date(
    Date.UTC(hoje.ano, hoje.mes - 1, hoje.dia, hora + DESLOCAMENTO_UTC_HORAS, minuto),
  );
  const inicioJanela = new Date(horarioAgendado.getTime() - 60 * 60 * 1000);
  const medicoes = await db
    .collection("usuarios")
    .doc(pacienteId)
    .collection("medicoes")
    .where("dataMedicao", ">=", Timestamp.fromDate(inicioJanela))
    .limit(1)
    .get();
  if (!medicoes.empty) {
    return;
  }

  const criado = await criarAlertaUnico(pacienteId, `${doc.id}_${hoje.dataIso}_perdida`, {
    tipo: "perdida",
    hora: agendamento.hora,
    agendamentoId: doc.id,
  });
  if (criado) {
    await enviarPush(todos, {
      titulo: `Medição perdida - ${agendamento.hora}`,
      corpo: `Nenhuma medição de ${paciente.nome} foi registrada até ${tolerancia} min após o horário.`,
      dados: { tipo: "perdida", pacienteId },
    });
  }
}

const INTERVALO_MINUTOS = 5;

exports.verificarAgendamentos = onSchedule(
  { schedule: `every ${INTERVALO_MINUTOS} minutes`, timeZone: FUSO },
  async () => {
    const hoje = agoraNoFuso(new Date());
    // Sem filtro na consulta para não exigir índice de collection group;
    // os inativos são ignorados em processarAgendamento.
    const agendamentos = await db.collectionGroup("agendamentos").get();

    const resultados = await Promise.allSettled(
      agendamentos.docs.map((doc) => processarAgendamento(doc, hoje, INTERVALO_MINUTOS)),
    );
    resultados
      .filter((resultado) => resultado.status === "rejected")
      .forEach((resultado) => logger.error("Erro ao processar agendamento", resultado.reason));
  },
);
