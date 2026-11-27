"use client";

import { useEffect, useRef, useState } from "react";
import { extractSerialCandidates } from "@/lib/inspections/serial-ocr";

type SerialScannerProps = {
  onDetected: (serial: string, source: "barcode" | "ocr") => void;
};

type BarcodeDetectorResult = { rawValue?: string };
type BarcodeDetectorLike = {
  detect(source: HTMLVideoElement): Promise<BarcodeDetectorResult[]>;
};

function enhanceCanvasForOcr(ctx: CanvasRenderingContext2D, width: number, height: number) {
  const imageData = ctx.getImageData(0, 0, width, height);
  const data = imageData.data;
  for (let i = 0; i < data.length; i += 4) {
    const luminance = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
    const stretched = Math.max(0, Math.min(255, (luminance - 128) * 1.45 + 128));
    data[i] = stretched;
    data[i + 1] = stretched;
    data[i + 2] = stretched;
  }
  ctx.putImageData(imageData, 0, 0);
}

export function SerialScanner({ onDetected }: SerialScannerProps) {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const timerRef = useRef<number | null>(null);
  const ocrInputRef = useRef<HTMLInputElement | null>(null);
  const [scanning, setScanning] = useState(false);
  const [ocrBusy, setOcrBusy] = useState(false);
  const [statusNote, setStatusNote] = useState<string | null>(null);
  const [ocrCandidates, setOcrCandidates] = useState<string[]>([]);

  function stopCamera() {
    if (timerRef.current !== null) {
      window.clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (streamRef.current) {
      for (const track of streamRef.current.getTracks()) {
        track.stop();
      }
      streamRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
    setScanning(false);
  }

  useEffect(() => {
    return () => {
      stopCamera();
    };
  }, []);

  async function runOcrOnCanvas(canvas: HTMLCanvasElement) {
    setOcrBusy(true);
    setOcrCandidates([]);
    setStatusNote("Memuat mesin OCR...");
    try {
      const { recognize } = await import("tesseract.js");
      const result = await recognize(canvas, "eng", {
        logger: (msg) => {
          if (msg.status === "recognizing text" && typeof msg.progress === "number") {
            setStatusNote(`Membaca OCR... ${Math.round(msg.progress * 100)}%`);
          }
        }
      });
      const rawText = result.data?.text ?? "";
      const candidates = extractSerialCandidates(rawText);
      if (candidates.length === 0) {
        setStatusNote(
          "Teks SN tidak terdeteksi jelas. Dekatkan label SN ke kotak panduan atau ketik manual."
        );
        return;
      }
      setOcrCandidates(candidates);
      stopCamera();
      setStatusNote(`OCR terbaca: ${candidates[0]} (periksa sebelum Klaim Unit).`);
      onDetected(candidates[0], "ocr");
    } catch {
      setStatusNote("Proses OCR gagal pada perangkat ini. Coba ulangi foto atau ketik SN manual.");
    } finally {
      setOcrBusy(false);
    }
  }

  async function captureVideoFrameForOcr() {
    const vid = videoRef.current;
    if (!vid || vid.readyState < 2 || vid.videoWidth === 0 || vid.videoHeight === 0 || ocrBusy) {
      return;
    }
    const cropWidth = Math.max(240, Math.floor(vid.videoWidth * 0.8));
    const cropHeight = Math.max(96, Math.floor(vid.videoHeight * 0.36));
    const sx = Math.floor((vid.videoWidth - cropWidth) / 2);
    const sy = Math.floor((vid.videoHeight - cropHeight) / 2);

    const canvas = document.createElement("canvas");
    canvas.width = cropWidth;
    canvas.height = cropHeight;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    ctx.drawImage(vid, sx, sy, cropWidth, cropHeight, 0, 0, cropWidth, cropHeight);
    enhanceCanvasForOcr(ctx, cropWidth, cropHeight);
    await runOcrOnCanvas(canvas);
  }

  async function handleOcrPhotoFile(file: File | undefined) {
    if (!file || ocrBusy) return;
    setStatusNote("Memproses foto label SN...");
    try {
      const bitmap = await createImageBitmap(file);
      const maxWidth = 1280;
      const scale = bitmap.width > maxWidth ? maxWidth / bitmap.width : 1;
      const width = Math.max(1, Math.round(bitmap.width * scale));
      const height = Math.max(1, Math.round(bitmap.height * scale));
      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext("2d");
      if (!ctx) {
        bitmap.close();
        return;
      }
      ctx.drawImage(bitmap, 0, 0, width, height);
      bitmap.close();
      enhanceCanvasForOcr(ctx, width, height);
      await runOcrOnCanvas(canvas);
    } catch {
      setStatusNote("Gagal membaca file foto label SN.");
    }
  }

  async function startCamera() {
    if (scanning) {
      stopCamera();
      return;
    }
    setStatusNote(null);
    setOcrCandidates([]);
    if (typeof navigator === "undefined" || !navigator.mediaDevices?.getUserMedia) {
      setStatusNote(
        "Kamera langsung tidak tersedia. Gunakan tombol Foto Label (OCR) atau ketik SN secara manual."
      );
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: { ideal: "environment" } },
        audio: false
      });
      streamRef.current = stream;
      setScanning(true);

      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        await videoRef.current.play().catch(() => {});
      }

      const win = window as unknown as {
        BarcodeDetector?: new (opts: { formats: string[] }) => BarcodeDetectorLike;
      };
      if (win.BarcodeDetector) {
        const detector = new win.BarcodeDetector({
          formats: ["qr_code", "code_128", "code_39", "ean_13", "data_matrix"]
        });
        timerRef.current = window.setInterval(() => {
          const vid = videoRef.current;
          if (!vid || vid.readyState < 2) return;
          void detector
            .detect(vid)
            .then((codes) => {
              const hit = codes.find((c) => c.rawValue && c.rawValue.trim().length >= 3);
              if (hit?.rawValue) {
                const value = hit.rawValue.trim();
                stopCamera();
                setStatusNote(`QR/Barcode terbaca: ${value}`);
                onDetected(value, "barcode");
              }
            })
            .catch(() => {
              // Ignore per-frame decode errors
            });
        }, 350);
      } else {
        setStatusNote(
          "Kamera aktif. Browser ini tidak mendukung BarcodeDetector — arahkan ke label lalu tekan Baca Teks SN (OCR)."
        );
      }
    } catch {
      stopCamera();
      setStatusNote(
        "Izin kamera ditolak atau tidak ditemukan. Gunakan Foto Label (OCR) atau ketik SN manual."
      );
    }
  }

  return (
    <div className="admin-list">
      <div className="admin-inline">
        <button
          type="button"
          className="auth-button auth-button-secondary admin-btn-sm"
          disabled={ocrBusy}
          onClick={() => void startCamera()}
        >
          {scanning ? "Tutup Kamera" : "Scan QR / OCR Kamera"}
        </button>
        {scanning ? (
          <button
            type="button"
            className="auth-button admin-btn-sm"
            disabled={ocrBusy}
            onClick={() => void captureVideoFrameForOcr()}
          >
            {ocrBusy ? "Membaca OCR..." : "Baca Teks SN (OCR)"}
          </button>
        ) : null}
        <button
          type="button"
          className="auth-button auth-button-secondary admin-btn-sm"
          disabled={ocrBusy}
          onClick={() => ocrInputRef.current?.click()}
        >
          Foto Label (OCR)
        </button>
        <input
          ref={ocrInputRef}
          type="file"
          accept="image/*"
          capture="environment"
          aria-label="Ambil foto label Serial Number untuk OCR"
          style={{ display: "none" }}
          onChange={(e) => {
            const file = e.target.files?.[0];
            e.target.value = "";
            void handleOcrPhotoFile(file);
          }}
        />
        {statusNote ? <span className="rbac-meta">{statusNote}</span> : null}
      </div>

      {ocrCandidates.length > 0 ? (
        <div className="admin-inline" aria-label="Kandidat Serial Number OCR">
          <span className="rbac-meta">Kandidat SN OCR:</span>
          {ocrCandidates.map((cand) => (
            <button
              key={cand}
              type="button"
              className="auth-button auth-button-secondary admin-btn-sm"
              onClick={() => {
                setStatusNote(`Kandidat dipilih: ${cand}`);
                onDetected(cand, "ocr");
              }}
            >
              {cand}
            </button>
          ))}
        </div>
      ) : null}

      {scanning ? (
        <div style={{ position: "relative", width: "100%", maxWidth: "360px" }}>
          <video
            ref={videoRef}
            muted
            playsInline
            autoPlay
            style={{
              width: "100%",
              display: "block",
              borderRadius: "10px",
              border: "1px solid var(--border)"
            }}
          />
          <div
            aria-hidden="true"
            style={{
              position: "absolute",
              left: "10%",
              right: "10%",
              top: "32%",
              height: "36%",
              border: "2px dashed #38bdf8",
              borderRadius: "8px",
              boxShadow: "0 0 0 9999px rgba(15, 23, 42, 0.28)",
              pointerEvents: "none"
            }}
          />
        </div>
      ) : null}
    </div>
  );
}
