local filter = require("webscraper.filters.validators").is_string

describe("Filters", function()
	it("is_string", function()
		assert.is_equal("3 is not a string", filter(3))
		assert.is_equal(nil, filter("test"))
		assert.is_equal("true is not a string", filter(true))
		assert.is_equal("false is not a string", filter(false))
		assert.is_equal("nil is not a string", filter(nil))
	end)
end)
