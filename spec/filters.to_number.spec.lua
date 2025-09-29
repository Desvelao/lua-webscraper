local filter = require("webscraper.filters.filters").to_number

describe("Filters", function()
	it("to_number", function()
		assert.is_equal(3, filter("3"))
		assert.is_equal(3.14, filter("3.14"))
	end)
end)
