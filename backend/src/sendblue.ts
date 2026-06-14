// Sendblue outbound + webhook auth for SAV-E's iMessage line. Minimal client —
// just what the channel needs: verify the inbound webhook, and send a reply.
// (Hard-won shape from the sllr-agent work: send-message requires from_number;
// the dashboard webhook secret arrives in the `sb-signing-secret` header.)

const API_BASE = "https://api.sendblue.co";

export type SendblueConfig = {
  apiKeyId: string;
  apiSecret: string;
  fromNumber: string;    // SAV-E's Sendblue number
  webhookSecret: string; // "" = no inbound verification (dev)
};

// null when Sendblue isn't configured — the channel still computes replies (and
// returns them in the HTTP response) so local testing works without creds.
export function sendblueConfig(): SendblueConfig | null {
  const apiKeyId = process.env.SENDBLUE_API_KEY_ID?.trim();
  const apiSecret = process.env.SENDBLUE_API_SECRET?.trim();
  if (!apiKeyId || !apiSecret) return null;
  return {
    apiKeyId,
    apiSecret,
    fromNumber: process.env.SENDBLUE_FROM_NUMBER?.trim() ?? "",
    webhookSecret: process.env.SENDBLUE_WEBHOOK_SECRET?.trim() ?? "",
  };
}

export function verifyWebhookSecret(
  cfg: SendblueConfig,
  headers: Record<string, string | string[] | undefined>,
  url: URL,
  body: Record<string, unknown>,
): boolean {
  if (!cfg.webhookSecret) return true; // not configured → open (dev only)
  const raw = headers["sb-signing-secret"];
  const header = Array.isArray(raw) ? raw[0] : raw;
  const query = url.searchParams.get("secret");
  const bodySecret = typeof body.secret === "string" ? body.secret : undefined;
  return header === cfg.webhookSecret || query === cfg.webhookSecret || bodySecret === cfg.webhookSecret;
}

// Send an iMessage/SMS. fromNumber: the line to send FROM (pass the inbound's
// sendblue_number; falls back to the configured SENDBLUE_FROM_NUMBER).
export async function sendMessage(
  cfg: SendblueConfig,
  number: string,
  content: string,
  fromNumber?: string,
): Promise<void> {
  const from = (fromNumber || cfg.fromNumber || "").trim();
  const body: Record<string, unknown> = { number, content };
  if (from) body.from_number = from;
  const res = await fetch(`${API_BASE}/api/send-message`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "sb-api-key-id": cfg.apiKeyId,
      "sb-api-secret-key": cfg.apiSecret,
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const j = (await res.json().catch(() => ({}))) as { error_message?: string };
    throw new Error(`Sendblue send failed (${res.status}): ${j.error_message ?? res.statusText}`);
  }
}
