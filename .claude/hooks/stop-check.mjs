// Stop and SubagentStop: the agent may only finish when `make check` passes.
// Rounds are counted per session; after DSF_MAX_STOP_ROUNDS failures (default 5) the agent must
// escalate: record the blocker in the task and hand it to the human instead of trying again.
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { readInput, projectDir, stateDir, logEvent } from "./lib.mjs";

const input = readInput();
const maxRounds = Number(process.env.DSF_MAX_STOP_ROUNDS || 5);
const git = (...args) => spawnSync("git", args, { cwd: projectDir, encoding: "utf8" }).stdout || "";

// Fingerprint of the working tree: skip the checks when nothing changed since the last green run.
const fingerprint = createHash("sha256")
  .update(git("rev-parse", "HEAD") + git("status", "--porcelain") + git("diff", "HEAD"))
  .digest("hex");
mkdirSync(stateDir, { recursive: true });
const greenFile = join(stateDir, "last-green");
if (existsSync(greenFile) && readFileSync(greenFile, "utf8") === fingerprint) process.exit(0);

const roundsFile = join(stateDir, `stop-rounds-${input.session_id || "unknown"}`);
const rounds = existsSync(roundsFile) ? Number(readFileSync(roundsFile, "utf8")) || 0 : 0;

const run = spawnSync("make", ["-s", "check"], { cwd: projectDir, encoding: "utf8", timeout: 15 * 60_000 });
if (run.status === 0) {
  writeFileSync(greenFile, fingerprint);
  writeFileSync(roundsFile, "0");
  logEvent(input, "stop-check-green", { rounds });
  process.exit(0);
}

const tail = `${run.stdout || ""}${run.stderr || ""}`.trim().split("\n").slice(-60).join("\n");
if (rounds + 1 >= maxRounds) {
  writeFileSync(roundsFile, "0");
  logEvent(input, "stop-check-escalated", { rounds: rounds + 1 });
  process.stdout.write(
    JSON.stringify({
      systemMessage: `DSF: make check still fails after ${rounds + 1} rounds; the agent is handing this to you.`,
    }),
  );
  process.exit(0);
}
writeFileSync(roundsFile, String(rounds + 1));
logEvent(input, "stop-check-red", { round: rounds + 1 });
process.stdout.write(
  JSON.stringify({
    decision: "block",
    reason:
      `DSF: make check fails (round ${rounds + 1} of ${maxRounds}). Fix the cause; never weaken, skip or delete a test or rule. ` +
      `If the same failure repeats, change approach. On round ${maxRounds} you will be stopped: then write the blocker into the task ` +
      `(status needs-human) with what you tried.\n\n${tail}`,
  }),
);
