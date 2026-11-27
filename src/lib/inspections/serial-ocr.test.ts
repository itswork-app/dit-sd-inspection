import { describe, expect, it } from "vitest";
import { extractSerialCandidates } from "./serial-ocr";

describe("[INS-005] extractSerialCandidates", () => {
  it("prioritizes explicitly labeled S/N or Serial Number tokens", () => {
    const ocrText = `
      MODEL: IFP-75PRO
      INPUT: 220V 50HZ 350W
      S/N: 3tb75b-004912
      MADE IN INDONESIA
    `;
    const result = extractSerialCandidates(ocrText);
    expect(result[0]).toBe("3TB75B-004912");
  });

  it("extracts alphanumeric or >=8-digit serials from multi-line noisy nameplate OCR", () => {
    const ocrText = `
      POWER CLASS 1
      RATING 100V 60HZ
      DATE 2026-11
      UNIT ID SN90887766A
      BATCH 202611270042
    `;
    const result = extractSerialCandidates(ocrText);
    expect(result).toContain("SN90887766A");
    expect(result).toContain("202611270042");
    expect(result).not.toContain("CLASS");
    expect(result).not.toContain("220V");
    expect(result).not.toContain("60HZ");
  });

  it("returns empty array for empty text or pure nameplate noise", () => {
    expect(extractSerialCandidates("")).toEqual([]);
    expect(
      extractSerialCandidates("MODEL POWER INPUT OUTPUT 220V 50HZ MADE IN CHINA")
    ).toEqual([]);
  });
});
