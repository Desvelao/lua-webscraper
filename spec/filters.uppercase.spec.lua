local filter = require("webscraper.filters.filters").uppercase

describe("Filters", function()
	it("uppercase", function()
		assert.is_equal("TEST", filter("test"))
		assert.is_equal("TEST2", filter("test2"))
		assert.is_equal("TES2T2", filter("tes2t2"))
	end)
end)
