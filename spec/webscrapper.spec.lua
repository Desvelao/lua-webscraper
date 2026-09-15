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
		assert.is_equal(11, scraper.filters.size)
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
					transform = "text() | trim | uppercase",
				},
				page = {
					selector = { ".page" },
					transform = "text() | to_number",
					validate = "is_number",
				},
			},
		}

		local site2 = {
			urls_match = { "test2%.net", "test2%.com" },
			fields = {
				title = {
					selector = { ".title" },
					transform = "text() | trim | uppercase",
				},
				subtitle = {
					selector = { ".subtitle" },
					transform = "text() | trim",
				},
				other_field = {
					selector = { ".other_field" },
					transform = "text() | to_number",
					validate = "is_number",
				},
			},
		}
		scraper.sites:register("test", site1)
		assert.is_equal(1, scraper.sites.size)

		scraper.filters:register("to_number", tonumber)
		scraper.filters:register("uppercase", webscraper.Filters.uppercase)
		scraper.filters:register("trim", webscraper.Filters.trim)
		scraper.filters:register("text", webscraper.Filters.text)
		assert.is_equal(4, scraper.filters.size)

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

	it("Default headers include a User-Agent", function()
		local scraper = webscraper.WebScraper:new()
		assert.is_not_nil(scraper.headers["User-Agent"])
		assert.is_equal("text/html", scraper.headers["Accept"])
	end)

	it("opts.user_agent overrides the default User-Agent only", function()
		local scraper = webscraper.WebScraper:new({ user_agent = "MyBot/1.0" })
		assert.is_equal("MyBot/1.0", scraper.headers["User-Agent"])
		assert.is_equal("text/html", scraper.headers["Accept"])
	end)

	it("opts.headers merges extra headers without dropping the defaults", function()
		local scraper = webscraper.WebScraper:new({ headers = { ["X-Custom"] = "y" } })
		assert.is_equal("y", scraper.headers["X-Custom"])
		assert.is_not_nil(scraper.headers["User-Agent"])
		assert.is_equal("text/html", scraper.headers["Accept"])
	end)

	it("page.block_text rejects a blocked page before extracting fields", function()
		local scraper = webscraper.WebScraper:new()
		scraper.filters:register("to_number", tonumber)
		scraper.validators:register("is_number", is_number)
		scraper.sites:register("blocked", {
			urls_match = { "blocked%.com" },
			page = { block_text = { "Unusual Traffic" } },
			fields = {
				page = { selector = { ".page" }, transform = "text() | to_number", validate = "is_number" },
			},
		})

		stub(scraper, "_fetch", function()
			return true, '<html><body>We detected unusual traffic from your network.</body></html>'
		end)

		local data, err = scraper:run("https://blocked.com/items/1")
		assert.is_not_nil(err)
		assert.is_true(err:find("page blocked", 1, true) ~= nil)
		assert.is_nil(data.page)
	end)

	it("page.expect_selector rejects a page missing the expected marker", function()
		local scraper = webscraper.WebScraper:new()
		scraper.sites:register("expect", {
			urls_match = { "expect%.com" },
			page = { expect_selector = { ".product-title" } },
			fields = {},
		})

		stub(scraper, "_fetch", function()
			return true, '<html><body><div class="something-else"></div></body></html>'
		end)

		local data, err = scraper:run("https://expect.com/items/1")
		assert.is_not_nil(err)
		assert.is_true(err:find("page validation failed", 1, true) ~= nil)
	end)

	it("a field with no transform still defaults to the element's text content", function()
		local scraper = webscraper.WebScraper:new()
		scraper.sites:register("notransform", {
			urls_match = { "notransform%.com" },
			fields = {
				title = { selector = { ".title" } },
			},
		})

		stub(scraper, "_fetch", function()
			return true, '<html><body><div class="title">Widget</div></body></html>'
		end)

		local data, err = scraper:run("https://notransform.com/items/1")
		assert.is_nil(err)
		assert.is_equal("Widget", data.title)
	end)

	it("attr() filter reads an HTML attribute instead of text", function()
		local scraper = webscraper.WebScraper:new()
		scraper.filters:register("attr", webscraper.Filters.attr)
		scraper.sites:register("attrs", {
			urls_match = { "attrs%.com" },
			fields = {
				link = { selector = { ".link" }, transform = "attr('href')" },
			},
		})

		stub(scraper, "_fetch", function()
			return true, '<html><body><a class="link" href="https://example.com/item/1">Item</a></body></html>'
		end)

		local data, err = scraper:run("https://attrs.com/items/1")
		assert.is_nil(err)
		assert.is_equal("https://example.com/item/1", data.link)
	end)

	it("page validation passes through to normal field extraction when satisfied", function()
		local scraper = webscraper.WebScraper:new()
		scraper.filters:register("trim", webscraper.Filters.trim)
		scraper.filters:register("text", webscraper.Filters.text)
		scraper.sites:register("ok", {
			urls_match = { "ok%.com" },
			page = { expect_selector = { ".product-title" }, block_text = { "captcha" } },
			fields = {
				title = { selector = { ".product-title" }, transform = "text() | trim" },
			},
		})

		stub(scraper, "_fetch", function()
			return true, '<html><body><div class="product-title"> Widget </div></body></html>'
		end)

		local data, err = scraper:run("https://ok.com/items/1")
		assert.is_nil(err)
		assert.is_equal("Widget", data.title)
	end)

	it("a computed field derives its value from other fields, and temporal fields are stripped", function()
		local scraper = webscraper.WebScraper:new()
		scraper.filters:register("text", webscraper.Filters.text)
		scraper.filters:register("to_number", tonumber)
		scraper.sites:register("computed", {
			urls_match = { "computed%.com" },
			fields = {
				price = { selector = { ".price" }, transform = "text() | to_number" },
				original_price = {
					selector = { ".original-price" },
					transform = "text() | to_number",
					temporal = true,
				},
				discount_percent = {
					compute = "(original_price - price) / original_price * 100",
				},
			},
		})

		stub(scraper, "_fetch", function()
			return true,
				'<html><body><div class="price">75</div><div class="original-price">100</div></body></html>'
		end)

		local data, err = scraper:run("https://computed.com/items/1")
		assert.is_nil(err)
		assert.is_equal(75, data.price)
		assert.is_equal(25, data.discount_percent)
		assert.is_nil(data.original_price)
	end)

	it("chained computed fields resolve regardless of declaration order", function()
		local scraper = webscraper.WebScraper:new()
		scraper.filters:register("text", webscraper.Filters.text)
		scraper.filters:register("to_number", tonumber)
		scraper.sites:register("chained", {
			urls_match = { "chained%.com" },
			fields = {
				-- Declared before its own dependency (rounded_discount
				-- references discount_percent) to prove ordering doesn't
				-- depend on Lua's (unspecified) table iteration order.
				rounded_discount = { compute = "discount_percent + 0" },
				discount_percent = { compute = "(original_price - price) / original_price * 100" },
				price = { selector = { ".price" }, transform = "text() | to_number" },
				original_price = { selector = { ".original-price" }, transform = "text() | to_number" },
			},
		})

		stub(scraper, "_fetch", function()
			return true,
				'<html><body><div class="price">50</div><div class="original-price">200</div></body></html>'
		end)

		local data, err = scraper:run("https://chained.com/items/1")
		assert.is_nil(err)
		assert.is_equal(75, data.discount_percent)
		assert.is_equal(75, data.rounded_discount)
	end)

	it("a circular dependency between computed fields returns an error instead of hanging", function()
		local scraper = webscraper.WebScraper:new()
		scraper.sites:register("circular", {
			urls_match = { "circular%.com" },
			fields = {
				a = { compute = "b + 1" },
				b = { compute = "a + 1" },
			},
		})

		stub(scraper, "_fetch", function()
			return true, "<html><body></body></html>"
		end)

		local data, err = scraper:run("https://circular.com/items/1")
		assert.is_not_nil(err)
		assert.is_true(err:find("circular dependency", 1, true) ~= nil)
	end)
end)
