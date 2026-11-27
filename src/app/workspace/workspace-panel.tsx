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

type LocationRow = { id: string; project_id: string; code: string; name: string; status: string };
type TeamRow = { id: string; project_id: string; code: string; name: string; status: string };
type InstrumentVersionRow = {
  id: string;
  instrument_id: string;
  version_number: number;
  status: string;
  draft_hash: string | null;
};
type AssignmentRow = {
  id: string;
  project_id: string;
  session_id: string;
  location_id: string;
  instrument_id: string;
  instrument_version_id: string;
  team_id: string;
  status: string;
};
type ApprovedUserRow = { id: string; display_name: string; account_status: string };
type UnitRow = {
  id: string;
  instrument_type: string;
  serial_raw: string | null;
  serial_normalized: string | null;
};
type UnitAssocRow = { id: string; unit_id: string; project_id: string; status: string };

type WorkspacePanelProps = {
  projects: ProjectRow[];
  sessions: SessionRow[];
  capacities: CapacityRow[];
  instruments: InstrumentRow[];
  conflicts: ConflictRow[];
  locations: LocationRow[];
  teams: TeamRow[];
  instrumentVersions: InstrumentVersionRow[];
  assignments: AssignmentRow[];
  approvedUsers: ApprovedUserRow[];
  units: UnitRow[];
  unitAssociations: UnitAssocRow[];
};

const PRESET_TEMPLATES = {
  IFP: {
    sections: [
      {
        code: "SEC_PHYS",
        label: "Pemeriksaan Fisik IFP",
        items: [
          { code: "ITEM_SCREEN", label: "Layar panel utuh tanpa retak", answer_type: "PASS_FAIL", required: true },
          { code: "ITEM_POWER", label: "Unit menyala dan fungsi sentuh normal", answer_type: "YES_NO", required: true }
        ]
      }
    ],
    spec_fields: [
      { code: "SPEC_SIZE", label: "Ukuran Layar", value_type: "TEXT", expected_value: "75", unit: "inch", required: true }
    ],
    evidence_slots: [
      { code: "EVD_FRONT", label: "Foto Depan & Nomor Seri", required: true, allowed_media_types: ["image/jpeg", "image/png", "image/webp"] }
    ]
  },
  SB: {
    sections: [
      {
        code: "SEC_FRAME",
        label: "Struktur & Roda Standing Bracket",
        items: [
          { code: "ITEM_BOLT", label: "Baut pengunci & rangka lengkap", answer_type: "PASS_FAIL", required: true },
          { code: "ITEM_LOCK", label: "Rem roda berfungsi baik", answer_type: "YES_NO", required: true }
        ]
      }
    ],
    spec_fields: [
      { code: "SPEC_MAT", label: "Material Rangka", value_type: "TEXT", expected_value: "Baja", unit: null, required: true }
    ],
    evidence_slots: [
      { code: "EVD_BRACKET", label: "Foto Unit Standing Bracket", required: true, allowed_media_types: ["image/jpeg", "image/png", "image/webp"] }
    ]
  }
} as const;

export function WorkspacePanel({
  projects,
  sessions,
  capacities,
  instruments,
  conflicts,
  locations,
  teams,
  instrumentVersions,
  assignments,
  approvedUsers,
  units,
  unitAssociations
}: WorkspacePanelProps) {
  const router = useRouter();
  const [busyKey, setBusyKey] = useState<string | null>(null);
  const [feedback, setFeedback] = useState<{ kind: "ok" | "err"; text: string } | null>(null);

  // Project & Capacity
  const [projCode, setProjCode] = useState("");
  const [projName, setProjName] = useState("");
  const [projTz, setProjTz] = useState("Asia/Jakarta");
  const [capInputs, setCapInputs] = useState<Record<string, string>>({});

  // Locations & Teams
  const [locProjectId, setLocProjectId] = useState(projects[0]?.id ?? "");
  const [locCode, setLocCode] = useState("");
  const [locName, setLocName] = useState("");
  const [teamProjectId, setTeamProjectId] = useState(projects[0]?.id ?? "");
  const [teamCode, setTeamCode] = useState("");
  const [teamName, setTeamName] = useState("");

  // Sessions
  const [sessProjectId, setSessProjectId] = useState(projects[0]?.id ?? "");
  const [sessCode, setSessCode] = useState("");
  const [sessStart, setSessStart] = useState("");
  const [sessEnd, setSessEnd] = useState("");

  // Instruments + Draft/Publish (CMD-018..020)
  const [instType, setInstType] = useState("");
  const [instCode, setInstCode] = useState("");
  const [instName, setInstName] = useState("");
  const [draftInstId, setDraftInstId] = useState(instruments[0]?.id ?? "");
  const [draftPreset, setDraftPreset] = useState<"IFP" | "SB">("IFP");

  // Assignment + Members (CMD-014)
  const [asgnProjectId, setAsgnProjectId] = useState(projects[0]?.id ?? "");
  const [asgnSessionId, setAsgnSessionId] = useState(sessions[0]?.id ?? "");
  const [asgnLocationId, setAsgnLocationId] = useState(locations[0]?.id ?? "");
  const [asgnTeamId, setAsgnTeamId] = useState(teams[0]?.id ?? "");
  const [asgnVersionId, setAsgnVersionId] = useState(
    instrumentVersions.find((v) => v.status === "PUBLISHED")?.id ?? ""
  );
  const [asgnUserId, setAsgnUserId] = useState(approvedUsers[0]?.id ?? "");
  const [asgnRole, setAsgnRole] = useState<"inspector" | "reviewer" | "korlap" | "print_officer">("inspector");

  // Target Plan (CMD-017)
  const [targetSessionId, setTargetSessionId] = useState(sessions[0]?.id ?? "");
  const [targetAssignId, setTargetAssignId] = useState(assignments[0]?.id ?? "");
  const [targetDate, setTargetDate] = useState("2026-11-27");
  const [targetQty, setTargetQty] = useState("10");

  // Register Unit & Claim (CMD-022 & CMD-026)
  const [unitProjectId, setUnitProjectId] = useState(projects[0]?.id ?? "");
  const [unitInstrumentId, setUnitInstrumentId] = useState(
    instruments.find((i) => i.status === "ACTIVE")?.id ?? ""
  );
  const [unitSerial, setUnitSerial] = useState("");
  const [claimAssignByAssoc, setClaimAssignByAssoc] = useState<Record<string, string>>({});

  const capByProject = new Map(capacities.map((c) => [c.project_id, c]));
  const activeInstruments = instruments.filter((i) => i.status === "ACTIVE");
  const publishedVersions = instrumentVersions.filter((v) => v.status === "PUBLISHED");
  const instrumentById = new Map(instruments.map((i) => [i.id, i]));
  const unitById = new Map(units.map((u) => [u.id, u]));

  async function callCommand(
    key: string,
    url: string,
    body: Record<string, unknown>,
    successMsg: string,
    onOk?: (payload: Record<string, unknown>) => void
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
        | (Record<string, unknown> & { status?: string; error?: { code?: string; message?: string } })
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
      if (payload && onOk) onOk(payload);
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

  async function handleCreateLocation(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await callCommand(
      "create-location",
      "/api/v1/projects/locations",
      { project_id: locProjectId, code: locCode.trim(), name: locName.trim() },
      `Lokasi ${locCode.trim().toUpperCase()} ditambahkan`
    );
  }

  async function handleCreateTeam(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await callCommand(
      "create-team",
      "/api/v1/projects/teams",
      { project_id: teamProjectId, code: teamCode.trim(), name: teamName.trim() },
      `Tim ${teamCode.trim().toUpperCase()} ditambahkan`
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

  async function handleSaveInstrumentDraft(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const preset = PRESET_TEMPLATES[draftPreset];
    await callCommand(
      "save-inst-draft",
      "/api/v1/instruments/draft",
      {
        instrument_id: draftInstId,
        schema_version: "1.0",
        sections: preset.sections,
        spec_fields: preset.spec_fields,
        evidence_slots: preset.evidence_slots
      },
      "Draft versi instrumen tersimpan (CMD-019)"
    );
  }

  async function handlePublishAssignment(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const ver = publishedVersions.find((v) => v.id === asgnVersionId);
    const sess = sessions.find((s) => s.id === asgnSessionId);
    if (!ver || !sess) {
      setFeedback({ kind: "err", text: "Pilih sesi aktif dan versi instrumen PUBLISHED." });
      return;
    }
    await callCommand(
      "publish-assignment",
      "/api/v1/assignments",
      {
        project_id: asgnProjectId,
        session_id: asgnSessionId,
        location_id: asgnLocationId,
        instrument_id: ver.instrument_id,
        instrument_version_id: ver.id,
        team_id: asgnTeamId,
        starts_at: new Date(sess.starts_at).toISOString(),
        ends_at: new Date(sess.ends_at).toISOString(),
        members: [{ user_id: asgnUserId, operational_role: asgnRole }]
      },
      "Penugasan operasional dipublikasikan (CMD-014)"
    );
  }

  async function handleCreateAndPublishTargetPlan(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const qty = Number.parseInt(targetQty, 10);
    if (!targetSessionId || !targetAssignId || Number.isNaN(qty) || qty < 1) {
      setFeedback({ kind: "err", text: "Pilih sesi, assignment, dan jumlah target minimal 1." });
      return;
    }
    await callCommand(
      "target-draft",
      "/api/v1/targets",
      {
        session_id: targetSessionId,
        action: "CREATE_DRAFT",
        allocations: [{ assignment_id: targetAssignId, target_date: targetDate, quantity: qty }]
      },
      "Draft target plan dibuat — lanjutkan publish di bawah jika diperlukan"
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
                const capVal = capInputs[p.id] ?? String(cap?.inspector_cap ?? 50);
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
                    {cap ? (
                      <div className="admin-inline">
                        <input
                          aria-label={`Kapasitas ${p.code}`}
                          className="inline-input"
                          type="number"
                          min={1}
                          max={100}
                          value={capVal}
                          onChange={(e) =>
                            setCapInputs((prev) => ({ ...prev, [p.id]: e.target.value }))
                          }
                        />
                        <button
                          type="button"
                          className="auth-button auth-button-secondary admin-btn-sm"
                          disabled={busyKey !== null}
                          onClick={() =>
                            callCommand(
                              `cap-${p.id}`,
                              "/api/v1/projects/capacity",
                              {
                                project_id: p.id,
                                inspector_cap: Number.parseInt(capVal, 10) || 50,
                                expected_row_version: cap.row_version,
                                reason: "Penyesuaian kapasitas T-14 melalui workspace"
                              },
                              `Kapasitas ${p.code} diperbarui (CMD-016)`
                            )
                          }
                        >
                          Simpan Kapasitas (CMD-016)
                        </button>
                      </div>
                    ) : null}
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

      {projects.length > 0 ? (
        <div className="admin-grid">
          <section className="admin-panel" aria-labelledby="loc-team-heading">
            <h2 id="loc-team-heading">
              Lokasi ({locations.length}) &amp; Tim ({teams.length})
            </h2>
            <form className="rbac-form" onSubmit={handleCreateLocation}>
              <div className="rbac-field">
                <label htmlFor="loc-proj">Proyek lokasi</label>
                <select id="loc-proj" value={locProjectId} onChange={(e) => setLocProjectId(e.target.value)}>
                  {projects.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.code}
                    </option>
                  ))}
                </select>
              </div>
              <div className="admin-inline">
                <input
                  aria-label="Kode lokasi"
                  className="inline-input"
                  required
                  value={locCode}
                  onChange={(e) => setLocCode(e.target.value)}
                  placeholder="LOC-01"
                />
                <input
                  aria-label="Nama lokasi"
                  className="inline-input"
                  required
                  value={locName}
                  onChange={(e) => setLocName(e.target.value)}
                  placeholder="SDN Contoh 01"
                />
                <button className="auth-button admin-btn-sm" type="submit" disabled={busyKey !== null}>
                  Tambah Lokasi
                </button>
              </div>
            </form>

            <form className="rbac-form" onSubmit={handleCreateTeam}>
              <div className="rbac-field">
                <label htmlFor="team-proj">Proyek tim</label>
                <select id="team-proj" value={teamProjectId} onChange={(e) => setTeamProjectId(e.target.value)}>
                  {projects.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.code}
                    </option>
                  ))}
                </select>
              </div>
              <div className="admin-inline">
                <input
                  aria-label="Kode tim"
                  className="inline-input"
                  required
                  value={teamCode}
                  onChange={(e) => setTeamCode(e.target.value)}
                  placeholder="TIM-01"
                />
                <input
                  aria-label="Nama tim"
                  className="inline-input"
                  required
                  value={teamName}
                  onChange={(e) => setTeamName(e.target.value)}
                  placeholder="Tim Inspeksi A"
                />
                <button className="auth-button admin-btn-sm" type="submit" disabled={busyKey !== null}>
                  Tambah Tim
                </button>
              </div>
            </form>
          </section>

          <section className="admin-panel" aria-labelledby="asgn-heading">
            <h2 id="asgn-heading">Penugasan Operasional ({assignments.length}) · CMD-014</h2>
            <form className="rbac-form" onSubmit={handlePublishAssignment}>
              <div className="admin-inline">
                <select aria-label="Proyek assignment" className="inline-input" value={asgnProjectId} onChange={(e) => setAsgnProjectId(e.target.value)}>
                  {projects.map((p) => (
                    <option key={p.id} value={p.id}>{p.code}</option>
                  ))}
                </select>
                <select aria-label="Sesi assignment" className="inline-input" value={asgnSessionId} onChange={(e) => setAsgnSessionId(e.target.value)}>
                  <option value="">-- Sesi --</option>
                  {sessions.filter((s) => s.project_id === asgnProjectId).map((s) => (
                    <option key={s.id} value={s.id}>{s.code} ({s.status})</option>
                  ))}
                </select>
                <select aria-label="Lokasi assignment" className="inline-input" value={asgnLocationId} onChange={(e) => setAsgnLocationId(e.target.value)}>
                  <option value="">-- Lokasi --</option>
                  {locations.filter((l) => l.project_id === asgnProjectId).map((l) => (
                    <option key={l.id} value={l.id}>{l.code}</option>
                  ))}
                </select>
                <select aria-label="Tim assignment" className="inline-input" value={asgnTeamId} onChange={(e) => setAsgnTeamId(e.target.value)}>
                  <option value="">-- Tim --</option>
                  {teams.filter((t) => t.project_id === asgnProjectId).map((t) => (
                    <option key={t.id} value={t.id}>{t.code}</option>
                  ))}
                </select>
              </div>
              <div className="admin-inline">
                <select aria-label="Versi instrumen PUBLISHED" className="inline-input" value={asgnVersionId} onChange={(e) => setAsgnVersionId(e.target.value)}>
                  <option value="">-- Versi Instrumen PUBLISHED --</option>
                  {publishedVersions.map((v) => {
                    const inst = instrumentById.get(v.instrument_id);
                    return (
                      <option key={v.id} value={v.id}>
                        {inst?.code ?? v.instrument_id.slice(0, 6)} v{v.version_number}
                      </option>
                    );
                  })}
                </select>
                <select aria-label="Pengguna anggota" className="inline-input" value={asgnUserId} onChange={(e) => setAsgnUserId(e.target.value)}>
                  <option value="">-- Akun Anggota --</option>
                  {approvedUsers.map((u) => (
                    <option key={u.id} value={u.id}>{u.display_name}</option>
                  ))}
                </select>
                <select
                  aria-label="Peran anggota"
                  className="inline-input"
                  value={asgnRole}
                  onChange={(e) => setAsgnRole(e.target.value as typeof asgnRole)}
                >
                  <option value="inspector">inspector</option>
                  <option value="reviewer">reviewer</option>
                  <option value="korlap">korlap</option>
                  <option value="print_officer">print_officer</option>
                </select>
                <button className="auth-button admin-btn-sm" type="submit" disabled={busyKey !== null}>
                  Publish Assignment
                </button>
              </div>
            </form>

            {assignments.length > 0 && sessions.length > 0 ? (
              <form className="rbac-form" onSubmit={handleCreateAndPublishTargetPlan}>
                <div className="admin-inline">
                  <select aria-label="Sesi target" className="inline-input" value={targetSessionId} onChange={(e) => setTargetSessionId(e.target.value)}>
                    {sessions.map((s) => (
                      <option key={s.id} value={s.id}>{s.code}</option>
                    ))}
                  </select>
                  <select aria-label="Assignment target" className="inline-input" value={targetAssignId} onChange={(e) => setTargetAssignId(e.target.value)}>
                    {assignments.map((a) => (
                      <option key={a.id} value={a.id}>Asgn {a.id.slice(0, 8)}…</option>
                    ))}
                  </select>
                  <input aria-label="Tanggal target" className="inline-input" type="date" value={targetDate} onChange={(e) => setTargetDate(e.target.value)} />
                  <input aria-label="Jumlah target" className="inline-input" type="number" min={1} max={10000} value={targetQty} onChange={(e) => setTargetQty(e.target.value)} />
                  <button className="auth-button auth-button-secondary admin-btn-sm" type="submit" disabled={busyKey !== null}>
                    Buat Target Plan (CMD-017)
                  </button>
                </div>
              </form>
            ) : null}
          </section>
        </div>
      ) : null}

      <div className="admin-grid">
        <section className="admin-panel" aria-labelledby="instruments-heading">
          <h2 id="instruments-heading">
            Katalog Instrumen ({instruments.length}) &amp; Versi ({instrumentVersions.length})
          </h2>
          {instruments.length === 0 ? (
            <p className="rbac-meta">Belum ada instrumen terdaftar.</p>
          ) : (
            <div className="admin-list">
              {instruments.map((inst) => {
                const vers = instrumentVersions.filter((v) => v.instrument_id === inst.id);
                return (
                  <article key={inst.id} className="admin-item">
                    <div className="admin-item-header">
                      <strong>
                        {inst.code} — {inst.name}
                      </strong>
                      <span className="status-badge">
                        {inst.status} · {inst.instrument_type}
                      </span>
                    </div>
                    {vers.map((v) => (
                      <div key={v.id} className="admin-inline">
                        <span className="rbac-meta">
                          Versi v{v.version_number} · <strong>{v.status}</strong>
                        </span>
                        {v.status === "DRAFT" && v.draft_hash ? (
                          <button
                            type="button"
                            className="auth-button admin-btn-sm"
                            disabled={busyKey !== null}
                            onClick={() =>
                              callCommand(
                                `pub-${v.id}`,
                                "/api/v1/instruments/publish",
                                {
                                  instrument_id: inst.id,
                                  version_id: v.id,
                                  expected_draft_hash: v.draft_hash,
                                  change_summary: "Publikasi versi instrumen dari workspace"
                                },
                                `Versi v${v.version_number} dipublikasikan (T-17 immutable)`
                              )
                            }
                          >
                            Publish v{v.version_number} (CMD-020)
                          </button>
                        ) : null}
                      </div>
                    ))}
                  </article>
                );
              })}
            </div>
          )}

          {instruments.length > 0 ? (
            <form className="rbac-form" onSubmit={handleSaveInstrumentDraft}>
              <div className="rbac-field">
                <label htmlFor="draft-inst">Simpan Draft Checklist/Spec/Slot (CMD-019)</label>
                <div className="admin-inline">
                  <select id="draft-inst" className="inline-input" value={draftInstId} onChange={(e) => setDraftInstId(e.target.value)}>
                    <option value="">-- Pilih Instrumen --</option>
                    {instruments.map((i) => (
                      <option key={i.id} value={i.id}>{i.code} ({i.status})</option>
                    ))}
                  </select>
                  <select aria-label="Preset template" className="inline-input" value={draftPreset} onChange={(e) => setDraftPreset(e.target.value as "IFP" | "SB")}>
                    <option value="IFP">Preset Standar IFP</option>
                    <option value="SB">Preset Standar Standing Bracket</option>
                  </select>
                  <button className="auth-button auth-button-secondary admin-btn-sm" type="submit" disabled={busyKey !== null || !draftInstId}>
                    Simpan Draft Versi
                  </button>
                </div>
              </div>
            </form>
          ) : null}

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
          <h2 id="units-heading">Registrasi Unit, Klaim &amp; Konflik Serial (T-16)</h2>
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

          <h3>Unit Terasosiasi ({unitAssociations.length}) — Siap Klaim (CMD-026)</h3>
          {unitAssociations.length === 0 ? (
            <p className="rbac-meta">Belum ada unit terasosiasi aktif.</p>
          ) : (
            <div className="admin-list">
              {unitAssociations.map((assoc) => {
                const u = unitById.get(assoc.unit_id);
                const projAssignments = assignments.filter((a) => a.project_id === assoc.project_id);
                const selectedAsgn = claimAssignByAssoc[assoc.id] ?? projAssignments[0]?.id ?? "";
                return (
                  <article key={assoc.id} className="admin-item">
                    <div className="admin-item-header">
                      <strong>
                        {u?.instrument_type ?? "UNIT"} · {u?.serial_normalized ?? u?.serial_raw ?? assoc.unit_id.slice(0, 8)}
                      </strong>
                      <span className="status-badge status-badge-approved">{assoc.status}</span>
                    </div>
                    {projAssignments.length > 0 ? (
                      <div className="admin-inline">
                        <select
                          aria-label={`Assignment untuk ${assoc.id}`}
                          className="inline-input"
                          value={selectedAsgn}
                          onChange={(e) =>
                            setClaimAssignByAssoc((prev) => ({ ...prev, [assoc.id]: e.target.value }))
                          }
                        >
                          {projAssignments.map((a) => (
                            <option key={a.id} value={a.id}>
                              Asgn {a.id.slice(0, 8)}… ({a.status})
                            </option>
                          ))}
                        </select>
                        <button
                          type="button"
                          className="auth-button admin-btn-sm"
                          disabled={busyKey !== null || !selectedAsgn}
                          onClick={() =>
                            callCommand(
                              `claim-${assoc.id}`,
                              "/api/v1/claims",
                              {
                                unit_id: assoc.unit_id,
                                association_id: assoc.id,
                                assignment_id: selectedAsgn,
                                claim_ttl_minutes: 120
                              },
                              "Unit diklaim (CMD-026) — membuka halaman inspeksi",
                              () => router.push("/inspections")
                            )
                          }
                        >
                          Klaim &amp; Mulai Inspeksi (CMD-026)
                        </button>
                      </div>
                    ) : (
                      <p className="rbac-meta">Buat &amp; publish Assignment proyek terlebih dahulu untuk mengklaim unit ini.</p>
                    )}
                  </article>
                );
              })}
            </div>
          )}

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
