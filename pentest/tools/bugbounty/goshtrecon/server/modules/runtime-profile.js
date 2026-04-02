export const RECON_PROFILES = {
  quick: {
    name: 'quick',
    maxHostsToProbe: 36,
    maxInterestingUrls: 180,
    maxVerifyEndpoints: 14,
    includeCliArchives: false,
  },
  standard: {
    name: 'standard',
    maxHostsToProbe: 80,
    maxInterestingUrls: 400,
    maxVerifyEndpoints: 36,
    includeCliArchives: false,
  },
  deep: {
    name: 'deep',
    maxHostsToProbe: 130,
    maxInterestingUrls: 900,
    maxVerifyEndpoints: 72,
    includeCliArchives: true,
  },
};

export function resolveReconProfile(name) {
  const key = String(name || 'standard').trim().toLowerCase();
  return RECON_PROFILES[key] || RECON_PROFILES.standard;
}
