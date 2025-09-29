local webscraper = require("webscraper")

local function noop() end

local function to_number(v)
	return tonumber(v)
end

local function is_number(v)
	if type(v) == "number" then
		return nil
	else
		return tostring(v) .. " is not a number"
	end
end

describe("Built-in Web scraper", function()
	local scraper = webscraper

	it("Built-in filters and validators", function()
		assert.is_equal(0, scraper.sites.size)
		assert.is_equal(8, scraper.filters.size)
		assert.is_equal(3, scraper.validators.size)
	end)

	it("Apply filters", function()
		assert.is_equal("TEST", scraper:apply_filter("test ", "uppercase | trim"))
		assert.is_equal(3.14, scraper:apply_filter("  3.14  ", "trim | to_number"))
		assert.is_equal(true, scraper:apply_filter("test", "to_boolean"))
	end)

	it("Apply validators", function()
		assert.are.same({ true, nil }, { scraper:apply_validate("test ", "is_string") })
		assert.are.same({ false, "test  is not a number" }, { scraper:apply_validate("test ", "is_number") })
		assert.are.same({ true, nil }, { scraper:apply_validate(3.14, "is_number") })
		assert.are.same({ false, "  3.14   is not a boolean" }, { scraper:apply_validate("  3.14  ", "is_boolean") })
		assert.are.same({ true, nil }, { scraper:apply_validate(true, "is_boolean") })
	end)
end)

describe("New Web scraper", function()
	it("Sites, filters and validators of new WebScraper", function()
		local scraper = webscraper.WebScraper:new()
		assert.is_equal(0, scraper.sites.size)
		assert.is_equal(0, scraper.filters.size)
		assert.is_equal(0, scraper.validators.size)

		local site = {
			urls_match = { "test%.net", "test%.com" },
			fields = {
				title = {
					selector = { ".title" },
				},
				page = {
					selector = { ".page" },
					transform = "to_number",
					validate = "is_number",
				},
			},
		}
		scraper.sites:register("test", site)
		assert.is_equal(1, scraper.sites.size)

		scraper.filters:register("to_number", tonumber)
		assert.is_equal(1, scraper.filters.size)

		scraper.validators:register("is_number", is_number)
		assert.is_equal(1, scraper.validators.size)
	end)

	it("Apply filters", function()
		local scraper = webscraper.WebScraper:new()
		scraper.filters:register("to_number", tonumber)
		assert.is_equal(3.14, scraper:apply_filter("3.14", "to_number"))
	end)

	it("Apply validators", function()
		local scraper = webscraper.WebScraper:new()
		scraper.validators:register("is_number", is_number)
		assert.are.same({ true, nil }, { scraper:apply_validate(3.14, "is_number") })
	end)

	it("Run", function()
		local scraper = webscraper.WebScraper:new()

		local site1 = {
			urls_match = { "test%.net", "test%.com" },
			fields = {
				title = {
					selector = { ".title" },
					transform = "trim | uppercase",
				},
				page = {
					selector = { ".page" },
					transform = "to_number",
					validate = "is_number",
				},
			},
		}

		local site2 = {
			urls_match = { "test2%.net", "test2%.com" },
			fields = {
				title = {
					selector = { ".title" },
					transform = "trim | uppercase",
				},
				subtitle = {
					selector = { ".subtitle" },
					transform = "trim",
				},
				other_field = {
					selector = { ".other_field" },
					transform = "to_number",
					validate = "is_number",
				},
			},
		}
		scraper.sites:register("test", site1)
		assert.is_equal(1, scraper.sites.size)

		scraper.filters:register("to_number", tonumber)
		scraper.filters:register("uppercase", webscraper.Filters.uppercase)
		scraper.filters:register("trim", webscraper.Filters.trim)
		assert.is_equal(3, scraper.filters.size)

		scraper.validators:register("is_number", is_number)
		assert.is_equal(1, scraper.validators.size)

		-- Mock _fetch
		stub(scraper, "_fetch", function()
			return true, '<html><body><div class="title"> Test </div><div class="page">2</div></body></html>'
		end)

		local data = scraper:run("https://test.com/items/1")

		assert.is_equal("https://test.com/items/1", data.url)
		assert.is_equal(2, data.page)
		assert.is_equal("TEST", data.title)
		assert.is_not_nil(data.timestamp)
	end)
end)
