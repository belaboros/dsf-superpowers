// Factory-wide dependency rules (owned by dsf-base). The app's .dependency-cruiser.cjs adds the
// module rules generated from docs/architecture/modules.json.
module.exports = {
  forbidden: [
    { name: "no-circular", severity: "error", comment: "Cycles make modules impossible to change or test alone.", from: {}, to: { circular: true } },
    { name: "no-orphans", severity: "warn", comment: "Files nobody imports are usually dead code.", from: { orphan: true, pathNot: ["\\.d\\.ts$", "(^|/)\\.[^/]+\\.(js|cjs|mjs|ts)$", "\\.config\\.(js|cjs|mjs|ts)$", "\\.test\\.ts$", "\\.spec\\.ts$", "(^|/)main\\.ts$", "(^|/)index\\.ts$"] }, to: {} },
    { name: "not-to-unresolvable", severity: "error", comment: "Imports must resolve.", from: {}, to: { couldNotResolve: true } },
    { name: "no-non-package-json", severity: "error", comment: "Only depend on packages listed in package.json.", from: {}, to: { dependencyTypes: ["npm-no-pkg", "npm-unknown"] } },
    { name: "not-to-dev-dep", severity: "error", comment: "Production code must not import dev dependencies.", from: { path: "^src/", pathNot: "\\.(test|spec)\\.ts$" }, to: { dependencyTypes: ["npm-dev"] } },
    { name: "not-to-test", severity: "error", comment: "Production code must not import tests.", from: { pathNot: "\\.(test|spec)\\.ts$" }, to: { path: "\\.(test|spec)\\.ts$" } },
  ],
  options: {
    doNotFollow: { path: "node_modules" },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: "tsconfig.json" },
    enhancedResolveOptions: { exportsFields: ["exports"], conditionNames: ["import", "require", "node", "default"] },
  },
};
