import { test } from "node:test";
import assert from "node:assert/strict";
import { routeMessage, runInbound, parseInbound, type ChannelDeps } from "./channels.js";

test("routeMessage classifies intents", () => {
  assert.equal(routeMessage("save Verve Coffee").action, "save");
  assert.equal(routeMessage("save: the matcha place on 5th").action, "save");
  assert.equal(routeMessage("order iced latte from raposa").action, "order");
  assert.equal(routeMessage("order: cold brew").action, "order");
  assert.equal(routeMessage("orders").action, "orders");
  assert.equal(routeMessage("my orders").action, "orders");
  assert.equal(routeMessage("hi there").action, "help");
});

test("save/order intents carry the payload", () => {
  const s = routeMessage("save Verve Coffee");
  assert.equal(s.action === "save" && s.text, "Verve Coffee");
  const o = routeMessage("order iced latte");
  assert.equal(o.action === "order" && o.intent, "iced latte");
});

test("parseInbound maps the Sendblue shape", () => {
  const m = parseInbound({ from_number: "+1555", content: "save X", is_outbound: false, message_handle: "h1" });
  assert.deepEqual(m, { fromNumber: "+1555", text: "save X", isOutbound: false, messageHandle: "h1", sendblueNumber: "" });
});

function deps(over: Partial<ChannelDeps> = {}): ChannelDeps {
  return {
    resolveUser: async () => ({ userId: "u1", buyer: { token: "t", buyerId: "b1" } }),
    saveMemory: async (_u, text) => ({ title: text }),
    placeOrder: async (_m, intent) => ({ id: "ord_1", status: "pending_payment", item: { name: intent, subtotalUsd: "6.50" }, merchantName: "Raposa Coffee" }),
    listOrders: async () => [{ id: "ord_1", status: "ready", item: { name: "Iced latte", subtotalUsd: "6.50" } }],
    defaultMerchantId: "raposa-coffee",
    seen: new Set(),
    ...over,
  };
}

test("runInbound: help for unknown text", async () => {
  const r = await runInbound(parseInbound({ from_number: "+1", content: "hello", message_handle: "a" }), deps());
  assert.match(r!, /SAV-E/);
});

test("runInbound: save writes memory", async () => {
  let saved = "";
  const r = await runInbound(
    parseInbound({ from_number: "+1", content: "save Verve Coffee", message_handle: "b" }),
    deps({ saveMemory: async (_u, t) => { saved = t; return { title: t }; } }),
  );
  assert.equal(saved, "Verve Coffee");
  assert.match(r!, /Saved/);
});

test("runInbound: order places via SLL-R", async () => {
  let ordered = "";
  const r = await runInbound(
    parseInbound({ from_number: "+1", content: "order iced latte", message_handle: "c" }),
    deps({ placeOrder: async (_m, intent) => { ordered = intent; return { id: "o", status: "pending_payment", item: { name: intent, subtotalUsd: "6.50" }, merchantName: "Raposa Coffee" }; } }),
  );
  assert.equal(ordered, "iced latte");
  assert.match(r!, /Ordered iced latte/);
});

test("runInbound: dedupe by message_handle", async () => {
  const seen = new Set<string>();
  const m = parseInbound({ from_number: "+1", content: "save X", message_handle: "dup" });
  assert.ok(await runInbound(m, deps({ seen })));
  assert.equal(await runInbound(m, deps({ seen })), null);
});

test("runInbound: unlinked number gets onboarding hint", async () => {
  const r = await runInbound(
    parseInbound({ from_number: "+1", content: "save X", message_handle: "e" }),
    deps({ resolveUser: async () => null }),
  );
  assert.match(r!, /isn't linked/);
});

test("runInbound: ignores outbound echo", async () => {
  const r = await runInbound({ fromNumber: "+1", text: "hi", isOutbound: true, messageHandle: "f", sendblueNumber: "" }, deps());
  assert.equal(r, null);
});
