async function analisar() {
  const cookies = document.cookie.split(";").map(c => c.trim());
  const rastreadores = cookies.filter(c => /(_ga|_gid|fbp|ajs_|amplitude|session)/i.test(c));
  const sessoes = await detectarSessoes();

  const results = {
    idioma: navigator.language,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    userAgent: navigator.userAgent,
    cookiesAtivos: cookies,
    cookiesRastreadores: rastreadores,
    sessoesAtivas: sessoes.filter(s => s.ativo).map(s => s.site),
    canvasFingerprint: getCanvasFingerprint(),
    audioFingerprint: await getAudioFingerprint(),
    webRTCLeak: await detectWebRTCLeak(),
    dnsLeak: await detectDNSLeak(),
    score: 100,
    dicas: []
  };

  if (results.userAgent.includes("Chrome")) {
    results.score -= 20;
    results.dicas.push("Evite usar o Chrome. Prefira Firefox, Brave ou Tor Browser.");
  }

  if (results.userAgent.includes(navigator.platform)) {
    results.score -= 10;
    results.dicas.push("Seu user-agent revela o sistema operacional. Considere alterá-lo.");
  }

  if (results.timezone && results.timezone !== "UTC") {
    results.score -= 10;
    results.dicas.push("Seu timezone pode revelar sua localização. Use UTC ou altere no navegador.");
  }

  if (results.idioma && !results.idioma.startsWith("en")) {
    results.score -= 10;
    results.dicas.push("Seu idioma revela sua região. Use navegador em inglês para maior anonimato.");
  }

  if (cookies.length > 0) {
    results.score -= 10;
    results.dicas.push("Cookies detectados. Considere usar navegação privada ou bloqueadores.");
  }

  if (rastreadores.length > 0) {
    results.score -= 10;
    results.dicas.push("Cookies de rastreamento identificados. Use extensões como uBlock ou Privacy Badger.");
  }

  if (results.sessoesAtivas.length > 0) {
    results.score -= 15;
    results.dicas.push("Sessões abertas detectadas (ex: Google, Facebook). Isso pode reduzir sua anonimidade.");
  }

  if (results.webRTCLeak) {
    results.score -= 30;
    results.dicas.push("WebRTC ativo pode vazar seu IP real. Use extensões para bloquear.");
  }

  if (results.dnsLeak) {
    results.score -= 20;
    results.dicas.push("DNS leak detectado. Use DNS seguro (ex: Cloudflare, DNSCrypt, ou VPN com proteção DNS).");
  }

  let scoreColor = results.score >= 80 ? "green" : results.score >= 50 ? "orange" : "red";

  document.getElementById("resultado").innerHTML = `
    <div class="score" style="color:${scoreColor};">Score de Anonimato: ${results.score}/100</div>
    <h3>Dicas:</h3>
    <ul>${results.dicas.map(d => "<li>" + d + "</li>").join("")}</ul>
    <h3>Detalhes Técnicos:</h3>
    <pre>${JSON.stringify(results, null, 2)}</pre>
  `;
}

function getCanvasFingerprint() {
  const canvas = document.createElement("canvas");
  const ctx = canvas.getContext("2d");
  ctx.textBaseline = "top";
  ctx.font = "14px 'Arial'";
  ctx.fillText("AnonCheck", 2, 2);
  return canvas.toDataURL();
}

async function getAudioFingerprint() {
  const ctx = new (window.AudioContext || window.webkitAudioContext)();
  const osc = ctx.createOscillator();
  const analyser = ctx.createAnalyser();
  const gain = ctx.createGain();
  const script = ctx.createScriptProcessor(4096, 1, 1);

  return new Promise(resolve => {
    script.onaudioprocess = function () {
      resolve("audio_fp_" + new Date().getTime());
      script.disconnect();
      osc.disconnect();
    };
    osc.connect(analyser);
    analyser.connect(gain);
    gain.connect(script);
    script.connect(ctx.destination);
    osc.start(0);
  });
}

async function detectWebRTCLeak() {
  return new Promise(resolve => {
    let rtc = new RTCPeerConnection({ iceServers: [] });
    rtc.createDataChannel("");
    rtc.createOffer().then(offer => rtc.setLocalDescription(offer));
    rtc.onicecandidate = evt => {
      if (evt && evt.candidate && evt.candidate.candidate.includes("srflx")) {
        resolve(true);
      } else {
        resolve(false);
      }
    };
  });
}

async function detectDNSLeak() {
  try {
    const rand = Math.floor(Math.random() * 100000);
    await fetch(`https://${rand}.anoncheck.dnsleaktest.com`, { mode: 'no-cors' });
    return true;
  } catch (e) {
    return false;
  }
}

async function detectarSessoes() {
  const alvos = [
    { nome: "Google", url: "https://mail.google.com/favicon.ico" },
    { nome: "Facebook", url: "https://www.facebook.com/favicon.ico" },
    { nome: "Twitter", url: "https://twitter.com/favicon.ico" }
  ];
  const resultados = [];

  for (const site of alvos) {
    try {
      await fetch(site.url, { mode: "no-cors", credentials: "include" });
      resultados.push({ site: site.nome, ativo: true });
    } catch {
      resultados.push({ site: site.nome, ativo: false });
    }
  }
  return resultados;
}
