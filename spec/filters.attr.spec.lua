local filter = require("webscraper.filters.filters").attr

describe("Filters", function()
	it("attr", function()
		local element = { attributes = { href = "https://example.com", ["data-id"] = "42" } }
		assert.is_equal("https://example.com", filter(element, "href"))
		assert.is_equal("42", filter(element, "data-id"))
		assert.is_nil(filter(element, "missing"))
		assert.is_nil(filter("not an element", "href"))
	end)
end)
