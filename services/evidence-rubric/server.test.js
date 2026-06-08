import assert from "node:assert/strict";
import test from "node:test";
import { createEvidenceRubricServer, evaluateRubric } from "./server.js";

test("evaluateRubric returns normalized OpenAI JSON verdict", async () => {
  const verdict = await evaluateRubric(
    {
      candidate: {
        name: "Utopia Euro Caffe",
        address: "2489 Park Ave, Tustin",
      },
    },
    {
      openAIKey: "test-key",
      model: "test-model",
      fetchImpl: async (_url, init) => {
        assert.equal(init.method, "POST");
        assert.equal(init.headers.Authorization, "Bearer test-key");
        const body = JSON.parse(init.body);
        assert.equal(body.model, "test-model");
        assert.equal(body.response_format.type, "json_schema");
        return new Response(JSON.stringify({
          choices: [
            {
              message: {
                content: JSON.stringify({
                  evidence_tier: "likely",
                  confidence_reason: "Source and media evidence cite the same venue and address.",
                  missing_info: ["Verified coordinates", "User confirmation before saving as Map Stamp"],
                }),
              },
            },
          ],
        }), { status: 200 });
      },
    },
  );

  assert.deepEqual(verdict, {
    evidence_tier: "likely",
    confidence_reason: "Source and media evidence cite the same venue and address.",
    missing_info: ["Verified coordinates", "User confirmation before saving as Map Stamp"],
  });
});

test("server requires bearer token for rubric route", async () => {
  const server = createEvidenceRubricServer({
    SAVE_EVIDENCE_RUBRIC_TOKEN: "secret-token",
    OPENAI_API_KEY: "test-key",
  }, async () => {
    throw new Error("fetch should not be called");
  });

  await usingServer(server, async (url) => {
    const response = await fetch(`${url}/rubric`, {
      method: "POST",
      body: JSON.stringify({}),
    });
    assert.equal(response.status, 401);
  });
});

test("health reports readiness without exposing secrets", async () => {
  const server = createEvidenceRubricServer({
    SAVE_EVIDENCE_RUBRIC_TOKEN: "secret-token",
    OPENAI_API_KEY: "test-key",
    OPENAI_MODEL: "test-model",
  });

  await usingServer(server, async (url) => {
    const response = await fetch(`${url}/health`);
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.deepEqual(body, {
      ready: true,
      tokenConfigured: true,
      openAIConfigured: true,
      model: "test-model",
    });
    assert.ok(!JSON.stringify(body).includes("secret-token"));
    assert.ok(!JSON.stringify(body).includes("test-key"));
  });
});

async function usingServer(server, callback) {
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  assert.ok(address && typeof address === "object");
  try {
    await callback(`http://127.0.0.1:${address.port}`);
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => error ? reject(error) : resolve());
    });
  }
}
