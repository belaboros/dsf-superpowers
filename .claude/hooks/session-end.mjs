// SessionEnd: append a one-line summary of the session to factory/logs/sessions.jsonl.
// The weekly factory-improve routine reads these logs to find repeated corrections and blocks.
import { readFileSync, writeFileSync, existsSync, mkdirSync, appendFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { readInput, projectDir, stateDir } from "./lib.mjs";

const input = readInput();
const id = input.session_id || "unknown";
const startFile = join(stateDir, `session-${id}.json`);
const start = existsSync(startFile) ? JSON.parse(readFileSync(startFile, "utf8")) : {};
const git = (...a) => spawnSync("git", a, { cwd: projectDir, encoding: "utf8" }).stdout.trim();

const eventsFile = join(stateDir, "events.jsonl");
const events = existsSync(eventsFile)
  ? readFileSync(eventsFile, "utf8").split("\n").filter(Boolean).map((l) => JSON.parse(l)).filter((e) => e.session === id)
  : [];
const counts = {};
for (const e of events) counts[e.event] = (counts[e.event] || 0) + 1;

const commits = start.head ? git("rev-list", "--count", `${start.head}..HEAD`) : "";
const entry = {
  ts: new Date().toISOString(),
  session: id,
  mode: start.mode,
  reason: input.reason,
  branch: git("branch", "--show-current"),
  commits: Number(commits) || 0,
  events: counts,
  blocked: events.filter((e) => e.event.endsWith("-block")).map((e) => e.path || e.why).slice(0, 20),
};
mkdirSync(join(projectDir, "factory", "logs"), { recursive: true });
appendFileSync(join(projectDir, "factory", "logs", "sessions.jsonl"), JSON.stringify(entry) + "\n");

// Keep only other sessions' events in the local state file.
if (existsSync(eventsFile)) {
  const rest = readFileSync(eventsFile, "utf8").split("\n").filter((l) => l && !l.includes(`"session":"${id}"`));
  writeFileSync(eventsFile, rest.length ? rest.join("\n") + "\n" : "");
}
