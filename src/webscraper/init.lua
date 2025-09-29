--- Main entry point for the webscraper module
-- This module initializes the webscraper, registers filters and validators,
-- and exposes the main WebScraper class along with available filters and validators.
-- @module WebScraper
-- @alias webscraper
-- @usage
-- local webscraper = require("webscraper")
-- local scraper = webscraper.WebScraper:new()
-- scraper.filters:register("lowercase", webscraper.Filters.lowercase)
-- scraper.validators:register("is_string", webscraper.Validators.is_string)
-- local result = scraper:scrape("http://example.com", { title = { selector = "h1", filters = { "lowercase" }, validators = { "is_string" } } })
-- print(result)
-- @usage
-- local webscraper = require("webscraper")
-- local result = webscraper:scrape("http://example.com", { title = { selector = "h1", filters = { "lowercase" }, validators = { "is_string" } } })
-- print(result)
local WebScraper = require("webscraper.web_scraper.web_scraper")
local Filters = require("webscraper.filters.filters.init")
local Validators = require("webscraper.filters.validators.init")

local webscraper = WebScraper:new()

for k, v in pairs(Filters) do
	webscraper.filters:register(k, v)
end

for k, v in pairs(Validators) do
	webscraper.validators:register(k, v)
end

local old_mt = getmetatable(webscraper)
local old_index = old_mt and old_mt.__index

return setmetatable(webscraper, {
	__index = function(t, k)
		-- first try the new table
		local v = ({
			WebScraper = WebScraper,
			Filters = Filters,
			Validators = Validators,
		})[k]
		if v ~= nil then
			return v
		end

		-- then fall back to the old __index
		if type(old_index) == "function" then
			return old_index(t, k)
		elseif type(old_index) == "table" then
			return old_index[k]
		end
	end,
})
