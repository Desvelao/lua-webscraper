local expr = require("webscraper.web_scraper.expr")

describe("web_scraper.expr", function()
	it("evaluates basic arithmetic with operator precedence", function()
		assert.is_equal(14, expr.eval("2 + 3 * 4", {}))
		assert.is_equal(20, expr.eval("(2 + 3) * 4", {}))
		assert.is_equal(-5, expr.eval("-5", {}))
		assert.is_equal(1, expr.eval("10 / 2 - 4", {}))
	end)

	it("resolves identifiers against the data table", function()
		local data = { price = 10, original_price = 20 }
		assert.is_equal(50, expr.eval("(original_price - price) / original_price * 100", data))
	end)

	it("coerces numeric-looking strings", function()
		assert.is_equal(30, expr.eval("price + 10", { price = "20" }))
	end)

	it("returns nil when a referenced identifier is missing or non-numeric", function()
		assert.is_nil(expr.eval("price + 1", {}))
		assert.is_nil(expr.eval("price + 1", { price = "not a number" }))
	end)

	it("returns nil, err for a malformed expression", function()
		local result, err = expr.eval("1 + ", {})
		assert.is_nil(result)
		assert.is_not_nil(err)

		result, err = expr.eval("(1 + 2", {})
		assert.is_nil(result)
		assert.is_not_nil(err)
	end)

	it("extracts referenced identifiers", function()
		local ids = expr.identifiers("(original_price - price) / original_price * 100")
		assert.is_true(ids.original_price)
		assert.is_true(ids.price)
		assert.is_nil(ids.discount)
	end)
end)
