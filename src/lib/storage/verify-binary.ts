import { createHash } from "node:crypto";
import type { ALLOWED_EVIDENCE_MIMES } from "@/lib/api/inspection-validators";

export type AllowedEvidenceMime = (typeof ALLOWED_EVIDENCE_MIMES)[number];

/**
 * Sniffs canonical file magic bytes to prevent MIME spoofing on private evidence/document uploads.
 */
export function detectAllowedMimeFromBytes(bytes: Uint8Array): AllowedEvidenceMime | null {
  if (bytes.byteLength < 8) return null;

  // JPEG: FF D8 FF
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return "image/jpeg";
  }

  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a
  ) {
    return "image/png";
  }

  // WebP: RIFF....WEBP
  if (
    bytes.byteLength >= 12 &&
    bytes[0] === 0x52 &&
    bytes[1] === 0x49 &&
    bytes[2] === 0x46 &&
    bytes[3] === 0x46 &&
    bytes[8] === 0x57 &&
    bytes[9] === 0x45 &&
    bytes[10] === 0x42 &&
    bytes[11] === 0x50
  ) {
    return "image/webp";
  }

  // PDF: %PDF-
  if (
    bytes[0] === 0x25 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x44 &&
    bytes[3] === 0x46 &&
    bytes[4] === 0x2d
  ) {
    return "application/pdf";
  }

  // MP4 (ISO Base Media File Format): ....ftyp
  if (
    bytes.byteLength >= 12 &&
    bytes[4] === 0x66 &&
    bytes[5] === 0x74 &&
    bytes[6] === 0x79 &&
    bytes[7] === 0x70
  ) {
    return "video/mp4";
  }

  // WebM / EBML: 1A 45 DF A3
  if (
    bytes[0] === 0x1a &&
    bytes[1] === 0x45 &&
    bytes[2] === 0xdf &&
    bytes[3] === 0xa3
  ) {
    return "video/webm";
  }

  return null;
}

export function inspectBinaryArtifact(bytes: Uint8Array): {
  sha256: string;
  byteSize: number;
  detectedMime: AllowedEvidenceMime | null;
} {
  const sha256 = createHash("sha256").update(bytes).digest("hex");
  return {
    sha256,
    byteSize: bytes.byteLength,
    detectedMime: detectAllowedMimeFromBytes(bytes)
  };
}
