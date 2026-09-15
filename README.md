# webscraper

## Description

This library provides a way to scrap data of static HTML webpages (data is not rendered using JavaScript).

## Features

- Define configurations for sites with URL matchers and field selectors.
- Use CSS selectors to extract content from HTML elements.
- Apply a string-based pipeline to filter and validate the data.
- Supports extensible filters and validators for custom transformations.

## Installation

To install the library, use [LuaRocks](https://luarocks.org/):

```bash
luarocks install webscraper
```

## Usage

### Basic example

```lua
local webscraper = require("webscraper")

-- Create a new WebScraper instance
local scraper = webscraper.WebScraper:new()
local builtin_scraper = webscraper -- This is the built-in scraper that has all the built-in filters and valitors pre-loaded

-- Define a site configuration
scraper.sites:register("example", {
    urls_match = { "https://example.com/.*" },
    fields = {
        -- A transform pipeline receives the matched element itself (not
        -- its text) - start it with the `text` filter to get the old
        -- default behavior back, or with `attr(name)` to read an
        -- attribute instead (see "Extracting attributes" below). A field
        -- with NO transform at all still defaults to the element's text
        -- content automatically.
        title = {
            selector = { "h1" },
            transform = "text | trim | uppercase",
            validate = "is_string", -- The validation ensures the transformed data fulfill the condition, else the field value will be nil
        },
        subtitle = {
            selector = { "h2", "h2.subtitle" }, -- Support multiple selectors to retrieve data for the same field
            transform = "text | trim | uppercase",
            validate = "is_string",
        },
        date = {
            selector = { ".date" },
            transform = "text | trim | parse_date('%d/%m/%Y')",
            validate = "is_string",
        },
        -- No transform at all - defaults to the element's text content.
        plain_text = {
            selector = { ".plain" },
        },
    },
})

-- Run the scraper
local result, err = scraper:run("https://example.com")
print(result, err)
```

### Extracting attributes

Sometimes the data you need is in an HTML attribute (a link's `href`, an
image's `src`, a meta tag's `content`) rather than the element's text.
Since a transform pipeline is seeded with the matched element itself, the
`attr(name)` filter reads straight off it - no `text` needed first:

```lua
scraper.sites:register("example", {
    urls_match = { "https://example.com/.*" },
    fields = {
        image_url = {
            selector = { "img.product" },
            transform = "attr('src')",
        },
    },
})
```

### Computed and temporal properties

A field can derive its value from other already-extracted fields instead
of a CSS selector, via `compute` - a small arithmetic expression
(`+ - * /`, parentheses, unary minus) resolved against the other fields'
values by name:

```lua
scraper.sites:register("example", {
    urls_match = { "https://example.com/.*" },
    fields = {
        price = { selector = { ".price" }, transform = "text | to_number" },
        -- Only needed to compute discount_percent below - `temporal`
        -- fields are extracted/computed normally but stripped from the
        -- final result.
        original_price = {
            selector = { ".original-price" },
            transform = "text | to_number",
            temporal = true,
        },
        discount_percent = {
            compute = "(original_price - price) / original_price * 100",
        },
    },
})

local result = scraper:run("https://example.com/item/1")
-- result = { price = 75, discount_percent = 25, ... } - no original_price.
```

A computed field can reference other computed fields too (resolved in
dependency order, regardless of declaration order); a circular dependency
(`a` depends on `b` which depends on `a`) makes `scraper:run(...)` return a
non-nil `err` describing the cycle rather than hanging. A missing or
non-numeric referenced field makes the whole computed value `nil` (the
field is simply absent), the same way a selector that matches nothing
leaves its field unset.

### Request headers

Every request sends a default `User-Agent`/`Accept`/`Content-Encoding`
header set. Override them via `WebScraper:new(opts)`:

```lua
-- Just override the User-Agent, keep the other defaults
local scraper = webscraper.WebScraper:new({ user_agent = "MyBot/1.0" })

-- Or set/override arbitrary headers (merged on top of the defaults)
local scraper = webscraper.WebScraper:new({
    headers = { ["User-Agent"] = "MyBot/1.0", ["Accept-Language"] = "en-US" },
})
```

### Page validation (block/CAPTCHA detection)

A site can declare an optional `page` config, checked right after the page
is fetched and parsed but *before* any field's selector/transform/validate
runs against it - useful when a site's anti-bot system returns a 200 status
with an unrelated block/CAPTCHA page instead of the real content, which
would otherwise just silently produce empty fields.

```lua
scraper.sites:register("example", {
    urls_match = { "https://example.com/.*" },
    page = {
        -- Fails validation if any of these selectors match (a known
        -- block/CAPTCHA page marker).
        block_selector = { "#captcha-form" },
        -- Fails validation if any of these substrings appear anywhere in
        -- the raw response body (case-insensitive).
        block_text = { "are you a human", "unusual traffic" },
        -- If given, at least one of these selectors must be present, or
        -- validation fails (a positive check that the real page loaded).
        expect_selector = { "#product-title" },
    },
    fields = { ... },
})

local result, err = scraper:run("https://example.com/item/1")
if err then
    print("scrape failed: " .. err) -- e.g. "page blocked: matched block_text 'unusual traffic'"
end
```

`scraper:run(url)` (and `WebScraper:_run`) now return `result, err` - `err`
is `nil` on success, or a string describing why (a failed fetch, or a
`page` validation failure) when the page couldn't be scraped. Existing code
that only captures the first return value is unaffected.

### Filters

Filters are used to transform data. Some built-in filters include:

- `attr`: Reads an attribute's value off the matched element (e.g. `attr('href')`).
- `lowercase`: Converts a string to lowercase.
- `match`: Match a text.
- `parse_date`: Parses a date string into a specific format.
- `text`: Extracts the matched element's text/inner content.
- `to_negate`: Inverts a boolean value.
- `to_number`: Converts a string to a number.
- `trim`: Removes leading and trailing whitespace.
- `uppercase`: Converts a string to uppercase.

### Validators

Validators ensure the data meets specific criteria. Some built-in validators include:

- `is_boolean`: Checks if the value is a boolean.
- `is_number`: Checks if the value is a number.
- `is_string`: Checks if the value is a string.

#### Custom filters and validators

```lua
-- Register a custom filter
webscraper.filters:register("reverse", function(v)
    return v:reverse()
end)

-- Register a custom validator
webscraper.validators:register("is_positive", function(v)
    if tonumber(v) > 0 then
        return nil
    else
        return tostring(v) .. " is not positive"
    end
end)
```

# Development

## Run environment

```bash
# Start environment
docker compose -f docker-compose.dev.yml up -d

# If the container was created, run:
docker compose -f docker-compose.dev.yml exec dev sh /app/setup/setup.sh

# Enter to container
docker compose -f docker-compose.dev.yml exec dev sh
```

## Run tests

Run the test suite using [Busted](https://olivinelabs.com/busted/):

```bash
/usr/local/bin/busted
```

## Format code

Run the test suite using [StyLua](https://github.com/JohnnyMorganz/StyLua):

```bash
/usr/local/bin/stylua src spec examples
```

# License

This library is licensed under the MIT License. See the LICENSE file for details.
