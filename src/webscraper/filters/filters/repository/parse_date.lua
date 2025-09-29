--- Parse date filter
-- This module provides a filter to parse date strings into ISO format.
-- @module filters.filters.parse_date
local M = {}

--- Parses a date string into ISO format (YYYY-MM-DD).
--  Supported format specifiers: %Y (year), %m (month), %d (day).
-- @param v The input date string to be parsed.
-- @param fmt The format of the input date string (default is "%d/%m/%Y").
-- @return The date in ISO format (YYYY-MM-DD) or the original string if parsing fails.
function M.apply(v, fmt)
	local s = tostring(v)
	fmt = fmt or "%d/%m/%Y"
	local map = {
		["%Y"] = "(%d%d%d%d)",
		["%m"] = "(%d%d)",
		["%d"] = "(%d%d)",
	}
	local patt = fmt:gsub("%%[Ymd]", map)
	local y, m, d
	if fmt:find("%%Y") and fmt:find("%%m") and fmt:find("%%d") then
		local matchers = table.pack(s:match(patt))
		-- infer order from fmt
		local yi = fmt:find("%%Y")
		local mi = fmt:find("%%m")
		local di = fmt:find("%%d")
		local seq = { { yi, "Y", a }, { mi, "m", b }, { di, "d", c } }
		table.sort(seq, function(x, y)
			return x[1] < y[1]
		end)
		local i = 1
		for _, t in pairs(seq) do
			t[3] = matchers[i]
			i = i + 1
		end
		for _, t in ipairs(seq) do
			if t[2] == "Y" then
				y = t[3]
			end
			if t[2] == "m" then
				m = t[3]
			end
			if t[2] == "d" then
				d = t[3]
			end
		end
		if y and m and d then
			return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
		end
	end
	return s
end

return M
