-- Description: DSL filter engine for web scraper
-- This module provides functionality to parse and apply a series of filters
-- to a given value based on a pipeline string.
-- @module dsl_filter
local M = {}

local function split_pipeline(s, delim)
	delim = delim or "|"
	local parts, buf, depth = {}, {}, 0
	local i, n = 1, #s
	while i <= n do
		local c = true
		local ch = s:sub(i, i)
		if ch == "(" then
			depth = depth + 1
			table.insert(buf, ch)
		elseif ch == ")" then
			depth = math.max(0, depth - 1)
			table.insert(buf, ch)
		elseif depth == 0 and s:sub(i, i + #delim - 1) == delim then
			table.insert(parts, table.concat(buf):match("^%s*(.-)%s*$"))
			buf = {}
			i = i + #delim
			c = false
		else
			table.insert(buf, ch)
		end
		if c then
			i = i + 1
		end
	end
	if #buf > 0 then
		table.insert(parts, table.concat(buf):match("^%s*(.-)%s*$"))
	end
	return parts
end

----- Utility: parse function call tokens like: name(arg1, 'arg2', /regex/) -----
local function parse_command(cmd)
	cmd = cmd:match("^%s*(.-)%s*$")
	local name, args = cmd:match("^([%w_]+)%s*%((.*)%)$")
	if not name then
		return cmd, {}
	end
	local raw = args or ""
	local out, cur, depth, in_s, in_d, i = {}, {}, 0, false, false, 1
	while i <= #raw do
		local ch = raw:sub(i, i)
		if ch == "'" and not in_d then
			in_s = not in_s
			table.insert(cur, ch)
		elseif ch == '"' and not in_s then
			in_d = not in_d
			table.insert(cur, ch)
		elseif not in_s and not in_d and ch == "(" then
			depth = depth + 1
			table.insert(cur, ch)
		elseif not in_s and not in_d and ch == ")" then
			depth = math.max(0, depth - 1)
			table.insert(cur, ch)
		elseif not in_s and not in_d and depth == 0 and ch == "," then
			table.insert(out, table.concat(cur):match("^%s*(.-)%s*$"))
			cur = {}
		else
			table.insert(cur, ch)
		end
		i = i + 1
	end
	if #cur > 0 then
		table.insert(out, table.concat(cur):match("^%s*(.-)%s*$"))
	end
	-- normalize args: strip surrounding quotes or /.../ literal
	local norm = {}
	for _, a in ipairs(out) do
		local q = a:sub(1, 1)
		if (q == "'" or q == '"') and a:sub(-1) == q then
			table.insert(norm, a:sub(2, -2))
		elseif a:sub(1, 1) == "/" and a:sub(-1) == "/" then
			table.insert(norm, a:sub(2, -2)) -- store as plain pattern; requires Lua patterns
		else
			table.insert(norm, a)
		end
	end
	return name, norm
end

----- Transform engine: parse "fn1(...) | fn2(...)" and apply sequentially -----
local function apply_filter(value, pipeline_str, filters)
	if not pipeline_str or pipeline_str == "" then
		return value
	end
	local steps = split_pipeline(pipeline_str, "|")
	local cur = value
	for _, step in ipairs(steps) do
		local name, args = parse_command(step)
		local fn = filters[name]
		if not fn then
			error("Unknown filter: " .. tostring(name))
		end
		cur = fn(cur, unpack(args))
	end
	return cur
end

local function apply_validate(value, pipeline_str, transformers)
	if not pipeline_str or pipeline_str == "" then
		return value
	end
	local steps = split_pipeline(pipeline_str, "|")
	local cur = value
	for _, step in ipairs(steps) do
		local name, args = parse_command(step)
		local fn = transformers[name]
		if not fn then
			error("Unknown validation: " .. tostring(name))
		end
		cur = fn(cur, unpack(args))

		if cur then
			return false, cur
		end
	end
	return true, cur
end

--- The DSL filter module provides functionality to apply a series of filters
-- to a given value based on a pipeline string.
-- It supports parsing and executing filter commands with arguments.
-- @module dsl_filter
-- @usage
-- local dsl_filter = require("web_scraper.dsl_filter")
-- local filters = {
--	 lowercase = function(v) return v:lower() end,
--	 uppercase = function(v) return v:upper() end,
-- }
-- local result = dsl_filter.apply_filter("Hello World", "lowercase() | uppercase()", filters)
-- print(result) -- Output: "HELLO WORLD"
-- @usage
--	 local dsl_filter = require("web_scraper.dsl_filter")
--	 local validators = {
--		 is_number = function(v) return tonumber(v) and nil or "Not a number" end,
--		 is_positive = function(v) return v > 0 and nil or "Not positive" end,
--	 }
--	 local valid, err = dsl_filter.apply_validate("42", "is_number() | is_positive()", validators)
--	 if valid then
--		 print("Value is valid")
--	 else
--		 print("Validation error: " .. err)
--	 end
return setmetatable({}, {
	__index = {
		apply_filter = apply_filter,
		apply_validate = apply_validate,
		parse_command = parse_command,
		split_pipeline = split_pipeline,
	},
	__call = function(_, ...)
		return apply_filter(...)
	end,
})
