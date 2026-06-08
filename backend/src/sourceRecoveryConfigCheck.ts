import { readSourceRecoveryConfigStatus } from "./sourceRecoveryConfig.js";

const status = await readSourceRecoveryConfigStatus();
console.log(JSON.stringify(status, null, 2));

if (!status.ready) {
  process.exitCode = 1;
}
