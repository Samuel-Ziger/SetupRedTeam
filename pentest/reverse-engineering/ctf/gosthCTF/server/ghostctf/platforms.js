export const PLATFORMS = {
  solyd: {
    id: 'solyd',
    label: 'Solyd',
    // Ex.: Solyd{Its*Always*Easier*To*Have*One*Strong*Password}
    flagRegex: /Solyd\{[^}]+\}/g,
    // Validação do formato final (normaliza espaços).
    validateFlag: (flag) => /^Solyd\{[^}]+\}$/.test(String(flag).trim()),
  },
  hackthebox: {
    id: 'hackthebox',
    label: 'HackTheBox',
    // Ex.: HTB{SomeFlagValue}
    flagRegex: /HTB\{[^}]+\}/g,
    validateFlag: (flag) => /^HTB\{[^}]+\}$/.test(String(flag).trim()),
  },
  google_ctf: {
    id: 'google_ctf',
    label: 'Google CTF',
    // Ex. (varia por CTF/edição): GCTF{...} ou GoogleCTF{...}
    flagRegex: /(?:GCTF|GoogleCTF)\{[^}]+\}/g,
    validateFlag: (flag) => /^(?:GCTF|GoogleCTF)\{[^}]+\}$/.test(String(flag).trim()),
  },
};

export function getPlatform(platformId) {
  const key = String(platformId || '').trim().toLowerCase();
  return PLATFORMS[key] || null;
}

