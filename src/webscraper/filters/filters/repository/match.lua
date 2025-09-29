--- Match filter
-- This module provides a filter to match strings against a given regular expression.
-- @module filters.filters.match
local M = {}

--- Matches a string against a given regular expression.
-- @param v The input string to be matched.
-- @param regexp The regular expression pattern to match against.
-- @return The matched substring if found, otherwise nil.
function M.apply(v, regexp)
	return v:match(regexp)
end

return M
