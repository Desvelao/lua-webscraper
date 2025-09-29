--- WebScraper class
-- A class for scraping web pages based on predefined site scrapers, applying transformations and validations.
-- Each site scraper defines how to extract data from specific web pages using CSS selectors, transformation functions, and validation functions.
-- The WebScraper class manages a collection of site scrapers, filters, and validators, and provides methods to run the scraping process for a given URL.
-- @classmod WebScraper
local WebScraper = {}

local requests = require("requests")
local htmlparser = require("htmlparser")
local socket = require("socket")
local zlib = require("zlib")
local dkjson = require("dkjson")
local dsl_filter = require("webscraper.web_scraper.dsl_filter")

local Set = {}

function Set:new()
	return setmetatable({ _set = {}, size = 0 }, { __index = Set })
end

function Set:register(name, data)
	if self._set[name] == nil then
		self._set[name] = data
		self.size = self.size + 1
	end
end

local function create_log_tag(tag)
	return function(message)
		print("[" .. tag .. "] " .. message)
	end
end
--- Create a new instance of WebScraper.
-- @return WebScraper A new WebScraper instance.
function WebScraper:new()
	local instance = {
		sites = Set:new(),
		filters = Set:new(),
		validators = Set:new(),
		logger = {
			debug = create_log_tag("DEBUG"),
			info = create_log_tag("INFO"),
			warn = create_log_tag("WARN"),
			error = create_log_tag("ERROR"),
		},
	}
	return setmetatable(instance, { __index = WebScraper })
end

function WebScraper:load_from_remote(url)
	local response = requests.get({ url, { headers = { ["Accept"] = "application/json" } } })
	local sites = dkjson.decode(response.text).items

	for i, site in ipairs(sites) do
		self.sites:register(site.name, site)
	end
end

--- Apply a transformation pipeline to a given value.
-- @param value The value to be transformed.
-- @param pipeline_str A string representing the transformation pipeline, e.g., "fn1(...) | fn2(...)".
function WebScraper:apply_filter(value, pipeline_str)
	return dsl_filter(value, pipeline_str, self.filters._set)
end

--- Apply a validation pipeline to a given value.
-- @param value The value to be validated.
-- @param pipeline_str A string representing the validation pipeline, e.g., "fn1(...) | fn2(...)".
function WebScraper:apply_validate(value, pipeline_str)
	return dsl_filter.apply_validate(value, pipeline_str, self.validators._set)
end

function WebScraper:_fetch(url)
	local logger = self.logger
	logger.debug("[" .. url .. "] - Scrapping data")

	logger.debug("[" .. url .. "] - Request ")
	local response = requests.get({ url, { headers = { ["Accept"] = "text/html", ["Content-Encoding"] = "gzip" } } })
	local text = response.text

	logger.debug("[" .. url .. "] - Response status code: " .. response.status_code)

	-- Uncompress responses on gzip
	if response.headers["content-encoding"] == "gzip" then
		logger.debug("[" .. url .. "] - Uncompress response on gzip " .. url)
		text = zlib.inflate()(text, "finish")
	end

	for k, v in pairs(response.headers) do
		logger.debug("[" .. url .. "] - Header [" .. k .. "] " .. v)
	end

	return response.status_code == 200, text, response
end

function WebScraper:_run(scraper, data)
	local logger = self.logger
	-- self.logger = logger
	local url = data.url

	local ok, text, response = self:_fetch(url)

	if ok then
		-- Date: ISO 8601 Example: 2024-05-29T08:31:14+00:00
		data.timestamp = os.date("!%Y-%m-%dT%TZ")

		logger.debug("Parsing response")
		local root = htmlparser.parse(text)
		logger.debug("Parsed response")

		for key, sc in pairs(scraper.fields) do
			for _, selector in pairs(sc.selector) do
				logger.debug(string.format("Getting [key=%s] [selector=%s]", key, selector))
				-- TODO: add support for shadow root element
				local element = root:select(selector)

				if element then
					logger.debug(string.format("Element found [key=%s] [selector=%s]", key, selector))
				else
					logger.warn(string.format("Element not found [key=%s] [selector=%s]", key, selector))
				end

				for _, e in ipairs(element) do
					-- TODO: add support to get the attributes
					local r = e:getcontent()
					logger.debug(string.format("Content [key=%s] [result=%s]", key, r))

					if r and sc.transform then
						logger.debug(string.format("Transforming [key=%s] [transform=%s]", key, sc.transform))
						r = self:apply_filter(r, sc.transform)
						logger.debug(
							string.format(
								"Transformed [key=%s] [transform=%s] => [result=%s]",
								key,
								sc.transform,
								tostring(r)
							)
						)
					end

					if r ~= nil then
						local assign_value = true
						if r and sc.validate then
							logger.debug(string.format("Validating [key=%s] [validate=%s]", key, sc.validate))
							local validation, validation_error = self:apply_validate(r, sc.validate)
							if validation then
								logger.debug(
									string.format(
										"Validated [key=%s] [validate=%s] => [result=%s]",
										key,
										sc.validate,
										tostring(true)
									)
								)
							else
								assign_value = false
								logger.debug(
									string.format(
										"Not validated [key=%s] [validate=%s] => [result=%s]",
										key,
										sc.validate,
										tostring(validation_error)
									)
								)
							end
						end
						if assign_value then
							data[key] = r
							logger.debug(string.format("Assigned [key=%s] [result=%s]", key, tostring(r)))
							break
						end
					end
				end

				if data[key] ~= nil then
					break
				end
			end
		end
	else
		logger.error("[" .. url .. "] - Failed request. Status code: " .. response.status_code)
	end

	return data
end

--- Run the web scraper for a given URL.
-- It matches the URL against registered site scrapers and applies the corresponding scraper if a match is found.
-- @param url The URL to scrape.
function WebScraper:run(url)
	for i, site in pairs(self.sites._set) do
		local urls_match = site.urls_match

		if type(urls_match) == "table" then
			for _, url_regex in ipairs(urls_match) do
				if url:match(url_regex) then
					return self:_run(site, { url = url })
				end
			end
		elseif type(urls_match) == "string" then
			if url:match(urls_match) then
				return self:_run(site, { url = url })
			end
		end
	end
end

return WebScraper
