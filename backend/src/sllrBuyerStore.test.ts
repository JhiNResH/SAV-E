import assert from "node:assert/strict";
import test from "node:test";
import { SllrBuyerStore } from "./sllrBuyerStore.js";
import type { Queryable } from "./sendbluePlaceStore.js";

class FakeQuery implements Queryable {
  public statements: { sql: string; values?: unknown[] }[] = [];
  constructor(private readonly responder: (sql: string, values?: unknown[]) => Record<string, unknown>[]) {}
  async query(sql: string, values?: unknown[]): Promise<{ rows: Record<string, unknown>[] }> {
    this.statements.push({ sql, values });
    return { rows: this.responder(sql, values) };
  }
}

test("get returns null when the number has no buyer", async () => {
  const store = new SllrBuyerStore(new FakeQuery(() => []));
  assert.equal(await store.get("+1555"), null);
});

test("get maps a row to a buyer", async () => {
  const store = new SllrBuyerStore(new FakeQuery(() => [{ token: "sllrb_x", buyer_id: "buyer_y" }]));
  assert.deepEqual(await store.get("+1555"), { token: "sllrb_x", buyerId: "buyer_y" });
});

test("set upserts by number (on conflict do update)", async () => {
  const db = new FakeQuery(() => []);
  const store = new SllrBuyerStore(db);
  await store.set("+1555", { token: "sllrb_x", buyerId: "buyer_y" });
  const upsert = db.statements.find((s) => s.sql.includes("insert into sendblue_sllr_buyers"));
  assert.ok(upsert, "must insert");
  assert.ok(upsert!.sql.includes("on conflict (number) do update"), "must upsert on number");
  assert.deepEqual(upsert!.values, ["+1555", "sllrb_x", "buyer_y"]);
});

test("all maps every row to a number+buyer", async () => {
  const store = new SllrBuyerStore(new FakeQuery(() => [
    { number: "+1555", token: "t1", buyer_id: "b1" },
    { number: "+1666", token: "t2", buyer_id: "b2" },
  ]));
  assert.deepEqual(await store.all(), [
    { number: "+1555", buyer: { token: "t1", buyerId: "b1" } },
    { number: "+1666", buyer: { token: "t2", buyerId: "b2" } },
  ]);
});

test("markNotified: first time → true (RETURNING a row), repeat → false (conflict, no row)", async () => {
  // Simulate the unique-PK dedup: the run id is returned only the first time.
  const seen = new Set<string>();
  const store = new SllrBuyerStore(new FakeQuery((sql, values) => {
    if (!sql.includes("insert into sendblue_sllr_notified_runs")) return [];
    const runId = String((values ?? [])[0]);
    if (seen.has(runId)) return []; // on conflict do nothing → no returned row
    seen.add(runId);
    return [{ run_id: runId }];
  }));
  assert.equal(await store.markNotified("run_1"), true, "first sighting notifies");
  assert.equal(await store.markNotified("run_1"), false, "duplicate is suppressed");
  assert.equal(await store.markNotified("run_2"), true, "a different run notifies");
});
