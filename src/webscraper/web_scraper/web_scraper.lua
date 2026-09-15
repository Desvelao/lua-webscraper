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
local expr = require("webscraper.web_scraper.expr")

-- Sent with every request unless overridden via WebScraper:new(opts) - see
-- its own doc comment. No previous default existed at all (just Accept/
-- Content-Encoding), which is a bigger giveaway to anti-bot/anti-scraping
-- systems than a real browser User-Agent.
local DEFAULT_HEADERS = {
	["Accept"] = "text/html",
	["Content-Encoding"] = "gzip",
	["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
}

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
-- @param opts (optional) table - `user_agent` overrides the default
-- User-Agent header; `headers` merges (and can override) any header,
-- including User-Agent/Accept/Content-Encoding, on top of DEFAULT_HEADERS.
-- @return WebScraper A new WebScraper instance.
function WebScraper:new(opts)
	opts = opts or {}
	local headers = {}
	for k, v in pairs(DEFAULT_HEADERS) do
		headers[k] = v
	end
	if opts.user_agent then
		headers["User-Agent"] = opts.user_agent
	end
	if opts.headers then
		for k, v in pairs(opts.headers) do
			headers[k] = v
		end
	end

	local instance = {
		sites = Set:new(),
		filters = Set:new(),
		validators = Set:new(),
		headers = headers,
		logger = {
			debug = create_log_tag("DEBUG"),
			info = create_log_tag("INFO"),
			warn = create_log_tag("WARN"),
			error = create_log_tag("ERROR"),
		},
	}
	return setmetatable(instance, { __index = WebScraper })
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

-- `headers` (optional) is a per-site override merged on top of self.headers
-- for this one request only - self.headers itself is never mutated, since
-- it's shared across every site this WebScraper instance serves.
-- `ssl_verify` (optional, third positional arg) is accepted for call-shape
-- parity with an injected transport's own :fetch(url, headers, ssl_verify)
-- (see a caller's own `_fetch` override), but is NOT acted on here - the
-- underlying `requests` library (lua-requests, over LuaSocket/LuaSec)
-- exposes no per-request certificate-verification toggle, so this
-- default fetch always verifies however LuaSec itself is configured.
function WebScraper:_fetch(url, headers, ssl_verify)
	local logger = self.logger
	logger.debug("[" .. url .. "] - Scrapping data")

	local request_headers = self.headers
	if headers then
		request_headers = {}
		for k, v in pairs(self.headers) do
			request_headers[k] = v
		end
		for k, v in pairs(headers) do
			request_headers[k] = v
		end
	end

	logger.debug("[" .. url .. "] - Request ")
	local response = requests.get({ url, { headers = request_headers } })
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

-- Checks a fetched page against a site's optional `page` config
-- ({expect_selector, block_selector, block_text}, all optional arrays of
-- strings) BEFORE any field selector/transform/validate runs against it -
-- so a bot-check/CAPTCHA page (which often responds 200 with entirely
-- unrelated content) is caught explicitly instead of silently producing
-- empty fields. `block_selector`/`block_text` are checked first (a match
-- means the page is a known block/CAPTCHA page); `expect_selector`, if
-- given, then requires at least one of its selectors to be present (a
-- caller's positive confirmation that the real page loaded).
-- @return true, nil on success, or false, reason on failure.
function WebScraper:_validate_page(root, text, page)
	if page.block_selector then
		for _, selector in ipairs(page.block_selector) do
			local element = root:select(selector)
			if element and #element > 0 then
				return false, string.format("page blocked: matched block_selector '%s'", selector)
			end
		end
	end

	if page.block_text then
		local lower_text = text:lower()
		for _, marker in ipairs(page.block_text) do
			if lower_text:find(marker:lower(), 1, true) then
				return false, string.format("page blocked: matched block_text '%s'", marker)
			end
		end
	end

	if page.expect_selector and #page.expect_selector > 0 then
		local found = false
		for _, selector in ipairs(page.expect_selector) do
			local element = root:select(selector)
			if element and #element > 0 then
				found = true
				break
			end
		end
		if not found then
			return false, "page validation failed: none of the expected selectors were found"
		end
	end

	return true, nil
end

-- Applies a field's transform/validate pipeline to an already-produced
-- value `r` (an element for a selector-based field, a number for a
-- computed one) and assigns it into `data[key]` if it survives both -
-- shared by both the selector pass and the computed pass in _run so this
-- transform -> validate -> assign logic lives in exactly one place.
function WebScraper:_assign_field(data, key, sc, r)
	local logger = self.logger

	if sc.transform and sc.transform ~= "" then
		logger.debug(string.format("Transforming [key=%s] [transform=%s]", key, sc.transform))
		r = self:apply_filter(r, sc.transform)
		logger.debug(
			string.format("Transformed [key=%s] [transform=%s] => [result=%s]", key, sc.transform, tostring(r))
		)
	end

	if r == nil then
		return
	end

	local assign_value = true
	if sc.validate then
		logger.debug(string.format("Validating [key=%s] [validate=%s]", key, sc.validate))
		local validation, validation_error = self:apply_validate(r, sc.validate)
		if validation then
			logger.debug(string.format("Validated [key=%s] [validate=%s] => [result=%s]", key, sc.validate, tostring(true)))
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
	end
end

-- Orders a site's computed fields ({[key] = expr_string}) so that any
-- field referencing another computed field is evaluated after it - raw
-- (selector-based) field references need no ordering here since the
-- selector pass in _run always runs first. Returns the ordered list of
-- keys, or nil, err if a circular dependency is found (e.g. a references
-- b which references a).
local function topo_sort_computed(computed)
	local order = {}
	local state = {} -- nil = unvisited, "visiting", "done"

	local function visit(key, chain)
		if state[key] == "done" then
			return true
		end
		if state[key] == "visiting" then
			return false, "circular dependency in computed properties: " .. table.concat(chain, " -> ") .. " -> " .. key
		end
		state[key] = "visiting"
		table.insert(chain, key)
		for dep in pairs(expr.identifiers(computed[key])) do
			if dep ~= key and computed[dep] then
				local ok, err = visit(dep, chain)
				if not ok then
					return false, err
				end
			end
		end
		table.remove(chain)
		state[key] = "done"
		table.insert(order, key)
		return true
	end

	for key in pairs(computed) do
		local ok, err = visit(key, {})
		if not ok then
			return nil, err
		end
	end
	return order
end

function WebScraper:_run(scraper, data)
	local logger = self.logger
	-- self.logger = logger
	local url = data.url

	local ok, text, response = self:_fetch(url, scraper.headers, scraper.ssl_verify)

	if not ok then
		local status_code = response and response.status_code
		logger.error("[" .. url .. "] - Failed request. Status code: " .. tostring(status_code))
		return data, string.format("fetch failed (status %s)", tostring(status_code))
	end

	-- Date: ISO 8601 Example: 2024-05-29T08:31:14+00:00
	data.timestamp = os.date("!%Y-%m-%dT%TZ")

	logger.debug("Parsing response")
	local root = htmlparser.parse(text)
	logger.debug("Parsed response")

	if scraper.page then
		local page_ok, page_err = self:_validate_page(root, text, scraper.page)
		if not page_ok then
			logger.warn("[" .. url .. "] - " .. page_err)
			return data, page_err
		end
	end

	-- Pass 1: selector-based fields (element-seeded pipelines, see
	-- _assign_field) - order-independent, since none of these can
	-- reference each other.
	for key, sc in pairs(scraper.fields) do
		if not sc.compute then
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
					-- The pipeline is seeded with the element itself (not its
					-- text) so a transform can read an attribute via the
					-- `attr(name)` filter - `text()` (or no transform at all)
					-- gets back today's old default, element:getcontent().
					logger.debug(string.format("Element [key=%s]", key))
					local r = (sc.transform and sc.transform ~= "") and e or e:getcontent()
					self:_assign_field(data, key, sc, r)

					if data[key] ~= nil then
						break
					end
				end

				if data[key] ~= nil then
					break
				end
			end
		end
	end

	-- Pass 2: computed fields - `compute = "<arithmetic expression>"`,
	-- resolved against `data` (see web_scraper.expr) so a field can derive
	-- its value from other fields, e.g. a discount percentage from a price
	-- and an original price. May reference raw fields from pass 1 above,
	-- or other computed fields, resolved in dependency order.
	local computed = {}
	for key, sc in pairs(scraper.fields) do
		if sc.compute then
			computed[key] = sc.compute
		end
	end
	if next(computed) then
		local order, order_err = topo_sort_computed(computed)
		if not order then
			logger.error(order_err)
			return data, order_err
		end
		for _, key in ipairs(order) do
			local sc = scraper.fields[key]
			local r, eval_err = expr.eval(sc.compute, data)
			if eval_err then
				logger.warn(string.format("Computing [key=%s] [compute=%s] failed: %s", key, sc.compute, eval_err))
			end
			self:_assign_field(data, key, sc, r)
		end
	end

	-- Pass 3: strip temporal fields - extracted/computed only so other
	-- fields (typically a computed one) could use them, never meant to
	-- appear in the final result.
	for key, sc in pairs(scraper.fields) do
		if sc.temporal then
			data[key] = nil
		end
	end

	return data, nil
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
