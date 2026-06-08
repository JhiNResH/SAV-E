import assert from "node:assert/strict";
import test from "node:test";
import { readSourceRecoveryConfigStatus } from "./sourceRecoveryConfig.js";

test("source recovery config is ready with optional adapters disabled", async () => {
  const status = await readSourceRecoveryConfigStatus({
    SAVE_ENABLE_SERVER_KEYFRAME_EXTRACTION: "false",
    SAVE_ENABLE_SERVER_OCR: "false",
    SAVE_ENABLE_SERVER_ASR: "false",
  });

  assert.equal(status.ready, true);
  assert.equal(status.asr.enabled, false);
  assert.equal(status.externalRubric.configured, false);
  assert.deepEqual(status.errors, []);
});

test("source recovery config fails when ASR is enabled without executable CLI", async () => {
  const status = await readSourceRecoveryConfigStatus({
    SAVE_ENABLE_SERVER_KEYFRAME_EXTRACTION: "true",
    SAVE_ENABLE_SERVER_ASR: "true",
    SAVE_SERVER_ASR_COMMAND: "save-missing-whisper-command-for-test",
  });

  assert.equal(status.ready, false);
  assert.equal(status.asr.enabled, true);
  assert.equal(status.asr.ready, false);
  assert.ok(status.errors.some((error) => error.includes("SAVE_ENABLE_SERVER_ASR=true")));
});

test("source recovery config rejects unsafe external rubric URL", async () => {
  const status = await readSourceRecoveryConfigStatus({
    SAVE_EVIDENCE_RUBRIC_URL: "http://localhost:8787/rubric",
  });

  assert.equal(status.ready, false);
  assert.equal(status.externalRubric.configured, true);
  assert.equal(status.externalRubric.ready, false);
  assert.ok(status.errors.some((error) => error.includes("SAVE_EVIDENCE_RUBRIC_URL")));
});

test("source recovery config fails when OCR or ASR is enabled without video evidence fetch", async () => {
  const status = await readSourceRecoveryConfigStatus({
    SAVE_ENABLE_SERVER_KEYFRAME_EXTRACTION: "false",
    SAVE_ENABLE_SERVER_ASR: "true",
    SAVE_SERVER_ASR_COMMAND: "/bin/echo",
  });

  assert.equal(status.ready, false);
  assert.ok(status.errors.some((error) => error.includes("SAVE_ENABLE_SERVER_KEYFRAME_EXTRACTION=true")));
});
