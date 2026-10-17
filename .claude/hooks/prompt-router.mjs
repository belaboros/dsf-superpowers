// UserPromptSubmit: name the workflow that fits the request, so the right one runs without the human naming it.
// Printed text is added to the context; it never blocks the prompt.
import { readInput } from "./lib.mjs";

const prompt = String(readInput().prompt || "").trim();
if (prompt.length < 20 || prompt.startsWith("/")) process.exit(0);

const p = prompt.toLowerCase();
let workflow = "feature";
if (/\b(bugs?|fix\w*|broken|crash\w*|errors?|regression|fail\w*|wrong)\b/.test(p)) workflow = "bugfix";
else if (/\b(idea|explore|research|prototype|spike|compare|options|what if|investigate)\b/.test(p)) workflow = "exploration";
else if (/\b(factory|skill|hook|linter|rule|checker|ci)\b/.test(p)) workflow = "factory";

console.log(
  `DSF: this looks like a ${workflow} request. Follow docs/dsf/workflows.md#${workflow}, ` +
    `using the commands that .dsf/CLAUDE.workflow.md maps to each step. If it is not a ${workflow} request, say which workflow you use instead.`,
);
