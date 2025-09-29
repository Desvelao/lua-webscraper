--- IsNumber filter
-- This module provides a filter to check if a value is a number.
-- @module filters.validators.is_number
local M = {}

--- Validator that checks if a value is a number.
-- Returns nil if the value is a number, otherwise returns an error message.
-- @param v The input value to be validated.
-- @return nil|string nil if the value is a number, otherwise an error message.
function M.apply(v)
	if type(v) == "number" then
		return nil
	else
		return tostring(v) .. " is not a number"
	end
end

return M
