local filter = require("webscraper.filters.validators").is_number

describe("Filters", function()
	it("uppercase", function()
		assert.is_equal(nil, filter(3))
		assert.is_equal("test is not a number", filter("test"))
		assert.is_equal("true is not a number", filter(true))
		assert.is_equal("false is not a number", filter(false))
		assert.is_equal("nil is not a number", filter(nil))
	end)
end)
