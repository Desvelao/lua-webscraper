--- ToBoolean filter
-- This module provides a filter to convert input values to boolean.
-- @module filters.filters.to_boolean
local M = {}

--- Converts a value to a boolean
-- If the value is truthy, returns true; otherwise, returns false.
-- @param v The input value to be converted.
-- @return boolean The boolean representation of the input value.
function M.apply(v)
	if v then
		return true
	end
	return false
end

return M
