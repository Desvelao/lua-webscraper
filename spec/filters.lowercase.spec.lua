local filter = require("webscraper.filters.filters").lowercase

describe("Filters", function()
	it("lowercase", function()
		assert.is_equal("test", filter("TEST"))
		assert.is_equal("test2", filter("TEST2"))
		assert.is_equal("tes2t2", filter("TES2T2"))
	end)
end)
