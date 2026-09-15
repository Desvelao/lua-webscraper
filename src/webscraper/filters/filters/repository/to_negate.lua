--- ToNegate filter
-- This module provides a filter to invert a boolean value.
-- @module filters.filters.to_negate
local M = {}

--- Inverts a boolean value.
-- Follows the same truthy/falsy semantics as the to_boolean filter: any
-- truthy Lua value (including a non-empty string) is treated as true.
-- @param v The input value to be negated.
-- @return boolean The inverted boolean representation of the input value.
function M.apply(v)
	if v then
		return false
	end
	return true
end

return M
