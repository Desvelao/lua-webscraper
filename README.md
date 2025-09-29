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
        title = {
            selector = { "h1" },
            transform = "trim | uppercase",
            validate = "is_string", -- The validation ensures the transformed data fulfill the condition, else the field value will be nil
        },
        subtitle = {
            selector = { "h2", "h2.subtitle" }, -- Support multiple selectors to retrieve data for the same field
            transform = "trim | uppercase",
            validate = "is_string",
        },
        date = {
            selector = { ".date" },
            transform = "trim | parse_date('%d/%m/%Y')",
            validate = "is_string",
        },
    },
})

-- Run the scraper
local result = scraper:run("https://example.com")
print(result)
```

### Filters

Filters are used to transform data. Some built-in filters include:

- `lowercase`: Converts a string to lowercase.
- `match`: Match a text.
- `parse_date`: Parses a date string into a specific format.
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
