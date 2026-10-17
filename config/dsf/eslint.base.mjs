// Factory-wide ESLint rules (owned by dsf-base). The app's eslint.config.js spreads this array first.
// Rules here exist to stop slop from accumulating; each one should name the failure it prevents.
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  // Factory code (.dsf, .claude, scripts/dsf, config/dsf) is checked in dsf-base, not in every app.
  { ignores: ["dist/", "coverage/", "node_modules/", "docs/architecture/generated/", ".features-gen/", "playwright-report/", "test-results/", "arch/health/", ".dsf/", ".claude/", ".specify/", "scripts/dsf/", "config/dsf/", "*.config.*", ".dependency-cruiser.cjs"] },
  js.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  {
    languageOptions: { parserOptions: { projectService: true, tsconfigRootDir: process.cwd() } },
    linterOptions: { reportUnusedDisableDirectives: "error" },
    rules: {
      // Size and complexity limits: large files and functions are where agents hide duplication.
      "max-lines": ["error", { max: 400, skipBlankLines: true, skipComments: true }],
      "max-lines-per-function": ["error", { max: 80, skipBlankLines: true, skipComments: true }],
      complexity: ["error", 12],
      "max-depth": ["error", 4],
      "max-params": ["error", 4],
      eqeqeq: "error",
      "no-console": ["error", { allow: ["warn", "error"] }],
      // Tests may not be skipped or focused to make a run green.
      "no-restricted-properties": [
        "error",
        ...["describe", "it", "test"].flatMap((object) =>
          ["skip", "only", "todo"].map((property) => ({ object, property, message: "Do not skip or focus tests; fix the code or ask the human." })),
        ),
      ],
      // Every suppression needs a reason a reviewer can judge.
      "@typescript-eslint/ban-ts-comment": ["error", { "ts-expect-error": "allow-with-description", minimumDescriptionLength: 10 }],
    },
  },
  {
    files: ["**/*.test.ts", "**/*.spec.ts", "uat/**/*.ts"],
    rules: { "max-lines-per-function": "off", "@typescript-eslint/no-floating-promises": "off" },
  },
  {
    // playwright-bdd steps without fixtures take an empty object pattern: Given("...", async ({}, n) => ...)
    files: ["uat/steps/**/*.ts"],
    rules: { "no-empty-pattern": "off" },
  },
  {
    files: ["**/*.js", "**/*.mjs", "**/*.cjs"],
    ...tseslint.configs.disableTypeChecked,
  },
);
