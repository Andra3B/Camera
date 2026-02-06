local System = {}

Enum.PathType = Enum.Create({
    File = 1,
    Folder = 2
})

Enum.PathType = Enum.Create({
    File = 1,
    Folder = 2
})

Enum.ExecutionMode = Enum.Create({
	Read = "r",
	Write = "w",
	Execute = "e"
})

Enum.OptionDataType = Enum.Create({
	String = 1,
	Boolean = 2,
	Number = 3,
	Enum = 4,
	Path = 5
})

function System.GetSeparator()
	return jit.os == "Windows" and "\\" or "/"
end

function System.GetScriptFolder()
	return System.Format(string.match(string.sub(debug.getinfo(2, "S").source, 2), "^(.+[\\/])"))
end

function System.Assert(condition, errorCode, ...)
    if not condition then
        Log.Critical(...)
        os.exit(errorCode, true)
    end
end

function System.UpdateOptions(arguments)
	for _, argument in ipairs(arguments) do
		if string.sub(argument, 1, 2) == "--" then
			local equalIndex = string.find(argument, "=", 1, true)
			local configuration
			local valueString

			if equalIndex then
				configuration = System.Options[string.sub(argument, 3, equalIndex - 1)]
				valueString = string.sub(argument, equalIndex + 1)
			else
				configuration = System.Options[string.sub(argument, 3)]
			end
			
			if configuration then
				local dataType = configuration.DataType

				if dataType == Enum.OptionDataType.String then
					configuration.Value = valueString
				elseif dataType == Enum.OptionDataType.Boolean then
					configuration.Value = true
				elseif dataType == Enum.OptionDataType.Number then
					configuration.Value = tonumber(valueString)
				elseif dataType == Enum.OptionDataType.Enum then
					configuration.Value = configuration.Enum[valueString]
				elseif dataType == Enum.OptionDataType.Path then
					configuration.Value = System.Format(valueString)
				end
			end
		end
	end

	for name, configuration in pairs(System.Options) do
		if configuration.Value == nil then
			if configuration.DataType ~= Enum.OptionDataType.Boolean then
				System.Assert(
					not configuration.Required,
					1,
					Enum.LogCategory.Option,
					"Missing required option \"%s\"!",
					name
				)
			end
			
			configuration.Value = configuration.Default
		end
	end
end

function System.Execute(command, mode)
	local finalCommand = "bash -c '"..command.."'"

	if mode == Enum.ExecutionMode.Execute then
		return os.execute(finalCommand)
	else
		return io.popen(finalCommand, mode)
	end
end

function System.GetDetails(path)
	local absolutePath, folder, name, extension, size, lastModificationTime, pathType

	if #path > 0 then
		local program = System.Execute(
			[[f=$(realpath -m "]]..path..[["); echo ${f}; dirname "${f}"; basename "${f}"; echo ${f##*.}; [ -e "${f}" ] && echo -e $(stat -c "%s\n%Y" "${f}")]],
			Enum.ExecutionMode.Read
		)
		absolutePath, folder, name, extension, size, lastModificationTime = program:read("*l", "*l", "*l", "*l", "*l" ,"*l")
		program:close()

		name = string.match(name, "(.*)%.?")
		size = tonumber(size)
		lastModificationTime = tonumber(lastModificationTime)
		pathType = absolutePath == extension and Enum.PathType.Folder or Enum.PathType.File
		
		if pathType == Enum.PathType.Folder then
			absolutePath = absolutePath.."/"
			extension = ""
		end
	end

	return {
		AbsolutePath = absolutePath,
		Exists = size ~= nil,
		Type = pathType,
		Folder = folder,
		Name = name,
		Extension = extension,
		Size = size,
		LastModificationTime = lastModificationTime
	}
end

function System.Format(path)
	return System.GetDetails(path).AbsolutePath
end

function System.Create(path)
	local pathDetails = System.GetDetails(path)

	if pathDetails.Exists then
		return true
	elseif pathDetails.AbsolutePath then
		if pathDetails.Type == Enum.PathType.Folder then
			return System.Execute(
				"mkdir -p \""..pathDetails.AbsolutePath.."\"",
				Enum.ExecutionMode.Execute
			) == 0
		else
			return System.Execute(
				"mkdir -p \""..pathDetails.Folder.."\" && touch \""..pathDetails.AbsolutePath.."\"",
				Enum.ExecutionMode.Execute
			) == 0
		end
	end

	return false
end

function System.Destroy(path)
	return System.Execute(
		"rm -r -f \""..path.."\"",
		Enum.ExecutionMode.Execute
	) == 0
end

function System.Copy(from, to, newer)
	return System.Execute(
		"cp -P --preserve=all --no-preserve=timestamps -r -f "..(newer and "-u \"" or "\"")..from.."\" \""..to.."\"",
		Enum.ExecutionMode.Execute
	) == 0
end

function System.GetContents(path, maxDepth, ...)
	local pathDetails = System.GetDetails(path)
	
	if pathDetails.Exists then
		local contents = {}

		if pathDetails.Type == Enum.PathType.File then
			table.insert(contents, pathDetails.AbsolutePath)
		else
			local wildcardTable = {...}
			local wildcards = ""

			if #wildcardTable > 0 then
				wildcards = " \\( "

				wildcards = wildcards.."-path \""..wildcardTable[1].."\""

				for index = 2, #wildcardTable, 1 do
					wildcards = wildcards.." -o -path \""..wildcardTable[index].."\""
				end

				wildcards = wildcards.." \\)"
			end

			local program = System.Execute(
				"find \""..pathDetails.AbsolutePath.."\" -mindepth 1 "..(type(maxDepth) == "number" and "-maxdepth "..tostring(maxDepth) or "")..wildcards.." -print",
				Enum.ExecutionMode.Read
			)

			for line in program:lines() do
				table.insert(contents, line)
			end

			program:close()
		end

		return contents
	end
end

return System