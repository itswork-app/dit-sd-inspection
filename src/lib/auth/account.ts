import "server-only";

import type { createClient } from "@/lib/supabase/server";

type SupabaseServerClient = Awaited<ReturnType<typeof createClient>>;

export type AccountStatus = "PENDING" | "APPROVED" | "REJECTED" | "SUSPENDED" | "DISABLED";

export type AppUserRecord = {
  id: string;
  display_name: string;
  account_status: AccountStatus;
  row_version: string;
  created_at: string;
  updated_at: string;
};

export type AccountRequestRecord = {
  id: string;
  user_id: string;
  status: "PENDING" | "APPROVED" | "REJECTED";
  requested_display_name: string;
  request_note: string | null;
  requested_at: string;
  decided_at: string | null;
};

export type AccountDecisionRecord = {
  id: string;
  request_id: string | null;
  target_user_id: string;
  actor_user_id: string;
  decision: "APPROVE" | "REJECT" | "SUSPEND" | "DISABLE" | "REINSTATE";
  rejection_category: string | null;
  reason: string;
  decided_at: string;
};

export type RoleCatalogRecord = {
  id: string;
  code: string;
  name: string;
  scope_class: "GLOBAL" | "PROJECT";
  status: "ACTIVE" | "INACTIVE";
};

export type UserRoleRecord = {
  id: string;
  user_id: string;
  role_id: string;
  role_code: string;
  role_name: string;
  scope_class: string;
  project_id: string | null;
  status: "ACTIVE" | "REVOKED";
  valid_from: string;
  valid_until: string | null;
  reason: string;
  row_version: string;
  granted_at: string;
  revoked_at: string | null;
};

export type UserScopeGrantRecord = {
  id: string;
  user_id: string;
  scope_type: string;
  scope_id: string;
  status: "ACTIVE" | "REVOKED";
  valid_from: string;
  valid_until: string | null;
  reason: string;
  row_version: string;
  granted_at: string;
  revoked_at: string | null;
};

export type SelfAccountSnapshotResult =
  | {
      status: "ok";
      user: AppUserRecord | null;
      requests: AccountRequestRecord[];
      decisions: AccountDecisionRecord[];
      roles: UserRoleRecord[];
      scopes: UserScopeGrantRecord[];
      isActiveSuperAdmin: boolean;
      canManageIdentity: boolean;
    }
  | { status: "schema_unavailable" }
  | { status: "error" };

export type AdminAccountsSnapshotResult =
  | {
      status: "ok";
      actorUserId: string;
      isActiveSuperAdmin: boolean;
      users: AppUserRecord[];
      requests: AccountRequestRecord[];
      decisions: AccountDecisionRecord[];
      roleCatalog: RoleCatalogRecord[];
      userRoles: UserRoleRecord[];
      userScopes: UserScopeGrantRecord[];
    }
  | { status: "forbidden" }
  | { status: "schema_unavailable" }
  | { status: "error" };

function isMissingSchemaError(error: { code?: string | null; message?: string | null } | null): boolean {
  if (!error) return false;
  return error.code === "42P01" || error.code === "PGRST205";
}

function normalizeRowVersion(value: unknown): string {
  if (typeof value === "string") return value;
  if (typeof value === "number" && Number.isSafeInteger(value)) return String(value);
  return "1";
}

function isRoleActiveNow(role: Pick<UserRoleRecord, "status" | "valid_from" | "valid_until">): boolean {
  if (role.status !== "ACTIVE") return false;
  const now = Date.now();
  const validFrom = Date.parse(role.valid_from);
  if (Number.isNaN(validFrom) || validFrom > now) return false;
  if (role.valid_until) {
    const validUntil = Date.parse(role.valid_until);
    if (Number.isNaN(validUntil) || validUntil <= now) return false;
  }
  return true;
}

function mapUserRow(row: Record<string, unknown>): AppUserRecord {
  return {
    id: String(row.id),
    display_name: String(row.display_name),
    account_status: String(row.account_status) as AccountStatus,
    row_version: normalizeRowVersion(row.row_version),
    created_at: String(row.created_at),
    updated_at: String(row.updated_at)
  };
}

function mapUserRoleRow(row: Record<string, unknown>): UserRoleRecord {
  const joinedRole = Array.isArray(row.roles)
    ? (row.roles[0] as Record<string, unknown> | undefined)
    : (row.roles as Record<string, unknown> | null | undefined);

  return {
    id: String(row.id),
    user_id: String(row.user_id),
    role_id: String(row.role_id),
    role_code: String(joinedRole?.code ?? ""),
    role_name: String(joinedRole?.name ?? ""),
    scope_class: String(joinedRole?.scope_class ?? ""),
    project_id: row.project_id ? String(row.project_id) : null,
    status: String(row.status) as "ACTIVE" | "REVOKED",
    valid_from: String(row.valid_from),
    valid_until: row.valid_until ? String(row.valid_until) : null,
    reason: String(row.reason ?? ""),
    row_version: normalizeRowVersion(row.row_version),
    granted_at: String(row.created_at),
    revoked_at: row.revoked_at ? String(row.revoked_at) : null
  };
}

function mapScopeRow(row: Record<string, unknown>): UserScopeGrantRecord {
  return {
    id: String(row.id),
    user_id: String(row.user_id),
    scope_type: String(row.scope_type),
    scope_id: String(row.scope_id),
    status: String(row.status) as "ACTIVE" | "REVOKED",
    valid_from: String(row.valid_from),
    valid_until: row.valid_until ? String(row.valid_until) : null,
    reason: String(row.reason ?? ""),
    row_version: normalizeRowVersion(row.row_version),
    granted_at: String(row.created_at),
    revoked_at: row.revoked_at ? String(row.revoked_at) : null
  };
}

export async function loadSelfAccountSnapshot(
  supabase: SupabaseServerClient,
  authUserId: string
): Promise<SelfAccountSnapshotResult> {
  const { data: userRow, error: userErr } = await supabase
    .from("app_users")
    .select("id, display_name, account_status, row_version, created_at, updated_at")
    .eq("auth_user_id", authUserId)
    .maybeSingle();

  if (userErr) {
    return isMissingSchemaError(userErr) ? { status: "schema_unavailable" } : { status: "error" };
  }

  if (!userRow) {
    return {
      status: "ok",
      user: null,
      requests: [],
      decisions: [],
      roles: [],
      scopes: [],
      isActiveSuperAdmin: false,
      canManageIdentity: false
    };
  }

  const user = mapUserRow(userRow as Record<string, unknown>);

  const [requestsRes, decisionsRes, rolesRes, scopesRes] = await Promise.all([
    supabase
      .from("account_requests")
      .select("id, user_id, status, requested_display_name, request_note, requested_at, decided_at")
      .eq("user_id", user.id)
      .order("requested_at", { ascending: false })
      .limit(20),
    supabase
      .from("account_decisions")
      .select("id, request_id, target_user_id, actor_user_id, decision, rejection_category, reason, decided_at")
      .eq("target_user_id", user.id)
      .order("decided_at", { ascending: false })
      .limit(20),
    supabase
      .from("user_roles")
      .select("id, user_id, role_id, project_id, status, valid_from, valid_until, reason, row_version, created_at, revoked_at, roles(code, name, scope_class)")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(50),
    supabase
      .from("user_scope_grants")
      .select("id, user_id, scope_type, scope_id, status, valid_from, valid_until, reason, row_version, created_at, revoked_at")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(50)
  ]);

  if (requestsRes.error || decisionsRes.error || rolesRes.error || scopesRes.error) {
    if (
      isMissingSchemaError(requestsRes.error) ||
      isMissingSchemaError(decisionsRes.error) ||
      isMissingSchemaError(rolesRes.error) ||
      isMissingSchemaError(scopesRes.error)
    ) {
      return { status: "schema_unavailable" };
    }
    return { status: "error" };
  }

  const roles = (rolesRes.data ?? []).map((row) => mapUserRoleRow(row as Record<string, unknown>));
  const scopes = (scopesRes.data ?? []).map((row) => mapScopeRow(row as Record<string, unknown>));
  const isActiveSuperAdmin =
    user.account_status === "APPROVED" &&
    roles.some((role) => role.role_code === "super_admin" && role.project_id === null && isRoleActiveNow(role));

  return {
    status: "ok",
    user,
    requests: (requestsRes.data ?? []) as AccountRequestRecord[],
    decisions: (decisionsRes.data ?? []) as AccountDecisionRecord[],
    roles,
    scopes,
    isActiveSuperAdmin,
    canManageIdentity: isActiveSuperAdmin
  };
}

export async function loadAdminAccountsSnapshot(
  supabase: SupabaseServerClient,
  authUserId: string
): Promise<AdminAccountsSnapshotResult> {
  const selfSnapshot = await loadSelfAccountSnapshot(supabase, authUserId);
  if (selfSnapshot.status !== "ok") return selfSnapshot;

  if (!selfSnapshot.user || !selfSnapshot.canManageIdentity) {
    return { status: "forbidden" };
  }

  const [usersRes, requestsRes, decisionsRes, rolesCatalogRes, userRolesRes, userScopesRes] = await Promise.all([
    supabase
      .from("app_users")
      .select("id, display_name, account_status, row_version, created_at, updated_at")
      .order("created_at", { ascending: false })
      .limit(200),
    supabase
      .from("account_requests")
      .select("id, user_id, status, requested_display_name, request_note, requested_at, decided_at")
      .order("requested_at", { ascending: false })
      .limit(200),
    supabase
      .from("account_decisions")
      .select("id, request_id, target_user_id, actor_user_id, decision, rejection_category, reason, decided_at")
      .order("decided_at", { ascending: false })
      .limit(200),
    supabase
      .from("roles")
      .select("id, code, name, scope_class, status")
      .eq("status", "ACTIVE")
      .order("code", { ascending: true }),
    supabase
      .from("user_roles")
      .select("id, user_id, role_id, project_id, status, valid_from, valid_until, reason, row_version, created_at, revoked_at, roles(code, name, scope_class)")
      .order("created_at", { ascending: false })
      .limit(300),
    supabase
      .from("user_scope_grants")
      .select("id, user_id, scope_type, scope_id, status, valid_from, valid_until, reason, row_version, created_at, revoked_at")
      .order("created_at", { ascending: false })
      .limit(300)
  ]);

  if (
    usersRes.error ||
    requestsRes.error ||
    decisionsRes.error ||
    rolesCatalogRes.error ||
    userRolesRes.error ||
    userScopesRes.error
  ) {
    return { status: "error" };
  }

  return {
    status: "ok",
    actorUserId: selfSnapshot.user.id,
    isActiveSuperAdmin: selfSnapshot.isActiveSuperAdmin,
    users: (usersRes.data ?? []).map((row) => mapUserRow(row as Record<string, unknown>)),
    requests: (requestsRes.data ?? []) as AccountRequestRecord[],
    decisions: (decisionsRes.data ?? []) as AccountDecisionRecord[],
    roleCatalog: (rolesCatalogRes.data ?? []) as RoleCatalogRecord[],
    userRoles: (userRolesRes.data ?? []).map((row) => mapUserRoleRow(row as Record<string, unknown>)),
    userScopes: (userScopesRes.data ?? []).map((row) => mapScopeRow(row as Record<string, unknown>))
  };
}
