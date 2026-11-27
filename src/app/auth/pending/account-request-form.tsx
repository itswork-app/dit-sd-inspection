"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";

type AccountRequestFormProps = {
  mode: "initial" | "reapply";
  initialDisplayName?: string;
};

export function AccountRequestForm({
  mode,
  initialDisplayName = ""
}: AccountRequestFormProps) {
  const router = useRouter();
  const [displayName, setDisplayName] = useState(initialDisplayName);
  const [requestNote, setRequestNote] = useState("");
  const [idempotencyKey, setIdempotencyKey] = useState(() => crypto.randomUUID());
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (isSubmitting) return;

    setErrorMessage(null);
    setSuccessMessage(null);

    const trimmedName = displayName.trim();
    if (trimmedName.length < 2 || trimmedName.length > 120) {
      setErrorMessage("Nama lengkap harus terdiri dari 2 hingga 120 karakter.");
      return;
    }

    setIsSubmitting(true);
    try {
      const response = await fetch("/api/v1/account/request", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": idempotencyKey
        },
        body: JSON.stringify({
          display_name: trimmedName,
          request_note: requestNote.trim() || null
        })
      });

      const payload = (await response.json().catch(() => null)) as
        | { status?: string; error?: { message?: string } }
        | null;

      if (!response.ok) {
        const statusCode = payload?.status;
        if (statusCode === "IDEMPOTENCY_KEY_REUSED") {
          setIdempotencyKey(crypto.randomUUID());
          setErrorMessage("Data permintaan berubah sejak percobaan sebelumnya. Silakan kirim ulang.");
        } else if (statusCode === "STATE_CONFLICT") {
          setErrorMessage("Status akun saat ini tidak mengizinkan pengajuan permintaan baru.");
        } else {
          setErrorMessage(
            payload?.error?.message ?? "Permintaan akses belum dapat diproses. Periksa isian Anda."
          );
        }
        return;
      }

      setIdempotencyKey(crypto.randomUUID());
      setSuccessMessage("Permintaan akses telah tercatat dan menunggu peninjauan Super Admin.");
      router.refresh();
    } catch {
      setErrorMessage("Koneksi ke server terputus. Anda dapat mencoba mengirim ulang secara aman.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form className="rbac-form" onSubmit={handleSubmit}>
      <div className="rbac-field">
        <label htmlFor="display-name">Nama lengkap</label>
        <input
          id="display-name"
          name="display_name"
          type="text"
          required
          minLength={2}
          maxLength={120}
          value={displayName}
          onChange={(e) => {
            setDisplayName(e.target.value);
            setIdempotencyKey(crypto.randomUUID());
          }}
          placeholder="Nama sesuai penugasan inspeksi"
          disabled={isSubmitting}
        />
      </div>

      <div className="rbac-field">
        <label htmlFor="request-note">Catatan penugasan / unit kerja (opsional)</label>
        <textarea
          id="request-note"
          name="request_note"
          rows={3}
          maxLength={500}
          value={requestNote}
          onChange={(e) => {
            setRequestNote(e.target.value);
            setIdempotencyKey(crypto.randomUUID());
          }}
          placeholder="Contoh: Tim Inspeksi Lapangan Wilayah A / referensi surat tugas"
          disabled={isSubmitting}
        />
      </div>

      {errorMessage ? (
        <p className="auth-error" role="alert">
          {errorMessage}
        </p>
      ) : null}
      {successMessage ? (
        <p className="auth-success" role="status">
          {successMessage}
        </p>
      ) : null}

      <button className="auth-button" type="submit" disabled={isSubmitting}>
        {isSubmitting
          ? "Mengirim permintaan..."
          : mode === "reapply"
            ? "Ajukan ulang permintaan akses"
            : "Ajukan permintaan akses"}
      </button>
    </form>
  );
}
