local filter = require("webscraper.filters.validators").is_boolean

describe("Filters", function()
	it("is_boolean", function()
		assert.is_equal("3 is not a boolean", filter(3))
		assert.is_equal("test is not a boolean", filter("test"))
		assert.is_equal(nil, filter(true))
		assert.is_equal(nil, filter(false))
		assert.is_equal("nil is not a boolean", filter(nil))
	end)
end)
