local filter = require("webscraper.filters.filters").to_boolean

describe("Filters", function()
	it("to_boolean", function()
		assert.is_equal(true, filter("test"))
		assert.is_equal(true, filter("3"))
		assert.is_equal(true, filter(3))
		assert.is_equal(true, filter(""))
		assert.is_equal(false, filter(nil))
		assert.is_equal(true, filter(0))
	end)
end)
