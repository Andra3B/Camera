require("main")

NIL = table.empty

local FFILoader = {}

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
	expression = string.gsub(expression, "%(([%w_]+%*?)%)%s*%(([%w_]-)%)", "ffi.cast(\"%1\", %2)")
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

function FFILoader.CreateBindings(libraryKeywords, headerPath, libraryPaths, outputPath, outputName, defines, declarations)
	local outputDirectory = outputPath.."/"..outputName

	local cDefinitionsFile = io.open(outputDirectory.."/"..outputName..".cdef", "w")
	local luaFile = io.open(outputDirectory.."/"..outputName..".lua", "w")
	cDefinitionsFile:setvbuf("full")
	luaFile:setvbuf("full")

	luaFile:write([[
local ffi = require("ffi")
local bit = require("bit")

local function IndexMetamethod(self, name)
	local value = self.Defines[name]

	if value == nil then
		return self.Library[name]
	elseif value ~= table.empty then
		return value
	end
end

local defines = {}
local libraries = {}

local cDefinitionsFile = io.open("]]..outputDirectory.."/"..outputName..[[.cdef", "r")
ffi.cdef(cDefinitionsFile:read("a*"))
cDefinitionsFile:close()

]])
	
	for name, library in pairs(libraryPaths) do
		luaFile:write([[libraries["]]..name..[["] = setmetatable({Library = ffi.load("]]..library..[[", true), Defines = defines}, {__index = IndexMetamethod})]].."\n")
	end

	luaFile:write("\n")

	if defines then
		for name, value in pairs(defines) do
			local valueType = type(value)

			if valueType == "string" then
				luaFile:write("defines[\""..name.."\"] = \""..value.."\"\n")
			elseif valueType == "number" or valueType == "boolean" then
				luaFile:write("defines[\""..name.."\"] = "..tostring(value).."\n")
			end
		end
	else
		defines = {}
	end
	
	local libraryLineMarkerMatches = {}

	for _, keyword in ipairs(libraryKeywords) do
		table.insert(libraryLineMarkerMatches, "^# %d+ \".*"..keyword)
	end
	
	local fromLibrary = false
	local declaration = ""

	if declarations then
		cDefinitionsFile:write(declarations.."\n")
	end

	local lineIndex = 1
	for line in love and love.filesystem.lines(headerPath) or io.lines(headerPath) do
		if string.find(line, "^%s*$") then
		elseif string.find(line, "^# %d") then
			fromLibrary = false

			for _, lineMarkerMatch in ipairs(libraryLineMarkerMatches) do
				if string.find(line, lineMarkerMatch) then
					fromLibrary = true

					break
				end
			end
		elseif fromLibrary then
			if string.find(line, "^#") then
				local name, arguments, value, body

				name, value = string.match(line, "^#define ([%w_]*) (.*)")

				if name then
					if not defines[name] then
						if #value == 0 then
							defines[name] = true
							luaFile:write("defines[\""..name.."\"] = true\n")
						else
							local defineCodeString = "return "..FFILoader.ConvertCToLua(value)
							local defineCode = load(defineCodeString, name, "t", defines)

							if defineCode then
								local success, defineValue = pcall(defineCode)

								if success then
									local valueType = type(defineValue)

									defines[name] = defineValue

									if valueType == "string" then
										luaFile:write("defines[\""..name.."\"] = \""..string.gsub(defineValue, "[\"\\']", "\\%0").."\"\n")
									elseif valueType == "number" or valueType == "boolean" then
										luaFile:write("defines[\""..name.."\"] = "..tostring(defineValue).."\n")
									end
								end
							end
						end

						goto LoopEnd
					end
				end

				name, arguments, body = string.match(line, "^#define ([%w_]*)(%b()) (.+)")

				if name then
					if not defines[name] then
						local macroCodeString = string.format(
							"function%s return %s end",
							arguments, FFILoader.ConvertCToLua(body)
						)
						local macroCode = load("return ("..macroCodeString..")(...)", name, "t", defines)

						if macroCode then
							defines[name] = macroCode
							luaFile:write("defines[\""..name.."\"] = setfenv("..macroCodeString..", defines)\n")
						end
					end

					goto LoopEnd
				end
					
				name = string.match(line, "^#undef ([%w_]*)")

				if name then
					defines[name] = nil
					luaFile:write("defines[\""..name.."\"] = nil\n")
				end
			else
				declaration = declaration.." "..line

				if string.find(declaration, ";", 1, true) then
					local insideString = false
					local curlyBraceCount = 0

					for character in string.gmatch(declaration, ".") do
						if character == "\"" or character == "'" then
							insideString = not insideString
						elseif not insideString then
							if character == "{" then
								curlyBraceCount = curlyBraceCount + 1
							elseif character == "}" then
								curlyBraceCount = curlyBraceCount - 1
							end
						end
					end

					if curlyBraceCount == 0 then
						declaration = declaration:gsub("%[%[.-%]%]", ""):gsub("__attribute__%(%(.-%)%)", "")

						if pcall(ffi.cdef, declaration) then
							cDefinitionsFile:write(declaration.."\n")
						end

						declaration = ""
					end
				end
			end
		end
		
		::LoopEnd::
		
		print("Line "..tostring(lineIndex).." processed.")
		lineIndex = lineIndex + 1
	end

	luaFile:write("\nreturn libraries")

	cDefinitionsFile:close()
	luaFile:close()
end

return FFILoader