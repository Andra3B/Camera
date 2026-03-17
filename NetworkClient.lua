local NetworkController = require("NetworkController")

local NetworkClient = {}

function NetworkClient.Create(clientSocket, connected)
	local self = Class.CreateInstance(NetworkController.Create(clientSocket), NetworkClient)

	self._LastInteractionTime = socket.gettime()
	self._LastPingTime = 0

	self._PingPeriod = 1
	self._IdleTime = 5

	self._Connected = connected

	return self
end

function NetworkClient:GetPingPeriod()
	return self._PingPeriod
end

function NetworkClient:SetPingPeriod(period)
	period = math.max(0, period)

	if period ~= self._PingPeriod then
		self._PingPeriod = period

		return true, period
	end
end

function NetworkClient:GetIdleTime()
	return self._IdleTime
end

function NetworkClient:SetIdleTime(time)
	time = math.max(0, time)

	if time ~= self._IdleTime then
		self._IdleTime = time

		return true, time
	end
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
		errorMessage = "Invalid IP address"
	end

	if success == 1 then
		self._Connected = true

		self._LastInteractionTime = socket.gettime()
		self._LastPingTime = 0

		return true
	else
		return false, errorMessage
	end
end

function NetworkClient:Disconnect()
	if self._Connected then
		self._Events:Trigger("Disconnected")

		if self._Parent then
			self._Parent.Events:Trigger("Disconnected", self)
		end
		
		self:Send("&Disconnect!")

		self._Socket:close()
		self._Socket = socket.tcp()
		self._Socket:settimeout(0)

		self._Connected = false
	end
end

function NetworkClient:IsConnected()
	return self._Connected
end

function NetworkClient:GetRemoteDetails()
	return self._Socket:getpeername()
end

function NetworkClient:Update()
	NetworkController.Update(self)
	
	if self._Connected then
		local now = socket.gettime()

		if now - self._LastPingTime >= self._PingPeriod then
			self:Send("Ping")

			self._LastPingTime = now
		end

		if now - self._LastInteractionTime <= self._IdleTime then
			local commands = nil
			local data = buffer.new()

			local partialData = nil
			local errorMessage = nil

			while true do
				partialData, errorMessage = self._Socket:receive("*l")

				if partialData then
					self._LastInteractionTime = now
					self._LastPingTime = now

					if partialData == "Ping" then
						self:Send("Pong")
					elseif partialData ~= "Pong" then
						if #data > 0 then
							data:put("\n"..partialData)
						else
							data:put(partialData)
						end

						commands = NetworkController.GetCommandsFromString(data:tostring())
						
						if commands then
							break
						end
					end
				else					
					break
				end
			end
			
			if errorMessage ~= "timeout" then
				if commands then
					for _, command in ipairs(commands) do
						if command[1] == "Disconnect" then
							self:Disconnect()

							break
						else
							self._Events:Push(command[1], select(2, unpack(command)))
									
							if self._Parent then
								self._Parent.Events:Push(command[1], self, select(2, unpack(command)))
							end
						end
					end
				else
					local sourceIPAddress, sourcePort = self:GetLocalDetails()
					local remoteIPAddress, remotePort = self:GetRemoteDetails()

					Log.Error(
						"Network",
						"%s:%s failed to read valid data from %s:%s! %s",
						sourceIPAddress, sourcePort,
						remoteIPAddress, remotePort,
						errorMessage
					)
				end
			end

			data:free()
		else
			self:Disconnect()
		end
	end
end

function NetworkClient:Send(message, ...)
	if self._Connected then
		message = " "..string.format(message, ...).."\n"

		local lastByteSent = 1
		local errorMessage

		while lastByteSent < #message do
			lastByteSent, errorMessage = self._Socket:send(message, lastByteSent + 1)

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
		self:Disconnect()

		NetworkController.Destroy(self)
	end
end

return Class.CreateClass(NetworkClient, "NetworkClient", NetworkController)