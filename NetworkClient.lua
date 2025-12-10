local NetworkController = require("NetworkController")

local NetworkClient = {}

function NetworkClient.Create(clientSocket, owner)
	local self = Class.CreateInstance(NetworkController.Create(clientSocket), NetworkClient)
	
	self._Owner = owner

	return self
end

function NetworkClient:ConnectUsingIPAddress(ipAddress, port, timeout)
	timeout = timeout or 0

	local success, errorMessage = false, "No IP address or port given"

	if ipAddress and port then
		self._Socket:settimeout(timeout)
		success, errorMessage = self._Socket:connect(ipAddress, port)
		self._Socket:settimeout(0)
	end

	if success == 1 then
		return true
	else
		return false, errorMessage
	end
end

function NetworkClient:ConnectUsingHostname(hostname, port, timeout)
	local ipAddress = socket.dns.toip(hostname)

	if ipAddress then
		return self:ConnectUsingIPAddress(ipAddress, port, timeout)
	else
		return false, "Failed to resolve hostname"
	end
end

function NetworkClient:Disconnect()
	if self:IsConnected() then
		self:Send({{
			"Disconnect"
		}})

		self._Socket:close()
		self._Socket = socket.tcp()
		self._Socket:settimeout(0)
	end
end

function NetworkClient:IsConnected()
	return self._Socket:getpeername() ~= nil
end

function NetworkClient:GetOwner()
	return self._Owner
end

function NetworkClient:GetLocalDetails()
	return self._Socket:getsockname()
end

function NetworkClient:GetRemoteDetails()
	return self._Socket:getpeername()
end

function NetworkClient:Update()
	NetworkController.Update(self)

	if self:IsConnected() then
		local commands = nil
		local data = buffer.new()
		local retries = 0
		local errorMessage = "Retry limit reached"

		while retries <= self._Retries do
			local partialData, partialErrorMessage = self._Socket:receive("*l")
			
			if partialData then
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
					self._Events:Push(command[1], select(2, unpack(command)))
					
					if self._Owner then
						self._Owner.Events:Push(command[1], self, select(2, unpack(command)))
					end

					if command[1] == "Disconnect" then
						self:Disconnect()

						break
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
	end
end

function NetworkClient:Send(commands)
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

function NetworkClient:Destroy()
	if not self._Destroyed then
		self:Disconnect()
		self._Owner = nil

		NetworkController.Destroy(self)
	end
end

return Class.CreateClass(NetworkClient, "NetworkClient", NetworkController)