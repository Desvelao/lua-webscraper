--- Lowercase filter
-- This module provides a filter to convert input values to lowercase strings.
-- @module filters.filters.lowercase
local M = {}

--- Converts the input value to a lowercase string.
-- @param v The input value to be converted.
-- @return The lowercase string representation of the input value.
function M.apply(v)
	return tostring(v):lower()
end

return M
