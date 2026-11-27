"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";

type ProjectRow = {
  id: string;
  code: string;
  name: string;
  status: string;
  timezone: string;
  row_version: string;
};

type SessionRow = {
  id: string;
  project_id: string;
  code: string;
  status: string;
  starts_at: string;
  ends_at: string;
  row_version: string;
};

type CapacityRow = {
  project_id: string;
  inspector_cap: number;
  row_version: string;
};

type InstrumentRow = {
  id: string;
  instrument_type: string;
  code: string;
  name: string;
  status: string;
  row_version: string;
};

type ConflictRow = {
  id: string;
  instrument_type: string;
  serial_normalized: string;
  proposed_project_id: string;
  status: string;
  row_version: string;
};

type WorkspacePanelProps = {
  projects: ProjectRow[];
  sessions: SessionRow[];
  capacities: CapacityRow[];
  instruments: InstrumentRow[];
  conflicts: ConflictRow[];
};

export function WorkspacePanel({
  projects,
  sessions,
  capacities,
  instruments,
  conflicts
}: WorkspacePanelProps) {
  const router = useRouter();
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ kind: "ok" | "err"; text: string } | null>(null);

  // Create Project state
  const [projCode, setProjCode] = useState("");
  const [projName, setProjName] = useState("");
  const [projTz, setProjTz] = useState("Asia/Jakarta");

  // Create Session state
  const [sessProjectId, setSessProjectId] = useState(projects[0]?.id ?? "");
  const [sessCode, setSessCode] = useState("");
  const [sessStart, setSessStart] = useState("");
  const [sessEnd, setSessEnd] = useState("");

  // Create Instrument state
  const [instType, setInstType] = useState("");
  const [instCode, setInstCode] = useState("");
  const [instName, setInstName] = useState("");

  // Register Canonical Unit state
  const [unitProjectId, setUnitProjectId] = useState(projects[0]?.id ?? "");
  const [unitInstrumentId, setUnitInstrumentId] = useState(
    instruments.find((i) => i.status === "ACTIVE")?.id ?? ""
  );
  const [unitSerial, setUnitSerial] = useState("");

  const capByProject = new Map(capacities.map((c) => [c.project_id, c]));
  const activeInstruments = instruments.filter((i) => i.status === "ACTIVE");

  async function callCommand(
    key: string,
    url: string,
    body: Record<string, unknown>,
    successMsg: string
  ) {
    if (busyKey) return;
    setBusyKey(key);
    setFeedback(null);

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "idempotency-key": crypto.randomUUID()
        },
        body: JSON.stringify(body)
      });
      const payload = (await response.json().catch(() => null)) as
        | { status?: string; error?: { code?: string; message?: string } }
        | null;

      if (!response.ok) {
        setFeedback({
          kind: "err",
          text: `Perintah ditolak (${payload?.status ?? payload?.error?.code ?? response.status}): ${
            payload?.error?.message ?? "Periksa izin, versi data, atau aturan domain."
          }`
        });
        return;
      }

      setFeedback({ kind: "ok", text: `${successMsg} (${payload?.status ?? "OK"}).` });
      router.refresh();
    } catch {
      setFeedback({ kind: "err", text: "Koneksi server terputus. Tidak ada mutasi dikonfirmasi." });
    } finally {
      setBusyKey(null);
    }
  }

  async function handleCreateProject(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await callCommand(
      "create-project",
      "/api/v1/projects",
      { code: projCode.trim(), name: projName.trim(), timezone: projTz.trim() },
      `Proyek ${projCode.trim().toUpperCase()} dibuat`
    );
  }

  async function handleCreateSession(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await callCommand(
      "create-session",
      "/api/v1/sessions",
      {
        project_id: sessProjectId,
        code: sessCode.trim(),
        starts_at: new Date(sessStart).toISOString(),
        ends_at: new Date(sessEnd).toISOString()
      },
      `Sesi ${sessCode.trim().toUpperCase()} dibuat (DRAFT)`
    );
  }

  async function handleSessionTransition(
    session: SessionRow,
    action: "ACTIVATE" | "PAUSE" | "RESUME" | "REQUEST_CLOSE" | "CLOSE"
  ) {
    await callCommand(
      `sess-${session.id}-${action}`,
      "/api/v1/sessions/transition",
      {
        session_id: session.id,
        action,
        expected_row_version: session.row_version,
        reason: `Transisi sesi ${action} melalui workspace operasional`
      },
      `Sesi ${session.code} -> ${action}`
    );
  }

  async function handleCreateInstrument(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await callCommand(
      "create-instrument",
      "/api/v1/instruments",
      {
        instrument_type: instType.trim(),
        code: instCode.trim(),
        name: instName.trim()
      },
      `Instrumen ${instCode.trim().toUpperCase()} dibuat (DRAFT)`
    );
  }

  async function handleRegisterUnit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await callCommand(
      "register-unit",
      "/api/v1/units/register",
      {
        project_id: unitProjectId,
        instrument_id: unitInstrumentId,
        serial_raw: unitSerial.trim() || null
      },
      "Registrasi unit kanonik diproses"
    );
  }

  return (
    <div className="admin-section">
      {feedback ? (
        <p className={feedback.kind === "ok" ? "auth-success" : "auth-error"} role="status">
          {feedback.text}
        </p>
      ) : null}

      <div className="admin-grid">
        <section className="admin-panel" aria-labelledby="projects-heading">
          <h2 id="projects-heading">Proyek Terotorisasi ({projects.length})</h2>
          {projects.length === 0 ? (
            <p className="rbac-meta">Belum ada proyek dalam cakupan akses Anda.</p>
          ) : (
            <div className="admin-list">
              {projects.map((p) => {
                const cap = capByProject.get(p.id);
                return (
                  <article key={p.id} className="admin-item">
                    <div className="admin-item-header">
                      <strong>
                        {p.code} — {p.name}
                      </strong>
                      <span
                        className={`status-badge ${
                          p.status === "ACTIVE" ? "status-badge-approved" : "status-badge-disabled"
                        }`}
                      >
                        {p.status} · v{p.row_version}
                      </span>
                    </div>
                    <p className="rbac-meta">
                      Zona waktu: {p.timezone} · Kapasitas Inspector (T-14):{" "}
                      {cap ? `${cap.inspector_cap} (v${cap.row_version})` : "50"}
                    </p>
                  </article>
                );
              })}
            </div>
          )}

          <form className="rbac-form" onSubmit={handleCreateProject}>
            <div className="rbac-field">
              <label htmlFor="proj-code">Kode proyek (CMD-008)</label>
              <input
                id="proj-code"
                required
                value={projCode}
                onChange={(e) => setProjCode(e.target.value)}
                placeholder="PRJ-IFP-2026"
              />
            </div>
            <div className="rbac-field">
              <label htmlFor="proj-name">Nama proyek</label>
              <input
                id="proj-name"
                required
                value={projName}
                onChange={(e) => setProjName(e.target.value)}
                placeholder="Inspeksi IFP Wilayah Sintetik"
              />
            </div>
            <div className="rbac-field">
              <label htmlFor="proj-tz">Zona waktu IANA</label>
              <input
                id="proj-tz"
                required
                value={projTz}
                onChange={(e) => setProjTz(e.target.value)}
              />
            </div>
            <button className="auth-button admin-btn-sm" type="submit" disabled={busyKey !== null}>
              Buat Proyek
            </button>
          </form>
        </section>

        <section className="admin-panel" aria-labelledby="sessions-heading">
          <h2 id="sessions-heading">Sesi Inspeksi ({sessions.length})</h2>
          {sessions.length === 0 ? (
            <p className="rbac-meta">Belum ada sesi pada proyek yang dapat Anda akses.</p>
          ) : (
            <div className="admin-list">
              {sessions.map((s) => (
                <article key={s.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>{s.code}</strong>
                    <span className="status-badge">
                      {s.status} · v{s.row_version}
                    </span>
                  </div>
                  <p className="rbac-meta">
                    {new Date(s.starts_at).toLocaleString("id-ID")} —{" "}
                    {new Date(s.ends_at).toLocaleString("id-ID")}
                  </p>
                  <div className="admin-inline">
                    {s.status === "DRAFT" ? (
                      <button
                        type="button"
                        className="auth-button admin-btn-sm"
                        disabled={busyKey !== null}
                        onClick={() => handleSessionTransition(s, "ACTIVATE")}
                      >
                        Aktifkan
                      </button>
                    ) : null}
                    {s.status === "ACTIVE" ? (
                      <>
                        <button
                          type="button"
                          className="auth-button auth-button-secondary admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() => handleSessionTransition(s, "PAUSE")}
                        >
                          Jeda
                        </button>
                        <button
                          type="button"
                          className="auth-button auth-button-secondary admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() => handleSessionTransition(s, "REQUEST_CLOSE")}
                        >
                          Ajukan Tutup
                        </button>
                        <button
                          type="button"
                          className="auth-button admin-btn-sm admin-btn-danger"
                          disabled={busyKey !== null}
                          onClick={() => handleSessionTransition(s, "CLOSE")}
                        >
                          Tutup Final
                        </button>
                      </>
                    ) : null}
                    {s.status === "PAUSED" ? (
                      <button
                        type="button"
                        className="auth-button admin-btn-sm"
                        disabled={busyKey !== null}
                        onClick={() => handleSessionTransition(s, "RESUME")}
                      >
                        Lanjutkan
                      </button>
                    ) : null}
                  </div>
                </article>
              ))}
            </div>
          )}

          {projects.length > 0 ? (
            <form className="rbac-form" onSubmit={handleCreateSession}>
              <div className="rbac-field">
                <label htmlFor="sess-proj">Proyek (CMD-011)</label>
                <select
                  id="sess-proj"
                  required
                  value={sessProjectId}
                  onChange={(e) => setSessProjectId(e.target.value)}
                >
                  {projects.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.code} — {p.name}
                    </option>
                  ))}
                </select>
              </div>
              <div className="rbac-field">
                <label htmlFor="sess-code">Kode sesi</label>
                <input
                  id="sess-code"
                  required
                  value={sessCode}
                  onChange={(e) => setSessCode(e.target.value)}
                  placeholder="SESS-2026-01"
                />
              </div>
              <div className="rbac-field">
                <label htmlFor="sess-start">Mulai</label>
                <input
                  id="sess-start"
                  type="datetime-local"
                  required
                  value={sessStart}
                  onChange={(e) => setSessStart(e.target.value)}
                />
              </div>
              <div className="rbac-field">
                <label htmlFor="sess-end">Selesai</label>
                <input
                  id="sess-end"
                  type="datetime-local"
                  required
                  value={sessEnd}
                  onChange={(e) => setSessEnd(e.target.value)}
                />
              </div>
              <button className="auth-button admin-btn-sm" type="submit" disabled={busyKey !== null}>
                Buat Sesi (DRAFT)
              </button>
            </form>
          ) : null}
        </section>
      </div>

      <div className="admin-grid">
        <section className="admin-panel" aria-labelledby="instruments-heading">
          <h2 id="instruments-heading">Katalog Instrumen ({instruments.length})</h2>
          {instruments.length === 0 ? (
            <p className="rbac-meta">Belum ada instrumen terdaftar.</p>
          ) : (
            <div className="admin-list">
              {instruments.map((inst) => (
                <article key={inst.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>
                      {inst.code} — {inst.name}
                    </strong>
                    <span className="status-badge">
                      {inst.status} · {inst.instrument_type}
                    </span>
                  </div>
                </article>
              ))}
            </div>
          )}

          <form className="rbac-form" onSubmit={handleCreateInstrument}>
            <div className="rbac-field">
              <label htmlFor="inst-type">Tipe kanonik T-16 (CMD-018)</label>
              <input
                id="inst-type"
                required
                value={instType}
                onChange={(e) => setInstType(e.target.value)}
                placeholder="IFP_75"
              />
            </div>
            <div className="rbac-field">
              <label htmlFor="inst-code">Kode katalog</label>
              <input
                id="inst-code"
                required
                value={instCode}
                onChange={(e) => setInstCode(e.target.value)}
                placeholder="IFP-75-STD"
              />
            </div>
            <div className="rbac-field">
              <label htmlFor="inst-name">Nama instrumen</label>
              <input
                id="inst-name"
                required
                value={instName}
                onChange={(e) => setInstName(e.target.value)}
                placeholder="Interactive Flat Panel 75 Inch"
              />
            </div>
            <button className="auth-button admin-btn-sm" type="submit" disabled={busyKey !== null}>
              Buat Instrumen (DRAFT)
            </button>
          </form>
        </section>

        <section className="admin-panel" aria-labelledby="units-heading">
          <h2 id="units-heading">Registrasi Unit &amp; Konflik Serial (T-16)</h2>
          <form className="rbac-form" onSubmit={handleRegisterUnit}>
            <div className="rbac-field">
              <label htmlFor="unit-proj">Proyek (CMD-022)</label>
              <select
                id="unit-proj"
                required
                value={unitProjectId}
                onChange={(e) => setUnitProjectId(e.target.value)}
              >
                <option value="">-- Pilih proyek --</option>
                {projects.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.code}
                  </option>
                ))}
              </select>
            </div>
            <div className="rbac-field">
              <label htmlFor="unit-inst">Instrumen aktif</label>
              <select
                id="unit-inst"
                required
                value={unitInstrumentId}
                onChange={(e) => setUnitInstrumentId(e.target.value)}
              >
                <option value="">-- Pilih instrumen aktif --</option>
                {activeInstruments.map((inst) => (
                  <option key={inst.id} value={inst.id}>
                    {inst.code} ({inst.instrument_type})
                  </option>
                ))}
              </select>
            </div>
            <div className="rbac-field">
              <label htmlFor="unit-serial">Nomor seri (kosongkan jika tidak diketahui)</label>
              <input
                id="unit-serial"
                value={unitSerial}
                onChange={(e) => setUnitSerial(e.target.value)}
                placeholder="SN-IFP-2026-0001"
              />
            </div>
            <button className="auth-button admin-btn-sm" type="submit" disabled={busyKey !== null}>
              Daftarkan Unit Kanonik
            </button>
          </form>

          <h3>Konflik Identitas Terbuka ({conflicts.filter((c) => c.status === "OPEN").length})</h3>
          {conflicts.length === 0 ? (
            <p className="rbac-meta">Tidak ada konflik identitas serial pada proyek Anda.</p>
          ) : (
            <div className="admin-list">
              {conflicts.map((c) => (
                <article key={c.id} className="admin-item">
                  <div className="admin-item-header">
                    <strong>
                      {c.instrument_type} · {c.serial_normalized}
                    </strong>
                    <span className="status-badge status-badge-pending">{c.status}</span>
                  </div>
                </article>
              ))}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
