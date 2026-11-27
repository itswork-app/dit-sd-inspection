import { describe, expect, it } from "vitest";
import {
  createMemoryQueueStore,
  enqueueDraftOperation,
  MAX_OFFLINE_QUEUE_ITEMS,
  rebaseConflictOperation,
  reconcileSyncResults,
  sha256Hex
} from "@/lib/offline/sync-queue";

describe("T-09 offline sync queue", () => {
  it("computes deterministic lowercase SHA-256 hex", async () => {
    const hash = await sha256Hex("dit-sd-inspection");
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
    const same = await sha256Hex(new TextEncoder().encode("dit-sd-inspection"));
    expect(same).toBe(hash);
  });

  it("enforces bounded queue cap of 50 active operations", async () => {
    const store = createMemoryQueueStore();
    for (let i = 0; i < MAX_OFFLINE_QUEUE_ITEMS; i += 1) {
      await enqueueDraftOperation(
        {
          inspection_id: "11111111-1111-4111-8111-111111111111",
          expected_row_version: "1",
          draft_checklist: { idx: i }
        },
        store
      );
    }

    await expect(
      enqueueDraftOperation(
        {
          inspection_id: "11111111-1111-4111-8111-111111111111",
          expected_row_version: "1",
          draft_checklist: { idx: 51 }
        },
        store
      )
    ).rejects.toThrow(/maksimum 50/);
  });

  it("[TC-OFF-003][TC-OFF-008] preserves CONFLICT operations without silently overwriting and supports explicit rebase", async () => {
    const store = createMemoryQueueStore();
    const op1 = await enqueueDraftOperation(
      {
        inspection_id: "11111111-1111-4111-8111-111111111111",
        expected_row_version: "1",
        draft_checklist: { panel_ok: true },
        notes: "Catatan lapangan offline"
      },
      store
    );
    const op2 = await enqueueDraftOperation(
      {
        inspection_id: "22222222-2222-4222-8222-222222222222",
        expected_row_version: "3",
        draft_checklist: { bracket_ok: true }
      },
      store
    );

    const afterSync = await reconcileSyncResults(
      [
        { operation_id: op1.operation_id, status: "VERSION_CONFLICT", message: "Row version mismatch" },
        { operation_id: op2.operation_id, status: "APPLIED" }
      ],
      store
    );

    const conflicted = afterSync.find((o) => o.operation_id === op1.operation_id);
    const applied = afterSync.find((o) => o.operation_id === op2.operation_id);
    expect(conflicted?.status).toBe("CONFLICT");
    expect(conflicted?.payload.notes).toBe("Catatan lapangan offline");
    expect(applied?.status).toBe("APPLIED");

    const rebased = await rebaseConflictOperation(op1.operation_id, "2", store);
    expect(rebased).not.toBeNull();
    expect(rebased?.operation_id).not.toBe(op1.operation_id);
    expect(rebased?.expected_row_version).toBe("2");
    expect(rebased?.status).toBe("PENDING");
    expect(rebased?.payload.notes).toBe("Catatan lapangan offline");

    const finalOps = await store.getAll();
    expect(finalOps.some((o) => o.operation_id === op1.operation_id)).toBe(false);
    expect(finalOps.some((o) => o.operation_id === rebased?.operation_id)).toBe(true);
  });
});
