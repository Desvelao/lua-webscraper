--- This module aggregates all filter modules and exposes them as a single module.
-- Each filter is required and assigned to a key in the returned table.
-- @module filters
local M = {}

for _, key in ipairs({ "lowercase", "match", "parse_date", "replace", "to_boolean", "to_number", "trim", "uppercase" }) do
	M[key] = require("webscraper.filters.filters.repository." .. key).apply
end

return M
