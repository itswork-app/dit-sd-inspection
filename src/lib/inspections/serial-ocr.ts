const NAMEPLATE_NOISE_WORDS = new Set([
  "MODEL",
  "INPUT",
  "OUTPUT",
  "POWER",
  "VOLT",
  "HERTZ",
  "MADE",
  "CHINA",
  "INDONESIA",
  "DATE",
  "CLASS",
  "SERIAL",
  "NUMBER",
  "RATING",
  "WEIGHT",
  "SPECS"
]);

const ELECTRICAL_OR_UNIT_PATTERN = /^\d+(?:\.\d+)?(?:V|VAC|VDC|W|KW|A|MA|MAH|HZ|KHZ|MHZ|KG|G|CM|MM)$/i;
const LABELED_SN_PATTERN =
  /\b(?:SERIAL(?:\s*(?:NO|NUM|NUMBER))?|S\s*\/\s*N|SN)\b[\s.:#-]*([A-Z0-9][A-Z0-9-]{2,31})/gi;
const CANDIDATE_TOKEN_PATTERN = /[A-Z0-9]+(?:-[A-Z0-9]+)*/g;

function normalizeCandidateToken(raw: string): string {
  return raw
    .trim()
    .toUpperCase()
    .replace(/^[^A-Z0-9]+|[^A-Z0-9]+$/g, "");
}

function isPlausibleSerialToken(token: string, allowShortLabeled = false): boolean {
  const minLen = allowShortLabeled ? 4 : 5;
  if (token.length < minLen || token.length > 32) return false;
  if (NAMEPLATE_NOISE_WORDS.has(token)) return false;
  if (ELECTRICAL_OR_UNIT_PATTERN.test(token)) return false;
  if (/^\d{4}[-/]\d{2}(?:[-/]\d{2})?$/.test(token)) return false;

  const compact = token.replace(/-/g, "");
  const hasLetter = /[A-Z]/.test(compact);
  const hasDigit = /\d/.test(compact);
  if (hasLetter && hasDigit) return true;
  if (/^\d{8,32}$/.test(compact)) return true;
  return allowShortLabeled && /^[A-Z0-9]{4,32}$/.test(compact) && hasDigit;
}

/**
 * Extracts and ranks plausible device Serial Number candidates from noisy nameplate OCR output.
 */
export function extractSerialCandidates(rawText: string): string[] {
  const normalizedText = rawText.replace(/\r/g, "\n");
  const candidates: string[] = [];
  const seen = new Set<string>();

  function pushCandidate(raw: string, allowShortLabeled = false) {
    const token = normalizeCandidateToken(raw);
    if (!token || seen.has(token)) return;
    if (!isPlausibleSerialToken(token, allowShortLabeled)) return;
    seen.add(token);
    candidates.push(token);
  }

  // 1. Prioritize explicitly labeled SN fields (e.g. "S/N: 3TB75B9012", "Serial No. SN-99881")
  for (const match of normalizedText.matchAll(LABELED_SN_PATTERN)) {
    if (match[1]) {
      pushCandidate(match[1], true);
      if (candidates.length >= 5) return candidates;
    }
  }

  // 2. Fallback: scan all uppercase tokens across lines, filtering electrical specs and noise
  const upperLines = normalizedText.toUpperCase().split("\n");
  for (const line of upperLines) {
    for (const match of line.matchAll(CANDIDATE_TOKEN_PATTERN)) {
      pushCandidate(match[0], false);
      if (candidates.length >= 5) return candidates;
    }
  }

  return candidates;
}
