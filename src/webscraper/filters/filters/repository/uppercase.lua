--- Uppercase filter
-- This module provides a filter to convert input values to uppercase strings.
-- @module filters.filters.uppercase
local M = {}

--- Converts a string to uppercase.
-- @param v The input string to be converted.
-- @return The uppercase string representation of the input value.
function M.apply(v)
	return tostring(v):upper()
end

return M
