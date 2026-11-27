export const MAX_OFFLINE_QUEUE_ITEMS = 50;
const IDB_NAME = "dit-sd-inspection-offline-v1";
const IDB_STORE = "sync_operations";
const DEVICE_STORAGE_KEY = "dit-sd-inspection-device-binding-v1";

export type OfflineOpStatus = "PENDING" | "APPLIED" | "CONFLICT" | "REJECTED";

export type OfflineSyncOperation = {
  operation_id: string;
  op_type: "SAVE_DRAFT";
  inspection_id: string;
  expected_row_version: string;
  payload: {
    draft_checklist: Record<string, unknown>;
    draft_specifications?: Record<string, unknown>;
    notes?: string | null;
  };
  queued_at: string;
  status: OfflineOpStatus;
  last_server_status?: string | null;
  last_error?: string | null;
};

export type StoredDeviceBinding = {
  device_id: string;
  label: string;
  fingerprint_hash: string;
  registered_at: string;
};

export type SyncServerOpResult = {
  operation_id?: string;
  status?: string;
  error?: string;
  message?: string;
};

export interface OfflineQueueStore {
  getAll(): Promise<OfflineSyncOperation[]>;
  put(op: OfflineSyncOperation): Promise<void>;
  delete(operationId: string): Promise<void>;
  clear(): Promise<void>;
}

export async function sha256Hex(input: ArrayBuffer | Uint8Array | string): Promise<string> {
  const bytes =
    typeof input === "string"
      ? new TextEncoder().encode(input)
      : input instanceof Uint8Array
        ? input
        : new Uint8Array(input);
  const copy = new Uint8Array(bytes.byteLength);
  copy.set(bytes);
  const digest = await crypto.subtle.digest("SHA-256", copy.buffer);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

export function createMemoryQueueStore(): OfflineQueueStore {
  const map = new Map<string, OfflineSyncOperation>();
  return {
    async getAll() {
      return Array.from(map.values()).sort((a, b) => a.queued_at.localeCompare(b.queued_at));
    },
    async put(op) {
      map.set(op.operation_id, structuredClone(op));
    },
    async delete(operationId) {
      map.delete(operationId);
    },
    async clear() {
      map.clear();
    }
  };
}

function openOfflineDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    if (typeof indexedDB === "undefined") {
      reject(new Error("IndexedDB unavailable"));
      return;
    }
    const request = indexedDB.open(IDB_NAME, 1);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(IDB_STORE)) {
        db.createObjectStore(IDB_STORE, { keyPath: "operation_id" });
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error ?? new Error("Failed to open IndexedDB"));
  });
}

export function createIndexedDbQueueStore(): OfflineQueueStore {
  return {
    async getAll() {
      const db = await openOfflineDb();
      return new Promise((resolve, reject) => {
        const tx = db.transaction(IDB_STORE, "readonly");
        const req = tx.objectStore(IDB_STORE).getAll();
        req.onsuccess = () => {
          const items = (req.result as OfflineSyncOperation[]) ?? [];
          items.sort((a, b) => a.queued_at.localeCompare(b.queued_at));
          resolve(items);
        };
        req.onerror = () => reject(req.error ?? new Error("Failed to read offline queue"));
        tx.oncomplete = () => db.close();
      });
    },
    async put(op) {
      const db = await openOfflineDb();
      return new Promise((resolve, reject) => {
        const tx = db.transaction(IDB_STORE, "readwrite");
        tx.objectStore(IDB_STORE).put(op);
        tx.oncomplete = () => {
          db.close();
          resolve();
        };
        tx.onerror = () => {
          db.close();
          reject(tx.error ?? new Error("Failed to persist offline operation"));
        };
      });
    },
    async delete(operationId) {
      const db = await openOfflineDb();
      return new Promise((resolve, reject) => {
        const tx = db.transaction(IDB_STORE, "readwrite");
        tx.objectStore(IDB_STORE).delete(operationId);
        tx.oncomplete = () => {
          db.close();
          resolve();
        };
        tx.onerror = () => {
          db.close();
          reject(tx.error ?? new Error("Failed to delete offline operation"));
        };
      });
    },
    async clear() {
      const db = await openOfflineDb();
      return new Promise((resolve, reject) => {
        const tx = db.transaction(IDB_STORE, "readwrite");
        tx.objectStore(IDB_STORE).clear();
        tx.oncomplete = () => {
          db.close();
          resolve();
        };
        tx.onerror = () => {
          db.close();
          reject(tx.error ?? new Error("Failed to clear offline queue"));
        };
      });
    }
  };
}

let defaultStoreSingleton: OfflineQueueStore | null = null;
export function getDefaultOfflineQueueStore(): OfflineQueueStore {
  if (!defaultStoreSingleton) {
    defaultStoreSingleton =
      typeof indexedDB !== "undefined" ? createIndexedDbQueueStore() : createMemoryQueueStore();
  }
  return defaultStoreSingleton;
}

export async function enqueueDraftOperation(
  input: {
    inspection_id: string;
    expected_row_version: string;
    draft_checklist: Record<string, unknown>;
    draft_specifications?: Record<string, unknown>;
    notes?: string | null;
  },
  store: OfflineQueueStore = getDefaultOfflineQueueStore()
): Promise<OfflineSyncOperation> {
  const existing = await store.getAll();
  const activeCount = existing.filter((op) => op.status !== "APPLIED").length;
  if (activeCount >= MAX_OFFLINE_QUEUE_ITEMS) {
    throw new Error(`Antrean offline penuh (maksimum ${MAX_OFFLINE_QUEUE_ITEMS} operasi).`);
  }

  const op: OfflineSyncOperation = {
    operation_id: `op-${crypto.randomUUID()}`,
    op_type: "SAVE_DRAFT",
    inspection_id: input.inspection_id,
    expected_row_version: input.expected_row_version,
    payload: {
      draft_checklist: input.draft_checklist,
      ...(input.draft_specifications ? { draft_specifications: input.draft_specifications } : {}),
      ...(input.notes !== undefined ? { notes: input.notes } : {})
    },
    queued_at: new Date().toISOString(),
    status: "PENDING",
    last_server_status: null,
    last_error: null
  };

  await store.put(op);
  return op;
}

/**
 * Conflict-aware reconciliation (T-09):
 * - APPLIED / IDEMPOTENT_REPLAY -> marked APPLIED
 * - CONFLICT / VERSION_CONFLICT / STATE_CONFLICT -> marked CONFLICT (never silently overwritten!)
 * - Any other failure -> marked REJECTED with server code
 */
export async function reconcileSyncResults(
  results: SyncServerOpResult[],
  store: OfflineQueueStore = getDefaultOfflineQueueStore()
): Promise<OfflineSyncOperation[]> {
  const existing = await store.getAll();
  const byId = new Map(existing.map((op) => [op.operation_id, op]));

  for (const res of results) {
    if (!res.operation_id) continue;
    const current = byId.get(res.operation_id);
    if (!current) continue;

    const statusUpper = String(res.status ?? "").toUpperCase();
    let nextStatus: OfflineOpStatus = "REJECTED";
    if (statusUpper === "APPLIED" || statusUpper === "DRAFT_SAVED" || statusUpper === "IDEMPOTENT_REPLAY") {
      nextStatus = "APPLIED";
    } else if (statusUpper.includes("CONFLICT") || statusUpper === "STALE_VERSION") {
      nextStatus = "CONFLICT";
    }

    const updated: OfflineSyncOperation = {
      ...current,
      status: nextStatus,
      last_server_status: statusUpper || "UNKNOWN",
      last_error:
        nextStatus === "APPLIED"
          ? null
          : res.message ?? res.error ?? `Server mengembalikan status ${statusUpper || "UNKNOWN"}`
    };
    await store.put(updated);
    byId.set(updated.operation_id, updated);
  }

  return store.getAll();
}

/**
 * Explicit user rebase of a CONFLICT operation against a freshly observed server row_version.
 * Creates a new operation_id and removes the old conflicted entry so idempotency history stays intact.
 */
export async function rebaseConflictOperation(
  oldOperationId: string,
  nextExpectedRowVersion: string,
  store: OfflineQueueStore = getDefaultOfflineQueueStore()
): Promise<OfflineSyncOperation | null> {
  const all = await store.getAll();
  const existing = all.find((op) => op.operation_id === oldOperationId);
  if (!existing) return null;

  const rebased: OfflineSyncOperation = {
    ...existing,
    operation_id: `op-${crypto.randomUUID()}`,
    expected_row_version: nextExpectedRowVersion,
    queued_at: new Date().toISOString(),
    status: "PENDING",
    last_server_status: null,
    last_error: null
  };

  await store.put(rebased);
  await store.delete(oldOperationId);
  return rebased;
}

export function loadStoredDeviceBinding(): StoredDeviceBinding | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(DEVICE_STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as Partial<StoredDeviceBinding>;
    if (
      typeof parsed.device_id === "string" &&
      typeof parsed.label === "string" &&
      typeof parsed.fingerprint_hash === "string" &&
      typeof parsed.registered_at === "string"
    ) {
      return parsed as StoredDeviceBinding;
    }
    return null;
  } catch {
    return null;
  }
}

export function saveStoredDeviceBinding(binding: StoredDeviceBinding): void {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(DEVICE_STORAGE_KEY, JSON.stringify(binding));
}

export async function purgeOfflineLocalState(
  store: OfflineQueueStore = getDefaultOfflineQueueStore()
): Promise<void> {
  await store.clear();
  if (typeof window !== "undefined") {
    window.localStorage.removeItem(DEVICE_STORAGE_KEY);
  }
}
