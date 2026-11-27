import type { UserRoleRecord } from "@/lib/auth/account";

export const ROLE_ORDER = [
  "super_admin",
  "admin",
  "korlap",
  "reviewer",
  "inspector",
  "print_officer"
] as const;

export type CanonicalRoleCode = (typeof ROLE_ORDER)[number];

export type AppNavPath =
  | "/dashboard"
  | "/workspace"
  | "/inspections"
  | "/operations"
  | "/notifications"
  | "/admin/accounts";

export type RoleCapabilities = {
  canManageAccounts: boolean;
  canManageWorkspace: boolean;
  canInspectField: boolean;
  canReviewInspections: boolean;
  canManageAborts: boolean;
  canGenerateOrPrintDocs: boolean;
  canManageAttendance: boolean;
  canReadAudit: boolean;
};

export const ROLE_META: Record<
  CanonicalRoleCode,
  {
    label: string;
    shortLabel: string;
    description: string;
    primaryHref: AppNavPath;
    primaryCta: string;
  }
> = {
  super_admin: {
    label: "Super Admin",
    shortLabel: "Super Admin",
    description:
      "Kelola persetujuan akun, penetapan peran dan cakupan proyek, pengawasan operasional, serta riwayat audit.",
    primaryHref: "/admin/accounts",
    primaryCta: "Kelola Akun & Peran"
  },
  admin: {
    label: "Admin Proyek",
    shortLabel: "Admin Proyek",
    description:
      "Siapkan proyek, lokasi, tim, katalog instrumen, sesi inspeksi, penugasan, dan rencana target.",
    primaryHref: "/workspace",
    primaryCta: "Buka Workspace Operasional"
  },
  korlap: {
    label: "Koordinator Lapangan",
    shortLabel: "Korlap",
    description:
      "Pantau sesi berjalan, klaim unit tim, daftar hadir lokasi, serta persetujuan pembatalan unit terkemas.",
    primaryHref: "/workspace",
    primaryCta: "Pantau Sesi & Tim"
  },
  reviewer: {
    label: "Reviewer",
    shortLabel: "Reviewer",
    description:
      "Periksa hasil inspeksi yang masuk, verifikasi kelengkapan checklist dan bukti, lalu setujui atau kembalikan.",
    primaryHref: "/inspections",
    primaryCta: "Tinjau Antrean Inspeksi"
  },
  inspector: {
    label: "Inspector Lapangan",
    shortLabel: "Inspector",
    description:
      "Scan QR/Barcode atau OCR Nomor Seri, klaim unit, lengkapi checklist, dan unggah foto/video bukti.",
    primaryHref: "/inspections",
    primaryCta: "Mulai Scan & Inspeksi"
  },
  print_officer: {
    label: "Petugas Cetak",
    shortLabel: "Petugas Cetak",
    description:
      "Terbitkan PDF Berita Acara untuk unit yang disetujui, unduh dokumen versi aktif, dan catat cetak batch.",
    primaryHref: "/operations",
    primaryCta: "Kelola Dokumen & Cetak"
  }
};

const ROLE_ORDER_INDEX = new Map<string, number>(
  ROLE_ORDER.map((role, index) => [role, index])
);

function isRoleCurrentlyActive(role: UserRoleRecord, nowMs: number): boolean {
  if (role.status !== "ACTIVE") return false;
  if (role.valid_until) {
    const untilMs = Date.parse(role.valid_until);
    if (!Number.isNaN(untilMs) && untilMs <= nowMs) return false;
  }
  return true;
}

/**
 * Extracts deduplicated active canonical roles sorted by operational precedence.
 */
export function extractActiveRoles(
  roles: UserRoleRecord[],
  nowMs: number = Date.now()
): CanonicalRoleCode[] {
  const unique = new Set<CanonicalRoleCode>();
  for (const role of roles) {
    if (!isRoleCurrentlyActive(role, nowMs)) continue;
    if (ROLE_ORDER_INDEX.has(role.role_code)) {
      unique.add(role.role_code as CanonicalRoleCode);
    }
  }
  return Array.from(unique).sort(
    (a, b) => (ROLE_ORDER_INDEX.get(a) ?? 99) - (ROLE_ORDER_INDEX.get(b) ?? 99)
  );
}

/**
 * Computes navigation destinations relevant to the caller's active role set.
 */
export function getAllowedNavPaths(activeRoles: CanonicalRoleCode[]): AppNavPath[] {
  const allowed = new Set<AppNavPath>(["/dashboard", "/notifications"]);
  for (const role of activeRoles) {
    if (role === "super_admin") {
      allowed.add("/admin/accounts");
      allowed.add("/workspace");
      allowed.add("/inspections");
      allowed.add("/operations");
    } else if (role === "admin" || role === "korlap") {
      allowed.add("/workspace");
      allowed.add("/inspections");
      allowed.add("/operations");
    } else if (role === "reviewer") {
      allowed.add("/inspections");
      allowed.add("/operations");
    } else if (role === "inspector") {
      allowed.add("/inspections");
    } else if (role === "print_officer") {
      allowed.add("/inspections");
      allowed.add("/operations");
    }
  }
  const ordered: AppNavPath[] = [
    "/dashboard",
    "/workspace",
    "/inspections",
    "/operations",
    "/notifications",
    "/admin/accounts"
  ];
  return ordered.filter((p) => allowed.has(p));
}

/**
 * Derives UI action visibility capabilities from the user's active roles.
 * Server commands and PostgreSQL RLS remain the authoritative enforcement boundary.
 */
export function getRoleCapabilities(activeRoles: CanonicalRoleCode[]): RoleCapabilities {
  const has = (r: CanonicalRoleCode) => activeRoles.includes(r);
  const isSuperOrAdmin = has("super_admin") || has("admin");

  return {
    canManageAccounts: has("super_admin"),
    canManageWorkspace: isSuperOrAdmin || has("korlap"),
    canInspectField: has("inspector") || isSuperOrAdmin,
    canReviewInspections: has("reviewer") || isSuperOrAdmin,
    canManageAborts: has("korlap") || isSuperOrAdmin,
    canGenerateOrPrintDocs: has("print_officer") || isSuperOrAdmin,
    canManageAttendance: has("korlap") || has("reviewer") || isSuperOrAdmin,
    canReadAudit: has("super_admin") || has("admin")
  };
}
