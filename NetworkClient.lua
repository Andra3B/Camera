local NetworkController = require("NetworkController")

local NetworkClient = {}

function NetworkClient.Create(clientSocket, owner)
	local self = Class.CreateInstance(NetworkController.Create(clientSocket), NetworkClient)
	
	self._Owner = owner

	self._Connected = owner ~= nil

	return self
end

function NetworkClient:Connect(ipAddress, port, timeout)
	timeout = timeout or 0
	port = tonumber(port)

	local success, errorMessage = false

	if ipAddress then
		if port then
			self._Socket:settimeout(timeout)
			success, errorMessage = self._Socket:connect(ipAddress, port)
			self._Socket:settimeout(0)
		else
			errorMessage = "Invalid port"
		end
	else
		errorMessage = "Invalid IP Address"
	end

	if success == 1 then
		self._Connected = true
		
		self:Send({{"Connected"}})

		return true
	else
		return false, errorMessage
	end
end

function NetworkClient:Disconnect()
	if self._Connected then
		if self._Owner then
			self._Events:Trigger("Disconnected")
			self._Owner.Events:Trigger("Disconnected", self)
		else
			self._Events:Push("Disconnected")
		end

		self:Send({{"Disconnected"}})
		
		self._Socket:close()
		self._Socket = socket.tcp()
		self._Socket:settimeout(0)

		self._Connected = false
	end
end

function NetworkClient:IsConnected()
	return self._Connected
end

function NetworkClient:GetOwner()
	return self._Owner
end

function NetworkClient:GetRemoteDetails()
	return self._Socket:getpeername()
end

function NetworkClient:Update()
	NetworkController.Update(self)

	if self._Connected then
		local commands = nil
		local data = buffer.new()
		local retries = 0
		local errorMessage = "Retry limit reached"

		while retries <= self._Retries do
			local partialData, partialErrorMessage = self._Socket:receive("*l")
			
			if partialErrorMessage == "closed" then
				self:Disconnect()

				return false
			elseif partialData then
				data:put(partialData)

				commands = NetworkController.GetCommandsFromString(data:tostring())

				if commands then
					break
				end
			else
				errorMessage = partialErrorMessage

				break
			end

			retries = retries + 1
		end

		if #data > 0 then
			if commands then
				for _, command in ipairs(commands) do
					if command[1] == "Disconnected" then
						self:Disconnect()

						break
					else
						self._Events:Push(command[1], select(2, unpack(command)))
							
						if self._Owner then
							self._Owner.Events:Push(command[1], self, select(2, unpack(command)))
						end
					end
				end
			else
				local sourceIPAddress, sourcePort = self:GetLocalDetails()
				local remoteIPAddress, remotePort = self:GetRemoteDetails()

				Log.Error(
					Enum.LogCategory.Network,
					"%s:%s failed to read valid data from %s:%s! %s",
					sourceIPAddress, sourcePort,
					remoteIPAddress, remotePort,
					errorMessage
				)
			end
		end

		data:free()
		return true
	end

	return false
end

function NetworkClient:Send(commands)
	if self._Connected then
		local commandsString = " "..NetworkController.GetStringFromCommands(commands).."\n"

		local lastByteSent = 1
		local errorMessage

		while lastByteSent < #commandsString do
			lastByteSent, errorMessage = self._Socket:send(commandsString, lastByteSent + 1)

			if not lastByteSent then
				return false, errorMessage
			end
		end

		return true
	end

	return false
end

function NetworkClient:Destroy()
	if not self._Destroyed then
		self._Owner = nil

		NetworkController.Destroy(self)
	end
end

return Class.CreateClass(NetworkClient, "NetworkClient", NetworkController)