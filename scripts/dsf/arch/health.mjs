#!/usr/bin/env node
// Architecture health: measures cohesion and coupling of the modules in docs/architecture/modules.json
// from the real import graph (dependency-cruiser), compares with the last run, and writes:
//   arch/health/latest.json   metrics, machine-readable (the maintenance agent reads it)
//   arch/health/latest.md     report with a table and a Mermaid diagram of the actual coupling
//   arch/health/history/<date>.json
//
//   node scripts/dsf/arch/health.mjs [--gate]   --gate exits 1 on rule violations or module cycles
//
// Metrics per module:
//   files       source files in the module
//   cohesion    share of the module's imports that stay inside it (internal / (internal + outgoing)); higher is better
//   relational  relational cohesion (internal edges + 1) / files; >= 1.5 suggests related files, < 1 loosely related
//   Ca, Ce      afferent / efferent coupling: how many modules use it / it uses
//   instability Ce / (Ca + Ce): 0 = stable (many users), 1 = unstable (depends on many)
//   undeclared  dependencies on modules that modules.json does not allow
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "..");
const gate = process.argv.includes("--gate");
const mapFile = join(root, "docs", "architecture", "modules.json");
if (!existsSync(mapFile)) {
  console.log("No docs/architecture/modules.json yet; nothing to measure.");
  process.exit(0);
}
const { modules = [] } = JSON.parse(readFileSync(mapFile, "utf8"));
const srcRoots = [...new Set(modules.map((m) => m.path.split("/")[0]))];

const cruise = spawnSync("npx", ["--no-install", "depcruise", ...srcRoots, "--output-type", "json"], {
  cwd: root,
  encoding: "utf8",
  maxBuffer: 256 * 1024 * 1024,
});
if (!cruise.stdout?.trim().startsWith("{")) {
  console.error("dependency-cruiser did not run; install the stack first (make init-stack).\n" + (cruise.stderr || "").slice(0, 2000));
  process.exit(gate ? 1 : 0);
}
const graph = JSON.parse(cruise.stdout);

const moduleOf = (file) => modules.find((m) => file === m.path || file.startsWith(m.path + "/"))?.name;
const stats = Object.fromEntries(
  modules.map((m) => [m.name, { files: 0, internal: 0, outgoing: 0, incoming: 0, uses: new Set(), usedBy: new Set(), external: new Set(), violations: 0 }]),
);
const edges = new Map(); // "a->b" -> count
let unassigned = 0;

for (const file of graph.modules || []) {
  if (file.coreModule || file.couldNotResolve || /node_modules/.test(file.source)) continue;
  const from = moduleOf(file.source);
  if (!from) {
    unassigned++;
    continue;
  }
  const s = stats[from];
  s.files++;
  for (const dep of file.dependencies || []) {
    if (dep.coreModule) continue;
    if (/node_modules/.test(dep.resolved || "") || dep.dependencyTypes?.some((t) => t.startsWith("npm"))) {
      s.external.add(dep.module);
      continue;
    }
    if ((dep.rules || []).some((r) => r.severity === "error")) s.violations++;
    const to = moduleOf(dep.resolved || "");
    if (!to) continue;
    if (to === from) {
      s.internal++;
    } else {
      s.outgoing++;
      stats[to].incoming++;
      s.uses.add(to);
      stats[to].usedBy.add(from);
      edges.set(`${from}->${to}`, (edges.get(`${from}->${to}`) || 0) + 1);
    }
  }
}

const round = (x) => Math.round(x * 100) / 100;
const declared = new Set(modules.flatMap((m) => (m.dependsOn || []).map((d) => `${m.name}->${d}`)));
const perModule = modules.map((m) => {
  const s = stats[m.name];
  const ce = s.uses.size, ca = s.usedBy.size;
  return {
    module: m.name,
    files: s.files,
    cohesion: s.internal + s.outgoing ? round(s.internal / (s.internal + s.outgoing)) : 1,
    relational: s.files ? round((s.internal + 1) / s.files) : 0,
    Ca: ca,
    Ce: ce,
    instability: ca + ce ? round(ce / (ca + ce)) : 0,
    undeclared: [...s.uses].filter((t) => !declared.has(`${m.name}->${t}`)),
    violations: s.violations,
    externalPackages: s.external.size,
  };
});

// Cycles between modules (depth-first search on the module graph).
const cycles = [];
const adj = Object.fromEntries(modules.map((m) => [m.name, [...stats[m.name].uses]]));
const color = {};
const stack = [];
const visit = (n) => {
  color[n] = 1;
  stack.push(n);
  for (const t of adj[n]) {
    if (color[t] === 1) cycles.push([...stack.slice(stack.indexOf(t)), t].join(" -> "));
    else if (!color[t]) visit(t);
  }
  stack.pop();
  color[n] = 2;
};
modules.forEach((m) => color[m.name] || visit(m.name));

const crossEdges = [...edges.values()].reduce((a, b) => a + b, 0);
const internalEdges = perModule.reduce((a, m) => a + stats[m.module].internal, 0);
const summary = {
  date: new Date().toISOString().slice(0, 10),
  modules: modules.length,
  files: perModule.reduce((a, m) => a + m.files, 0),
  unassignedFiles: unassigned,
  crossModuleShare: internalEdges + crossEdges ? round(crossEdges / (internalEdges + crossEdges)) : 0,
  averageCohesion: perModule.length ? round(perModule.reduce((a, m) => a + m.cohesion, 0) / perModule.length) : 0,
  undeclaredDependencies: perModule.reduce((a, m) => a + m.undeclared.length, 0),
  ruleViolations: graph.summary?.error ?? perModule.reduce((a, m) => a + m.violations, 0),
  moduleCycles: cycles.length,
};

const outDir = join(root, "arch", "health");
const previous = existsSync(join(outDir, "latest.json")) ? JSON.parse(readFileSync(join(outDir, "latest.json"), "utf8")).summary : null;
const delta = (k) => (previous && typeof previous[k] === "number" ? ` (${summary[k] - previous[k] >= 0 ? "+" : ""}${round(summary[k] - previous[k])})` : "");

const id = (s) => s.replace(/[^A-Za-z0-9_]/g, "_");
const mermaidEdges = [...edges.entries()].map(([k, n]) => {
  const [a, b] = k.split("->");
  return { line: `  ${id(a)} -->|${n}| ${id(b)}`, bad: !declared.has(k) };
});
const md = [
  `# Architecture health, ${summary.date}`,
  "",
  `Average cohesion ${summary.averageCohesion}${delta("averageCohesion")}, cross-module import share ${summary.crossModuleShare}${delta("crossModuleShare")}, ` +
    `${summary.undeclaredDependencies} undeclared dependencies${delta("undeclaredDependencies")}, ${summary.ruleViolations} rule violations${delta("ruleViolations")}, ` +
    `${summary.moduleCycles} module cycles${delta("moduleCycles")}, ${summary.unassignedFiles} files outside any module.`,
  "",
  "| Module | Files | Cohesion | Relational | Ca | Ce | Instability | Undeclared deps | Violations |",
  "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
  ...perModule.map((m) => `| ${m.module} | ${m.files} | ${m.cohesion} | ${m.relational} | ${m.Ca} | ${m.Ce} | ${m.instability} | ${m.undeclared.join(", ") || "-"} | ${m.violations} |`),
  "",
  cycles.length ? `Module cycles:\n${cycles.map((c) => `- ${c}`).join("\n")}\n` : "",
  "Actual coupling (edge labels = number of imports; red = not allowed by modules.json):",
  "",
  "```mermaid",
  "flowchart LR",
  ...modules.map((m) => `  ${id(m.name)}["${m.name}"]`),
  ...mermaidEdges.map((e) => e.line),
  ...mermaidEdges.map((e, i) => (e.bad ? `  linkStyle ${i} stroke:#d73a4a,stroke-width:2px` : null)).filter(Boolean),
  "```",
  "",
].join("\n");

mkdirSync(join(outDir, "history"), { recursive: true });
const result = { summary, modules: perModule, cycles, edges: Object.fromEntries(edges) };
writeFileSync(join(outDir, "latest.json"), JSON.stringify(result, null, 2) + "\n");
writeFileSync(join(outDir, "history", `${summary.date}.json`), JSON.stringify(result, null, 2) + "\n");
writeFileSync(join(outDir, "latest.md"), md);
console.log(md);

if (gate && (summary.ruleViolations > 0 || summary.moduleCycles > 0)) {
  console.error("Architecture gate failed: rule violations or module cycles.");
  process.exit(1);
}
