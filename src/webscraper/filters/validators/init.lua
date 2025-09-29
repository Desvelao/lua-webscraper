--- This module aggregates various validator filters for the webscraper.
--- Each validator is required and assigned to a key in the returned table.
--- @module validators
local M = {}

for _, key in ipairs({ "is_boolean", "is_number", "is_string" }) do
	M[key] = require("webscraper.filters.validators.repository." .. key).apply
end

return M
