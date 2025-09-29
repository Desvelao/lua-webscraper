--- IsNumber filter
-- This module provides a filter to check if a value is a string.
-- @module filters.validators.is_string
local M = {}

--- Validates that the value is a string
-- Returns nil if the value is a string, otherwise returns an error message.
-- @param v The input value to be validated.
-- @return nil|string nil if the value is a string, otherwise an error message.
function M.apply(v)
	if type(v) == "string" then
		return nil
	else
		return tostring(v) .. " is not a string"
	end
end

return M
