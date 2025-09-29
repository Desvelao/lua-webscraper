--- Replace filter
-- This module provides a filter to replace occurrences of a pattern in a string with a replacement string.
-- @module filters.filters.replace
local M = {}

--- Replace occurrences of a pattern in a string with a replacement string.
-- @param v The input string where replacements will be made.
-- @param pattern The pattern to search for (default is an empty string).
-- @param repl The replacement string (default is an empty string).
-- @return The modified string with replacements made.
function M.apply(v, pattern, repl)
	pattern = pattern or ""
	repl = repl or ""
	return tostring(v):gsub(pattern, repl)
end

return M
