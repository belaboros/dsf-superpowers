// PostToolUse (Edit|Write|MultiEdit): format and lint the file that was just edited.
// The stack's Makefile.app provides `lint-file-stack`; problems go straight back to the agent (exit 2).
import { spawnSync } from "node:child_process";
import { readInput, projectDir, toRepoPath, logEvent } from "./lib.mjs";

const input = readInput();
const path = toRepoPath(input.tool_input?.file_path);
if (!path || path.startsWith("..")) process.exit(0);

const probe = spawnSync("make", ["-n", "lint-file-stack", `FILE=${path}`], { cwd: projectDir, encoding: "utf8" });
if (probe.status !== 0) process.exit(0); // no stack configured yet

const run = spawnSync("make", ["-s", "lint-file-stack", `FILE=${path}`], { cwd: projectDir, encoding: "utf8", timeout: 60_000 });
if (run.status !== 0) {
  logEvent(input, "post-edit-problems", { path });
  const out = `${run.stdout || ""}${run.stderr || ""}`.trim().split("\n").slice(-40).join("\n");
  process.stderr.write(`DSF: ${path} has lint or format problems. Fix them before moving on:\n${out}\n`);
  process.exit(2);
}
