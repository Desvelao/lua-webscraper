--- ToNumber filter
-- This module provides a filter to convert strings to numbers, handling common decimal and grouping conventions.
-- @module filters.filters.to_number
local M = {}

--- Convert a string to a number, handling common decimal/grouping conventions
-- @param v The input string to be converted to a number.
-- @return The numeric representation of the input string, or nil if conversion fails.
function M.apply(v)
	local s = tostring(v)
	-- normalize common decimal/grouping conventions: keep last separator as decimal
	-- remove spaces
	s = s:gsub("%s+", "")
	-- if both , and . exist, assume . thousands if last , after ., else vice versa
	local last_dot = s:match(".*()%.")
	local last_com = s:match(".*(),")
	if last_dot and last_com then
		if last_com > last_dot then
			s = s:gsub("%.", ""):gsub(",", ".")
		else
			s = s:gsub(",", "")
		end
	else
		-- if only comma present, use as decimal
		if s:find(",") and not s:find("%.") then
			s = s:gsub(",", ".")
		end
		-- if only dot present: keep as-is
	end
	local num = tonumber(s)
	return num
end

return M
