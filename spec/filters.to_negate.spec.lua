local filter = require("webscraper.filters.filters").to_negate

describe("Filters", function()
	it("to_negate", function()
		assert.is_equal(false, filter(true))
		assert.is_equal(true, filter(false))
		assert.is_equal(false, filter("test"))
		assert.is_equal(false, filter(""))
		assert.is_equal(true, filter(nil))
	end)
end)
