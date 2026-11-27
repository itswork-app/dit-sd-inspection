export type MinimalPdfSpec = {
  title: string;
  lines: string[];
};

function escapePdfLiteral(input: string): string {
  // Sanitize to printable ASCII for deterministic single-byte PDF literal strings
  const ascii = input.replace(/[^\x20-\x7e]/g, "?");
  return ascii.replace(/\\/g, "\\\\").replace(/\(/g, "\\(").replace(/\)/g, "\\)");
}

/**
 * Deterministic, zero-dependency PDF 1.4 binary generator for synthetic/development
 * inspection certificates and Berita Acara artifacts (CMD-036).
 */
export function renderMinimalPdfDocument(spec: MinimalPdfSpec): Uint8Array {
  const safeLines = [spec.title, "", ...spec.lines].slice(0, 40);
  const streamCommands = [
    "BT",
    "/F1 11 Tf",
    "50 760 Td",
    "16 TL",
    ...safeLines.map((line, index) =>
      index === 0
        ? `(${escapePdfLiteral(line)}) Tj`
        : `T* (${escapePdfLiteral(line)}) Tj`
    ),
    "ET"
  ].join("\n");

  const streamByteLength = Buffer.byteLength(streamCommands, "ascii");

  const objects: string[] = [
    "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n",
    "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n",
    "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n",
    "4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n",
    `5 0 obj\n<< /Length ${streamByteLength} >>\nstream\n${streamCommands}\nendstream\nendobj\n`
  ];

  const header = "%PDF-1.4\n";
  const chunks: string[] = [header];
  const offsets: number[] = [0];
  let cursor = Buffer.byteLength(header, "ascii");

  for (const obj of objects) {
    offsets.push(cursor);
    chunks.push(obj);
    cursor += Buffer.byteLength(obj, "ascii");
  }

  const xrefOffset = cursor;
  const xrefLines = [
    "xref",
    `0 ${objects.length + 1}`,
    "0000000000 65535 f ",
    ...offsets.slice(1).map((offset) => `${String(offset).padStart(10, "0")} 00000 n `)
  ];

  const trailer = [
    ...xrefLines,
    "trailer",
    `<< /Size ${objects.length + 1} /Root 1 0 R >>`,
    "startxref",
    String(xrefOffset),
    "%%EOF\n"
  ].join("\n");

  chunks.push(trailer);
  return new Uint8Array(Buffer.from(chunks.join(""), "ascii"));
}
