// UAT runner: Gherkin scenarios in uat/features/ (protected in build mode), step definitions in uat/steps/.
import { defineConfig } from "@playwright/test";
import { defineBddConfig } from "playwright-bdd";

const testDir = defineBddConfig({ features: "uat/features/**/*.feature", steps: "uat/steps/**/*.ts" });

export default defineConfig({ testDir, reporter: [["list"], ["json", { outputFile: "uat/results.json" }]] });
