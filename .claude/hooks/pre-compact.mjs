// PreCompact: save where the work stands, so the session can pick it up after compaction
// (session-start.mjs prints it back when the session resumes from a compaction).
import { writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { stateDir, projectDir } from "./lib.mjs";

const git = (...a) => spawnSync("git", a, { cwd: projectDir, encoding: "utf8" }).stdout.trim();
mkdirSync(stateDir, { recursive: true });
writeFileSync(
  join(stateDir, "compact-snapshot.md"),
  [
    `Branch: ${git("branch", "--show-current")}`,
    `Uncommitted changes:`,
    git("status", "--short") || "(none)",
    `Last commits:`,
    git("log", "-5", "--format=%h %s"),
    `Re-read the current task and its plan file before continuing.`,
  ].join("\n"),
);
