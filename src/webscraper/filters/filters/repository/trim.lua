--- Trim filter
-- This module provides a filter to trim leading and trailing whitespace from strings.
-- @module filters.filters.trim
local M = {}

--- Trim leading and trailing whitespace from a string
-- @param v The input string to be trimmed.
-- @return The trimmed string with leading and trailing whitespace removed.
function M.apply(v)
	return (tostring(v):gsub("^%s+", ""):gsub("%s+$", ""))
end

return M
