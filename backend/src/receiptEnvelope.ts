import { createHash, randomUUID } from "node:crypto";

export type JsonObject = Record<string, unknown>;

export const receiptProduct = "save";
export const recommendationAnalysisReceiptType = "recommendation_analysis";
export const recommendationAnalysisCapability = "place_claim_recommendation";

export const evaluatorVerdicts = ["pass", "partial", "fail", "manual_review"] as const;
export const settlementStates = ["not_settled", "pending", "settled", "refunded", "manual_review"] as const;

export type EvaluatorVerdict = typeof evaluatorVerdicts[number];
export type SettlementState = typeof settlementStates[number];

export interface RecommendationAnalysisPublicSummary extends JsonObject {
  summary: string;
  capability: typeof recommendationAnalysisCapability;
  result_count: number;
  saved_result_count: number;
  public_result_count: number;
  proof_level_min: string | null;
  public_web_used: boolean;
}

export interface AgentShackReceiptEnvelope extends JsonObject {
  product: typeof receiptProduct;
  receipt_type: typeof recommendationAnalysisReceiptType;
  user_id: string;
  agent_id: string;
  capability: typeof recommendationAnalysisCapability;
  input_hash: string;
  output_hash: string;
  private_payload_ref: string;
  public_summary: RecommendationAnalysisPublicSummary;
  preference_signals: string[];
  evaluator_verdict: EvaluatorVerdict;
  settlement_state: SettlementState;
  created_at: string;
}

export interface RecommendationAnalysisReceiptDraft extends JsonObject {
  id: string;
  user_id: string;
  product: typeof receiptProduct;
  receipt_type: typeof recommendationAnalysisReceiptType;
  agent_id: string;
  capability: typeof recommendationAnalysisCapability;
  input_hash: string;
  output_hash: string;
  private_payload_ref: string;
  private_payload: JsonObject;
  public_summary: RecommendationAnalysisPublicSummary;
  preference_signals: string[];
  evaluator_verdict: EvaluatorVerdict;
  settlement_state: SettlementState;
  created_at: string;
}

export interface RecommendationAnalysisReceiptInput {
  userId: string;
  agentId?: string;
  request: JsonObject;
  output: JsonObject;
  createdAt?: string;
}

export function buildRecommendationAnalysisReceiptDraft(
  input: RecommendationAnalysisReceiptInput,
): RecommendationAnalysisReceiptDraft {
  const id = randomUUID();
  const createdAt = input.createdAt ?? new Date().toISOString();
  const publicSummary = publicSummaryFor(input.request, input.output);
  const preferenceSignals = preferenceSignalsFor(input.request);
  const evaluatorVerdict = evaluatorVerdictFor(input.output);

  return {
    id,
    user_id: input.userId,
    product: receiptProduct,
    receipt_type: recommendationAnalysisReceiptType,
    agent_id: cleanText(input.agentId) ?? "save-ios",
    capability: recommendationAnalysisCapability,
    input_hash: sha256CanonicalJson(input.request),
    output_hash: sha256CanonicalJson(input.output),
    private_payload_ref: `save://receipts/recommendation_analysis/${id}`,
    private_payload: {
      receipt_type: recommendationAnalysisReceiptType,
      request: input.request,
      output: input.output,
    },
    public_summary: publicSummary,
    preference_signals: preferenceSignals,
    evaluator_verdict: evaluatorVerdict,
    settlement_state: "not_settled",
    created_at: createdAt,
  };
}

export function envelopeForRecommendationAnalysisReceipt(row: JsonObject): AgentShackReceiptEnvelope {
  return {
    product: receiptProduct,
    receipt_type: recommendationAnalysisReceiptType,
    user_id: requiredString(row.user_id, "user_id"),
    agent_id: requiredString(row.agent_id, "agent_id"),
    capability: recommendationAnalysisCapability,
    input_hash: requiredString(row.input_hash, "input_hash"),
    output_hash: requiredString(row.output_hash, "output_hash"),
    private_payload_ref: requiredString(row.private_payload_ref, "private_payload_ref"),
    public_summary: asPublicSummary(row.public_summary),
    preference_signals: stringArray(row.preference_signals),
    evaluator_verdict: parseEnum(row.evaluator_verdict, evaluatorVerdicts, "manual_review"),
    settlement_state: parseEnum(row.settlement_state, settlementStates, "manual_review"),
    created_at: requiredString(row.created_at, "created_at"),
  };
}

export function sha256CanonicalJson(value: unknown): string {
  return createHash("sha256").update(canonicalJson(value)).digest("hex");
}

function publicSummaryFor(request: JsonObject, output: JsonObject): RecommendationAnalysisPublicSummary {
  const results = Array.isArray(output.results) ? output.results : [];
  const receipt = objectValue(output.retrieval_receipt) ?? {};

  return {
    summary: "SAV-E analyzed owner-scoped saved places and kept public discovery separate.",
    capability: recommendationAnalysisCapability,
    result_count: results.length,
    saved_result_count: results.length,
    public_result_count: 0,
    proof_level_min: cleanText(request.proof_level_min ?? request.proofLevelMin) ?? null,
    public_web_used: receipt.public_web_used === true,
  };
}

function preferenceSignalsFor(request: JsonObject): string[] {
  const text = [
    cleanText(request.intent),
    ...stringArray(request.constraints),
  ].filter(Boolean).join(" ");
  const signals = new Set<string>();

  addSignal(signals, text, "coffee", /coffee|cafe|café|咖啡|咖啡廳/i);
  addSignal(signals, text, "milk_tea", /boba|milk tea|bubble tea|奶茶|珍奶/i);
  addSignal(signals, text, "restaurant", /restaurant|dinner|lunch|food|餐廳|晚餐|午餐|吃/i);
  addSignal(signals, text, "brunch", /brunch|早餐|早午餐/i);
  addSignal(signals, text, "dessert", /dessert|甜點|蛋糕/i);
  addSignal(signals, text, "bar", /bar|cocktail|wine|酒吧|調酒|葡萄酒/i);
  addSignal(signals, text, "saved_memory", /saved|memory|存過|記憶/i);
  addSignal(signals, text, "nearby", /nearby|near me|附近/i);

  signals.add(`proof_level:${cleanText(request.proof_level_min ?? request.proofLevelMin) ?? "user_confirmed_place"}`);
  return [...signals].slice(0, 12);
}

function evaluatorVerdictFor(output: JsonObject): EvaluatorVerdict {
  const results = Array.isArray(output.results) ? output.results : [];
  return results.length > 0 ? "pass" : "partial";
}

function addSignal(signals: Set<string>, text: string, signal: string, pattern: RegExp): void {
  if (pattern.test(text)) signals.add(signal);
}

function canonicalJson(value: unknown): string {
  return JSON.stringify(canonicalValue(value));
}

function canonicalValue(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonicalValue);
  if (!value || typeof value !== "object") return value;

  return Object.fromEntries(
    Object.entries(value as JsonObject)
      .filter(([, nested]) => nested !== undefined)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, nested]) => [key, canonicalValue(nested)]),
  );
}

function asPublicSummary(value: unknown): RecommendationAnalysisPublicSummary {
  const object = objectValue(value) ?? {};
  return {
    summary: cleanText(object.summary) ?? "SAV-E analyzed a recommendation request.",
    capability: recommendationAnalysisCapability,
    result_count: numberValue(object.result_count),
    saved_result_count: numberValue(object.saved_result_count),
    public_result_count: numberValue(object.public_result_count),
    proof_level_min: cleanText(object.proof_level_min) ?? null,
    public_web_used: object.public_web_used === true,
  };
}

function numberValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) && value >= 0 ? Math.floor(value) : 0;
}

function objectValue(value: unknown): JsonObject | undefined {
  return value && typeof value === "object" && !Array.isArray(value) ? value as JsonObject : undefined;
}

function stringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim())
    .filter(Boolean)
    .slice(0, 12);
}

function cleanText(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim().replace(/\s+/g, " ");
  return trimmed || undefined;
}

function requiredString(value: unknown, field: string): string {
  const text = cleanText(value);
  if (!text) throw new Error(`Missing receipt envelope field: ${field}`);
  return text;
}

function parseEnum<const T extends readonly string[]>(value: unknown, allowed: T, fallback: T[number]): T[number] {
  return typeof value === "string" && allowed.includes(value as T[number]) ? value as T[number] : fallback;
}
