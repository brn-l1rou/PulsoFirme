const { GoogleGenAI } = require("@google/genai");

// Alias que sempre aponta para o modelo Flash mais recente da Gemini API.
const MODELO_IA = "gemini-flash-latest";

// Coeficiente de variação acima de 36% indica glicemia instável
// (consenso internacional de monitorização de glicose).
const LIMITE_VARIABILIDADE = 36;

const PERIODOS = [
  { nome: "madrugada", inicio: 0, fim: 6 },
  { nome: "manhã", inicio: 6, fim: 12 },
  { nome: "tarde", inicio: 12, fim: 18 },
  { nome: "noite", inicio: 18, fim: 24 },
];

const NOMES_CONTEXTO = {
  jejum: "em jejum",
  pre_prandial: "antes das refeições",
  pos_prandial: "após as refeições",
  antes_dormir: "antes de dormir",
};

function media(valores) {
  return valores.reduce((soma, v) => soma + v, 0) / valores.length;
}

function desvioPadrao(valores) {
  const m = media(valores);
  return Math.sqrt(media(valores.map((v) => (v - m) ** 2)));
}

function resumoGrupo(medicoes, limites) {
  const valores = medicoes.map((m) => m.valor);
  return {
    quantidade: medicoes.length,
    media: Math.round(media(valores)),
    acima: medicoes.filter((m) => m.valor > limites.maximo).length,
    abaixo: medicoes.filter((m) => m.valor < limites.minimo).length,
  };
}

// RN19: identifica padrões anormais no histórico. Cada medição tem
// { valor, data (Date), hora (0-24, no fuso de São Paulo), contexto, sintomas }.
function analisarEstatisticas(medicoes, limites, dias) {
  const valores = medicoes.map((m) => m.valor);
  const geral = resumoGrupo(medicoes, limites);
  const naFaixa = medicoes.length - geral.acima - geral.abaixo;
  const percentualNaFaixa = Math.round((naFaixa / medicoes.length) * 100);
  const cv = Math.round((desvioPadrao(valores) / media(valores)) * 100);
  const padroes = [];

  // Horários do dia em que a glicemia costuma sair da faixa.
  const porPeriodo = {};
  for (const periodo of PERIODOS) {
    const grupo = medicoes.filter((m) => m.hora >= periodo.inicio && m.hora < periodo.fim);
    if (grupo.length === 0) {
      continue;
    }
    const resumo = resumoGrupo(grupo, limites);
    porPeriodo[periodo.nome] = resumo;
    if (resumo.quantidade >= 3 && resumo.acima / resumo.quantidade >= 0.5) {
      padroes.push(
        `Glicemia acima do limite com frequência pela ${periodo.nome} ` +
          `(${resumo.acima} de ${resumo.quantidade} medições, média ${resumo.media} mg/dL).`,
      );
    }
    if (resumo.quantidade >= 3 && resumo.abaixo / resumo.quantidade >= 0.3) {
      padroes.push(
        `Glicemia abaixo do limite com frequência pela ${periodo.nome} ` +
          `(${resumo.abaixo} de ${resumo.quantidade} medições).`,
      );
    }
  }

  // RF12: momento da medição (jejum, após refeição...).
  const porContexto = {};
  for (const [chave, nome] of Object.entries(NOMES_CONTEXTO)) {
    const grupo = medicoes.filter((m) => m.contexto === chave);
    if (grupo.length === 0) {
      continue;
    }
    const resumo = resumoGrupo(grupo, limites);
    porContexto[nome] = resumo;
    if (resumo.quantidade >= 3 && (resumo.acima + resumo.abaixo) / resumo.quantidade >= 0.5) {
      padroes.push(
        `Medições ${nome} saem da faixa com frequência ` +
          `(${resumo.acima + resumo.abaixo} de ${resumo.quantidade}, média ${resumo.media} mg/dL).`,
      );
    }
  }

  // Tendência: última semana comparada com a anterior.
  const agora = Date.now();
  const semana = 7 * 86400000;
  const ultimaSemana = medicoes.filter((m) => agora - m.data.getTime() <= semana);
  const semanaAnterior = medicoes.filter((m) => {
    const idade = agora - m.data.getTime();
    return idade > semana && idade <= 2 * semana;
  });
  let tendencia = null;
  if (ultimaSemana.length >= 3 && semanaAnterior.length >= 3) {
    const diferenca = Math.round(
      media(ultimaSemana.map((m) => m.valor)) - media(semanaAnterior.map((m) => m.valor)),
    );
    tendencia = diferenca;
    if (Math.abs(diferenca) >= 15) {
      padroes.push(
        `A média dos últimos 7 dias ${diferenca > 0 ? "subiu" : "caiu"} ` +
          `${Math.abs(diferenca)} mg/dL em relação à semana anterior.`,
      );
    }
  }

  const hiposSemana = ultimaSemana.filter((m) => m.valor < limites.minimo).length;
  if (hiposSemana >= 2) {
    padroes.push(`Houve ${hiposSemana} medições abaixo do limite nos últimos 7 dias.`);
  }

  if (medicoes.length >= 5 && cv > LIMITE_VARIABILIDADE) {
    padroes.push(
      `A glicemia está variando bastante (coeficiente de variação de ${cv}%, ` +
        `acima de ${LIMITE_VARIABILIDADE}%).`,
    );
  }

  // RF13: sintomas que mais aparecem junto de valores fora da faixa.
  const contagemSintomas = {};
  for (const medicao of medicoes) {
    if (medicao.valor >= limites.minimo && medicao.valor <= limites.maximo) {
      continue;
    }
    for (const sintoma of medicao.sintomas) {
      contagemSintomas[sintoma] = (contagemSintomas[sintoma] || 0) + 1;
    }
  }
  const sintomasFrequentes = Object.entries(contagemSintomas)
    .filter(([, vezes]) => vezes >= 2)
    .sort((a, b) => b[1] - a[1]);
  if (sintomasFrequentes.length > 0) {
    const [sintoma, vezes] = sintomasFrequentes[0];
    padroes.push(`"${sintoma}" foi relatado ${vezes} vezes junto de valores fora da faixa.`);
  }

  if (padroes.length === 0) {
    padroes.push("Nenhum padrão anormal foi identificado no período.");
  }

  return {
    dias,
    totalMedicoes: medicoes.length,
    media: geral.media,
    minima: Math.min(...valores),
    maxima: Math.max(...valores),
    percentualNaFaixa,
    acimaDoLimite: geral.acima,
    abaixoDoLimite: geral.abaixo,
    coeficienteVariacao: cv,
    tendenciaSemanal: tendencia,
    porPeriodo,
    porContexto,
    sintomasFrequentes: Object.fromEntries(sintomasFrequentes),
    padroes,
    resumo:
      `Nos últimos ${dias} dias: média de ${geral.media} mg/dL e ` +
      `${percentualNaFaixa}% das medições dentro da faixa ` +
      `(${limites.minimo} a ${limites.maximo} mg/dL).`,
  };
}

// RN19/RN21: a IA só reescreve os dados calculados acima em linguagem
// simples; ela não diagnostica nem sugere mudanças de tratamento.
async function gerarTextoComIa(chaveApi, estatisticas, limites) {
  const ia = new GoogleGenAI({ apiKey: chaveApi });
  const resposta = await ia.models.generateContent({
    model: MODELO_IA,
    contents: JSON.stringify({ limites, ...estatisticas }),
    config: {
      systemInstruction:
        "Você ajuda famílias a acompanhar a glicemia de um paciente com diabetes. " +
        "Recebe estatísticas já calculadas das medições (mg/dL) e escreve, em português " +
        "do Brasil, com linguagem simples para leigos: um resumo de 1 a 2 frases e de 1 a 4 " +
        "pontos curtos destacando padrões anormais (horários, momentos da refeição, " +
        "tendência, variabilidade, sintomas). Use apenas os números recebidos; não invente " +
        "dados. Não faça diagnósticos, não sugira doses ou mudanças de remédio. Quando houver " +
        "valores fora da faixa com frequência, recomende conversar com o médico. Se nada " +
        "estiver anormal, diga isso de forma tranquilizadora.",
      temperature: 0.3,
      responseMimeType: "application/json",
      responseJsonSchema: {
        type: "object",
        properties: {
          resumo: { type: "string" },
          pontos: { type: "array", items: { type: "string" }, maxItems: 4 },
        },
        required: ["resumo", "pontos"],
      },
    },
  });

  const texto = JSON.parse(resposta.text);
  if (typeof texto.resumo !== "string" || !Array.isArray(texto.pontos)) {
    throw new Error("Resposta da IA em formato inesperado");
  }
  return { resumo: texto.resumo, pontos: texto.pontos.slice(0, 4).map(String) };
}

module.exports = { analisarEstatisticas, gerarTextoComIa };
