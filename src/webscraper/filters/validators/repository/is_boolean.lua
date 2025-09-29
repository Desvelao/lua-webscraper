--- IsBoolean filter
-- This module provides a filter to validate if a value is a boolean.
-- @module filters.validators.is_boolean
local M = {}

--- Validates if a value is a boolean
-- Returns nil if the value is a boolean, otherwise returns an error message.
-- @param v The input value to be validated.
-- @return nil|string nil if the value is a boolean, otherwise an error message.
function M.apply(v)
	if type(v) == "boolean" then
		return nil
	else
		return tostring(v) .. " is not a boolean"
	end
end

return M
