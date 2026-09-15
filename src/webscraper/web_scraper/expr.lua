--- Computed-property arithmetic expressions
-- A small recursive-descent tokenizer + evaluator for a minimal arithmetic
-- grammar, used by WebScraper:_run's computed-field pass (see
-- WebScraper:_run's doc comment on `fields.<key>.compute`).
--
-- Grammar:
--   expr   := term (('+' | '-') term)*
--   term   := factor (('*' | '/') factor)*
--   factor := '-' factor | '(' expr ')' | NUMBER | IDENT
--
-- An identifier resolves against the `data` table (a field name -> its
-- already-extracted/computed value). A missing or non-numeric identifier
-- makes the WHOLE expression resolve to nil rather than raising -
-- consistent with the rest of this library treating "couldn't produce a
-- value" as simply an absent field, not a crash (the same way a selector
-- that matches nothing just leaves a field unset).
-- @module web_scraper.expr
local M = {}

local function tokenize(s)
	local tokens = {}
	local i, n = 1, #s
	while i <= n do
		local c = s:sub(i, i)
		if c:match("%s") then
			i = i + 1
		elseif c:match("%d") or (c == "." and s:sub(i + 1, i + 1):match("%d")) then
			local j = i
			while j <= n and s:sub(j, j):match("[%d%.]") do
				j = j + 1
			end
			table.insert(tokens, { type = "number", value = tonumber(s:sub(i, j - 1)) })
			i = j
		elseif c:match("[%a_]") then
			local j = i
			while j <= n and s:sub(j, j):match("[%w_]") do
				j = j + 1
			end
			table.insert(tokens, { type = "ident", value = s:sub(i, j - 1) })
			i = j
		elseif c == "+" or c == "-" or c == "*" or c == "/" or c == "(" or c == ")" then
			table.insert(tokens, { type = c })
			i = i + 1
		else
			error("computed expression: unexpected character '" .. c .. "'")
		end
	end
	return tokens
end

-- Coerces a value to a number for arithmetic, the same way to_number
-- style filters would (a string field that hasn't been through its own
-- `to_number` transform still works here). Anything else (nil, a table, a
-- non-numeric string) yields nil.
local function tonum(v)
	if type(v) == "number" then
		return v
	end
	return tonumber(v)
end

local function make_evaluator(tokens, data)
	local pos = 1

	local function peek()
		return tokens[pos]
	end
	local function advance()
		pos = pos + 1
	end

	local parse_expr

	local function parse_factor()
		local t = peek()
		if not t then
			error("computed expression: unexpected end of input")
		end
		if t.type == "-" then
			advance()
			local v = parse_factor()
			if v == nil then
				return nil
			end
			return -v
		elseif t.type == "(" then
			advance()
			local v = parse_expr()
			if not (peek() and peek().type == ")") then
				error("computed expression: expected ')'")
			end
			advance()
			return v
		elseif t.type == "number" then
			advance()
			return t.value
		elseif t.type == "ident" then
			advance()
			return tonum(data[t.value])
		else
			error("computed expression: unexpected token")
		end
	end

	local function parse_term()
		local v = parse_factor()
		while peek() and (peek().type == "*" or peek().type == "/") do
			local op = peek().type
			advance()
			local rhs = parse_factor()
			if v == nil or rhs == nil then
				v = nil
			elseif op == "*" then
				v = v * rhs
			else
				v = v / rhs
			end
		end
		return v
	end

	parse_expr = function()
		local v = parse_term()
		while peek() and (peek().type == "+" or peek().type == "-") do
			local op = peek().type
			advance()
			local rhs = parse_term()
			if v == nil or rhs == nil then
				v = nil
			elseif op == "+" then
				v = v + rhs
			else
				v = v - rhs
			end
		end
		return v
	end

	local result = parse_expr()
	if peek() then
		error("computed expression: unexpected trailing token")
	end
	return result
end

--- Evaluates an arithmetic expression against a data table.
-- @param expr_str The expression, e.g. "(original_price - price) / original_price * 100".
-- @param data A table of already-extracted/computed field values, resolved by identifier name.
-- @return number|nil The result, or nil if a referenced field is missing/non-numeric.
-- @return string|nil An error message if the expression itself is malformed.
function M.eval(expr_str, data)
	local ok, tokens_or_err = pcall(tokenize, expr_str)
	if not ok then
		return nil, tokens_or_err
	end
	local eval_ok, result_or_err = pcall(make_evaluator, tokens_or_err, data)
	if not eval_ok then
		return nil, result_or_err
	end
	return result_or_err
end

--- Returns the set of identifier names referenced in an expression.
-- Used to order computed fields that reference each other - not by the
-- evaluator itself, which resolves identifiers directly against `data`.
-- @param expr_str The expression to scan.
-- @return table A set ({[name]=true, ...}) of every identifier found.
function M.identifiers(expr_str)
	local ids = {}
	for id in expr_str:gmatch("[%a_][%w_]*") do
		ids[id] = true
	end
	return ids
end

return M
