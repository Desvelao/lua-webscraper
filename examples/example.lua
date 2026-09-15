-- parser deep limit
htmlparser_looplimit = 8000

local webscraper = require("webscraper")

webscraper.sites:register("site1", {
	urls_match = { "site1%.com", "site1%.net" },
	fields = {
		title = {
			selector = { ".title" },
		},
		subtitle = {
			selector = { ".subtitle", "#subtitle" }, -- multiple selector matchers, the first one that get a value will be used
		},
		-- A transform pipeline receives the matched element itself, not its
		-- text - start it with `text` to get the element's text content.
		image_url = {
			selector = { ".image" },
			transform = "attr('src')", -- read an attribute instead of the element's text
		},
		out_of_stock = {
			selector = { ".in_stock" },
			transform = "text | trim | to_boolean | to_negate", -- invert a boolean value
		},
		property_number = {
			selector = { ".property_number" },
			transform = "text | trim | to_number",
		},
		property_text = {
			selector = { ".property_text" },
			transform = "text | trim",
		},
		price = {
			selector = { ".price" },
			transform = "text | trim | to_number",
		},
		-- Only needed to compute discount_percent below - `temporal` fields
		-- are extracted normally but stripped from the final result.
		original_price = {
			selector = { ".original_price" },
			transform = "text | trim | to_number",
			temporal = true,
		},
		discount_percent = {
			compute = "(original_price - price) / original_price * 100",
		},
	},
})
