local filter = require("webscraper.filters.filters").match

describe("Filters", function()
	it("match", function()
		assert.is_equal("t", filter("test", "(t)"))
		assert.is_equal("te", filter("test", "(te)"))
		assert.is_equal("test.", filter("test.test", "(test%.)"))
	end)
end)
