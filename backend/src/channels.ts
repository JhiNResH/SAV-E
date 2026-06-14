// SAV-E messaging channel — phone (iMessage/SMS) → SAV-E.
//
// A consumer texts SAV-E's number; this turns the message into an action:
//   "save <place>"  → write to SAV-E memory (a capture)
//   "order <thing>" → place an order via SLL-R (the commerce rail)
//   "orders"        → list the buyer's SLL-R orders
// Pure routing + orchestration here; all IO (DB, SLL-R, user resolution) is
// injected so this is unit-testable with no network/DB. server.ts wires the real
// deps; #4 (user_channels phone→user) and #7 (Sendblue outbound + number) layer on.

import type { SllrBuyer, SllrOrder } from "./sllrCommerce.js";

export type InboundMessage = {
  fromNumber: string;
  text: string;
  isOutbound: boolean;
  messageHandle: string;
  sendblueNumber: string; // the SAV-E line it arrived on — reply FROM this
};

// Sendblue inbound webhook shape (verified live in the sllr-agent work).
export function parseInbound(body: Record<string, unknown>): InboundMessage {
  return {
    fromNumber: typeof body.from_number === "string" ? body.from_number : "",
    text: typeof body.content === "string" ? body.content : "",
    isOutbound: body.is_outbound === true,
    messageHandle: typeof body.message_handle === "string" ? body.message_handle : "",
    sendblueNumber: typeof body.sendblue_number === "string" && body.sendblue_number
      ? body.sendblue_number
      : (typeof body.to_number === "string" ? body.to_number : ""),
  };
}

export type Intent =
  | { action: "save"; text: string }
  | { action: "order"; intent: string }
  | { action: "orders" }
  | { action: "help" };

// Deterministic intent routing (v0). An LLM brain can replace this later; keeping
// it pure means the plumbing is testable now and the parse is swappable.
export function routeMessage(raw: string): Intent {
  const text = raw.trim();
  const lower = text.toLowerCase();
  if (/^my orders\b|^orders\b/.test(lower)) return { action: "orders" };
  const save = text.match(/^save[:\s]+(.+)/is);
  if (save) return { action: "save", text: save[1].trim() };
  const order = text.match(/^order[:\s]+(.+)/is);
  if (order) return { action: "order", intent: order[1].trim() };
  return { action: "help" };
}

export type ChannelDeps = {
  // phone → SAV-E user + their SLL-R buyer session. null = number not linked yet.
  resolveUser: (fromNumber: string) => Promise<{ userId: string; buyer: SllrBuyer } | null>;
  // write a memory (capture) for the user; returns a short title for the reply.
  saveMemory: (userId: string, text: string) => Promise<{ title: string }>;
  // SLL-R calls (injected for testability).
  placeOrder: (merchantId: string, intent: string, buyer: SllrBuyer) => Promise<SllrOrder>;
  listOrders: (buyer: SllrBuyer) => Promise<SllrOrder[]>;
  defaultMerchantId: string;
  seen: Set<string>; // message_handle dedupe
};

const HELP =
  "Hey, I'm SAV-E 👋 Text me:\n• save <place> — I'll remember it\n• order <thing> — I'll order it for you\n• orders — your recent orders";

// Handle one inbound message; returns the reply text (server sends it), or null
// to stay silent (outbound echo / empty / duplicate).
export async function runInbound(msg: InboundMessage, deps: ChannelDeps): Promise<string | null> {
  if (msg.isOutbound) return null;
  const text = msg.text.trim();
  if (!text) return null;
  if (msg.messageHandle) {
    if (deps.seen.has(msg.messageHandle)) return null;
    deps.seen.add(msg.messageHandle);
  }

  const intent = routeMessage(text);
  if (intent.action === "help") return HELP;

  const who = await deps.resolveUser(msg.fromNumber);
  if (!who) {
    return "Your number isn't linked to a SAV-E account yet — onboarding is coming. Once linked, text 'save <place>' or 'order <thing>'.";
  }

  switch (intent.action) {
    case "save": {
      const { title } = await deps.saveMemory(who.userId, intent.text);
      return `📌 Saved "${title}" to your memory — I'll help you plan or visit it later.`;
    }
    case "order": {
      const order = await deps.placeOrder(deps.defaultMerchantId, intent.intent, who.buyer);
      return `✅ Ordered ${order.item.name} ($${order.item.subtotalUsd}) at ${order.merchantName ?? "the merchant"}. I'll text you when it's confirmed.`;
    }
    case "orders": {
      const orders = await deps.listOrders(who.buyer);
      return orders.length
        ? "Your recent orders:\n" + orders.slice(0, 5).map((o) => `• ${o.item.name} — ${o.status}`).join("\n")
        : "No orders yet. Text 'order <thing>' to start.";
    }
  }
}
