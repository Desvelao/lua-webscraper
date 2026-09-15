--- Attr filter
-- This module provides a filter to read an HTML attribute (e.g. href, src,
-- content) off the matched element, instead of its text content.
-- @module filters.filters.attr
local M = {}

--- Reads an attribute's value off an element.
-- WebScraper:_run seeds a field's transform pipeline with the matched
-- element itself (not pre-extracted text), specifically so this filter can
-- reach the element's own htmlparser attributes table - a plain text-only
-- pipeline should start with the `text()` filter instead (or have no
-- transform at all, which defaults to element:getcontent()).
-- @param v The input element.
-- @param name The attribute name to read (e.g. "href", "src", "content").
-- @return string|nil The attribute's value, or nil if v isn't an element
-- or has no such attribute.
function M.apply(v, name)
	if type(v) == "table" and type(v.attributes) == "table" then
		return v.attributes[name]
	end
	return nil
end

return M
