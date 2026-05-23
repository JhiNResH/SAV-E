export type SourceSearchInput = {
  sourceUrl?: string | null;
  rawText?: string | null;
  title?: string | null;
  suggestedSearchQueries?: string[];
  maxQueries?: number;
};

export type SourceSearchResult = {
  query: string;
  title: string;
  url?: string;
  snippet?: string;
};

export type SourceSearchCandidate = {
  name: string;
  address: string;
  evidence: string[];
  confidence: number;
  missingInfo: string[];
};

export type SourceSearchOutput = {
  queries: string[];
  searchResults: SourceSearchResult[];
  candidates: SourceSearchCandidate[];
  errors: string[];
};

type FetchText = (url: string) => Promise<string>;

const defaultMaxQueries = 4;
const maxResultsPerQuery = 5;

export async function runSourceSearchRecovery(
  input: SourceSearchInput,
  fetchText: FetchText = defaultFetchText,
): Promise<SourceSearchOutput> {
  const queries = buildSourceRecoveryQueries(input).slice(0, input.maxQueries ?? defaultMaxQueries);
  const searchResults: SourceSearchResult[] = [];
  const errors: string[] = [];

  for (const query of queries) {
    try {
      const html = await fetchText(duckDuckGoHTMLURL(query));
      searchResults.push(...parseDuckDuckGoResults(html, query).slice(0, maxResultsPerQuery));
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown search error";
      errors.push(`${query}: ${message}`);
    }
  }

  return {
    queries,
    searchResults,
    candidates: candidatesFromSearchResults(searchResults),
    errors,
  };
}

export function buildSourceRecoveryQueries(input: SourceSearchInput): string[] {
  const queries: string[] = [];
  queries.push(...(input.suggestedSearchQueries ?? []));

  const sourceUrl = input.sourceUrl?.trim();
  const url = sourceUrl ? safeURL(sourceUrl) : undefined;
  const reelId = instagramReelID(url);
  const rawText = cleanText([input.title, input.rawText].filter(Boolean).join(" "));

  if (reelId) {
    queries.push(`instagram reel ${reelId} place`);
    queries.push(`${reelId} restaurant venue`);
  } else if (url?.host) {
    queries.push(`${url.host} ${url.pathname.split("/").filter(Boolean).at(-1) ?? ""} place`.trim());
  }

  const handle = firstSocialHandle(rawText);
  if (handle) queries.push(`@${handle} address`);

  if (rawText) queries.push(`"${rawText.slice(0, 80)}" place`);

  const canonicalURL = canonicalSearchURL(url);
  if (canonicalURL) queries.push(`"${canonicalURL}"`);

  return unique(queries).filter(Boolean).slice(0, defaultMaxQueries);
}

export function parseDuckDuckGoResults(html: string, query: string): SourceSearchResult[] {
  const results: SourceSearchResult[] = [];
  const blocks = html.match(/<div[^>]+class="[^"]*result[^"]*"[\s\S]*?(?=<div[^>]+class="[^"]*result[^"]*"|$)/gi) ?? [];

  for (const block of blocks) {
    const linkMatch = block.match(/<a[^>]+class="[^"]*result__a[^"]*"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/i);
    if (!linkMatch) continue;

    const snippetMatch = block.match(/<a[^>]+class="[^"]*result__snippet[^"]*"[^>]*>([\s\S]*?)<\/a>/i) ??
      block.match(/<div[^>]+class="[^"]*result__snippet[^"]*"[^>]*>([\s\S]*?)<\/div>/i);

    const title = cleanText(stripTags(linkMatch[2]));
    if (!title) continue;

    results.push({
      query,
      title,
      url: normalizeDuckDuckGoURL(decodeHTML(linkMatch[1])),
      snippet: snippetMatch ? cleanText(stripTags(snippetMatch[1])) : undefined,
    });
  }

  return results;
}

export function candidatesFromSearchResults(results: SourceSearchResult[]): SourceSearchCandidate[] {
  const candidates: SourceSearchCandidate[] = [];
  const seen = new Set<string>();

  for (const result of results) {
    const name = candidateNameFromResult(result);
    if (!name) continue;

    const address = addressFromText(`${result.title}\n${result.snippet ?? ""}`) ?? "";
    const key = `${canonicalName(name)}|${canonicalName(address)}`;
    if (seen.has(key)) continue;
    seen.add(key);

    const evidence = [
      `Search query: ${result.query}`,
      `Search result title: ${result.title}`,
      result.snippet ? `Search result snippet: ${result.snippet}` : "",
      result.url ? `Search result URL: ${result.url}` : "",
    ].filter(Boolean);

    candidates.push({
      name,
      address,
      evidence,
      confidence: address ? 0.52 : 0.38,
      missingInfo: [
        address ? "Confirm exact address" : "Verified address",
        "Verified coordinates",
        "Search-derived candidate; verify source before saving",
      ],
    });
  }

  return candidates.slice(0, 5);
}

function candidateNameFromResult(result: SourceSearchResult): string | undefined {
  let title = cleanText(result.title)
    .replace(/\s+[@#][A-Za-z0-9._-]{3,30}\b/g, "")
    .replace(/\s+\|\s+.*$/g, "")
    .replace(/\s+[–-]\s+(?:Google Maps|Yelp|Tripadvisor|OpenTable|Instagram|Facebook|TikTok).*$/gi, "")
    .replace(/\s+[–-]\s+Official(?:\s+Site)?$/gi, "")
    .replace(/\s*•\s*Instagram.*$/gi, "")
    .replace(/\s+on Instagram.*$/gi, "")
    .trim();

  title = title.split(/\s+(?:menu|reviews?|photos?|reservations?)\b/i)[0]?.trim() ?? title;
  title = title.replace(/^official\s+/i, "").trim();

  if (!isUsableCandidateName(title)) return undefined;
  return title;
}

function isUsableCandidateName(value: string): boolean {
  const lowered = value.toLowerCase();
  if (value.length < 2 || value.length > 90) return false;
  if (/\b(instagram|reel|tiktok|facebook|login|explore|hashtag|comments?|likes?)\b/i.test(value)) return false;
  if (/^\d+$/.test(value)) return false;
  if (!/[A-Za-z\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]/.test(value)) return false;
  if (/^(restaurant|venue|place|travel|food|coffee|hotel)$/i.test(value)) return false;
  return !looksLikeAddress(value);
}

function addressFromText(text: string): string | undefined {
  const patterns = [
    /\b\d{1,6}\s+[A-Za-z0-9 .'-]{2,80}\b(?:Street|St\.?|Road|Rd\.?|Avenue|Ave\.?|Boulevard|Blvd\.?|Lane|Ln\.?|Drive|Dr\.?|Way|Highway|Hwy\.?|Coast Hwy)\b(?:,\s*[A-Za-z .'-]{2,40})?/i,
    /[\u4e00-\u9fff]{2,}(?:市|区|區|路|街|道)[\u4e00-\u9fffA-Za-z0-9\-－\s]{0,40}\d{1,6}\s*(?:号|號)?/,
  ];
  return patterns.map((pattern) => text.match(pattern)?.[0]).find(Boolean);
}

function looksLikeAddress(value: string): boolean {
  return addressFromText(value) !== undefined;
}

function instagramReelID(url?: URL): string | undefined {
  if (!url?.host.toLowerCase().includes("instagram")) return undefined;
  const parts = url.pathname.split("/").filter(Boolean);
  const markerIndex = parts.findIndex((part) => part.toLowerCase() === "reel" || part.toLowerCase() === "reels");
  return markerIndex >= 0 ? parts[markerIndex + 1] : undefined;
}

function firstSocialHandle(text: string): string | undefined {
  const ignored = new Set(["instagram", "reels", "reel", "explore", "threads", "tiktok", "wanderly", "save"]);
  for (const match of text.matchAll(/@([A-Za-z0-9._]{3,30})/g)) {
    const handle = match[1].toLowerCase();
    if (!ignored.has(handle) && !handle.includes("instagram") && !/\d{5,}/.test(handle)) return handle;
  }
  return undefined;
}

function duckDuckGoHTMLURL(query: string): string {
  const params = new URLSearchParams({ q: query });
  return `https://duckduckgo.com/html/?${params.toString()}`;
}

async function defaultFetchText(url: string): Promise<string> {
  const response = await fetch(url, {
    headers: {
      "User-Agent": "SAV-E source recovery worker/1.0",
      "Accept": "text/html,application/xhtml+xml",
    },
  });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.text();
}

function safeURL(value: string): URL | undefined {
  try {
    return new URL(value);
  } catch {
    return undefined;
  }
}

function canonicalSearchURL(url?: URL): string | undefined {
  if (!url) return undefined;
  const copy = new URL(url.toString());
  copy.search = "";
  copy.hash = "";
  return copy.toString();
}

function normalizeDuckDuckGoURL(value: string): string | undefined {
  try {
    const url = new URL(value, "https://duckduckgo.com");
    const uddg = url.searchParams.get("uddg");
    return uddg ? decodeURIComponent(uddg) : url.toString();
  } catch {
    return undefined;
  }
}

function cleanText(value: string): string {
  return decodeHTML(value)
    .replace(/\s+/g, " ")
    .trim();
}

function stripTags(value: string): string {
  return value.replace(/<[^>]*>/g, " ");
}

function decodeHTML(value: string): string {
  return value
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, "\"")
    .replace(/&#034;/g, "\"")
    .replace(/&#39;/g, "'")
    .replace(/&#039;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ");
}

function unique(values: string[]): string[] {
  const seen = new Set<string>();
  const result: string[] = [];
  for (const value of values.map((item) => item.trim()).filter(Boolean)) {
    if (seen.has(value)) continue;
    seen.add(value);
    result.push(value);
  }
  return result;
}

function canonicalName(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9\u4e00-\u9fff]+/g, " ").trim();
}
