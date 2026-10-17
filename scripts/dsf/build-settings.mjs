#!/usr/bin/env node
// Builds .claude/settings.json from the layered sources, in this order:
//   .dsf/settings/base.json      owned by dsf-base
//   .dsf/settings/workflow.json  owned by the dsf-<workflow> repo (skill packs, plugins)
//   .dsf/settings/app.json       owned by the application
// Objects merge key by key, arrays are concatenated without duplicates, later layers win for plain values.
// Run with --check to fail when .claude/settings.json is out of date (used by `make check`).
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const layers = ["base", "workflow", "app"].map((n) => join(root, ".dsf", "settings", `${n}.json`));
const target = join(root, ".claude", "settings.json");

const isObject = (v) => v !== null && typeof v === "object" && !Array.isArray(v);
function merge(a, b) {
  if (Array.isArray(a) && Array.isArray(b)) {
    const seen = new Set(a.map((x) => JSON.stringify(x)));
    return [...a, ...b.filter((x) => !seen.has(JSON.stringify(x)))];
  }
  if (isObject(a) && isObject(b)) {
    const out = { ...a };
    for (const [k, v] of Object.entries(b)) out[k] = k in out ? merge(out[k], v) : v;
    return out;
  }
  return b;
}

let settings = {};
for (const file of layers) {
  if (!existsSync(file)) continue;
  const layer = JSON.parse(readFileSync(file, "utf8"));
  delete layer.$comment;
  settings = merge(settings, layer);
}
// No comment key in the output: Claude Code validates settings.json. docs/dsf/hooks.md explains the layering.
const text = JSON.stringify(settings, null, 2) + "\n";

if (process.argv.includes("--check")) {
  const current = existsSync(target) ? readFileSync(target, "utf8") : "";
  if (current !== text) {
    console.error(".claude/settings.json is out of date; run `make settings` and commit it.");
    process.exit(1);
  }
  process.exit(0);
}
mkdirSync(dirname(target), { recursive: true });
writeFileSync(target, text);
console.log(`wrote ${target}`);
