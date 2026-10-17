// Factory rules (config/dsf) + module rules generated from docs/architecture/modules.json.
const base = require("./config/dsf/depcruise.base.cjs");

let moduleRules = [];
try {
  moduleRules = require("./docs/architecture/generated/depcruise-modules.cjs");
} catch {
  // No module map yet: the architect agent creates it.
}

module.exports = { ...base, forbidden: [...base.forbidden, ...moduleRules] };
