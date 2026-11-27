import { describe, expect, it } from "vitest";
import { detectAllowedMimeFromBytes, inspectBinaryArtifact } from "./verify-binary";
import { renderMinimalPdfDocument } from "@/lib/pdf/minimal-pdf";

describe("binary artifact verification & deterministic PDF 1.4 renderer", () => {
  it("[TC-EVD-002] detects valid JPEG, PNG, WebP, and PDF magic bytes and rejects forged content", () => {
    const png = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00]);
    const jpg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46]);
    const webp = new Uint8Array([0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50]);
    const forgedHtml = new TextEncoder().encode("<html><script>alert(1)</script></html>");

    expect(detectAllowedMimeFromBytes(png)).toBe("image/png");
    expect(detectAllowedMimeFromBytes(jpg)).toBe("image/jpeg");
    expect(detectAllowedMimeFromBytes(webp)).toBe("image/webp");
    expect(detectAllowedMimeFromBytes(forgedHtml)).toBeNull();
  });

  it("renders deterministic valid PDF 1.4 binaries recognized by magic-byte verifier", () => {
    const spec = {
      title: "Dit. SD Inspection - Approved Certificate",
      lines: ["Document Type: INSPECTION_PDF", "Version: 1", "Status: APPROVED"]
    };
    const pdfA = renderMinimalPdfDocument(spec);
    const pdfB = renderMinimalPdfDocument(spec);

    const text = new TextDecoder("ascii").decode(pdfA);
    expect(text.startsWith("%PDF-1.4\n")).toBe(true);
    expect(text.endsWith("%%EOF\n")).toBe(true);
    expect(text).toContain("Dit. SD Inspection - Approved Certificate");

    const infoA = inspectBinaryArtifact(pdfA);
    const infoB = inspectBinaryArtifact(pdfB);
    expect(infoA.detectedMime).toBe("application/pdf");
    expect(infoA.sha256).toBe(infoB.sha256);
    expect(infoA.byteSize).toBe(pdfA.byteLength);
  });
});
