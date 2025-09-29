-- parser deep limit
htmlparser_looplimit = 8000

local webscraper = require("webscraper")

webscraper.sites:register("site1", {
	urls_match = { "site1%.com", "site1%.net" },
	fields = {
		title = {
			selector = ".title",
		},
		subtitle = {
			selector = { ".subtitle", "#subtitle" }, -- multiple selector matchers, the first one that get a value will be used
		},
		property_number = {
			selector = { ".property_number" },
			transform = "trim | to_number",
		},
		property_text = {
			selector = { ".property_text" },
			transform = "trim | to_number",
		},
	},
})
