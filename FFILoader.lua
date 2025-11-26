local ffi = require("ffi")

local FFILoader = {}

local function IndexMetamethod(self, name)
	local value = self.Defines[name]

	if value == nil then
		return self.Library[name]
	elseif value ~= table.empty then
		return value
	end
end

function FFILoader.ConvertCToLua(expression)
	if string.find(expression, "^\".*\"$") then return expression end

	expression = string.gsub(expression, "||", "or")
	expression = string.gsub(expression, "&&", "and")
	expression = string.gsub(expression, "->", ".")
	expression = string.gsub(expression, "NULL", "NIL")
	expression = string.gsub(expression, "%([%w_]+%)(%(?[%w_-].-%)?)", "%1")
	expression = string.gsub(expression, "~([%b()%w]+)", "bit.bnot(%1)")
	expression = string.gsub(expression, "(0x%x+)[fuUl]+", "%1")
	expression = string.gsub(expression, "(%d)[FfuULl]+", "%1")
	expression = "("..expression..")"

	while true do
		local subexpressionStart, subexpressionEnd, subexpression = 0, 0, expression

		while string.find(subexpression, "[|<>&]") do
			local _subexpressionStart, _, _subexpression = string.find(subexpression, "^(%b())")
			if _subexpressionStart then
				subexpression = string.sub(_subexpression, 2, -2)
				subexpressionStart = subexpressionStart + _subexpressionStart
				subexpressionEnd = subexpressionStart + #subexpression + 1
			else
				_subexpressionStart, _, _subexpression = string.find(subexpression, "[^%w_](%b())")

				if _subexpressionStart then
					subexpression = string.sub(_subexpression, 2, -2)
					subexpressionStart = subexpressionStart + _subexpressionStart + 1
					subexpressionEnd = subexpressionStart + #subexpression + 1
				else
					break
				end
			end
		end

		if subexpressionStart ~= 0 then
			local operationStart, operationEnd, left, right = string.find(subexpression, "(.+)|(.+)")

			if operationStart then subexpression = string.replace(subexpression, operationStart, operationEnd,
				string.format("bit.bor((%s), (%s))", left, right)
			) end

			operationStart, operationEnd, left, right = string.find(subexpression, "(.+)&(.+)")

			if operationStart then subexpression = string.replace(subexpression, operationStart, operationEnd,
				string.format("bit.band((%s), (%s))", left, right)
			) end

			operationStart, operationEnd, left, right = string.find(subexpression, "(.+)<<(.+)")

			if operationStart then subexpression = string.replace(subexpression, operationStart, operationEnd,
				string.format("bit.lshift((%s), (%s))", left, right)
			) end

			operationStart, operationEnd, left, right = string.find(subexpression, "(.+)>>(.+)")
			
			if operationStart then subexpression = string.replace(subexpression, operationStart, operationEnd,
				string.format("bit.rshift((%s), (%s))", left, right)
			) end

			expression = string.replace(expression, subexpressionStart, subexpressionEnd, subexpression)
		else
			break
		end
	end

	return expression
end

function FFILoader.LoadDefinitions(libraryKeywords, preprocessedHeaderPath, defines, declarations)
	defines = defines or {}

	defines.bit = require("bit")
	defines.NIL = table.empty

	local libraryLineMarkerMatches = {}

	for _, keyword in ipairs(libraryKeywords) do
		table.insert(libraryLineMarkerMatches, "^# %d+ \".*"..keyword)
	end
	
	local fromLibrary = false
	local declaration = ""

	if declarations then
		ffi.cdef(declarations)
	end

	for line in love and love.filesystem.lines(preprocessedHeaderPath) or io.lines(preprocessedHeaderPath) do
		if string.find(line, "^%s*$") then
		elseif string.find(line, "^# %d") then
			fromLibrary = false

			for _, lineMarkerMatch in ipairs(libraryLineMarkerMatches) do
				if string.find(line, lineMarkerMatch) then
					fromLibrary = true

					break
				end
			end
		elseif string.find(line, "^#") then
			if fromLibrary then
				local name, arguments, value, body

				name, value = string.match(line, "^#define ([%w_]*) (.*)")

				if name then
					if not defines[name] then
						if #value == 0 then
							defines[name] = true
						else
							local defineCode = load(
								"return "..FFILoader.ConvertCToLua(value),
								name, "t", defines
							)

							if defineCode then
								local success, defineValue = pcall(defineCode)

								if success then
									defines[name] = defineValue
								end
							end
						end

						goto LoopEnd
					end
				end

				name, arguments, body = string.match(line, "^#define ([%w_]*)(%b()) (.+)")

				if name then
					if not defines[name] then
						local macroCode = load(string.format(
							"return (function%s return %s end)(...)", arguments, FFILoader.ConvertCToLua(body)
						), name, "t", defines)

						defines[name] = macroCode
					end

					goto LoopEnd
				end
						
				name = string.match(line, "^#undef ([%w_]*)")

				if name then
					defines[name] = nil
				end
			end
		else
			declaration = declaration..line

			if
				string.find(declaration, ";", 1, true) and
				select(2, string.gsub(declaration, "{", "")) == select(2, string.gsub(declaration, "}", ""))
			then
				declaration = declaration:gsub("%[%[.-%]%]", ""):gsub("__attribute__%(%(.-%)%)", "")
				pcall(ffi.cdef, declaration)

				declaration = ""
			end
		end
		
		::LoopEnd::
	end

	return defines
end

function FFILoader.CreateLibrary(libraryPath, defines, loadGlobally)
	return setmetatable({
		Defines = defines,
		Library = ffi.load(libraryPath, loadGlobally)
	}, { __index = IndexMetamethod })
end

return FFILoader