--- Text filter
-- This module provides a filter to extract an element's text/inner content.
-- @module filters.filters.text
local M = {}

--- Extracts an element's content via its own getcontent() method - the
-- same call WebScraper:_run used unconditionally before fields started
-- receiving the raw element (see attr.lua's doc comment for why). Passing
-- through a non-element value unchanged keeps this safe to use after
-- another filter has already produced a plain value.
-- @param v The input element (or already-extracted value).
-- @return string The element's text/inner content, or v unchanged.
function M.apply(v)
	if type(v) == "table" and type(v.getcontent) == "function" then
		return v:getcontent()
	end
	return v
end

return M
