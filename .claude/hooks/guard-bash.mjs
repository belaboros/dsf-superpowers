// PreToolUse (Bash): block commands that bypass the factory's checks or rewrite shared history,
// and shell writes into paths the current mode protects.
import { readInput, currentMode, logEvent, deny } from "./lib.mjs";

const input = readInput();
const cmd = String(input.tool_input?.command || "");

const rules = [
  [/\bgit\s+commit\b[^|;&]*(\s--no-verify\b|\s-[a-zA-Z]*n\b)/, "skips the git hooks (--no-verify)"],
  [/\bgit\s+push\b[^|;&]*(\s--force\b|\s--force-with-lease\b|\s-[a-zA-Z]*f\b)/, "force-pushes"],
  [/\bgit\s+push\b[^|;&]*\s(origin|dsf|base)\s+(HEAD:)?(main|master)\b/, "pushes straight to main; open a pull request instead"],
  [/\bgit\s+config\b[^|;&]*core\.hooksPath/, "changes the git hooks path"],
  [/\bgit\s+(reset\s+--hard|clean\s+-[a-zA-Z]*f)/, "discards work irreversibly"],
  [/\b(HUSKY|LEFTHOOK|SKIP)=0?\S*\s/, "disables git hooks through an environment variable"],
];
for (const [re, why] of rules) {
  if (re.test(cmd)) {
    logEvent(input, "guard-bash-block", { why });
    deny(`DSF: this command ${why}. If it is truly needed, stop and ask the human to run it.`);
  }
}

// Best effort: shell writes into protected paths (the PR checks are the final authority).
const mode = currentMode();
const writes = /(>>?|\btee\b|\bsed\s+-i|\bperl\s+-i|\bmv\b|\bcp\b|\brm\b|\btruncate\b|\bgit\s+(checkout|restore)\b)/;
if (writes.test(cmd)) {
  const hit = mode.protect.find((p) => new RegExp(`(^|[\\s'"=/])${p.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`).test(cmd));
  if (hit) {
    logEvent(input, "guard-bash-block", { why: "protected-path-write", path: hit });
    deny(`DSF: this command looks like it writes to '${hit}', which is protected in ${mode.name} mode. Use the mode meant for it, or ask the human.`);
  }
}
