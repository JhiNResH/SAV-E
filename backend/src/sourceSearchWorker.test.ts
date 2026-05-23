import assert from "node:assert/strict";
import test from "node:test";
import {
  buildSourceRecoveryQueries,
  candidatesFromSearchResults,
  parseDuckDuckGoResults,
  runSourceSearchRecovery,
} from "./sourceSearchWorker.js";

test("buildSourceRecoveryQueries strips Instagram tracking query", () => {
  const queries = buildSourceRecoveryQueries({
    sourceUrl: "https://www.instagram.com/reel/DWmzyodgbuv/?igsh=tracking",
  });

  assert.deepEqual(queries, [
    "instagram reel DWmzyodgbuv place",
    "DWmzyodgbuv restaurant venue",
    "\"https://www.instagram.com/reel/DWmzyodgbuv/\"",
  ]);
});

test("parseDuckDuckGoResults extracts titles snippets and canonical target URLs", () => {
  const html = `
    <div class="result">
      <a class="result__a" href="/l/?uddg=https%3A%2F%2Fwww.theranchlb.com%2Fdining%2Fthe-porch">The Porch at The Ranch at Laguna Beach - Official</a>
      <a class="result__snippet">31106 Coast Hwy, Laguna Beach, CA. Outdoor dining and reservations.</a>
    </div>
  `;

  const results = parseDuckDuckGoResults(html, "DWmzyodgbuv restaurant venue");

  assert.equal(results.length, 1);
  assert.equal(results[0].title, "The Porch at The Ranch at Laguna Beach - Official");
  assert.equal(results[0].url, "https://www.theranchlb.com/dining/the-porch");
  assert.match(results[0].snippet ?? "", /31106 Coast Hwy/);
});

test("candidatesFromSearchResults keeps search-derived candidates review scoped", () => {
  const candidates = candidatesFromSearchResults([
    {
      query: "DWmzyodgbuv restaurant venue",
      title: "The Porch at The Ranch at Laguna Beach - Official",
      url: "https://www.theranchlb.com/dining/the-porch",
      snippet: "31106 Coast Hwy, Laguna Beach, CA",
    },
  ]);

  assert.equal(candidates.length, 1);
  assert.equal(candidates[0].name, "The Porch at The Ranch at Laguna Beach");
  assert.equal(candidates[0].address, "31106 Coast Hwy, Laguna Beach");
  assert.equal(candidates[0].confidence, 0.52);
  assert.ok(candidates[0].missingInfo.includes("Verified coordinates"));
  assert.ok(candidates[0].missingInfo.includes("Search-derived candidate; verify source before saving"));
});

test("runSourceSearchRecovery uses injected fetcher and returns candidates", async () => {
  const output = await runSourceSearchRecovery(
    {
      sourceUrl: "https://www.instagram.com/reel/DWmzyodgbuv/?igsh=tracking",
      maxQueries: 1,
    },
    async () => `
      <div class="result">
        <a class="result__a" href="https://example.com/place">The Porch at The Ranch at Laguna Beach - Official</a>
        <div class="result__snippet">31106 Coast Hwy, Laguna Beach, CA</div>
      </div>
    `,
  );

  assert.deepEqual(output.queries, ["instagram reel DWmzyodgbuv place"]);
  assert.equal(output.searchResults.length, 1);
  assert.equal(output.candidates[0].name, "The Porch at The Ranch at Laguna Beach");
});
