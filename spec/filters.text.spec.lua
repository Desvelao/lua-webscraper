local filter = require("webscraper.filters.filters").text

describe("Filters", function()
	it("text", function()
		local element = {
			getcontent = function(self)
				return " Widget "
			end,
		}
		assert.is_equal(" Widget ", filter(element))
		assert.is_equal("already a string", filter("already a string"))
	end)
end)
