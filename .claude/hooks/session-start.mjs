// SessionStart: give every session the current factory context instead of letting it guess.
// Whatever this prints is added to the session's context.
import { readdirSync, readFileSync, existsSync, writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { readInput, projectDir, stateDir, currentMode, readJson, readSetting } from "./lib.mjs";

const input = readInput();
const mode = currentMode();
const lines = [];
const role = existsSync(join(projectDir, ".dsf.app")) ? "application" : existsSync(join(projectDir, ".dsf.layer")) ? "workflow" : "base";

lines.push(`# Dark / gray Software Factory context`);
lines.push(`Repo role: ${role}. Mode: ${mode.name}: ${mode.description}`);
if (mode.unknown) lines.push(`WARNING: unknown DSF_MODE; valid modes are in .dsf/modes.json.`);
lines.push(`Protected in this mode: ${mode.protect.join(", ") || "nothing"}`);
if (role === "application") {
  lines.push(`Application: ${readSetting(".dsf.app", "APP_NAME")}. Tasks live in: ${readSetting(".dsf.app", "TASKS_BACKEND")} (see CLAUDE.app.md).`);
}

const modules = readJson("docs/architecture/modules.json");
if (modules?.modules?.length) {
  lines.push(`Modules (docs/architecture/modules.json): ` + modules.modules.map((m) => `${m.name} -> [${(m.dependsOn || []).join(", ")}]`).join("; "));
}

const adrDir = join(projectDir, "docs", "architecture", "adr");
if (existsSync(adrDir)) {
  const adrs = readdirSync(adrDir).filter((f) => /^\d+.*\.md$/.test(f)).sort();
  const summary = adrs.map((f) => {
    const text = readFileSync(join(adrDir, f), "utf8");
    const title = text.match(/^#\s+(.+)$/m)?.[1] || f;
    const status = text.match(/^(?:status|Status):\s*(\w+)/m)?.[1] || "?";
    return `${title} [${status}]`;
  });
  if (summary.length) lines.push(`ADRs: ${summary.join("; ")}`);
}

const health = join(projectDir, "arch", "health", "latest.md");
if (existsSync(health)) {
  lines.push(`Latest architecture health (arch/health/latest.md):`);
  lines.push(...readFileSync(health, "utf8").split("\n").slice(0, 12));
}

const snapshot = join(stateDir, "compact-snapshot.md");
if (input.source === "compact" && existsSync(snapshot)) {
  lines.push(`Before compaction you were here:`, readFileSync(snapshot, "utf8"));
}

// Remember where the session started, for the session log.
mkdirSync(stateDir, { recursive: true });
const head = spawnSync("git", ["rev-parse", "HEAD"], { cwd: projectDir, encoding: "utf8" }).stdout.trim();
writeFileSync(join(stateDir, `session-${input.session_id || "unknown"}.json`), JSON.stringify({ head, mode: mode.name, started: new Date().toISOString() }));

console.log(lines.join("\n"));
