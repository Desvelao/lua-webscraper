local filter = require("webscraper.filters.filters").parse_date

describe("Filters", function()
	it("trim", function()
		assert.is_equal("2025-09-23", filter("23/09/2025"))
	end)
end)
