// PreToolUse (Edit|Write|MultiEdit|NotebookEdit): agents may not edit what judges them.
// Which paths are protected depends on DSF_MODE (design, build, factory); see .dsf/modes.json.
import { readInput, currentMode, toRepoPath, protectedBy, logEvent, deny } from "./lib.mjs";

const input = readInput();
const mode = currentMode();
const path = toRepoPath(input.tool_input?.file_path || input.tool_input?.notebook_path);
if (!path || path.startsWith("..")) process.exit(0);

const hit = protectedBy(path, mode.protect, mode.allow);
if (hit) {
  logEvent(input, "protect-paths-block", { mode: mode.name, path });
  deny(
    `DSF: '${path}' is protected in ${mode.name} mode (rule '${hit}'). ` +
      `${mode.name} mode is for: ${mode.description} ` +
      "If this file really needs to change, stop and say so: it is changed in another mode (make design / make build / make factory) through a PR the human approves.",
  );
}
