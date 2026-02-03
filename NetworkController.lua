local NetworkController = {}

function NetworkController.Create(controllerSocket)
	local self = Class.CreateInstance(Entity.Create(), NetworkController)

	self._Socket = controllerSocket or socket.tcp()
	self._Socket:settimeout(0)
	
	self._Retries = 3

	self._Events = EventDirector.Create()

	return self
end

function NetworkController.GetStringFromCommands(commands)
	local commandsString = buffer.new()

	for _, command in ipairs(commands) do
		commandsString:put("&", command[1])

		if #command > 1 then
			commandsString:put(":")

			for index = 2, #command, 1 do
				local argument = command[index]

				if type(argument) == "string" then
					for bytePosition, codePoint in utf8.codes(argument) do
						local character = utf8.char(codePoint)
						
						if
							character == ',' or
							character == '!' or
							character == '&' or
							character == ':'
						then
							commandsString:put("\\")
						end

						commandsString:put(character)
					end
				else
					commandsString:put(argument)
				end
				
				commandsString:put(index < #command and "," or "")
			end
		end
	end

	local resultingString = commandsString:put("!"):get()
	commandsString:free()

	return resultingString
end

function NetworkController.GetCommandsFromString(commandsString)
	if string.sub(commandsString, -1) == "!" then
		local parsedCommands = {}

		local commandStart = nil
		
		local ignoreNext = false
		
		local commandTable = nil
		local argumentBuffer = buffer.new()

		for bytePosition, codePoint in utf8.codes(commandsString) do
			local character = utf8.char(codePoint)

			if ignoreNext then
				ignoreNext = false
			elseif character == '&' then
				if commandTable then
					table.insert(commandTable, argumentBuffer:skip(1):get())
				elseif commandStart then
					local commandName = string.sub(commandsString, commandStart + 1, bytePosition - 1)
				
					if #commandName > 0 then
						table.insert(parsedCommands, {commandName})
					end
				end

				commandStart = bytePosition
			elseif character == ':' then
				if commandStart then
					local commandName = string.sub(commandsString, commandStart + 1, bytePosition - 1)

					if #commandName > 0 then
						commandTable = {commandName}
						table.insert(parsedCommands, commandTable)
					end
				end

				commandStart = nil
				argumentBuffer:reset()
			elseif character == ',' then
				if commandTable then
					table.insert(commandTable, argumentBuffer:skip(1):get())
				end
			elseif character == '!' then
				if commandStart then
					local commandName = string.sub(commandsString, commandStart + 1, bytePosition - 1)

					if #commandName > 0 then
						table.insert(parsedCommands, {commandName})
					end
				end

				if commandTable then
					table.insert(commandTable, argumentBuffer:skip(1):get())
				end

				break
			elseif character == '\\' then
				ignoreNext = true
			end

			if not ignoreNext then
				argumentBuffer:put(character)
			end
		end

		argumentBuffer:free()
		return parsedCommands
	end
end

function NetworkController.GetPrivateIP()
	local udpSocket = socket.udp()
	udpSocket:setpeername("8.8.8.8", 80) -- Google DNS

	local privateIP = udpSocket:getsockname()
	udpSocket:close()

	return privateIP
end

function NetworkController.GetFreePort()
	local portFinder = socket.tcp()
	portFinder:bind("*", 0, 1)

	local _, freePort = portFinder:getsockname()
	portFinder:close()

	return freePort
end

function NetworkController:GetEvents()
	return self._Events
end

function NetworkController:GetRetries()
	return self._Retries
end

function NetworkController:SetRetries(retries)
	self._Retries = retries
end

function NetworkController:Update()
	self._Events:Update()
end

function NetworkController:Bind(IPAddress, port)
	IPAddress = IPAddress or NetworkController.GetPrivateIP()
	port = port or 0

	local success, errorMessage = self._Socket:bind(IPAddress, port)

	if success == 1 then
		return true
	else
		return false, errorMessage
	end
end

function NetworkController:Destroy()
	if not self._Destroyed then
		self._Socket:close()
		self._Socket = nil

		self._Events:Destroy()
		self._Events = nil

		Entity.Destroy(self)
	end
end

return Class.CreateClass(NetworkController, "NetworkController", Entity)